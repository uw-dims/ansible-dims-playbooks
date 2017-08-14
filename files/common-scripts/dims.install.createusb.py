#!/usr/bin/env python
# -*- coding: iso-8859-15 -*-
#
# Copyright (C) 2014, 2017, University of Washington. All rights reserved.
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
# David Dittrich <dittrich@u.washington.edu>
# 
# This script creates a custom DIMS Ubuntu installation USB
# drive from a pre-mastered ISO image containing a casper-rw
# (a.k.a., "presistence") file. This file is used to hold
# certificates and key material necessary to perform a
# remote custom install of a DIMS system (e.g., a DIMS-DEVOPS
# development desktop, or a DIMS-PISCES collector appliance).
#
# See (link to Sphinx document here...)

# WARNING:  This script was written using an SSHFS file system
# for storing the system configuration information. The use of
# SSHFS causes problems for some of the operations here, since the
# files and file systems (e.g., casper-rw) that we are dealing with
# are owned by root, and some of the operations (e.g., a loopback
# mount on Ubuntu 14.04) require root. That means that certain
# operations (like "rsync") don't work so well with "sudo".
# Be aware of this when reading/modifying the code below.

import sys
import os
import time
import functools
import datetime
import platform
import bz2

from optparse import OptionParser, OptionGroup

from sh import chmod
from sh import cp
from sh import ls
from sh import grep
from sh import mount
from sh import rm
from sh import rsync
from sh import sudo
from sh import tree
from sh import udisksctl
from sh import Command

# Managed by bumpversion
VERSION = "2.10.2"

# Define a globals class
class mem(object):
    # Set defaults
    #SSHFS="gituser@git.prisem.washington.edu:cfg"
    #CFGPATH="{0}/dims/cfg".format(os.environ["HOME"])
    CFGPATH="{0}/nas/scd".format(os.environ["DIMS"])
    DISTROVERSION="14.04.5"
    HOSTNAME=platform.node()
    DEFAULTDEVICE="sdb"
    USBLABEL="DIMSINSTALL"
    COMPRESSUTIL="bzip2"
    COMPRESSEXT=".dd.bz2"
    BLOCKSIZE="512"
    USAGESTRING="""usage: %(_progname)s [options] [args]

Use "%(_progname)s --help" to see help on command line options.
"""
    EXTRAUSAGE="""Example:

$ %(_progname)s -verbose --debug--hostname dimsdemo1
[+] /home/dittrich/dims/git/dims-ci-utils/usb-install/dims.install.createusb
[+] Found device labelled 'DIMSINSTALL' on /dev/sdb1
[+] get_mount_point found /dev/sdb1 mounted on /media/dittrich/DIMSINSTALL
[+] Creating mount point "/home/dittrich/dims/git/dims-ci-utils/usb-install/casper-rw"
[+] Mounting /media/dittrich/DIMSINSTALL/casper-rw to /home/dittrich/dims/git/dims-ci-utils/usb-install/casper-rw
total 36
drwxrwxr-x 3 dittrich dittrich  4096 Jul 24 21:46 ..
drwxr-xr-x 6 root     root      4096 Jul 24 21:44 .
drwx------ 2 root     root     16384 Jul 24 17:05 lost+found
drwxr-xr-x 2 root     dittrich  4096 Apr  4 11:24 ssh-host-keys
drwxr-xr-x 2 root     dittrich  4096 Aug 18  2015 openvpn-cert
drwxr-xr-x 2 root     dittrich  4096 Aug 11  2015 ssh-user-keys
[+] Installed preseed.cfg to /media/dittrich/DIMSINSTALL/preseed.cfg
[+] Installed ks.cfg to /media/dittrich/DIMSINSTALL/ks.cfg
[+] Installed txt.cfg to /media/dittrich/DIMSINSTALL/syslinux/txt.cfg
[+] Installed syslinux.cfg to /media/dittrich/DIMSINSTALL/syslinux/syslinux.cfg
[+] Copying SSH key(s) from /opt/dims/nas/scd/dimsdev3/ssh-host-keys to /home/dittrich/dims/git/dims-ci-utils/usb-install/casper-rw/ssh-host-keys)
[+] Copying SSH key(s) from /opt/dims/nas/scd/dimsdev3/ssh-user-keys to /home/dittrich/dims/git/dims-ci-utils/usb-install/casper-rw/ssh-user-keys)
[+] Copying OpenVPN cert(s) from /opt/dims/nas/scd/dimsdev3/openvpn-cert to /home/dittrich/dims/git/dims-ci-utils/usb-install/casper-rw/openvpn-cert)
[+] Unmounting /home/dittrich/dims/git/dims-ci-utils/usb-install/casper-rw
[+] Removing /home/dittrich/dims/git/dims-ci-utils/usb-install/casper-rw mount point
[+] get_mount_point found /dev/sdb1 mounted on /media/dittrich/DIMSINSTALL
[+] Partition /dev/sdb12 is not mounted
[+] Partition /dev/sdb11 is not mounted

$ %(_progname)s --ls-casper
[+] Contents of /home/dittrich/dims/git/dims-ci-utils/usb-install/casper-rw:
/home/dittrich/dims/git/dims-ci-utils/usb-install/casper-rw
├── [drw------- root    ]  lost+found [error opening dir]
├── [drwxrwxr-x root    ]  openvpn-cert
│   └── [-rw-r--r-- root    ]  uwapl_dimsdemo1.ovpn
├── [drwxr-xr-x root    ]  ssh-host-keys
│   ├── [-rw-r--r-- root    ]  key_fingerprints.txt
│   ├── [-rw-r--r-- root    ]  known_hosts.add
│   ├── [-rw------- root    ]  ssh_host_dsa_key
│   ├── [-rw-r--r-- root    ]  ssh_host_dsa_key.pub
│   ├── [-rw------- root    ]  ssh_host_ecdsa_key
│   ├── [-rw-r--r-- root    ]  ssh_host_ecdsa_key.pub
│   ├── [-rw------- root    ]  ssh_host_ed25519_key
│   ├── [-rw-r--r-- root    ]  ssh_host_ed25519_key.pub
│   ├── [-rw------- root    ]  ssh_host_rsa_key
│   └── [-rw-r--r-- root    ]  ssh_host_rsa_key.pub
└── [drwxrwxr-x root    ]  ssh-user-keys
    ├── [-rw------- root    ]  dims_ansible_rsa
    └── [-rw-r--r-- root    ]  dims_ansible_rsa.pub

4 directories, 14 files

$ %(_progname)s -v -d --device sdb --read-usb-into
[+] dims.install.createusb
[+] Reading USB drive on sdb into ubuntu-14.04.3-install.bz2.dd.bz2
[+] Block size for dd: 512
15642624+0 records in
15642624+0 records out
8009023488 bytes (8.0 GB) copied, 1112.94 s, 7.2 MB/s
1557808+1 records in
1557808+1 records out
797597824 bytes (798 MB) copied, 1112.98 s, 717 kB/s
[+] Finished writing ubuntu-14.04.3-install.bz2.dd.bz2 in 0:18:32.982333 seconds



$ %(_progname)s -v --device sdb --write-usb-from ubuntu-14.04.3-install.dd.bz2
[+] dims.install.createusb
[+] Found sdb mounted as /dev/sdb1 on /media/dittrich/DIMSINSTALL
[+] Found /media/dittrich/DIMSINSTALL mounted as /dev/sdb1 on /media/dittrich/DIMSINSTALL
[+] Unmounted /dev/sdb1
[+] Writing ubuntu-14.04-install.dd.bz2 to USB drive on /dev/sdb
dd: error writing ‘/dev/sdb’: No space left on device

"""

