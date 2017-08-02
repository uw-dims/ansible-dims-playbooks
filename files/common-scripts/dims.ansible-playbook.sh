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

# WARNING: Tight coupling of this value with ansible-server role
# (config file, etc.)
FACTSD="/opt/dims/data/facts.d"

# Tracks with bumpversion
DIMS_VERSION=2.7.1

DEPLOYMENT=${DIMS_DEPLOYMENT:-$(get_deployment)}
CATEGORY=${DIMS_CATEGORY:-devops}
GROUP=${DEPLOYMENT}
HOSTNAME=$(hostname)
INVENTORY=${INVENTORY:-$(get_inventory $DEPLOYMENT)}

# If you change this from 'hello' to something else, make sure to also
# change the tightly-coupled output string in the usage() function.
DEFAULT_ROLE='hello'

# Define command line options
DEFINE_boolean 'debug' false 'enable debug mode' 'd'
DEFINE_string 'deployment' "${DEPLOYMENT}" 'deployment identifier' 'D'
DEFINE_string 'category' "${CATEGORY}" 'category identifier' 'C'
DEFINE_string 'host' "${HOSTNAME}" 'host identifier' 'H'
DEFINE_string 'group' "${GROUP}" 'inventory group' 'G'
DEFINE_string 'role' "${DEFAULT_ROLE}" 'role to apply' 'R'
DEFINE_string 'task' '' 'task to execute' 't'
DEFINE_string 'inventory' "${INVENTORY}" 'inventory file' 'i'
DEFINE_boolean 'list-roles' false 'list available roles' ''
DEFINE_boolean 'list-hosts' false 'list defined hosts' ''
DEFINE_boolean 'list-tasks' false 'list defined tasks' ''
DEFINE_boolean 'list-facts' false 'list cached facts' ''
DEFINE_boolean 'list-deployments' false 'list defined deployments' ''
DEFINE_boolean 'gather-facts' false 'gather facts and cache' ''
DEFINE_boolean 'show-facts' false 'show cached facts' ''
DEFINE_boolean 'show-playbook' false 'show playbook (do not run it)' ''
DEFINE_boolean 'delete-facts' false 'delete cached facts' ''
DEFINE_boolean 'runplaybook' false 'run playbook for host' 'r'
DEFINE_string 'template-src' '' 'template source file' 'I'
DEFINE_string 'template-dest' '' 'template dest file' 'O'
DEFINE_string 'template-vars' '' 'template vars file' ''
DEFINE_boolean 'nocolor' false 'turn off colorization' 'n'
DEFINE_boolean 'upgrade' false 'upgrade patches to OS' 'U'
DEFINE_boolean 'usage' false 'print usage information' 'u'
DEFINE_boolean 'verbose' false 'be verbose' 'v'
DEFINE_boolean 'version' false 'print version number and exit' 'V'

ANSIBLE_OPTIONS="${ANSIBLE_OPTIONS}"
FLAGS_HELP="usage: $BASE [options] args"

# Define functions

