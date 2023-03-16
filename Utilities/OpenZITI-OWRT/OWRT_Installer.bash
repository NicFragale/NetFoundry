#!/bin/bash
################################################## ATTENTION ###################################################
# Instruction: Run on the router via SSH as ROOT.
ZT_BVER="20230301: NFragale: Install and Setup Helper for OpenZITI on OpenWRT"
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
ZT_PADLINE=""
ZT_SWIDTH="${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}"
for ((i=0;i<(ZT_SWIDTH/2);i++)); do ZT_PADLINE+=' '; done
function CPrint() { local INPUT="${1:0:${ZT_SWIDTH}}"; printf "\e[37;41m%-${ZT_SWIDTH}s\e[1;0m\n" "${ZT_PADLINE:0:-$((${#INPUT}/2))}${INPUT}"; }
function GTE() { CPrint "ERROR: Early Exit at Step ${1}." && exit ${1}; }

###################################################
CPrint "[${ZT_BVER}]"
CPrint "[WORKING DIRECTORY ${ZT_WORKDIR}]"
CPrint "[URL ${ZT_URL:0:30}...${ZT_ZET[0]}]"
CPrint "[ZITI DIRECTORY ${ZT_DIR}]"
CPrint "[ZITI IDENTITY DIRECTORY ${ZT_DIR}]"
sleep 5

###################################################
CPrint "Begin Step $((++ZT_STEP)): Update System and Packages."
opkg update || GTE ${ZT_STEP}
opkg install libatomic1 kmod-tun sed ip-full bash || GTE ${ZT_STEP}

###################################################
CPrint "Begin Step $((++ZT_STEP)): Create Directory Structures and Files."
mkdir -vp "${ZT_DIR}" || GTE ${ZT_STEP}
mkdir -vp "${ZT_IDDIR}" || GTE ${ZT_STEP}
[[ ! -f "${ZT_IDDIR}/${ZT_IDMANIFEST}"  ]] \
    && echo  -e "# ZITI EDGE TUNNEL IDENTITY MANIFEST - DO NOT DELETE\n# Initialized on $(date -u)" > "${ZT_IDDIR}/${ZT_IDMANIFEST}"

###################################################
CPrint "Begin Step $((++ZT_STEP)): Create Runtime Service."
cat << EOFEOF > "${ZT_SERVICES[0]}"
#!/bin/sh /etc/rc.common
# Init script for NetFoundry OpenZITI (ZITI EDGE TUNNEL, OpenWRT version).
USE_PROCD=1
START=85
STOP=01
ZETPATH="${ZT_DIR}"
ZETIDPATH="${ZT_IDDIR}"
ZETAPP="${ZT_ZET[1]}"
PID_FILE="/var/run/\${ZETAPP}.pid"
ZETOPTIONS="run -I \${ZETIDPATH}"
ZETMANIFEST="manifest.info"

start_service() {
    ZETUPSTREAMDNS="-u \$(grep -oEm1 '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' /tmp/resolv.conf.d/resolv.conf.auto || echo 1.1.1.1)"
    procd_open_instance
    procd_set_param command "\${ZETPATH}/\${ZETAPP}" \${ZETOPTIONS} \${ZETUPSTREAMDNS}
    procd_set_param respawn 600 5 5
    procd_set_param file "\${ZETIDPATH}/\${ZETMANIFEST}"
    procd_set_param \${PID_FILE}
    procd_set_param limits core="unlimited"
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_close_instance
}

stop_service() {
    start-stop-daemon -K -p \$PID_FILE -s TERM
    rm -rf \$PID_FILE
}
EOFEOF
chmod 755 "${ZT_SERVICES[0]}" || GTE ${ZT_STEP}

###################################################
CPrint "Begin Step $((++ZT_STEP)): Create EnrollWatch Service."
cat << EOFEOF > "${ZT_SERVICES[1]}"
#!/bin/sh /etc/rc.common
# Init script for NetFoundry OpenZITI (WATCH, OpenWRT version).
USE_PROCD=1
START=86
STOP=01
ZETWPATH="${ZT_DIR}"
ZETWAPP="${ZT_WATCH}"
PID_FILE="/var/run/\${ZETWAPP}.pid"
ZETWOPTIONS="60"

start_service() {
    procd_open_instance
    procd_set_param command "\${ZETWPATH}/\${ZETWAPP}" \${ZETWOPTIONS}
    procd_set_param respawn 600 5 5
    procd_set_param \${PID_FILE}
    procd_set_param limits core="unlimited"
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_close_instance
}

