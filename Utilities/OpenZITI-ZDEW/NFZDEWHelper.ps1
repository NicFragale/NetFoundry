###################################################################################################################
# NFZDEWHelper - A helper utility for installing/enrolling/DNSing NetFoundry OpenZiti Desktop Edge for Windows.
# Written by Nic Fragale @ NetFoundry.
###################################################################################################################
############################################# DO NOT MODIFY THIS FILE #############################################
###################################################################################################################
# Configuration variables are loaded from a secondary file or via a cloud server.
# This configuration file will be created from defaults if it does not exist or if not loaded from a cloud server.
# You can modify the configuration file with changes which will not be overwritten if an update occurs.
###################################################################################################################
[CmdletBinding(PositionalBinding=$false)]
param(
	[Parameter()][Alias('Resolve')][string]$InputModeResolve,
	[Parameter()][Alias('Tasks')][string]$InputModeTasks,
	[Parameter()][Alias('Configuration')][string]$CentralConfURL,
	[Parameter()][Alias('Help')][switch]$InputModeHelp,
	[Parameter()][Alias('Environment')][switch]$InputModeEnvironment,
	[Parameter()][Alias('Install')][switch]$InputModeInstall,
	[Parameter()][Alias('InstallAdd')][switch]$InputModeInstallAdd,
	[Parameter()][Alias('Remove')][switch]$InputModeRemove,
	[Parameter()][Alias('RemoveAll')][switch]$InputModeRemoveAll,
	[Parameter()][Alias('List')][switch]$InputModeList,
	[Parameter()][ValidateRange(0,3)][int]$Verbosity=1,
	[Parameter()][switch]$Force,
	[Parameter()][Alias('JWT')][string]$InputJWT,
	[Parameter(ValueFromRemainingArguments = $true)][string]$UnknownArgs
)

### STATIC VARIABLES LOADER ###
$MyWarranty     = "This program comes without any warranty, implied or otherwise."
$MyLicense      = "This program utilizes the Apache 2.0 license."
$MyVersion      = "20250418"
$SystemRuntime  = [system.diagnostics.stopwatch]::StartNew()
$MyPath         = Split-Path $MyInvocation.MyCommand.Path
$ThisUser       = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$MyRootExec     = $MyInvocation.MyCommand.Name
$MyRootName     = $MyRootExec.split(".")[0]
$MyCommandLine  = ($MyInvocation.Line -Replace ".*$([regex]::escape($MyRootExec))(.*);?.*",'$1').Trim()
$MyConfig       = $MyPath + "\" + $MyRootName + "_config.ps1"
$MyName         = $MyRootName + "_" + (Get-Random)
$MyTmpPath      = $MyPath + "\" + $MyName
$ZDEKSPath      = "$env:windir\System32\config\systemprofile\AppData\Roaming\NetFoundry"
$ZSWName        = "NetFoundry Inc\Ziti Desktop Edge"
$RegistryZSW    = "HKLM:\SOFTWARE\$ZSWName"
$RegistryNRPT   = "HKLM:\SYSTEM\ControlSet001\Services\Dnscache\Parameters\DnsPolicyConfig"
$ZRPath         = "${env:ProgramFiles(x86)}\$ZSWName"
$ZTUNRBinary    = "ziti-tunnel.exe"
$ZUIRBinary     = "ZitiDesktopEdge.exe"
$ZTCLIRBinary   = "ziti.exe"
$ZDERRepo       = "https://api.github.com/repos/openziti/desktop-edge-win/releases/latest"
$ZCLIRRepo      = "https://api.github.com/repos/openziti/ziti/releases/latest"
$ZDERTarget     = "https://github.com/openziti/desktop-edge-win/releases/download"
$ZDERFIPSTarget = "https://netfoundry.jfrog.io/artifactory/downloads/desktop-edge-win-win32crypto"
$ZCLIRTarget    = "https://github.com/openziti/ziti/releases/download"
$DisplayName    = "NetFoundry DNS Redirect"
$Comment        = "Created by $MyRootName"
$RequiredCmds   = @(
	"Get-Command","Split-Path","Write-Host","Select-Object","Out-String","Format-Table","Sort-Object","Test-Path",
	"Invoke-Expression","Invoke-Command","Get-FileHash","Get-CimInstance","Read-Host","ForEach-Object","Start-Sleep","Expand-Archive",
	"Rename-Item","Get-ItemProperty","Set-Content","New-Object","Add-Member","Get-ChildItem","New-Item","Get-Content","Move-Item","Remove-Item",
	"Invoke-RestMethod","Invoke-WebRequest","Start-BitsTransfer",
	"Start-Process","Receive-Job","Get-Job","ConvertFrom-Json","Start-Job"
)
$OptionalCmds	= @(
	"Get-DnsClientGlobalSetting","Add-DnsClientNrptRule","Remove-DnsClientNrptRule","Clear-DnsClientCache","Set-DnsClientGlobalSetting"
)

### INTERNAL CONFIGURATION DEFAULTS ###
$ConfigDefaults	= '
	$script:DefaultMode     = "environment" # Default mode if no options arguments are passed in. See help menu for options.
	$script:AutoUpdate      = "true" # Instructs the program to check for an update to itself from the specified server (true=try to update | false=ignore).
	$script:FIPS		    = "false" # Instructs the program to download/install the FIPs enabled binary (true=FIPS | false=non-FIPS).
	$script:ServerURL       = "https://raw.githubusercontent.com/NicFragale/NetFoundry/main/Utilities/OpenZITI-ZDEW" # Update server URL.
	$script:ServerRootExec  = "NFZDEWHelper.ps1" # Filename of runtime on update server.
	$script:ZDERVer         = "AUTO" # ZITI Desktop Edge (Win) version to target from repos (AUTO=find automatically | [X.XX.XX=target this version]).
	$script:ZCLIRVer        = "AUTO" # ZITI CLI version to target from repos (AUTO=find automatically | [X.XX.XX]=target this version).
	$script:OverwriteInst   = "false" # If set to "true" will overwrite if software already exists (true=overwrite | false=ignore).
	$script:JWTObtain       = "SEARCH" # Default Enrollment Action when no JWT string is passed in (ASK=Ask with prompt for JWT string | SEARCH=Find any JWTs in local dir).
	$script:EnrollMethod    = "NATIVE" # Method in which to invoke enrollment (NATIVE=IPC | ZCLI=ZITI CLI).
	$script:DLDefaultMethod = "BITS" # The default method by which to request downloads (BITS | WEBCLIENT).
	$script:LogElevation    = "true" # A flag which causes the elevation event and subsequent runtime to be placed into a log file (true=logging enabled | false=no logging).
	$script:AddSuffix       = "domain.local" # Change the following DOMAIN and NAMESERVERS as appropriate.
	$script:Domain          = @(
		".domain.local"
	)
	$script:NameServers     = @(
		"1.2.3.4"
		"5.6.7.8"
	)
	$script:InputJWT       = ""
'