usage() {
    flags_help
    cat << EOD

This script is intended to facilitate running a single role against a target
host from a controller host. By default, the controller host and the target host
are the local host. It uses the playbook 'base_playbook.yml' to do this.

The target host's fully qualified domain name is used to set all category,
deployment, and host variables variables according to the standard methodology
used by DIMS project tools. The 'base_playbook.yml' playbook file is structured
identically to other host or group playbooks to ensure this is done.

Running this script with no arguments results in the 'hello' role being run
against the local host. This allows a simple functional test to be performed
that validates the Ansible configuration is set up properly.  The results
would look something like this:

  $ dims.ansible-playbook
  [ ... ]

  TASK [hello : debug] ***********************************************************
  ok: [dimsdemo1.devops.develop] => {
      "msg": "Hello from dimsdemo1"
  }

  msg: Hello from dimsdemo1

  msg: Hello from dimsdemo1

  PLAY RECAP *********************************************************************
  dimsdemo1.devops.develop   : ok=3    changed=1    unreachable=0    failed=0

To select a specific role, use the --role option like this:

  $ dims.ansible-playbook --role 'ansible-server'


To select a specific host, use the '--host', '--category' and/or
'--deployment' options as needed. The resulting fully qualified domain
name is used to load variables and a remote (SSH) connection will be
made.

To restrict which plays are executed, or to pass any other Ansible command
line options, add '--' to the end of the options for this script, followed
by the options and arguments to pass to Ansible:

  $ dims.ansible-playbook --role 'base' -- -e 'somevar=someval' --tags 'config'

To run a host playbook for the specific host, use the '--runplaybook' ('-r') flag.

To run a task playbook, use the '--task' ('-t') flag.

You can list tasks (--list-task), roles (--list-roles), deployments
(--list-deployments) and hosts (--list-hosts).

When listing hosts, you can also show the assigned roles using the
--verbose flag:

  $ dims.ansible-playbook --list-hosts --verbose red blue
  blue.devops.local
      base, artifact_branch: develop
      hosts, artifact_branch: develop
      dims-base, artifact_branch: develop
      dims-ci-utils, artifact_branch: develop
      python-virtualenv, artifact_branch: develop, use_sphinx: true
      consul, artifact_branch: develop
      ansible-server
      vagrant
      pycharm
      byobu
      openstack-ansible-security
  red.devops.local
      base, artifact_branch: develop
      hosts, artifact_branch: develop
      dims-base, artifact_branch: develop
      dims-ci-utils, artifact_branch: develop
      python-virtualenv, artifact_branch: develop, use_sphinx: false, https_proxy: "https://10.0.2.2:8000"
      dns, artifact_branch: develop, zones: ['local']
      consul, artifact_branch: develop

To enable upgrading of base operating system patches in the 'base' role, use --upgrade.

(NOTE: The roles *must* be written on a single line for the roles to be found properly.)

Using --verbose enables verbose output in this script and runs ansible-playbook with '-vv'.
Using --debug enables debugging output in this script and runs ansible-playbook with '-vv'.
Using both --verbose and --debug gives max output and runs ansible-playbook with '-vvvv'.

EOD
    exit 0
}

to_json_pretty() {
    echo $@ | python -m json.tool
}

exists_task() {
    if [[ -z $1 ]]; then
        error_exit 1 "No task specified"
    fi
    local _task="${PBR}/tasks/$1.yml"
    if [[ -f $_task ]]; then
        return ${FLAGS_TRUE}
    else
        return ${FLAGS_FALSE}
    fi
}

exists_role() {
    if [[ -z $1 ]]; then
        error_exit 1 "No role specified"
    fi
    local _role="${PBR}/roles/$1"
    if [[ -f $_role/tasks/main.yml ]]; then
        return ${FLAGS_TRUE}
    else
        return ${FLAGS_FALSE}
    fi
}

list_roles() {
    declare -a results
    while read i; do
          results=( "${results[@]}" "$i" )
    done < <(cd ${PBR}/roles &&
        ls -1 */tasks/main.yml|
        sed -e 's|/tasks/main.yml||')
    debug "list_roles()"
    for r in ${results[@]}; do
        # The following implements the ternary operation a == b ? do_a() : do_b()
        ([[ ${FLAGS_nocolor} == ${FLAGS_TRUE} ]] && usecolor="-n") || usecolor="-C"
        if [[ ${FLAGS_verbose} == ${FLAGS_TRUE} ]]; then
            echo "$(cd ${PBR}/roles && tree -d ${usecolor} --noreport $r)"
        else
            echo $r
        fi
    done
    return 0
}

show_roles() {
    local _host=$1
    [[ -f ${PBR}/playbooks/hosts/$_host.yml ]] || error_exit 1 "[-] No host specified or specified host not found"
    while read i; do
          echo "   " $i
    done < <(grep "role: " ${PBR}/playbooks/hosts/${d}.yml |
        sed -e 's| *\- *{ * role: ||' -e 's| *}||')
    return 0
}

