# {{ ansible_managed }} [ansible-playbooks v{{ ansibleplaybooks_version }}]
#
# vim: set ts=4 sw=4 tw=0 et :
#
# Copyright (C) 2014-2016, University of Washington. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# To facilitate debugging or verbosity of specific programs, this
# library supports setting defaults on a per-program basis using
# the following two files. See default_enable_verbose() and
# default_enable_debug() for more.

#HELP_Global: /etc/environment contents
#HELP_Global: DIMS_DEFAULT_VERBOSE
DIMS_DEFAULT_VERBOSE=$HOME/.DIMS_DEFAULT_VERBOSE
#HELP_Global: DIMS_DEFAULT_DEBUG
DIMS_DEFAULT_DEBUG=$HOME/.DIMS_DEFAULT_DEBUG

# This file provides functions for DIMS scripts. It assumes
# the calling script is also using Google's shFlags module.
#HELP_Global export: UNAVAILABLE
export UNAVAILABLE="__unavailable__"
#HELP_Global export: UNDEFINED
export UNDEFINED="__undefined__"
#HELP_Global export: INVALID
export INVALID="__invalid__"
#HELP_Global export: NONEXISTENT
export NONEXISTENT="nonexistent" # String for simulating a Vagrant state
#HELP_Global export: TMPDIR
export TMPDIR=${TMPDIR:-/tmp}
# TODO(mboggess): normalize the global variable names for dirs
# between DIMS and fedora

# Enable more detailed debugging output.
# http://wiki.bash-hackers.org/scripting/debuggingtips
# Using embedded tab at the end of the string to make output more visually aligned
# and readable, e.g.:
# +(/opt/dims/bin/dims.ansible-playbook:427): main():     [[ 1 -eq 0 ]]
# +(/opt/dims/bin/dims.ansible-playbook:430): main():     is_fqdn --tags
# ++(/opt/dims/bin/dims_functions.sh:328): is_fqdn():     parse_fqdn --tags
# ++(/opt/dims/bin/dims_functions.sh:1064): parse_fqdn(): read -a fields
# +++(/opt/dims/bin/dims_functions.sh:1064): parse_fqdn():        echo --tags
# +++(/opt/dims/bin/dims_functions.sh:1064): parse_fqdn():        sed 's/\./ /g'
# ++(/opt/dims/bin/dims_functions.sh:1065): parse_fqdn(): '[' 1 -eq 1 ']'
# ++(/opt/dims/bin/dims_functions.sh:1066): parse_fqdn(): echo ''
# ++(/opt/dims/bin/dims_functions.sh:1067): parse_fqdn(): return 1
# +(/opt/dims/bin/dims_functions.sh:328): is_fqdn():      _tmp=
# +(/opt/dims/bin/dims_functions.sh:329): is_fqdn():      debug 'is_fqdn: _tmp='
# +(/opt/dims/bin/dims_functions.sh:216): debug():        [[ ! -z 0 ]]
# +(/opt/dims/bin/dims_functions.sh:216): debug():        [[ 0 -eq 0 ]]
# +(/opt/dims/bin/dims_functions.sh:217): debug():        echo '[+] DEBUG: is_fqdn: _tmp='
# [+] DEBUG: is_fqdn: _tmp=
# +(/opt/dims/bin/dims_functions.sh:218): debug():        return 0
# +(/opt/dims/bin/dims_functions.sh:330): is_fqdn():      [[ '' != '' ]]
# +(/opt/dims/bin/dims_functions.sh:333): is_fqdn():      return 1
# ++(/opt/dims/bin/dims.ansible-playbook:435): main():    compose_fqdn dimsdemo1 devops develop
# ++(/opt/dims/bin/dims_functions.sh:1126): compose_fqdn():       [[ 3 -ne 3 ]]
# ++(/opt/dims/bin/dims_functions.sh:1126): compose_fqdn():       [[ -z dimsdemo1 ]]
# ++(/opt/dims/bin/dims_functions.sh:1126): compose_fqdn():       [[ -z devops ]]
# ++(/opt/dims/bin/dims_functions.sh:1126): compose_fqdn():       [[ -z develop ]]
# ++(/opt/dims/bin/dims_functions.sh:1129): compose_fqdn():       echo dimsdemo1.devops.develop
# +(/opt/dims/bin/dims.ansible-playbook:435): main():     FQDN=dimsdemo1.devops.develop

# (This is a Bash internal variable)
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}():	}'

# Location of the error in the calling script.
function _error_location() {
    local _caller=$(caller 1)
    [[ ! -z "$_caller" ]] && echo "$_caller" | awk '{print "(" $3 ":" $1 ")";}'
}

function _caller_script_directory() {
    local _caller1=$(caller 1)
    local _c3=$(echo "$_caller1" | awk '{print $3;}')
    [[ -z "$c3" ]] && echo "?"
    [[ ! -z "$_caller1" ]] && echo $(dirname $_c3)
}

function error_exit() {
    local retval=$1 && shift
    if [[ $retval -eq 0 ]]; then
       echo "[!] !!! error_exit called with return code 0" >&2
       retval=42
    fi
    echo -n "[-] " >&2
    [[ $FLAGS_debug -eq ${FLAGS_TRUE} ]] && echo -n "$(_error_location) " >&2
    echo "$@" >&2
    exit $retval
}

# Do operating system specific setup here
#HELP_Global: OS
OS=$(uname -s); export OS

#HELP_Global: STAT
if [ "$OS" == "Linux" ]; then
	export STAT=stat
elif [ "$OS" == "Darwin" ]; then
	export STAT=gstat
else
	error_exit 1 "operating system type $OS not supported: please update this script"
fi

# Code derived from https://github.com/docker/global-hack-day-3/scaleswarm/test/integration/run.sh

function run_from_script_dir() {
    local script=$1
    # Try to use GNU version of readlink on non-GNU systems (e.g., BSD,
    # OSX). On OSX, install with "brew install coreutils".
    READLINK_LOCATION=$(which greadlink readlink | head -n 1)
    [[ -z "$READLINK_LOCATION" ]] && error_exit 1 "Failed to set READLINK_LOCATION"
    cd "$(dirname "$(${READLINK_LOCATION} -f "$script")")" 2>/dev/null
}

# Code for the on_exit functionality derived from:
# http://www.linuxjournal.com/content/use-bash-trap-statement-cleanup-temporary-files
#
# WARNING!!! This functionality relies on use of a global array
# 'on_exit_items', which is set within the on_exit() function.
# That means that on_exit() CANNOT -- eith directly, or
# indirectly -- be called within a sub-shell. Doing so will
# only alter the array in the sub-shell, not the calling shell.
# This means inline command substitution with $(some_function) or
# `some_function` that in turn calls add_on_exit, will not result
# in the desired action being performed.

# (This is an internal variable)
declare -a on_exit_items

# NOTE: This function CANNOT be called within a subshell.
function on_exit()
{
    debug "Entering on_exit()"
    for i in "${on_exit_items[@]}"
    do
        debug "on_exit() performing: $i"
        eval $i
    done
    # Unset the trap, since it was just invoked
    cancel_on_exit
}

function cancel_on_exit() {
    trap - EXIT SIGHUP SIGINT SIGQUIT SIGTERM
}

# NOTE: This function CANNOT be called within a subshell.
function add_on_exit()
{
    local n=${#on_exit_items[*]}
    debug "Adding on_exit_item \"$*\""
    on_exit_items[$n]="$*"
    if [[ $n -eq 0 ]]; then
        debug "Setting trap on_exit()"
        trap on_exit EXIT SIGHUP SIGINT SIGQUIT SIGTERM
    fi
}

function clear_on_exit()
{
    on_exit_items=( )
}

function get_on_exit()
{
    local -a _array=( "${on_exit_items[@]}" )
    declare -p _array | sed -e 's/^declare -a _array=//'
}

#HELP_Global export: RNDSTR
RNDSTR="XXXXXXXXXX"

# Do not output anything in this function, just file name.
function get_temp_file() {
    # If an extension is given, add it to the name (otherwise, use default)
    local _ext=${1:-tmp}
    local _tmp
    if [ "$OS" == "Linux" ]; then
        _tmp=$(mktemp --tmpdir $BASE.${RANDOM}${RNDSTR}.$_ext) || exit 1
    elif [ "$OS" == "Darwin" ]; then
        _tmp=$(mktemp -t $BASE.${RANDOM}${RNDSTR}.$_ext) || exit 1
    else
        error_exit 1 "get_temp_file() does not support operating system \"$OS\""
    fi
    echo $_tmp
}

#HELP get_true()
#HELP     Return the word "true" if $1 is 0, otherwise return "false".
#HELP     This converts Bash style return codes to a string.

get_true() {
    case $1 in
        0) echo 'true' ;;
        *) echo 'false' ;;
    esac
}

#HELP get_temp_dir()
#HELP     Produce a temporary directory and return the path to the
#HELP     caller on stdout. If the directory cannot be created, the
#HELP     function returns a null string.

function get_temp_dir() {
    local _tmp
    if [ "$OS" == "Linux" ]; then
        _tmp=$(mktemp -d --tmpdir $BASE.${RANDOM}${RNDSTR}) || exit 1
    elif [ "$OS" == "Darwin" ]; then
        _tmp=$(mktemp -d -t $BASE.${RANDOM}${RNDSTR}) || exit 1
    else
        _tmp=''
    fi
    echo $_tmp
}