###################################################################################################################
### FUNCTIONS LOADER ###
# Printer.
function GoToPrint ([int]$PrintLevel="1", $PrintColor="DarkGray:White", $PrintMessage="No Message") {
	# Only print if the level is below the verbosity level.
	if (($PrintLevel -LT 0) -OR ($Verbosity -GE $PrintLevel)) {
		# If level is set above 2, also print information about the level and timing.
		if (($PrintLevel -GT 0) -AND ($Verbosity -GE 2)) {
			$PrintMessage = "[$PrintLevel|$Verbosity|3] [$([math]::Round($SystemRuntime.Elapsed.TotalSeconds,0))s] $PrintMessage"
		# If level is set above 0, also oprint timing.
		} elseif (($PrintLevel -GT 0) -AND ($Verbosity -GE 0)) {
			$PrintMessage = "[$([math]::Round($SystemRuntime.Elapsed.TotalSeconds,0))s] $PrintMessage"
		}
		# Color Options [Black, DarkBlue, DarkGreen, DarkCyan, DarkRed, DarkMagenta, DarkYellow, Gray, DarkGray, Blue, Green, Cyan, Red, Magenta, Yellow, White]
		$private:FGColor = $PrintColor.Split(":")[0]
		$private:BGColor = $PrintColor.Split(":")[1]
		# Input was (FG:BG) where FG and BG are the same (an error).
		if ($FGColor -EQ $BGColor) {
			Write-Host "$PrintMessage" -ForegroundColor "$FGColor"
		# Input was (FG) or (FG:).
		} elseif (($FGColor) -AND (-NOT($BGColor))) {
			Write-Host "$PrintMessage" -ForegroundColor "$FGColor"
		# Input was (:BG).
		} elseif (($BGColor) -AND (-NOT($FGColor))) {
			Write-Host "$PrintMessage" -BackgroundColor "$BGColor"
		# Input was (FG:BG).
		} else {
			Write-Host "$PrintMessage" -ForegroundColor "$FGColor" -BackgroundColor "${BGColor}"
		}
	}
}

# Color banner generation.
function PrintBanner ($PrintType = "INIT") {
	$NFBanner = @(
		'##########################################################################################'
		'                   _   __     __  ______                      __                          '
		'                  / | / /__  / /_/ ____/___  __  ______  ____/ /______  __                '
		'                 /  |/ / _ \/ __/ /_  / __ \/ / / / __ \/ __  / ___/ / / /                '
		'                / /|  /  __/ /_/ __/ / /_/ / /_/ / / / / /_/ / /  / /_/ /                 '
		'               /_/ |_/\___/\__/_/    \____/\__,_/_/ /_/\__,_/_/   \__, /                  '
		'                                                                 /____/                   '
	)
	if ($PrintType -EQ "INIT") {
		$NFBanner += "# V$MyVersion [$FileHashLocal] ".PadRight(90,"#")
	} elseif ($PrintType -EQ "INITERROR") {
		$NFBanner += "# $MyVersion".PadRight(90,"#")
	} elseif ($PrintType -EQ "TERM") {
		$SystemRuntime.Stop()
		$TotalSeconds = "# Runtime [$([math]::Round($SystemRuntime.Elapsed.TotalSeconds,0))s] "
		$NFBanner += "$TotalSeconds".PadRight(90,"#")
	}
	if (-NOT($script:BLRandom)) {
		$script:BLRandom = Get-Random -Minimum 0 -Maximum 4
	}
	foreach ($BannerLine in $($NFBanner -split "`r`n")) {
		switch ($script:BLRandom) {
			0 {GoToPrint "-1" "White:DarkMagenta" "$BannerLine"}
			1 {GoToPrint "-1" "Green:Black" "$BannerLine"}
			2 {GoToPrint "-1" "DarkBlue:Gray" "$BannerLine"}
			3 {GoToPrint "-1" "DarkYellow:DarkCyan" "$BannerLine"}
			4 {GoToPrint "-1" "DarkRed:DarkGray" "$BannerLine"}
		}
	}
}

# Check for ADMIN rights.
function CheckAdmin {
	if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
		return 0
	} else {
		if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
			return 1
		} else {
			return 2
		}
	}
}

# Second level function to find a process in the system.
function FindProcess ($ThisProcess) {
	try {
		Get-Process "$ThisProcess" -ErrorAction SilentlyContinue
		return 0
	} catch {
		return 1
	} finally {
		$error.clear()
	}
}

# Get current environment.
function RunGetCurrentEnv ($GetTypes="ALL") {
	if (($GetTypes -EQ "ALL") -OR ($GetTypes -EQ "ZPROCESSES")) {
		GoToPrint "1" "White:DarkCyan" "######## OPENZITIPROCESSINFO ########"
		if (FindProcess "ZitiDesktopEdge") {
			GoToPrint "1" "Green" "OPENZITI WINDOWS DESKTOP EDGE [RUNNING]."
		} else {
			GoToPrint "1" "Yellow" "OPENZITI WINDOWS DESKTOP EDGE [NOTRUNNING]."
		}
		if (FindProcess "ziti-edge-tunnel") {
			GoToPrint "1" "Green" "OPENZITI WINDOWS TUNNEL [RUNNING]."
		} else {
			GoToPrint "1" "Yellow" "OPENZITI WINDOWS TUNNEL [NOTRUNNING]."
		}
		if (FindProcess "ZitiUpdateService") {
			GoToPrint "1" "Green" "OPENZITI WINDOWS UPDATE SERVICE [RUNNING]."
		} else {
			GoToPrint "1" "Yellow" "OPENZITI WINDOWS UPDATE SERVICE [NOTRUNNING]."
		}
	}

	if (($GetTypes -EQ "ALL") -OR ($GetTypes -EQ "DNS")) {
		GoToPrint "1" "White:DarkCyan" "#### DNSCLIENTGLOBALSETTINGS ####"
		Get-DnsClientGlobalSetting | Select-Object SuffixSearchList | Out-String -Stream | Where { $_.Trim().Length -gt 0 }
		GoToPrint "1" "White:DarkCyan" "####### DNSCLIENTNRPTRULE #######"
		Get-DnsClientNrptRule | ForEach-Object {
			[PSCustomObject]@{
				'DisplayName' = $_.DisplayName
				'ActualName' = $_.Name
				'NameSpace' = $_.NameSpace
				'NameServers' = $_.NameServers
			}
		} | Sort-Object "ActualName" | Format-Table -AutoSize | Out-String -Stream | Where { $_.Trim().Length -gt 0 }
	}
}

# Get a resolved name from DNS.
function RunGetResolution ($InputArgs) {
	GoToPrint "1" "White:DarkCyan" "######### DNSRESOLUTION #########"
	$InputArgs = 'Resolve-DnsName ' + $InputArgs
	GoToPrint "1" "DarkGray" "Sending [$InputArgs] for resolution."
	Invoke-Expression $InputArgs | Format-Table -AutoSize | Out-String -Stream | Where { $_.Trim().Length -gt 0 }
}

# Get task(s) from the OS.
function RunGetTasks ($InputArgs, $REQType) {
	GoToPrint "1" "White:DarkCyan" "########## TASKLOOKUP ##########"
	if ($REQType -EQ "NUM") {
		$InputArgs = 'Get-Process | where {$_.cpu -GT ' + $InputArgs + '}'
	} else {
		$InputArgs = 'Get-Process *' + $InputArgs + '* -IncludeUserName'
	}
	GoToPrint "1" "DarkGray" "Sending [$InputArgs] for review."
	Invoke-Expression $InputArgs | Format-Table -AutoSize | Out-String -Stream | Where { $_.Trim().Length -gt 0 }
}

