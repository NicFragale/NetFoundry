#!/bin/bash
################################################## ATTENTION ###################################################
# Instruction: Run on the router via SSH as ROOT.
MY_NAME="OWRT_Installer"
MY_VERSION="20230706"
MY_DESCRIPTION="NFragale: Install/Run Helper for OpenZITI/OpenWRT"
################################################################################################################

###################################################
# Set initial variables/functions.
ZT_WORKDIR="/tmp"
ZT_ZET=("${1}" "ziti-edge-tunnel") # File name in GZ compressed format.  EX: OpenWRT-22.03.3-ath79_generic.gz
ZT_URL="${2}" # URL basis for obtaining the runtime.  EX: https://myserver.com/somefolder
ZT_DIR="/opt/netfoundry/ziti"
ZT_IDDIR="${ZT_DIR}/identities"
ZT_DIR_MIN_SIZE="7000" # KBytes. 7000KB+ strongly recommended.

################################################################################################################
# DO NOT MODIFY BELOW THIS LINE
################################################################################################################
ZT_IDMANIFEST="manifest.info"
ZT_WATCH="ziti_watch"
ZT_SERVICES=("/etc/init.d/ziti-service" "/etc/init.d/ziti_watch-service")
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

###################################################
# Check for OpenWRT info from input or system.
if [[ ${ZT_ZET[0]} == "" ]] && [[ -f /etc/os-release ]]; then
	. /etc/os-release 2>/dev/null
	ZT_ZET[0]="OpenWRT-${VERSION}-${OPENWRT_BOARD/\//_}.gz"
fi

###################################################
CPrint "30:46" "${MY_NAME:-UNSET NAME} - v${MY_VERSION:-UNSET VERSION} - ${MY_DESCRIPTION:-UNSET DESCRIPTION}"
CPrint "30:42" "WORK DIRECTORY: ${ZT_WORKDIR:=UNKNOWN}"
CPrint "30:42" "BUILD URL: ${ZT_URL:=UNKNOWN}"
CPrint "30:42" "BUILD RUNTIME: ${ZT_ZET[0]:=UNKNOWN}->${ZT_ZET[1]:=UNKNOWN}"
CPrint "30:42" "INSTALL DIRECTORY: ${ZT_DIR:=UNKNOWN}"
CPrint "30:42" "IDENTITY DIRECTORY: ${ZT_IDDIR:=UNKNOWN}"

###################################################
CPrint "30:43" "Begin Step $((++ZT_STEP)): System Checking."
ZT_DIR_SIZE="$(GetDirSize "${ZT_DIR}")"
if [[ -f "${ZT_DIR}/${ZT_ZET[1]}" ]]; then
	ZT_ISDYNAMIC="false"
	CPrint "30:42" "EXISTING INSTALL DETECTED - BYPASSING SPACE CHECK [${ZT_DIR}: ${ZT_DIR_SIZE}KB Avail, ${ZT_DIR_MIN_SIZE}KB Min] - RUNNING LOCALLY."
elif [[ ${ZT_DIR_SIZE} -lt ${ZT_DIR_MIN_SIZE} ]]; then
	ZT_ISDYNAMIC="true"
	CPrint "30:45" "LOW STORAGE SPACE DEVICE DETECTED [${ZT_DIR}: ${ZT_DIR_SIZE}KB Avail < ${ZT_DIR_MIN_SIZE}KB Min] - RUNNING DYNAMICALLY FROM INPUT URL."
else
	ZT_ISDYNAMIC="false"
	CPrint "30:42" "SUFFICIENT STORAGE SPACE DEVICE DETECTED [${ZT_DIR}: ${ZT_DIR_SIZE}KB Avail > ${ZT_DIR_MIN_SIZE}KB Min] - RUNNING LOCALLY."
fi

###################################################
CPrint "30:43" "Begin Step $((++ZT_STEP)): Input Checking."
if [[ ${ZT_WORKDIR} == "UNKNOWN" ]] \
	|| [[ ${ZT_ZET[0]} == "UNKNOWN" ]] \
	|| [[ ${ZT_ZET[1]} == "UNKNOWN" ]] \
	|| [[ ${ZT_DIR} == "UNKNOWN" ]] \
	|| [[ ${ZT_IDDIR} == "UNKNOWN" ]]; then
	CPrint "30:42" "Input Missing/Error - Please Check."
	GTE ${ZT_STEP}
fi
if [[ ${ZT_ISDYNAMIC} == "true" ]] && [[ ${ZT_URL} == "UNKNOWN" ]]; then
	CPrint "30:41" "ERROR: DYNAMIC RUNTIME REQUIRES COMPRESSED FILE NAME INPUT AND URL INPUT."
	GTE ${ZT_STEP}
