# Powershell.exe -ExecutionPolicy Bypass -Command "Invoke-WebRequest -DisableKeepAlive -UseBasicParsing https://raw.githubusercontent.com/NicFragale/NetFoundry/main/Utilities/OpenZITI-ZDEW/NFZDEWHelper.ps1 -OutFile NFZDEWHelper.ps1; .\NFZDEWHelper.ps1 -conf https://raw.githubusercontent.com/NicFragale/NetFoundry/main/Utilities/OpenZITI-ZDEW/NFZDEWHelper_BASICINSTALL.ps1"
$script:DefaultMode		= "install" # Default mode if no options arguments are passed in. See help menu for options.
#$script:AutoUpdate		= "true" # Instructs the program to check for an update to itself from the specified server (true=try to update | false=ignore).
#$script:ServerURL		= "https://raw.githubusercontent.com/NicFragale/NetFoundry/main/Utilities/OpenZITI-ZDEW" # Update server URL.
#$script:ServerRootExec	= "NFZDEWHelper.ps1" # Filename of runtime on update server.
#$script:ZDERVer		= "AUTO" # ZITI Desktop Edge (Win) version to target from repos (AUTO=find automatically | [X.XX.XX=target this version]).
#$script:ZCLIRVer		= "AUTO" # ZITI CLI version to target from repos (AUTO=find automatically | [X.XX.XX]=target this version).
$script:OverwriteInst	= "true" # If set to "true" will overwrite if software already exists (true=overwrite | false=ignore).
#$script:JWTObtain		= "SEARCH" # Default Enrollment Action when no JWT string is passed in (ASK=Ask with prompt for JWT string | SEARCH=Find any JWTs in local dir).
#$script:EnrollMethod	= "NATIVE" # Method in which to invoke enrollment (NATIVE=IPC | ZCLI=ZITI CLI).
#$script:DLDefaultMethod= "BITS" # The default method by which to request downloads (BITS | WEBCLIENT).
#$script:LogElevation	= "true" # A flag which causes the elevation event and subsequent runtime to be placed into a log file (true=logging enabled | false=no logging).
#$script:AddSuffix		= "domain.local" # Change the following DOMAIN and NAMESERVERS as appropriate.
#$script:Domain			= @(".domain.local")
#$script:NameServers	= @("1.2.3.4" "5.6.7.8")