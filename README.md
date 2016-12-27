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


## /root/
	SSH as root using password

+ wrap

## /user/
	SSH as user with a keyfile

+ wrap

# Functions 

## SSH\_DEP\_INSTALL ()  
  
  
  
Make sure that OpenSSH is installed.  
  
### Returns:  
- 0: dependencies found  
- 1: failed to find dependencies  
  
  
  
## SSH ()  
  
  
  
SSH into a remote machine, possibly via a jump host.  
  
### Parameters:  
- $1: flags  
- $2: user name  
- $3: host  
- $4: port (optional)  
- $5: keyfile (optional)  
- $6: command (optional)  
  
### Expects:  
- SSHJUMPHOST: optional - set to use ProxyCommand to connect to the indented host.  
- SSHJUMPPORT: optional  
- SSHJUMPUSER: optional  
- SSHJUMPKEYFILE: optional  
  
  
  
## SSH\_WRAP ()  
  
  
  
Wrapper over SSH that uses environment  
variables instead of positional arguments.  
  
### Expects:  
- SSHHOST:  
- SSHFLAGS: optional  
- SSHUSER: optional  
- SSHPORT: optional - defaults to 22.  
- SSHKEYFILE: optional  
- SSHSHELL: optional  
  
### Returns:  
- 0: success  
- 1: missing SSHHOST failure  
  
  
  
## SSH\_KEYGEN ()  
  
  
  
Generate a SSH key pair.  
  
### Parameters:  
- $1: Path of the private key to create. The pub key will have the prefix ".pub".  
- $2: file path where to copy the pub key to after generation (optional).  
  
### Returns:  
- 0: success  
- 1: failure  
  
  
  
## SSH\_FS ()  
  
  
  
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
  
  
  
## SSH\_SSHD\_CONFIG ()  
  
  
  
Configure the SSHD of the OS so that authorized\_keys file is used.  
  
### Expects:  
- $SUDO: if not run as root set SUDOsudo  
  
### Returns:  
- 0: success  
- 2: file does not exist  
  
  
  
## SSH\_ADD\_SSH\_KEY ()  
  
  
  
Add a SSH public key to a users authorized\_keys file.  
  
### Parameters:  
- $1: The name of the existing user to add ssh key file for  
- $2: Path to the pub key file to upload for the target user  
  
  
  
## SSH\_RESET\_SSH\_KEY ()  
  
  
  
Clear all authorized keys and re-add the current users pub key as the only one.  
This is useful to revoke all other admins access to the machine.  
  
### Parameters:  
- $1: The name if the existing user to add ssh key file for.  
- $2: Path to the pub key file to upload for the target user.  
  
  
  