list_tasks() {
    declare -a results
    while read i; do
          results=( "${results[@]}" "$i" )
    done < <(cd ${PBR}/tasks &&
        ls -1 *.yml|
        egrep -v "pre-tasks|post-tasks" |
        sed -e 's/\.yml//')
    debug "list_tasks()"
    for t in ${results[@]}; do
        echo $t
    done
    return 0
}

exists_host_playbook() {
    [[ -f ${PBR}/playbooks/hosts/$1.yml ]]
    local result=$?
    debug "exists_host_playbook result=$result"
    return $result
}

list_hosts() {
    local _hosts=$(echo $@ | sed 's# #|#g')
    [[ ${_hosts} == "|" ]] && _hosts='.*'
    declare -a results
    while read i; do
          results=( "${results[@]}" "$i" )
    done < <(cd ${PBR}/playbooks/hosts &&
        ls -1 *.yml|
        egrep "$_hosts" |
        sed -e 's/\.yml//')
    debug "list_hosts()"
    for d in ${results[@]}; do
        echo $d
        [[ ${FLAGS_verbose} -eq ${FLAGS_TRUE} ]] && show_roles $d
    done
    return 0
}

list_deployments() {
    declare -a results
    while read i; do
          results=( "${results[@]}" "$i" )
    done < <(cd ${PBR}/inventory &&
        find */group_vars -maxdepth 0 -exec dirname {} ';')
    debug "results[]=${results[@]}"
    for d in ${results[@]}; do
        echo $d
    done
    return 0
}

list_facts() {
    declare -a results
    while read i; do
          results=( "${results[@]}" "$i" )
    done < <(cd ${FACTSD} && ls -1)
    debug "results[]=${results[@]}"
    for d in ${results[@]}; do
        if [[ ${FLAGS_verbose} == ${FLAGS_TRUE} ]]; then
            echo "$(cd ${FACTSD} && ls -l $d | awk '{print $6,$7,$8,$9;}')"
        else
            echo $d
        fi
    done
    return 0
}

gather_facts() {
    local target=$1 && shift
    # "All we want are the facts, ma'am". Joe Friday.
    # If the only fact is that there are no facts, don't cache that fact.
    ansible ${target} -i ${PBR}/${FLAGS_inventory} -m setup --tree ${FACTSD} $@ || rm ${FACTSD}/${target} && exit 1
    exit 0
}

show_facts() {
    if [[ ! -f "${FACTSD}/$1" ]]; then
        error_exit 1 "No facts file '${FACTSD}/$1' found"
    else
        verbose "Cached facts for $1"
        python -mjson.tool ${FACTSD}/$1
    fi
    exit $?
}

validate_type() {
    local _type=$1 && shift
    if [[ ${_type} != "task" || ${_type} != "role" ]]; then
        error_exit 1 'Temporary playbook type must be "role" or "task"'
    fi
}

# Create a temporary file and load it with the host vars for the
# specified host using dims.inventory dynamic inventory script so as
# to produce identical vars as Ansible would produce. This allows the
# localhost to template a file with vars for a different host (possibly
# in a different deployment). To ensure accurate output of the
# dims.inventory script, make sure to set environment variables for
# DIMS_FQDN, DIMS_CATEGORY, DIMS_DEPLOYMENT, and DIMS_GROUP when calling
# the script. Make sure to read the document provided by
# "dims.inventory --usage" to understand how to control it properly.

get_temp_vars_file() {
    local _host=$1
    local _deployment=$(get_deployment_from_fqdn $_host)
    local _vars=$(get_temp_file vars.yml)
    ( cd ${FLAGS_inventory}; \
      DIMS_FQDN=$_host \
      DIMS_CATEGORY=${FLAGS_category} \
      DIMS_DEPLOYMENT=${FLAGS_deployment} \
      DIMS_GROUP=${FLAGS_group} \
      dims.inventory \
          --host ${_host} ) > ${_vars}
    if [[ $? -ne 0 ]]; then
        rm -f ${_vars}
        error_exit $? "Failed to get vars"
    fi
    echo ${_vars}
}

