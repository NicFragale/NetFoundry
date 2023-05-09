<p><center>
    <h1><b>NetFoundry OpenZITI Utility: Compile and Build Helper for OpenWRT</b></h1>
    
![OpenZITI_OpenWRT][PS-shield] 

</center></p>

<br>

---

<p><center>
    <h2><b>TL;DR These commands are usually all you need!</b></h2>
</center></p>

<p>
    
Run this on your build machine to obtain the compressed runtime file.
```
bash <(curl -Ls https://owrtbuilder.fragale.us) [OpenWRT_Version] [Target_Part_A] [Target_Part_B]
```

Copy the compressed runtime file to your OpenWRT router and place it into `/tmp`.  Then run this on your OpenWRT router.
```
opkg update && opkg install bash
bash <(curl -Ls https://owrtinstaller.fragale.us)
```

<br>

---

<p><center>
    <h2><b>(Build Machine) Running the Compile and Builder "OWRT_Builder.bash"</b></h2>
</center></p>

This utility was written for Ubuntu 22.04+.  Though it may work on other environments that utilize the APT package manager, it is not tested on others.  Run on the build server as a BUILD CAPABLE USER (ROOT is assumed in this example).

Once this repo has been cloned to the building server (or the raw utility downloaded), change the run permissions of the file for execute rights, and then run the utility.  Alternatively, you can run directly in a shell so long as you have BASH available.
```
chmod 755 ./OWRT_Builder.bash
./OWRT_Builder.bash [OpenWRT_Version] [Target_Part_A] [Target_Part_B] [OpenZITI_Tunnel_Version]
```

-OR-

```
bash <(curl -Ls https://owrtbuilder.fragale.us [OpenWRT_Version]) [Target_Part_A] [Target_Part_B] [OpenZITI_Tunnel_Version]
```
* EXAMPLES:
    * bash <(curl -Ls https://owrtbuilder.fragale.us) "22.03.03" "ath79" "nand" "latest"
    * bash <(curl -Ls https://owrtbuilder.fragale.us) "22.03.03" "ipq806x" "generic"
    * bash <(curl -Ls https://owrtbuilder.fragale.us) "22.03.03" "ipq806x" "generic" "0.20.03"

* WHERE: 
    * `[OpenWRT_Version]` is the OpenWRT version you wish to use [https://downloads.openwrt.org/releases].
    * `[Target_Part_A]` is the first part of the target platform from within the version to use.
    * `[Target_Part_B]` is the second part of the target platform from within the version to use.
    * `[OpenZITI_Tunnel_Version]` is the OpenZITI Tunnel version you wish to use [https://github.com/openziti/ziti-tunnel-sdk-c/releases].  If not, * present, assumes "latest".

<br>

---

<p><center>
    <h2><b>(Router Device) Running the Installer and Setup "OWRT_Installer.bash"</b></h2>
</center></p>

Run on the router device as the administrative user (ROOT is assumed in this example).

Once this repo has been cloned to the router device (or the raw utility downloaded), change the run permissions of the file for execute rights, and then run the utility.  Alternatively, you can run directly in a shell so long as you have BASH available.
```
chmod 755 ./OWRT_Installer.bash
./OWRT_Installer.bash [OpenZITI_Tunnel_Compressed_Build] [URL_To_Download]
```
-OR-
```
bash <(curl -Ls https://owrtinstaller.fragale.us [OpenZITI_Tunnel_Compressed_Build] [URL_To_Download])
```
* Example: bash <(curl -Ls https://owrtinstaller.fragale.us) "OpenWRT-22.03.3-ath79_nand.gz" "https://owrtbuilds.fragale.us/0.21.0/"<br>
* Example: bash <(curl -Ls https://owrtinstaller.fragale.us) "OpenWRT-22.03.3-ipq806x_generic.gz"<br>
* Example: bash <(curl -Ls https://owrtinstaller.fragale.us)<br>

- [OpenZITI_Tunnel_Compressed_Build]: The compressed build of the OpenZITI binary built by the first step in format "OpenWRT-[OWRT_VERSION]-[TARGETA]_[TARGETB].gz".
- [URL_To_Download]: The URL location of the compressed build - folder path only.

HINT: If you specify the compressed file name without specifying a URL, the utility will seek to find it locally in (/tmp).
HINT: If you run the utility without any syntax, it will be assumed that the compressed file (format as above) or uncompressed file (format as ziti-edge-tunnel) exists locally in (/tmp).  To find the appropriate compressed file name, the utility will build the name from the components of the file (/etc/os-release) if it can.
HINT: The utility will setup the runtime if spaces allows, however, if less than 7MB is available to install, it will attempt to run DYNAMICALLY.  In this mode of operation, all services are created to launch the runtime, except the runtime itself it will be downloaded at boottime - every time.  This allows a limited space device to run OpenZITI even when space is available.  Ideally, the download location is within a private LAN (NOT INTERNET), uses HTTPS as the protocol, and is located on a server that you control for security reasons.  Note that in this mode you MUST specify the compressed file name (format as above) AND URL where it can be obtained or this operation will fail.  

[PS-shield]: https://img.shields.io/badge/Code%20Basis-Linux%20BASH-blue.svg
