#!/bin/bash
################################################## ATTENTION ###################################################
# Instruction: Run on the router via SSH as ROOT.
MYVER="20230412: NFragale: Manipulates WiFi as an access point.  WARNING: Supports only GL.iNet GL-AR300M16"
################################################################################################################

###################################################
# Set initial variables/functions.
ZT_DIR="/opt/netfoundry/ziti"
ZT_WIFI_NAME="Router Config AP"
ZT_WIFI_PASS="MAINT-NET-ENTRY"

################################################################################################################
# DO NOT MODIFY BELOW THIS LINE
################################################################################################################
ZT_WIFIMAINT="wifi_maint"
ZT_SERVICES=("/etc/init.d/wifi_maint-service")
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

###################################################
CPrint "44" "[${MYVER:-UNSET VERSION}]"
CPrint "44" "INSTALL DIRECTORY: ${ZT_DIR:=UNKNOWN}"

###################################################
CPrint "41" "Begin Step $((++ZT_STEP)): Create WiFi Maintenance Service."
cat << EOFEOF > "${ZT_SERVICES[0]}"
#!/bin/sh /etc/rc.common
# Init script for WiFi Maintenence Utility.
USE_PROCD=1
START=99
STOP=01
THIS_PATH="${ZT_DIR}"
THIS_APP="${ZT_WIFIMAINT}"
THIS_PIDFILE="/var/run/\${THIS_APP}.pid"
THIS_RUNOPTIONS="300"

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
chmod 755 "${ZT_SERVICES[0]}" || GTE ${ZT_STEP}

###################################################
CPrint "41" "Begin Step $((++ZT_STEP)): Create WiFi Maintenance."
cat << EOFEOF > "${ZT_DIR}/${ZT_WIFIMAINT}"
#!/bin/bash
# WiFi maintenance activation system.
SLEEPTIME="\${1}"
HARDWARENAME="GL.iNet GL-AR300M16"
function CheckHardware() {
    if grep -q "\${HARDWARENAME}" 2>/dev/null /etc/board.json; then
        echo "Hardware matches requirement to run [\${HARDWARENAME}]"
        return 0
    else
        echo "ERROR: Hardware does not match requirement to run [\${HARDWARENAME}]"
        exit 1
    fi
}
function SetupWiFi() {
    uci set wireless.radio0=wifi-device
    uci set wireless.radio0.type='mac80211'
    uci set wireless.radio0.path='platform/ahb/18100000.wmac'
    uci set wireless.radio0.band='2g'
    uci set wireless.radio0.htmode='HT40'
    uci set wireless.radio0.channel='auto'
    uci set wireless.radio0.cell_density='0'
    uci set wireless.default_radio0=wifi-iface
    uci set wireless.default_radio0.device='radio0'
    uci set wireless.default_radio0.network='lan'
    uci set wireless.default_radio0.mode='ap'
    uci set wireless.default_radio0.ssid='${ZT_WIFI_NAME}'
    uci set wireless.default_radio0.isolate='1'
    uci set wireless.default_radio0.encryption='psk2'
    uci set wireless.default_radio0.key='${ZT_WIFI_PASS}'
    uci set wireless.default_radio0.disabled='0'
    uci commit wireless
    wifi up
    echo "WIFI TURNED ON."
}
# Setup and checking.
CheckHardware 
SetupWiFi
# Initial wait.
sleep \${SLEEPTIME:-60}
while true; do
    echo "WIFI MAINT CYCLE [\$((++CYCLE_ITR))]"
    # Loop around. 
    if ! iwinfo wlan0 assoc 2>&1 | grep -qi 'No such wireless device'; then
       echo "WIFI IS ON."
       if iwinfo wlan0 assoc 2>&1 | grep -qi 'No station connected'; then  
          echo "WIFI HAS NO CLIENTS - SHUTTING DOWN."
          wifi down
       else
          echo "WIFI HAS CLIENTS - WAITING."
       fi
    else 
       echo "WIFI IS OFF."
    fi

    # Sleep until the next round.
    sleep \${SLEEPTIME:-60}
done
EOFEOF
chmod 755 "${ZT_DIR}/${ZT_WIFIMAINT}" || GTE ${ZT_STEP}

###################################################
CPrint "41" "Begin Step $((++ZT_STEP)): Enabling and Starting Services."
${ZT_SERVICES[0]} enable || GTE ${ZT_STEP}
${ZT_SERVICES[0]} start || GTE ${ZT_STEP}

###################################################
CPrint "44" "Install and Setup Complete."