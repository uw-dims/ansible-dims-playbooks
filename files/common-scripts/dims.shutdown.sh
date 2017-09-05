#!/bin/bash
#
# vim: set ts=4 sw=4 tw=0 et :
#
# Copyright (C) 2014-2017, University of Washington. All rights reserved.
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

. $DIMS/lib/shflags
. $DIMS/bin/dims_functions.sh

# Tracks with bumpversion
DIMS_VERSION=2.12.0

# This script is designed to handle shutting down Vagrants before
# the VM host, so DEPLOYMENT here applies to the Vagrants.
DEPLOYMENT=${DIMS_VAGRANT_DEPLOYMENT:-$(get_deployment)}
CATEGORY=${DIMS_CATEGORY:-devops}
INVENTORY=${INVENTORY:-$(get_inventory $DEPLOYMENT)}
GROUP=${GROUP:-vagrants}
FLAGS_HELP="usage: $BASE [options] [TIME]"
DEFAULT_TIME="+3"

DEFINE_boolean 'cancel' false 'cancel shutdown' 'c'
DEFINE_boolean 'debug' false 'enable debug mode' 'd'
DEFINE_string 'group' "${GROUP}" 'inventory group' 'G'
DEFINE_string 'inventory' "${INVENTORY}" 'inventory file' 'i'
DEFINE_boolean 'reboot' false 'reboot instead of shutdown' 'r'
DEFINE_boolean 'resume' false 'resume vagrants in group' 'R'
DEFINE_boolean 'usage' false 'print usage information' 'u'
DEFINE_boolean 'only-vagrants' false 'only act on vagrants, not host' 'O'
DEFINE_boolean 'version' false 'print version number and exit' 'V'
DEFINE_boolean 'verbose' false 'be verbose' 'v'

# Define functions

usage() {
    flags_help
    cat <<EOD

This script is intended to help shut down a DIMS development
or service host. Developer laptops have had problems with an
NFS mounted file system used over a VPN to not unmount
properly, causing laptops to not actually shut down when you
need them to. Also, a hard and immediate shutdown while
Virtualbox vagrants are running leaves them in the "aborted"
state and is tedious to restart them. This script uses
functions in dims_functions.sh to suspend and resume
vagrants.

The default timeout grace period, if none is specified on
the command line, is ${DEFAULT_TIME}.

To use another time, do something like:

    \$ $BASE +3      # in 3 minutes
    \$ $BASE 20:30   # at 8:30PM
    \$ $BASE now     # exactly 24 hours after this time yesterday

A shutdown operation can be cancelled. Say you request a
shutdown in 30 minutes:

    \$ $BASE +30
    ==> default: Saving VM state and suspending execution...
    ==> default: Saving VM state and suspending execution...
    ==> default: Saving VM state and suspending execution...
    ==> default: Saving VM state and suspending execution...
    ==> default: Saving VM state and suspending execution...

    Broadcast message from dittrich@dimsdemo1
            (/dev/pts/28) at 19:06 ...

    The system is going down for power off in 30 minutes!

All terminals will receive the broadcast message about the
shutdown.  The shutdown program runs in the foreground, so
the shell in which the command was run will appear to "hang"
right after the message as seen here.

If you wish to cancel a scheduled shutdown, use the
-c/--cancel option.  In another shell, run:

    \$ $BASE --cancel

You will see the confirmation of the cancellation in the
initial window, as well as the terminal in which you did the
cancellation.

     . . .
     The system is going down for power off in 30 minutes!
     shutdown: Shutdown cancelled

(Advanced user will know you can suspend the initial shell
with CTRL-Z, then cancel and refresh terminal windows to get
rid of the broadcast message.)

Add the -r/--reboot option to reboot instead of shutting
down (the default).

Add the -v/--verbose option to see more details about what
is happening.

    \$ $BASE --only-vagrants --group coreos -v
    [+] dims.function vagrant_desired_state core-01.devops.local saved
    ==> default: Saving VM state and suspending execution...
    [+] dims.function vagrant_desired_state core-02.devops.local saved
    ==> default: Saving VM state and suspending execution...
    [+] dims.function vagrant_desired_state core-03.devops.local saved
    ==> default: Saving VM state and suspending execution...

If you want to only suspend the vagrants without shutting
down the host, use the --only-vagrants option. Use --group
to select a specific sub-group (default is "$GROUP").

    \$ $BASE --only-vagrants --group coreos

To resume the suspended vagrants, use the --resume option:

    \$ $BASE --resume --group coreos -v
    [+] dims.function vagrant_desired_state core-01.devops.local running
    Bringing machine 'default' up with 'virtualbox' provider...
    ==> default: Resuming suspended VM...
    ==> default: Booting VM...
    ==> default: Waiting for machine to boot. This may take a few minutes...
        default: SSH address: 127.0.0.1:2222
        default: SSH username: core
        default: SSH auth method: private key
    ==> default: Machine booted and ready!
    . . .
    ==> default: Command execution finished.
    [+] Resumed all vagrants in group "coreos"

This is useful for suspending and resuming just the vagrants
without having to actually shut down the entire laptop or
server.

EOD
    exit 0
}

function suspend_vagrants() {
    local _node
    for _node in $(test.vagrant.list --inventory ${FLAGS_inventory} --group ${FLAGS_group}); do
        verbose dims.function vagrant_desired_state $_node saved;
        dims.function vagrant_desired_state $_node saved;
    done
}

function resume_vagrants() {
    local _node
    for _node in $(test.vagrant.list --inventory ${FLAGS_inventory} --group ${FLAGS_group}); do
        verbose dims.function vagrant_desired_state $_node running;
        dims.function vagrant_desired_state $_node running;
    done
}

function is_mounted_nas() {
    mount | grep -q "$NAS"
}

function validate_when() {
    echo "$1" |
        egrep -q "+[0-9]+|now|[0-9][0-9]:[0-9][0-9]"
}

main()
{
    dims_main_init

    WHEN=${1:-+3}

    # Are you having second thoughts about something?
    # "Should I stay or should I go now?"
    #                        Joe Strummer
    if [[ ${FLAGS_cancel} -eq ${FLAGS_TRUE} ]]; then
        sudo /sbin/shutdown -c ||
            error_exit $? "Failed to cancel shutdown (might not be a bad thing)"
        exit 0
    fi

    # Are we resuming suspended vagrants after last shutdown/reboot?
    if [[ ${FLAGS_resume} -eq ${FLAGS_TRUE} ]]; then
        resume_vagrants ||
            error_exit $? "Problems encountered resuming vagrants in group \"${FLAGS_group}\""
        verbose "Resumed all vagrants in group \"${FLAGS_group}\""
        exit 0
    fi

    # We're actually going to take things down.

    if [[ ${FLAGS_only_vagrants} -eq ${FLAGS_true} ]]; then
        suspend_vagrants ||
            error_exit $? "Problems encountered resuming vagrants"
        exit 0
    else
        suspend_vagrants ||
            say "Problems encountered resuming vagrants: continuing with host shutdown"
    fi

    validate_when "$WHEN" ||
        error_exit 1 "The value \"$WHEN\" is not a valid time delay for 'shutdown'"

    if is_mounted_nas; then
        dims.nas.umount ||
            error_exit $? "Failed to unmount NAS"
        verbose "Unmounted NAS"
    fi

    if [[ ${FLAGS_reboot} -eq ${FLAGS_TRUE} ]]; then
        sudo /sbin/shutdown -r $WHEN
    else
        sudo /sbin/shutdown -P $WHEN
    fi
}

# parse the command-line
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"
main "$@"
exit $?
