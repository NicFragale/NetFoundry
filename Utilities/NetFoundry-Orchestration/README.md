<p><center>
<h1><b>NetFoundry OpenZITI Utility: Orchestration Quick API</b></h1>

![OpenZITI_QuickAPI][PS-shield]

</center></p>
<br>

This utility acts as a quick and easy way to interact with the NetFoundry Orchestration Platform (MOP) with a limited set of capabilities.  The WEB UI (Console) that acts as a mechanism for general MOP interactions using HTTP provides a rich experience for an admin of a ZITI network.  Though, a CLI construct can sometimes lend to a faster method of interactation with such a system.

The full APIv2 spec for management can be found at the [API Guide](https://gateway.production.netfoundry.io/core/v2/docs/index.html).

---

Basic functions of this utility are:
1. Upon initialization of the utility runtime, use an API CLIENT and API SECRET generated from the NetFoundry MOP and available in the environment of the running shell.
2. Convert the API CLIENT AND API SECRET into a time-limited BEARER TOKEN.
3. Utilize the time-limited BEARER TOKEN to interact with the MOP, explictly with the network(s) tied to it.
4. Upon conclusion of the utility runtime, destroy the time-limited BEARER TOKEN.

---

What can this utility do?
1. Work on ENDPOINT/IDENTITY and SERVICE objects.
2. LIST or MODIFY the objects' attribute tags.
3. Rich capabilities to search for REGEX matching object names and/or attributes.

In the future, as time permits development, the utility will also have functionality for:
1. Work on APPNET/POLICIES.
2. Add/remove objects starting with simple and eventually moving to advanced inputs.
3. Rename objects.
4. ...and more.

```
ABC
```

For more information about OpenZITI, check out the Github page at [The OpenZITI Repo](https://github.com/openziti).

[PS-shield]: https://img.shields.io/badge/Code%20Basis-Linux%20BASH-blue.svg