elif [[ ${ZT_ISDYNAMIC} == "false" ]]; then
	if [[ ${ZT_URL} == "UNKNOWN" ]] && [[ ! -f "${ZT_WORKDIR}/${ZT_ZET[0]}" ]] && [[ ! -f "${ZT_WORKDIR}/${ZT_ZET[1]}" ]] && [[ ! -f "${ZT_DIR}/${ZT_ZET[1]}" ]]; then
		CPrint "30:41" "ERROR: COMPRESSED [${ZT_ZET[0]}] OR UNCOMPRESSED [${ZT_ZET[1]}] RUNTIME FILE COULD NOT BE FOUND AND NO URL INPUT WAS SPECIFIED."
		GTE ${ZT_STEP}
	elif [[ ${ZT_URL} != "UNKNOWN" ]] && [[ ${ZT_ZET[0]} == "UNKNOWN" ]]; then
		CPrint "30:41" "ERROR: URL INPUT WAS SPECIFIED HOWEVER COMPRESSED RUNTIME FILE WAS NOT."
		GTE ${ZT_STEP}
	fi
fi
sleep 5

###################################################
CPrint "30:43" "Begin Step $((++ZT_STEP)): Update System and Packages."
opkg update || GTE ${ZT_STEP}
opkg install libatomic1 kmod-tun sed ip-full || GTE ${ZT_STEP}

###################################################
CPrint "30:43" "Begin Step $((++ZT_STEP)): Create Directory Structures and Files."
mkdir -vp "${ZT_DIR}" || GTE ${ZT_STEP}
mkdir -vp "${ZT_IDDIR}" || GTE ${ZT_STEP}
[[ ! -f "${ZT_IDDIR}/${ZT_IDMANIFEST}"  ]] \
	&& echo  -e "# ZITI EDGE TUNNEL IDENTITY MANIFEST - DO NOT DELETE\n# Initialized on $(date -u)" > "${ZT_IDDIR}/${ZT_IDMANIFEST}"

###################################################
if ${ZT_ISDYNAMIC}; then
	CPrint "30:43" "Skipping Step $((++ZT_STEP)): Dynamic Runtime Mode."
elif [[ -f "${ZT_WORKDIR}/${ZT_ZET[1]}" ]]; then
	CPrint "30:43" "Skipping Step $((++ZT_STEP)): Uncompressed Runtime Present [Location ${ZT_WORKDIR}/${ZT_ZET[1]}]."
elif  [[ -f "${ZT_DIR}/${ZT_ZET[1]}" ]]; then
	CPrint "30:43" "Skipping Step $((++ZT_STEP)): Uncompressed Runtime Present [Location ${ZT_DIR}/${ZT_ZET[1]}]."
else
	if [[ -f "${ZT_WORKDIR}/${ZT_ZET[0]}" ]]; then
		CPrint "30:43" "Skipping Step $((++ZT_STEP)): Compressed Runtime Present [Location ${ZT_WORKDIR}/${ZT_ZET[0]}]."
	else
		CPrint "30:43" "Begin Step $((++ZT_STEP)): Obtaining Compressed Runtime [${ZT_ZET[0]}]."
		wget "${ZT_URL}/${ZT_ZET[0]}" -O "${ZT_WORKDIR}/${ZT_ZET[0]}" || GTE ${ZT_STEP}
	fi
	CPrint "30:43" "Begin Step $((++ZT_STEP)): Decompress Runtime."
	gzip -fdc "${ZT_WORKDIR}/${ZT_ZET[0]}" > "${ZT_WORKDIR}/${ZT_ZET[1]}" || GTE ${ZT_STEP}
fi