# Run the ADD function.
function RunAdd {

	GoToPrint "1" "White:DarkCyan" "########## DNSRULESADD ##########"

	if ($script:DNSCGSetting) {

		GoToPrint "1" "DarkGray" "Adding rules to the system."

		if (($NameServers[0] -EQ "DNS_SERVER_1") -OR ($Domain[0] -EQ ".domain.local")) {
			GoToPrint "2" "Yellow" "WARNING: DNS/DOMAIN SERVERS list in this file has not been updated so no action has been taken to update settings."
			return
		}

		Get-DnsClientNrptRule | Where "DisplayName" -EQ "$DisplayName" | ForEach-Object {
			$ThisDisplayName = $_.DisplayName
			$ThisDomain = $_.NameSpace
			$ThisNameServers = $_.NameServers
			GoToPrint "1" "DarkGray" "Cleaning rule [DisplayName=$ThisDisplayName] [Namespace=$ThisDomain] [NameServers=$ThisNameServers]."
			Remove-DnsClientNrptRule -Name $_.Name -Force
		}

		GoToPrint "1" "DarkGray" "Adding rule [DisplayName=$DisplayName] [Namespace=$Domain] [NameServers=$NameServers]."
		Add-DnsClientNrptRule -Namespace $Domain -NameServers $NameServers -Comment $Comment -DisplayName $DisplayName

		try {
			$TargetRule = (Get-DnsClientNrptRule | Where-Object {$_.DisplayName -EQ "$DisplayName"}).Name
			$TargetRuleModified = $TargetRule -Replace '{(.*)-(.*)-(.*)-(.*)-(.*)}','{00000000-$2-$3-$4-$5}'
			Rename-Item -Path "$RegistryNRPT\$TargetRule" "$TargetRuleModified"
		} catch {
			GoToPrint "2" "Yellow" "WARNING: Could not ascertain the required NRPT rule."
		} finally {
			$HKLMData = Get-ItemProperty "$RegistryNRPT\$TargetRuleModified" -ErrorAction SilentlyContinue
			if ($HKLMData) {
				GoToPrint "1" "Green" "Successfully ascertained and modified the required NRPT rule."
			} else {
				GoToPrint "1" "Red" "ERROR: Failed to modify the required NRPT rule."
			}
			$error.clear()
		}

		if ($DNSCGSetting.SuffixSearchList.Contains($AddSuffix)) {
			if ($DNSCGSetting.SuffixSearchList[0] -NE $AddSuffix) {
				$SuffixIndex = $DNSCGSetting.SuffixSearchList.IndexOf($AddSuffix)
				GoToPrint "1" "DarkGray" "Search suffix [$AddSuffix] is in the system, but does not have precedence (Index=$SuffixIndex)."
				$DNSCGSetting.SuffixSearchList = @($AddSuffix; foreach ($Name in $DNSCGSetting.SuffixSearchList) { if($Name -ne $AddSuffix) {GoToPrint "1" "DarkGray" "$Name"} })
				Set-DnsClientGlobalSetting -SuffixSearchList $DNSCGSetting.SuffixSearchList
			} else {
				GoToPrint "1" "DarkGray" "Search suffix [$AddSuffix] is already in the system. (Index=0)."
			}
		} else {
			GoToPrint "1" "DarkGray" "Adding new search suffix [$AddSuffix]."
			$DNSCGSetting.SuffixSearchList = @($AddSuffix; $DNSCGSetting.SuffixSearchList)
			Set-DnsClientGlobalSetting -SuffixSearchList $DNSCGSetting.SuffixSearchList
		}

		GoToPrint "1" "DarkGray" "Clearing DNS cache."
		Clear-DnsClientCache

	} else {

		GoToPrint "1" "Red" "Function ""add"" cannot execute due to unavailable data method."

	}
}

# Decode a JWT into parts.
function Parse-JWTtoken {
	[cmdletbinding()]
	param([Parameter(Mandatory=$true)][string]$InputJWT)

	# Parse the input.
	if (-NOT($InputJWT.Contains(".")) -OR -NOT($InputJWT.StartsWith("eyJ"))) {
		GoToPrint "1" "Red" "Invalid JWT was provided."
		return 0
	}

	# Payload.
	$JWTPayload = $InputJWT.Split(".")[1].Replace('-', '+').Replace('_', '/')
	# Fix padding as needed, keep adding "=" until string length modulus 4 reaches 0.
	while ($JWTPayload.Length % 4) {
		$JWTPayload += "="
	}
	# Convert to Byte array.
	$ByteArray = [System.Convert]::FromBase64String($JWTPayload)
	# Convert to string array.
	$JSONArray = [System.Text.Encoding]::ASCII.GetString($ByteArray)
	# Convert from JSON to PSObject.
	$JSONObj = $JSONArray | ConvertFrom-Json

	return $JSONObj
}

# Resolve the latest version of software in a repo.
function RunRepoResolve ($ResolveRepo) {
	$ResolvedVersion = Invoke-RestMethod -Uri "$ResolveRepo"
	$ResolvedVersion.tag_name.Trim("v"," ")
}

# Choose a method to DOWNLOAD.
function DownloadMethod ($DLSource, $DLWhat, $DLDestination, $DLMethod="$DLDefaultMethod") {
	GoToPrint "1" "Yellow" "Downloading [$DLWhat] from [$DLSource] using [$DLMethod], please wait..."
	if ($DLMethod -EQ "WEBCLIENT") {
		try {
			Invoke-WebRequest -DisableKeepAlive -UseBasicParsing "$DLSource/$DLWhat" -OutFile "$DLDestination"
		} catch {
	  		$BTRETURN = $_
		}
		finally {
			$error.clear()
		}
	} elseif ($DLMethod -EQ "BITS") {
		try {
			Start-BitsTransfer -Source "$DLSource/$DLWhat" -Destination "$DLDestination" -DisplayName "NetFoundry Software Installer" -ErrorVariable BTRETURN -ErrorAction SilentlyContinue
		}
		finally {
			$error.clear()
		}
	}
	return $BTRETURN
}

