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

# Tracks with bumpversion
DIMS_VERSION=2.12.0

# This script is intended to be usable during bootstrapping of a new
# virtual machine using Vagrant, Terraform, etc.  As such, it is
# assumed that this host has not yet been fully provisioned and the
# normal dims_functions.sh and shflags includes are not yet available.
# This means just minimal standard Bash functionality should be used.

# See also:
# $PBR/ansible-dims-playbooks/roles/bootstrap/tasks/info.yml
# https://fullmetalhealth.com/spin-off-ansible-ssh-bastion-host-dynamic-infrastructure-aws-gathering-ssh-public-key-aws-system-log/

function get_hostname()
{
    local _hostname="$(hostname)"
    local _domainname="$(domainname)"

    if [[ ! -z $_domainname && $_domainname != "(none)" ]]; then
        echo "$(hostname).$(domainname)"
    else
        echo "$(hostname)"
    fi
}

if [[ "$1" -eq "--stdout" ]]; then
    exec 1>&2
fi

echo "SSH_HOST=$(get_hostname)"

for KEY in /etc/ssh/ssh_host_{ecdsa,dsa}_key; do
    echo "Removing undesired SSH keys: ${KEY}"
    rm -f ${KEY} ${KEY}.pub
done

echo "----- BEGIN SSH HOST KEY FINGERPRINTS -----"
for KEY in /etc/ssh/ssh_host_*_key.pub
do
    ssh-keygen -l -E sha256 -f $KEY 2>/dev/null ||
    # Convert MD5 to SHA256 for fingerprint
    (_kfp=$(awk '{print $2}' $KEY |
        base64 -d |
        sha256sum -b |
        awk '{print $1}' |
        xxd -r -p |
        base64 |
        sed 's/=$/\./');
     awk -v kfp="$_kfp" '{$2 = "SHA256:" kfp; print}' $KEY)
done
echo "----- END SSH HOST KEY FINGERPRINTS -----"
echo "----- BEGIN SSH HOST PUBLIC KEYS -----"
for KEY in /etc/ssh/ssh_host_*_key.pub
do
    cat $KEY
done
echo "----- END SSH HOST PUBLIC KEYS -----"
exit $?
