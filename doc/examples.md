---
modulename: SSH
title: Examples
giturl: gitlab.com/space-sh/ssh
weight: 200
---
# SSH Module

## Simple usage

Using positional arguments:  

```sh
$ space -m ssh /ssh/ -- address

```

Or, instead use environment variables, which is often recommended,
because then you do not have to consider what position an argument
must come in:  

```sh
$ space -m ssh /ssh/ -e SSHHOST=address

```

The above will issue a login shell onto the remote host.  

### Run command remotely

```sh
$ space -m ssh /ssh/ -e SSHHOST=address -e SSHCOMMAND="ls -l"

```

### Using jump hosts to bypass firewalls

Often a machine is on a restricted network protected by a firewall to protect the machines from the chaos of the internet.
However, there is usually one or more machines which serves as `jump hosts` or `bastion hosts`.

We could use the SSH module to jump over any number of hosts to reach our destination host.  

Usually keys are used as login credentials and all keys are to exist on the client issuing the request.

To use jump hosts, simply add all hosts from left to right, comma separated. The last host is the destination host:  

```sh
$ space -m ssh /ssh/ -e SSHHOST=jump1.example.com,jump2.example.com,jump3.example.com,destination.example.com -e SSHCOMMAND="ls -l"

```

If you need to specify the keys manually add those too:  

```sh
$ space -m ssh /ssh/ -e SSHHOST=jump1.example.com,jump2.example.com,jump3.example.com,destination.example.com \
    -e SSHKEYFILE=key1_id,key2_id,key3_id,key4_id -e SSHCOMMAND="ls -l"
```

### Wrapping other modules in SSH

One of the most powerful features of Space is that it can `wrap` commands
inside other commands to have them run somewhere else.  

For example the OS module could be wrapped in the SSH module to be run on a remote machine.

```sh
$ space -m os /info/
```

Above will output some basic info about the system.  

If we want to run this on a remote machine over ssh, simply do this:  

```sh
$ space -m os /info -m ssh /wrap/ -e SSHHOST=address

```

Of course, you can still use jump hosts when wrapping commands.
We'll take the example above, now you will see why we usually want
to use `-e` variables instead of positional arguments, because we can use modules together:  

```sh
$ space -m os /info/ \
    -m ssh /wrap/ -e SSHHOST=jump1.example.com,jump2.example.com,jump3.example.com,destination.example.com \
    -e SSHKEYFILE=key1_id,key2_id,key3_id,key4_id
```

Any command in any module can get wrapped and run remotely.  
No files nor scripts are uploaded to the host, they are run directly by SSH.

However, if you want to upload a file to a remote system over SSH, it's quite easy
using the `file` module.

### Upload a file

```sh
$ echo "Hello World!" | space -m file /pipwrite/ -e file=/tmp/hello \
    -m ssh /wrap/ -e SSHHOST=jump1.example.com,jump2.example.com,jump3.example.com,destination.example.com \
    -e SSHKEYFILE=key1_id,key2_id,key3_id,key4_id
```

Let's fetch the contents back using `cat`:  

```sh
$ space -m file /cat/ -e file=/tmp/hello \
    -m ssh /wrap/ -e SSHHOST=jump1.example.com,jump2.example.com,jump3.example.com,destination.example.com \
    -e SSHKEYFILE=key1_id,key2_id,key3_id,key4_id
```

### Wait for file(s) to be created

We can use the `utils` module for waiting on files we expect to be created:  

```sh
$ space -m utils /waitforfile/ -e waitfilelist=/tmp/hello \
    -m ssh /wrap/ -e SSHHOST=jump1.example.com,jump2.example.com,jump3.example.com,destination.example.com \
    -e SSHKEYFILE=key1_id,key2_id,key3_id,key4_id
```