export PROGRAM="${0##-}"
#HELP_Global: BASE
export BASE=$(basename "$PROGRAM")
#HELP_Global: PWD
export PWD=$(pwd); export PWD
#HELP_Global: COMMAND
export COMMAND=""

# Known bug: REV holds the revision of the code in the current
# working directory when the script invoking this file is run.
# This may not be what you expect. (See dims-302)
caller_script_dir="$(_caller_script_directory)"

#HELP_Global export: DIMS_REV
if [[ "$caller_script_dir" != "?" ]] && [[ -r "$caller_script_dir" ]]; then
    DIMS_REV=$(cd $caller_script_dir && git describe 2>/dev/null)
    if [ $? -ne 0 ]; then
        DIMS_REV="unspecified"
    fi
else
    DIMS_REV="unspecified"
fi

# Inherit DIMS_VERSION from sourcing script, else use dims-ci-utils version
#HELP_Global: DIMS_VERSION
if [ ! -z "$DIMS_VERSION" ]; then
	DIMS_VERSION=$DIMS_VERSION
else
	DIMS_VERSION="2.12.2"
fi

#HELP
#HELP get_dims_private_dir()
#HELP     Return the name of the root of the directory where
#HELP     all DIMS secrets (SSH keys, passwords, etc) are
#HELP     stored (a directory with the name "private-$DEPLOYMENT")
#HELP     If $1 is set, it is assumed to be the specific
#HELP     deployment whose private directory you want to find.
#HELP     If no specific secrets directory is found, return
#HELP     the public playbooks root.

function get_dims_private_dir() {
    local _deployment=${1:-${DEPLOYMENT}}
    if [[ -d $GIT/private-${_deployment} ]]; then
        echo "$GIT/private-${_deployment}"
    elif [[ -z ${1} && ! -z "$DIMS_PRIVATE" ]]; then
        echo "$DIMS_PRIVATE"
    else
        echo "${PBR}"
    fi
}

#HELP
#HELP get_repo_origin_name()
#HELP     Return the name of the origin Git repository name
#HELP     associated with the directory specified by $1, or
#HELP     the process current working directory if no arg.
#HELP     This function extracts the basename from the
#HELP     repo's remote.origin.url, w/o the .git extension.

get_repo_origin_name() {
    local _dir=$1
    local _origin
    (if [[ ! -z "$_dir" && -d "$_dir" ]]; then cd $_dir; fi;
     _origin=$(git config remote.origin.url 2>/dev/null);
     [[ ! -z "$_origin" ]] && echo $(basename $_origin .git)
    )
}

#HELP
#HELP get_repo_toplevel()
#HELP     Return the path to the top level of the local Git
#HELP     repository. If $1 is specified, that directory is
#HELP     used to locate the repo, otherwise the current
#HELP     working directory is used.

get_repo_toplevel() {
    local _dir=$1
    (if [[ ! -z "$_dir" ]]; then
         if [[ -d "$_dir" ]]; then
             cd $_dir;
         else
             return 1;
        fi;
     fi;
    git rev-parse --show-toplevel 2>/dev/null
    )
}

#HELP
#HELP get_repo_local_name()
#HELP     Similar to get_repo_origin_name(), but derive the
#HELP     directory name instead. Nothing is returned if
#HELP     this is not a Git repo.

get_repo_local_name() {
    local _dir=$1
    local _toplevel=$(get_repo_toplevel $_dir)
    [[ ! -z "$_toplevel" ]] && echo $(basename $_toplevel)
}

# The following comes from this stackoverflow Q&A
# http://stackoverflow.com/questions/10707173/bash-parameter-quotes-and-eval/10707498#10707498

#HELP_Global: LOG
LOG="eval _log \${BASH_SOURCE} \${LINENO}"

_log () {
    _BASH_SOURCE=`basename "${1}"` && shift
    _LINENO=${1} && shift

    echo "(${_BASH_SOURCE}:${_LINENO}) $@"
}

#HELP
#HELP export_vars_from_file()
#HELP     If the file specified by $1 exists, source it while
#HELP     'allexport' is set to ensure variables are loaded into
#HELP     the environment for child processes to access.

function export_vars_from_file() {
    local _file=$1
    if [[ -f ${_file} ]]; then
        # Force all variables read from file to be exported to environment.
        set -o allexport
        debug "source ${_file} with 'allexport' set"
        source ${_file}
        set +o allexport
    else
        debug "export_vars_from_file(): ${_file} not found"
    fi
}


#HELP
#HELP plural_s()
#HELP    Provide a plural 's' inline (no newline) for proper grammarization
#HELP    usage: echo "I have 1 thing$(plural_s 1), I have 2 thing$(plural_s 2)."
#HELP           I have 1 thing, I have 2 things.
plural_s() {
    local n=$1
    if [[ -z "$n" ]]; then
        echo -n "" && return 1
    elif [[ $n -eq 1 ]]; then
        echo -n "" && return 0
    else
        echo -n "s" && return 0
    fi
}

#HELP
#HELP default_enable_verbose()
#HELP     This function allows the default for verbosity to be set on a
#HELP     per-program basis by checking to see if the calling program is
#HELP     listed in $HOME/.DIMS_DEFAULT_VERBOSE with the value 1. If so,
#HELP     verbosity defaults to enabled (otherwise, disabled). The
#HELP     command line option --verbose can be used to set as desired
#HELP     at run time. Use with shflags as:
#HELP        DEFINE_boolean 'verbose' $(default_enable_verbose) 'be verbose' 'v'