def cleanexit(retcode):
    """
    Cleanly exit by unmounting devices/files and removing temporary mount point.

    :param retcode:
    :return:
    """
    if os.path.exists(mem.casper_rw_mp):
        unmount_casper()
        remove_casper_mountpoint()
    # Unmount device
    if is_mounted(mem.options.device):
        unmount_device(mem.options.device)
    sys.exit(retcode)


def get_block_device(device_):
    """Get the udisksctl block device name for a given device file."""
    if device_.startswith("/dev/"):
        device_ = os.path.basename(device_)
    block_device_ = "block_devices/{0}".format(device_)
    # Get udisksctl device output and look for this device.
    # Return block device name (if found), or None
    return block_device_


#@functools.lru_cache(maxsize=None)
def get_mount_point(device_):
    """
    Get the mounted directory path for a specific device.

    :param device_: Device name (e.g., "/dev/sdb1")
    :return: String
    """
    for line in grep(mount(), device_, _ok_code=[0, 1], _iter=True):
        words = line.split()
        if device_ in words[0]:
            if mem.options.debug:
                print "[+] get_mount_point found {0} mounted on {1}".format(
                    device_, words[2])
            return words[2]
    return None


def get_partition(string_):
    """
    Return the partition portion of a device name (mount style, or udisksctl style).

    :param string_:
    :return:
    """
    if "block_devices/" in string_:
        return string_[len("block_devices/"):]
    elif "/dev/" in string_:
        return string_[len("/dev/"):]
    else:
        return string_


def installfile(f_,dest_):
    """Install a file in a destination directory."""
    dstf_ = "{0}/{1}".format(dest_, f_)
    try:
        sudo.cp(f_, dstf_)
    except Exception as exception_:
        print u"[!] Exception: {0}".format(exception_)
        print "[!] Failed to install {0} as {1}".format(f_, dstf_)
        cleanexit(1)
    if mem.options.verbose:
        print "[+] Installed {0} to {1}".format(f_, dstf_)
    try:
        chmod("755", dstf_) 
    except Exception as exception_:
        print u"[!] Exception: {0}".format(exception_)
        print "[!] Failed to set permissions on {0}".format(dstf_)
        cleanexit(1)


def mount_nas():
   try:
       mountnas = Command("dims.nas.mount")
       mountnas()
   except Exception as exception_:
       print u"[!] Exception: {0}".format(exception_)
       cleanexit(1)


#def mount_cfg(sshfs_, cfg_):
#    if os.path.exists("{}/.mounted".format(cfg_)):
#        if mem.options.verbose:
#            print "[+] {0} already mounted".format(cfg_)
#        return True
#    if not os.path.exists(cfg_):
#        if mem.options.verbose:
#            print "[+] Creating mount point {0}".format(cfg_)
#        try:
#            mkdir(cfg_)
#        except Exception as exception_:
#            print u"[!] Exception: {0}".format(exception_)
#            print "[!] Can't create mount point {0}".format(cfg_)
#    try:
#        sshfs(SSHFS, cfg_)
#    except Exception as exception_:
#        print u"[!] Exception: {0}".format(exception_)
#        print "[!] Can't sshfs mount {0} on {1}".format(sshfs_, cfg_)
#        cleanexit(1)


