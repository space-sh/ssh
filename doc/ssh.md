---
modulename: SSH
title: /ssh/
giturl: gitlab.com/space-sh/ssh
weight: 200
---
# SSH module: SSH

_SSH_ into remote machine.


## Example

Enter a remote host:
```sh
space -m ssh /ssh/ -- "192.168.0.10"
```

Enter a remote host port `2221`, specifying user and custom public key:
```sh
space -m ssh /ssh/ -- "192.168.0.10" "janitor" "/tmp/janitor.pub" "2221"
```


Exit status code is expected to be 0 on success.
