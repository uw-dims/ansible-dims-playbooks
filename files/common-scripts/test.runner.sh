#!/bin/bash
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

TESTDIR=${TESTDIR:-$DIMS/tests.d/}
TESTLEVEL=${TESTLEVEL:-system}

# The 'tput' program doesn't work and play well when TERM
# is not defined. Default to TAP format if not set.
DEFAULTTAP=$([[ -z "$TERM" || $TERM = 'dumb' ]] && echo true || echo false)

# Define command line options
DEFINE_boolean 'debug' false 'enable debug mode' 'd'
DEFINE_string 'exclude' "" 'tests to exclude' 'E'
DEFINE_string 'level' "${TESTLEVEL}" 'test level' 'L'
DEFINE_string 'match' '.*' 'regex to match tests' 'M'
DEFINE_boolean 'list-tests' false 'list available tests' 'l'
DEFINE_boolean 'tap' $DEFAULTTAP 'output tap format' 't'
DEFINE_boolean 'sudo-tests' false 'perform sudo tests' 'S'
DEFINE_boolean 'terse' false 'print only failed tests' 'T'
DEFINE_string 'testdir' "${TESTDIR}" 'test directory' 'D'
DEFINE_boolean 'usage' false 'print usage information' 'u'
DEFINE_boolean 'verbose' false 'be verbose' 'v'

FLAGS_HELP="usage: $BASE [options] args"

# Define functions

usage() {
    flags_help
    cat << EOD

This script provides support for running Bats tests. It supports selection
of tests by test level, through inclusion of tests matching regular
expressions in test names, through exclusion by filtering out tests
matching regular expressions, and by whether the test requires
elevated privileges ("sudo") to work.

    $ test.runner --level system --list-tests
    system/dims-base.bats
    system/pycharm.bats
    system/dns.bats
    system/docker.bats
    system/dims-accounts.bats
    system/dims-ci-utils.bats
    system/deprecated.bats
    system/coreos-prereqs.bats
    system/user/vpn.bats
    system/proxy.bats


    $ test.runner --level "*" --list-tests
    system/dims-base.bats
    system/pycharm.bats
    system/dns.bats
    system/docker.bats
    system/dims-accounts.bats
    system/dims-ci-utils.bats
    system/deprecated.bats
    system/coreos-prereqs.bats
    system/user/vpn.bats
    system/proxy.bats
    unit/dims-filters.bats
    unit/bats-helpers.bats


    $ test.runner --list-tests --sudo-tests
    system/dims-accounts-sudo.bats
    system/iptables-sudo.bats


    $ test.runner --level system --match dims --list-tests
    system/dims-base.bats
    system/dims-accounts.bats
    system/dims-ci-utils.bats


    $ test.runner --level system --match "dims|coreos" --list-tests
    system/dims-base.bats
    system/dims-accounts.bats
    system/dims-ci-utils.bats
    system/coreos-prereqs.bats


    $ test.runner --level system --match "dims|coreos" --exclude "base|utils" --list-tests
    system/dims-accounts.bats
    system/coreos-prereqs.bats


    $ test.runner --match "pycharm|coreos" --tap
    [+] Running test system/pycharm.bats
    1..5
    ok 1 [S][EV] Pycharm is not an installed apt package.
    ok 2 [S][EV] Pycharm Community edition is installed in /opt
    ok 3 [S][EV] "pycharm" is /opt/dims/bin/pycharm
    ok 4 [S][EV] /opt/dims/bin/pycharm is a symbolic link to installed pycharm
    ok 5 [S][EV] Pycharm Community installed version number is 2016.2.2
     . . .


    $ test.runner --match "pycharm|coreos" --terse
    [+] Running test system/pycharm.bats

    5 tests, 0 failures
     . . .


    $ test.runner --match "pycharm|coreos" --tap --terse
    [+] Running test system/pycharm.bats
    1..5
     . . .


Using --verbose enables verbose output in this script.
Using --debug enables debugging output in this script.
Using both --verbose and --debug gives max output.

EOD
    exit 0
}

array_to_string()
{
    # Treat the arguments as an array:
    local -a _array=( "$@" )
    declare -p _array | sed -e 's/^declare -a _array=//'
}

# Return all tests at a given level in the form of a string version of
# an array:
#
#   $ array[0]=one
#   $ array[1]=two
#   $ array[2]=three
#   $ declare -p array
#   declare -a array='([0]="one" [1]="two" [2]="three")'

get_tests_at_level() {
    local _level=$1
    local _exclude=$2
    local _results=()
    local _i
    [[ -z "${_level}" ]] && return 1
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
    done < <(cd ${FLAGS_testdir} &&
        find ${_level} -name '*.bats' | sed 's/\.bats$//')
    debug "$(array_to_string ${_results[@]})"
    array_to_string ${_results[@]}
}