###################################################
CPrint "30:43" "Begin Step $((++ZT_STEP)): Create Runtime Service."
cat << EOFEOF > "${ZT_SERVICES[0]}"
#!/bin/sh /etc/rc.common
# Init script for NetFoundry OpenZITI (ZITI EDGE TUNNEL, OpenWRT version).
USE_PROCD=1
START=85
STOP=85
THIS_PATH="${ZT_DIR}"
THIS_IDPATH="${ZT_IDDIR}"
THIS_APP="${ZT_ZET[1]}"
THIS_PIDFILE="/var/run/\${THIS_APP}.pid"
THIS_MANIFEST="manifest.info"
THIS_IDSAVAIL=""
THIS_RESOLVFILE="/tmp/resolv.conf.d/resolv.conf.auto"
THIS_UPDNSOPTS=""
THIS_IDOPTS=""
THIS_RUNOPTIONS=""
THIS_LOGGER="logger -s -t \${THIS_APP}"
start_service() {
	\${THIS_LOGGER} "Starting \${THIS_APP}."
	if [[ -f \${THIS_RESOLVFILE} ]]; then
		THIS_UPDNSOPTS="\$(grep -oEm1 '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' \${THIS_RESOLVFILE})"
		if [[ -z \${THIS_UPDNSOPTS} ]]; then
			THIS_UPDNSOPTS="1.1.1.1"
			\${THIS_LOGGER} "WARNING: DNS Resolv INVALID/EMPTY - Upstream Set to Default [\${THIS_UPDNSOPTS}]."
		else
			\${THIS_LOGGER} "INFO: DNS Upstream Set [\${THIS_UPDNSOPTS}]."
		fi
	else
		THIS_UPDNSOPTS="1.1.1.1"
		\${THIS_LOGGER} "WARNING: DNS Resolv NOT PRESENT - Upstream Set to Default [\${THIS_UPDNSOPTS}]."
	fi
	THIS_UPDNSOPTS="-u \${THIS_UPDNSOPTS}"
	THIS_IDSAVAIL="\$(grep -coE '\/.*\.json' \${THIS_IDPATH}/\${THIS_MANIFEST})"
	if [[ \${THIS_IDSAVAIL} -gt 1 ]]; then
		THIS_IDOPTS="-I \${THIS_IDPATH}"
		\${THIS_LOGGER} "INFO: Multiple Identities Available in Manifest - Using Directory Syntax."
	elif [[ \${THIS_IDSAVAIL} -eq 1 ]]; then
		THIS_IDOPTS="-i \$(grep -oEm1 '\/.*\.json' \${THIS_IDPATH}/\${THIS_MANIFEST})"
		\${THIS_LOGGER} "INFO: Single Identity Available in Manifest - Using File Syntax."
	else
		\${THIS_LOGGER} "WARNING: No Identities Available in Manifest [\${THIS_IDPATH}/\${THIS_MANIFEST}]."
	fi
	THIS_RUNOPTIONS="run \${THIS_IDOPTS} \${THIS_UPDNSOPTS}"
	procd_open_instance \${THIS_APP}
	procd_set_param command "\${THIS_PATH}/\${THIS_APP}" \${THIS_RUNOPTIONS}
	procd_set_param respawn 30 5 5
	procd_set_param file "\${THIS_IDPATH}/\${THIS_MANIFEST}"
	procd_set_param pidfile \${THIS_PIDFILE}
	procd_set_param limits core="unlimited"
	procd_set_param stdout 1
	procd_set_param stderr 1
	procd_open_trigger
	for EachInterface in \$(ip address show | awk '/^[[:digit:]]/{gsub(":","");if(\$2!="lo"&&\$2!~"ziti[[:digit:]]"){print \$2}}'); do
		\${THIS_LOGGER} "INFO: Adding Trigger for Interface [\${EachInterface}]."
		procd_add_reload_interface_trigger \${EachInterface}
	done
	procd_close_trigger
	procd_close_instance
}
stop_service() {
	\${THIS_LOGGER} "Stopping \${THIS_APP}."
	start-stop-daemon -K -p \${THIS_PIDFILE} -s TERM
}
EOFEOF
chmod 755 "${ZT_SERVICES[0]}" || GTE ${ZT_STEP}

###################################################
CPrint "30:43" "Begin Step $((++ZT_STEP)): Create ZITI Watch Service."
cat << EOFEOF > "${ZT_SERVICES[1]}"
#!/bin/sh /etc/rc.common
# Init script for NetFoundry OpenZITI (WATCH, OpenWRT version).
USE_PROCD=1
START=86
STOP=86
THIS_PATH="${ZT_DIR}"
THIS_APP="${ZT_WATCH}"
THIS_PIDFILE="/var/run/\${THIS_APP}.pid"
THIS_RUNOPTIONS="60"
THIS_LOGGER="logger -s -t \${THIS_APP}"
start_service() {
	\${THIS_LOGGER} "Starting \${THIS_APP}."
	procd_open_instance \${THIS_APP}
	procd_set_param command "\${THIS_PATH}/\${THIS_APP}" \${THIS_RUNOPTIONS}
	procd_set_param respawn 30 5 5
	procd_set_param pidfile \${THIS_PIDFILE}
	procd_set_param stdout 1
	procd_set_param stderr 1
	procd_close_instance
}
stop_service() {
	\${THIS_LOGGER} "Stopping \${THIS_APP}."
	start-stop-daemon -K -p \${THIS_PIDFILE} -s TERM
}
EOFEOF
chmod 755 "${ZT_SERVICES[1]}" || GTE ${ZT_STEP}

