---
modulename: SSH
title: /sshfs/
giturl: gitlab.com/space-sh/ssh
weight: 200
---
# SSH module: Mount over SSH 

Mount over _SSH_.

This node takes the same arguments as the /ssh/ node, except the addition of
`SSHREMOTEPATH` and `SSHLOCALPATH`.


## Example

Mount:
```sh
$ space -m ssh /mount/ -e SSHHOST=example.org -e SSHREMOTEPATH=/var/log -e SSHLOCALPATH=/mnt/ext1

# Then to umount:
$ space -m ssh /umount/ -e SSHLOCALPATH=/mnt/ext1
```

Exit status code is expected to be 0 on success.
