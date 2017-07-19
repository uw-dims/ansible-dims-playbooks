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

# Source shflags
. $DIMS/lib/shflags

if [[ -f ./dims_functions.sh ]]; then
    . ./dims_functions.sh
else
    . $DIMS/bin/dims_functions.sh
fi

# Tracks with bumpversion
DIMS_VERSION=2.6.6

# Define command line options
DEFINE_boolean 'debug' false 'enable debug mode' 'd'
DEFINE_boolean 'show-help' false 'show help text' 'H'
DEFINE_boolean 'usage' false 'print usage information' 'u'
DEFINE_boolean 'verbose' false 'be verbose' 'v'

ANSIBLE_OPTIONS="${ANSIBLE_OPTIONS}"
FLAGS_HELP="usage: $BASE [options] args"

# Define functions

usage() {
    flags_help
    cat << EOD

This script is a simple wrapper for the dims_functions.sh library.

Call with arguments just as if you were doing so using functions
in the dims_functions.sh library. The following are equivalent:

    In a script:

        echo \$(get_vagrant_run_dir red.devops.local)
        /vm/run/red

    From command line:

        $ dims.function get_vagrant_run_dir red.devops.local
        /vm/run/red

To do recursive expansion of inline expressions (i.e., '\$(x)'),
be sure to "take away the magic" from characters that your
command line shell might try to interpret prior to passing
them to this script.

$ dims.function  'get_vagrant_status_by_id \$(get_vagrant_id red.devops.local)'
running

When the --debug flag is used, the script will attempt to load
dims_functions.sh from the current working directory. This allows
easier development and testing of the functions in this file.
If no file named "dims_functions.sh" exists in the CWD, the
system installed version is sourced instead.

Using the --show-help flag will extract the help text to
make it easier to determine the function names and/or how
they work.

To debug the dims_functions.sh library, you can enable tracing
as in other DIMS programs by using --verbose and --debug at the
same time.
EOD
    exit 0
}

main()
{
    dims_main_init

    # Default is use the system installed version
    function_file="$DIMS/bin/dims_functions.sh"

    if [[ $FLAGS_debug -eq ${FLAGS_TRUE} ]]; then
        if [[ ! -f ./dims_functions.sh ]]; then
            echo "[!] Could not find \"dims_functions.sh\" in the current working directory"
            . $DIMS/bin/dims_functions.sh
        else
            function_file="./dims_functions.sh"
        fi
    else
        . $DIMS/bin/dims_functions.sh
    fi

    if [[ ${FLAGS_show_help} -eq ${FLAGS_TRUE} ]]; then
        get_help_text $function_file
        exit 0
    fi

    . $function_file
    verbose "Sourced $function_file"
    eval $@
    return $?
}

# parse the command-line
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"
main "$@"
exit $?
