#!/usr/bin/env bash
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

# This is a prototype Bash script implementing an Ansible module.
# To invoke this script, do the following:
#
#   $ ansible -m dump_env -i $PBR/inventory/develop localhost
#
# To see how environment variables can be over-ridden, do:
#
#   $ DIMS_DEBUG=1 DIMS_VERBOSE=1 DIMS_DEPLOYMENT=devlop ansible -m dump_env -i $PBR/inventory/develop localhost
#
# To trigger the failure logic, do:
#
#   $ ansible -m dump_env -i $PBR/inventory/develop localhost -a failure=true
#
# See also:
# https://github.com/pmarkham/writing-ansible-modules-in-bash/blob/master/ansible_bash_modules.md
# http://docs.ansible.com/ansible/script_module.html

function str_to_json() {
  printf "$1" | python -c 'import json,sys; print json.dumps(sys.stdin.read())'
}

function file_to_json() {
  cat $1 | python -c 'import json,sys; print json.dumps(sys.stdin.read())'
}

# Source the Ansible module variables
source $1

# To implement a required argument, check existence here:
#if [[ -z "$dump_args" ]]; then
#  printf '{"failed": true, "msg": "missing required arguments: dump_args"}'
#  exit 1
#fi

# Defaults
changed="false"

if [[ "$dump_args" == "true" ]]; then
  msg=$(str_to_json 'Dumping Ansible module args')
  contents=$(file_to_json $1)
  printf '{"changed": %s, "msg": %s, "contents": %s}' "$changed" "$msg" "$contents"
  exit 1
elif [[ "$failure" == "true" ]]; then
  printf '{"failed": true, "msg": "you told me to fail, so I failed"}'
else
  msg=$(str_to_json 'Dumping environment variables')
  contents=$(str_to_json "$(env)")
  printf '{"changed": %s, "msg": %s, "contents": %s}' "$changed" "$msg" "$contents"
  exit 0
fi