default_enable_verbose() {
    if [[ ! -f $DIMS_DEFAULT_VERBOSE ]]; then
        echo 'false'
        return 1
    fi
    local _default=$(cat ${DIMS_DEFAULT_VERBOSE} | awk -F: "
BEGIN { e=0; }
/$BASE/ { print \$2; exit; }
END { print e; }
    ")
    [[ "$_default" == "1" ]] && echo 'true' || echo 'false'
    return 0
}

#HELP
#HELP default_enable_debug()
#HELP     This function allows the default for debugging to be set on a
#HELP     per-program basis by checking to see if the calling program is
#HELP     listed in $HOME/.DIMS_DEFAULT_DEBUG with the value 1. If so,
#HELP     verbosity defaults to enabled (otherwise, disabled). The
#HELP     command line option --debug can be used to set as desired
#HELP     at run time. Use with shflags as:
#HELP        DEFINE_boolean 'debug' $(default_enable_debug) 'debug mode' 'v'

default_enable_debug() {
    if [[ ! -f $DIMS_DEFAULT_DEBUG ]]; then
        echo 'false'
        return 1
    fi
    local _default=$(cat ${DIMS_DEFAULT_DEBUG} | awk -F: "
BEGIN { e=0; }
/$BASE/ { print \$2; exit; }
END { print e; }
    ")
    [[ "$_default" == "1" ]] && echo 'true' || echo 'false'
    return 0
}

#HELP
#HELP dims_main_init()
#HELP     Initialize DIMS project scrips by handling common shflags setup
#HELP     operations related to --debug, --verbose, etc. Doing things in
#HELP     this function allows less DRY coupling of logic across many
#HELP     scripts.

dims_main_init() {
    # Process flags that just return something and exit
    [[ ${FLAGS_help} -eq ${FLAGS_TRUE} ]] && exit 0
    [[ ${FLAGS_usage} -eq ${FLAGS_TRUE} ]] && usage && exit 0
    [[ ! -z ${FLAGS_version} && ${FLAGS_version} -eq ${FLAGS_TRUE} ]] && version && exit 0

    debug "$PROGRAM enabled DEBUG mode"

    # If both --debug and --verbose, set tracing
    [[ ${FLAGS_debug} -eq ${FLAGS_TRUE} && ${FLAGS_verbose} -eq ${FLAGS_TRUE} ]] && set -x
}

#HELP
#HELP verbose_enabled()
#HELP     Return Bash true (0) if verbose is enabled, otherwise
#HELP     false (1).

verbose_enabled() {
    [[ ! -z ${FLAGS_verbose} && ${FLAGS_verbose} -eq ${FLAGS_TRUE} || $DIMS_VERBOSE -eq 1 ]]
}

# This function expects use of shFlags.
#HELP
#HELP verbose()
#HELP     Output the command line arguments as a string if verbose is
#HELP     enabled to stdout.  Output looks like:
#HELP       [+] The arguments of the call

verbose() {
    verbose_enabled && echo "[+] $(echo $@ | sed 's/[	 ]\+/ /g')"
    return 0
}

#HELP
#HELP debug_enabled() {
#HELP     Return Bash true (0) if verbose is enabled, otherwise
#HELP     false (1).

debug_enabled() {
    [[ ! -z ${FLAGS_debug} && ${FLAGS_debug} -eq ${FLAGS_TRUE} || $DIMS_DEBUG -eq 1 ]]
}

#HELP
#HELP debug()
#HELP     Produce debugging output on stderr from $@ if debugging is enabled.
#HELP     Output on stderr looks like:
#HELP       [+] DEBUG: The arguments of the call

debug() {
    debug_enabled && echo "[+] DEBUG: $@" >&2
    return 0
}

#HELP
#HELP warn()
#HELP     Produce a string that looks the same as the error_exit() output on
#HELP     stderr and return (rather than exit).
#HELP     Output on stderr looks like:
#HELP       [-] The arguments of the call
warn() {
    echo "[-] $(echo $@ | sed -e 's/[[:blank:]]\+/ /g' -e 's/[[:blank:]][[:blank:]]*$//')" >&2
    return 0
}

#HELP
#HELP say()
#HELP     Output all args passed to function, eliminating any repeated whitespace,
#HELP     to stdout. This allows multi-line output with lots of whitespace to be
#HELP     cleaner. (See also: say_raw()) Output on stdout looks like:
#HELP       [+] The arguments of the call

say() {
    #echo "[+] $(echo $@ | sed -e 's/[	 ]\+/ /g' -e 's/  *$//')"
    echo "[+] $(echo $@ | sed -e 's/[[:blank:]]\+/ /g' -e 's/[[:blank:]][[:blank:]]*$//')"
    return 0
}

#HELP
#HELP say_raw()
#HELP     Output the string passed to function as $1, without any processing, with
#HELP     formatting like verbose() on stdout.
#HELP     (See also: say()) Output on stdout looks like:
#HELP       [+] The   contents   of   first    arg    with   all   these   spaces

say_raw() {
    printf "[+] %s" "$1"
    return 0
}

#HELP
#HELP get_hostname()
#HELP     Return the hostname

get_hostname() {
    echo $(hostname)
}

#HELP
#HELP get_domainname()
#HELP     Return the DNS domain name

get_domainname() {
    echo $(domainname)
}

#HELP
#HELP get_deployment()
#HELP     Return the top level DNS name component

get_deployment() {
    echo $(domainname | sed 's/.*\.\(.*\)/\1/')
}

#HELP
#HELP get_fqdn()
#HELP     Return the fully qualified domain name

get_fqdn() {
    echo $(hostname).$(domainname)
}


# TODO(dittrich): Add to list other status output values.

#HELP
#HELP get_swarm_status()
#HELP     Return the status of Docker Swarm. Possible values are
#HELP     'inactive', 'active', 'pending', ...
#HELP     Returns $UNAVAILABLE if docker command fails.

get_swarm_status() {
    local status=$(docker info 2>/dev/null | grep '^Swarm:')
    if [[ $? -ne 0 ]]; then
        echo $UNAVAILABLE
        return 1
    fi
    echo $status | awk -F': ' '{print $2;}'
}

#HELP
#HELP ansible_connection()
#HELP     Return a valid Ansible --connection value depending on whether
#HELP     this looks like a local host or a remote host.

ansible_connection() {
    if [[ $1 == "localhost" || $1 == $(get_fqdn) ]]; then
        echo "local"
    else
        echo "smart"
    fi
}

#HELP
#HELP is_fqdn()
#HELP     Return Bash true (0) or false (1) in $? if arg looks like a
#HELP     valid FQDN.

is_fqdn() {
    _tmp=$(parse_fqdn $1)
    debug "is_fqdn: _tmp=$_tmp"
    if [[ $_tmp != "" ]]; then
        return 0
    else
        return 1
    fi
}

#HELP
#HELP usage()
#HELP    Placeholder function that simple returns a message that
#HELP    usage() is not defined. (Override this function in your own
#HELP    script after sourcing this file.)

function usage() {
    say "Function usage() is not defined"
}

#HELP
#HELP version()
#HELP     Prints out a version number for the current script.
function version() {
	if [[ ${FLAGS_debug} -eq ${FLAGS_TRUE} || ${FLAGS_verbose} -eq ${FLAGS_TRUE} ]]; then
		echo "$PROGRAM $DIMS_VERSION"
	else
		echo "$BASE $DIMS_VERSION"
	fi
}

# Print a header for test programs.
function header() {
	echo "PROGRAM: $PROGRAM"
	echo "REV:     $DIMS_REV"
	echo "HOST:    $(hostname)"
	echo "DATE:    $(iso8601dateshort)"
	echo "USER:    $USER"
	if [ "x$COMMAND" != "x" ]; then
	  echo "COMMAND: $COMMAND"
	fi
	echo ""
	echo "[dims-ci-utils version $(version) (rev $DIMS_REV)]"
	echo ""
}

function printresults() {
	local _passed=$1
	local _failed=${2:-0}
	local _alltests=$((_passed + _failed))
	printf "\n"
	printf "%10s%10s%10s\n" " " "Test Cases" "Total"
	printf "%10s%10d%10d\n" "Passed" $_passed $_passed
	printf "%10s%10d%10d\n" "Failed" $_failed $_failed
	printf "%10s%10d%10d\n" "Total" $_alltests $_alltests
	printf "\n"
	[ $_failed == 0 ]
}

#HELP
#HELP get_time_now()
#HELP     Return the current Unix time in seconds.

function get_time_now() {
    date +%s
}

#HELP
#HELP get_file_timestamp()
#HELP     Return the last modify timestamp for the file $1 using
#HELP     'date --reference=FILE +%s'. Return Bash False (1) if file
#HELP     does not exist, otherwise return True (0).

function get_file_timestamp() {
    local _file=$1
    if [[ ! -f $_file ]]; then
        echo ""
        return 1
    else
        echo "$(date --reference=${_file} +%s)"
        return 0
    fi
}

#HELP
#HELP get_files_in_directory()
#HELP     Return all of the files in the top level (i.e., no recursion
#HELP     into subdirectories) found the directory specified by $1.
#HELP     On error, returns $UNAVAILABLE and return code 1.
#HELP     (NOTE: Will not work properly with spaces in file names)

function get_files_in_directory() {
    local _dir="$1"
    local _type="${2:-f}" # Default to file type

    if [[ ! -d ${_dir} ]]; then
        echo $UNAVAILABLE
        return 1
    fi
    (cd ${_dir} 2>/dev/null && ls >/dev/null) ||
        error_exit 1 "get_files_in_directory: cannot access directory ${_dir}"

    [[ "$_type" == "d" || "$_type" == "f" ]] ||
        error_exit 1 "get_files_in_directory: type \"${_type}\" not supported"

    local _results=$(cd ${_dir} &&
        find * -maxdepth 0 -type ${_type} -printf "%p " 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        echo $UNAVAILABLE
        return 1
    fi

    echo $_results
    return 0
}

#HELP
#HELP get_directories_in_directory()
#HELP     Return all of the directories in the top level (i.e., no recursion
#HELP     into subdirectories) found the directory specified by $1.
#HELP     On error, returns $UNAVAILABLE and return code 1.
#HELP     (NOTE: Will not work properly with spaces in file names)

function get_directories_in_directory() {
    get_files_in_directory "$1" d
}

#HELP
#HELP get_time_diff()
#HELP     Calculate the time difference between two timestamps (in seconds)
#HELP     specified as $1 and $2. Hours continue growing past 24:59:59, but
#HELP     this function does not convert days, weeks, months, etc. (just
#HELP     hours, minutes, seconds).

function get_time_diff() {
    local t1=$1
    local t2=$2
    local td=$((t2-t1))
    [[ $td -ge 0 ]] || error_exit 1 "Time difference between $t1 and $t2 is not positive ($td)"
    printf "%02d:%02d:%02d" "$(($td / 3600 ))" "$((($td % 3600) / 60))" "$(($td % 60))"
}

#HELP
#HELP get_time_diff_from_2files()
#HELP     Calculate the time difference between last modify timestamps
#HELP     of two files given as $1 and $2.

# Logic courtesy of:
# http://stackoverflow.com/questions/8903239/how-to-calculate-time-difference-in-bash-script

function get_time_diff_from_2files() {
    local f1=$1
    local f2=$2
    local t1=$(get_file_timestamp ${f1}) || error_exit 1 "No such file: $f1"
    local t2=$(get_file_timestamp ${f2}) || error_exit 1 "No such file: $f2"
    get_time_diff $t1 $t2
}

#HELP
#HELP validate_required_vars()
#HELP     This function takes two files: $1 references a file containing VAR=val
#HELP     pairs, and $2 references a file containing a list of those VAR names
#HELP     that should occur in the file $1. This is a 1:1 mapping of variable
#HELP     names that results in true/false determination as to whether all of
#HELP     the required variables are available.

function validate_required_vars() {
    local _varsdefs=$1
    local _reqvars=$2

    if [[ -z ${_varsdefs} || ! -f ${_varsdefs} ]]; then
        error_exit 1 "Variable definitions file does not exist: ${_varsdefs}"
    elif [[ -z ${_reqvars} || ! -f ${_reqvars} ]]; then
        error_exit 1 "Required variables file does not exist: ${_reqvars}"
    fi

    # Extract the VAR side of VAR=val pairs and compare resulting sorted list
    # with the sorted contents of the required variables list.
    # (Handle the deletion of the temp file without using trap, since the
    # program calling this, like 'bats', may also be trying to trap.
    local _retval=0
    local _reqtmp=$(get_temp_file)
    sort < ${_reqvars} > ${_reqtmp}
    if [[ $? -ne 0 ]]; then
        rm -f ${_reqtmp}
        error_exit $? "Failed to sort ${_reqvars} into ${_reqtmp}"
    fi
    (awk -F= '{print $1;}' < ${_varsdefs} | sort) |
     diff - ${_reqtmp} 2>/dev/null >/dev/null
    _retval=$?
    rm -f ${_reqtmp} && return $_retval
}

#HELP
#HELP get_help_text()
#HELP     Extract help text from a file, where "help text" is identified by lines
#HELP     that begin with "#HELP ". Identify those lines, and strip that line
#HELP     identifier from them, to produce self-documenting help text. This is used
#HELP     by both Makefile and Bash scripts.

function get_help_text() {
    local fname=$1
    [[ -f $fname ]] || error_exit 1 "get_help_text(): file does not exist: $fname"
    say "Help text for $fname"
    say ""
    say "Global variables (local or exported)"
    say ""
    egrep "^#HELP_Global" $fname |
        sed -e 's/#HELP_//' |
        sort
    say ""
    say "Functions and usage"
    say ""
    egrep "^#HELP$|#HELP " $fname |
        sed -e 's/#HELP //' -e 's/#HELP//'
}

function require_runasroot() {
	if [ $(whoami) != 'root' ]; then
		echo "$BASE: must be run as root"
		exit 1
	fi
}

function require_gnu_stat() {
	# Require GNU stat
	$STAT  --version 2>&1 | grep -q GNU
	if [ ! $? ]
	then
		echo "$0: this version of stat is not supported"
		exit 1
	fi
}

function require_string() {
	if [ "x$1" == "x" ]; then
		echo "$BASE: $2"
		exit 1
	fi
}

function require_fileexists() {
	if [ ! -f $1 ]
	then
		echo "$BASE: can't find expected output file: \"$1\""
		exit 1
	fi
}

function md5compare() {
	local _file=$1
	local _expectedmd5=$2
	local _result=$(md5sum < $_file | sed 's/ -.*//')
	if [ $_result == $_expectedmd5 ]; then
		echo 1
	else
		echo 0
	fi
}

function sha256compare() {
	local _file=$1
	local _expectedsha256=$2
	local _result=$(sha256sum < $_file | sed 's/ -.*//')
	if [ $_result == $_expectedsha256 ]; then
		echo 1
	else
		echo 0
	fi
}

# If $1 is a file, use that as input. Otherwise,
# run the command specified in $1.

function run_if_no_input() {
	if [ "x$1" == "x" -a "x$2" != "x" ]; then
		($2 2>&1)
	elif [ -f "$1" ]; then
		cat $1
	fi
}

function send_output_email() {
	# $1 is recipients
	# $2 is sender
	# $3 is subject line
	# $4 is file containing body of message to send
	(echo "To: $1";
	 echo "From: $2";
	 echo "Subject: $3";
	 echo "Date: $(date)";
	 echo "";
	 echo "";
	 cat $4) | /usr/sbin/sendmail -t -oi
}

#HELP
#HELP vagrant_plugin_present()
#HELP     Return Bash true/false if plugin ($1) is installed in Vagrant.
#HELP     Vagrant stores plugins in each user's home directory in the
#HELP     directory $HOME/.vagrant.d/gems/gems/, so it is not possible
#HELP     to manage plugins system-wide (and tests for existence of a
#HELP     a plugin must be done on a per-user basis when running scripts
#HELP     that use these plugins.)

function vagrant_plugin_present() {
    local _plugin=$1
    vagrant plugin list | grep -q "^$_plugin"
}

#HELP
#HELP get_vagrant_global_status()
#HELP     Print out the global status of all Vagrants. (Simple wrapper
#HELP     for 'vagrant global-status' command that prints everything
#HELP     up to the first empty line, i.e., strips the helper text
#HELP     at the end of the status output.)

function get_vagrant_global_status() {
    # Note: Vagrant puts out a bunch of spaces at the end
    # of the line, which complicates parsing the output.
    vagrant global-status 2>/dev/null |
        sed 's/  *$//' |
        sed -e '/^$/,$d'
}

#HELP get_vagrant_id()
#HELP     Return the ID of the vagrant specified by $1 (either short or
#HELP     fully-qualified name) by finding its run directory (as returned
#HELP     by get_vagrant_run_dir()) in the output of 'vagrant global-status'.

function get_vagrant_id() {
    local _rundir=$(get_vagrant_run_dir $1) ||
        return $?
    get_vagrant_global_status |
        awk '$NF == "'$_rundir'" { print $1; quit;}'
}

#HELP
#HELP get_vagrant_status()
#HELP     Return the status of the vagrants named by $@ (if any), otherwise
#HELP     get names of all Vagrants in $VMDIR/run and return their status.

function get_vagrant_status() {
    local _vagrants=("$@")
    debug "_vagrants=\"${_vagrants[@]}\""
    local _vagrant
    local _status
    # NOTE: We began naming vargrants with just short names, not fully qualified
    # names. To adhere to this convention, split off the short-name of the
    # host from the FQDN and use that for local references.
    for _vagrant in ${_vagrants[@]}; do
        is_fqdn $_vagrant && _vagrant=$(get_hostname_from_fqdn $_vagrant)
        echo -n "${_vagrant}: "
        _id=$(get_vagrant_id $_vagrant)
        if [[ -z ${_id} ]]; then
            echo "not_created"
            continue
        fi
        _status=$(get_vagrant_status_by_id $_id)
        if [[ ! -z "$_status" ]]; then
             echo "$_status"
        else
            echo "not_created"
            #echo "spotless"
        fi
    done
}

#HELP
#HELP get_vagrant_status_by_id()
#HELP     Returns the status string for a Vagrant. This function
#HELP     can be passed a directory path as returned by
#HELP     get_vagrant_run_dir(), or will assume that the process
#HELP     current working directory is already within a Vagrant
#HELP     run directory in order for Vagrant to access its state
#HELP     properly. If there is no Vagrant, the return result
#HELP     Note: This function is highly dependent on Vagrant's
#HELP     error output, which is not very programmer-friendly
#HELP     to start with (hence the tail/head/sed foo just to

function get_vagrant_status_by_id() {
    local _id=$1
    # Isolate the specific line in Vagrant's verbose and unstructured
    # output to then parse out just the status. (Vagrant should really
    # provide a structured way to do this deterministicly.)
	vagrant status $_id 2>/dev/null |
		tail -n +3 |
		head -n 1 |
		sed -e 's/  */ /g' -e 's/default //' -e 's/ (.*)$//'
    if [[ $? -ne 0 ]]; then
        echo $NONEXISTENT
        return 1
    fi
    return 0
}

#HELP
#HELP vagrant_halt()
#HELP     Halt the vagrant named by $1 by calling
#HELP     "vagrant_desired_state $vagrant poweroff"

function vagrant_halt() {
    local _vagrant=$1
    [[ ! -z "$_vagrant" ]] || return 1
    vagrant_desired_state ${_vagrant} poweroff
}

#HELP vagrant_suspend()
#HELP     Halt the vagrant named by $1 by calling
#HELP     "vagrant_desired_state $vagrant saved"

function vagrant_suspend() {
    local _vagrant=$1
    [[ ! -z "$_vagrant" ]] || return 1
    vagrant_desired_state ${_vagrant} saved
}


#HELP vagrant_up()
#HELP     Start the vagrant named by $1 by calling
#HELP     "vagrant_desired_state $vagrant running"

function vagrant_up() {
    local _vagrant=$1
    [[ ! -z "$_vagrant" ]] || return 1
    vagrant_desired_state ${_vagrant} running
}

#HELP
#HELP vagrant_desired_state()
#HELP     Attempt to put the Vagrant named by $1 into the state defined
#HELP     by $2. These are both required arguments.  The available states
#HELP     are: "running", "poweroff", "aborted", and "saved".
#HELP     If the related Vagrant operation succeeds, 0 is returned. If
#HELP     the operation fails, the "vagrant" program's return code is
#HELP     returned. If the operational state is invalid, 4 is returned.

function vagrant_desired_state() {
    local _vagrant=$1
    local _state=$2
    local _id
    [[ ! -z "$_vagrant" ]] || return 1
    [[ ! -z "$_state" ]] || return 2
    _id=$(get_vagrant_id $_vagrant)
    case ${_state} in
    running)
        start_vagrant_by_id ${_id}
        return $?
        ;;
    saved)
        suspend_vagrant_by_id ${_id}
        return $?
        ;;
    poweroff)
        poweroff_vagrant_by_id ${_id}
        return $?
        ;;
    *)
        return 4
        ;;
    esac
    return 4
}

