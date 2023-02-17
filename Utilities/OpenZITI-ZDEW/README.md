# NetFoundry OpenZITI Utility: Helper for Windows OpenZITI Desktop Edge

![Designed for Windows OpenZITI Desktop Edge][PS-shield]

 ## TLDR; ?
 Get started quickly with a silent installation and enrollment.  Place your JWTs in a folder of your choice.  Open Windows Explorer on that folder and paste in the following.
 > Powershell.exe -ExecutionPolicy Bypass -Command "Invoke-WebRequest -DisableKeepAlive -UseBasicParsing https://raw.githubusercontent.com/NicFragale/NetFoundry/main/Utilities/OpenZITI-ZDEW/NFZDEWHelper.ps1 -OutFile NFZDEWHelper.ps1; .\NFZDEWHelper.ps1 -install"

<center> ![Example][Example] </center>

<center>Hungry for more?  Read further below!</center>

---


## How to Use

Regardless of which system controls the endpoint (CloudZITI or OpenZITI) the endpoint must be registered as a valid identity. If you wish to try out the FREE TEAMS EDITION of CloudZITI, sign up at [CloudZITI](https://nfconsole.io/signup).

### Prerequisite
Clone and build your own OpenZITI network with [OpenZITI](https://github.com/openziti) or sign up for free to the [CloudZITI](https://nfconsole.io/signup) which automatically deploys all elements for you.

### MODE ONE: Silent Installation and Enrollment of Identities
This utility can boot strap itself, install OpenZITI Windows Desktop Edge, and enroll any available identities.

1. Place identity files [JWTs] in the folder that the explorer window is showing and the utility will find and utilize them. 
2. Run the following in an explorer window.  

> Powershell.exe -ExecutionPolicy Bypass -Command "Invoke-WebRequest -DisableKeepAlive -UseBasicParsing https://raw.githubusercontent.com/NicFragale/NetFoundry/main/Utilities/OpenZITI-ZDEW/NFZDEWHelper.ps1 -OutFile NFZDEWHelper.ps1; .\NFZDEWHelper.ps1 -conf https://raw.githubusercontent.com/NicFragale/NetFoundry/main/Utilities/OpenZITI-ZDEW/NFZDEWHelper_BASICINSTALL.ps1"

This command is broken down as:
* Runs Powershell.exe (A Shell for Windows) with a command syntax.
* Invoke-WebRequest (Powershell Commandlet) is run to retrieve this utility from GitHub and place it into a file located in the folder where the command was launched from.
* Subsequent to download of the utility, it is run in the same Powershell session with a [-conf] flag which is to be used for default configurations for running.  This option is not required, but helps to simplify the command syntax for installation.  
* The configuration file is also pulled from GitHub.  Feel free to review it, download it locally, modify it, or remove it from the option chain.
* If you wish to use an identity [JWTs] through the file context instead of transferring the file itself, you may add [-JWT (JWTCONTEXT)] to the runtime options string.

Once run, the command performs the following:
1. Downloads the latest version of the NetFoundry OpenZITI Desktop Edge for Windows.
2. Installs it to the local machine silently with (usually) only one prompt for elevation on the machine.
3. If there are any identities [JWTs] in the folder which was used for running, those will be attempted to be enrolled silently as well.
4. At conclusion, the OpenZITI monitor UI will be shown with the enrolled identities ready to be used.

### MODE TWO: Print Environment
This utility can boot strap itself and print the environment with regards to OpenZITI installation and runtime tasks.

> Powershell.exe -ExecutionPolicy Bypass -Command "Invoke-WebRequest -DisableKeepAlive -UseBasicParsing https://raw.githubusercontent.com/NicFragale/NetFoundry/main/Utilities/OpenZITI-ZDEW/NFZDEWHelper.ps1 -OutFile NFZDEWHelper.ps1; .\NFZDEWHelper.ps1 -conf https://raw.githubusercontent.com/NicFragale/NetFoundry/main/Utilities/OpenZITI-ZDEW/NFZDEWHelper_ENVIRONMENT.ps1"

This command is broken down as:
* Runs Powershell.exe (A Shell for Windows) with a command syntax.
* Invoke-WebRequest (Powershell Commandlet) is run to retrieve this utility from GitHub and place it into a file located in the folder where the command was launched from.
* Subsequent to download of the utility, it is run in the same Powershell session with a [-conf] flag which is to be used for default configurations for running.  This option is not required, but helps to simplify the command syntax for installation.  
* The configuration file is also pulled from GitHub.  Feel free to review it, download it locally, modify it, or remove it from the option chain.

Once run, the command performs the following:
1. Prints any running OpenZITI runtime tasks and their state.
2. Prints the DNS entries added by OpenZITI to the machine.

### OTHER MODES
There are other modes of operation handled by the utility.  To see them, simply run the utility with the option [-h].

For more information, see the open source project page at [OpenZITI](https://github.com/openziti).

[PS-shield]: https://img.shields.io/badge/Code%20Basis-Windows%20PowerShell-blue.svg
[Example]: https://raw.githubusercontent.com/NicFragale/NetFoundry/main/Utilities/OpenZITI-ZDEW/ZDEW_Silent.gif