# Run the DOWNLOAD AND INSTALL function.
function DownloadInstall {
	if ($ZDERVer -EQ "AUTO") {
		$ZDERVer = RunRepoResolve "$ZDERRepo"
		$ZDERBinary = "Ziti.Desktop.Edge.Client-$ZDERVer.exe"
		#$ZDERName = "ZitiDesktopEdgeClient-$ZDERVer"
		#$ZDERBinary = "Ziti Desktop Edge Client-$ZDERVer.exe"
		#$ZDERZip = "$ZDERName.zip"
	}
	if ($ZCLIRVer -EQ "AUTO" -AND $EnrollMethod -EQ "ZCLI") {
		$ZCLIRVer = RunRepoResolve "$ZCLIRRepo"
		$ZCLIRZip = "ziti-windows-amd64-$ZCLIRVer.zip"
	}

	if ($FIPS -EQ "true") {
		$ZDERTarget = "$ZDERFIPSTarget"
	}

	if ($EnrollMethod -EQ "ZCLI") {
		$ZDECLIEnroll = $MyTmpPath + "\ziti\$ZTCLIRBinary"
		$BTRETURN = DownloadMethod "$ZDERTarget/$ZDERVer" "$ZDERBinary" "$MyTmpPath"
		$BTRETURN = DownloadMethod "$ZCLIRTarget/v$ZCLIRVer" "$ZCLIRZip" "$MyTmpPath"
	} elseif ($EnrollMethod -EQ "NATIVE") {
		$BTRETURN = DownloadMethod "$ZDERTarget/$ZDERVer" "$ZDERBinary" "$MyTmpPath"
	}

	if ([string]::IsNullOrWhiteSpace($BTRETURN)) {

		$WAITCOUNT = 0
		do {
			$WAITCOUNT++
			if ($WAITCOUNT -GT 20) {
				GoToPrint "1" "White:Red" "Download failed. Cannot continue."
				return 0
			}
			GoToPrint "1" "DarkGray" "Waiting for OpenZiti installation binary to become available, please wait... ($WAITCOUNT/20)"
			Start-Sleep 1
		} until (Test-Path "$MyTmpPath\$ZDERBinary")
		GoToPrint "1" "Green" "Download succeeded."
		#Expand-Archive -Path "$MyTmpPath\$ZDERZip" -DestinationPath "$MyTmpPath" -Force 2>&1 | out-null
		#if (-NOT (Get-FileHash "$MyTmpPath\$ZDERBinary" -Algorithm SHA256 | Select-Object -ExpandProperty Hash) -EQ (Get-Content "$MyTmpPath\$ZDERBinary.sha256")) {
		#	$ZDERBinaryHash = Get-FileHash "$MyTmpPath\$ZDERBinary" -Algorithm SHA256 | Select-Object -ExpandProperty Hash
		#	$ZDERBinaryHashExpected = Get-Content "$MyTmpPath\$ZDERBinary.sha256"
		#	GoToPrint "1" "White:Red" "Decompress and validation (SHA256) failed. Hash mismatch."
		#	GoToPrint "1" "White:Red" "File HASH:     $ZDERBinaryHash"
		#	GoToPrint "1" "White:Red" "EXPECTED HASH: $ZDERBinaryHashExpected"
		#	return 0
		#}
		GoToPrint "1" "Green" "OpenZiti installation binary is available. Download complete."

		GoToPrint "1" "Yellow" "Now installing NetFoundry software silently, please wait..."
		Start-Process "$MyTmpPath\$ZDERBinary" -WorkingDirectory "$MyTmpPath" -ArgumentList "/PASSIVE" -Wait

		if ($EnrollMethod -EQ "ZCLI") {
			Expand-Archive -Path "$MyTmpPath\$ZCLIRZip" -DestinationPath "$MyTmpPath" -Force 2>&1 | out-null
		}

		if ((Test-Path "$ZRPath\$ZUIRBinary") -AND ($EnrollMethod -EQ "NATIVE" -OR (Test-Path "$ZDECLIEnroll"))) {
			Start-Process "$ZRPath\$ZUIRBinary" -WorkingDirectory "$ZRPath"
			GoToPrint "1" "Green" "Install complete."
			return 1
		} else {
			if (-NOT (Test-Path "$ZRPath\$ZUIRBinary"))  {
				GoToPrint "1" "White:Red" "OpenZiti runtime binary at path [$ZRPath\$ZUIRBinary] does not exist."
			}
			if (($EnrollMethod -EQ "NATIVE") -AND (-NOT (Test-Path "$ZDECLIEnroll")))  {
				GoToPrint "1" "White:Red" "OpenZiti CLI at path [$ZDECLIEnroll] does not exist."
			}
			GoToPrint "1" "White:Red" "Install failed.  Cannot continue."
			return 0
		}

	} else {

		GoToPrint "1" "Red" "Download failed. Cannot continue. Error message below."
		GoToPrint "1" "Red" "$BTRETURN"
		return 0

	}
}