get_temp_playbook() {
    local _type=$1 && shift
    local _pb=$(get_temp_file yml)
    (awk '1;/@@dims.ansible-playbook@@/{exit}' ${PBR}/base_playbook.yml && \
    [[ ! -z "${FLAGS_template_src}" && ! -z "${FLAGS_template_dest}" ]] && \
        echo "  gather_facts: false"; \
    if [[ $_type == "task" ]]; then \
        echo "  tasks:"; \
        if [[ ${FLAGS_debug} -eq ${FLAGS_TRUE} ]]; then \
            echo "    - include: $(get_task_playbook debug-dump-vars)"; \
        fi; \
        echo "    - include: $(get_task_playbook $1)"; \
    else \
        echo "  roles:"; \
        if [[ ${FLAGS_debug} -eq ${FLAGS_TRUE} ]]; then \
            echo "    - debug"; \
        fi; \
        echo "    - { role: $1 }"; \
    fi) > $_pb
    echo "$_pb"
}

# Do not output anything in this function except content
get_host_playbook() {
    pb="${PBR}/playbooks/hosts/$1.yml"
    grep -q '^---' ${pb}
    if [[ $? -eq 0 ]]; then
        echo "${pb}"
    else
        echo ""
    fi
}

# Do not output anything in this function except content
get_task_playbook() {
    pb="${PBR}/tasks/$1.yml"
    grep -q '^---' ${pb}
    if [[ $? -eq 0 ]]; then
        echo "${pb}"
    else
        error_exit 1 "$pb does not appear to be a valid playbook"
    fi
}

run_playbook() {
    # Args $1 and $2 are required. Remainder of args are passed to Ansible.
    local pb=$1; shift
    local host=$1; shift

    JSON='{"host": "'"$host"'",
       "debug": "'"$(get_true ${FLAGS_debug})"'",
       "verbose": "'"$(get_true ${FLAGS_verbose})"'",
       "connection": "'"$(ansible_connection $host)"'",
       "ansible_base": "'"$PBR"'",
       "packages_upgrade": "'"$(get_true ${FLAGS_upgrade})"'",
       "playbooks_root": "'"$PBR"'",
    }'
    if [[ ${FLAGS_show_playbook} -eq ${FLAGS_TRUE} ]]; then
        say "Ansible arguments:"
        echo "$JSON"
        say "Host playbook ${pb}:"
        cat ${pb}
        return 0
    fi

    # (See comment in front of ansible-playbook call in run_template() )
    ANSIBLE_NOCOLOR=0 \
    ansible-playbook \
        -i ${FLAGS_inventory} \
        -c $(ansible_connection ${host}) \
        --become \
        -e "$(echo $JSON | paste -d' ' -)" \
        $pb $@ ${ANSIBLE_OPTIONS}
    return $?
}

run_template() {
    local pb=$1; shift
    local host=$1; shift
    local _tmpout=$(get_temp_file ansible_out)
    add_on_exit rm -f $_tmpout
    local _retval=0

    JSON='{"host": "'"$host"'",
       "connection": "'"$(ansible_connection $host)"'",
       "ansible_base": "'"$PBR"'",
       "playbooks_root": "'"$PBR"'",
       "tsrc": "'"${FLAGS_template_src}"'",
       "tdest": "'"${FLAGS_template_dest}"'",
       "tvars": "'"${FLAGS_template_vars}"'"
    }'

    # Pass a couple environment variables to ansible to control
    # output. Using the force_color configuration file option
    # to enable color seems to override ANSIBLE_NOCOLOR,
    # so just enable color when calling ansible-playbook.
    ANSIBLE_STDOUT_CALLBACK=debug \
    ANSIBLE_NOCOLOR=1 \
    ansible-playbook \
        -i ${FLAGS_inventory} \
        -c $(ansible_connection ${host}) \
        -e "$(echo $JSON | paste -d' ' -)" \
        $pb $@ ${ANSIBLE_OPTIONS} > $_tmpout
    _retval=$?
    # Don't let an empty template go out.
    if [[ $_retval -ne 0 ]]; then
        cp ${_tmpout} ${_tmpout}.txt
        verbose "Ansible templating failed: output in ${_tmpout}.txt"
        if [[ enabled_debug ]]; then
            [[ -s ${FLAGS_template_dest} ]] && cat ${FLAGS_template_dest}
            cat ${_tmpout} ${_tmpout}.txt
        fi
    fi
    if [[ ! -s ${FLAGS_template_dest} ]]; then
        rm -f ${FLAGS_template_dest}
    fi
    if verbose_enabled; then
        # In case Ansible is repeating itself, eliminate dupes.
        # See $PBR/tasks/template.yml for formatting.
        grep '^\[[+_!]\] ' $_tmpout | sort -r | uniq
    fi
    return $_retval
}