def is_mounted(dev_):
    """
    Is the block device containing dev_ currently mounted?

    :param dev_:
    :return:
    """
    return get_mount_point(dev_) is not None


# May abandon this function...
def find_device_bystring(string_):
    """
    Look for device mounted by searching mount output for string_.

    :param string_:
    :return:
    """
    if string_ is None:
        return None, None
    for line in grep(mount(), "udisks", _ok_code=[0, 1], _iter=True):
        words = line.split()
        w1_ = words[0]
        w2_ = words[2]
        if string_ in w2_:
            if mem.options.debug:
                print "[+] find_device_by_string found {0} mounted on {1}".format(w1_, w2_)
            return w1_, w2_
    return None, None


def get_device_mount(dev_):
    """
    Return mount point for specified device.
    :param string_:
    :return:
    """
    if dev_ is None:
        return None, None
    for line in mount(_iter=True):
        if dev_ in line:
            dev_mount_ = line.split()[2]
            if mem.options.debug:
                print "[+] get_device_mount found {0} mounted on {1}".format(dev_, dev_mount_)
            return dev_mount_
    return None


def get_label_device(label_):
    """
    Return the actual device path for a labelled device.

    :param label_:
    :return: String containing path to labelled device or None
    """
    lpath="/dev/disk/by-label/{0}".format(label_)
    if os.path.islink(lpath):
        return os.path.realpath(lpath)
    else:
        return None


def device_exists(dev_):
    """Verify if udisksctl knows about this device or not."""
    for line in sudo.udisksctl("dump", _iter=True):
        if mem.options.debug:
            print "[+] udisksctl returned line: {0}".format(line.strip())
        if dev_ in line:
            return True
    return False


def mount_device(dev_):
    """
    Validate device mount point for installation USB.

    :param dev_:
    :return:
    """
    part1_ = dev_ + "1"
    part2_ = dev_ + "2"
    block_device1_ = get_block_device(part1_)
    if block_device1_ is None:
        print "[!] No udisks block device found for {0}".format(part1_)
        cleanexit(1)
    block_device2_ = get_block_device(part2_)
    if block_device2_ is None:
        print "[!] No udisks block device found for {0}".format(part2_)
        cleanexit(1)
    if not is_mounted(block_device1_):
        try:
            udisksctl("mount", "-p", block_device1_)
        except Exception as exception_:
            print u"[!] Exception: {0}".format(exception_)
            print "[!] Failed to mount {0} with udisksctl".format(block_device1_)
            cleanexit(1)
        if mem.options.verbose:
            print "[+] Mounted {0}".format(block_device1_)
    if not is_mounted(block_device2_):
        try:
            udisksctl("mount", "-p", block_device2_)
        except Exception as exception_:
            print u"[!] Exception: {0}".format(exception_)
            print "[!] Failed to mount {0} with udisksctl".format(block_device2_)
            cleanexit(1)
        if mem.options.verbose:
            print "[+] Mounted {0}".format(block_device2_)
    return True


def unmount_device(dev_):
    """
    Unmount device using udisksctl.

    :param dev_:
    :return:
    """
    part1_ = dev_ + "1"
    part2_ = dev_ + "2"
    if is_mounted(part2_):
        block_device_ = get_block_device(part2_)
        try:
            sudo.udisksctl("unmount", "-p", block_device_)
        except Exception as exception_:
            print u"[!] Exception: {0}".format(exception_)
            print "[!] Failed to unmount {0} with udisksctl".format(part2_)
            cleanexit(1)
        if mem.options.verbose:
            print "[+] Unmounted {0}".format(part2_)
    else:
        if mem.options.verbose or mem.options.debug:
            print "[+] Partition {0} is not mounted".format(part2_)
    if is_mounted(part1_):
        block_device_ = get_block_device(part1_)
        try:
            udisksctl("unmount", "-p", block_device_)
        except Exception as exception_:
            print u"[!] Exception: {0}".format(exception_)
            print "[!] Failed to unmount {0} with udisksctl".format(part1_)
            cleanexit(1)
        if mem.options.verbose:
            print "[+] Unmounted {0}".format(part1_)
    else:
        if mem.options.verbose or mem.options.debug:
            print "[+] Partition {0} is not mounted".format(part1_)
    return True

# To disable automounting:
# gconftool-2 --type bool --set /apps/nautilus/preferences/media_automount False

