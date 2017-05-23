---
modulename: SSH
title: /addsshkey/
giturl: gitlab.com/space-sh/ssh
editurl: /edit/master/doc/addsshkey.md
weight: 200
---
# SSH module: Add SSH key

Add a _SSH_ public key to remote users `authorized_keys` file.


## Example

```sh
space -m ssh /addsshkey/ -- "janitor" "/tmp/janitor.pub"
```

Exit status code is expected to be 0 on success.
