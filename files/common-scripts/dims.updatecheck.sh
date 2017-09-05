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

FLAGS_HELP="usage: $BASE [options]"

DEFINE_boolean 'debug' false 'enable debug mode' 'd'
DEFINE_boolean 'usage' false 'print usage information' 'u'
DEFINE_string 'mailto' "root" 'email recipient for report' 't'
DEFINE_boolean 'version' false 'print version number and exit' 'V'
DEFINE_boolean 'verbose' false 'be verbose' 'v'

# Define functions

usage() {
    flags_help
    cat <<EOD

This script is designed to check for package updates and/or required
reboot status using the DIMS bats tests "system/updates" and
"system/reboot". If either test fails, the output is mailed to
the system administrator. This script is designed to be run
from a cron job or systemd timer.

EOD
    exit 0
}

main()
{
    dims_main_init

    local _now=$(iso8601date)
    local _hostname="$(hostname).$(domainname)"
    local _tmpout=$(get_temp_file)
    add_on_exit rm -f ${_tmpout}

    if ! test.runner --tap --match "updates|reboot" > ${_tmpout}; then
        cat << EOD | mail -s "$BASE results from ${_hostname} (${_now})" ${FLAGS_mailto}
-----------------------------------------------------------------------

Host: ${_hostname}
Date: ${_now}

This is a report of available package updates and/or required reboot
status.  The output of the bats tests that were run is included below.

If package updates are necessary, this can be accomplished by running
the Ansible playbook for ${_hostname} with the following options:

   --tags updates -e packages_update=true

If a reboot is necessary, ensure that the reboot is handled in
a controlled manner:

  o Ensure that all users of external services are aware of any
    potential outage of services provided by this host (or its
    (VMs). Keep in mind that the disruption may occur to system
    that are not being rebooted, but rely on services on those
    that are being rebooted.

  o Halt or suspend any VMs if this is a VM host (and be prepared
    to ensure they are restart after rebooting is complete.)
    (Use the "dims.shutdown" script to facilitate this. See
    documentation and/or "dims.shutdown --usage".)

  o Notify any active users to ensure no active development work
    is lost.

-----------------------------------------------------------------------
test.runner --tap --match "updates|reboot"

$(cat ${_tmpout})

-----------------------------------------------------------------------
EOD
        return $?
    fi
    return 0
}

# parse the command-line
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"
main "$@"
exit $?