main()
{
    dims_main_init

    # If --verbose or --debug used alone, go with -vv, but if both used, crank it up to -vvvv
    if [[ $FLAGS_debug -eq ${FLAGS_TRUE} && $FLAGS_verbose -eq ${FLAGS_TRUE} ]]; then
        ANSIBLE_OPTIONS+=" -vvvv"
    elif [[ $FLAGS_debug -eq ${FLAGS_TRUE} || $FLAGS_verbose -eq ${FLAGS_TRUE} ]]; then
        ANSIBLE_OPTIONS+=" -vv"
    fi

    [[ ${FLAGS_list_roles} -eq ${FLAGS_TRUE} ]] && list_roles && exit 0
    [[ ${FLAGS_list_hosts} -eq ${FLAGS_TRUE} ]] && list_hosts $@ && exit 0
    [[ ${FLAGS_list_tasks} -eq ${FLAGS_TRUE} ]] && list_tasks && exit 0
    [[ ${FLAGS_list_facts} -eq ${FLAGS_TRUE} ]] && list_facts && exit 0
    [[ ${FLAGS_list_deployments} -eq ${FLAGS_TRUE} ]] && list_deployments && exit 0

    # Support for use in Jinja templating via ansible-playbook. If both --template-src
    # and --template-dest are given, default to 'localhost' and invoke the 'template'
    # task implicitly. An optional template vars file is loaded later when the
    # playbook is about to be run.

    [[ ! -z "${FLAGS_template_src}" && -z "${FLAGS_template_dest}" ]] &&
        error_exit 1 "--template-dest not specified: must accompany --template-src"
    [[ -z "${FLAGS_template_src}" && ! -z "${FLAGS_template_dest}" ]] &&
        error_exit 1 "--template-src not specified: must accompany --template-dest"

    # Validate template related flag settings.
    if [[ ! -z "${FLAGS_template_src}" && ! -z "${FLAGS_template_dest}" ]]; then
        [[ -f ${FLAGS_template_src} ]] || error_exit 1 "File not found: ${FLAGS_template_src}"
        touch ${FLAGS_template_dest} || error_exit 1 "Can't create file: ${FLAGS_template_dest}"
        if [[ ! -z "${FLAGS_template_vars}" ]]; then
            [[ -f "${FLAGS_template_vars}" ]] || error_exit 1 "Template vars file not found: ${FLAGS_template_vars}"
        fi
    fi

    # Override hostname, etc. if first argument validates to a three-component FQDN.
    if is_fqdn $1; then
        FQDN=$1 && shift
        FLAGS_host="$(get_hostname_from_fqdn $FQDN)"
        FLAGS_category="$(get_category_from_fqdn $FQDN)"
        FLAGS_deployment="$(get_deployment_from_fqdn $FQDN)"
        FLAGS_inventory="$PBR/inventory/$FLAGS_deployment"
        verbose "Using inventory ${FLAGS_inventory} for host $FQDN"
        debug "FLAGS_inventory=${FLAGS_inventory}"
        debug "FQDN=${FQDN}"
    else
        # (Force three arguments from command line flags to compose_fqdn)
        FQDN=$(compose_fqdn "${FLAGS_host}" "${FLAGS_category}" "${FLAGS_deployment}")
        [[ -z $FQDN ]] && error_exit 1 "Could not compose an FQDN from host:\'${FLAGS_host}\' category:\'${FLAGS_category}\' deployment:\'${FLAGS_deployment}\'"
        debug "FQDN=${FQDN}"
    fi

    if [[ ! -z "${FLAGS_template_src}" && ! -z "${FLAGS_template_dest}" ]]; then
        if [[ -z "$FLAGS_template_vars" ]]; then
            FLAGS_template_vars=$(get_temp_vars_file $FQDN)
            if [[ ${FLAGS_debug} -eq ${FLAGS_TRUE} ]]; then
                debug "Temporary vars file \"${FLAGS_template_vars}\" will not be deleted"
            else
                add_on_exit rm -f ${FLAGS_template_vars}
            fi
        fi
        ansible_host="$FQDN"
        FLAGS_task="template"
    elif [[ "$(get_fqdn)" == "$FQDN" ]]; then
        verbose "Operating on local target"
        ansible_host="localhost"
    else
        verbose "Operating on remote target"
        ansible_host="$FQDN"
    fi

    # Force execution to be rooted in the playbooks directory.
    [[ -z $PBR ]] && error_exit 1 'PBR must be defined to point to ansible playbooks'
    cd $PBR

    if [[ ${FLAGS_gather_facts} -eq ${FLAGS_TRUE} ]]; then
        gather_facts $FQDN $@
    elif [[ ${FLAGS_show_facts} -eq ${FLAGS_TRUE} ]]; then
        show_facts $FQDN
    elif [[ ${FLAGS_delete_facts} -eq ${FLAGS_TRUE} ]]; then
        error_exit 1 "--delete-facts is not implemented yet; do it yourself, they are in ${FACTSD}"
    fi

    if [[ ( ! -z "${FLAGS_task}" || ${FLAGS_runplaybook} -eq ${FLAGS_TRUE} ) && \
          ( ${FLAGS_role} != ${DEFAULT_ROLE} ) ]]; then
            error_exit 1 'Options --role, --runplaybook, and --task are mutually exclusive'
    fi

    # Find or build a playbook as appropriate.
    if [[ ${FLAGS_runplaybook} -eq ${FLAGS_TRUE} || ${FLAGS_show_playbook} -eq ${FLAGS_TRUE} ]]; then
        pb=$(get_host_playbook $FQDN)
    elif [[ ! -z ${FLAGS_task} ]]; then
        exists_task ${FLAGS_task}
        [[ $? -eq ${FLAGS_TRUE} ]] || error_exit 1 "Task \"${FLAGS_task}\" not found"
        pb=$(get_temp_playbook task ${FLAGS_task})
        [[ ${FLAGS_debug} -eq ${FLAGS_FALSE} ]] && add_on_exit rm -f $pb
    elif [[ ! -z ${FLAGS_role} ]]; then
        exists_role ${FLAGS_role}
        [[ $? -eq ${FLAGS_TRUE} ]] || error_exit 1 "Role \"${FLAGS_role}\" not found"
        pb=$(get_temp_playbook role ${FLAGS_role})
        [[ ${FLAGS_debug} -eq ${FLAGS_FALSE} ]] && add_on_exit rm -f $pb
    fi
    if [[ ${FLAGS_debug} -eq ${FLAGS_TRUE} ]]; then
        debug "Temporary playbook \"$pb\" will not be deleted"
    fi
    exists_host_playbook $FQDN || error_exit 1 "No host playbook found for $FQDN"
    if [[ ! -z "${FLAGS_template_src}" && ! -z "${FLAGS_template_dest}" ]]; then
        run_template $pb $ansible_host $@
    else
        run_playbook $pb $ansible_host $@
    fi
    debug "Returning from main()"
    on_exit
    return $?
}


# parse the command-line
FLAGS "$@" || exit $?
eval set -- "${FLAGS_ARGV}"
main "$@"
exit $?
