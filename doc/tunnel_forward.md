---
modulename: SSH
title: /tunnel/forward/
giturl: gitlab.com/space-sh/ssh
weight: 200
---
# SSH module: Open forward tunnel from server

We can open a forward tunnel from the local computer to the remote server.  

A tunnel could be useful when you are behind a strict firewall and cannot access parts
of the internet, then we can leverage a third party server to make that connection for us.  

A forward tunnel will have SSH open a listening socket locally on the
client computer. On accepting new connection the SSH client will ask
the SSH daemon on the remote server to open a client connection to
remotehost:remoteport, and all data will be tunnelled between the end points.

Set `-e SSHTUNNEL=localhost:localport:remotehost:remoteport`  

localhost:localport are relative to the local machine.
remotehost:remoteport are relative to the remote machine.

## Example

```sh
$ space -m ssh /tunnel/forward/ -e SSHTUNNEL=0.0.0.0:9333:example.com:9333 -e SSHHOST=address
```

Exit status code is expected to be 0 on success.
