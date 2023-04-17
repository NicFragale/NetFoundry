#!/bin/bash
################################################## ATTENTION ###################################################
# Instruction: Run on the router via SSH as ROOT.
MYVER="20230317: NFragale: Install and Setup Helper for OpenZITI on OpenWRT"
################################################################################################################

###################################################
# Set initial variables/functions.
ZT_WORKDIR="/tmp"
ZT_URL="${1}"
ZT_ZET=("${2}" "ziti-edge-tunnel")
ZT_DIR="/opt/netfoundry/ziti"
ZT_IDDIR="${ZT_DIR}/identities"

################################################################################################################
# DO NOT MODIFY BELOW THIS LINE
################################################################################################################
ZT_IDMANIFEST="manifest.info"
ZT_WATCH="ziti-watch"
ZT_SERVICES=("/etc/init.d/ziti-service" "/etc/init.d/ziti_watch-service")
function GetDirSize() {
    local EachDir="/${1}"
    while [[ ${EachDir} != "" ]]; do 
        [[ -d ${EachDir} ]] \
            && df ${EachDir} | awk 'NR==2{print $4}' \
            && return \
            || EachDir=${EachDir%\/*}
    done
    echo "0"
}
function CPrint() { 
    local OUT_COLOR="${1}" IN_TEXT="${2}" OUT_SCREENWIDTH OUT_PADLEN
    shopt -s checkwinsize; (:); OUT_SCREENWIDTH="${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}";
    for ((i=0;i<(OUT_SCREENWIDTH/2);i++)); do OUT_PADLEN+=' '; done    
    printf "\e[37;${OUT_COLOR}m%-${OUT_SCREENWIDTH}s\e[1;0m\n" "${OUT_PADLEN:0:-$((${#IN_TEXT}/2))}${IN_TEXT}"
}
function GTE() { 
    CPrint "45" "ERROR: Early Exit at Step ${1}."
    exit ${1}
}
if [[ ${ZT_ZET[0]} == "" ]] && [[ -f /etc/os-release ]]; then
    . /etc/os-release 2>/dev/null
    ZT_ZET[0]="OpenWRT-${VERSION}-${OPENWRT_BOARD/\//_}.gz"
fi

###################################################
CPrint "44" "[${MYVER:-UNSET VERSION}]"
CPrint "44" "WORK DIRECTORY: ${ZT_WORKDIR:=UNKNOWN}"
CPrint "44" "BUILD URL: ${ZT_URL:=UNKNOWN}"
CPrint "44" "BUILD RUNTIME: ${ZT_ZET[0]:=UNKNOWN}->${ZT_ZET[1]:=UNKNOWN}"
CPrint "44" "INSTALL DIRECTORY: ${ZT_DIR:=UNKNOWN}"
CPrint "44" "IDENTITY DIRECTORY: ${ZT_IDDIR:=UNKNOWN}"

###################################################
CPrint "41" "Begin Step $((++ZT_STEP)): Input Checking."
if [[ ${ZT_WORKDIR} == "UNKNOWN" ]] \
    || [[ ${ZT_URL} == "UNKNOWN" ]] \
    || [[ ${ZT_ZET[0]} == "UNKNOWN" ]] \
    || [[ ${ZT_ZET[1]} == "UNKNOWN" ]] \
    || [[ ${ZT_DIR} == "UNKNOWN" ]] \
    || [[ ${ZT_IDDIR} == "UNKNOWN" ]]; then
    CPrint "45" "Input Missing/Error - Please Check."
    GTE ${ZT_STEP}
fi
if [[ $(GetDirSize "${ZT_DIR}") -lt 8000 ]]; then
    ZT_ISDYNAMIC="true"
    CPrint "44" "LOW STORAGE SPACE DEVICE DETECTED - RUNNING DYNAMICALLY"
else
    ZT_ISDYNAMIC="false"
fi
sleep 5

###################################################
CPrint "41" "Begin Step $((++ZT_STEP)): Update System and Packages."
opkg update || GTE ${ZT_STEP}
opkg install libatomic1 kmod-tun sed ip-full || GTE ${ZT_STEP}

###################################################
CPrint "41" "Begin Step $((++ZT_STEP)): Create Directory Structures and Files."
mkdir -vp "${ZT_DIR}" || GTE ${ZT_STEP}
mkdir -vp "${ZT_IDDIR}" || GTE ${ZT_STEP}
[[ ! -f "${ZT_IDDIR}/${ZT_IDMANIFEST}"  ]] \
    && echo  -e "# ZITI EDGE TUNNEL IDENTITY MANIFEST - DO NOT DELETE\n# Initialized on $(date -u)" > "${ZT_IDDIR}/${ZT_IDMANIFEST}"

###################################################
CPrint "41" "Begin Step $((++ZT_STEP)): Create Runtime Service."
cat << EOFEOF > "${ZT_SERVICES[0]}"
#!/bin/sh /etc/rc.common
# Init script for NetFoundry OpenZITI (ZITI EDGE TUNNEL, OpenWRT version).
USE_PROCD=1
START=85
STOP=01
THIS_PATH="${ZT_DIR}"
THIS_IDPATH="${ZT_IDDIR}"
THIS_APP="${ZT_ZET[1]}"
THIS_PIDFILE="/var/run/\${THIS_APP}.pid"
THIS_RUNOPTIONS="run -I \${THIS_IDPATH}"
THIS_MANIFEST="manifest.info"

start_service() {
    logger -t \${THIS_APP} "Starting \${THIS_APP}."
    THIS_UPSTREAMDNS="-u \$(grep -oEm1 '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' /tmp/resolv.conf.d/resolv.conf.auto || echo 1.1.1.1)"
    procd_open_instance
    procd_set_param command "\${THIS_PATH}/\${THIS_APP}" \${THIS_RUNOPTIONS} \${THIS_UPSTREAMDNS}
    procd_set_param respawn 600 5 5
    procd_set_param file "\${THIS_IDPATH}/\${THIS_MANIFEST}"
    procd_set_param pidfile \${THIS_PIDFILE}
    procd_set_param limits core="unlimited"
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_close_instance
}

stop_service() {
    logger -t \${THIS_APP} "Stopping \${THIS_APP}."
    start-stop-daemon -K -p \${THIS_PIDFILE} -s TERM
}
EOFEOF
chmod 755 "${ZT_SERVICES[0]}" || GTE ${ZT_STEP}

###################################################
CPrint "41" "Begin Step $((++ZT_STEP)): Create ZITI Watch Service."
cat << EOFEOF > "${ZT_SERVICES[1]}"
#!/bin/sh /etc/rc.common
# Init script for NetFoundry OpenZITI (WATCH, OpenWRT version).
USE_PROCD=1
START=86
STOP=01
THIS_PATH="${ZT_DIR}"
THIS_APP="${ZT_WATCH}"
THIS_PIDFILE="/var/run/\${THIS_APP}.pid"
THIS_RUNOPTIONS="60"

start_service() {
    logger -t \${THIS_APP} "Starting \${THIS_APP}."
    procd_open_instance
    procd_set_param command "\${THIS_PATH}/\${THIS_APP}" \${THIS_RUNOPTIONS}
    procd_set_param respawn 600 5 5
    procd_set_param pidfile \${THIS_PIDFILE}
    procd_set_param limits core="unlimited"
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_close_instance
}

stop_service() {
    logger -t \${THIS_APP} "Stopping \${THIS_APP}."
    start-stop-daemon -K -p \${THIS_PIDFILE} -s TERM
}
EOFEOF
chmod 755 "${ZT_SERVICES[1]}" || GTE ${ZT_STEP}

###################################################
CPrint "41" "Begin Step $((++ZT_STEP)): Create ZITI Watch."
cat << EOFEOF > "${ZT_DIR}/${ZT_WATCH}"
#!/bin/bash
# Trigger system for NetFoundry OpenZITI.
SLEEPTIME="\${1}"
ZT_URL="${ZT_URL}"
ZT_ZET=("${ZT_ZET[0]}" "${ZT_ZET[1]}")
ZT_WORKDIR="${ZT_WORKDIR}"
ZT_DIR="${ZT_DIR}"
ZT_IDDIR="${ZT_IDDIR}"
ZT_IDMANIFEST="${ZT_IDMANIFEST}"
ZT_SERVICES=("${ZT_SERVICES[0]}" "${ZT_SERVICES[1]}")
while true; do
    # Show a log message every 10 iterations.
    if [[ \$((++ZW_ITR%10)) -eq 1 ]]; then
        echo "ZITIWATCH CYCLE [\${ZW_ITR}]"
    fi
    # LOW STORAGE DEVICE FUNCTION: Attempt to obtain the runtime if not present.
    if ${ZT_ISDYNAMIC} && [[ ! -f \${ZTWORKDIR}/\${ZT_ZET[1]} ]]; then
        echo "[\${ZW_ITR}] DYNAMIC MODE, OBTAINING RUNTIME"
	    wget "\${ZT_URL}/\${ZT_ZET[0]}" -O "\${ZT_WORKDIR}/\${ZT_ZET[0]}" \
            && gzip -fdc "\${ZT_WORKDIR}/\${ZT_ZET[0]}" > "\${ZT_WORKDIR}/\${ZT_ZET[1]}" \
            && ln -sf "\${ZT_WORKDIR}/\${ZT_ZET[1]}" "\${ZT_DIR}/\${ZT_ZET[1]}" \
            && chmod 755 "\${ZT_WORKDIR}/\${ZT_ZET[1]}" \
            && "\${ZT_SERVICES[1]}" reload \
            && rm -f "\${ZT_WORKDIR}/\${ZT_ZET[0]}" \
            && echo "[\${ZW_ITR}] SUCCESS: Obtained Runtime" \
            || echo "[\${ZW_ITR}] FAILED: Could Not Obtain Runtime"
    fi    
    # Cycle any available JWTs.
    while IFS=$'\n' read -r EachJWT; do
        echo "[\${ZW_ITR}] ENROLLING: \${EachJWT}"
        if "\${ZT_DIR}/\${ZT_ZET[1]}" enroll -j "\${EachJWT}" -i "\${EachJWT/.jwt/.json}"; then
            echo "[\${ZW_ITR}] SUCCESS: \${EachJWT/.jwt/.json}"
            echo "[\$(date -u)] ADDED \${EachJWT/.jwt/}" >> "\${ZT_IDDIR}/\${ZT_IDMANIFEST}"
            rm -f "\${EachJWT}"
            sleep 3
            # Reload the daemon if any changes were flagged.
            \${ZT_SERVICES[0]} reload            
        else
            echo "[\${ZW_ITR}] FAILED: \${EachJWT}.ENROLLFAIL"
            mv -vf "\${EachJWT}" "\${EachJWT}.ENROLLFAIL"
            rm -f "\${EachJWT/.jwt/.json}"
        fi
    done < <(find \${ZT_IDDIR} -name *.jwt)

    # Sleep until the next round.
    sleep \${SLEEPTIME:-60}
done
EOFEOF
chmod 755 "${ZT_DIR}/${ZT_WATCH}" || GTE ${ZT_STEP}

###################################################
if ${ZT_ISDYNAMIC}; then
    CPrint "41" "Skipping Step $((++ZT_STEP)): Dynamic Runtime Mode."
elif [[ -f "${ZT_WORKDIR}/${ZT_ZET[1]}" ]]; then
    CPrint "41" "Skipping Step $((++ZT_STEP)): Uncompressed Runtime Present [Location ${ZT_WORKDIR}/${ZT_ZET[1]}]."
else
    if [[ -f "${ZT_WORKDIR}/${ZT_ZET[0]}" ]]; then
        CPrint "41" "Skipping Step $((++ZT_STEP)): Compressed Runtime Present [Location ${ZT_WORKDIR}/${ZT_ZET[0]}]."
    else
        CPrint "41" "Begin Step $((++ZT_STEP)): Obtaining Compressed Runtime [${ZT_ZET[0]}]."
        wget "${ZT_URL}/${ZT_ZET[0]}" -O "${ZT_WORKDIR}/${ZT_ZET[0]}" || GTE ${ZT_STEP}
    fi
    CPrint "41" "Begin Step $((++ZT_STEP)): Decompress Runtime."
    gzip -fdc "${ZT_WORKDIR}/${ZT_ZET[0]}" > "${ZT_WORKDIR}/${ZT_ZET[1]}" || GTE ${ZT_STEP}
fi

###################################################
if ${ZT_ISDYNAMIC}; then
    CPrint "41" "Skipping Step $((++ZT_STEP)): Dynamic Runtime Mode."
else
    CPrint "41" "Begin Step $((++ZT_STEP)): Setup Runtime."
    mv -vf "${ZT_WORKDIR}/${ZT_ZET[1]}" "${ZT_DIR}" || GTE ${ZT_STEP}
    rm -f "${ZT_WORKDIR}/${ZT_ZET[0]}" "${ZT_WORKDIR}/${ZT_ZET[1]}" || GTE ${ZT_STEP}
    chmod 755 "${ZT_DIR}/${ZT_ZET[1]}" || GTE ${ZT_STEP}
    ZT_BINARYVER="$(${ZT_DIR}/${ZT_ZET[1]} version || echo UNKNOWN)"
    [[ ${ZT_BINARYVER} == "UNKNOWN" ]] \
        && GTE ${ZT_STEP} \
        || echo "ZITI EDGE TUNNEL VERSION: ${ZT_BINARYVER}"
fi

###################################################
CPrint "41" "Begin Step $((++ZT_STEP)): Permit of Sockets."
if [[ -f "/etc/group" ]] && ! grep -q "ziti" "/etc/group"; then
    echo 'ziti:x:99:' >> /etc/group
fi

###################################################
CPrint "41" "Begin Step $((++ZT_STEP)): Enabling and Starting Services."
${ZT_SERVICES[0]} enable || GTE ${ZT_STEP}
${ZT_SERVICES[1]} enable || GTE ${ZT_STEP}
${ZT_SERVICES[0]} start || GTE ${ZT_STEP}
${ZT_SERVICES[1]} start || GTE ${ZT_STEP}

###################################################
CPrint "44" "Install and Setup Complete."