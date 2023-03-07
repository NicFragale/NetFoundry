#!/bin/sh
################################################## ATTENTION ###################################################
# Instruction: Run on the router via SSH as ROOT.
# Instruction: Run with flag "enroll" to initiate the enrollment process.
# Instruction: Run with flag "install" to initialize the file structure and runtimes.
################################################################################################################

###################################################
# Set initial variables/functions.
ZT_URL="https://fragale.us/PDATA"
ZT_DIR="/opt/netfoundry/ziti"
ZT_ZET="ziti-edge-tunnel"
ZT_FT="tgz"
ZT_SERVICE="/etc/init.d/ziti-service"

# Create the directory structure.
mkdir -vp "${ZT_DIR}"

if [[ $1 == "install" ]]; then

    # Create the startup file.
    cat << EOFEOF > "${ZT_SERVICE}"
#!/bin/sh /etc/rc.common
#
# Init script for NetFoundry OpenZITI (OpenWRT version).

USE_PROCD=1
START=85
STOP=01
ZETPATH=${ZT_DIR}
ZETIDPATH=${ZT_DIR}/identities
ZETAPP=${ZT_ZET}
PID_FILE=/var/run/\${ZETAPP}.pid
ZETOPTIONS="run -I ${ZT_DIR}/identities"

start_service() {
    procd_open_instance
    procd_set_param command ${ZT_DIR}/\${ZETAPP} \${ZETOPTIONS}
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
    chmod 755 "${ZT_SERVICE}"

    # Obtain the compiled and built ZITI EDGE TUNNEL binary.
    wget --no-check-certificate "${ZT_URL}/${ZT_ZET}" -O /tmp/${ZT_ZET}.${ZT_FT}
    # Unpack the package and move it into place.
    gzip -d /tmp/${ZT_ZET}.${ZT_FT}
    mv /tmp/${ZT_ZET} ${ZT_DIR}
    # Cleanup.
    rm -f /tmp/${ZT_ZET}.${ZT_FT}

    # Test the binary function.
    chmod 755 ${ZT_DIR}/${ZT_ZET}
    ${ZT_DIR}/${ZT_ZET} version

    # Enable and start the binary.
    ${ZT_SERVICE} enable
    ${ZT_SERVICE} start

elif [[ $1 == "enroll" ]]; then

    # Enroll identities.
    # Note, JWT files must be transferred to the router, or no identities will be enrolled.
    for EachJWT in $(find ${ZT_DIR}/identities -name *.jwt); do
        echo ">> ENROLLING: ${EachJWT}"
        ${ZT_DIR}/${ZT_ZET} enroll -j ${ZT_DIR}/identities/${EachJWT} -o ${ZT_DIR}/identities/${EachJWT/.jwt/.json}
    done
    
    # Done.
    echo "Enrollment done.  If there were any newly enrolled identities, please restart the machine or the OpenZITI application to make it take effect."

else

    echo "Command syntax not given."
    echo "Please run with one of the following options:"
    echo "> To install the structures for running..."
    echo ">> ./$0 install"
    echo "> To enroll any JWTs in the already installed identities directory..."
    echo ">> ./$0 enroll"

fi