#HELP
#HELP start_vagrant_by_id()
#HELP     Starts the vagrant with ID specified as $1 (required argument)
#HELP     by issuing "vagrant $id --no-provision". Any error text from
#HELP     Vagrant is ignored, but the return code is passed along. If
#HELP     the vagrant is already in the "running" state, 0 is returned.

function start_vagrant_by_id() {
    local _id=$1
    local _status
    [[ ! -z "$_id" ]] || return 1
    _status=$(get_vagrant_status_by_id ${_id}) || return 2
    case ${_status} in
        running)
            return 0
            ;;
        poweroff)
            vagrant up $_id --no-provision 2>/dev/null || return 3
            return 0
            ;;
        aborted)
            vagrant up $_id --no-provision 2>/dev/null || return 3
            return 0
            ;;
        saved)
            vagrant up $_id --no-provision 2>/dev/null || return 3
            return 0
            ;;
        *)
            return 4
            ;;
    esac
    # Should not get here.
    return 4
}

#HELP
#HELP suspend_vagrant_by_id()
#HELP     Suspends the vagrant with ID specified as $1 (required argument)
#HELP     by issuing "vagrant suspend $id". Any error text from
#HELP     Vagrant is ignored, but the return code is passed along. If
#HELP     the vagrant is already in the "saved" state, 0 is returned.
#HELP     If it is in any other state, 1 is returned. If any other
#HELP     problems are encountered, 4 is returned.

