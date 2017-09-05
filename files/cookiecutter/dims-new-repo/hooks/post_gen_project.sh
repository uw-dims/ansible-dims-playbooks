#!/bin/bash

# This script inserts an appropriate length section
# underline for a top level section in .rst files.

if grep -rq FIX_UNDERLINE $(pwd); then
	echo "[+] Fix underlining in these files:"
	for F in $(find $(pwd) -name '*.rst'); do
		grep -l FIX_UNDERLINE $F
	done
fi

exit 0

# vim: set ts=4 sw=4 tw=0 noet :
