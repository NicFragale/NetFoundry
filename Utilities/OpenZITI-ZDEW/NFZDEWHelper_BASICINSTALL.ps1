#  Powershell.exe -ExecutionPolicy Bypass -Command 'Invoke-WebRequest -Headers @{"""Cache-Control"""="""no-cache"""} -UseBasicParsing https://raw.githubusercontent.com/NicFragale/NetFoundry/main/Utilities/OpenZITI-ZDEW/NFZDEWHelper.ps1 -OutFile NFZDEWHelper.ps1; .\NFZDEWHelper.ps1 -conf https://raw.githubusercontent.com/NicFragale/NetFoundry/main/Utilities/OpenZITI-ZDEW//NFZDEWHelper_BASICINSTALL.ps1'
$script:AutoUpdate      = $true
$script:InputMode       = "install"
$script:OverwriteInst   = $false