def copy_ssh_keys(ssh_keys_path_, device_mount_):
    """
    Copy SSH keyset (entire directory) to directory in mounted casper-rw file system.

    :param ssh_keys_path_:
    :param device_mount_:
    :return:
    """
    dest_ = "{0}/{1}".format(device_mount_, os.path.basename(ssh_keys_path_))
    if mem.options.verbose:
        print "[+] Copying SSH key(s) from {0} to {1})".format(ssh_keys_path_, dest_)
    if not os.path.exists(dest_):
        try:
            sudo.mkdir(dest_)
        except Exception as exception_:
            print u"[!] Exception: {0}".format(exception_)
            print "[!] Can't create directory {0}".format(dest_)
    # Using SSHFS causes problems for root/user interaction. Copy everything
    # to /tmp first, then use sudo to copy to casper-rw.
    tmp_ = "/tmp/{0}".format(os.path.split(dest_)[1])
    if tmp_ == "/tmp/":
        print "[!] Refusing to possibly delete /tmp/"
        sys.exit(1)
    rsync("-a",
          "--delete",
          "{0}/".format(ssh_keys_path_),
          "{0}/".format(tmp_))
    try:
        sudo.rsync("-a",
                  "--delete",
                   "--no-owner",
                   "{0}/".format(tmp_),
                   "{0}/".format(dest_))
        rm("-rf", tmp_)
    except Exception as exception_:
        print u"[!] Exception: {0}".format(exception_)
        print "[!] Failed: copy_ssh_host_keys()"
        rm("-rf", tmp_)
        cleanexit(1)


def copy_openvpn_cert(openvpn_cert_path_, device_mount_):
    """Copy OpenVPN certificate(s) (entire directory) to directory in mounted casper-rw file system."""
    dest_ = "{0}/{1}".format(device_mount_, os.path.basename(openvpn_cert_path_))
    if mem.options.verbose:
        print "[+] Copying OpenVPN cert(s) from {0} to {1})".format(openvpn_cert_path_, dest_)
    if not os.path.exists(dest_):
        try:
            sudo.mkdir(dest_)
        except Exception as exception_:
            print u"[!] Exception: {0}".format(exception_)
            print "[!] Can't create directory {0}".format(dest_)
    # Using SSHFS causes problems for root/user interaction. Copy everything
    # to /tmp first, then use sudo to copy to casper-rw.
    tmp_ = "/tmp/{0}".format(os.path.split(dest_)[1])
    if tmp_ == "/tmp/":
        print "[!] Refusing to possibly delete /tmp/"
        sys.exit(1)
    rsync("-a",
          "--delete",
          "{0}/".format(openvpn_cert_path_),
          "{0}/".format(tmp_))
    try:
        sudo.rsync("-a",
                  "--delete",
                   "--no-owner",
                   "{0}/".format(tmp_),
                   "{0}/".format(dest_))
        rm("-rf", tmp_)
    except Exception as exception_:
        print u"[!] Exception: {0}".format(exception_)
        print "[!] Failed: copy_openvpn_cert()"
        rm("-rf", tmp_)
        cleanexit(1)


def mount_casper():
    """Create temporary casper mount point and mount casper read/write file."""
    if not os.path.exists(mem.casper_rw_src):
        print "[!] Cannot find casper-rw source {0}".format(mem.casper_rw_src)
        cleanexit(1)
    if not os.path.exists(mem.casper_rw_mp):
        if mem.options.verbose:
            print "[+] Creating mount point \"{0}\"".format(mem.casper_rw_mp)
        sudo.mkdir(mem.casper_rw_mp)

    if mem.options.verbose:
        print "[+] Mounting {0} to {1}".format(mem.casper_rw_src, mem.casper_rw_mp)
    try:
        sudo.mount("-o", "loop,rw", "-t", "ext2",
                   mem.casper_rw_src, mem.casper_rw_mp,
                   _out=sys.stdout, _err=sys.stderr)
    except Exception as exception_:
        print u"[!] Exception: {0}".format(exception_)
        cleanexit(1)
    if mem.options.debug:
        ls("-lat", mem.casper_rw_mp, _out=sys.stdout)


def unmount_casper():
    """Unmount casper-rw file system (as root)."""
    if mem.options.verbose:
        print "[+] Unmounting {0}".format(mem.casper_rw_mp)
    try:
        # Command("sudo", "umount", casper_rw_mp, _ok_code=[0,1,2])
        sudo.umount(mem.casper_rw_mp)
    except Exception as exception_:
        print u"[!] Exception: {0}".format(exception_)
        print "[!] Failed to unmount {0}".format(mem.casper_rw_mp)


def remove_casper_mountpoint():
    """Remove the temporary casper-rw mount point."""
    if mem.options.verbose:
        print "[+] Removing {0} mount point".format(mem.casper_rw_mp)
    if os.path.exists(mem.casper_rw_mp):
        try:
            # Command("sudo", "rmdir", casper_rw_mp, _ok_code=[0, 1])
            sudo.rmdir(mem.casper_rw_mp, _ok_code=[0, 1])
        except Exception as exception_:
            print u"[!] Exception: {0}".format(exception_)
            print "[!] Failed to rmdir {0}".format(mem.casper_rw_mp)

