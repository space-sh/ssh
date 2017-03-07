# SSH module | [![build status](https://gitlab.com/space-sh/ssh/badges/master/build.svg)](https://gitlab.com/space-sh/ssh/commits/master)

Provides common admin and user ssh client operations.



## /addsshkey/
	Add public key

	Add a ssh public key to a remote users authorized_keys file.
	


## /configsshd/
	Configure SSHD

	Make sure that SSHD is properly configured.
	


## /keygen/
	Generate SSH key pair


## /resetsshkey/
	Reset ssh key

	Reset the remote users authorized_keys file to only hold one pub key.
	The pub key uploaded should be the current one being used by you.
	


## /ssh/
	SSH into remote machine


## /wrap/
	Wrap other command in SSH call.


# Functions 

## SSH\_DEP\_INSTALL()  
  
  
  
Make sure that OpenSSH is installed.  
  
### Returns:  
- 0: dependencies found  
- 1: failed to find dependencies  
  
  
  
## SSH()  
  
  
  
Connect to remote server over SSH.  
Optionally use one or more "jump servers"  
  
### Parameters:  
- $1: host address, or many space separated addresses if using jump hosts.  
- Last address is the final destination host.  
- $2: Optional matching list of user names.  
- $3: Optional matching list of key files.  
- $4: Optional matching list of ports. e.g. "223 22 222"  
- $5: Optional matching list of flags. e.g. "q q q"  
- $6: Optional shell to use on remote side, leave empty for default  
- login shell. e.g. "sh" or "bash".  
- $7: Optional command to execute on server, leave blank for interactive shell.  
  
- The parameter lists do not have to be as big as the "hosts" list, if they  
- are not then no or a default value is used.  
- To put on item in the middle of a list as empty use ''.  
  
### Returns:  
- non-zero on error  
  
  
  
## SSH\_WRAP()  
  
  
  
Wrapper over SSH that uses environment  
variables instead of positional arguments.  
  
If connecting to multiple hosts the variables must be balanced,  
see the SSH function for more information.  
  
### Expects:  
- SSHHOST:  
- SSHUSER: optional  
- SSHKEYFILE: optional  
- SSHPORT: optional - defaults to 22.  
- SSHFLAGS: optional  
- SSHSHELL: optional  
  
### Returns:  
- non-zero on error.  
  
  
  
## SSH\_KEYGEN()  
  
  
  
Generate a SSH key pair.  
  
### Parameters:  
- $1: Path of the private key to create. The pub key will have the prefix ".pub".  
- $2: file path where to copy the pub key to after generation (optional).  
  
### Returns:  
- 0: success  
- 1: failure  
  
  
  
## SSH\_FS()  
  
  
  
Setup sshfs onto a remote machine, possibly via a jump host.  
  
### Parameters:  
- $1: flags  
- $2: user  
- $3: host  
- $4: port  
- $5: keyfile  
- $6: remotepath  
- $7: localpath  
  
### Expects:  
- SSHJUMPHOST: optional - set to use ProxyCommand to connect to the indented host.  
- SSHJUMPPORT: optional  
- SSHJUMPUSER: optional  
- SSHJUMPKEYFILE: optional  
- SUDO: optional - set to "sudo" to use sudo.  
  
  
  
## SSH\_FS\_UMOUNT()  
  
  
  
Umount a sshfs mount point.  
  
### Parameters:  
- $1: local path  
  
### Expects:  
- SUDO: set to "sudo" to use sudo (optional)  
  
  
  
## SSH\_SSHD\_CONFIG()  
  
  
  
Configure the SSHD of the OS so that authorized\_keys file is used.  
  
### Expects:  
- $SUDO: if not run as root set SUDOsudo  
  
### Returns:  
- 0: success  
- 2: file does not exist  
  
  
  
## SSH\_ADD\_SSH\_KEY()  
  
  
  
Add a SSH public key to a users authorized\_keys file.  
  
### Parameters:  
- $1: The name of the existing user to add ssh key file for  
- $2: Path to the pub key file to upload for the target user  
  
  
  
## SSH\_RESET\_SSH\_KEY()  
  
  
  
Clear all authorized keys and re-add the current users pub key as the only one.  
This is useful to revoke all other admins access to the machine.  
  
### Parameters:  
- $1: The name if the existing user to add ssh key file for.  
- $2: Path to the pub key file to upload for the target user.  
  
  
  