stop_service() {
    start-stop-daemon -K -p \$PID_FILE -s TERM
    rm -rf \$PID_FILE
}
EOFEOF
chmod 755 "${ZT_SERVICES[1]}" || GTE ${ZT_STEP}

###################################################
CPrint "Begin Step $((++ZT_STEP)): Create ZITIWatch."
cat << EOFEOF > "${ZT_DIR}/${ZT_WATCH}"
#!/bin/bash
# Trigger system for NetFoundry OpenZITI.
SLEEPTIME=\$1
while true; do
    # Reload the daemon if any changes were flagged.
    ${ZT_SERVICES[0]} reload
    [[ \$((++ZW_ITR%10)) -eq 0 ]] \
        echo "> ZITIWATCH CYCLE [\${ZW_ITR}]"
    # Cycle any available JWTs.
    while IFS=$'\n' read -r EachJWT; do
        echo ">> ENROLLING: \${EachJWT}"
        if "${ZT_DIR}/${ZT_ZET[1]}" enroll -j "\${EachJWT}" -i "\${EachJWT/.jwt/.json}"; then
            echo ">>> SUCCESS: \${EachJWT/.jwt/.json}"
            echo "[\$(date -u)] ADDED \${EachJWT/.jwt/}" >> "${ZT_IDDIR}/${ZT_IDMANIFEST}"
            rm -f "\${EachJWT}"
        else
            echo ">>> FAILED: \${EachJWT}.ENROLLFAIL"
            mv -vf "\${EachJWT}" "\${EachJWT}.ENROLLFAIL"
            rm -f "\${EachJWT/.jwt/.json}"
        fi
    done < <(find ${ZT_DIR}/identities -name *.jwt)

    # Sleep until the next round.
    sleep \${SLEEPTIME:-60}
done
EOFEOF
chmod 755 "${ZT_DIR}/${ZT_WATCH}" || GTE ${ZT_STEP}

###################################################
if [[ -f "${ZT_WORKDIR}/${ZT_ZET[1]}" ]]; then
    CPrint "Skipping Step $((++ZT_STEP)): Uncompressed Runtime Already Present [Location ${ZT_WORKDIR}/${ZT_ZET[1]}]."
else
    if [[ -f "${ZT_WORKDIR}/${ZT_ZET[0]}" ]]; then
        CPrint "Skipping Step $((++ZT_STEP)): Compressed Runtime Already Present [Location ${ZT_WORKDIR}/${ZT_ZET[0]}]."
    else
        CPrint "Begin Step $((++ZT_STEP)): Obtaining Compressed Runtime [${ZT_ZET[0]}]."
        wget "${ZT_URL}/${ZT_ZET[0]}" -O "${ZT_WORKDIR}/${ZT_ZET[0]}" || GTE ${ZT_STEP}
    fi
    CPrint "Begin Step $((++ZT_STEP)): Decompress Runtime."
    gzip -fdc "${ZT_WORKDIR}/${ZT_ZET[0]}" > "${ZT_WORKDIR}/${ZT_ZET[1]}" || GTE ${ZT_STEP}
fi

###################################################
CPrint "Begin Step $((++ZT_STEP)): Setup Runtime."
mv -vf "${ZT_WORKDIR}/${ZT_ZET[1]}" "${ZT_DIR}" || GTE ${ZT_STEP}
rm -f "${ZT_WORKDIR}/${ZT_ZET[0]}" "${ZT_WORKDIR}/${ZT_ZET[1]}" || GTE ${ZT_STEP}
chmod 755 "${ZT_DIR}/${ZT_ZET[1]}" || GTE ${ZT_STEP}
ZT_BINARYVER="$(${ZT_DIR}/${ZT_ZET[1]} version || echo UNKNOWN)"
[[ ${ZT_BINARYVER} == "UNKNOWN" ]] \
    && GTE ${ZT_STEP} \
    || echo "ZITI EDGE TUNNEL VERSION: ${ZT_BINARYVER}"

###################################################
CPrint "Begin Step $((++ZT_STEP)): Enabling and Starting Services."
${ZT_SERVICES[0]} enable || GTE ${ZT_STEP}
${ZT_SERVICES[1]} enable || GTE ${ZT_STEP}
${ZT_SERVICES[0]} start || GTE ${ZT_STEP}
${ZT_SERVICES[1]} start || GTE ${ZT_STEP}

###################################################
CPrint "Install and Setup Complete."