function suspend_vagrant_by_id() {
    local _id=$1
    local _status
    [[ ! -z "$_id" ]] || return 1
    _status=$(get_vagrant_status_by_id ${_id}) || return 2
    case ${_status} in
        running)
            vagrant suspend $_id 2>/dev/null || return $?
            return 0
            ;;
        poweroff)
            return 1
            ;;
        aborted)
            return 1
            ;;
        saved)
            return 0
            ;;
        *)
            return 4
            ;;
    esac
    # Should not get here.
    return 4
}

#HELP
#HELP poweroff_vagrant_by_id()
#HELP     Halts the vagrant with ID specified as $1 (required argument)
#HELP     by issuing "vagrant halt $id". Any error text from
#HELP     Vagrant is ignored, but the return code is passed along. If
#HELP     the vagrant is already in the "poweroff" state, 0 is returned.
#HELP     If it is in any other state, 0 is also returned (because it is
#HELP     now "off".) If any other problems are encountered, 4 is returned.

function poweroff_vagrant_by_id() {
    local _id=$1
    local _status
    [[ ! -z "$_id" ]] || return 1
    _status=$(get_vagrant_status_by_id ${_id}) || return 2
    case ${_status} in
        running)
            vagrant halt $_id 2>/dev/null || return $?
            return 0
            ;;
        poweroff)
            return 0
            ;;
        aborted)
            return 0
            ;;
        saved)
            return 0
            ;;
        *)
            return 4
            ;;
    esac
    # Should not get here.
    return 4
}

#HELP
#HELP resume_vagrant_by_id()
#HELP     Resumes a saved vagrant with ID specified as $1 (required argument)
#HELP     by issuing "vagrant resume $id". Any error text from
#HELP     Vagrant is ignored, but the return code is passed along. If
#HELP     the vagrant is already in the "running" state, 0 is returned.
#HELP     If it is in any other state, 1 is returned. If any other problems
#HELP     are encountered, 4 is returned.

function resume_vagrant_by_id() {
    local _id=$1
    local _status
    [[ ! -z "$_id" ]] || return 1
    _status=$(get_vagrant_status_by_id ${_id}) || return 2
    case ${_status} in
        running)
            return 0
            ;;
        poweroff)
            return 1
            ;;
        aborted)
            return 1
            ;;
        saved)
            vagrant resume $_id 2>/dev/null || return $?
            return 0
            ;;
        *)
            return 4
            ;;
    esac
    # Should not get here.
    return 4
}

# Return an ISO 8601 format date string similar to logmon.
# Requires GNU date to get sub-second values.
function iso8601date()
{
	if [ $(date +"%N") == "N" ]; then
		date -u '+%Y-%m-%dT%H:%M:%S%z'
	else
		date -u '+%Y-%m-%dT%H:%M:%S.%N%z' |
		sed 's|\(.*\)\(...\)\(.\)\(..\)\(..\)$|\1\3\4:\5|'
	fi

}

# Return an shorter version of ISO 8601 format date
# string suitable for file names.
function iso8601dateshort()
{
	date +%FT%T%Z
}

# Return the uid, gid, mode and path to the specified file(s).

function stat_file() {
	# Force a relative path to precede file name
    [[ -z "$1" ]] && error_exit 1 "no file specified"
    [[ ! -f "$1" ]] && error_exit 1 "file not found: \"$1\""
	local _name=$(dirname $1)/$(basename $1)
	local _result=$($STAT -c "%a %U %G %n" $_name | sed "s/[']//")
	echo $_result
}


#HELP
#HELP get_release_codename()
#HELP     Return the release code name for the given host operating system
#HELP     and Bash success (0) else "" and Bash failure (1).

function get_release_codename() {
    local codename
    # Typical Debian?
    codename=$(lsb_release -c 2>/dev/null | cut -f2)
    if [[ ! -z ${codename} ]]; then
        echo ${codename}
        return 0
    fi
    # CoreOS?
    codename=$(awk -F= '/DISTRIB_CODENAME/ { print $2;}' /etc/lsb-release 2>/dev/null | sed 's/"//g')
    if [[ ! -z ${codename} ]]; then
        echo ${codename}
        return 0
    fi
    # Darwin
    codename=$(guname -o 2>/dev/null)
    if [[ ! -z ${codename} ]]; then
        echo ${codename}
        return 0
    fi
    # Unsupported as of yet
    echo ${UNAVAILABLE}
    return 1
}

#HELP
#HELP service_is_enabled()
#HELP     Return Bash true (0) if service specified by $1 is enabled,
#HELP     1 if not, 2 if service is not known.
#HELP     (NOT IMPLEMENTED YET).

function service_is_enabled() {
#    local codename=$(get_release_codename)
#    case codename in
#    jessie)
#    wheezy)
#    $UNAVAILABLE) return 2
    error_exit 1 "service_is_enabled: not implemented yet"
}


#HELP
#HELP service_is_running()
#HELP     Return Bash true (0) or false (1) depending on whether service
#HELP     specified by $1 is running or not.
#HELP     (NOT IMPLEMENTED YET).

function service_is_running() {
    error_exit 1 "service_is_running: not implemented yet"
}

#HELP
#HELP is_valid_ssh_keytype()
#HELP    Returns true (0) or false (1) if the key type specified
#HELP    by $1 is a valid key type we support. Recognized key types
#HELP    are "rsa", "dsa", "ecdsa".

function is_valid_ssh_keytype() {
    case $1 in
        dsa) ;;
        ecdsa) ;;
        rsa) ;;
        *) return 1;;
    esac
    return 0
}

#HELP
#HELP get_user_ssh_key_name()
#HELP     Derives the file name for the SSH key of a specified
#HELP     user ($1) and key type ($2). The user name is required.
#HELP     If no user name is provided, returns "" and return code
#HELP     1. The key type is optional (see is_valid_ssh_keytype()
#HELP     for valid types.) If the key type is not supported,
#HELP     the function returns 2. Otherwise, a non-null string is
#HELP     produced with return code 0.
#HELP     $1 - the user name of the owner of the key. (REQUIRED)
#HELP     $2 - the key type. (OPTIONAL)
#HELP     (Default key type is "rsa")

function get_user_ssh_key_name() {
    local _user=$1
    local _type=${2:-rsa}

    [[ ! -z "${_user}" ]] || return 1

    is_valid_ssh_keytype ${_type} || return 2

    echo "dims_${_user}_${_type}"
    return 0
}

#HELP
#HELP get_user_ssh_key_dir()
#HELP     Returns the directory name to the location of where
#HELP     SSH user keys for the specified user and deployment.
#HELP     $1 - the user name of the owner of the key. (REQUIRED)
#HELP     $2 - the deployment. (OPTIONAL: default is current
#HELP          deployment.)

function get_user_ssh_key_dir() {
    local _user=$1
    local _deployment=${2:-$(get_deployment)}

    if [[ -z ${_user} ]]; then
        echo $UNAVAILABLE
        return 1
    fi

    if [[ -z ${_deployment} ]]; then
        error_exit 1 "Could not determine deployment"
    fi

    echo "${DIMS_PRIVATE}/files/ssh-keys/user/${_user}"
    return 0
}

#HELP
#HELP get_custom
#HELP     This function returns the full path to the customization
#HELP     directory pointed to by the environment variable
#HELP     DIMS_PRIVATE, if defined, otherwise PBR.

function get_custom() {
    echo ${DIMS_PRIVATE:-${PBR:-$UNDEFINED}}
}

#HELP
#HELP get_ssh_private_key_file
#HELP     This function returns the full path to the SSH
#HELP     private RSA key file name for the specified user. The
#HELP     name of this function mirrors that of the Ansible variable
#HELP     referencing the private SSH key to use for remote
#HELP     SSH access. The path is constructed according to the
#HELP     DIMS path convention for separating "secrets" from public
#HELP     repositories.
#HELP     $1 - the user name of the owner of the key (REQUIRED)
#HELP     $2 - the deployment customization directory (OPTIONAL)

function get_ssh_private_key_file() {
    local _user=$1
    local _custom="${2:-$(get_custom)}"
    local _kfile="${_custom}/files/ssh-keys/user/${_user}/dims_${_user}_rsa"

    if [[ -f ${_kfile}  ]]; then
        echo ${_kfile}
        return 0
    else
        echo ''
        return 1
    fi
}

#HELP get_user_ssh_key()
#HELP     Returns the contents of the specified user's SSH key.
#HELP     (Calls get_user_ssh_key_name() and
#HELP     get_user_ssh_key_dir() to get name of file.)

function get_user_ssh_key() {
    local _user=$1; shift
    local _deployment=$1; shift
    local _root=${1:-$DIMS_PRIVATE}

    if [[ -z ${_user} || -z ${_deployment} || -z ${_root} ]]; then
        echo ''
        return 1
    fi

    local _dir=$(get_user_ssh_key_dir $_user $_deployment $_root)
    local _file=$(get_user_ssh_key_name $_user $_root)
    cat "${_dir}/${_file}"
    return $?
}

#HELP
#HELP get_host_ssh_key_name()
#HELP     Returns the path to the base name of the specified SSH key for
#HELP     the specified host.
#HELP     First argument should be the host's shortname;
#HELP     second argument should be the deployment;
#HELP     third argument should be the state of the key (public or private key);
#HELP     fourth argument should be the key type (dsa, ecdsa, ed25519, rsa);
#HELP     fifth argument can be the root to the private directory.

