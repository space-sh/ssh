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


# Disable warning about local keyword
# shellcheck disable=SC2039
# Disable warning about indirectly checking status code
# shellcheck disable=SC2181

#==================
# SSH
#
# Connect to remote server over SSH.
# Optionally use one or more "jump servers"
#
# Parameters:
#   $1: host address, or many space separated addresses if using jump hosts.
#       Last address is the final destination host.
#       This value is optional if using a SSHHOSTFILE.
#   $2: Optional matching list of user names.
#   $3: Optional matching list of key files.
#   $4: Optional matching list of ports. e.g. "223 22 222"
#   $5: Optional matching list of flags. e.g. "q q q"
#   $6: Optional shell to use on remote side, leave empty for default
#   $6: Optional host.env file to use instead or added to other SSH_* variables.
#   $7: Optional shell to use on remote side, leave empty for default
#       login shell. e.g. "sh" or "bash".
#   $8: Optional command to execute on server, leave blank for interactive shell.
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
# If using a host file, this is an .env file where the SSH_* variables are read from
# the file instead from the cmd line.
# If values are also provided on command line then
# those values are appended to those in the .env file so that the host.env file can be
# used for declaring the jump host you are using for the host you are providing on cmd line.
# In the .env file there can also be jump hosts defined, if so that will trigger a read of
# another host.env file which will be used as a jump host for the host described in the first host.env file.
# A special case is when using a host.env file and declaring port, user, keyfile, flags on command line
# but no host parameter, then those values are used *instead* of the values read from the (first) host.env file.
#
# Example host.env file:
# HOST=1.2.3.4
# USER=clownsalad
# KEYFILE=.ssh/id_rsa
# PORT=4562
# FLAGS=-opasswordauthentication=no -ostricthostkeychecking=no -oexitonforwardfailure=no
# JUMPHOST=../host2
#
# HOST is required.
# PORT defaults to 22.
# Multiple flags can be used and are optional
# JUMPHOST is the path to another diretory where a host.env file exists, which will be used as a jumphost.
# JUMPHOST can also point to another .env file in the same directory.
# For KEYFILE and JUMPHOST relative paths will be set below user $HOME.
#
# Returns:
#   non-zero on error
#
#==================
SSH()
{
    SPACE_SIGNATURE="[host user keyfile port flags hostfile shell command args]"
    SPACE_DEP="PRINT _SSH_BUILD_COMMAND STRING_ESCAPE"

    local hosts="${1:-}"
    shift $(( $# > 0 ? 1 : 0 ))

    local users="${1-}"
    shift $(( $# > 0 ? 1 : 0 ))

    local keyfiles="${1-}"
    shift $(( $# > 0 ? 1 : 0 ))

    local ports="${1-}"
    shift $(( $# > 0 ? 1 : 0 ))

    local flagses="${1-}"
    shift $(( $# > 0 ? 1 : 0 ))

    local hostfile="${1-}"
    shift $(( $# > 0 ? 1 : 0 ))

    local shell="${1-}"
    shift $(( $# > 0 ? 1 : 0 ))

    local command="${1-}"
    shift $(( $# > 0 ? 1 : 0 ))

    # Args are used as "$@" and are passed along.

    local is_terminal=
    # 0 must be terminal for ssh to accept the -t flag
    # stdout/stderr must also be terminal to use terminal.
    # We really do not want terminal if we are to capture any output (cause we get carriage returns).
    if [ -t 0 ] && [ -t 1 ] && [ -t 2 ]; then
        is_terminal=1
    fi

    local out_sshcommand=""
    _SSH_BUILD_COMMAND
    if [ "$?" -gt 0 ]; then
        return 1
    fi

    if [ "${is_terminal}" = "1" ]; then
        out_sshcommand="ssh -t ${out_sshcommand}"
    else
        out_sshcommand="ssh ${out_sshcommand}"
    fi

    PRINT "${out_sshcommand}" "debug"
    PRINT "Connecting to: ${hosts}" "debug"

    if [ -z "${shell}" ]; then
        # No shell given, run in login shell.
        if [ -n "${command}" ]; then
            PRINT "No shell defined, running in default login shell." "debug"
            # We need to wrap it in function to let it use the args as it pleases.
            command="__sshwrap()
             {
                $command
             }
             __sshwrap"
            local args=
            local arg=
            for arg in "$@"; do
                STRING_ESCAPE arg '$"'
                args="${args}${args:+ }\"${arg}\""
            done
            eval "${out_sshcommand} \"\$command\" \$args"
        else
            PRINT "No shell defined, entering default login shell." "debug"
            eval "${out_sshcommand}"
        fi
    else
        # Run in specified shell.
        if [ -n "${command}" ]; then
            # Run command in defined shell (via login shell).
            PRINT "Run command in defined shell: ${shell}."  "debug"
            # shellcheck disable=SC2034
            local command2="
RUN=\$(cat <<\"SPACEGAL_SAYS_END_OF_FINITY_\"
${command}
SPACEGAL_SAYS_END_OF_FINITY_
)
${shell} -c \"\$RUN\" \"${shell}\""
            # Note: first argument to $RUN is the shell interpretor name provided as $0,
            # same as when using default shell, to keep consistency.
            local arg=
            for arg in "$@"; do
                STRING_ESCAPE arg '$"'
                command2="${command2} \"${arg}\""
            done
            # Add newline
            command2="${command2}
"
            eval "${out_sshcommand} \"\$command2\""
        else
            PRINT "Enter defined shell: ${shell}." "debug"
            eval "${out_sshcommand} -- \"\${shell}\""
        fi
    fi
}


# Disable warning about local keyword
# shellcheck disable=SC2039

#================================
# _SSH_BUILD_COMMAND
#
# Helper macro
#
# Expects:
#   out_sshcommand, hosts, users, keyfiles, ports, flagses, hostfile
#
#
# Return:
#   non-zero on error
#
#================================
_SSH_BUILD_COMMAND()
{
    SPACE_DEP="PRINT STRING_ESCAPE STRING_ITEM_COUNT STRING_ITEM_GET STRING_SUBST FILE_STAT FILE_REALPATH _SSH_BUILD_COMMAND_HOSTFILE"

    # First check if we are provided with a hostfile, if so read it and add onto the variables.
    if [ -n "${hostfile}" ]; then
        hostfile="$(FILE_REALPATH "${hostfile}")"
        if [ ! -f "${hostfile}" ]; then
            PRINT "Given hostfile does not exist: ${hostfile}." "error"
            return 1
        fi
        if ! _SSH_BUILD_COMMAND_HOSTFILE; then
            return 1
        fi
    fi


    if [ -z "${hosts}" ]; then
        PRINT "No SSHHOST provided." "error"
        return 1
    fi

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
        # be a prefix to actual flags that have been concatenated on,
        # so we simply remove any leading ''.
        flags="${flags#\'\'}"
        # We use semicolon as a deferred space, since a space would separate the flags.
        STRING_SUBST "flags" ';' ' ' 1

        if [ -n "${keyfile}" ]; then
            # Check permissions of key file because ssh might refuse it
            local prms=
            prms=$(FILE_STAT "${keyfile}" "%a" 2>/dev/null)
            if [ "$?" -eq 0 ]; then
                if [ "${prms%?00}" != "" ]; then
                    PRINT "The keyfile ${keyfile} has to broad permissions, ssh will likely refuse it." "warning"
                fi
            else
                PRINT "Could not stat keyfile ${keyfile}." "warning"
            fi
        fi

        if [ -z "${out_sshcommand}" ]; then
            out_sshcommand="${keyfile:+-i ${keyfile} }-p ${port} ${flags:+${flags} }${user:+${user}@}${host}"
        else
            STRING_ESCAPE "out_sshcommand" '"'
            out_sshcommand="-o proxycommand=\"ssh -W ${host}:${port} ${out_sshcommand}\" ${keyfile:+-i ${keyfile} }-p ${port} ${flags:+${flags} }${user:+${user}@}${host}"
        fi
        index=$((index+1))
    done
}

# Disable warning about local keyword
# shellcheck disable=SC2039

#================================
# _SSH_BUILD_COMMAND_HOSTFILE
#
# Helper macro
#
# Expects:
#   hostfile, hosts, users, keyfiles, ports, flagses
#
# Return:
#   non-zero on error
#
#================================
_SSH_BUILD_COMMAND_HOSTFILE()
{
    SPACE_DEP="PRINT STRING_SUBST FILE_REALPATH STRING_SUBSTR"

    # Check if we are to override values of the final target host
    # Only if no host was set, but other values were set do we override
    # the values of the final destination host.
    local overrideFlags=
    local overridePort=
    local overrideKeyfile=
    local overrideUser=
    if [ -z "${hosts}" ]; then
        if [ -n "${flagses}" ]; then
            overrideFlags="${flagses}"
            flagses=""
        fi
        if [ -n "${keyfiles}" ]; then
            overrideKeyfile="${keyfiles}"
            keyfiles=""
        fi
        if [ -n "${ports}" ]; then
            overridePort="${ports}"
            ports=""
        fi
        if [ -n "${users}" ]; then
            overrideUser="${users}"
            users=""
        fi
    fi

    local hostEnvDir="${hostfile%/*}"
    local HOST=
    local USER=
    local KEYFILE=
    local PORT=
    local FLAGS=
    local JUMPHOST=
    local counter="0"
    while true; do
        counter="$((counter+1))"

        if [ "${counter}" -gt 10 ]; then
            PRINT "Jumphost count exceeded, maximum 10 allowed." "error"
            return 1
        fi

        local value=
        local varname=
        for varname in HOST USER KEYFILE PORT FLAGS JUMPHOST; do
            value="$(grep -m 1 "^${varname}=" "${hostfile}")"
            value="${value#*${varname}=}"
            eval "${varname}=\"\${value}\""
        done

        STRING_SUBST "FLAGS" ' ' ';' 1

        # Check special case here. If user provided override values for final
        # target host, we override them now.
        if [ -n "${overrideFlags}" ]; then
            FLAGS="${overrideFlags}"
            overrideFlags=
        fi

        if [ -n "${overridePort}" ]; then
            PORT="${overridePort}"
            overridePort=
        fi

        if [ -n "${overrideKeyfile}" ]; then
            KEYFILE="${overrideKeyfile}"
            overrideKeyfile=
        fi

        if [ -n "${overrideUser}" ]; then
            USER="${overrideUser}"
            overrideUser=
        fi

        if [ -n "${KEYFILE}" ]; then
            KEYFILE="$(FILE_REALPATH "${KEYFILE}" "${hostEnvDir}")"
        fi

        if [ -z "${HOST}" ]; then
            PRINT "HOST must be defined in ${hostfile}." "error"
            return 1
        fi

        USER="${USER:-''}"
        KEYFILE="${KEYFILE:-''}"
        PORT="${PORT:-22}"
        FLAGS="${FLAGS:-''}"
        hosts="${HOST}${hosts:+ }${hosts}"
        users="${USER}${users:+ }${users}"
        keyfiles="${KEYFILE}${keyfiles:+ }${keyfiles}"
        ports="${PORT}${ports:+ }${ports}"
        flagses="${FLAGS}${flagses:+ }${flagses}"

        if [ -n "${JUMPHOST}" ]; then
            hostfile="$(FILE_REALPATH "${JUMPHOST}" "${hostEnvDir}")"
            if [ ! -f "${hostfile}" ]; then
                hostfile="${hostfile}/host.env"
            fi
            hostfile="$(FILE_REALPATH "${hostfile}")"
            if [ ! -f "${hostfile}" ]; then
                PRINT "JUMPHOST ${JUMPHOST} env file does not exist as: ${hostfile}" "error"
                return 1
            fi
            hostEnvDir="${hostfile%/*}"
            # Iterate again using JUMPHOST
        else
            break
        fi
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
#   SSHHOSTFILE: optional
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
    # shellcheck disable=2034
    SPACE_ENV="SSHHOST SSHUSER=\"${SSHUSER-}\" SSHKEYFILE=\"${SSHKEYFILE-}\" SSHPORT=\"${SSHPORT-}\" SSHFLAGS=\"${SSHFLAGS-}\" SSHHOSTFILE=\"${SSHHOSTFILE-}\" SSHSHELL=\"${SSHSHELL-}\""
    # shellcheck disable=2034
    SPACE_ARGS="\"\${SSHHOST}\" \"\${SSHUSER}\" \"\${SSHKEYFILE}\" \"\${SSHPORT}\" \"\${SSHFLAGS}\" \"\${SSHHOSTFILE}\" \"\${SSHSHELL}\" \"\${RUN}\" \"\$@\""
}


# Disable warning about local keyword
# shellcheck disable=SC2039
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
    SPACE_SIGNATURE="sshkeyfile:1 [bits sshpubkeyfile]"
    SPACE_DEP="PRINT FILE_MKDIRP FILE_CP"

    local sshkeyfile="${1}"
    shift

    local bits="${1:-2048}"
    shift $(( $# > 0 ? 1 : 0 ))

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
    FILE_MKDIRP "$(dirname "${sshkeyfile}")" && ssh-keygen -f "${sshkeyfile}" -b "${bits}" -N ""
    if [ "$?" != "0" ]; then
        return 1
    fi
    if [ "${sshpubkeyfile-}" != "" ]; then
        FILE_MKDIRP "$(dirname ${sshpubkeyfile})" && FILE_CP "${sshkeyfile}.pub" "${sshpubkeyfile}"
    fi
}


# Disable warning about local keyword
# shellcheck disable=SC2039
# Disable warning about indirectly checking status code
# shellcheck disable=SC2181

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
#   $8: Optional host.env file with SSH values
#
# The parameter lists do not have to be as long as the "hosts" list, if they
# are not then no or a default value is used.
# To put an item in the middle of a list as empty use ''.
#
# Returns:
#   non-zero on error
#
#
#================================
SSH_FS()
{
    SPACE_SIGNATURE="remotepath:1 localpath:1 [host user keyfile port flags hostfile]"
    SPACE_DEP="PRINT FILE_MKDIRP FILE_CHOWN FILE_CHMOD _SSH_BUILD_COMMAND"

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

    local hostfile="${1-}"
    shift $(( $# > 0 ? 1 : 0 ))

    local out_sshcommand=""
    _SSH_BUILD_COMMAND
    if [ "$?" -gt 0 ]; then
        return 1
    fi

    local uid=
    uid="$(id -u)"
    local gid=
    gid="$(id -g)"

    out_sshcommand="sshfs ${out_sshcommand}:${remotepath} ${localpath} -o reconnect -o gid=${gid} -o uid=${uid}"

    PRINT "${out_sshcommand}" "debug"

    [ ! -d "${localpath}" ] &&
    FILE_MKDIRP "${localpath}" &&
    FILE_CHOWN "${uid}:${gid}" "${localpath}" &&
    FILE_CHMOD "770" "${localpath}"

    PRINT "Connecting to: ${hosts}, mounting ${remotepath} to $localpath" "info"

    eval "${out_sshcommand}"
}


# Disable warning about local keyword
# shellcheck disable=SC2039

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


# Disable warning about local keyword
# shellcheck disable=SC2039

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
    SPACE_DEP="FILE_PIPE_APPEND PRINT OS_ID"

    local targetuser="${1}"
    shift

    local sshpubkeyfile="${1}"
    shift

    PRINT "Add SSH pub key ${sshpubkeyfile} for user ${targetuser}." "debug"

    local out_ostype=''
    local out_ospkgmgr=''
    local out_oshome=''
    local out_oscwd=''
    local out_osinit=''
    OS_ID

    if [ ! -d "${out_oshome}/${targetuser}/.ssh/" ]; then
        mkdir "${out_oshome}/${targetuser}/.ssh/" &&
        chmod 700 "${out_oshome}/${targetuser}/.ssh/" &&
        chown "${targetuser}:${targetuser}" "${out_oshome}/${targetuser}/.ssh/" ||
        PRINT "Could not create .ssh directory for user ${targetuser}." "error"
        return 1
    fi
    FILE_PIPE_APPEND "${out_oshome}/${targetuser}/.ssh/authorized_keys" &&
    chmod 600 "${out_oshome}/${targetuser}/.ssh/authorized_keys" &&
    chown "${targetuser}:${targetuser}" "${out_oshome}/${targetuser}/.ssh/authorized_keys"
}


# Disable warning about unused OS_ID out parameters
# shellcheck disable=2034
# Disable warning about local keyword
# shellcheck disable=SC2039

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
    SPACE_DEP="FILE_PIPE_WRITE PRINT OS_ID"

    local targetuser="${1}"
    shift

    local sshpubkeyfile="${1}"
    shift

    PRINT "Reset SSH pub key ${sshpubkeyfile} for user ${targetuser}." "debug"

    local out_ostype=''
    local out_ospkgmgr=''
    local out_oshome=''
    local out_oscwd=''
    local out_osinit=''
    OS_ID

    if [ ! -d "${out_oshome}/${targetuser}/.ssh/" ]; then
        mkdir "${out_oshome}/${targetuser}/.ssh/" &&
        chmod 700 "${out_oshome}/${targetuser}/.ssh/" &&
        chown "${targetuser}:${targetuser}" "${out_oshome}/${targetuser}/.ssh/" ||
        PRINT "Could not create .ssh directory for user ${targetuser}." "error"
        return 1
    fi
    FILE_PIPE_WRITE "${out_oshome}/${targetuser}/.ssh/authorized_keys" &&
    chmod 600 "${out_oshome}/${targetuser}/.ssh/authorized_keys" &&
    chown "${targetuser}:${targetuser}" "${out_oshome}/${targetuser}/.ssh/authorized_keys"
}
