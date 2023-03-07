# NetFoundry OpenZITI Utility: Compile and Build Helper for OpenWRT

![OpenZITI_OpenWRT][PS-shield]

## How to Use

### Prerequisite
This utility was written for Ubuntu 20.04+.  Though it may work on other environments that utilize the APT package manager, it is not tested on others.  Run on the build server as a BUILD CAPABLE USER (ROOT is assumed in this example).

### Running the Compile and Builder
Once this repo has been cloned to the building server (or the raw script downloaded), change the run permissions of the file for execute rights. 
> chmod 755 ./OWRT_Builder.bash

Modify the header of the file as required, then run the utility.
> ./OWRT_Builder.bash

[PS-shield]: https://img.shields.io/badge/Code%20Basis-Linux%20BASH-blue.svg