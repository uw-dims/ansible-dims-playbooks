#!/usr/bin/env python

# Copyright (C) 2014-2017, University of Washington. All rights reserved.
#
# David Dittrich <dittrich@u.washington.edu>
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
#
# This script creates a custom DIMS Ubuntu installation USB
# drive from a pre-mastered ISO image containing a casper-rw
# (a.k.a., "presistence") file. This file is used to hold
# certificates and key material necessary to perform a
# remote custom install of a DIMS system (e.g., a DIMS-DEVOPS
# development desktop, or a DIMS-PISCES collector appliance).
#
# See (link to Sphinx document here...)

import sys
import os
from sh import Command, bumpversion
from optparse import OptionParser

# Set defaults
CONFIG=".bumpversion.cfg"
USAGESTRING="""
%(_progname)s [options] [args]

Use "%(_progname)s --help" to see options.
Use "%(_progname)s --usage" to see help on "bumpversion" itself.

%(_progname)s -- [bumpversion_options] [bumpversion_args]

Follow this second usage example and put -- before any bumpversion
options and arguments to pass them on bumpversion (rather than
process them as though they were %(_progname)s arguments.) After
all, %(_progname)s is just a shell wrapping bumpversion.
"""

def find_bumpversion_cfg(dir_, verbose_):
    if dir_ == os.environ['GIT']:
        return None
    if os.path.exists("{0}/{1}".format(dir_, CONFIG)):
        if verbose_:
            print "[+] Found {0}/{1}".format(dir_, CONFIG)
        return(dir_)
    else:
        return(find_bumpversion_cfg(os.path.split(dir_)[0], verbose_))

def main():

    _progname=sys.argv[0]
    _shortname, _extension = os.path.splitext(_progname)

    parser = OptionParser(usage=USAGESTRING % vars())
    parser.add_option("-d", "--debug",
        action="store_true", dest="debug", default=False,
        help="Enable debugging")
    parser.add_option("-u", "--usage",
        action="store_true", dest="usage", default=False,
        help="Print usage information.")
    parser.add_option("-v", "--verbose",
        action="store_true", dest="verbose", default=False,
        help="Be verbose (on stdout) about what is happening.")
    (options, args) = parser.parse_args()

    # Default to "patch" if no args provided.
    if args == []:
        args = ["patch"]

    if options.usage:
        print USAGESTRING % vars()
        print "\n\n"
        bumpversion("--help", _out=sys.stdout)
        return 0

    # Look for CONFIG going up the directory hierarchy until you get to $GIT.
    bumpbase_ = find_bumpversion_cfg(os.getcwd(), options.verbose)
    if bumpbase_ is not None:
        os.chdir(bumpbase_)
        bumpversion(args)

    return 0

if __name__ == "__main__":
    sys.exit(main())