# Run the ENROLL function.
function RunEnroll {
	GoToPrint "1" "Yellow" "Now enrolling any available identities, please wait..."
	if ($InputJWT) {

		if ($InputJWT.length -LT 500) {
			GoToPrint "1" "Red" "ERROR: The input JWT string is not correct for processing."
			return
		}
		Set-Content $TargetJWT $InputJWT 2>&1 | out-null
		$AllEnrollments = New-Object -TypeName psobject
		$AllEnrollments | Add-Member -MemberType NoteProperty -Name Name -Value "$MyName.jwt"

	} elseif ($JWTObtain -EQ "ASK") {

		$InputJWT = Read-Host "Paste the enrollment JWT string." -AsSecureString
		while ($InputJWT.length -LT 500) {
			GoToPrint "1" "Red" "ERROR: The input JWT string is not correct for processing."
			$InputJWT = Read-Host "Paste the enrollment JWT string." -AsSecureString
		}
		Set-Content $TargetJWT $InputJWT 2>&1 | out-null
		$AllEnrollments = New-Object -TypeName psobject
		$AllEnrollments | Add-Member -MemberType NoteProperty -Name Name -Value "$MyName.jwt"

	} elseif ($JWTObtain -EQ "SEARCH") {

		$AllEnrollments = Get-ChildItem -Path $MyPath *.jwt -File -ErrorAction SilentlyContinue
		if ($AllEnrollments.count -EQ 0) {
			GoToPrint "1" "Yellow" "WARNING: There were no JWTs for enrollment in the local path."
		} else {
			GoToPrint "1" "Green" "Found [$($AllEnrollments.count)] enrollments to process."
		}

	}

	# Interworking for the pipe system.
	$PipeInit = {
		function ZPipeRelay ($PipeInputPayload) {
			function PipeOpen {
				try {
					$script:ZIPCIO = New-Object System.IO.Pipes.NamedPipeClientStream '.','ziti-edge-tunnel.sock','InOut'
					$script:ZIPCIO.Connect(1000)
					$script:ZIPCREAD = New-Object System.IO.StreamReader $script:ZIPCIO
					$script:ZIPCWRITE = New-Object System.IO.StreamWriter $script:ZIPCIO
					$script:ZIPCWRITE.AutoFlush = $true
				} catch {
					PipeClose
				}
			}
			function PipeSubmitPayload ($PipeInputPayload) {
				try {
					$script:ZIPCWRITE.WriteLine($PipeInputPayload)
					$script:ZIPCWRITE.Flush()
				} catch {}
			}
			function PipeClose {
				try {
					$script:ZIPCREAD.Dispose()
					$script:ZIPCIO.Dispose()
				} catch {}
				$script:ZIPCIO = $null
			}
			function PipeRead {
				try {
					$script:ZIPCIOENROLLRESPONSE = $script:ZIPCREAD.ReadLine()
					if (($script:ZIPCIOENROLLRESPONSE | ConvertFrom-Json).Error -IMATCH "failed to parse") {
						return 0
					} else {
						return 1
					}
				} catch {
					return 1
				}
			}
			function PipeStatus {
				if ($script:ZIPCIO.IsConnected -EQ "True") {
					return 1
				} else {
					return 0
				}
			}
			if ($PipeInputPayload -EQ "CLOSE") {
				PipeClose
			} elseif ($PipeInputPayload -EQ "OPEN") {
				if (-NOT(PipeStatus)) {
					PipeOpen
				}
				PipeStatus
			} elseif ($PipeInputPayload -EQ "READ") {
				PipeRead
			} elseif ($PipeInputPayload -EQ $null) {
				PipeStatus
			} else {
				PipeSubmitPayload "$PipeInputPayload"
			}
		}
		function GoToPrintJSON ($MessageVerbosity=$null, $MessageColor=$null, $Message=$null, $ErrorMessage=$null) {
				@{Verbosity=$MessageVerbosity;Color=$MessageColor;Message=$Message;Error=$ErrorMessage} | ConvertTo-Json -Compress
				start-sleep -Milliseconds 100
		}
	}

	$AllEnrollments | ForEach-Object {
		$TargetFile = ($_.Name).Replace(".jwt","")
		$TargetJWT = $TargetPath + "\" + $TargetFile + ".jwt"
		$TargetJSON = $TargetPath + "\" + $TargetFile + ".json"

		GoToPrint "1" "Yellow" "Reviewing enrollment JWT [$TargetFile]..."
		$JSONObj = Parse-JWTtoken (Get-Content "$TargetJWT")
		if (-NOT ($JSONObj -EQ "")) {
			$JSONExp = (([System.DateTimeOffset]::FromUnixTimeSeconds($JSONObj.exp)).DateTime).ToString()
			if ((Get-Date) -GT $JSONExp -AND $JSONObj.em -EQ "ott") {
				GoToPrint "1" "Red" "Enrollment of [$TargetFile] failed because it is expired as of [$JSONObj]."
				return
			} elseif (Test-Path -Path "$ZDEKSPath\$TargetFile.json" -PathType Leaf) {
				GoToPrint "1" "Yellow" "Enrollment of [$TargetFile] will not occur because it has already been enrolled."
				return
			} else {
				GoToPrint "3" "DarkGray" "The JWT points towards the OpenZiti controller at [$($JSONObj.iss)]."
				if ($JSONObj.em -EQ "ott") {
					GoToPrint "3" "DarkGray" "The JWT has an expiration of [$JSONExp]."
				} else {
					GoToPrint "3" "DarkGray" "The JWT is network-only, and has no expiration."
				}
				GoToPrint "3" "Green" "Enrollment of [$TargetFile] proceeding."
			}
		} else {
			GoToPrint "1" "Red" "Enrollment of [$TargetFile] failed because it is not a valid JWT."
			return
		}

		GoToPrint "1" "Yellow" "Now enrolling [$TargetFile] using method [$EnrollMethod], please wait..."
		if ($EnrollMethod -EQ "NATIVE") {

			$null = Start-Job -Name "$TargetFile-ZENROLL" -InitializationScript $PipeInit -ArgumentList "$TargetJWT","$TargetFile" -ScriptBlock {
				param($TargetJWT,$TargetFile)
				$TargetJWTString = Get-Content "$TargetJWT"

				$WAITCOUNT = 0
				do {
					$WAITCOUNT++
					if ($WAITCOUNT -GT 20) {
						GoToPrintJSON "1" "Red" "The OpenZiti IPC pipe failed to become available."
						ZPipeRelay "CLOSE"
						return
					}
					GoToPrintJSON "1" "DarkGray" "Waiting for OpenZiti IPC pipe to become available, please wait... ($WAITCOUNT/20)"
				} until (ZPipeRelay "OPEN")
				GoToPrintJSON "1" "DarkGray" "The OpenZiti IPC pipe became available."

				$WAITCount = 0
				do {
					$WAITCOUNT++
					if ($WAITCOUNT -GT 20) {
						GoToPrintJSON "1" "Red" "The OpenZiti IPC pipe failed to accept inbound enrollment request."
						ZPipeRelay "CLOSE"
						return
					}
					GoToPrintJSON "1" "DarkGray" "Sending the OpenZiti IPC pipe the enrollment request, please wait... ($WAITCOUNT/20)"
					ZPipeRelay "{""Data"":{""IdentityFilename"":""$TargetFile.json"",""JwtContent"":""$TargetJWTString"",""UseKeychain"":true},""Command"":""AddIdentity""}\n"
					start-sleep 1
				} until (ZPipeRelay "READ")
				GoToPrintJSON "1" "DarkGray" "The OpenZiti IPC pipe accepted the enrollment request."

				$script:ZIPCIOENROLLRESPONSE

				ZPipeRelay "CLOSE"
			}

			# Begin review of enrollment process until no more data is available on the process.
			$EnrollState = $false
			do {
				$CurrentLine = Receive-Job -Name "$TargetFile-ZENROLL" -ErrorAction Continue 6>&1
				if ([string]::IsNullOrWhiteSpace($CurrentLine)) {
					continue
				} else {
					$CurrentLineJSON = $CurrentLine | ConvertFrom-Json
				}
				# Enrollment flags.
				if (($CurrentLineJSON.Success -EQ $null) -AND ($CurrentLineJSON.Error -EQ $null) -AND ($CurrentLineJSON.Message -EQ $null)) {
					GoToPrint "1" "Red" "UNKNOWN_RESPONSE [$CurrentLine]"
				} elseif ($CurrentLineJSON.Success -EQ $null) {
					if ($CurrentLineJSON.Error) {
						GoToPrint $CurrentLineJSON.Verbosity $CurrentLineJSON.Color "$($CurrentLineJSON.Message) [$($CurrentLineJSON.Error)]"
					} else {
						GoToPrint $CurrentLineJSON.Verbosity $CurrentLineJSON.Color "$($CurrentLineJSON.Message)"
					}
				} elseif ($CurrentLineJSON.Success -EQ $true) {
					$EnrollState = $CurrentLineJSON.Success
					GoToPrint "1" "Green" "The OpenZiti IPC pipe returned [$EnrollState]."
					break
				} elseif ($CurrentLineJSON.Success -EQ $false) {
					$EnrollState = $CurrentLineJSON.Success
					GoToPrint "1" "Red" "The OpenZiti IPC pipe returned [$EnrollState] with message [$($CurrentLineJSON.Error)]."
					break
				}
			} while (((Get-Job -Name "$TargetFile-ZENROLL").HasMoreData) -EQ $true)

			Remove-Job -Force -Name $TargetFile-ZENROLL

			# If the flag of TRUE was caught, review that data payload from the output.
			if ($EnrollState) {
				$WAITCOUNT = 0;
				do {
					$WAITCOUNT++
					if ($WAITCOUNT -GT 5) {
						break
					}
					GoToPrint "1" "DarkGray" "Waiting for file population to [$((Get-Item $TargetJWT).BaseName).json], please wait... ($WAITCOUNT/5)"
					Start-Sleep 1
				} until (Test-Path -Path "$ZDEKSPath\$TargetFile.json" -PathType Leaf)
				GoToPrint "1" "Green" "Enrollment of [$TargetFile] succeeded."
			} else {
				GoToPrint "1" "Red" "Enrollment of [$TargetFile] failed."
				if (-NOT([string]::IsNullOrWhiteSpace($ErrorMessage))) {
					GoToPrint "1" "Red" "> MESSAGE: [$ErrorMessage]"
				}
			}

		} elseif ($EnrollMethod -EQ "ZCLI") {

			Start-Process "$ZTCLIRBinary" -WorkingDirectory "$TargetPath" -ArgumentList "edge enroll --jwt `"$TargetJWT`" --out `"$TargetJSON`" --rm" -Wait -ErrorVariable ERRETURN 2>&1 | out-null
			if (Test-Path $TargetJSON) {
				Move-Item -Path "$TargetJSON" -Destination "$ZDEKSPath" 2>&1 | out-null
				Start-Process "$ZTUNRBinary" -WorkingDirectory "$ZRPath" -ArgumentList "stop" -Wait
				Start-Sleep 2
				Start-Process "$ZTUNRBinary" -WorkingDirectory "$ZRPath" -ArgumentList "start" -Wait
				$WAITCOUNT = 0
				do {
					$WAITCOUNT++
					if ($WAITCOUNT -GT 30) {
						GoToPrint "1" "Red" "Core Software did not restart. Something is wrong."
						break
					}
					GoToPrint "1" "DarkGray" "Waiting for Core Software to restart, please wait... ($WAITCOUNT/30)"
					Start-Sleep 1
				} until ([System.IO.Directory]::GetFiles("\\.\\pipe\\") | findstr "ziti-edge-tunnel.sock")
				Start-Process "$ZTUNRBinary" -WorkingDirectory "$ZRPath" -ArgumentList "--identity $TargetJSON --on" -Wait
				GoToPrint "1" "Green" "Enrollment complete. Identity should appear in a few moments if there were no errors."
				GoToPrint "1" "Green" "Restarting UI Software..."
				Start-Process "$ZUIRBinary" -WorkingDirectory "$ZRPath"
			} else {
				GoToPrint "1" "Red" "Enrollment of [$TargetJWT] failed."
				GoToPrint "1" "Red" ">>> File not found [$TargetJSON]."
				if (-NOT($ERRETURN -EQ $null)) { GoToPrint "1" "Red" ">>> $ERRETURN" }
			}
		}
	}
	GoToPrint "1" "Green" "Enrollment complete."
}

