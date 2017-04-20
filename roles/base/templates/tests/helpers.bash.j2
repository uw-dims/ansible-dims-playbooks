#!/bin/bash

# {{ ansible_managed }} [ansible-playbooks v{{ ansibleplaybooks_version }}]

# vim: set ts=4 sw=4 tw=0 et :

# This function comes from https://github.com/jenkinsci/docker
# Assert that $1 is the output of a command (remainder of argv)
function assert() {
    local expected_output="$1"
    shift
    local actual_output
    actual_output="$("$@")"
    actual_output="${actual_output//[$'\t\r\n']}" # remove tabs, line ends
    if [[ "$actual_output" != "$expected_output" ]]; then
        echo "expected: \"$expected_output\""
        echo "actual:   \"$actual_output\""
        false
    fi
}

# Validate a file contents by SHA256 hash.
function assert_sha256() {
    [[ ! -z "$1" ]]
    [[ -f $2 ]]
    assert "$1  $2" sha256sum $2
}


# Make a dig query and return whether an IN records were
# returned by looking for tab separated IN lines with values
function dig_returns_A_records() {
    local query=$@
    dig $query | egrep "[[:blank:]]IN[[:blank:]]A[[:blank:]][0-9].*"
    return $?
}

# Return status of given NIC
function is_nic_up() {
    local nic=$1
    local status=$(ifconfig $nic 2>/dev/null)
    (echo "$status" | egrep -q "UP") && (echo $status | egrep -q "RUNNING")
}

# Return IP address currently in use by a given NIC.
function ip_of_nic() {
    local nic=$1
    ifconfig $nic 2>/dev/null |
        tail -n +2 |
        head -n 1 |
        grep "inet" |
        sed 's/addr://' |
        awk '{ print $2; }'
}

# Is the package named by $1 included in the list of installed
# packages? This is an exact test (i.e., package name must
# *exactly* be the string), not be a substring in some
# other related package like a development library.)

function is_installed_package() {
    local lookfor="$1"
    dpkg -l |
        egrep '^ii' |
        awk '{print $2;}' |
        egrep -q "^${lookfor}\$"
}


# Difference two files to determine if they are the same or not,
# providing the differences if they exist.
function assert_files_identical() {
    local f1=$1
    local f2=$2
    if [[ ! -f $f1 ]]; then
        echo "File $f1 does not exist" >&2
        false
    elif [[ ! -f $f2 ]]; then
        echo "File $f2 does not exist" >&2
        false
    else
        local lw=130
        local l_title="$(center $lw "<<< $f1"     | sed 's/  *$//')"
        local r_title="$(center $lw "    $f2 >>>" | sed 's/  *$//')"
        echo "${l_title}" >&2
        echo "${r_title}" >&2
        echo "" >&2
        diff --suppress-common-lines \
             --side-by-side \
             --expand-tabs \
             --width $lw \
             $f1 $f2 >&2
    fi
}

# Center within a line of width $1 text given as $2.
# This assumes you know the length of $2 is less than
# $1, and that $1 is > 2.
function center() {
    local width=$(($1-2))
    local text=$2
    {%- raw %}
    echo ${text} | sed -e :a -e 's/^.\{1,'${width}'\}$/ & /;ta'
    {% endraw %}
}


# Validate the ownerships (user:group) of a file specified by $1
function assert_ownerships() {
    [ ! -z "$1" ]
    [ ! -z "$2" -a -f "$2" ]
    assert "$1" stat --printf "%U:%G" "$2"
}

# Validate the permissions of a file
#
# assert_permissions_octal 777 /path/to/file
#
function assert_permissions_octal() {
    [ ! -z "$1" ]
    [ ! -z "$2" -a -f "$2" ]
    assert "$1" stat --printf "%a" "$2"
}

# Validate the permissions of a file
#
# assert_permissions_human -rwxrwxrwx /path/to/file
#
function assert_permissions_human() {
    [ ! -z "$1" ]
    [ ! -z "$2" -a -f "$2" ]
    assert "$1" stat --printf "%A" "$2"
}

#HELP
#HELP is_coreos()
#HELP     Return Bash true (0) if running on CoreOS, otherwise false (1).

function is_coreos() {
    [[ "coreos" == "$(uname -r | awk -F- '{ print $2; }')" ]]
}