def write_usb_from_1():
    """
    Write USB drive from mem.options.imagefile using dd

    :return:
    """
    if mem.options.imagefile is None:
        print "[!] Must specify --file with name for USB image"
        sys.exit(1)
    if mem.options.device is None or mem.options.imagefile is None:
        print "[!] Must specify both --device and --write-usb-from"
        sys.exit(1)
    if not os.path.exists("/dev/{0}".format(mem.options.device)):
        print "[!] Device file /dev/{0} does not exist".format(mem.options.device)
        sys.exit(1)
    try:
        f_ = open(mem.options.imagefile, "r")
        f_.close()
    except Exception as exception_:
        print u"[!] Exception: {0}".format(exception_)
        print "[!] Cannot read from {0}".format(mem.options.imagefile)
        sys.exit(1)
        # Unmount patition if it was automounted already before writing to drive.
    device_, device_mount_ = find_device_bystring(mem.options.device)
    if device_ is not None:
        unmount_device(device_)
    if mem.options.verbose:
        verbose_ = ""
    else:
        verbose_ = "2>&1 1>/dev/null"
    t1_ = time.time()
    if mem.options.verbose:
        print "[+] Writing {0} to USB drive on /dev/{1}".format(mem.options.imagefile, mem.options.device)
    if mem.options.debug:
        print "[+] Block size {0}".format(mem.options.blocksize)
    try:
        # Decompress file and write to device file.
        # Produces "dd: error writing ‘/dev/sdb’: No space left on device" that needs
        # to be ignored/suppressed as it is not really an error. (Happens when you
        # write the full device' worth of data back to the device.
        retval_ = os.system("{0} -dc {1} | sudo -b dd bs={4} of=/dev/{2} {3}".format(
            mem.COMPRESSUTIL, mem.options.imagefile, mem.options.device, verbose_, mem.BLOCKSIZE))
        if retval_ != 0:
            print "[!] Failed to write {0} to {1}".format(mem.options.imagefile, mem.options.device)
    except Exception as exception_:
        print u"[!] Exception: {0}".format(exception_)
        print "[!] Failed to write {0} to {1}".format(mem.options.imagefile, mem.options.device)
        sys.exit(1)
    t2_ = time.time()
    if mem.options.verbose:
        print "[+] Wrote {0} to USB drive on {1} in {2} seconds".format(
            mem.options.imagefile, mem.options.device,
            str(datetime.timedelta(seconds=(t2_ - t1_))))
        # if mem.options.verbose:
        #    print "[+] Re-mounting {0}".format(mem.options.device)
        # if not mount_device(mem.options.device):
        #    print "[!] Failed to mount {0}".format(device_)
        #    sys.exit(1)

def write_usb_from_2():
    """
    Write USB drive from mem.options.imagefile using raw I/O

    :return:
    """
    if mem.options.imagefile is None:
        print "[!] Must specify --file with name for USB image"
        sys.exit(1)
    if mem.options.device is None or mem.options.imagefile is None:
        print "[!] Must specify both --device and --write-usb-from"
        sys.exit(1)
    if not os.path.exists("/dev/{0}".format(mem.options.device)):
        print "[!] Device file /dev/{0} does not exist".format(mem.options.device)
        sys.exit(1)
    if is_mounted(mem.device_path_):
        unmount_device(mem.device_path_)
    t1_ = time.time()
    if mem.options.verbose:
        print "[+] Writing {0} to USB drive on {1}".format(mem.options.imagefile, mem.device_path_)
    if mem.options.debug:
        print "[+] Block size {0}".format(mem.options.blocksize)
    with open("/dev/{0}".format(mem.options.device), "rb+") as rawout,\
            bz2.open(mem.options.imagefile) as bz2in:
            shutil.copyfileobj(bz2in, rawout, mem.options.blocksize)
    t2_ = time.time()
    if mem.options.verbose:
        print "[+] Wrote {0} to USB drive on {1} in {2} seconds".format(
            mem.options.device, mem.options.imagefile,
            str(datetime.timedelta(seconds=(t2_ - t1_))))


