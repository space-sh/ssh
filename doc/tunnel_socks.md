---
modulename: SSH
title: /tunnel/socks/
giturl: gitlab.com/space-sh/ssh
editurl: /edit/master/doc/tunnel_socks.md
weight: 200
---
# SSH module: Open SOCKS tunnel

To surf through a VPN tunnel we can use the SSH socks functionality.

The SSH client will open a secure connection to a remote server, your browser
must be setup to use the local address as a socks5 proxy, then all requests
within the browser will be tunnelled through the secure connection and all
outbound connections to the internet will look like the originated from the
remote server.

bindhost:bindport are relative to the local machine.


## Example

```sh
space -m ssh /tunnel/socks/ -e SSHTUNNEL=0.0.0.0:9333 -e SSHHOST=address
```

Remember to configure your browser to use a socks5 proxy connected to 127.0.0.1:9333.

This wi

Exit status code is expected to be 0 on success.
