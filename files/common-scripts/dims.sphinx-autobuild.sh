#!/bin/bash
#
# vim: set ts=4 sw=4 tw=0 et :
#
# Copyright (c) 2014-2017, University of Washington. All rights reserved.
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

# Ignore all the files created by "make latexpdf" in case that is invoked
# as a documentation test prior to committing to Git at the same time a
# sphinx-autobuild is active.

. $DIMS/lib/shflags
. $DIMS/bin/dims_functions.sh

# DOCLSURL is a Python format string.
export DOCSURL=${DOCSURL:-file://${GIT}}

# Tracks with bumpversion
DIMS_VERSION=2.6.6

DEFINE_boolean 'debug' false 'enable debug mode' 'd'
DEFINE_integer 'delay' 5 'browser open delay' 'D'
DEFINE_boolean 'openbrowser' true 'open browser window' 'b'
DEFINE_integer 'port' 0 'HTTP listen port' 'p'
DEFINE_boolean 'touchfiles' false 'update timestamps first' 't'
DEFINE_boolean 'usage' false 'show usage information' 'u'
DEFINE_boolean 'verbose' false 'be verbose' 'v'
DEFINE_boolean 'version' false 'print version number and exit' 'V'

FLAGS_HELP="usage: $BASE [options] args"

# Define functions

usage() {
    flags_help
    cat << EOD

This script is intended to facilitate editing Sphinx documentation by running
a Sphinx autobuild session for a Git repository. It makes some attempt to find
the Sphinx docs directory and running sphinx-autobuild from there. (Note that
this assumes the directory structure \$REPOBASE/docs/source for the location
where a Sphinx conf.py file should be found.)

EOD
    exit 0
}

find_docsbase() {
    if [ -f source/conf.py ]; then
        # We already appear to be in a Sphinx docs/ directory.
        echo .
    elif [ -f ../docs/source/conf.py ]; then
        # We appear to be in another directory parallel to a Sphinx docs/ directory.
        echo ../docs
    fi
    # Are we elsewhere in a Git repo that has a Sphinx docs/ directory?
    _repobase=$(git rev-parse --show-toplevel 2>/dev/null)
    debug "_repobase=${_repobase}"
    if [[ ! -z $_{repobase} ]]; then
        if [[ -f ${_repobase}/docs/source/conf.py ]]; then
            echo "${_repobase}/docs"
        fi
    fi
    # I give up.
    echo ""
}

main()
{
    dims_main_init

    open_browser=""
    [[ $FLAGS_openbrowser -eq ${FLAGS_TRUE} ]] && open_browser="--open-browser"

    docsbase=$(find_docsbase)
    [[ -z $docsbase ]] && $ERROR_EXIT 1 "Can\'t find a Sphinx docs/ directory"
    cd $docsbase

    # Clean out any cached content before starting.
    make clean 2>/dev/null

    # Background a trigger for initial build of all files.
    if [[ ${FLAGS_touchfiles} -eq ${FLAGS_TRUE} ]]; then
        (sleep 3 && touch source/*.rst) &
    fi

    sphinx-autobuild -q \
        -p ${FLAGS_port} \
        $open_browser \
        --delay ${FLAGS_delay} \
        --ignore "*.swp" \
        --ignore "*.pdf" \
        --ignore "*.log" \
        --ignore "*.out" \
        --ignore "*.toc" \
        --ignore "*.aux" \
        --ignore "*.idx" \
        --ignore "*.ind" \
        --ignore "*.ilg" \
        --ignore "*.tex" \
        source \
        build/html
    exit 0
}

# parse the command-line
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"
main "$@"
