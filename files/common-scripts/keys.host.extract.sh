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
# virtual machine using Vagrant, Terraform, etc. It will extract public
# keys and fingerprints that were printed out by the complementary script
# "keys.host.fingerprints.sh".

# See also:
# $PBR/ansible-dims-playbooks/roles/bootstrap/tasks/info.yml
# https://fullmetalhealth.com/spin-off-ansible-ssh-bastion-host-dynamic-infrastructure-aws-gathering-ssh-public-key-aws-system-log/

awk -v domain="devops.local" '
BEGIN {
    SUBSEP="@";
    FS=" ";
    debug=0;
}

function _prep_directory(_dir)
{
    _cmd="[ ! -d " _dir " ] && mkdir -p " _dir " 2>/dev/null"
    system(_cmd)
    close(_cmd)
}

function _write_ssh_fingerprint(_host, _type, _key_fingerprint)
{
    _fqdn=_host "." domain
    _root="fingerprints/" _fqdn
    _prep_directory(_root)
    _file=_root "/" _type ".fingerprint"
    if (debug) {
        printf "[+] _write_ssh_fingerprint: _type=%s, _key_fingerprint=%s\n", _type, _key_fingerprint > "/dev/stderr";
    }
    printf "%s %s\n", _type, _key_fingerprint > _file;
}

function _write_ssh_known_hosts(_host, _ip, _type, _key_comment)
{
    _fqdn=_host "." domain
    _root="known_hosts/" _fqdn
    _prep_directory(_root)
    _file=_root "/" _type ".known_hosts"
    if (debug) {
        printf "[+] _write_ssh_known_hosts: _fqdn=%s, _ip=%s, _type=%s, _key_comment=%s\n", _fqdn, _ip, _type, _key_comment > "/dev/stderr";
    }
    printf "%s,%s %s %s\n", _fqdn, _ip, _type, _key_comment > _file;
}

# Toggles to determine whether public keys or fingerprints of
# keys are being exported from droplets when terraform creates
# droplets.
/BEGIN SSH HOST KEY FINGERPRINTS/ { fingerprint=1; }
/END SSH HOST KEY FINGERPRINTS/ { fingerprint=0; }
/BEGIN SSH HOST PUBLIC KEYS/ { publickey=1; }
/END SSH HOST PUBLIC KEYS/ { publickey=0; }

{
    print;

	# Extract IP address for droplet
    # arr[1] is shortname
    # arr[2] is IP address
	if (match($0, /digitalocean_droplet\.([^ ]*) \(remote-exec\): *Host: (.*)/, arr)) {
		ip_addr[arr[1]]=arr[2];
	}

	# Extract SSH public keys and fingerprints for droplet
    # arr[1] is short name
    # arr[2] is SSH key type
    # arr[3] is key and comment string
	if (match($0, /digitalocean_droplet\.([^ ]*) \(remote-exec\): (ssh-[^ ]*) (.*$)/, arr)) {
		if (fingerprint) {
			if (debug) { printf "ssh_pubkey: %s %s %s\n", arr[1], arr[2], arr[3] > "/dev/stderr"; }
			_write_ssh_fingerprint(arr[1], arr[2], arr[3])
		}
		if (publickey) {
			if (debug) { printf "ssh_known_hosts: %s %s %s %s\n", arr[1], ip_addr[arr[1]], arr[2], arr[3] > "/dev/stderr"; }
			_write_ssh_known_hosts(arr[1], ip_addr[arr[1]], arr[2], arr[3])
		}
	}
}
'

exit $?