# Download and install the software.
function RunInstall {
	GoToPrint "1" "White:DarkCyan" "########## ZDEWINSETUP ##########"
	New-Item -ItemType "directory" -Path $MyPath -Name $MyName 2>&1 | out-null
	GoToPrint "1" "DarkGray" "Created [$MyTmpPath] to work within."
	if ($JWTObtain -EQ "ASK" -AND [string]::IsNullOrWhiteSpace($InputJWT)) {
		$TargetPath = $MyTmpPath
		$TargetJWT = $MyName + ".jwt"
		$TargetJSON = $MyTmpPath + "\" + $MyName + ".json"
		GoToPrint "1" "DarkGray" "No JWT input string. Will ask later."
	} elseif ($JWTObtain -EQ "SEARCH" -AND [string]::IsNullOrWhiteSpace($InputJWT)) {
		$TargetPath = $MyPath
		$TargetJWT = "UNSET"
		$TargetJSON = "UNSET"
		GoToPrint "1" "DarkGray" "No JWT input string. Will search local directory later."
	} else {
		$TargetPath = $MyTmpPath
		$TargetJWT = $MyTmpPath + "\" + $MyName + ".jwt"
		$TargetJSON = $MyTmpPath + "\" + $MyName + ".json"
		GoToPrint "1" "DarkGray" "JWT input string available. Will attempt to utilize it later."
	}

	try {
		$HKLMData = Get-ItemProperty "$RegistryZSW" -ErrorAction SilentlyContinue
	} catch {
		GoToPrint "1" "Yellow" "Software is not present. Initiating installation."
	} finally {
		if ($HKLMData) {
			if ($OverwriteInst) {
				GoToPrint "1" "Yellow" "Software already exists and overwrite parameter is true. Initiating re-installation."
				if (DownloadInstall) {
					RunEnroll
					if ($InputMode -EQ "installadd") { RunAdd }
				}
			} else {
				GoToPrint "1" "Yellow" "Software already exists and overwrite parameter is not true. Bypassing re-installation."
				RunEnroll
				if ($InputMode -EQ "installadd") { RunAdd }
			}
		} else {
			if (DownloadInstall) {
				RunEnroll
				if ($InputMode -EQ "installadd") { RunAdd }
			}
		}
		$error.clear()
	}
}

# Remove only target entries from NRPT.
function RunRemove {
	GoToPrint "1" "White:DarkCyan" "########## DNSRULESREM ##########"
	if ($script:DNSCGSetting) {
		GoToPrint "1" "DarkGray" "Removing rules from the system with permission."
		Get-DnsClientNrptRule | Where "DisplayName" -EQ "$DisplayName" | ForEach-Object {
			$ThisDisplayName = $_.DisplayName
			$ThisDomain = $_.NameSpace
			$ThisNameServers = $_.NameServers
			GoToPrint "1" "DarkGray" "Removing rule [DisplayName=$ThisDisplayName] [Namespace=$ThisDomain] [NameServers=$ThisNameServers] from system."
			Remove-DnsClientNrptRule -Name $_.Name -Force
		}
		if ($DNSCGSetting.SuffixSearchList.Contains($AddSuffix)) {
			$SuffixIndex = $DNSCGSetting.SuffixSearchList.IndexOf($AddSuffix)
			GoToPrint "1" "DarkGray" "Search suffix [$AddSuffix] in the system. (Index=$SuffixIndex)."
			$DNSCGSetting.SuffixSearchList = @(foreach ($Name in $DNSCGSetting.SuffixSearchList) {if ($Name -ne $AddSuffix) {GoToPrint "1" "DarkGray" "$Name"} })
			Set-DnsClientGlobalSetting -SuffixSearchList $DNSCGSetting.SuffixSearchList
			GoToPrint "1" "White:DarkCyan" "##########################################################################################"
		} else {
			GoToPrint "1" "DarkGray" "Search suffix [$AddSuffix] not in the system. Doing nothing."
			GoToPrint "1" "White:DarkCyan" "##########################################################################################"
		}
		GoToPrint "1" "DarkGray" "Clearing DNS cache."
		Clear-DnsClientCache
	} else {
		GoToPrint "1" "Red" "Function ""remove"" cannot execute due to unavailable data method."
	}
}

# Remove all entries from NRPT.
function RunRemoveAll {
	GoToPrint "1" "White:DarkCyan" "########## DNSRULESREM ##########"
	if ($DNSCGSetting) {
		GoToPrint "1" "DarkGray" "Removing ALL rules from the system without question."
		Get-DnsClientNrptRule | ForEach-Object {
			$ThisDisplayName = $_.DisplayName
			$ThisDomain = $_.NameSpace
			$ThisNameServers = $_.NameServers
			if ($Force) {
				$UserConfirm = "y"
				GoToPrint "1" "DarkGray" ">>> Removing rule [DisplayName=$ThisDisplayName] [Namespace=$ThisDomain] [NameServers=$ThisNameServers] from system!"
			} else {
				$UserConfirm = Read-Host "Remove rule [DisplayName=$ThisDisplayName] [Namespace=$ThisDomain] [NameServers=$ThisNameServers] from system?"
			}
			if ($UserConfirm -EQ 'y') {
				Remove-DnsClientNrptRule -Name $_.Name -Force
			} else {
				GoToPrint "1" "DarkGray" ">>> Skipped removal of [DisplayName $ThisDisplayName]."
			}
		}
		if ($Force) {
			GoToPrint "1" "DarkGray" ">>> Removing ALL search suffix(es) ["$DNSCGSetting.SuffixSearchList"] from the global table!"
			$DNSCGSetting.SuffixSearchList = " "
		} else {
			$DNSCGSetting.SuffixSearchList = @(foreach ($Name in $DNSCGSetting.SuffixSearchList) {
				$UserConfirm = Read-Host "Remove search suffix [$Name] from the global table?"
				if ($UserConfirm -EQ 'n') {
					GoToPrint "1" "DarkGray" "$Name"
				}
			})
		}
		Set-DnsClientGlobalSetting -SuffixSearchList $DNSCGSetting.SuffixSearchList
		GoToPrint "1" "White:DarkCyan" "##########################################################################################"
		GoToPrint "1" "DarkGray" "Clearing DNS cache."
		Clear-DnsClientCache
	} else {
		GoToPrint "1" "Red" "Function ""removeall"" cannot execute due to unavailable data method."
	}
}