def main(argv=sys.argv[1:]):
    # Begin script.
    mem._progname = sys.argv[0]
    mem._shortname, mem._extension = os.path.splitext(mem._progname)

    parser = OptionParser(usage=mem.USAGESTRING % mem.__dict__)
    parser.add_option("-d", "--debug",
                      action="store_true",
                      dest="debug",
                      default=False,
                      help="Enable debugging.")
    #parser.add_option("-c", "--cfg-path",
    #                  action="store",
    #                  dest="cfgpath",
    #                  default=mem.CFGPATH,
    #                  help="Device file for mounting USB [default: {0}]".format(mem.CFGPATH))
    parser.add_option("-D", "--device",
                      action="store",
                      dest="device",
                      default=mem.DEFAULTDEVICE,
                      help="Device file for mounting USB. [default: {0}]".format(mem.DEFAULTDEVICE))
    parser.add_option("-H", "--hostname",
                      action="store",
                      dest="hostname",
                      default=mem.HOSTNAME,
                      metavar="HOSTNAME",
                      help="Hostname of system to install. [default {0}]".format(mem.HOSTNAME))
    parser.add_option("-l", "--usblabel",
                      action="store",
                      dest="usblabel",
                      default=mem.USBLABEL,
                      metavar="USBLABEL",
                      help="USB device label. [default: {0}]".format(mem.USBLABEL))
    parser.add_option("--distro-version",
                      action="store",
                      dest="distro_version",
                      default=mem.DISTROVERSION,
                      metavar="DISTROVERSION",
                      help="Distribution version. [default: {0}]".format(mem.DISTROVERSION))
    parser.add_option("--base-configs-dir",
                      action="store",
                      dest="base_configs_dir",
                      default=mem.CFGPATH,
                      metavar="BASE_CONFIGS_DIR",
                      help="Base directory for configuration files. [default: {0}]".format(mem.CFGPATH))
    parser.add_option("-u", "--usage",
                      action="store_true",
                      dest="usage",
                      default=False,
                      help="Print usage information.")
    parser.add_option("-v", "--verbose",
                      action="store_true",
                      dest="verbose",
                      default=False,
                      help="Be verbose (on stdout) about what is happening.")
    parser.add_option("-V", "--version",
                      action="store_true",
                      dest="version",
                      default=False,
                      help="Print version and exit.")

    group = OptionGroup(parser, "Development Options",
                        "Caution: use these options at your own risk.")
    group.add_option("--find-device",
                     action="store_true",
                     dest="find_device",
                     default=False,
                     help="Attempt to find USB device actively mounted and exit.")
    group.add_option("--empty-casper",
                     action="store_true",
                     dest="empty_casper",
                     default=False,
                     help="Empty out all contents (except lost+found) from casper-rw and exit.")
    group.add_option("--ls-casper",
                     action="store_true",
                     dest="ls_casper",
                     default=False,
                     help="Just list contents of casper-rw file system.")
    group.add_option("--label-casper",
                     action="store_true",
                     dest="label_casper",
                     default=False,
                     help="Put --usblabel into casper-rw and exit.")
    group.add_option("--mount-casper",
                     action="store_true",
                     dest="mount_casper",
                     default=False,
                     help="Mount casper-rw in cwd and exit.")
    group.add_option("--unmount-casper",
                     action="store_true",
                     dest="unmount_casper",
                     default=False,
                     help="Unmount casper-rw and exit.")
    group.add_option("--mount-usb",
                     action="store_true",
                     dest="mount_usb",
                     default=False,
                     help="Mount DIMS install USB ({0}) and exit. [default: False]".format(
                         mem.DEFAULTDEVICE))
    group.add_option("--unmount-usb",
                     action="store_true",
                     dest="unmount_usb",
                     default=False,
                     help="Unmount DIMS install USB ({0}) and exit. [default: False]".format(
                         mem.DEFAULTDEVICE))
    group.add_option("--read-usb-into",
                     action="store_true",
                     dest="read_usb_into",
                     default=False,
                     help="Read USB drive into file. [default: False]")
    group.add_option("--write-usb-from",
                     action="store_true",
                     dest="write_usb_from",
                     default=False,
                     help="Write USB drive from file. [default: False]")
    group.add_option("-f", "--imagefile",
                      action="store",
                      dest="imagefile",
                      default="ubuntu-{0}-install{1}".format(
                          mem.DISTROVERSION, mem.COMPRESSEXT),
                      help=("File name to use for storing compressed USB image. "
                            "[default: ubuntu-{0}-install{1}]".format(
                          mem.DISTROVERSION, mem.COMPRESSEXT)
                      ))
    group.add_option("--block-size",
                     action="store",
                     dest="blocksize",
                     default=mem.BLOCKSIZE,
                     metavar="BLOCK_SIZE",
                     help="Block size to use for 'dd' read/write. [default: {0}]".format(
                         mem.BLOCKSIZE))
    parser.add_option_group(group)

    (mem.options, mem.args) = parser.parse_args()

    if mem.options.version:
        print "{0} {1}".format(
        os.path.basename(sys.argv[0]),
        VERSION
        )
        sys.exit(0)

    mem.DISTROVERSION=mem.options.distro_version

    if mem.options.usage:
        print mem.USAGESTRING % mem.__dict__
        print ""
        print mem.EXTRAUSAGE % mem.__dict__
        sys.exit(0)

    if mem.options.debug or mem.options.verbose:
        print "[+] {0}".format(mem._progname)

    # Look to see if a partition is mounted that has the specific label
    # required for a DIMS install USB. Any option that needs it should
    # force an error exit if not found.
    mem.device_path_ = get_label_device(mem.options.usblabel)
    if mem.device_path_ is None:
        print "[+] No device labelled '{0}' found".format(mem.options.usblabel)
        if (mem.options.find_device or
            mem.options.empty_casper or
            mem.options.ls_casper or
            mem.options.label_casper or
            mem.options.mount_casper or
            mem.options.mount_usb or
            mem.options.read_usb_into or
            mem.options.write_usb_from):
                exit(1)
    else:
        if mem.options.debug:
            print "[+] Found device labelled '{0}' on {1}".format(
                mem.options.usblabel, mem.device_path_)

    # Validate device before building any variables that
    # depend on it.
    if mem.options.device is None:
        print "[+] No device specified".format(mem.options.device)
        sys.exit(1)

    if mem.options.find_device:
        if mem.device_path_ is not None:
            print "[+] Partition with label {0} is found on {1}".format(
                mem.options.usblabel, mem.device_path_)
            sys.exit(0)
        if mem.options.usblabel is not None:
            device_, mem.device_mount_ = find_device_bystring(mem.options.usblabel)
            if device_ is not None:
                # Strip off
                basedevice_ = device_[:-1]
                block_device_ = get_block_device(device_)
                print "[+] Partition {0} is mounted on {1}".format(device_, mem.device_mount_)
                print "[+] Guessing base device file is {0} and udisksctl uses {1}".format(
                    basedevice_, block_device_)
                sys.exit(0)
            else:
                print "[+] Cannot find device"
                sys.exit(0)

    # # Writing a configuration to a formatted USB drive requires
    # # that the device IS MOUNTED. If it isn't, try to mount it.
    # if not is_mounted(mem.options.device) and not \
    #         (mem.options.write_usb_from or mem.options.read_usb_into):
    #     if mem.options.verbose:
    #         print "[+] Device {0} is not mounted".format(mem.options.device)
    #     if not mount_device(mem.options.device):
    #         sys.exit(0)

    if mem.options.mount_usb:
        if mem.device_path_ is not None and get_device_mount(mem.device_path_) is not None:
            print "[+] Partition {0} is already mounted".format(mem.device_path_)
            sys.exit(1)
        if not mount_device(mem.options.device):
            print "[!] Failed to mount {0}".format(mem.options.device)
            sys.exit(1)
        sys.exit(0)

    if mem.options.unmount_usb:
        if mem.device_path_ is None:
            print "[+] Device {0} is not mounted".format(mem.options.device)
            sys.exit(1)
        if not unmount_device(mem.options.device):
            print "[!] Failed to unmount {0}".format(mem.options.device)
            sys.exit(1)
        sys.exit(0)

    # Set globals for directories and mount points.
    mem.hostpath_ = "{0}/{1}".format(mem.CFGPATH, mem.options.hostname)
    mem.ssh_host_keys_path_ = "{0}/ssh-host-keys".format(mem.hostpath_)
    mem.ssh_user_keys_path_ = "{0}/ssh-user-keys".format(mem.hostpath_)
    mem.openvpn_cert_path_ = "{0}/openvpn-cert".format(mem.hostpath_)

    mem.device_mount_ = get_mount_point(mem.device_path_)
    if mem.device_mount_ is None:
        print "[+] Device {0} is not mounted".format(mem.options.device)
        sys.exit(1)
    mem.syslinux_ = "{0}/syslinux".format(mem.device_mount_)
    mem.casper_rw_src = "{0}/casper-rw".format(mem.device_mount_)
    mem.casper_rw_mp = "{0}/casper-rw".format(os.getcwd())

    if mem.options.read_usb_into:
        if mem.options.imagefile is None:
            print "[!] Must specify --imagefile with name for USB image"
            sys.exit(1)
        if mem.options.device is None or mem.options.read_usb_into is None:
            print "[!] Must specify both --device and --read-usb-into"
            sys.exit(1)
        # Make sure file name ends with correct extension
        if mem.options.imagefile[-len(mem.COMPRESSEXT):] != mem.COMPRESSEXT:
            mem.options.imagefile += mem.COMPRESSEXT
        try:
            f_ = open(mem.options.imagefile, "w")
            f_.close()
        except Exception as exception_:
            print u"[!] Exception: {0}".format(exception_)
            print "[!] Cannot write to {0}".format(mem.options.imagefile)
            sys.exit(1)
        # Unmount patition if it was automounted already before reading from drive.
        device_, device_mount_ = find_device_bystring(mem.options.usblabel)
        if device_ is not None:
            unmount_device(device_)
        t1_ = time.time()
        if mem.options.verbose:
            print "[+] Reading USB drive on {0} into {1}".format(
                mem.options.device, mem.options.imagefile)
        if mem.options.debug:
            print "[+] Block size for dd: {0}".format(mem.options.blocksize)
        try:
            if mem.options.verbose:
                verbose_ = ""
            else:
                verbose_ = "2>&1 1>/dev/null"
            retval_ = os.system("sudo -b dd bs={4} if=/dev/{0} {3} | {2} | dd bs={4} of={1} {3}".format(
                mem.options.device, mem.options.imagefile, mem.COMPRESSUTIL, verbose_, mem.BLOCKSIZE))
            if retval_ != 0:
                print "[!] Failed to read {0} into {1}".format(
                    mem.options.device, mem.options.imagefile)
        except Exception as exception_:
            print u"[!] Exception: {0}".format(exception_)
            print "[!] Failed to read {0} into {1}".format(
                mem.options.device, mem.options.imagefile)
            sys.exit(1)
        t2_ = time.time()
        if mem.options.verbose:
            print "[+] Finished writing {0} in {1} seconds".format(
                mem.options.imagefile, str(datetime.timedelta(seconds=(t2_-t1_))))
        sys.exit(0)

    if mem.options.write_usb_from:
        write_usb_from_1()
        sys.exit(0)
        # if mem.options.imagefile is None:
        #     print "[!] Must specify --file with name for USB image"
        #     sys.exit(1)
        # if mem.options.device is None or mem.options.imagefile is None:
        #     print "[!] Must specify both --device and --write-usb-from"
        #     sys.exit(1)
        # if not os.path.exists("/dev/{0}".format(mem.options.device)):
        #     print "[!] Device file /dev/{0} does not exist".format(mem.options.device)
        #     sys.exit(1)
        # try:
        #     f_ = open(mem.options.imagefile, "r")
        #     f_.close()
        # except Exception as exception_:
        #     print u"[!] Exception: {0}".format(exception_)
        #     print "[!] Cannot read from {0}".format(mem.options.imagefile)
        #     sys.exit(1)
        # # Unmount patition if it was automounted already before writing to drive.
        # device_, device_mount_ = find_device_bystring(mem.options.device)
        # if device_ is not None:
        #     unmount_device(device_)
        # if mem.options.verbose:
        #     verbose_ = ""
        # else:
        #     verbose_ = "2>&1 1>/dev/null"
        # t1_ = time.time()
        # if mem.options.verbose:
        #     print "[+] Writing {0} to USB drive on {1}".format(mem.options.imagefile, mem.options.device)
        # if mem.options.debug:
        #     print "[+] Block size {0}".format(mem.options.blocksize)
        # try:
        #     # Decompress file and write to device file.
        #     # Produces "dd: error writing ‘/dev/sdb’: No space left on device" that needs
        #     # to be ignored/suppressed as it is not really an error. (Happens when you
        #     # write the full device' worth of data back to the device.
        #     retval_ = os.system("{0} -dc {1} | sudo -b dd bs={4} of=/dev/{2} {3}".format(
        #         mem.COMPRESSUTIL, mem.options.imagefile, mem.options.device, verbose_, mem.BLOCKSIZE))
        #     if retval_ != 0:
        #         print "[!] Failed to write {0} to {1}".format(mem.options.imagefile, mem.options.device)
        # except Exception as exception_:
        #     print u"[!] Exception: {0}".format(exception_)
        #     print "[!] Failed to write {0} to {1}".format(mem.options.imagefile, mem.options.device)
        #     sys.exit(1)
        # t2_ = time.time()
        # if mem.options.verbose:
        #     print "[+] Wrote {0} to USB drive on {1} in {2} seconds".format(
        #         mem.options.device, mem.options.imagefile,
        #         str(datetime.timedelta(seconds=(t2_-t1_))))
        # #if mem.options.verbose:
        # #    print "[+] Re-mounting {0}".format(mem.options.device)
        # #if not mount_device(mem.options.device):
        # #    print "[!] Failed to mount {0}".format(device_)
        # #    sys.exit(1)
        # sys.exit(0)

    # Process casper related mem.options
    if mem.options.mount_casper:
        mount_casper()
        sys.exit(0)

    if mem.options.unmount_casper:
        unmount_casper()
        remove_casper_mountpoint()
        sys.exit(0)

    if mem.options.ls_casper:
        mount_casper()
        # Show what is in casper-rw/
        print "[+] Contents of {0}:".format(mem.casper_rw_mp)
        tree("-pu", mem.casper_rw_mp, _out=sys.stdout)
        unmount_casper()
        remove_casper_mountpoint()
        sys.exit(0)

    if mem.options.empty_casper:
        mount_casper()
        # Empty out casper-rw/
        if mem.options.verbose:
            print "[+] Emptying out contents of {0}".format(mem.casper_rw_mp)
        try:
            retval_ = os.system(
                "sudo rm -rf {0}/ssh-host-keys {0}/ssh-user-keys {0}/openvpn-cert".format(
                    mem.casper_rw_mp))
            if retval_ != 0:
                print "[!] Failed to empty {0}".format(
                    mem.casper_rw_mp)
        except Exception as exception_:
            print u"[!] Exception: {0}".format(exception_)
            print "[!] Could not empty contents of {0}".format(mem.casper_rw_mp)
        unmount_casper()
        remove_casper_mountpoint()
        sys.exit(0)

    if mem.options.label_casper:
        # Put --usblabel into casper-rw
        if mem.options.usblabel is None:
            print "[!] Must specify --usblabel with --label-casper"
            sys.exit(1)
        label_ = "{0}/{1}".format(mem.casper_rw_mp, mem.options.usblabel)
        mount_casper()
        try:
            sudo.touch(label_)
        except Exception as exception_:
            print u"[!] Exception: {0}".format(exception_)
            print "[!] Could not create {0}".format(label_)
        unmount_casper()
        remove_casper_mountpoint()
        sys.exit(0)


    # Mount required file systems.