###################################################
CPrint "30:43" "Begin Step $((++ZT_STEP)): Create ZITI Watch."
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
		"\${ZT_SERVICES[0]}" stop
		wget "\${ZT_URL}/\${ZT_ZET[0]}" -O "\${ZT_WORKDIR}/\${ZT_ZET[0]}" \
			&& gzip -fdc "\${ZT_WORKDIR}/\${ZT_ZET[0]}" > "\${ZT_WORKDIR}/\${ZT_ZET[1]}" \
			&& ln -sf "\${ZT_WORKDIR}/\${ZT_ZET[1]}" "\${ZT_DIR}/\${ZT_ZET[1]}" \
			&& chmod 755 "\${ZT_WORKDIR}/\${ZT_ZET[1]}" \
			&& "\${ZT_SERVICES[1]}" reload \
			&& rm -f "\${ZT_WORKDIR}/\${ZT_ZET[0]}" \
			&& "\${ZT_SERVICES[0]}" restart \
			&& echo "[\${ZW_ITR}] SUCCESS: Obtained Runtime" \
			|| echo "[\${ZW_ITR}] FAILED: Could Not Obtain Runtime"
	# RECOVERY FUNCTION: Attempt to obtain the runtime if not present.
	elif ! ${ZT_ISDYNAMIC} && [[ ! -f \${ZT_DIR}/\${ZT_ZET[1]} ]]; then
		echo "[\${ZW_ITR}] RECOVERY MODE, OBTAINING RUNTIME"
		"\${ZT_SERVICES[0]}" stop
		wget "\${ZT_URL}/\${ZT_ZET[0]}" -O "\${ZT_WORKDIR}/\${ZT_ZET[0]}" \
			&& gzip -fdc "\${ZT_WORKDIR}/\${ZT_ZET[0]}" > "\${ZT_DIR}/\${ZT_ZET[1]}" \
			&& chmod 755 "\${ZT_DIR}/\${ZT_ZET[1]}" \
			&& "\${ZT_SERVICES[1]}" reload \
			&& rm -f "\${ZT_WORKDIR}/\${ZT_ZET[0]}" \
			&& "\${ZT_SERVICES[0]}" restart \
			&& echo "[\${ZW_ITR}] SUCCESS: Obtained Runtime" \
			|| echo "[\${ZW_ITR}] FAILED: Could Not Obtain Runtime"
	elif [[ \$(\${ZT_SERVICES[0]} status) != "running" ]] || ! pgrep "${ZT_SERVICES[1]}" >/dev/null; then
		echo "[\${ZW_ITR}] RECOVERY MODE, RESTARTING RUNTIME"
		\${ZT_SERVICES[0]} restart
	fi
	# Cycle any available JWTs.
	while IFS=$'\n' read -r EachJWT; do
		echo "[\${ZW_ITR}] ENROLLING: \${EachJWT}"
		if "\${ZT_DIR}/\${ZT_ZET[1]}" enroll -j "\${EachJWT}" -i "\${EachJWT/.jwt/.json}"; then
			echo "[\${ZW_ITR}] SUCCESS: \${EachJWT/.jwt/.json}"
			echo "[\$(date -u)] ADDED \${EachJWT/.jwt/.json}" >> "\${ZT_IDDIR}/\${ZT_IDMANIFEST}"
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
	CPrint "30:43" "Skipping Step $((++ZT_STEP)): Dynamic Runtime Mode."
else
	CPrint "30:43" "Begin Step $((++ZT_STEP)): Setup Runtime."
	if [[ ! -f "${ZT_DIR}/${ZT_ZET[1]}" ]]; then
		mv -vf "${ZT_WORKDIR}/${ZT_ZET[1]}" "${ZT_DIR}" || GTE ${ZT_STEP}
	fi
	rm -f "${ZT_WORKDIR}/${ZT_ZET[0]}" "${ZT_WORKDIR}/${ZT_ZET[1]}" || GTE ${ZT_STEP}
	chmod 755 "${ZT_DIR}/${ZT_ZET[1]}" || GTE ${ZT_STEP}
	ZT_BINARYVER="$(${ZT_DIR}/${ZT_ZET[1]} version || echo UNKNOWN)"
	[[ ${ZT_BINARYVER} == "UNKNOWN" ]] \
		&& GTE ${ZT_STEP} \
		|| echo "ZITI EDGE TUNNEL VERSION: ${ZT_BINARYVER}"
fi

###################################################
if [[ -f "/etc/group" ]] && ! grep -q "ziti" "/etc/group"; then
	CPrint "30:43" "Begin Step $((++ZT_STEP)): Permit of Sockets."
	echo 'ziti:x:99:' >> /etc/group
else
	CPrint "30:43" "Skipping Step $((++ZT_STEP)): Permit of Sockets."
fi

###################################################
CPrint "30:43" "Begin Step $((++ZT_STEP)): Enabling and Starting Services."
${ZT_SERVICES[0]} enable || GTE ${ZT_STEP}
${ZT_SERVICES[1]} enable || GTE ${ZT_STEP}
${ZT_SERVICES[0]} start || GTE ${ZT_STEP}
${ZT_SERVICES[1]} start || GTE ${ZT_STEP}

###################################################
CPrint "30:42" "Install and Setup Complete."