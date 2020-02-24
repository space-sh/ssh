---
modulename: SSH
title: /tunnel/wrap_reverse/
giturl: gitlab.com/space-sh/ssh
editurl: /edit/master/doc/tunnel_wrap_reverse.md
weight: 200
---
# SSH module: Open reverse tunnel as a wrapper

We can open a reverse tunnel from a remote server back to the local computer as a wrapper.

Wrapping a reverse tunnel could be when the _SSH_ user does not have administrative privileges.


## Example

Run `socat` in the server using `sudo`, listening to port `80` and then tunnelling:
```sh
space -m os /shell/ -e command="socat tcp-listen:80,fork,reuseaddr tcp-connect:127.0.0.1:7474" -s sudo \
      -m ssh /tunnel/wrap_reverse/ -e SSHTUNNEL=0.0.0.0:9333:127.0.0.1:9333 -e SSHHOST=address
```

Exit status code is expected to be 0 on success.