#    if not is_mounted(mem.device_path_):
#        mount_device(mem.device_path_)
    mount_casper()
    #mount_cfg(SSHFS, mem.options.cfgpath)
    mount_nas()

    if not os.path.exists(mem.options.base_configs_dir):
        print "[!] Can't find base configuration directory {0}".format(mem.options.base_configs_dir)
        cleanexit(1)

    if not os.path.exists(mem.hostpath_):
        print "[!] Can't find directory with data for {0} ({1})".format(mem.options.hostname, mem.hostpath_)
        cleanexit(1)

    if not os.path.exists(mem.ssh_host_keys_path_):
        print "[!] Cannot find SSH key data {0}".format(mem.ssh_host_keys_path_)
        cleanexit(1)

    if not os.path.exists(mem.ssh_user_keys_path_):
        print "[!] Cannot find SSH key data {0}".format(mem.ssh_user_keys_path_)
        cleanexit(1)


    # Install modified preseed file and associated config files to
    # control installation.
    installfile("preseed.cfg", mem.device_mount_)
    installfile("ks.cfg", mem.device_mount_)
    installfile("txt.cfg", mem.syslinux_)
    installfile("syslinux.cfg", mem.syslinux_)

    # Copy user- and host-specific SSH keys and OpenVPN cert.
    copy_ssh_keys(mem.ssh_host_keys_path_, mem.casper_rw_mp)
    copy_ssh_keys(mem.ssh_user_keys_path_, mem.casper_rw_mp)
    copy_openvpn_cert(mem.openvpn_cert_path_, mem.casper_rw_mp)

    # Go away.
    cleanexit(0)

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
