#!/usr/bin/env /bin/bash
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

# Author: Dave Dittrich <dittrich@u.washington.edu>

# Source shflags
. $DIMS/lib/shflags
. $DIMS/bin/dims_functions.sh

# Tracks with bumpversion
DIMS_VERSION=2.6.1

TRIGGERDIR=${TRIGGERDIR:-$DIMS/triggers.d}
TRIGGERSTATE=${TRIGGERSTATE:-''}

# Define command line options
DEFINE_boolean 'debug'          false             'enable debug mode'        'd'
DEFINE_string  'exclude'        ""                'triggers to exclude'      'E'
DEFINE_string  'state'          "${TRIGGERSTATE}" 'trigger state'            'T'
DEFINE_string  'match'          '.*'              'regex to match triggers'  'M'
DEFINE_boolean 'list-triggers'  false             'list available triggers'  'l'
DEFINE_boolean 'sudo-triggers'  false             'perform sudo triggers'    'S'
DEFINE_string  'triggerdir'     "${TRIGGERDIR}"   'trigger directory'        'D'
DEFINE_boolean 'usage'          false             'print usage information'  'u'
DEFINE_boolean 'verbose'        false             'be verbose'               'v'
DEFINE_boolean 'version'        false             'print version and exit'   'V'

FLAGS_HELP="usage: $BASE [options] args"

# Define functions

usage() {
    flags_help
    cat << EOD

This script provides support for running scripts against Vagrant VMs
at different "trigger" states via a plugin called "vagrant-triggers".
These "triggers" allow arbitrary scripts to be run either before or
after different Vagrant commands that coincide with states a VM may
exist in, including but not limited to:
    - up (on)
    - provision
    - halt (off)
    - destroy 

The Vagrantfile controls these triggers with directives as follows:

  config.trigger.before :command, :option => "value" do
    run "script"
    ...
  end

  config.trigger.after :command, :option => "value" do
    run "script"
    ...
  end

For example we have added the following to our Vagrantfiles:

  config.trigger.after [:up], :stdout => true do
    run "vagrant ssh -c 'sudo /vagrant/trigger.runner --state after-up"
  end

  config.trigger.after [:provision], :stdout => true do
    run "vagrant ssh -c 'sudo /vagrant/trigger.runner --state after-provision'"
  end

When specifying a state, all scripts for that particular state will be
executed.  Lower-level scripts are stored in the /opt/dims/triggers.d/
directory. Prepending numeric values to the scripts assists in
prioritizing their execution as file names are sorted at run time.

  $ tree /opt/dims/triggers.d
  ├── after-provision
  │   └── 00-network-capture.sh
  └── after-up
      ├── 00-create-network-interfaces.sh
      └── 10-network-capture.sh

The value specified with the --state option supports wild card
pattern matching, allowing multiple states to be selected for
operations like --list-triggers.

  $ trigger.runner --state after-up --list-triggers
  after-up/00-create-network-interfaces.sh
  after-up/network-debug.sh
 
  $ trigger.runner --state "*" --list-triggers
  after-destroy/network-debug.sh
  after-halt/network-debug.sh
  after-provision/network-debug.sh
  after-up/00-create-network-interfaces.sh
  after-up/network-debug.sh
  before-destroy/network-debug.sh
  before-halt/network-debug.sh
  before-provision/network-debug.sh
  before-up/network-debug.sh
  network-debug.sh

The --match and --exclude options allow inclusion or exclusion
of triggers by name.

  $ trigger.runner --state after-up --match "create" --list-triggers
  after-up/00-create-network-interfaces.sh

  $ trigger.runner --state after-up --exclude "create" --list-triggers
  after-up/network-debug.sh

  $ trigger.runner --state "*" --exclude "after-provision" --list-triggers
  after-up/00-create-network-interfaces.sh
  after-up/network-debug.sh
  network-debug.sh

  $ trigger.runner --state after-provision

Using --verbose enables verbose output in this script.
Using --debug enables debugging output in this script.
Using both --verbose and --debug gives max output.

NOTE: Some scripts are for debug-use only. To "activate" those, the debug
flag must be sent to this script ($BASE) so the debug flag can
be propogated to the scripts run by this script and the higher-level
scripts.

  $ trigger.runner --state after-provision --debug --verbose

EOD
    exit 0
}

array_to_string()
{
    # Treat the arguments as an array:
    local -a _array=( "$@" )
    declare -p _array | sed -e 's/^declare -a _array=//'
}

