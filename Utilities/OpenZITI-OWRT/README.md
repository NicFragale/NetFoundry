# NetFoundry OpenZITI Utility: Compile and Build Helper for OpenWRT

![OpenZITI_OpenWRT][PS-shield]

## How to Use

## TL;DR These commands are usually all you need!

Run this on your build machine to obtain the compressed runtime file.
* bash <(curl -Ls https://owrtbuilder.fragale.us) [OpenWRT_Version] [Target_Part_A] [Target_Part_B]

Copy the compressed runtime file to your OpenWRT router and place it into (/tmp).  Then run this on your OpenWRT router.
* opkg update && opkg install bash
* bash <(curl -Ls https://owrtinstaller.fragale.us)

### (Build Machine) Running the Compile and Builder "OWRT_Builder.bash"
This utility was written for Ubuntu 22.04+.  Though it may work on other environments that utilize the APT package manager, it is not tested on others.  Run on the build server as a BUILD CAPABLE USER (ROOT is assumed in this example).

Once this repo has been cloned to the building server (or the raw utility downloaded), change the run permissions of the file for execute rights, and then run the utility.  Alternatively, you can run directly in a shell so long as you have BASH available.
> chmod 755 ./OWRT_Builder.bash
>> ./OWRT_Builder.bash [OpenWRT_Version] [Target_Part_A] [Target_Part_B] [OpenZITI_Tunnel_Version]

-OR-

> bash <(curl -Ls https://owrtbuilder.fragale.us [OpenWRT_Version]) [Target_Part_A] [Target_Part_B] [OpenZITI_Tunnel_Version]
* Example: bash <(curl -Ls https://owrtbuilder.fragale.us) "22.03.03" "ath79" "nand" "latest"
* Example: bash <(curl -Ls https://owrtbuilder.fragale.us) "22.03.03" "ipq806x" "generic"
* Example: bash <(curl -Ls https://owrtbuilder.fragale.us) "22.03.03" "ipq806x" "generic" "0.20.03"

- [OpenWRT_Version]: The OpenWRT version you wish to use [https://downloads.openwrt.org/releases].
- [Target_Part_A]: The first part of the target platform from within the version to use.
- [Target_Part_B]: The second part of the target platform from within the version to use. 
- [OpenZITI_Tunnel_Version]: The OpenZITI Tunnel version you wish to use [https://github.com/openziti/ziti-tunnel-sdk-c/releases].  If not present, assumes "latest".

### (Router Device) Running the Installer and Setup "OWRT_Installer.bash"
Run on the router device as the administrative user (ROOT is assumed in this example).

Once this repo has been cloned to the router device (or the raw utility downloaded), change the run permissions of the file for execute rights, and then run the utility.  Alternatively, you can run directly in a shell so long as you have BASH available.
> chmod 755 ./OWRT_Installer.bash
>> ./OWRT_Installer.bash [OpenZITI_Tunnel_Compressed_Build] [URL_To_Download]

-OR-

> bash <(curl -Ls https://owrtinstaller.fragale.us [OpenZITI_Tunnel_Compressed_Build] [URL_To_Download])
* Example, expecting to find the compressed file at the URL folder specified: bash <(curl -Ls https://owrtinstaller.fragale.us) "OpenWRT-22.03.3-ath79_nand.gz" "https://github.com/NicFragale/NetFoundry/raw/main/Utilities/OpenZITI-OWRT/Builds/0.21.0"
* Example, expecting to find the compressed file in (/tmp): bash <(curl -Ls https://owrtinstaller.fragale.us) "OpenWRT-22.03.3-ipq806x_generic.gz"
* Example, expecting to figure out what compressed file should be found in (/tmp) based on (/etc/os-release) info: bash <(curl -Ls https://owrtinstaller.fragale.us)

- [URL_To_Download]: The URL location of the compressed build - folder path only.
- [OpenZITI_Tunnel_Compressed_Build]: The compressed build of the OpenZITI binary built by the first step in format "OpenWRT-[OWRT_VERSION]-[TARGETA]_[TARGETB].gz".

HINT: The utility will setup the runtime if spaces allows, however, if less than 7MB is available to install, it will attempt to run DYNAMICALLY.  In this mode of operation, all services are created to launch the runtime, except the runtime itself it will be downloaded at boottime - every time.  This allows a limited space device to run OpenZITI even when space is available.  Ideally, the download location is within a private LAN (NOT INTERNET), uses HTTPS as the protocol, and is located on a server that you control for security reasons.  Note that in this mode you MUST specify the compressed file name (format as above) AND URL where it can be obtained or this operation will fail.  

[PS-shield]: https://img.shields.io/badge/Code%20Basis-Linux%20BASH-blue.svg
