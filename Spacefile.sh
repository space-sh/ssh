#
# Copyright 2016-2017 Blockie AB
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
# The parameter lists do not have to be as long as the "hosts" list, if they
# are not then no or a default value is used.
# To put an item in the middle of a list as empty use ''.
#
# To have a space within a single value, say when using multiple flags,
# put a semicolon ";" between flags, this semicolon will later be substituted for a space.
# We can't put a space directly between flags for the same command since it will be split
# and treated as flags for different commands.
#
# Returns:
#   non-zero on error
#
#==================
SSH()
{
    SPACE_SIGNATURE="host:1 [user keyfile port flags shell command]"
    SPACE_DEP="PRINT _SSH_BUILD_COMMAND"

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

    local sshcommand=""
    _SSH_BUILD_COMMAND
    if [ "$?" -gt 0 ]; then
        return 1
    fi

    if [ "${is_terminal}" = "1" ]; then
        sshcommand="ssh -t ${sshcommand}"
    else
        sshcommand="ssh ${sshcommand}"
    fi

    PRINT "${sshcommand}" "debug"
    PRINT "Connecting to: ${hosts}"

    if [ -z "${shell}" ]; then
        # No shell given, run in login shell.
        if [ -n "${command}" ]; then
            PRINT "No shell defined, running in default login shell." "debug"
            eval "${sshcommand} \"\$command\""
        else
            PRINT "No shell defined, entering default login shell." "debug"
            eval "${sshcommand}"
        fi
    else
        # Run in specified shell.
        if [ -n "${command}" ]; then
            # Run command in defined shell (via login shell).
            PRINT "Run command in defined shell: ${shell}."  "debug"
            local command2="
RUN=\$(cat <<\"SPACEGAL_SAYS_END_OF_FINITY_\"
${command}
SPACEGAL_SAYS_END_OF_FINITY_
)
${shell} -c \"\$RUN\"
"
#printf "%s\n" "$command2"
            eval "${sshcommand} \"\$command2\""
        else
            PRINT "Enter defined shell: ${shell}." "debug"
            eval "${sshcommand} -- \"\${shell}\""
        fi
    fi
}

#================================
# _SSH_BUILD_COMMAND
#
# Helper macro
#
# Expects:
#   sshcommand
#   SSH/SSH_FS variables
#
# Return:
#   non-zero on error
#
#================================
_SSH_BUILD_COMMAND()
{
    SPACE_DEP="PRINT STRING_ESCAPE STRING_ITEM_COUNT STRING_ITEM_GET STRING_SUBST"

    local IFS="${IFS},"
    local count=0
    STRING_ITEM_COUNT "${hosts}" "count"
    if [ "${count}" -eq 0 ]; then
        PRINT "Missing host(s)." "error"
        return 1
    fi

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
        # '' is used as placeholder for no value, it can also
        # be a prefix to actual flags that have been concated on,
        # so we simply remove any leading ''.
        flags="${flags#\'\'}"
        # We use semicolon as a deferred space, since a space would separate the flags.
        STRING_SUBST "flags" ';' ' ' 1

        if [ -z "${sshcommand}" ]; then
            sshcommand="${keyfile:+-i ${keyfile} }-p ${port} ${flags:+${flags} }${user:+${user}@}${host}"
        else
            STRING_ESCAPE "sshcommand" '"'
            sshcommand="-o proxycommand=\"ssh -W ${host}:${port} ${sshcommand}\" ${keyfile:+-i ${keyfile} }-p ${port} ${flags:+${flags} }${user:+${user}@}${host}"
        fi
        index=$((index+1))
    done
}

#================================
# SSH_WRAP
#
# Wrapper over SSH that uses environment
# variables instead of positional arguments.
#
# If connecting to multiple hosts the variables must be balanced,
# see the SSH function for more information.
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
    # shellcheck disable=2034
    SPACE_FN="SSH"
    SPACE_ENV="SSHHOST SSHUSER=\"${SSHUSER-}\" SSHKEYFILE=\"${SSHKEYFILE-}\" SSHPORT=\"${SSHPORT-}\" SSHFLAGS=\"${SSHFLAGS-}\" SSHSHELL=\"${SSHSHELL-}\""
    # shellcheck disable=2034
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
    SPACE_SIGNATURE="sshkeyfile:1 [sshpubkeyfile]"
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
# Setup sshfs onto a remote machine, possibly via jump host(s).
#
# Parameters:
#   $1: remotepath, path on remote server to mount
#   $2: localpath, local path to mount to
#   $3: host address, or many space separated addresses if using jump hosts.
#       Last address is the final destination host.
#   $4: Optional matching list of user names.
#   $5: Optional matching list of key files.
#   $6: Optional matching list of ports. e.g. "223 22 222"
#   $7: Optional matching list of flags. e.g. "q q q"
#   $8: Optional shell to use on remote side, leave empty for default
#       login shell. e.g. "sh" or "bash".
#   $9: Optional command to execute on server, leave blank for interactive shell.
#
# The parameter lists do not have to be as long as the "hosts" list, if they
# are not then no or a default value is used.
# To put an item in the middle of a list as empty use ''.
#
# Expects:
#   SUDO: optional - set to "sudo" to use sudo.
#
# Returns:
#   non-zero on error
#
#
#================================
SSH_FS()
{
    SPACE_SIGNATURE="remotepath:1 localpath:1 host:1 [user keyfile port flags]"
    SPACE_DEP="PRINT FILE_MKDIRP FILE_CHOWN FILE_CHMOD _SSH_BUILD_COMMAND"
    SPACE_ENV="SUDO=${SUDO-}"

    local remotepath="${1}"
    shift

    local localpath="${1}"
    shift

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

    local sshcommand=""
    _SSH_BUILD_COMMAND
    if [ "$?" -gt 0 ]; then
        return 1
    fi

    local uid=
    uid="$(id -u)"
    local gid=
    gid="$(id -g)"

    sshcommand="${SUDO} sshfs ${sshcommand}:${remotepath} ${localpath} -o reconnect -o gid=${gid} -o uid=${uid}"

    PRINT "${sshcommand}" "debug"

    local SUDO="${SUDO-}"
    [ ! -d "${localpath}" ] &&
    FILE_MKDIRP "${localpath}" &&
    FILE_CHOWN "${uid}:${gid}" "${localpath}" &&
    FILE_CHMOD "770" "${localpath}"

    PRINT "Connecting to: ${hosts}, mounting ${remotepath} to $localpath" "info"

    # shellcheck disable=2090
    # shellcheck disable=2086
    sh -c "${sshcommand}"
}

#================================
# SSH_FS_UMOUNT
#
# Umount a sshfs mount point.
#
# Parameters:
#   $1: local path
#
#================================
SSH_FS_UMOUNT()
{
    # shellcheck disable=2034
    SPACE_SIGNATURE="localpath:1"
    # shellcheck disable=2034
    SPACE_DEP="PRINT"

    local localpath="${1}"
    shift

    PRINT "Unmounting $localpath" "info"

    fusermount -u "${localpath}"
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
    SPACE_SIGNATURE="targetuser:1 sshpubkeyfile:1"
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
    SPACE_SIGNATURE="targetuser:1 sshpubkeyfile:1"
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