# Check AD and list details if available.
function RunADList {
	GoToPrint "1" "White:DarkCyan" "###### ACTIVEDIRECTORYLIST ######"
	$FullCreds = Get-Credential -Username $ThisUser.Name -Message "[NETFOUNDRY] Listing requires an authorized user and password."
	$ADList=(
		Get-WmiObject -Namespace "root/microsoftdns" -Query "select * from MicrosoftDNS_SRVtype" -ComputerName $AddSuffix -Credential $FullCreds -ErrorAction SilentlyContinue |
		?{($_.domainname -imatch $AddSuffix) -OR ($_.srvdomainname -imatch $AddSuffix)} |
		ft OwnerName,DomainName,srvdomainname,port -auto
	)
	if ($ADList.count -GT 0) {
		$ADList
	} else {
		GoToPrint "1" "Red" "ERROR: Could not execute the listing."
	}
}

# Command checking.
function CommandChecking {
	try {
		$private:CheckedCommands = Get-Command $RequiredCmds -ErrorAction stop
		if ($Verbosity -GE 3) {
			GoToPrint "3" "Green" "All required commands are present in the system."
			$CheckedCommands
		}
	} catch {
		GoToPrint "0" "White:Red" "ERROR: Command [$($_.Exception.Message.split("'")[1])] is not present in the system. Cannot continue."
		exit 1
	} finally {
		$error.clear()
	}

	try {
		$private:CheckedCommands = Get-Command $OptionalCmds -ErrorAction stop
		if ($Verbosity -GE 3) {
			GoToPrint "3" "Green" "All optional commands are present in the system."
			$CheckedCommands
		}
	} catch {
		GoToPrint "1" "Yellow" "WARNING: Command [$($_.Exception.Message.split("'")[1])] is not present in the system. This may limit some functionality."
	} finally {
		$error.clear()
	}
}

# Checking performed at initialization of the program.
function InitialChecking ($ParameterList=$null) {
	CommandChecking

	try {
		$script:FileHashLocal = (Get-FileHash "$MyPath\$MyRootExec" -Algorithm SHA1).Hash
	} catch {
		PrintBanner "INITERROR"
		GoToPrint "1" "Red" "ERROR: Could not ascertain a SHA1 hash of the runtime. Cannot continue."
		PrintBanner "TERM"
		exit 1
	} finally {
		$error.clear()
	}

	PrintBanner "INIT"

	if ($Verbosity -GE 2) {
		GoToPrint "2" "White:Black" "Runtime Information. CommandLine= [$($MyCommandLine)]"
		GoToPrint "2" "White:Black" "User is [$($ThisUser.Name)]."
		GoToPrint "2" "White:Black" "[$MyRootName] is running in the path [$MyPath]."
	}

	foreach ($Parameter in $ParameterList) {
		if ($Parameter.Name.Contains("InputMode") -AND $Parameter.Value) {
			$script:InputMode = $Parameter.Name.Replace("InputMode","").Trim()
			if ($Verbosity -GE 2) {
				if ($Parameter.Value){
					GoToPrint "2" "White:Black" "Runtime Information. InputMode  = [$($InputMode) $($Parameter.Value)]"
				} else {
					GoToPrint "2" "White:Black" "Runtime Information. InputMode  = [$($InputMode)]"
				}
			}
		} elseif ($Parameter.Value) {
			if ($Verbosity -GE 2) {
				GoToPrint "2" "White:Black" "Runtime Information. InputArg   = [$($Parameter.Name)] Value=[$($Parameter.Value)]"
			}
		}
		if ($Verbosity -GT 3) {
			Get-Variable -Name $Parameter.Value.Name -ErrorAction SilentlyContinue
		}
	}

	$ConfigDefaults | Invoke-Expression

	if ((Test-Path -Path "$MyConfig" -PathType Leaf) -AND (-NOT($CentralConfURL))) {
		GoToPrint "1" "Green" "Found local configuration file. Loading configuration."
		. "$MyConfig"
	} elseif ($CentralConfURL) {
		GoToPrint "1" "Yellow" "Loading the central configuration file [$CentralConfURL], please wait..."
		$CentralConfFile = ($CentralConfURL -Split "/")[-1]
		$CentralConfServer = $CentralConfURL -Replace "/$CentralConfFile"
		try {
			$CentralConfContext = Invoke-WebRequest -DisableKeepAlive -UseBasicParsing "$CentralConfURL"
			if ($Verbosity -GE 2) {
				GoToPrint "2" "White:Black" "CentralConfContext:"
				GoToPrint "1" "DarkGray" "$CentralConfContext"
			}
			$CentralConfContext | Invoke-Expression
		} catch {
			GoToPrint "1" "Red" "ERROR: Could not download the central configuration. Cannot continue."
			PrintBanner "TERM"
			exit 1
		} finally {
			$error.clear()
		}
		GoToPrint "1" "Green" "Successfully loaded the central configuration file."
	} else {
		GoToPrint "1" "Yellow" "Configuration file was not found. Building the configuration file."
		Set-Content -Path "$MyConfig" -Value "$ConfigDefaults"
		GoToPrint "1" "Green" "Configuration file was built from default. Continuing with default configuration."
		. "$MyConfig"
	}

	if ($script:InputMode) {
		if ($Verbosity -GE 2) {
			GoToPrint "2" "DarkGray" "Using the specified mode [$($script:InputMode)]."
		}
 	} else {
		if ($Verbosity -GE 1) {
			GoToPrint "1" "DarkGray" "No mode specified. Using default [$($DefaultMode)]."
		}
		$script:InputMode = $script:DefaultMode
	}

	try {
		$script:DNSCGSetting = Get-DnsClientGlobalSetting -ErrorAction SilentlyContinue
	} catch {
		GoToPrint "1" "Yellow" "WARNING: Command ""Get-DnsClientGlobalSetting"" was unavailable in this system. Some functions will be limited."
	} finally {
		$error.clear()
	}
}

# Check/validate/syncronize and download the program from a server.
function CheckUpdate {
	try {
		$FileHashServer	= (Get-FileHash -InputStream ([System.Net.WebClient]::new().OpenRead("$ServerURL/$ServerRootExec")) -Algorithm SHA1).Hash
	} catch {
		GoToPrint "1" "Yellow" "ERROR: A communication problem occurred. Running local version without updating."
	} finally {
		$error.clear()
	}

	if (($FileHashLocal -EQ $null) -OR ($FileHashServer -EQ $null)) {
		return 0
	} elseif ($FileHashLocal -EQ $FileHashServer) {
		GoToPrint "1" "Green" "Server reported matching version of the runtime. Proceeding."
		return 0
	} else {
		GoToPrint "1" "Yellow" "ATTENTION: Server reported a different version of the runtime. Will attempt to download the update."
		$BTRETURN = DownloadMethod "$ServerURL" "$ServerRootExec" "$MyPath\$MyRootExec"
		if ([string]::IsNullOrWhiteSpace($BTRETURN)) {
			GoToPrint "1" "Green" "Update file was downloaded. Relaunching."
			return 0
		} else {
			GoToPrint "1" "Red" "ERROR: Update file could not be downloaded. Continuing without update."
			GoToPrint "1" "Red" "$BTRETURN"
			return 1
		}
	}
}

