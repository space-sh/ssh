clone os file

#================================
# SSH_DEP_INSTALL
#
# Make sure that OpenSSH is installed.
#
#================================
SSH_DEP_INSTALL ()
{
    SPACE_CMDDEP="OS_IS_INSTALLED PRINT"

    PRINT "Checking for OS dependencies." "info"

    OS_IS_INSTALLED "ssh" "openssh-client"

    if [ "$?" -eq 0 ]; then
        PRINT "Dependencies found." "success"
    else
        PRINT "Failed finding dependencies." "error"
        return 1
    fi
}

#================================
# SSH
#
# SSH into a remote machine, possibly via a jump host.
#
# env:
#   SSHJUMPHOST: optional - set to use ProxyCommand to connect to the indented host.
#   SSHJUMPPORT: optional
#   SSHJUMPUSER: optional
#   SSHJUMPKEYFILE: optional
#
# positional args:
#   flags
#   user
#   host
#   port - optional
#   keyfile - optional
#   command - optional
#
#================================
SSH ()
{
    SPACE_SIGNATURE="flags user host [port keyfile shell command]"
    SPACE_CMDDEP="PRINT"
    SPACE_CMDENV="SSHJUMPKEYFILE=${SSHJUMPKEYFILE-} SSHJUMPUSER=${SSHJUMPUSER-} SSHJUMPHOST=${SSHJUMPHOST-}"

    local sshflags="${1}"
    shift

    local sshuser="${1}"
    shift

    local sshhost="${1}"
    shift

    local sshport="${1:-22}"
    shift $(( $# > 0 ? 1 : 0 ))

    local sshkeyfile="${1-}"
    shift $(( $# > 0 ? 1 : 0 ))

    local shell="${1-}"
    shift $(( $# > 0 ? 1 : 0 ))

    local command="${1-}"
    shift $(( $# > 0 ? 1 : 0 ))

    local is_terminal=
    if [ -t 0 ] && [ -t 1 ]; then
        is_terminal=1
    fi

    if [ "${is_terminal}" = "1" ]; then
        PRINT "Terminal detected," "debug"
    else
        PRINT "Non terminal detected," "debug"
    fi

    local sshproxycommand=""
    if [ "${SSHJUMPHOST-}" != "" ]; then
        sshproxycommand="ProxyCommand=ssh ${is_terminal:+-t} -q ${SSHJUMPKEYFILE:+-i $SSHJUMPKEYFILE} -W %h:%p ${SSHJUMPUSER-$sshuser}@$SSHJUMPHOST -p ${SSHJUMPPORT-22}"
    fi

    if [ "${SSHJUMPHOST}" = "" ]; then
        PRINT "Host: ${sshhost}." "info"
    else
        PRINT "Host: ${sshhost}, jump host: ${SSHJUMPHOST}." "info"
    fi
    # shellcheck disable=2086
    # shellcheck disable=2029
    if [ "${shell}" = "" ]; then
        PRINT "Run in standard shell." "debug"
        ssh ${sshproxycommand:+-o "${sshproxycommand}"} ${is_terminal:+-t} ${sshflags} ${sshkeyfile:+-i ${sshkeyfile}} ${sshuser:+${sshuser}@}$sshhost -p ${sshport} ${command:+"${command}"}
    else
        PRINT "Run in defined shell: ${shell}." "debug"
        if [ "${command}" != "" ]; then
            local cm="
_spaceinvader=\$(cat <<\"_SPACEGAL_SSH_\"
$command
_SPACEGAL_SSH_
)
bash -c \"\${_spaceinvader}\"
"
            ssh ${sshproxycommand:+-o "${sshproxycommand}"} ${is_terminal:+-t} ${sshflags} ${sshkeyfile:+-i ${sshkeyfile}} ${sshuser:+${sshuser}@}$sshhost -p ${sshport} "${cm}"
        else
            ssh ${sshproxycommand:+-o "${sshproxycommand}"} ${is_terminal:+-t} ${sshflags} ${sshkeyfile:+-i ${sshkeyfile}} ${sshuser:+${sshuser}@}$sshhost -p ${sshport} "${shell}"
        fi
    fi
}

#================================
# SSH_WRAP
#
# Wrapper over SSH that uses environment
# variables instead of positional arguments.
#
# env:
#   SSHFLAGS: optional
#   SSHUSER: optional
#   SSHHOST:
#   SSHPORT: optional - defaults to 22.
#   SSHKEYFILE: optional.
#   SSHSHELL: optional
#
#================================
SSH_WRAP ()
{
    # shellcheck disable=2034
    SPACE_CMD="SSH"
    # shellcheck disable=2153

    if [ "${_FORCE_BASH}" = "1" ] && [ "${SSHSHELL-}" = "" ]; then
        SSHSHELL="bash -c"
    fi

    if [ "${SSHHOST-}" = "" ]; then
        # This variable is mandatory.
        _error "SSHHOST variable must be set."
        return 1
    fi

    # We evalutate SPACE_CMDARGS inside this body because
    # SSHSHELL must have been set first.
    # shellcheck disable=2034
    SPACE_CMDARGS="\"${SSHFLAGS-}\" \"${SSHUSER-}\" \"${SSHHOST}\" \"${SSHPORT-}\" \"${SSHKEYFILE-}\" \"${SSHSHELL-}\" \"\${CMD}\""
}

#================================
# SSH_KEYGEN
#
# Generate a SSH key pair.
#
# positional args:
#   sshkeyfile: Path of the private key to create.
#               The pub key will have the prefix ".pub".
#   sshpubkeyfile: optional - file path where to copy the pub key to efter generation.
#
#================================
SSH_KEYGEN ()
{
    SPACE_SIGNATURE="sshkeyfile [sshpubkeyfile]"
    SPACE_CMDDEP="PRINT FILE_MKDIRP FILE_CP"

    local sshkeyfile="${1}"
    shift

    local sshpubkeyfile="${1-}"
    shift $(( $# > 0 ? 1 : 0 ))

    PRINT "Generate new key pair." "info"

    # Don't copy the pub key file to it self.
    if [ "${sshpubkeyfile}" = "${sshkeyfile}.pub" ]; then
        sshpubkeyfile=
    fi

    if [ -f "${sshkeyfile}" ]; then
        PRINT "Keyfile: ${sshkeyfile} already exists, not generating new." "warning"
        return 0
    fi
    FILE_MKDIRP "$(dirname "${sshkeyfile}")" && ssh-keygen -f "${sshkeyfile}"
    if [ "$?" != "0" ]; then
        return 1
    fi
    if [ "${sshpubkeyfile-}" != "" ]; then
        FILE_MKDIRP "$(dirname ${sshpubkeyfile})" && FILE_CP "${sshkeyfile}.pub" "${sshpubkeyfile}"
    fi
}

#================================
# SSH_FS
#
# Setup sshfs onto a remote machine, possibly via a jump host.
#
# env:
#   SSHJUMPHOST: optional - set to use ProxyCommand to connect to the indented host.
#   SSHJUMPPORT: optional
#   SSHJUMPUSER: optional
#   SSHJUMPKEYFILE: optional
#   SUDO: optional - set to "sudo" to use sudo.
#
# positional args:
#   flags
#   user
#   host
#   port
#   keyfile
#   remotepath
#   localpath
#
#================================
SSH_FS ()
{
    SPACE_SIGNATURE="flags user host port keyfile remotepath localpath"
    SPACE_CMDDEP="PRINT FILE_MKDIRP FILE_CHOWN FILE_CHMOD"
    SPACE_CMDENV="SUDO SSHJUMPKEYFILE=${SSHJUMPKEYFILE-} SSHJUMPUSER=${SSHJUMPUSER-} SSHJUMPHOST=${SSHJUMPHOST-}"

    local sshflags="${1}"
    shift

    local sshuser="${1}"
    shift

    local sshhost="${1}"
    shift

    local sshport="${1}"
    shift

    local sshkeyfile="${1}"
    shift

    local remotepath="${1}"
    shift

    local localpath="${1}"
    shift

    local uid=
    uid="$(id -u)"
    local gid=
    gid="$(id -g)"

    # NOTE: proxycommand untested for sshfs.
    local sshproxycommand=""
    if [ "${SSHJUMPHOST-}" != "" ]; then
        # shellcheck disable=2089
        sshproxycommand="-o ProxyCommand=\"ssh -q ${JUMPKEYFILE:+-i $JUMPKEYFILE} -W %h:%p $JUMPUSER@$JUMPHOST -p ${JUMPPORT-22}\""
    fi

    local SUDO="${SUDO-}"
    [ ! -d "${localpath}" ] &&
    FILE_MKDIRP "${localpath}" &&
    FILE_CHOWN "${uid}:${gid}" "${localpath}" &&
    FILE_CHMOD "770" "${localpath}"

    PRINT "Mounting to $localpath" "info"

    # shellcheck disable=2090
    # shellcheck disable=2086
    sshfs $sshproxycommand -p $sshport ${sshkeyfile:+-o IdentityFile="${sshkeyfile}"} ${sshuser:+${sshuser}@}${sshhost}:${remotepath} "${localpath}" -o reconnect -o gid="${gid}" -o uid="${uid}"
}

#================================
# SSH_FS_UMOUNT
#
# Umount a sshfs mount point.
#
# env:
#   SUDO: optional - set to "sudo" to use sudo.
#
# positional args:
#   locapath
#
#================================
SSH_FS_UMOUNT()
{
    # shellcheck disable=2034
    SPACE_SIGNATURE="localpath"
    # shellcheck disable=2034
    SPACE_CMDDEP="PRINT"
    # shellcheck disable=2034
    SPACE_CMDENV="SUDO"

    local localpath="${1}"
    shift

    PRINT "Unmounting $localpath" "info"

    local SUDO="${SUDO-}"
    $SUDO umount "${localpath}"
}

#=======================
# SSH_SSHD_CONFIG
#
# Configure the SSHD of the OS so that authorized_keys file is used.
#
# env:
#   $SUDO: if not run as root set SUDO=sudo
#
#=======================
SSH_SSHD_CONFIG ()
{
    SPACE_CMDDEP="PRINT FILE_ROW_PERSIST"
    SPACE_CMDENV="SUDO=\${SUDO-}"

    local file="/etc/ssh/sshd_config"
    local row="AuthorizedKeysFile %h\/.ssh\/authorized_keys"

    PRINT "modify ${file}." "debug"

    local SUDO="${SUDO-}"
    FILE_ROW_PERSIST "${row}" "${file}"
    local status="$?"
    if [ "${status}" -eq 2 ]; then
        PRINT "File does not exist." "debug"
        return 2
    fi

    row="GatewayPorts yes"
    FILE_ROW_PERSIST "${row}" "${file}"
}

#===================
# SSH_ADD_SSH_KEY
#
# Add a SSH public key to a users authorized_keys file.
#
# positional args:
#   targetuser: The name if the existing user to add ssh key file for.
#   sshpubkeyfile: Path to the pub key file to upload for the target user.
#
#===================
SSH_ADD_SSH_KEY ()
{
    SPACE_SIGNATURE="targetuser sshpubkeyfile"
    SPACE_CMDREDIR="<${2}"
    SPACE_CMDDEP="FILE_PIPE_APPEND PRINT"

    local targetuser="${1}"
    shift

    local sshpubkeyfile="${1}"
    shift

    PRINT "Add SSH pub key ${sshpubkeyfile} for user ${targetuser}." "debug"

    FILE_PIPE_APPEND "${_OSHOME}/${targetuser}/.ssh/authorized_keys"
}

#=====================
# SSH_RESET_SSH_KEY
#
# Clear all authorized keys and re-add the current users pub key as the only one.
# This is useful to revoke all other admins access to the machine.
#
# positional args:
#   targetuser: The name if the existing user to add ssh key file for.
#   sshpubkeyfile: Path to the pub key file to upload for the target user.
#
#=====================
SSH_RESET_SSH_KEY ()
{
    # shellcheck disable=2034
    SPACE_SIGNATURE="targetuser sshpubkeyfile"
    # shellcheck disable=2034
    SPACE_CMDREDIR="<${2}"
    # shellcheck disable=2034
    SPACE_CMDDEP="FILE_PIPE_WRITE PRINT"

    local targetuser="${1}"
    shift

    local sshpubkeyfile="${1}"
    shift

    PRINT "Reset SSH pub key ${sshpubkeyfile} for user ${targetuser}." "debug"

    FILE_PIPE_WRITE "${_OSHOME}/${targetuser}/.ssh/authorized_keys"
}
