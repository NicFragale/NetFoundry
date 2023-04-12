#!/bin/bash
SLEEPTIME=$1

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
    uci set wireless.default_radio0.ssid='Router Config AP'
    uci set wireless.default_radio0.isolate='1'
    uci set wireless.default_radio0.encryption='psk2'
    uci set wireless.default_radio0.key='MAINT-NET-ENTRY'
    uci set wireless.default_radio0.disabled='0'
    uci commit wireless
    wifi up
    echo "> WIFI TURNED ON."
}

function SetupService() {
    if [[ -f "/etc/init.d/wifi-maint" ]]; then
        echo "> WIFI MAINT SERVICE READY."
        return 0
    else
        echo "> WIFI MAINT SERVICE INIT SETUP."
    fi
cat << EOFEOF > "/etc/init.d/wifi-maint"
#!/bin/sh /etc/rc.common
# Init script for WiFi Maintenence Utility.
USE_PROCD=1
START=99
STOP=01
THIS_PATH="/opt/netfoundry/ziti"
THIS_APP="wifi-maint"
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
    chmod 755 "/etc/init.d/wifi-maint"
    /etc/init.d/wifi-maint enable
    /etc/init.d/wifi-maint start
    echo "> WIFI MAINT SERVICE READY."
    exit 0
}

# Setup and checking.
SetupService 
SetupWiFi

# Initial wait.
sleep ${SLEEPTIME:-60}

while true; do
    echo "> WIFI MAINT CYCLE [$((++CYCLE_ITR))]"

    # Loop around. 
    if ! iwinfo wlan0 assoc 2>&1 | grep -qi 'No such wireless device'; then
       echo ">> WIFI IS ON."
       if iwinfo wlan0 assoc 2>&1 | grep -qi 'No station connected'; then  
          echo ">>> WIFI HAS NO CLIENTS - SHUTTING DOWN."
          wifi down
       else
          echo ">>> WIFI HAS CLIENTS - WAITING."
       fi
    else 
       echo ">> WIFI IS OFF."
    fi

    # Sleep until the next round.
    sleep ${SLEEPTIME:-60}
done
