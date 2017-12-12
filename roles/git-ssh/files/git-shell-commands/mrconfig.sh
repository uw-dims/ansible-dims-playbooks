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

# Source shflags
. $DIMS/lib/shflags
. $DIMS/bin/dims_functions.sh


# This Git shell script produces an .mrconfig file for all repos
# specified on the command line, or all bare repos in $GITDIR.

# Tracks with bumpversion
VERSION=2.14.0

export FQDN=$(get_fqdn)
DEPLOYMENT=${DEPLOYMENT:-$(get_deployment_from_fqdn)}
CATEGORY=${CATEGORY:-$(get_category_from_fqdn)}
GITDIR=${GITDIR:-/opt/git}
GITHOST=${GITHOST:-source.${CATEGORY}.${DEPLOYMENT}}

FLAGS_HELP="usage: $BASE [options] args"

# Define command line options
DEFINE_string  'category'     "${CATEGORY}"     'category identifier'      'C'
DEFINE_boolean 'debug'        false             'enable debug mode'        'd'
DEFINE_string  'deployment'   "${DEPLOYMENT}"   'deployment identifier'    'D'
DEFINE_string  'githost'      "${GITHOST}"      'repostories host'         'H'
DEFINE_string  'reposdir'     "${GITDIR}"       'repostories directory'    'R'
DEFINE_boolean 'usage'        false             'print usage information'  'u'
DEFINE_boolean 'verbose'      false             'be verbose'               'v'
DEFINE_boolean 'version'      false             'print version and exit'   'V'

# Define functions

usage() {
    flags_help
    cat << EOD

This script is intended to facilitate tracking repositories
using 'mr'. It is designed to be run as a Git shell command.

usage: ssh git@${GITHOST} mrconfig [ repo1 [ ... repon ] ]

EOD
    exit 0
}

print_if_bare_repo='
	if "$(git --git-dir="$1" rev-parse --is-bare-repository)" = true
	then
		printf "%s\n" "${1#./}"
	fi
'

# Print out an mrconfig line containing information derived from
print_mr_config() {
    local reponame
    local repourl
    # Strip off any .git extension
    reponame="$(basename $1 .git)"
    if [[ ! -z "$2" ]]; then
        if [[ $2 =~ :// ]]; then
            repourl="$2"
        else
            error_exit 1 "The string \"$2\" does not appear to be a URL"
        fi
    else
        repourl="git@${GITHOST}:${GITDIR}/$1.git"
    fi
	cat << EOD
[git/${reponame}]
checkout = git clone '${repourl}' '${reponame}' &&
	(cd ${reponame}; git hf init)
show = git remote show origin
update = git hf update
pull = git hf update &&
	git hf pull
stat = git status -s

EOD
}

get_repos() {
    # Find all Git repo directories, then
    # Find all Git repo references. Sort the results.
    (find * \
        -type d \
        -name "*.git" \
        -exec bash -c "$print_if_bare_repo" -- {} \; \
        -prune 2>/dev/null; \
    find * \
        -type f \
        -name "*.git" \
        -print \
        -prune 2>/dev/null) | sort
}


main()
{
    # Just exit if all we were asked for was help.
    [[ ${FLAGS_help} -eq ${FLAGS_TRUE} ]] && exit 0
    [[ ${FLAGS_usage} -eq ${FLAGS_TRUE} ]] && usage
    if [[ ${FLAGS_version} -eq ${FLAGS_TRUE} ]]; then
        echo "$PROGRAM $VERSION"
        exit 0
    fi

    debug 'Debug mode enabled'
    [[ $FLAGS_debug -eq ${FLAGS_TRUE} && $FLAGS_verbose -eq ${FLAGS_TRUE} ]] && set -x

    cd ${FLAGS_reposdir} || error_exit 1 "Cannot change directory to ${FLAGS_reposdir}"

    # If any arguments are given, produce output for just them, otherwise, use all available repos.
    if [ $# -gt 0 ]; then
        REPOS=$@
    else
        REPOS=$(get_repos)
    fi

    for repo in $REPOS; do
        # Make sure repo names end in .git only when necessary.
        repo=$(basename $repo .git)
        debug "repo=$repo"
        if [[ -d ${repo}.git ]]; then
            print_mr_config $repo
        elif [[ -f ${repo}.git ]]; then
            debug "cat ${repo}.git => $(cat ${repo}.git)"
            print_mr_config $repo $(cat ${repo}.git)
        else
            error_exit 1 "Unrecognized file type (must be file containing Git repo URL or directory)"
        fi
    done

    debug "Returning from main()"
    on_exit
    return $?
}


# parse the command-line
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"
main "$@"
exit $?
