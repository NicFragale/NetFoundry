#!/bin/bash
################################################## ATTENTION ###################################################
# Instruction: Run on the build server as a BUILD CAPABLE USER (ROOT is assumed in this example).
ZT_BVER="20230301: NFragale: Compile and Build Helper for OpenZITI on OpenWRT"
################################################################################################################

###################################################
# Set initial variables/functions.
ZT_TUNVER="${1:-latest}"
ZT_OWRTVER="${2:-22.03.3}"
ZT_OWRTTARGET=("${3:-ath79}" "${4:-nand}")

################################################################################################################
# DO NOT MODIFY BELOW THIS LINE 
################################################################################################################
ZT_WORKDIR="$(pwd)/OpenWRT-${ZT_OWRTVER}-${ZT_OWRTTARGET[0]}_${ZT_OWRTTARGET[1]}"
ZT_STEP=0
ZT_TCINFO="UNSET"
ZT_TCTRIPLE="UNSET"
ZT_TCGCC="UNSET"
ZT_TCGPP="UNSET"
ZT_BINC="UNSET"
ZT_PADLINE=""
ZT_SWIDTH="${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}"
for ((i=0;i<(ZT_SWIDTH/2);i++)); do ZT_PADLINE+=' '; done
function CPrint() { printf "\e[37;41m%-${ZT_SWIDTH}s\e[1;0m\n" "${ZT_PADLINE:0:-$((${#1}/2))}${1}"; }
function GTE() { CPrint "ERROR: Early Exit at Step ${1}." && exit ${1}; }

###################################################
CPrint "[${ZT_BVER}]"
CPrint "[ZITI EDGE TUNNEL VERSION ${ZT_TUNVER}] [OPENWRT VERSION ${ZT_OWRTVER}] [OPENWRT TARGET ${ZT_OWRTTARGET[0]}/${ZT_OWRTTARGET[1]}]"
sleep 5

###################################################
CPrint "Begin Step $((++ZT_STEP)): Create Staging Area [Location ${ZT_WORKDIR}]."
mkdir -v "${ZT_WORKDIR}" && cd "${ZT_WORKDIR}" || GTE ${ZT_STEP}

###################################################
CPrint "Begin Step $((++ZT_STEP)): Acquire Additional Software."
apt update
apt install -y build-essential clang flex bison g++ gawk gcc-multilib gettext git libncurses5-dev libssl-dev python3-distutils rsync unzip zlib1g-dev file wget curl || GTE ${ZT_STEP}

###################################################
CPrint "Begin Step $((++ZT_STEP)): Acquire ZITI EDGE TUNNEL Source [Version ${ZT_TUNVER}]."
if [[ ${ZT_TUNVER:-latest} == "latest" ]]; then
    ZT_ALLVERSIONS=( $(curl -Ls 'https://github.com/openziti/ziti-tunnel-sdk-c/tags' \
	    | awk '/tags/{if(match($0,/v[0-9].[0-9]+.[0-9]+/)){ALLVERSIONS[substr($0,RSTART,RLENGTH)]++}}END{for(EACHVERSION in ALLVERSIONS){gsub("v","",EACHVERSION);print EACHVERSION}}' \
	    | sort -rnt '.' -k1,1 -k2,2 -k3,3)
    )
    ZT_TUNVER="${ZT_ALLVERSIONS[0]}"
fi
wget "https://github.com/openziti/ziti-tunnel-sdk-c/archive/refs/tags/v${ZT_TUNVER}.zip" -O "${ZT_WORKDIR}/ziti-tunnel-sdk-c.zip" || GTE ${ZT_STEP}
unzip "${ZT_WORKDIR}/ziti-tunnel-sdk-c.zip" || GTE ${ZT_STEP}

###################################################
CPrint "Begin Step $((++ZT_STEP)): Acquire OpenWRT SDK [Version ${ZT_OWRTVER}] [Target ${ZT_OWRTTARGET[0]}/${ZT_OWRTTARGET[1]}]."
ZT_OWRTMUSLVER="$(wget -q "https://downloads.openwrt.org/releases/${ZT_OWRTVER}/targets/${ZT_OWRTTARGET[0]}/${ZT_OWRTTARGET[1]}" -O- | \
    awk '/musl/{match($0,/([0-9]+\.){1,}[0-9]+_musl/);print substr($0,RSTART,RLENGTH)}')"
ZT_OWRTSDK="openwrt-sdk-${ZT_OWRTVER}-${ZT_OWRTTARGET[0]}-${ZT_OWRTTARGET[1]}_gcc-${ZT_OWRTMUSLVER:-ERROR}.Linux-x86_64"
ZT_OWRTSDKURL="https://downloads.openwrt.org/releases/${ZT_OWRTVER}/targets/${ZT_OWRTTARGET[0]}/${ZT_OWRTTARGET[1]}/${ZT_OWRTSDK}.tar.xz"
ZT_BUILDSTAGEDIR="${ZT_WORKDIR}/${ZT_OWRTSDK}/staging_dir/"
wget "${ZT_OWRTSDKURL}" || GTE ${ZT_STEP}
xz -d "${ZT_OWRTSDK}.tar.xz" || GTE ${ZT_STEP}
tar -xf "${ZT_OWRTSDK}.tar" && rm -f "${ZT_OWRTSDK}.tar" || GTE ${ZT_STEP}
ZT_BUILDTARGET="$(find "${ZT_BUILDSTAGEDIR}" -maxdepth 1 -name "target-*" -printf "%P" || GTE ${ZT_STEP})"
ZT_BUILDTARGETDIR="${ZT_BUILDSTAGEDIR}/${ZT_BUILDTARGET}"

