# NetFoundry OpenZITI Utility: Compile and Build Helper for OpenWRT

![OpenZITI_OpenWRT][PS-shield]

## How to Use

### (Build Machine) Running the Compile and Builder "OWRT_Builder.bash"
This utility was written for Ubuntu 22.04+.  Though it may work on other environments that utilize the APT package manager, it is not tested on others.  Run on the build server as a BUILD CAPABLE USER (ROOT is assumed in this example).

Once this repo has been cloned to the building server (or the raw utility downloaded), change the run permissions of the file for execute rights, modify the header of the file as required, then run the utility.
> chmod 755 ./OWRT_Builder.bash
>> ./OWRT_Builder.bash

### (Router Device) Running the Installer and Setup "OWRT_Installer.bash"
Run on the router device as the administrative user (ROOT is assumed in this example).

Once this repo has been cloned to the router device (or the raw utility downloaded), change the run permissions of the file for execute rights, modify the header of the file as required, then run the utility.
> chmod 755 ./OWRT_Installer.bash
>> ./OWRT_Installer.bash

[PS-shield]: https://img.shields.io/badge/Code%20Basis-Linux%20BASH-blue.svg