function get_host_ssh_key_name() {
    local _host=$1; shift
    local _deployment=$1; shift
    local _state=$1; shift
    local _type=$1; shift
    local _root=${1:-$DIMS_PRIVATE}
    local _dir=$(get_host_ssh_key_dir ${_host} ${_deployment} ${_root})

    if [[ -z ${_host} || -z ${_deployment} || -z ${_state} || -z ${_type} || -z ${_root} ]]; then
        echo $UNAVAILABLE
        return 1
    fi

    if [[ "${_state}" == "private" ]]; then
        echo "${_dir}/ssh_host_${_type}_key"
    else
        echo "${_dir}/ssh_host_${_type}_key.pub"
    fi
    return 0
}

#HELP
#HELP get_host_ssh_key_dir()
#HELP     Returns the directory name to the location of the specified SSH key
#HELP     for the specified host.
#HELP     First argument should be the host's shortname;
#HELP     second argument should be the deployment;
#HELP     third argument can be the root to the private directory.

function get_host_ssh_key_dir() {
    local _host=$1; shift
    local _deployment=$1; shift
    local _root=${1:-$DIMS_PRIVATE}

    if [[ -z ${_host} || -z ${_deployment} || -z ${_root} ]]; then
        echo $UNAVAILABLE
        return 1
    fi

    echo "${_root}/${_deployment}/ssh-keys/host/${_host}"
    return 0
}

#HELP
#HELP get_host_ssh_key()
#HELP     Returns the contents of the specified user's SSH key.
#HELP     (Calls get_host_ssh_key_name() to get name of file.)

function get_host_ssh_key() {
    local _host=$1; shift
    local _deployment=$1; shift
    local _state=$1; shift
    local _type=$1; shift
    local _root=${1:-$DIMS_PRIVATE}

    if [[ -z ${_host} || -z ${_deployment} || -z ${_state} || -z ${_type} || -z ${_root} ]]; then
        echo $UNAVAILABLE
        return 1
    fi

    local _dir=$(get_host_ssh_key_dir ${_host} ${_deployment} ${_root})
    local _file=$(get_host_ssh_key_name ${_host} ${_deployment} ${_state} ${_type} ${_root})
    cat "${_dir}/${_file}"
    return $?
}

#HELP
#HELP create_host_ssh_key()
#HELP     Returns Bash true (0) if it successfully creates
#HELP     a host SSH key pair. Returns Bash false (1), otherwise.
#HELP     First argument should be the host's shortname;
#HELP     second argument should be the deployment;
#HELP     third argument should be the root to the private directory.

function create_host_ssh_key() {
    local _host=$1; shift
    local _deployment=$1; shift
    local _root=${1:-$DIMS_PRIVATE}
    local _dir="$(get_host_ssh_key_dir ${_host} ${_deployment} ${_root})"

    if [ ! -d ${_dir} ]; then
        mkdir ${_dir} ||
            error_exit 1 "create_host_ssh_key: could not mkdir ${_dir}/"
    fi

    keys.host.create -d ${_dir} -p ${_host}
    return $?
}

#HELP
#HELP delete_host_ssh_key()
#HELP     Returns Bash true (0) if it successfully deletes the directory
#HELP     holding host SSH key pairs for the specified host. Returns
#HELP     Bash false (1), otherwise.
#HELP     First argument should be the host's shortname;
#HELP     second argument should be the deployment;
#HELP     third argument can be the root to the private directory.

function delete_host_ssh_key() {
    local _host=$1; shift
    local _deployment=$1; shift
    local _root=${1:-$DIMS_PRIVATE}

    if [[ -z ${_host} || -z ${_deployment} || -z ${_root} ]]; then
        echo $UNAVAILABLE
        return 1
    fi

    rm -rf $(get_host_ssh_key_dir ${_host} ${_deployment} ${_root})
    return $?
}

#HELP
#HELP get_vagrantd_home_dir()
#HELP     Returns the directory name of the hidden $HOME
#HELP     directory Vagrant uses to store program data.

function get_vagrantd_home_dir() {
    echo "$HOME/.vagrant.d"
}

#HELP
#HELP get_vagrant_home_dir()
#HELP     Returns the directory name of the hidden $HOME
#HELP     directory Vagrant uses to store machine data.

function get_vagrant_home_dir() {
    echo "$HOME/.vagrant"
}

#HELP
#HELP get_vbox_home_dir()
#HELP     Returns the directory name of the $HOME
#HELP     directory VirtualBox uses to store data.

function get_vbox_home_dir() {
    echo "$HOME/VirtualBox\ VMs"
}

#HELP
#HELP get_vagrant_run_dir()
#HELP     Return the directory name for storing the Vagrant
#HELP     environment for name ($1).

function get_vagrant_run_dir() {
    local _shortname
    if [[ -z "$1" ]]; then
        echo $UNAVAILABLE
        return 1
    fi

    if is_fqdn $1; then
        _shortname=$(get_hostname_from_fqdn $1)
    else
        _shortname=$1
    fi

    echo "${VMDIR}/run/${_shortname}"
    return 0
}

#HELP
#HELP get_packer_ovf_dir()
#HELP     Return the directory name for storing the OVF file for
#HELP     baseos ($1) and osversion ($2).

function get_packer_ovf_dir() {
    local baseos=$1
    local osversion=$2

    if [[ -z "${baseos}" || -z "${osversion}" ]]; then
        echo "${UNAVAILABLE}"
        return 1
    fi

    echo "${VMDIR}/ovf/$baseos-$osversion"
    return 0
}


#HELP
#HELP get_packer_box_dir()
#HELP     Return the directory name for storing the BOX file for
#HELP     baseos ($1) and osversion ($2).

function get_packer_box_dir() {
    local baseos=$1
    local osversion=$2

    if [[ -z "${baseos}" || -z "${osversion}" ]]; then
        echo "${UNAVAILABLE}"
        return 1
    fi

    echo "${VMDIR}/box/$baseos-$osversion"
    return 0
}

#HELP
#HELP get_os_base_name()
#HELP     Return base name comprised of baseos ($1) and osversion ($2)
#HELP     for consistency in naming objects related to distribution ISOs,
#HELP     Packer base and box files, Vagrants, etc.

function get_os_base_name() {
    local baseos=$1
    local osversion=$2

    if [[ -z "${baseos}" || -z "${osversion}" ]]; then
        echo "${UNAVAILABLE}"
        return 1
    fi

    echo "${baseos}-${osversion}"
    return 0
}

#HELP
#HELP get_packer_ovf_name()
#HELP     Return Packer OVF name that matches the format produced by
#HELP     DIMS scripts for a vagrant with baseos ($1) and osversion ($2).

#TODO(dittrich): Retire calls to this in favor of get_os_base_name() then delete
function get_packer_ovf_name() {
    local baseos=$1
    local osversion=$2

    if [[ -z "${baseos}" || -z "${osversion}" ]]; then
        echo "${UNAVAILABLE}"
        return 1
    fi

    echo "${baseos}-${osversion}"
    return 0
}


#HELP
#HELP get_packer_box_name()
#HELP     Return Packer Virtualbox BOX name that matches the format produced by
#HELP     DIMS scripts for a vagrant with baseos ($1) and osversion ($2).

function get_packer_box_name() {
    local baseos=$1
    local osversion=$2

    if [[ -z "${baseos}" || -z "${osversion}" ]]; then
        echo "${UNAVAILABLE}"
        return 1
    fi
    echo "packer_${baseos}-${osversion}_box_virtualbox"
    return 0
}

#HELP
#HELP get_packer_ovf_json_name()
#HELP     Return Packer OVF json name that matches
#HELP     the format produced by DIMS scripts for a vagrant
#HELP     with baseos ($1) and osversion ($2).

function get_packer_ovf_json_name() {
    local baseos=$1
    local osversion=$2

    if [[ -z "${baseos}" || -z "${osversion}" ]]; then
        echo "${UNAVAILABLE}"
        return 1
    fi

    echo "${baseos}-${osversion}_base"
    return 0
}

#HELP
#HELP get_packer_box_json_name()
#HELP     Return Packer BOX json name that matches
#HELP     the format produced by DIMS scripts for a vagrant
#HELP     with baseos ($1) and osversion ($2).

function get_packer_box_json_name() {
    local baseos=$1
    local osversion=$2

    if [[ -z "${baseos}" || -z "${osversion}" ]]; then
        echo "${UNAVAILABLE}"
        return 1
    fi

    echo "${baseos}-${osversion}_box"
    return 0
}

#HELP
#HELP get_packer_json_dir()
#HELP     Return the directory storing derived json files for
#HELP     Packer to use in the creation of a vagrant with
#HELP     baseos ($1) and osversion ($2).

function get_packer_json_dir() {
    local baseos=$1
    local osversion=$2

    if [[ -z "${baseos}" || -z "${osversion}" ]]; then
        echo "${UNAVAILABLE}"
        return 1
    fi

    echo "${GIT}/dims-packer/${baseos}_64_vagrant"
    return 0
}

#HELP
#HELP get_isos()
#HELP     Return a list of all .iso files in the $VMDIR/cache/isos
#HELP     directory.

function get_isos() {
    # Note: Echo returns same string if no wildcard expansion occurs.
    local isos="$(echo $VMDIR/cache/isos/*.iso)"
    [[ "$isos" = "$VMDIR/cache/isos/*.iso" ]] && echo "" || echo $isos
}


#HELP
#HELP get_packer_ovfs()
#HELP     Return an arg list of OVF names, or "".

