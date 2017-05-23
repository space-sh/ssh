---
modulename: SSH
title: /wrap/
giturl: gitlab.com/space-sh/ssh
editurl: /edit/master/doc/wrap.md
weight: 200
---
# SSH module: Wrap

Wrap a command in a _SSH_ call.


## Example

```sh
space -m os /info/ -m ssh /wrap/ -esshuser="janitor" -esshkeyfile="/tmp/janitor.key" -esshhost="192.168.0.10"
```

Exit status code is expected to be 0 on success.
