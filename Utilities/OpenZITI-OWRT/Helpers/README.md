# NetFoundry OpenWRT Utility: WiFi Maintenance Helper

![OpenZITI_OpenWRT][PS-shield]

This is a helper utility which turns on the inactive WiFi, enables it as an Access Point, and permits access to the router for a period of time before the WiFi is shutdown.  

## WARNING
Supports only GL.iNet GL-AR300M16 router.  Possibly works on others, but has not been tested as such.

## How to Use

### (Router Device) Running the Installer and Setup "OWRT_WIFI_Maint.bash"
Run on the router device as the administrative user (ROOT is assumed in this example).

Once this repo has been cloned to the router device (or the raw utility downloaded), change the run permissions of the file for execute rights, modify the header of the file as required, then run the utility.
> chmod 755 ./OWRT_WIFI_Maint.bash
>> ./OWRT_WIFI_Maint.bash

[PS-shield]: https://img.shields.io/badge/Code%20Basis-Linux%20BASH-blue.svg