# Print out all tests passed in $@
list_tests() {
    local _test
    local _results=()
    for _test in $@; do
        # Don't list tests with 'sudo' in the name unless --sudo
        if [[ ${FLAGS_sudo_tests} -eq ${FLAGS_TRUE} ]] ; then
            if ! echo "${_test}" | grep -q "sudo"; then
                continue
            fi
        else
            if echo "${_test}" | grep -q "sudo"; then
                continue
            fi
        fi
        _results=( "${_results[@]}" "${_test}" )
    done
    (for _test in ${_results[@]}; do echo ${_test}; done) | sort
}

run_tests_pretty() {
    local _test
    local _failures=0
	if [[ ${FLAGS_terse} -eq ${FLAGS_TRUE} ]]; then
        FILTER="grep -v '1G [^ ]'"
    else
        FILTER="cat"
    fi
    for _test in $@; do
        if [[ ${FLAGS_sudo_tests} -eq ${FLAGS_TRUE} ]]; then
            # Only run tests with "sudo" in the name
            if echo "${_test}" | grep -q "sudo"; then
                echo "[+] Running test ${_test} as root"
                eval "(sudo bats --pretty ${_test}.bats; echo \$? > $RETVAL) | $FILTER"
                echo "" # Add a blank line to help with multi-test --terse readability
                let _failures+=$(($(cat $RETVAL)))
            fi
        else
            # Only run tests without "sudo" in the name
            if ! echo "${_test}" | grep -q "sudo"; then
                echo "[+] Running test ${_test}"
                eval "(bats --pretty ${_test}.bats; echo \$? > $RETVAL) | $FILTER"
                echo "" # Add a blank line to help with multi-test --terse readability
                let _failures+=$(($(cat $RETVAL)))
            fi
        fi
    done
    return $_failures
}

# Run each test with bats
run_tests_tap() {
    local _test
    local _failures=0
	if [[ ${FLAGS_terse} -eq ${FLAGS_TRUE} ]]; then
        FILTER="egrep -v '^ok'"
    else
        FILTER="cat"
    fi
    for _test in $@; do
        if [[ ${FLAGS_sudo_tests} -eq ${FLAGS_TRUE} ]]; then
            # Only run tests with "sudo" in the name
            if echo "${_test}" | grep -q "sudo"; then
                echo "# [+] Running test ${_test} as root"
                eval "(sudo bats --tap ${_test}.bats; echo \$? > $RETVAL) | $FILTER"
                echo "#" # Add a blank line to help with multi-test --terse readability
                let _failures+=$(($(cat $RETVAL)))
            fi
        else
            # Only run tests without "sudo" in the name
            if ! echo "${_test}" | grep -q "sudo"; then
                echo "# [+] Running test ${_test}"
                eval "(bats --tap ${_test}.bats; echo \$? > $RETVAL) | $FILTER"
                echo "#" # Add a blank line to help with multi-test --terse readability
                let _failures+=$(($(cat $RETVAL)))
            fi
        fi
    done
    return $_failures
}



# Print out all tests with names matching $@ except
# those excluded by --exclude option
list_all_tests() {
    local _levels="$@"
    local _results=()
    local _level
    for _level in ${_levels}; do
        eval declare -a _results=$(get_tests_at_level "${_level}" "${FLAGS_exclude}")
        [ ${#_results[@]} -gt 0 ] || continue
        verbose "${_level}"
        list_tests ${_results[@]}
    done
}

main()
{
    dims_main_init

    # Get a temporary file to store exit code from bats to pass along failures
    # to caller of this script.
    RETVAL=$(get_temp_file)
    add_on_exit rm -f $RETVAL

    [[ -d ${FLAGS_testdir} ]] || error_exit 1 "Test directory \"${FLAGS_testdir}\" does not exist"
    debug "cd ${FLAGS_testdir}"
    cd ${FLAGS_testdir}

    # Were tests explicitly given on the command line, or is this an
    # attempt to run a suite of tests (minus exclusions, or with
    # a specific subset of tests?)
    if [ ! -z "$@" ]; then
        TESTS=$@
    else
        # Identify tests by level (with exclusions)
        eval declare -a results=$(get_tests_at_level "${FLAGS_level}" "${FLAGS_exclude}")
        TESTS="${results[@]}"
    fi
    debug "TESTS=${TESTS}"

    if [[ $FLAGS_list_tests -eq ${FLAGS_TRUE} ]]; then
        list_tests ${TESTS}
    else
        if [[ ${FLAGS_tap} -eq ${FLAGS_TRUE} ]]; then
            run_tests_tap ${TESTS}
            RESULTS=$?
        else
            run_tests_pretty ${TESTS}
            RESULTS=$?
        fi
    fi
 
    debug "Returning from main()"
    on_exit
    return $RESULTS
}


# parse the command-line
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"
main "$@"
exit $?