function get_packer_ovfs() {
    # Note: Echo returns same string if no wildcard expansion occurs.
    local ovfs="$(echo $VMDIR/ovf/*/*.ovf)"
    [[ "$ovfs" = "$VMDIR/ovf/*/*.ovf" ]] && echo "" || echo $ovfs
}


#HELP
#HELP get_packer_boxes()
#HELP     Return an arg list of BOX names, or "".

function get_packer_boxes() {
    # Note: Echo returns same string if no wildcard expansion occurs.
    local boxes=$(echo $VMDIR/box/*/*.box)
    [[ "$boxes" = "$VMDIR/box/*/*.box" ]] && echo "" || echo $boxes
}


#NOTE(mboggess): This is different from get_packer_boxes()
# because it asks for boxes known to Vagrant, not ones we
# stored in our organizing structure. Vagrant doesn't know
# about ones in $VMDIR/box/*/ unless a VM has been created
# via Vagrant with that .box file.
#HELP
#HELP get_vagrant_boxes()
#HELP     Return an arg list of BOX names known to Vagrant.

function get_vagrant_boxes() {
    vagrant box list
}

#HELP
#HELP get_virtualbox_vm_ids()
#HELP     Return the Virtualbox VM IDs associated with name ($1)
#HELP     If one ID is found, return 0 with the ID.
#HELP     If no name is specified, return 1 and $UNAVAILABLE.
#HELP     If vboxmanage fails, return 2 and $UNAVAILABLE.
#HELP     If more than one Virtualbox ID is found for the
#HELP     specified name, return 3 along with all the names.

function get_virtualbox_vm_ids() {
    local name=$1
    if [[ -z "${name}" ]]; then
        echo "${UNAVAILABLE}"
        return 1
    fi
    # Output lines are pairs that look like:
    # "node01_default_1477027795977_86100" {1ac0853a-00a7-4418-8c70-a91db50aa384}
    local result=$(vboxmanage list vms |
        sed 's/["\{\}]//g' |
        awk "/^${name}_default_/ { print \$2; }"
    )
    # TODO(dittrich): Bug? Did we want to pass retval from vboxmanage or awk?
    if [[ $? -ne 0 ]]; then
        echo "${UNAVAILABLE}"
        return 2
    fi
    # We have now reduced the pairs to just IDs.
    local words=$(echo ${result} | wc -w)
    if [[ $words -eq 0 ]]; then
        return 1
    elif [[ $words -eq 1 ]]; then
        echo ${result}
        return 0
    else
        echo ${result}
        return 3
    fi
}


#HELP
#HELP exists_vagrant_run_dir()
#HELP     Return Bash true (0) or false (!0) depending on whether
#HELP     a $VMDIR/run directory exists associated with name ($1)

function  exists_vagrant_run_dir() {
    local name=$1

    if [[ -z "${name}" ]]; then
        echo "${UNAVAILABLE}"
        return 1
    fi

    local _dir=$(get_vagrant_run_dir ${name})
    [[ -d ${_dir} ]]
}


#HELP
#HELP exists_dims_vagrant_env()
#HELP     Return Bash true (0) or false (!0) depending on whether
#HELP     any directories comprising $VMDIR environment exist. Call with:
#HELP     $1 - baseos
#HELP     $2 - osversion
#HELP     $3 - name

function exists_dims_vagrant_env() {
    local baseos=$1
    local osversion=$2
    local name=$3

    if [[ -z "${baseos}" || -z "${osversion}" || -z "${name}" ]]; then
        echo "${UNAVAILABLE}"
        return 1
    fi

    if exists_packer_box_dir ${baseos} ${osversion}; then
        return 0
    elif exists_packer_ovf_dir ${baseos} ${osversion}; then
        return 0
    elif exists_vagrant_run_dir ${name}; then
        return 0
    else
        return 1
    fi
}


#HELP
#HELP exists_packer_ovf_file()
#HELP     Return Bash true (0) or false (!0) depending on whether a
#HELP     Packer OVF file exists in the $VMDIR environment whose
#HELP     baseos-osversion matches $1-$2

function exists_packer_ovf_file() {
    local baseos=$1
    local osversion=$2

    if [[ -z "${baseos}" || -z "${osversion}" ]]; then
        echo "${UNAVAILABLE}"
        return 1
    fi

    #vboxmanage list vms | grep -q "^\"${1}\""
    local ovfdir=$(get_packer_ovf_dir ${baseos} ${osversion})
    local ovfbase=$(get_packer_ovf_name ${baseos} ${osversion})
    [[ -f ${ovfdir}/${ovfbase}.ovf ]]
}


#HELP
#HELP exists_packer_ovf_dir()
#HELP     Return Bash true (0) or false (!0) depending on whether a
#HELP     directory to store a Packer OVF file exists in the $VMDIR
#HELP     environment whose baseos-osversion matches $1-$2

function exists_packer_ovf_dir() {
    local baseos=$1
    local osversion=$2

    if [[ -z "${baseos}" || -z "${osversion}" ]]; then
        echo "${UNAVAILABLE}"
        return 1
    fi

    local ovfdir=$(get_packer_ovf_dir ${baseos} ${osversion})
    [[ -d ${ovfdir} ]]
}


#HELP
#HELP exists_packer_box_file()
#HELP     Return Bash true (0) or false (!0) depending on whether a
#HELP     Packer BOX file exists in the $VMDIR environment whose
#HELP     baseos-osversion matches $1-$2

function exists_packer_box_file() {
    local baseos=$1
    local osversion=$2

    if [[ -z "${baseos}" || -z "${osversion}" ]]; then
        echo "${UNAVAILABLE}"
        return 1
    fi

    # TODO(dittrich): Keep one or the other: check vagrant, or check /vm?
    #vagrant box list | grep -q "$(get_packer_box_name $1 $2)"
    local boxdir=$(get_packer_box_dir ${baseos} ${osversion})
    local boxbase=$(get_packer_box_name ${baseos} ${osversion})
    [[ -f ${boxdir}/${boxbase}.box ]]
}


#HELP
#HELP exists_packer_box_dir()
#HELP     Return Bash true (0) or false (!0) depending on whether a
#HELP     directory to store a Packer BOX file exists in the $VMDIR
#HELP     environment whose baseos-osversion matches $1-$2

function exists_packer_box_dir() {
    local baseos=$1
    local osversion=$2

    if [[ -z "${baseos}" || -z "${osversion}" ]]; then
        echo "${UNAVAILABLE}"
        return 1
    fi

    local boxdir=$(get_packer_box_dir ${baseos} ${osversion})
    [[ -d ${boxdir} ]]
}


#HELP
#HELP exists_vagrant_box()
#HELP     Return Bash true (0) or false (!0) depending on whether
#HELP     Vagrant has knowledge of a box associated with
#HELP     baseos-osversion matching $1-$2.

function exists_vagrant_box() {
    local baseos=$1
    local osversion=$2

    if [[ -z "${baseos}" || -z "${osversion}" ]]; then
        echo "${UNAVAILABLE}"
        return 1
    fi

    vagrant box list | grep -q "$(get_packer_box_name ${baseos} ${osversion})"
}

#HELP
#HELP exists_virtualbox_vm()
#HELP     Return Bash true (0) if only one VM associate with the
#HELP     name "$1_default" is found. For other return results,
#HELP     see get_virtualbox_vm_ids().

function exists_virtualbox_vm() {
    local name=$1
    [[ ! -z "${name}" ]] ||
        error_exit 1 "No virtual machine name specified"
    get_virtualbox_vm_ids ${name} 2>/dev/null >/dev/null
    return $?

}


#HELP
#HELP is_virtualbox_vm_running()
#HELP     Return Bash true (0) or false (!0) depending on whether a Virtualbox
#HELP     VM is running whose Virtualbox ID matches $1. (Uses 'grep -q' for
#HELP     checking: see 'man grep')

function is_virtualbox_vm_running() {
    vboxmanage list runningvms | grep -q "{$1}"
}


#HELP
#HELP rm_packer_box_dir()
#HELP     Remove the directory storing Packer BOX file
#HELP     associated with baseos ($1) and osversion ($2).

function rm_packer_box_dir() {
    local baseos=$1
    local osversion=$2

    if [[ -z "${baseos}" || -z "${osversion}" ]]; then
        echo "${UNAVAILABLE}"
        return 1
    fi

    local boxdir="$(get_packer_box_dir ${baseos} ${osversion})"
    rm -rf ${boxdir}
    return $?
}


#HELP
#HELP rm_packer_ovf_dir()
#HELP     Remove the directory storing Packer OVF file
#HELP     associated with baseos ($1) and osversion ($2).

function rm_packer_ovf_dir() {
    local baseos=$1
    local osversion=$2

    if [[ -z "${baseos}" || -z "${osversion}" ]]; then
        echo "${UNAVAILABLE}"
        return 1
    fi

    local ovfdir="$(get_packer_ovf_dir ${baseos} ${osversion})"
    rm -rf ${ovfdir}
    return $?
}


#HELP
#HELP rm_vagrant_run_dir()
#HELP     Remove the directory storing the VM environment
#HELP     given by name ($1)

function rm_vagrant_run_dir() {
    local name=$1

    if [[ -z "${name}" ]]; then
        echo "${UNAVAILABLE}"
        return 1
    fi

    local rundir="$(get_vagrant_run_dir ${name})"
    rm -rf ${rundir}
    return $?
}


#HELP
#HELP rm_dims_vagrant_env()
#HELP     Remove all artifacts in $VMDIR environment. Call with:
#HELP     $1 - baseos
#HELP     $2 - osversion
#HELP     $3 - name

function rm_dims_vagrant_env() {
    local baseos=$1
    local osversion=$2
    local name=$3

    if [[ -z "${baseos}" || -z "${osversion}" || -z "${name}" ]]; then
        echo "${UNAVAILABLE}"
        return 1
    fi

    if exists_packer_box_dir ${baseos} ${osversion}; then
        rm_packer_box_dir ${baseos} ${osversion}
    fi
    if exists_packer_ovf_dir ${baseos} ${osversion}; then
        rm_packer_ovf_dir ${baseos} ${osversion}
    fi
    if exists_vagrant_run_dir ${name}; then
        rm_vagrant_run_dir ${name}
    fi
}

#NOTE(mboggess): I think this is a duplicate of rm_virtualbox_vm()
#                which is actually what is happening in these
#                two functions.
#HELP
#HELP rm_packer_ovf()
#HELP     Remove VirtualBox ovf associated with name $1.

function rm_packer_ovf() {
    local ovfid=$(vboxmanage list vms |
            sed 's/[\{\}]//g' |
            awk "/^\"${1}\"/ { print \$2; }")

    if [[ -z "$ovfid" ]]; then
        echo "${UNAVAILABLE}"
        return 1
    fi

    vboxmanage unregistervm $ovfid --delete
}


#HELP
#HELP rm_vagrant_box()
#HELP     Remove Vagrant box known to the Vagrant program
#HELP     associated with baseos-osversion $1-$2.

function rm_vagrant_box() {
    local baseos=$1
    local osversion=$2

    if [[ -z "${baseos}" || -z "${osversion}" ]]; then
        echo "${UNAVAILABLE}"
        return 1
    fi

    vagrant box --force remove "$(get_packer_box_name ${baseos} ${osversion})" 2>/dev/null
    return $?
}


#HELP
#HELP rm_virtualbox_vm()
#HELP     Remove Virtualbox VM whose Virtualbox ID matches $1.
#HELP     $1 must only include one string.

function rm_virtualbox_vm() {
    local boxid=$1
    [[ ! -z "$boxid" ]] ||
        error_exit 1 "rm_virtualbox_vm: No boxid provided"
    [[ $(echo $boxid | wc -w) -eq 1 ]] ||
        error_exit 1 "rm_virtualbox_vm: More than one boxid provided: ${boxid}"
    vboxmanage unregistervm $boxid --delete ||
        error_exit 1 "rm_virtualbox_vm: Failed to unregistervm $boxid"
    return 0
}


#HELP
#HELP halt_virtualbox_vm()
#HELP     Use 'vboxmange controlvm' to do 'poweroff' on VM that
#HELP     is running whose Virtualbox ID matches $1. If no boxid
#HELP     is given the function returns the same exit code (1)
#HELP     that 'vboxmange' returns if it can't find the box ID
#HELP     passed to it.

function halt_virtualbox_vm() {
    local boxid=$1
    [[ ! -z $boxid ]] || return 1
    vboxmanage controlvm $boxid poweroff 2>/dev/null
    return $?
}

#HELP
#HELP canonicalize_path()
#HELP     Return a path with any/all slashes replaced with "_"
#HELP     (e.g., "/bin/ls" would become "_bin_ls".

function canonicalize() {
    echo $1 | sed 's/\//_/g'
}

#HELP
#HELP ensure_logdir_exists()
#HELP     Create directory specified by $1 if it does not exist. This
#HELP     is used primarily for debugging in Vagrants, where files and
#HELP     command output are copied to a subdirectory of /vagrant inside
#HELP     the Vagrant virtual machine.

function ensure_logdir_exists() {
    local _dir=$1
    if [[ ! -d ${_dir} ]]; then
        mkdir -p ${_dir}
    fi
}

#HELP
#HELP command_to_logdir()
#HELP     Copy the output of a command to a log directory. The directory
#HELP     is specified by $1 and the remaining arguments on the command
#HELP     are the command to be run. The output is placed into a file
#HELP     whose name is based on the command (first argument), optionally
#HELP     canonicalized by converting slashes in the path to
#HELP     the file with "_" (e.g., "/etc/hosts" would become "_etc_hosts".
#HELP     If the log directory does not exist, it is created first.

function command_to_logdir() {
    local _dir=$1; shift
    local _command=$1; shift
    local _canonical
    local _now=$(date +%s)

    ensure_logdir_exists $_dir
    _canonical=$(canonicalize $_command).${_now} ||
        error_exit $? "Failed to canonicalize \"$_command\""
    verbose "Capturing output of \"$_command $@\""
    $_command $@ > $_dir/$_canonical ||
        warn "Failed to run \"$_command $@\""
    return $?
}

#HELP
#HELP escape_spaces()
#HELP     Return a string with all spaces escaped with backslashes to
#HELP     allow variable definitions in a file that can be 'source'd
#HELP     in Bash scripts and 'include'd in GNU Makefile.

function escape_spaces() {
    echo "$1" | sed s'/ /\\ /g'
}

#HELP
#HELP file_to_logdir()
#HELP     Create copies of files to a log directory. The directory is specified
#HELP     by $1 and all remaining arguments on the command line are files.
#HELP     Each file name is canonicalized by converting slashes in the path to
#HELP     the file with "_" (e.g., "/etc/hosts" would become "_etc_hosts".
#HELP     If the log directory does not exist, it is created first.

function file_to_logdir() {
    local _dir=$1; shift
    local _file
    local _canonical
    local _retval=0
    local _now=$(date +%s)

    ensure_logdir_exists $_dir
    for _file in $@; do
        if ! _canonical=$(canonicalize $_file).${_now}; then
            warn "Failed to canonicalize \"$_command\""
            _retval=1
            continue
        fi
        debug "_canonical=$_canonical"
        verbose "Capturing $_file to ${_dir}/${_canonical}"
        if [[ -f $_file ]]; then
            cp $_file ${_dir}/${_canonical}
        else
            warn "File not found: $_file"
            _retval=1
            continue
        fi
    done
    return $_retval
}

#HELP
#HELP get_inventory()
#HELP     Return the path to the inventory directory for the specified
#HELP     deployment. This function checks to see if a directory with
#HELP     the base name "private-" concatenated with the deployment
#HELP     (or $1) with an "inventory/" subdirectory within it is
#HELP     present. If so, it is returned. Otherwise, the inventory
#HELP     directory is sought within the directory pointed to by
#HELP     $2. Failing that, the inventory directory within the
#HELP     playbooks root ($PBR) is returned.

get_inventory() {
    local _deployment="$1"
    local _pbr="$2"
    if [[ ! -z "${_deployment}" ]]; then
        if is_fqdn "${_deployment}"; then
            _deployment="$(get_deployment_from_fqdn "${_deployment}")"
        fi
    else
      _deployment="$(get_deployment)"
    fi
    if [[ -d "${GIT}/private-${_deployment}/inventory" ]]; then
        echo "${GIT}/private-${_deployment}/inventory"
    elif [[ -d "${_pbr}/inventory" ]]; then
        echo "${_pbr}/inventory"
    else
        echo "$PBR/inventory"
    fi
    return 0
}

#HELP
#HELP parse_fqdn()
#HELP     Return ${FLAGS_TRUE} or ${FLAGS_FALSE} depending on whether $1 can
#HELP     be parsed into an array from space delimited version of dotted DNS
#HELP     name. The call returns the space separated elements if so.

parse_fqdn() {
    read -a fields <<< $(echo $1 | sed 's/\./ /g')
    if [ ${#fields[@]} -eq 1 ]; then
        echo ""
        return ${FLAGS_FALSE}
    else
        echo "${fields[@]}"
        return ${FLAGS_TRUE}
    fi
}

#HELP
#HELP require_fqdn()
#HELP     Exit if $1 does not appear to be an FQDN.

require_fqdn() {
    if [[ $(parse_fqdn $1) == "" ]]; then
        error_exit 1 "Not recognized as a domain name: \"$1\""
    fi
    true
}

# Internal domain names in DIMS end in .category.deployment.
# Since there may be more than one DNS name component prior to
# these two, indexes need to be adjusted based on the total
# number of fields in the DNS name.

get_deployment_from_fqdn() {
    local fqdn=${1:-$FQDN}
    if [[ -z "$fqdn" ]]; then
        echo ""
        return 1
    fi
    read -a fields <<<$(parse_fqdn $fqdn)
    local dfield=$((${#fields[@]} - 1))
    echo "${fields[$dfield]}"
    return 0
}

get_category_from_fqdn() {
    local fqdn=${1:-$FQDN}
    if [[ -z "$fqdn" ]]; then
        echo ""
        return 1
    fi
    read -a fields <<<$(parse_fqdn $fqdn)
    local cfield=$((${#fields[@]} - 2))
    echo "${fields[$cfield]}"
    return 0
}

get_hostname_from_fqdn() {
    local fqdn=${1:-$FQDN}
    if [[ -z "$fqdn" ]]; then
        echo ""
        return 1
    fi
    read -a fields <<<$(parse_fqdn $fqdn)
    echo "${fields[0]}"
    return 0
}

compose_fqdn() {
    if [[ $# -ne 3 || -z $1 || -z $2 || -z $3 ]]; then
        echo ""
    else
        echo "$1.$2.$3"
    fi
}

# DO NOT EXIT! Sourced file.
