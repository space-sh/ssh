---
modulename: SSH
title: /tunnel/reverse/
giturl: gitlab.com/space-sh/ssh
weight: 200
---
# SSH module: Open reverse tunnel from server

We can open a reverse tunnel from a remote server back to the local computer.

A reverse tunnel could be useful when we are behing a strict firewall and cannot
listen for incoming connections directly because the firewall will not let them through.
So we leverage a third party server to tunnel such a connection back to us over the secure
SSH connection.

A reverse tunnel makes the SSH daemon on the remote server
open a listening socket on the provided bindaddress:bindport,
and each accepted connection will be tunneled back to the local
computer by SSH opening a client socket to localhost:localport
so that data can be tunneled bwtween those end points.

Set `-e SSHTUNNEL=bindaddress:bindport:localhost:localport`  

bindaddress:bindport are relative to the remote machine.  
localhost:localport are relative to the local machine.


## Example

```sh
$ space -m ssh /tunnel/reverse/ -e SSHTUNNEL=0.0.0.0:9333:127.0.0.1:9333 -e SSHHOST=address
```

Exit status code is expected to be 0 on success.
