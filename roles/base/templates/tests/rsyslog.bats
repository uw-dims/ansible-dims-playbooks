#!/usr/bin/env bats
#
# {{ ansible_managed }} [ansible-playbooks v{{ ansibleplaybooks_version }}]
#
# vim: set ts=4 sw=4 tw=0 et :

@test "[S][EV] Directory /var/log/dims exists" {
    [ -d /var/log/dims ]
}

@test "[C][EV] System logs show up in host-based file in /var/log/dims" {
    rand="${$}${!}"
    fqdn="$(hostname).$(domainname)"
    run logger -t local0.info "@@${rand}@@" && sleep 3
    [ -f /var/log/dims/${fqdn}.log ]
} 
