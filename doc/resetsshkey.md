---
modulename: SSH
title: /resetsshkey/
giturl: gitlab.com/space-sh/ssh
weight: 200
---
# SSH module: Reset SSH key

Reset remote users `authorized_keys` file to only hold one public key file. This is useful for setting permissions only to the current user in charge of performing this command.


## Example

```sh
space -m ssh /resetsshkey/ -- "janitor" "/tmp/janitor.pub"
```

Exit status code is expected to be 0 on success.
