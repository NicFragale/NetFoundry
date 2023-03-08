#!/bin/bash
################################################## ATTENTION ###################################################
# Instruction: Run on the router via SSH as ROOT.
################################################################################################################

###################################################
# Set initial variables/functions.
ZT_BVER="20230301: NFragale: Install and Setup Helper for OpenZITI on OpenWRT"
ZT_URL="https://fragale.us/PDATA"
ZT_DIR="/opt/netfoundry/ziti"
ZT_ZET=("ziti-edge-tunnel" "gz")
ZT_EW="ziti-enrollwatch"
ZT_SERVICES=("/etc/init.d/ziti-service" "/etc/init.d/ziti_enrollwatch-service")
ZT_PADLINE=""
ZT_SWIDTH="${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}"
for ((i=0;i<(ZT_SWIDTH/2);i++)); do ZT_PADLINE+=' '; done
function CPrint() { printf "\e[37;41m%-${ZT_SWIDTH}s\e[1;0m\n" "${ZT_PADLINE:0:-$((${#1}/2))}${1}"; }
function GTE() { CPrint "ERROR: Early Exit at Step ${1}." && exit ${1}; }

CPrint "[${ZT_BVER}]"

###################################################
CPrint "Begin Step $((++ZT_STEP)): Create Directory Structures."
mkdir -vp "${ZT_DIR}" || GTE ${ZT_STEP}

###################################################
CPrint "Begin Step $((++ZT_STEP)): Create Runtime Service."
cat << EOFEOF > "${ZT_SERVICES[0]}"
#!/bin/sh /etc/rc.common
# Init script for NetFoundry OpenZITI (ZITI EDGE TUNNEL, OpenWRT version).
USE_PROCD=1
START=85
STOP=01
ZETPATH="${ZT_DIR}"
ZETIDPATH="${ZT_DIR}/identities"
ZETAPP="${ZT_ZET}"
PID_FILE="/var/run/\${ZETAPP}.pid"
ZETOPTIONS="run -I \${ZTIDPATH}"

start_service() {
    procd_open_instance
    procd_set_param command "\${ZETPATH}/\${ZETAPP}" \${ZETOPTIONS}
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
chmod 755 "${ZT_SERVICES[0]}" || GTE ${ZT_STEP}

###################################################
CPrint "Begin Step $((++ZT_STEP)): Create EnrollWatch Service."
cat << EOFEOF > "${ZT_SERVICES[1]}"
#!/bin/sh /etc/rc.common
# Init script for NetFoundry OpenZITI (ENROLL WATCH, OpenWRT version).
USE_PROCD=1
START=86
STOP=01
ZETEWPATH="${ZT_DIR}"
ZETEWAPP="${ZT_EW}"
PID_FILE="/var/run/${ZT_EW}.pid"
ZETEWOPTIONS="60"

start_service() {
    procd_open_instance
    procd_set_param command "\${ZETEWPATH}/\${ZETEWAPP}" \${ZETEWOPTIONS}
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
CPrint "Begin Step $((++ZT_STEP)): Create EnrollWatch."
cat << EOFEOF > "${ZT_DIR}/${ZT_EW}"
#!/bin/bash
# Enrollment trigger system for NetFoundry OpenZITI.
SLEEPTIME=\$1
while true; do
    # Cycle any available JWTs.
    echo "> ENROLLLWATCH CYCLE [\$((++EW_ITR))]"
    while IFS=$'\n' read -r EachJWT; do
        echo ">> ENROLLING: \${EachJWT}"
        if "${ZT_DIR}/${ZT_ZET[0]}" enroll -j "\${EachJWT}" -i "\${EachJWT/.jwt/.json}"; then
            echo ">>> SUCCESS: \${EachJWT/.jwt/.json}"
            rm -f "\${EachJWT}"
        else
            echo ">>> FAILED: \${EachJWT}.ENROLLFAIL"
            mv -vf "\${EachJWT}" "\${EachJWT}.ENROLLFAIL"
        fi
    done < <(find ${ZT_DIR}/identities -name *.jwt)

    # Sleep until the next round.
    sleep \${SLEEPTIME:-60}
done
EOFEOF
chmod 755 "${ZT_DIR}/${ZT_EW}" || GTE ${ZT_STEP}

###################################################
CPrint "Begin Step $((++ZT_STEP)): Obtaining Runtime."
wget --no-check-certificate "${ZT_URL}/${ZT_ZET[0]}.${ZT_ZET[1]}" -O "/tmp/${ZT_ZET[0]}.${ZT_ZET[1]}" || GTE ${ZT_STEP}

###################################################
CPrint "Begin Step $((++ZT_STEP)): Setup of Runtime."
gzip -fd "/tmp/${ZT_ZET[0]}.${ZT_ZET[1]}" || GTE ${ZT_STEP}
mv "/tmp/${ZT_ZET[0]}" "${ZT_DIR}" || GTE ${ZT_STEP}
rm -f "/tmp/${ZT_ZET[0]}.${ZT_ZET[1]}" || GTE ${ZT_STEP}
chmod 755 "${ZT_DIR}/${ZT_ZET}" || GTE ${ZT_STEP}
echo "ZITI EDGE TUNNEL VERSION: $(${ZT_DIR}/${ZT_ZET} version || echo UNKNOWN)" || GTE ${ZT_STEP}

###################################################
CPrint "Begin Step $((++ZT_STEP)): Enabling and Starting Services."
${ZT_SERVICES[0]} enable || GTE ${ZT_STEP}
${ZT_SERVICES[1]} enable || GTE ${ZT_STEP}
${ZT_SERVICES[0]} start || GTE ${ZT_STEP}
${ZT_SERVICES[1]} start || GTE ${ZT_STEP}

###################################################
CPrint "Install and Setup Complete."