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

. $DIMS/bin/dims_functions.sh

function on_linux() {
    # Swap Left CapsLock with Left Ctrl
    if [[ ! -z "$XAUTHORITY" ]]; then
        setxkbmap -layout us -option '' -option grp:shift_caps_switch -option ctrl:swapcaps
        exit $?
    else
        echo "XAUTHORITY not set: remap CAPSLOCK/CTRL keys another way"
        exit 1
    fi
}

function on_darwin() {
    echo "To remap CAPSLOCK/CTRL keys, follow guidance at https://support.apple.com/kb/PH18422"
    exit 1
}

function not_implemented() {
    echo "Not implemented for $1"
    exit 1
}

case $OS in
	Darwin) on_darwin ;;
	Linux) on_linux ;;
	*) not_implemented $OS;;
esac

exit 0
