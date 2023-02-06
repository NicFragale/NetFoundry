# Powershell.exe -ExecutionPolicy Bypass -Command "Invoke-WebRequest -UseBasicParsing https://fragale.us/PDATA/NFZDEWHelper.ps1 -OutFile NFZDEWHelper.ps1; .\NFZDEWHelper.ps1 -conf https://fragale.us/PDATA/NFZDEWHelper_BASICINSTALL.ps1"
$script:AutoUpdate      = $true
$script:InputMode       = "install"
$script:OverwriteInst   = $false
$script:Verbosity       = 3