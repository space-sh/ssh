#
# Copyright 2016 Blockie AB
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Disable warning about indirectly checking status code
# shellcheck disable=SC2181

#================================
# SSH_DEP_INSTALL
#
# Make sure that OpenSSH is installed.
#
# Returns:
#   0: dependencies found
#   1: failed to find dependencies
#
#================================
SSH_DEP_INSTALL()
{
    SPACE_DEP="OS_IS_INSTALLED PRINT"

    PRINT "Checking for OS dependencies." "info"

    OS_IS_INSTALLED "ssh" "openssh-client"

    if [ "$?" -eq 0 ]; then
        PRINT "Dependencies found." "ok"
    else
        PRINT "Failed finding dependencies." "error"
        return 1
    fi
}

#==================
# SSH
#
# Connect to remote server over SSH.
# Optionally use one or more "jump servers"
#
# Parameters:
#   $1: host address, or many space separated addresses if using jump hosts.
#       Last address is the final destination host.
#   $2: Optional matching list of user names.
#   $3: Optional matching list of key files.
#   $4: Optional matching list of ports. e.g. "223 22 222"
#   $5: Optional matching list of flags. e.g. "q q q"
#   $6: Optional shell to use on remote side, leave empty for default
#       login shell. e.g. "sh" or "bash".
#   $7: Optional command to execute on server, leave blank for interactive shell.
#
# The parameter lists do not have to be as big as the "hosts" list, if they
# are not then no or a default value is used.
# To put on item in the middle of a list as empty use ''.
#
# Returns:
#   non-zero on error
#
#==================
SSH()
{
    SPACE_SIGNATURE="host [user keyfile port flags shell command]"
    SPACE_DEP="PRINT STRING_ESCAPE STRING_ITEM_COUNT STRING_ITEM_GET"

    local hosts="${1}"
    shift

    local users="${1-}"
    shift $(( $# > 0 ? 1 : 0 ))

    local keyfiles="${1-}"
    shift $(( $# > 0 ? 1 : 0 ))

    local ports="${1-}"
    shift $(( $# > 0 ? 1 : 0 ))

    local flagses="${1-}"
    shift $(( $# > 0 ? 1 : 0 ))

    local shell="${1-}"
    shift $(( $# > 0 ? 1 : 0 ))

    local command="${1-}"
    shift $(( $# > 0 ? 1 : 0 ))

    local is_terminal=
    if [ -t 0 ] && [ -t 1 ]; then
        is_terminal=1
    fi

    local count=0
    STRING_ITEM_COUNT "${hosts}" "count"

    local sshcommand=""
    local index=0
    while [ "${index}" -lt "${count}" ]; do
        local host=
        STRING_ITEM_GET "${hosts}" ${index} "host"

        local user=
        STRING_ITEM_GET "${users}" ${index} "user"
        if [ "${user}" = "''" ]; then
            user=
        fi

        local keyfile=
        STRING_ITEM_GET "${keyfiles}" ${index} "keyfile"
        if [ "${keyfile}" = "''" ]; then
            keyfile=
        fi

        local port=22
        STRING_ITEM_GET "${ports}" ${index} "port"
        if [ "${port}" = "''" ]; then
            port=22
        fi

        local flags=
        STRING_ITEM_GET "${flagses}" ${index} "flags"
        if [ "${flags}" = "''" ]; then
            flags=
        fi

        if [ -z "${sshcommand}" ]; then
            sshcommand="${keyfile:+-i ${keyfile} }-p ${port} ${flags:+-${flags} }${user:+${user}@}${host}"
        else
            STRING_ESCAPE "sshcommand" '"'
            sshcommand="-o proxycommand=\"ssh -W ${host}:${port} ${sshcommand}\" ${keyfile:+-i ${keyfile} }-p ${port} ${flags:+-${flags} }${user:+${user}@}${host}"
        fi
        index=$((index+1))
    done

    if [ "${is_terminal}" = "1" ]; then
        sshcommand="ssh -t ${sshcommand}"
    else
        sshcommand="ssh ${sshcommand}"
    fi

    PRINT "${sshcommand}" "debug"

    if [ -z "${shell}" ]; then
        # No shell given, run in login shell.
        PRINT "No shell defined, running in default login shell." "debug"
        STRING_ESCAPE "command" '"$'
        sh -c "${sshcommand}${command:+ -- \"${command}\"}"
    else
        # Run in defined shell.
        if [ -n "${command}" ]; then
            PRINT "Run command in defined shell: ${shell}." "debug"
            STRING_ESCAPE "command" '"$'
            STRING_ESCAPE "command" '"$'
            sh -c "${sshcommand} -- ${shell} \"-c \\\"${command}\\\"\""
        else
            PRINT "Run defined shell: ${shell}." "debug"
            sh -c "${sshcommand} -- ${shell}"
        fi
    fi
}

#================================
# SSH_WRAP
#
# Wrapper over SSH that uses environment
# variables instead of positional arguments.
#
# Expects:
#   SSHHOST:
#   SSHUSER: optional
#   SSHKEYFILE: optional
#   SSHPORT: optional - defaults to 22.
#   SSHFLAGS: optional
#   SSHSHELL: optional
#
# Returns:
#   non-zero on error.
#
#================================
SSH_WRAP()
{
    SPACE_FN="SSH"
    SPACE_ENV="SSHHOST SSHUSER=\"${SSHUSER-}\" SSHKEYFILE=\"${SSHKEYFILE-}\" SSHPORT=\"${SSHPORT-}\" SSHFLAGS=\"${SSHFLAGS-}\" SSHSHELL=\"${SSHSHELL-}\""
    SPACE_ARGS="\"\${SSHHOST}\" \"\${SSHUSER}\" \"\${SSHKEYFILE}\" \"\${SSHPORT}\" \"\${SSHFLAGS}\" \"\${SSHSHELL}\" \"\${RUN}\""
}

# Disable warning about indirectly checking status code
# shellcheck disable=SC2181

#================================
# SSH_KEYGEN
#
# Generate a SSH key pair.
#
# Parameters:
#   $1: Path of the private key to create. The pub key will have the prefix ".pub".
#   $2: file path where to copy the pub key to after generation (optional).
#
# Returns:
#   0: success
#   1: failure
#
#================================
SSH_KEYGEN()
{
    SPACE_SIGNATURE="sshkeyfile [sshpubkeyfile]"
    SPACE_DEP="PRINT FILE_MKDIRP FILE_CP"

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
# Parameters:
#   $1: flags
#   $2: user
#   $3: host
#   $4: port
#   $5: keyfile
#   $6: remotepath
#   $7: localpath
#
# Expects:
#   SSHJUMPHOST: optional - set to use ProxyCommand to connect to the indented host.
#   SSHJUMPPORT: optional
#   SSHJUMPUSER: optional
#   SSHJUMPKEYFILE: optional
#   SUDO: optional - set to "sudo" to use sudo.
#
#================================
SSH_FS()
{
    # TODO this needs to be reupholstered just like SSH function.
    SPACE_SIGNATURE="flags user host port keyfile remotepath localpath"
    SPACE_DEP="PRINT FILE_MKDIRP FILE_CHOWN FILE_CHMOD"
    SPACE_ENV="SUDO=${SUDO-} SSHJUMPKEYFILE=${SSHJUMPKEYFILE-} SSHJUMPUSER=${SSHJUMPUSER-} SSHJUMPHOST=${SSHJUMPHOST-}"

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
# Parameters:
#   $1: local path
#
# Expects:
#   SUDO: set to "sudo" to use sudo (optional)
#
#================================
SSH_FS_UMOUNT()
{
    # shellcheck disable=2034
    SPACE_SIGNATURE="localpath"
    # shellcheck disable=2034
    SPACE_DEP="PRINT"
    # shellcheck disable=2034
    SPACE_ENV="SUDO=${SUDO-}"

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
# Expects:
#   $SUDO: if not run as root set SUDO=sudo
#
# Returns:
#   0: success
#   2: file does not exist
#
#=======================
SSH_SSHD_CONFIG()
{
    SPACE_DEP="PRINT FILE_ROW_PERSIST"   # shellcheck disable=SC2034
    SPACE_ENV="SUDO=${SUDO-}"            # shellcheck disable=SC2034

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

    # This is for port forwarding, which could be used with -g switch, they say.
    # But is insecure to just allow.
    #row="GatewayPorts yes"
    #FILE_ROW_PERSIST "${row}" "${file}"
}

#===================
# SSH_ADD_SSH_KEY
#
# Add a SSH public key to a users authorized_keys file.
#
# Parameters:
#   $1: The name of the existing user to add ssh key file for
#   $2: Path to the pub key file to upload for the target user
#
#===================
SSH_ADD_SSH_KEY()
{
    SPACE_SIGNATURE="targetuser sshpubkeyfile"
    SPACE_REDIR="<${2}"
    SPACE_DEP="FILE_PIPE_APPEND PRINT"

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
# Parameters:
#   $1: The name if the existing user to add ssh key file for.
#   $2: Path to the pub key file to upload for the target user.
#
#=====================
SSH_RESET_SSH_KEY()
{
    # shellcheck disable=2034
    SPACE_SIGNATURE="targetuser sshpubkeyfile"
    # shellcheck disable=2034
    SPACE_REDIR="<${2}"
    # shellcheck disable=2034
    SPACE_DEP="FILE_PIPE_WRITE PRINT"

    local targetuser="${1}"
    shift

    local sshpubkeyfile="${1}"
    shift

    PRINT "Reset SSH pub key ${sshpubkeyfile} for user ${targetuser}." "debug"

    FILE_PIPE_WRITE "${_OSHOME}/${targetuser}/.ssh/authorized_keys"
}
