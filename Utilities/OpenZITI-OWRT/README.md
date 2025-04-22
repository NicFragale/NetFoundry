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
curl -fsSL https://owrtbuilder.fragale.us | bash -s -- [OpenWRT_Version] [Target_Part_A] [Target_Part_B]
```

Copy the compressed runtime file to your OpenWRT router and place it into `/tmp`.  Then run this on your OpenWRT router.
```
opkg update && opkg install bash
curl -fsSL https://owrtinstaller.fragale.us | bash
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
WHERE:
* `[OpenWRT_Version]` is the OpenWRT version you wish to use [https://downloads.openwrt.org/releases].
* `[Target_Part_A]` is the first part of the target platform from within the version to use.
* `[Target_Part_B]` is the second part of the target platform from within the version to use.
* `[OpenZITI_Tunnel_Version]` is the OpenZITI Tunnel version you wish to use [https://github.com/openziti/ziti-tunnel-sdk-c/releases].  If not present, assumes "latest".

EXAMPLES:
```
# Run the builder with OpenWRT version "22.03.3", platform "ath79/nand", using OpenZITI version "latest".
curl -fsSL https://owrtbuilder.fragale.us | bash -s -- "22.03.3" "ath79" "nand" "latest"
```
```
# Run the builder with OpenWRT version "22.03.3", platform "ipq806x/generic", assume OpenZITI version "latest".
curl -fsSL https://owrtbuilder.fragale.us | bash -s -- "22.03.3" "ipq806x" "generic"
```

```
# Run the builder with OpenWRT version "22.03.3", platform "ath79/nand", using OpenZITI version "0.21.0".
curl -fsSL https://owrtbuilder.fragale.us | bash -s -- "22.03.3" "ipq806x" "generic" "0.21.0"
```


<br>

---

<p><center>
    <h2><b>(Router Device) Running the Installer and Setup "OWRT_Installer.bash"</b></h2>
</center></p>

Run on the router device as the administrative user (ROOT is assumed in this example).

Once this repo has been cloned to the router device (or the raw utility downloaded), change the run permissions of the file for execute rights, and then run the utility.  Alternatively, you can run directly in a shell so long as you have BASH available.

NOTE: If you are attempting to upgrade to a newer version, you must first remove or rename the binary in the run time directory.  This is a precaution to prevent a bad upgrade from removing your ability to reach the system.  Run the utility normally after the file is moved/removed.

```
chmod 755 ./OWRT_Installer.bash
./OWRT_Installer.bash [OpenZITI_Tunnel_Compressed_Build] [URL_To_Download]
```
-OR-
```
curl -fsSL https://owrtinstaller.fragale.us | bash -s -- [OpenZITI_Tunnel_Compressed_Build] [URL_To_Download]
```
WHERE:
* `[OpenZITI_Tunnel_Compressed_Build]` is the name of the compressed build of the OpenZITI binary built by the first step in format "OpenWRT-[OWRT_VERSION]-[TARGETA]_[TARGETB].gz".
* `[URL_To_Download]` is the URL location of the compressed build - folder path only.

EXAMPLES:
```
# Run the installer with compressed file "OpenWRT-22.03.3-ath79_nand.gz" which is located at "https://owrtbuilds.fragale.us/0.21.0/".
curl -fsSL https://owrtinstaller.fragale.us | bash -s -- "OpenWRT-22.03.5-ath79_nand.gz" "https://owrtbuilds.fragale.us/0.21.5"
```
```
# Run the installer with compressed file "OpenWRT-22.03.3-ipq806x_generic.gz" which is located locally in (/tmp).
curl -fsSL https://owrtinstaller.fragale.us | bash -s -- "OpenWRT-22.03.5-ipq806x_generic.gz"
```
```
# Run the installer and review the system to determine the name of the compressed file which is located locally in (/tmp) OR locate the uncompressed file (ziti-edge-tunnel) in (/tmp) if it exists instead.
curl -fsSL https://owrtinstaller.fragale.us | bash
```

> HINT: The utility will setup the runtime if spaces allows, however, if less than 7MB is available to install, it will attempt to run DYNAMICALLY.  In this mode of operation, all services are created to launch the runtime, except the runtime itself it will be downloaded at boottime - every time.  This allows a limited space device to run OpenZITI even when space is limited.  Ideally, the download location is within a private LAN (NOT INTERNET), uses HTTPS as the protocol, and is located on a server that you control for security reasons.  Note that in this mode you MUST specify the compressed file name (format as above) AND URL where it can be obtained or this operation will fail.

[PS-shield]: https://img.shields.io/badge/Code%20Basis-Linux%20BASH-blue.svg
