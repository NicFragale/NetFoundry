<p><center>
<h1><b>NetFoundry Utility: Automation for 3rd Party CAs</b></h1>

![AutoCA][PS-shield]

</center></p>
<br>

This utility acts as a quick and easy way to interact with the NetFoundry Orchestration Platform (MOP) with a limited set of capabilities.  The WEB UI (Console) that acts as a mechanism for general MOP interactions using HTTP provides a rich experience for an admin of a ZITI network.  Though, a CLI construct can sometimes lend to a faster method of interactation with such a system.

For official usage and implementation of 3rd Party CAs in NetFoundry, visit the support page. [NetFoundry 3rd Party CA Guide](https://support.netfoundry.io/hc/en-us/articles/360048210572-How-to-Register-Endpoints-with-Certificates-from-Another-Authority).

---

PREREQ: You must obtain a BEARER TOKEN from the NetFoundry Console for the organization you wish to work with.  This BEARER TOKEN must be shell exported in the environment variable "NF_BearerToken" prior to running the utility.

Basic functions of this utility are:
1. Workflow to create a self signed ROOT and INTERMEDIATE certificate authority.
2. Workflow to utilize the INTERMEDIATE certificate authority and validate it for signing identities with the NetFoundry network target(s).
3. Workflow to utilize the primary ZITI CLI [DOWNLOADABLE HERE](https://github.com/openziti/ziti/releases) to enroll identities utilizing the INTERMEDIATE certificate authority's signer to create identities in the target network(s).
4. Learning mode teaches you how/what calls are made to NetFoundry API to perform the actions.

[PS-shield]: https://img.shields.io/badge/Code%20Basis-Linux%20BASH-blue.svg