###################################################
CPrint "Begin Step $((++ZT_STEP)): Setup Build Environment Part One [Target ${ZT_BUILDTARGET}]."
source <(find "${ZT_WORKDIR}" -type f -name info.mk -exec cat {} \;) || GTE ${ZT_STEP}
ZT_TCINFO=(${TARGET_CROSS//-/ })
ZT_TCTRIPLE="${ZT_TCINFO[0]}-${ZT_TCINFO[1]}-${ZT_TCINFO[2]}"
ZT_TCGCC="$(find "${ZT_WORKDIR}" -type l -name ${ZT_TCTRIPLE}-gcc || GTE ${ZT_STEP})"
ZT_TCGPP="$(find "${ZT_WORKDIR}" -type l -name ${ZT_TCTRIPLE}-g++ || GTE ${ZT_STEP})"
ZT_BINC="$(find "${ZT_BUILDTARGETDIR}/usr" -type d -name include || GTE ${ZT_STEP})"
cp -v /usr/include/zlib.h "${ZT_BINC}" || GTE ${ZT_STEP}
cp -v /usr/include/zconf.h "${ZT_BINC}" || GTE ${ZT_STEP}
cat << EOFEOF > "${ZT_WORKDIR}/toolchain.cmake"
set(triple "${ZT_TCTRIPLE}")
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR "${ZT_TCINFO[0]}")
set(CMAKE_SYSROOT "${ZT_BUILDTARGETDIR}")
set(CMAKE_C_COMPILER "${ZT_TCGCC}")
set(CMAKE_CXX_COMPILER "${ZT_TCGPP}")
set(INCLUDE_DIRECTORIES "${ZT_BINC}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
EOFEOF
cat toolchain.cmake || GTE ${ZT_STEP}

###################################################
CPrint "Begin Step $((++ZT_STEP)): Setup Build Environment Part Two [Target ${ZT_BUILDTARGET}]."
ZT_CMAKE_OPTS="-DDISABLE_LIBSYSTEMD_FEATURE=on -DCMAKE_C_FLAGS=-I${ZT_BINC}"
[[ -x /usr/bin/ninja ]] && ZT_CMAKE_OPTS="${ZT_CMAKE_OPTS} -G Ninja"
[[ -f "${ZT_BUILDTARGETDIR}/usr/include/openssl/opensslv.h" ]] && ZT_CMAKE_OPTS="${ZT_CMAKE_OPTS} -DUSE_OPENSSL=on"
[[ -f "${ZT_BUILDTARGETDIR}/usr/include/sodium.h" ]] && ZT_CMAKE_OPTS="${ZT_CMAKE_OPTS} -DHAVE_LIBSODIUM=on"
[[ -f "${ZT_BUILDTARGETDIR}/usr/include/uv.h" ]] && ZT_CMAKE_OPTS="${ZT_CMAKE_OPTS} -DHAVE_LIBUV=on"
ZT_CMAKE_OPTS="${ZT_CMAKE_OPTS} -DCMAKE_TOOLCHAIN_FILE=${ZT_WORKDIR}/toolchain.cmake -DGIT_VERSION=${ZT_TUNVER}"
echo "CMAKE OPTIONS: [${ZT_CMAKE_OPTS}]."

###################################################
CPrint "Begin Step $((++ZT_STEP)): Compile [Target ${ZT_BUILDTARGET}]."
export STAGING_DIR="${ZT_WORKDIR}/${ZT_OWRTSDK}/staging_dir"
cmake ${ZT_CMAKE_OPTS} "${ZT_WORKDIR}/ziti-tunnel-sdk-c-${ZT_TUNVER}" || GTE ${ZT_STEP}
sed -i '/# if ! __GNUC_PREREQ(4,9)/,+2d' "${ZT_WORKDIR}/_deps/ziti-sdk-c-src/inc_internal/metrics.h" || GTE ${ZT_STEP}

###################################################
CPrint "Begin Step $((++ZT_STEP)): Build [Target ${ZT_BUILDTARGET}]."
cmake --build "${ZT_WORKDIR}" --target "ziti-edge-tunnel" || GTE ${ZT_STEP}

###################################################
CPrint "Begin Step $((++ZT_STEP)): Compress Binary."
gzip -k9 programs/ziti-edge-tunnel/ziti-edge-tunnel || GTE ${ZT_STEP}

###################################################
CPrint "Begin Step $((++ZT_STEP)): Move Compressed Binary [Location $(pwd)]."
mv -vf programs/ziti-edge-tunnel/ziti-edge-tunnel.gz ./ || GTE ${ZT_STEP}

###################################################
CPrint "Compile and Build Complete."