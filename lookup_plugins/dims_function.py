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

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import os
from sh import bash

from ansible.plugins.lookup import LookupBase

# This lookup sends the arguments passed to it into a Bash shell that
# has loaded the dims_functions.sh library. It works in a similar manner
# to the dims.function command. It allows calling the Bash library
# from within Ansible templates.
#
# 
# $ ansible -i $PBR/inventory/local -m debug -a "msg={{ lookup('dims_function', 'say inventory_hostname={{ inventory_hostname }}') }}" coreos
# node01.devops.local | SUCCESS => {
#     "msg": "[+] inventory_hostname=node01.devops.local"
# }
# node02.devops.local | SUCCESS => {
#     "msg": "[+] inventory_hostname=node02.devops.local"
# }
# node03.devops.local | SUCCESS => {
#     "msg": "[+] inventory_hostname=node03.devops.local"
# }
# $ ansible -i $PBR/inventory/local -a "msg={{ lookup('dims_function', 'get_hostname_from_fqdn {{ inventory_hostname }}') }}" coreos
# node01.devops.local | SUCCESS => {
#     "msg": "node01"
# }
# node03.devops.local | SUCCESS => {
#     "msg": "node03"
# }
# node02.devops.local | SUCCESS => {
#     "msg": "node02"
# }

class LookupModule(LookupBase):

    def run(self, terms, variables=None, **kwargs):

        results = []
        _dims_function = "{}/bin/dims.function".format(
                os.getenv('DIMS', '')
                )
        cmd = [ _dims_function ] + [ arg for arg in terms ]
        try:
            results = [line.strip() for line in bash(cmd, _iter=True)]
        except Exception as e:
            raise e

        return results
