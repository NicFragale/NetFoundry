#!/bin/bash
################################################## ATTENTION ###################################################
# Instruction: Run on the build server as a BUILD CAPABLE USER (ROOT is assumed in this example).
MY_NAME="OWRT_Builder"
MY_VERSION="20230614"
MY_DESCRIPTION="NFragale: Compile/Build Helper for OpenZITI/OpenWRT"
################################################################################################################

###################################################
# Set initial variables/functions.
ZT_OWRT_VER="${1}"
ZT_OWRT_TARGET=("${2}" "${3}")
ZT_OWRT_URL="https://downloads.openwrt.org"
ZT_TUNVER="${4:-latest}"
ZT_WORKDIR="/tmp"
ZT_CLONEURL="https://github.com/openziti/ziti-tunnel-sdk-c"
#ZT_CLONEBRANCH="main"
ZT_CLONEBRANCH="vcpkg-less-build" # Temporary.
VCPKG_URL="https://github.com/microsoft/vcpkg"

################################################################################################################
# DO NOT MODIFY BELOW THIS LINE
################################################################################################################
ZT_CMAKEVER="0.0.0"
ZT_WORKDIR="${ZT_WORKDIR}/OpenWRT-${ZT_OWRT_VER}-${ZT_OWRT_TARGET[0]}_${ZT_OWRT_TARGET[1]}"
VCPKG_ROOT="${ZT_WORKDIR}/vcpkg"
ZT_STEP="0"
ZT_ADDLPKG=("gawk" "git" "zip" "unzip" "wget" "curl")
for ((i=0;i<100;i++)); do PRINT_PADDING+='          '; done
function CPrint() {
    local OUT_COLOR=(${1/:/ }) IN_TEXT="${2}" OUT_MAXWIDTH OUT_SCREENWIDTH NL_INCLUDE i x z
    shopt -s checkwinsize; (:); OUT_SCREENWIDTH="${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}";
    OUT_MAXWIDTH="${3:-${OUT_SCREENWIDTH:-80}}"
    [[ ${OUT_MAXWIDTH} -eq ${OUT_SCREENWIDTH} ]] && NL_INCLUDE='\n'
    [[ ${#IN_TEXT} -gt ${OUT_MAXWIDTH} ]] && IN_TEXT="${IN_TEXT:0:${OUT_MAXWIDTH}}"
    if [[ ${OUT_COLOR} == "COLORTEST" ]]; then
        OUT_MAXWIDTH="10"
        for i in {1..107}; do
            for x in {1..107}; do
                [[ $((++z%(OUT_SCREENWIDTH/OUT_MAXWIDTH))) -eq 0 ]] && echo
                IN_TEXT="${i}:${x}"
                printf "\e[${i};${x}m%-${OUT_MAXWIDTH}s\e[1;0m" "${PRINT_PADDING:0:$(((OUT_MAXWIDTH/2)-${#IN_TEXT}/2))}${IN_TEXT}"
            done
        done
        echo
    else
        printf "\e[${OUT_COLOR[0]};${OUT_COLOR[1]}m%-${OUT_MAXWIDTH}s\e[1;0m${NL_INCLUDE}" "${PRINT_PADDING:0:$(((OUT_MAXWIDTH/2)-${#IN_TEXT}/2))}${IN_TEXT}"
    fi
}
function GTE() {
    CPrint "30:41" "ERROR: Early Exit at Step ${1}."
    exit ${1}
}

###################################################
CPrint "30:46" "${MY_NAME:-UNSET NAME} - v${MY_VERSION:-UNSET VERSION} - ${MY_DESCRIPTION:-UNSET DESCRIPTION}"
CPrint "30:42" "ZITI EDGE TUNNEL VERSION: ${ZT_TUNVER:=UNKNOWN}"
CPrint "30:42" "OPENWRT VERSION: ${ZT_OWRT_VER:=UNKNOWN}"
CPrint "30:42" "OPENWRT TARGET: ${ZT_OWRT_TARGET[0]:=UNKNOWN}/${ZT_OWRT_TARGET[1]:=UNKNOWN}"

###################################################
CPrint "30:43" "Begin Step $((++ZT_STEP)): Input Checking."
if [[ ${ZT_TUNVER} == "UNKNOWN" ]] \
    || [[ ${ZT_OWRT_VER} == "UNKNOWN" ]] \
    || [[ ${ZT_OWRT_TARGET[0]} == "UNKNOWN" ]] \
    || [[ ${ZT_OWRT_TARGET[1]} == "UNKNOWN" ]]; then
    CPrint "30:41" "Input Missing/Error - Please Check."
    GTE ${ZT_STEP}
fi
sleep 3

###################################################
CPrint "30:43" "Begin Step $((++ZT_STEP)): Create Staging Area [Location ${ZT_WORKDIR}]."
if [[ -d ${ZT_WORKDIR} ]]; then
    CPrint "30:45" "WARNING: Staging Area Already Exists ."
    CPrint "30:45" "WARNING: Stop Program (CTRL+C) to Prevent Overwrite."
    sleep 5
    rm -rf "${ZT_WORKDIR}" || GTE ${ZT_STEP}
fi
mkdir -vp "${ZT_WORKDIR}" || GTE ${ZT_STEP}
cd "${ZT_WORKDIR}" || GTE ${ZT_STEP}

###################################################
CPrint "30:43" "Begin Step $((++ZT_STEP)): Acquire Additional Software Part One."
apt update
apt install -y ${ZT_ADDLPKG[@]} || GTE ${ZT_STEP}
IFS='\.' read -r -d '' -a ZT_CMAKEVER < <(\
    awk '/^cmake version/ {
        CMAKEVER=gensub(/cmake version (.*)/,"\\1","1")
        print CMAKEVER
    }' <(cmake --version 2>/dev/null)
)
if [[ ${ZT_CMAKEVER[0]:-0} -ge 3 ]] && [[ ${ZT_CMAKEVER[1]:-0} -ge 24 ]]; then
    echo "CMake Version: ${ZT_CMAKEVER[0]:-0}.${ZT_CMAKEVER[1]:-0}.${ZT_CMAKEVER[2]:-0}"
else
    CPrint "30:41" "ERROR: CMake Version Installed [${ZT_CMAKEVER[0]:-0}.${ZT_CMAKEVER[1]:-0}.${ZT_CMAKEVER[2]:-0}]."
    CPrint "30:41" "ERROR: CMake Version Required [3.24.0+]."
    CPrint "30:41" "See [https://apt.kitware.com] for Latest Version."
    GTE ${ZT_STEP}
fi

###################################################
CPrint "30:43" "Begin Step $((++ZT_STEP)): Acquire ZITI EDGE TUNNEL Source [Version ${ZT_TUNVER}]."
if [[ ${ZT_TUNVER:-latest} == "latest" ]]; then
    IFS=$'\n' read -r -d '' -a ZT_ALLVERSIONS < <(\
        curl -Ls "${ZT_CLONEURL}/tags" \
        | awk '/tags/ {
            if (match($0,/v[0-9].[0-9]+.[0-9]+/)) {
                ALLVERSIONS[substr($0,RSTART,RLENGTH)]++}
            } END {
                for (EACHVERSION in ALLVERSIONS) {
                    gsub("v","",EACHVERSION)
                    print EACHVERSION
                }
            }' \
        | sort -rnt '.' -k1,1 -k2,2 -k3,3
    )
    ZT_TUNVER="${ZT_ALLVERSIONS[0]}"
    ZT_TUNVERARR=( ${ZT_TUNVER//\./ } )
    # VCPKG support began with ZITI-TUNNEL-SDK-C version 0.21.1.
    if [[ ${ZT_TUNVERARR[0]} -gt 0 ]]; then
        ZT_USEVCPKG="TRUE" 
    elif [[ ${ZT_TUNVERARR[0]} -eq 0 ]] && [[ ${ZT_TUNVERARR[1]} -gt 21 ]]; then
        ZT_USEVCPKG="TRUE"
    elif [[ ${ZT_TUNVERARR[0]} -eq 0 ]] && [[ ${ZT_TUNVERARR[1]} -eq 21 ]] && [[ ${ZT_TUNVERARR[2]} -ge 1 ]]; then
        ZT_USEVCPKG="TRUE" 
    else
        ZT_USEVCPKG="FALSE" 
    fi
fi
git clone --single-branch --branch "${ZT_CLONEBRANCH}" "${ZT_CLONEURL}"  "${ZT_WORKDIR}/ziti-tunnel-sdk-c-${ZT_TUNVER}" || GTE ${ZT_STEP}
mkdir -vp "${ZT_WORKDIR}/ziti-tunnel-sdk-c-${ZT_TUNVER}/build" || GTE ${ZT_STEP}

###################################################
if [[ ${ZT_USEVCPKG} == "TRUE" ]]; then
    CPrint "30:43" "Begin Step $((++ZT_STEP)): Acquire Additional Software Part Two - VCPKG Required."
    git clone "${VCPKG_URL}" "${VCPKG_ROOT}" || GTE ${ZT_STEP}
    ${VCPKG_ROOT}/bootstrap-vcpkg.sh -disableMetrics || GTE ${ZT_STEP}
    ${VCPKG_ROOT}/vcpkg version >&1 >/dev/null || GTE ${ZT_STEP}
    mkdir -vp "${VCPKG_ROOT}/custom-triplets" || GTE ${ZT_STEP}
else
    CPrint "30:43" "Skipping Step $((++ZT_STEP)): Acquire Additional Software Part Two - VCPKG Not Required."
fi

###################################################
CPrint "30:43" "Begin Step $((++ZT_STEP)): Acquire OpenWRT SDK [Version ${ZT_OWRT_VER}] [Target ${ZT_OWRT_TARGET[0]}/${ZT_OWRT_TARGET[1]}]."
ZT_OWRT_MUSLVER="$(wget -q "${ZT_OWRT_URL}/releases/${ZT_OWRT_VER}/targets/${ZT_OWRT_TARGET[0]}/${ZT_OWRT_TARGET[1]}" -O- \
    | awk -F'-' '{
        for (i=1;i<=NF;i++) {
            if (match($i,"musl")){
                print $i
                exit
            }
        }
    }'
)"
ZT_OWRT_SDK[0]="openwrt-sdk-${ZT_OWRT_VER}-${ZT_OWRT_TARGET[0]}-${ZT_OWRT_TARGET[1]}_gcc-${ZT_OWRT_MUSLVER}-x86_64"
ZT_OWRT_SDK[1]="${ZT_OWRT_URL}/releases/${ZT_OWRT_VER}/targets/${ZT_OWRT_TARGET[0]}/${ZT_OWRT_TARGET[1]}/${ZT_OWRT_SDK}.tar.xz"
ZT_OWRT_DIRS[0]="${ZT_WORKDIR}/${ZT_OWRT_SDK[0]}/build_dir"
ZT_OWRT_DIRS[1]="${ZT_WORKDIR}/${ZT_OWRT_SDK[0]}/staging_dir"
wget "${ZT_OWRT_SDK[1]}" -O ${ZT_OWRT_SDK[0]}.tar.xz || GTE ${ZT_STEP}
xz -d "${ZT_OWRT_SDK[0]}.tar.xz" || GTE ${ZT_STEP}
tar -xf "${ZT_OWRT_SDK[0]}.tar" && rm -f "${ZT_OWRT_SDK[0]}.tar" || GTE ${ZT_STEP}
ZT_OWRT_BUILDTARGET="$(find "${ZT_OWRT_DIRS[1]}" -maxdepth 1 -name "target-*" -printf "%P" || GTE ${ZT_STEP})"
ZT_OWRT_BUILDTOOLCHAIN[0]="$(find "${ZT_OWRT_DIRS[1]}" -maxdepth 1 -name "toolchain-*" -printf "%P" || GTE ${ZT_STEP})"
ZT_OWRT_BUILDTOOLCHAIN[1]="${ZT_OWRT_DIRS[1]}/${ZT_OWRT_BUILDTOOLCHAIN[0]}"
export STAGING_DIR="${ZT_OWRT_DIRS[1]}"

###################################################
CPrint "30:43" "Begin Step $((++ZT_STEP)): Setup Build Environment Part One [Target ${ZT_OWRT_BUILDTARGET}]."
source <(find "${ZT_WORKDIR}" -type f -name info.mk -exec cat {} \;) || GTE ${ZT_STEP}
ZT_OWRT_TCINFO=(${TARGET_CROSS//-/ })
ZT_OWRT_TRIPLE="${ZT_OWRT_TCINFO[0]}-${ZT_OWRT_TCINFO[1]}-${ZT_OWRT_TCINFO[2]}"
ZT_OWRT_GCC="$(find "${ZT_WORKDIR}" -type l -name ${ZT_OWRT_TRIPLE}-gcc || GTE ${ZT_STEP})"
ZT_OWRT_GPP="$(find "${ZT_WORKDIR}" -type l -name ${ZT_OWRT_TRIPLE}-g++ || GTE ${ZT_STEP})"
cat << EOFEOF > "${ZT_WORKDIR}/toolchain.cmake"
set(triple "${ZT_OWRT_TRIPLE}")
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR "${ZT_OWRT_TCINFO[0]}")
set(CMAKE_SYSROOT "${ZT_OWRT_BUILDTOOLCHAIN[1]}")
set(CMAKE_C_COMPILER "${ZT_OWRT_GCC}")
set(CMAKE_CXX_COMPILER "${ZT_OWRT_GPP}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
EOFEOF
echo "TOOLCHAIN:"
cat "${ZT_WORKDIR}/toolchain.cmake" || GTE ${ZT_STEP}
if [[ ${ZT_USEVCPKG} == "TRUE" ]]; then
    cat << EOFEOF > "${VCPKG_ROOT}/custom-triplets/${ZT_OWRT_TCINFO[0]}-linux.cmake"
set(VCPKG_TARGET_ARCHITECTURE "${ZT_OWRT_TCINFO[0]}")
set(VCPKG_CRT_LINKAGE "dynamic")
set(VCPKG_LIBRARY_LINKAGE "dynamic")
set(VCPKG_CMAKE_SYSTEM_NAME "Linux")
set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "${ZT_WORKDIR}/toolchain.cmake")
EOFEOF
    echo "VCPKG_TRIPLE:"
    cat "${VCPKG_ROOT}/custom-triplets/${ZT_OWRT_TCINFO[0]}-linux.cmake" || GTE ${ZT_STEP}
fi

###################################################
CPrint "30:43" "Begin Step $((++ZT_STEP)): Setup Build Environment Part Two [Target ${ZT_OWRT_BUILDTARGET}]."
ZT_OWRT_CMAKEOPTS[((i++))]="-DDISABLE_LIBSYSTEMD_FEATURE=ON"
[[ -x "/usr/bin/ninja" ]] && ZT_OWRT_CMAKEOPTS[((i++))]="-G Ninja"
ZT_OWRT_CMAKEOPTS[((i++))]="-DTLSUV_TLSLIB=mbedtls"
ZT_OWRT_CMAKEOPTS[((i++))]="-DUSE_MBEDTLS=ON"
ZT_OWRT_CMAKEOPTS[((i++))]="-DHAVE_LIBSODIUM=ON"
ZT_OWRT_CMAKEOPTS[((i++))]="-DCMAKE_TOOLCHAIN_FILE=${ZT_WORKDIR}/toolchain.cmake"
ZT_OWRT_CMAKEOPTS[((i++))]="-DGIT_VERSION=${ZT_TUNVER}"
ZT_OWRT_CMAKEOPTS[((i++))]="-S ${ZT_WORKDIR}/ziti-tunnel-sdk-c-${ZT_TUNVER}"
ZT_OWRT_CMAKEOPTS[((i++))]="-B ${ZT_WORKDIR}/ziti-tunnel-sdk-c-${ZT_TUNVER}/build"
echo "CMAKE OPTIONS: [${ZT_OWRT_CMAKEOPTS[@]}]."

###################################################
if [[ ${ZT_USEVCPKG} == "TRUE" ]]; then
    CPrint "30:43" "Begin Step $((++ZT_STEP)): Build Dependencies via VCPKG [Target ${ZT_OWRT_BUILDTARGET}]."
    cd "${VCPKG_ROOT}"
    ./vcpkg install zlib:${ZT_OWRT_TCINFO[0]}-linux --overlay-triplets=custom-triplets || GTE ${ZT_STEP}
    ./vcpkg install mbedtls:${ZT_OWRT_TCINFO[0]}-linux --overlay-triplets=custom-triplets || GTE ${ZT_STEP}
    cp -vr "installed/${ZT_OWRT_TCINFO[0]}-linux"/* "${ZT_OWRT_BUILDTOOLCHAIN[1]}" || GTE ${ZT_STEP}
    cd -
else
    CPrint "30:43" "Skipping Step $((++ZT_STEP)): Build Dependencies via VCPKG - Not Required."
fi

###################################################
CPrint "30:43" "Begin Step $((++ZT_STEP)): Configure Build [Target ${ZT_OWRT_BUILDTARGET}]."
cmake ${ZT_OWRT_CMAKEOPTS[@]} || GTE ${ZT_STEP}

###################################################
CPrint "30:43" "Begin Step $((++ZT_STEP)): Pre-Build Modifications."
sed -i '/# if ! __GNUC_PREREQ(4,9)/,+2d' "${ZT_WORKDIR}/ziti-tunnel-sdk-c-${ZT_TUNVER}/build/_deps/ziti-sdk-c-src/inc_internal/metrics.h" || GTE ${ZT_STEP}

###################################################
CPrint "30:43" "Begin Step $((++ZT_STEP)): Build [Target ${ZT_OWRT_BUILDTARGET}]."
cmake --build "${ZT_WORKDIR}/ziti-tunnel-sdk-c-${ZT_TUNVER}/build" --target "ziti-edge-tunnel" || GTE ${ZT_STEP}

###################################################
CPrint "30:43" "Begin Step $((++ZT_STEP)): Compress and Move Binary [Location ${ZT_WORKDIR%\/*}/${ZT_WORKDIR##*\/}.gz]."
gzip -ck9 "${ZT_WORKDIR}/ziti-tunnel-sdk-c-${ZT_TUNVER}/build/programs/ziti-edge-tunnel/ziti-edge-tunnel" > "${ZT_WORKDIR%\/*}/${ZT_WORKDIR##*\/}.gz" || GTE ${ZT_STEP}

###################################################
CPrint "30:42" "Compile and Build Complete."