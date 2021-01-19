---
modulename: SSH
title: Examples
giturl: gitlab.com/space-sh/ssh
editurl: /edit/master/doc/examples.md
weight: 200
---
# SSH Module

## Simple usage

Using positional arguments:  

```sh
space -m ssh /ssh/ -- address

```

Or, instead use environment variables, which is often recommended,
because then you do not have to consider what position an argument
must come in:  

```sh
space -m ssh /ssh/ -e SSHHOST=address

```

The above will issue a login shell onto the remote host.  

### Run command remotely

```sh
space -m ssh /ssh/ -e SSHHOST=address -e SSHCOMMAND="ls -l"

```

### Using jump hosts to bypass firewalls

Often a machine is on a restricted network protected by a firewall to protect the machines from the chaos of the internet.
However, there is usually one or more machines which serves as `jump hosts` or `bastion hosts`.

We could use the SSH module to jump over any number of hosts to reach our destination host.  

Usually keys are used as login credentials and all keys are to exist on the client issuing the request.

To use jump hosts, simply add all hosts from left to right, comma separated. The last host is the destination host:  

```sh
space -m ssh /ssh/ -e SSHHOST=jump1.example.com,jump2.example.com,jump3.example.com,destination.example.com -e SSHCOMMAND="ls -l"

```

If you need to specify the keys manually add those too:  

```sh
space -m ssh /ssh/ -e SSHHOST=jump1.example.com,jump2.example.com,jump3.example.com,destination.example.com \
    -e SSHKEYFILE=key1_id,key2_id,key3_id,key4_id -e SSHCOMMAND="ls -l"
```

### Wrapping other modules in SSH

One of the most powerful features of Space is that it can `wrap` commands
inside other commands to have them run somewhere else.  

For example the OS module could be wrapped in the SSH module to be run on a remote machine.

```sh
space -m os /info/
```

Above will output some basic info about the system.  

If we want to run this on a remote machine over ssh, simply do this:  

```sh
space -m os /info -m ssh /wrap/ -e SSHHOST=address

```

Of course, you can still use jump hosts when wrapping commands.
We'll take the example above, now you will see why we usually want
to use `-e` variables instead of positional arguments, because we can use modules together:  

```sh
space -m os /info/ \
    -m ssh /wrap/ -e SSHHOST=jump1.example.com,jump2.example.com,jump3.example.com,destination.example.com \
    -e SSHKEYFILE=key1_id,key2_id,key3_id,key4_id
```

Any command in any module can get wrapped and run remotely.  
No files nor scripts are uploaded to the host, they are run directly by SSH.

However, if you want to upload a file to a remote system over SSH, it's quite easy
using the `file` module.

### Upload a file

```sh
echo "Hello World!" | space -m file /pipwrite/ -e file=/tmp/hello \
    -m ssh /wrap/ -e SSHHOST=jump1.example.com,jump2.example.com,jump3.example.com,destination.example.com \
    -e SSHKEYFILE=key1_id,key2_id,key3_id,key4_id
```

Let's fetch the contents back using `cat`:  

```sh
space -m file /cat/ -e file=/tmp/hello \
    -m ssh /wrap/ -e SSHHOST=jump1.example.com,jump2.example.com,jump3.example.com,destination.example.com \
    -e SSHKEYFILE=key1_id,key2_id,key3_id,key4_id
```

### Wait for file(s) to be created

We can use the `utils` module for waiting on files we expect to be created:  

```sh
space -m utils /waitforfile/ -e waitfilelist=/tmp/hello \
    -m ssh /wrap/ -e SSHHOST=jump1.example.com,jump2.example.com,jump3.example.com,destination.example.com \
    -e SSHKEYFILE=key1_id,key2_id,key3_id,key4_id
```

### Using a hostfile instead of arguments
Instead of providing SSH arguments on command line or as variables one can use a `.env` file from where variables are read.

If using a host file, this is an `.env` file where the `SSH_*` variables are read from the file instead from the cmd line.

If values are also provided on command line then those values are appended to those in the .env file so that the host.env file can be used for declaring the jump host you are using for the host you are providing on cmd line.

In the `.env` file there can also be jump hosts defined, if so that will trigger a read of another `host.env` file which will be used as a jump host for the host described in the first `host.env` file.

A special case is when using a `host.env` file and declaring port, user, keyfile, flags on command line but no host parameter, then those values are used *instead* of the values read from the (first) `host.env` file.

Example host.env file:
```sh
HOST=1.2.3.4
USER=clownsalad
KEYFILE=.ssh/id_rsa
PORT=4562
FLAGS=-opasswordauthentication=no -ostricthostkeychecking=no -oexitonforwardfailure=no
JUMPHOST=../host2
```

`HOST` is required.  
`PORT` defaults to 22.  
`Multiple` flags can be used and are optional  
`JUMPHOST` is the path to another diretory where a host.env file exists, which will be used as a jumphost.  
`JUMPHOST` can also point to another .env file in the same directory.  
For `KEYFILE` and `JUMPHOST` relative paths will be set below user `$HOME`.  