# Return all triggers at a given state in the form of a string version of
# an array:
#
#   $ array[0]=one
#   $ array[1]=two
#   $ array[2]=three
#   $ declare -p array
#   declare -a array='([0]="one" [1]="two" [2]="three")'

get_triggers_for_state() {
    local _state=$1
    local _exclude=$2
    local _results=()
    local _i
    [[ -z "${_state}" ]] && return 1
    while read _i; do
        # If an exlusion set exists, and ${_i} is not in exclusion set,
        # then add it to the results.
        if [ ! -z "${_exclude}" ]; then
            if echo "${_i}" | egrep -q "${_exclude}"; then
                debug "excluding ${_i}"
                continue
            fi
        fi
        # Now check to see if name matches
        if ! echo "${_i}" | egrep -q "${FLAGS_match}"; then
            continue
        fi
        debug "adding ${_i}"
        _results=( "${_results[@]}" "${_i}" )
    done < <(cd ${FLAGS_triggerdir} &&
        [[ -d ${_state} ]] &&
        find ${_state} -name '*.sh')
    debug "$(array_to_string ${_results[@]})"
    array_to_string ${_results[@]}
}


# Print out all triggers passed in $@
list_triggers () {
    local _trigger
    local _results=()
    for _trigger in $@; do
        # Don't list triggers with 'sudo' in the name unless --sudo
        if [[ ${FLAGS_sudo_triggers} -eq ${FLAGS_TRUE} ]] ; then
            if ! echo "${_trigger}" | grep -q "sudo"; then
                continue
            fi
        else
            if echo "${_trigger}" | grep -q "sudo"; then
                continue
            fi
        fi
        _results=( "${_results[@]}" "${_trigger}" )
    done
    (for _trigger in ${_results[@]}; do echo ${_trigger}; done) | sort
}


# Print out all triggers with names matching $@ except
# those excluded by --exclude option
list_all_triggers () {
    local _states="$@"
    local _results=()
    local _state
    for _state in ${_states}; do
        eval declare -a _results=$(get_triggers_for_state "${_state}" "${FLAGS_exclude}")
        [ ${#_results[@]} -gt 0 ] || continue
        verbose "${_state}"
        list_triggers ${_results[@]}
    done
}

# 
run_triggers () {
    local _trigger
    local _failures=0

    # Build a string with space-separated flags (if necessary) to pass to sub-commands.
    local _flags=""
    [[ ${FLAGS_debug} -eq ${FLAGS_true} ]] && _flags=" --debug"
    [[ ${FLAGS_verbose} -eq ${FLAGS_true} ]] && _flags=" --verbose"

    # Run all triggers, making note if any one of them fails.
    for _trigger in $@; do
        verbose ""
        verbose "Running trigger ${FLAGS_triggerdir}/${_trigger} $_flags"
        bash ${FLAGS_triggerdir}/${_trigger} $_flags
        let _failures+=$(($?))
    done
    verbose ""
    return $_failures
}

main()
{
    dims_main_init

    # Default return value.
    _results=0

    debug 'debug mode enabled'
    [[ $FLAGS_debug -eq ${FLAGS_TRUE} && $FLAGS_verbose -eq ${FLAGS_TRUE} ]] && set -x

    # Get a temporary file to store exit code from scripts to pass along failures
    # to caller of this script.
    RETVAL=$(get_temp_file)
    add_on_exit rm -f $RETVAL

    [[ -d ${FLAGS_triggerdir} ]] || error_exit 1 "Trigger directory \"${FLAGS_triggerdir}\" does not exist"
    debug "cd ${FLAGS_triggerdir}"
    cd ${FLAGS_triggerdir}

    # Were triggers explicitly given on the command line, or is this an
    # attempt to run a suite of triggers (minus exclusions, or with
    # a specific subset of triggers?)
    if [ ! -z "$@" ]; then
        TRIGGERS=$@
    else
        # Identify triggers by state (with exclusions)
        eval declare -a results=$(get_triggers_for_state "${FLAGS_state}" "${FLAGS_exclude}")
        TRIGGERS="${results[@]}"
    fi
    debug "TRIGGERS=${TRIGGERS}"

    if [[ $FLAGS_list_triggers -eq ${FLAGS_TRUE} ]]; then
        list_triggers ${TRIGGERS}
    else
        run_triggers ${TRIGGERS}
        _results=$?
    fi
 
    debug "Returning from main()"
    on_exit
    return $_results
}


# parse the command-line
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"
main "$@"
exit $?
