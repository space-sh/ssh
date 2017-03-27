---
modulename: SSH
title: /keygen/
giturl: gitlab.com/space-sh/ssh
weight: 200
---
# SSH module: Keygen

Generate _SSH_ key pair.


## Example

Generate _SSH_ private and public key pair, respectively:
```sh
space -m ssh /keygen/ -- "/tmp/janitor.key" "/tmp/janitor.pub"
```

Exit status code is expected to be 0 on success.
