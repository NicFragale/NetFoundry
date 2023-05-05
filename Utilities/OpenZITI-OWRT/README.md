# NetFoundry OpenZITI Utility: Compile and Build Helper for OpenWRT

![OpenZITI_OpenWRT][PS-shield]

## How to Use

### (Build Machine) Running the Compile and Builder "OWRT_Builder.bash"
This utility was written for Ubuntu 22.04+.  Though it may work on other environments that utilize the APT package manager, it is not tested on others.  Run on the build server as a BUILD CAPABLE USER (ROOT is assumed in this example).

Once this repo has been cloned to the building server (or the raw utility downloaded), change the run permissions of the file for execute rights, modify the header of the file as required, then run the utility.  Alternatively, you can run directly in a shell so long as you have BASH available.
> chmod 755 ./OWRT_Builder.bash
>> ./OWRT_Builder.bash [OpenWRT_Version] [Target_Part_A] [Target_Part_B] [OpenZITI_Tunnel_Version]
-OR-
> bash <(curl -Ls https://owrtbuilder.fragale.us [OpenWRT_Version] [Target_Part_A] [Target_Part_B] [OpenZITI_Tunnel_Version])
* Example: ./OWRT_Builder.bash "22.03.03" "ath79" "nand" "latest"
* Example: ./OWRT_Builder.bash "22.03.03" "ipq806x" "generic" 
* Example: ./OWRT_Builder.bash "22.03.03" "ipq806x" "generic" "0.20.03"

- [OpenWRT_Version]: The OpenWRT version you wish to use [https://downloads.openwrt.org/releases].
- [Target_Part_A]: The first part of the target platform from within the version to use.
- [Target_Part_B]: The second part of the target platform from within the version to use. 
- [OpenZITI_Tunnel_Version]: The OpenZITI Tunnel version you wish to use [https://github.com/openziti/ziti-tunnel-sdk-c/releases].  If not present, assumes "latest".

### (Router Device) Running the Installer and Setup "OWRT_Installer.bash"
Run on the router device as the administrative user (ROOT is assumed in this example).

Once this repo has been cloned to the router device (or the raw utility downloaded), change the run permissions of the file for execute rights, modify the header of the file as required, then run the utility.  Alternatively, you can run directly in a shell so long as you have BASH available.
> chmod 755 ./OWRT_Installer.bash
>> ./OWRT_Installer.bash [OpenZITI_Tunnel_Compressed_Build] [URL_To_Download]
-OR-
> bash <(curl -Ls https://owrtbuilder.fragale.us [OpenZITI_Tunnel_Compressed_Build] [URL_To_Download])
* Example: ./OWRT_Installer.bash "OpenWRT-22.03.3-ath79_nand.gz" "https://github.com/NicFragale/NetFoundry/raw/main/Utilities/OpenZITI-OWRT/Sample_Builds"

- [OpenZITI_Tunnel_Compressed_Build]: The compressed build of the OpenZITI binary built by the first step.
- [URL_To_Download]: The URL location of the compressed build.

[PS-shield]: https://img.shields.io/badge/Code%20Basis-Linux%20BASH-blue.svg