# The help menu.
function PrintHelp {
	GoToPrint "1" "DarkGray" "[BLANK]                 : Will assume the default mode with no options of the program in its configuration parameters."
	GoToPrint "1" "DarkGray" "-env                    : [MODE] Will output the current rules/environment of the system."
	GoToPrint "1" "DarkGray" "-install [-JWT (STR)]   : [MODE] Will download/install NetFoundry software and enroll (using JWT string if provided)."
	GoToPrint "1" "DarkGray" "-installadd [-JWT (STR)]: [MODE] Will perform the actions of ""install"" then run the ""add"" function below."
	GoToPrint "1" "DarkGray" "-add                    : [MODE] Will add rules to the DNS subsystem (search domains)."
	GoToPrint "1" "DarkGray" "-remove                 : [MODE] Will remove rules from the DNS subsystem (explicitly/only implemented in the add function)."
	GoToPrint "1" "DarkGray" "-removeall              : [MODE] Will remove rules to the DNS subsystem (prompting for each or will not prompt if ""force"" option is present)."
	GoToPrint "1" "DarkGray" "-list                   : [MODE] Will list all the AD (SRV) entries that match the domain."
	GoToPrint "1" "DarkGray" "-resolve (NAME)         : [MODE] Will resolve using ""Resolve-DnsName"" for the ""NAME"" passed in."
	GoToPrint "1" "DarkGray" "-tasks (NAME/#)         : [MODE] Will review the OS tasks using ""Get-Processes"" for the ""NAME"" passed in or a CPU usage level above ""#"" (%) passed in."
	GoToPrint "1" "DarkGray" "-verbosity [0-3]        : [OPTION] Affects logging output where a higher number is more verbose."
	GoToPrint "1" "DarkGray" "-force                  : [OPTION] Affects certain [MODE]s which normally prompt by forcing an affirmative answer."
	GoToPrint "1" "DarkGray" "-JWT [STR]              : [OPTION] Affects certain [MODE]s which normally would seek a JWT."
	GoToPrint "1" "DarkGray" "-conf (URL)       : [OPTION] Will attempt to load configuration from ""URL"" (EX: https://fragale.us/PDATA/NFZDEWHelper_conf.ps1)"
}

# Cleanup any temporary files and folders before exit is called.
function RunCleanup {
	GoToPrint "1" "White:DarkCyan" "############ CLEANUP ############"
	Remove-Item $MyTmpPath -ErrorAction Ignore -Recurse
	GoToPrint "1" "Green" "Temporary files have been cleaned."
}

# The MAIN runtime function.
function MainRuntime {
	if (($UnknownArgs) -OR ($InputMode -EQ "help")) {
		if ($UnknownArgs) {
			GoToPrint "1" "White:Red" "ERROR: Input ""$UnknownArgs"" are not recognized by the program."
		}
		PrintHelp
	} elseif ($InputMode -EQ "environment") {
		RunGetCurrentEnv "ALL"
	} elseif ($InputMode -EQ "install" -OR $InputMode -EQ "installadd") {
		RunGetCurrentEnv "ZPROCESSES"
		RunInstall
	} elseif ($InputMode -EQ "remove") {
		RunRemove
		RunGetCurrentEnv "DNS"
	} elseif ($InputMode -EQ "removeall") {
		RunRemoveAll
		RunGetCurrentEnv "DNS"
	} elseif ($InputMode -EQ "add") {
		RunAdd
		RunGetCurrentEnv "DNS"
	} elseif ($InputMode -EQ "list") {
		RunGetCurrentEnv "DNS"
		RunADList
	} elseif ($InputMode -EQ "resolve") {
		RunGetResolution $InputModeResolve
	} elseif ($InputMode -EQ "tasks") {
		if ($InputModeTasks -IS [int]) {
			RunGetTasks $InputModeTasks "NUM"
		} else {
			RunGetTasks $InputModeTasks "STR"
		}
	} else {
		GoToPrint "1" "Red" "ERROR: The run mode [$InputMode] is not supported."
		PrintHelp
	}
	RunCleanup
}

###################################################################################################################
### MAIN ###
InitialChecking (Get-Variable -Name ($ParameterList = (Get-Command -Name ("$MyPath\$MyRootExec")).Parameters).Values.Name -ErrorAction SilentlyContinue)

switch (CheckAdmin) {
	0 {
		GoToPrint "1" "Green" "Runtime is elevated."
		if ($AutoUpdate -EQ "true") {
			GoToPrint "1" "Yellow" "Checking for updates, please wait..."
			if (CheckUpdate) {
				try {
					Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -NoLogo -NoProfile -Mta -WindowStyle Maximized",
					"-Command",
					"Start-Transcript -Append \`"$MyPath\$MyRootName.log\`";
						& \`"$MyPath\$MyRootName\`" $MyCommandLine;
					"
					break
				} catch {
					GoToPrint "1" "White:Red" "ERROR: Elevation could not be achieved. Cannot continue."
					Start-Sleep 5
				} finally {
					$error.clear()
				}
			} else {
				MainRuntime
				break
			}
		} else {
			GoToPrint "1" "DarkGray" "Checking for updates is not enabled."
			MainRuntime
			break
		}
	}
	1 {
		GoToPrint "1" "Yellow" "Runtime is NOT elevated. Elevation will be attempted."
		try {
			if ($LogElevation) {
				Start-Process powershell -Verb "RunAs" -ArgumentList "-ExecutionPolicy Bypass -NoLogo -NoProfile -Mta -WindowStyle Maximized",
				"-Command",
				"Start-Transcript -Append \`"$MyPath\$MyRootName.log\`";
					& \`"$MyPath\$MyRootExec\`" $MyCommandLine;
					& Write-Host \`"Log created at [\`"$MyPath\$MyRootName.log\`"]. Window will close in 10 seconds.\`";
					& Start-Sleep 10;
				"
			} else {
				Start-Process powershell -Verb "RunAs" -ArgumentList "-ExecutionPolicy Bypass -NoLogo -NoProfile -Mta -WindowStyle Maximized",
				"-Command",
				"\`"$MyPath\$MyRootExec\`" $MyCommandLine;
					& Write-Host \`"Window will close in 10 seconds.\`"
				"
			}
		} catch {
			GoToPrint "1" "White:Red" "ERROR: Elevation could not be achieved. Cannot continue."
			Start-Sleep 5
		} finally {
			$error.clear()
		}
		break
	}
	2 {
		GoToPrint "1" "White:Red" "ERROR: The Operating System is not at a build level which supports the required operations."
		pause
		break
	}
	default {
		GoToPrint "1" "White:Red" "ERROR: A failure occurred preventing further runtime."
		pause
		break
	}
}

PrintBanner "TERM"
###################################################################################################################
# EOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOFEOF #
###################################################################################################################


