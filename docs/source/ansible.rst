.. _ansibleintro:

Ansible and Configuration Management
====================================

`Ansible`_ is an open source tool that can be used to automate system
administration tasks related to installation, configuration, account setup, and
anything else required to manage system configurations across a large number of
computers.

While it is possible to manually install and configure a hand-full of
computer systems that do not change very often, this kind of system
deployment and system administration quickly becomes a limiting factor. It
does not scale very well, for one, and makes it very difficult to change
or replicate. You may need to move hardware from one data center to another,
requiring reconfiguration of both hosts and dozens of VM guests. You may
need to move from one Linux distribution to another. You may wish to add
another continuous integration build cluster to support another operating
system major/minor version, or a new processor architecture like ARM.
Even if the number of hosts is small, having the knowledge of how the
systems were built and configured in the head of just one person (who
may go on vacation, or permanently leave the project) increases the
risk of total disruption of the project in the event of an outage.

.. tip::

   If you are not familiar with Ansible, take some time to look at
   the Ansible `Get Started`_ page, and/or watch the following
   video series:

       + `19 Minutes With Ansible (Part 1/4)`_, Justin Weissig, sysadmincasts.com, January 13, 2015
       + `Learning Ansible with Vagrant (Part 2/4)`_, Justin Weissig, sysadmincasts.com, March 19, 2015
       + `Configuration Management with Ansible (Part 3/4)`_, Justin Weissig, sysadmincasts.com, March 26, 2015
       + `Zero-downtime Deployment with Ansible (Part 4/4)`_, Justin Weissig, sysadmincasts.com, April 2, 2015

   Many more references can be found at <https://staff.washington.edu/dittrich/home/unix.html#ansible>

..

.. _Get Started: https://www.ansible.com/get-started
.. _19 Minutes With Ansible (Part 1/4): https://sysadmincasts.com/episodes/43-19-minutes-with-ansible-part-1-4
.. _Learning Ansible with Vagrant (Part 2/4): https://sysadmincasts.com/episodes/45-learning-ansible-with-vagrant-part-2-4
.. _Configuration Management with Ansible (Part 3/4): https://sysadmincasts.com/episodes/46-configuration-management-with-ansible-part-3-4
.. _Zero-downtime Deployment with Ansible (Part 4/4): https://sysadmincasts.com/episodes/47-zero-downtime-deployments-with-ansible-part-4-4
.. _Ansible section: https://staff.washington.edu/dittrich/home/unix.html#ansible


.. _ansiblefundamentals:

Ansible fundamentals
--------------------

Ansible allows you to document all of the steps necessary to perform the
required tasks, organize sets of computers on which those steps should
be performed, and then allow you to perform those tasks precisely and
consistently across all of those hosts.  Figure :ref:`ansibleOverview`
(source: `19 Minutes with Ansible (Part 1/4)`_ ) illustrates this process.

.. _ansibleOverview:

.. figure:: images/ansible-overview.png
    :width: 90%
    :align: center

    Ansible Overview

..

At the center of the left side of Figure :ref:`ansibleOverview` is the
**Ansible Management Node** (also called by some a **Control** node). This
figure depicts the *push model* for using Ansible, where a Control machine
holds the playbooks and inventory files necessary to drive Ansible, and that
Control machine reaches out to *target* hosts on which the actions take place.
Another way to use Ansible is by using a ``localhost`` connection for the
Control machine to also be the Target machine (in which case the actions
Ansible performs are done to the same computer on which Ansible is running.)

A set of hosts can be specified with an *inventory*. Ansible supports two
styles for static inventories, an INI format style, and a YAML format style.
The INI style format is known as a ``hosts`` file, by default stored in a file
named ``/etc/ansible/hosts``.

An INI style inventory that implements the example above could look like this:

.. code-block:: yaml

    [web]
    10.0.15.21
    10.0.15.22
    10.0.15.23
    10.0.15.24
    10.0.15.25
    10.0.15.26

..

.. note::

    The ``-i`` flag can be used to specify the inventory file to use,
    rather than always having to over-write the file ``/etc/ansible/hosts``.
    Alternatively, it can be specified in an ``ansible.cfg`` file,
    typically found in ``/etc/ansible/ansible.cfg`` for the global
    file. This is covered more in Section :ref:`ansibleconfiguration`.)

..

Ansible has two main command line interface programs you can use. The
first is just ``ansible`` and it allows you to run individual modules
against a set of hosts (also known as "running a play"). Here is a
very simple example of running the ``ping`` module against every
host in the ``all`` group in the ``development`` inventory shown
above:

.. code-block:: none

    $ ansible -i $GIT/ansible-playbooks/inventory/development all -m ping
    floyd2-p.devops.develop | success >> {
        "changed": false,
        "ping": "pong"
    }

    hub.devops.develop | success >> {
        "changed": false,
        "ping": "pong"
    }

    u12-dev-svr-1.devops.develop | success >> {
        "changed": false,
        "ping": "pong"
    }

    linda-vm1.devops.develop | success >> {
        "changed": false,
        "ping": "pong"
    }

    u12-dev-ws-1.devops.develop | success >> {
        "changed": false,
        "ping": "pong"
    }

..

Using the ``command`` module, and passing in arguments, you can run arbitrary
commands on hosts as a form of distributed SSH:

.. code-block:: none

    $ ansible -i $GIT/ansible-playbooks/inventory/development all -m command -a /usr/bin/uptime
    floyd2-p.devops.develop | success | rc=0 >>
     01:02:52 up 22 days,  7:27,  1 user,  load average: 0.04, 0.12, 1.11

    u12-dev-ws-1.devops.develop | success | rc=0 >>
     01:02:52 up 148 days, 14:58,  1 user,  load average: 0.00, 0.01, 0.05

    u12-dev-svr-1.devops.develop | success | rc=0 >>
     01:02:45 up 144 days, 17:53,  1 user,  load average: 0.03, 0.05, 0.05

    hub.devops.develop | success | rc=0 >>
     09:02:52 up 130 days, 15:14,  1 user,  load average: 0.00, 0.01, 0.05

    linda-vm1.devops.develop | success | rc=0 >>
     01:02:53 up 148 days, 14:58,  1 user,  load average: 0.00, 0.01, 0.05

..

The other principal command line program is ``ansible-playbook``, which is used
to run more complex playbooks made up of multiple sequentially organized plays
with all kinds of complex logic and other organizational techniques to manage
complex processes.  Examples of writing and running playbooks are found in the
rest of this document.

.. note::

   Ansible also has a Python API that can be used to embed Ansible
   functionality into other programs, or to write your own modules to perform
   tasks.  This is explained in the video `Alejandro Guirao Rodríguez -
   Extending and embedding Ansible with Python`_ from EuroPython 2015.

..

.. caution::

   Always remember that Ansible is used in a distributed system manner,
   meaning that it has two execution contexts:

   (1) it runs with the chosen Python interpreter on the **control** host,
   which creates Python code that is then

   (2) copied to and executed within the context of the **target** host.

   Take another look at Figure :ref:`ansibleOverview` and realize that the
   arrows pointing away from the blue node (the control host) to the many green
   nodes (the targets) implicitly show this context switch.

   This has ramifications for targets that run operating systems like CoreOS
   (that don't have Python installed, and don't have a package manager), and
   for use of modules like ``apt`` that call Python libraries to use operating
   system specific package managers like APT from within Ansible's Python code.

   Since the DIMS project uses Python virtual environments to isolate
   the Python interpreter used by developers from the interpreter used
   by the system (to avoid breaking the system), this means by definition
   there are multiple Python interpreters on DIMS hosts. This requires
   that pay **very close attention** to configuration settings that affect
   the Python interpreter used by Ansible and consiciously do things (and
   test the results of changes carefully to know when a change breaks
   something in Ansible.) The result of changes the Python interpreter used by
   Ansible can be random failures with cryptic error messages like these:

   .. code-block:: none

       Traceback (most recent call last):
         File \"/home/core/.ansible/tmp/ansible-tmp-1462413293.33-173671562381843/file\", line 114, in <module>
           exitcode = invoke_module(module, zipped_mod, ZIPLOADER_PARAMS)
         File \"/home/core/.ansible/tmp/ansible-tmp-1462413293.33-173671562381843/file\", line 28, in invoke_module
           p = subprocess.Popen(['/opt/bin/python', module], env=os.environ, shell=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin=subprocess.PIPE)
         File \"/usr/lib/python2.7/subprocess.py\", line 710, in __init__
           errread, errwrite)
         File \"/usr/lib/python2.7/subprocess.py\", line 1335, in _execute_child
           raise child_exception
       OSError: [Errno 2] No such file or directory

   ..

   .. code-block:: none

       msg: Could not import python modules: apt, apt_pkg. Please install python-apt package.

   ..

   Both of these messages are due to the Python interpreter being used by Ansible
   on the **target** end being set to a non-system Python interpreter that does
   not have the necessary libraries or programs that Ansible needs. In the
   second case, commenters on blogs may say, "But I installed ``python-apt``
   and I still get this message. Why?" Yes, you may have installed the
   ``python-apt`` package like it says, but it was installed into the
   **system** Python interpreter, which is **not** the one that Ansible is
   using if ``ansible_python_interpreter`` or ``$PATH`` would cause Ansible to
   use a different one!

..

.. _Alejandro Guirao Rodríguez - Extending and embedding Ansible with Python: https://www.youtube.com/watch?v=qLoBHbVb0Fw

.. _ansibleVariables:

Variables
---------

Ansible playbooks are general rules and steps for performing actions.
These actions can be selected using logic ("If this is Redhat, do ``A``, but if
it is Ubuntu, do ``B``"), or by using `Jinja templating`_ to apply variables to
a generic template file, resulting in specific contents customized for a given host.

.. _Jinja templating: http://jinja.pocoo.org

Some of these variables (known as "facts") are set by Ansible when it first
starts to run on a target host, while others are defined in files that
accompany playbooks and inventories.  You can see the dictionary of
``ansible_facts`` for a given system using Ansible's ``setup`` module:

.. code-block:: none

    $ ansible -m setup localhost -c local
    localhost | success >> {
        "ansible_facts": {
            "ansible_all_ipv4_addresses": [
                "172.17.0.1",
                "10.88.88.5",
                "192.168.0.100",
                "10.86.86.7"
            ],
            "ansible_all_ipv6_addresses": [
                "fe80::d253:49ff:fed7:9ebd"
            ],
            "ansible_architecture": "x86_64",
            "ansible_bios_date": "01/29/2015",
            "ansible_bios_version": "A13",
            "ansible_cmdline": {
                "BOOT_IMAGE": "/vmlinuz-3.16.0-30-generic",
                "quiet": true,
                "ro": true,
                "root": "/dev/mapper/hostname_vg-root_lv",
                "splash": true,
                "vt.handoff": "7"
            },
            "ansible_date_time": {
                "date": "2016-03-10",
                "day": "10",
                "epoch": "1457653607",
                "hour": "15",
                "iso8601": "2016-03-10T23:46:47Z",
                "iso8601_micro": "2016-03-10T23:46:47.246903Z",
                "minute": "46",
                "month": "03",
                "second": "47",
                "time": "15:46:47",
                "tz": "PST",
                "tz_offset": "-0800",
                "weekday": "Thursday",
                "year": "2016"
            },
            "ansible_default_ipv4": {
                "address": "192.168.0.100",
                "alias": "wlan0",
                "gateway": "192.168.0.1",
                "interface": "wlan0",
                "macaddress": "d0:53:49:d7:9e:bd",
                "mtu": 1500,
                "netmask": "255.255.255.0",
                "network": "192.168.0.0",
                "type": "ether"
            },
            "ansible_default_ipv6": {},
            "ansible_devices": {
                "sda": {
                    "holders": [],
                    "host": "SATA controller: Intel Corporation 8 Series...",
                    "model": "ST1000LM014-1EJ1",
                    "partitions": {
                        "sda1": {
                            "sectors": "997376",
                            "sectorsize": 512,
                            "size": "487.00 MB",
                            "start": "2048"
                        },
                        "sda2": {
                            "sectors": "2",
                            "sectorsize": 512,
                            "size": "1.00 KB",
                            "start": "1001470"
                        },
                        "sda5": {
                            "sectors": "1952522240",
                            "sectorsize": 512,
                            "size": "931.04 GB",
                            "start": "1001472"
                        }
                    },
                    "removable": "0",
                    "rotational": "1",
                    "scheduler_mode": "deadline",
                    "sectors": "1953525168",
                    "sectorsize": "4096",
                    "size": "7.28 TB",
                    "support_discard": "0",
                    "vendor": "ATA"
                },
                "sr0": {
                    "holders": [],
                    "host": "SATA controller: Intel Corporation 8 Series...",
                    "model": "DVD-ROM SU-108GB",
                    "partitions": {},
                    "removable": "1",
                    "rotational": "1",
                    "scheduler_mode": "deadline",
                    "sectors": "2097151",
                    "sectorsize": "512",
                    "size": "1024.00 MB",
                    "support_discard": "0",
                    "vendor": "TSSTcorp"
                }
            },
            "ansible_distribution": "Ubuntu",
            "ansible_distribution_major_version": "14",
            "ansible_distribution_release": "trusty",
            "ansible_distribution_version": "14.04",
            "ansible_docker0": {
                "active": false,
                "device": "docker0",
                "id": "8000.0242a37d17a7",
                "interfaces": [],
                "ipv4": {
                    "address": "172.17.0.1",
                    "netmask": "255.255.0.0",
                    "network": "172.17.0.0"
                },
                "macaddress": "02:42:a3:7d:17:a7",
                "mtu": 1500,
                "promisc": false,
                "stp": false,
                "type": "bridge"
            },
            "ansible_domain": "",
            "ansible_env": {
                "BASE": "bash",
                "BYOBU_ACCENT": "#75507B",
                "BYOBU_BACKEND": "tmux",
                "BYOBU_CHARMAP": "UTF-8",
                "BYOBU_CONFIG_DIR": "/home/dittrich/.byobu",
                "BYOBU_DARK": "#333333",
                "BYOBU_DATE": "%Y-%m-%d ",
                "BYOBU_DISTRO": "Ubuntu",
                "BYOBU_HIGHLIGHT": "#DD4814",
                "BYOBU_LIGHT": "#EEEEEE",
                "BYOBU_PAGER": "sensible-pager",
                "BYOBU_PREFIX": "/usr",
                "BYOBU_PYTHON": "python3",
                "BYOBU_READLINK": "readlink",
                "BYOBU_RUN_DIR": "/dev/shm/byobu-dittrich-0R38I1Mb",
                "BYOBU_SED": "sed",
                "BYOBU_TIME": "%H:%M:%S",
                "BYOBU_TTY": "/dev/pts/24",
                "BYOBU_ULIMIT": "ulimit",
                "BYOBU_WINDOW_NAME": "-",
                "CFG": "/opt/dims/nas/scd",
                "CLUTTER_IM_MODULE": "xim",
                "COLORTERM": "gnome-terminal",
                "COMMAND": "",
                "COMPIZ_BIN_PATH": "/usr/bin/",
                "COMPIZ_CONFIG_PROFILE": "ubuntu",
                "CONSUL_LEADER": "10.142.29.116",
                "DBUS_SESSION_BUS_ADDRESS": "unix:abstract=/tmp/dbus-sYbG5zmdUA",
                "DEBUG": "0",
                "DEFAULTS_PATH": "/usr/share/gconf/ubuntu.default.path",
                "DESKTOP_SESSION": "ubuntu",
                "DIMS": "/opt/dims",
                "DIMS_REV": "unspecified",
                "DIMS_VERSION": "1.6.129 (dims-ci-utils)",
                "DISPLAY": ":0",
                "GDMSESSION": "ubuntu",
                "GDM_LANG": "en_US",
                "GIT": "/home/dittrich/dims/git",
                "GNOME_DESKTOP_SESSION_ID": "this-is-deprecated",
                "GNOME_KEYRING_CONTROL": "/run/user/1004/keyring-7kI0rA",
                "GNOME_KEYRING_PID": "2524",
                "GPG_AGENT_INFO": "/run/user/1004/keyring-7kI0rA/gpg:0:1",
                "GTK_IM_MODULE": "ibus",
                "GTK_MODULES": "overlay-scrollbar:unity-gtk-module",
                "HOME": "/home/dittrich",
                "IM_CONFIG_PHASE": "1",
                "INSTANCE": "",
                "JOB": "dbus",
                "LANG": "C",
                "LANGUAGE": "en_US",
                "LC_CTYPE": "C",
                "LESSCLOSE": "/usr/bin/lesspipe %s %s",
                "LESSOPEN": "| /usr/bin/lesspipe %s",
                "LOGNAME": "dittrich",
                "LS_COLORS": "rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:a....",
                "MANDATORY_PATH": "/usr/share/gconf/ubuntu.mandatory.path",
                "NAS": "/opt/dims/nas",
                "OLDPWD": "/home/dittrich",
                "OS": "Linux",
                "PATH": "/home/dittrich/dims/envs/dimsenv/bin:/home/di...",
                "PROGRAM": "/bin/bash",
                "PROJECT_HOME": "/home/dittrich/dims/devel",
                "PS1": "\\[\\033[1;34m\\][dimsenv]\\[\\e[0m\\] \\[\\03...",
                "PWD": "/vm/vagrant-run-devserver",
                "QT4_IM_MODULE": "xim",
                "QT_IM_MODULE": "ibus",
                "QT_QPA_PLATFORMTHEME": "appmenu-qt5",
                "RECIPIENTS": "dims-devops@uw.ops-trust.net",
                "SELINUX_INIT": "YES",
                "SESSION": "ubuntu",
                "SESSIONTYPE": "gnome-session",
                "SESSION_MANAGER": "local/dimsdemo1:@/tmp/.ICE-unix/27...",
                "SHELL": "/bin/bash",
                "SHLVL": "3",
                "SSH_AUTH_SOCK": "/home/dittrich/.byobu/.ssh-agent",
                "STAT": "stat",
                "TERM": "screen-256color",
                "TEXTDOMAIN": "im-config",
                "TEXTDOMAINDIR": "/usr/share/locale/",
                "TMUX": "/tmp/tmux-1004/default,3276,1",
                "TMUX_PANE": "%16",
                "UPSTART_SESSION": "unix:abstract=/com/ubuntu/upstart-s...",
                "USER": "dittrich",
                "VERBOSE": "0",
                "VIRTUALENVWRAPPER_HOOK_DIR": "/home/dittrich/dims/envs",
                "VIRTUALENVWRAPPER_PROJECT_FILENAME": ".project",
                "VIRTUALENVWRAPPER_PYTHON": "/home/dittrich/dims/bin/python",
                "VIRTUALENVWRAPPER_SCRIPT": "/home/dittrich/dims/bin/vir...",
                "VIRTUALENVWRAPPER_WORKON_CD": "1",
                "VIRTUAL_ENV": "/home/dittrich/dims/envs/dimsenv",
                "VTE_VERSION": "3409",
                "WINDOWID": "23068683",
                "WORKON_HOME": "/home/dittrich/dims/envs",
                "XAUTHORITY": "/home/dittrich/.Xauthority",
                "XDG_CONFIG_DIRS": "/etc/xdg/xdg-ubuntu:/usr/share/upstar...",
                "XDG_CURRENT_DESKTOP": "Unity",
                "XDG_DATA_DIRS": "/usr/share/ubuntu:/usr/share/gnome:/usr...",
                "XDG_GREETER_DATA_DIR": "/var/lib/lightdm-data/dittrich",
                "XDG_MENU_PREFIX": "gnome-",
                "XDG_RUNTIME_DIR": "/run/user/1004",
                "XDG_SEAT": "seat0",
                "XDG_SEAT_PATH": "/org/freedesktop/DisplayManager/Seat0",
                "XDG_SESSION_ID": "c2",
                "XDG_SESSION_PATH": "/org/freedesktop/DisplayManager/Session0",
                "XDG_VTNR": "7",
                "XMODIFIERS": "@im=ibus",
                "_": "/home/dittrich/dims/envs/dimsenv/bin/ansible"
            },
            "ansible_eth0": {
                "active": false,
                "device": "eth0",
                "macaddress": "34:e6:d7:72:0d:b0",
                "module": "e1000e",
                "mtu": 1500,
                "promisc": false,
                "type": "ether"
            },
            "ansible_form_factor": "Laptop",
            "ansible_fqdn": "dimsdemo1",
            "ansible_hostname": "dimsdemo1",
            "ansible_interfaces": [
                "docker0",
                "tun88",
                "lo",
                "tun0",
                "wlan0",
                "vboxnet2",
                "vboxnet0",
                "vboxnet1",
                "eth0"
            ],
            "ansible_kernel": "3.16.0-30-generic",
            "ansible_lo": {
                "active": true,
                "device": "lo",
                "ipv4": {
                    "address": "127.0.0.1",
                    "netmask": "255.0.0.0",
                    "network": "127.0.0.0"
                },
                "ipv6": [
                    {
                        "address": "::1",
                        "prefix": "128",
                        "scope": "host"
                    }
                ],
                "mtu": 65536,
                "promisc": false,
                "type": "loopback"
            },
            "ansible_lsb": {
                "codename": "trusty",
                "description": "Ubuntu 14.04.3 LTS",
                "id": "Ubuntu",
                "major_release": "14",
                "release": "14.04"
            },
            "ansible_machine": "x86_64",
            "ansible_memfree_mb": 2261,
            "ansible_memtotal_mb": 15988,
            "ansible_mounts": [
                {
                    "device": "/dev/mapper/hostname_vg-root_lv",
                    "fstype": "ext4",
                    "mount": "/",
                    "options": "rw,errors=remount-ro",
                    "size_available": 859396513792,
                    "size_total": 982859030528
                },
                {
                    "device": "/dev/sda1",
                    "fstype": "ext3",
                    "mount": "/boot",
                    "options": "rw",
                    "size_available": 419035136,
                    "size_total": 486123520
                }
            ],
            "ansible_nodename": "dimsdemo1",
            "ansible_os_family": "Debian",
            "ansible_pkg_mgr": "apt",
            "ansible_processor": [
                "Intel(R) Core(TM) i7-4710MQ CPU @ 2.50GHz",
                "Intel(R) Core(TM) i7-4710MQ CPU @ 2.50GHz",
                "Intel(R) Core(TM) i7-4710MQ CPU @ 2.50GHz",
                "Intel(R) Core(TM) i7-4710MQ CPU @ 2.50GHz",
                "Intel(R) Core(TM) i7-4710MQ CPU @ 2.50GHz",
                "Intel(R) Core(TM) i7-4710MQ CPU @ 2.50GHz",
                "Intel(R) Core(TM) i7-4710MQ CPU @ 2.50GHz",
                "Intel(R) Core(TM) i7-4710MQ CPU @ 2.50GHz"
            ],
            "ansible_processor_cores": 4,
            "ansible_processor_count": 1,
            "ansible_processor_threads_per_core": 2,
            "ansible_processor_vcpus": 8,
            "ansible_product_name": "Precision M4800",
            "ansible_product_serial": "NA",
            "ansible_product_uuid": "NA",
            "ansible_product_version": "01",
            "ansible_python_version": "2.7.6",
            "ansible_selinux": false,
            "ansible_ssh_host_key_dsa_public": "AAAA...==",
            "ansible_ssh_host_key_ecdsa_public": "AA...==",
            "ansible_ssh_host_key_rsa_public": "AAAA...",
            "ansible_swapfree_mb": 975,
            "ansible_swaptotal_mb": 975,
            "ansible_system": "Linux",
            "ansible_system_vendor": "Dell Inc.",
            "ansible_tun0": {
                "active": true,
                "device": "tun0",
                "ipv4": {
                    "address": "10.86.86.7",
                    "netmask": "255.255.255.0",
                    "network": "10.86.86.0"
                },
                "mtu": 1500,
                "promisc": false
            },
            "ansible_tun88": {
                "active": true,
                "device": "tun88",
                "ipv4": {
                    "address": "10.88.88.5",
                    "netmask": "255.255.255.0",
                    "network": "10.88.88.0"
                },
                "mtu": 1500,
                "promisc": false
            },
            "ansible_user_id": "dittrich",
            "ansible_userspace_architecture": "x86_64",
            "ansible_userspace_bits": "64",
            "ansible_vboxnet0": {
                "active": false,
                "device": "vboxnet0",
                "macaddress": "0a:00:27:00:00:00",
                "mtu": 1500,
                "promisc": false,
                "type": "ether"
            },
            "ansible_vboxnet1": {
                "active": false,
                "device": "vboxnet1",
                "macaddress": "0a:00:27:00:00:01",
                "mtu": 1500,
                "promisc": false,
                "type": "ether"
            },
            "ansible_vboxnet2": {
                "active": false,
                "device": "vboxnet2",
                "macaddress": "0a:00:27:00:00:02",
                "mtu": 1500,
                "promisc": false,
                "type": "ether"
            },
            "ansible_virtualization_role": "host",
            "ansible_virtualization_type": "kvm",
            "ansible_wlan0": {
                "active": true,
                "device": "wlan0",
                "ipv4": {
                    "address": "192.168.0.100",
                    "netmask": "255.255.255.0",
                    "network": "192.168.0.0"
                },
                "ipv6": [
                    {
                        "address": "fe80::d253:49ff:fed7:9ebd",
                        "prefix": "64",
                        "scope": "link"
                    }
                ],
                "macaddress": "d0:53:49:d7:9e:bd",
                "module": "wl",
                "mtu": 1500,
                "promisc": false,
                "type": "ether"
            },
            "module_setup": true
        },
        "changed": false
    }

..

Other variables are added from variables files found in ``defaults/`` and
``vars/`` directories in a role, from ``group_vars/``, from ``host_vars/``,
from ``vars`` listed in a playbook, and from the command line with the ``-e``
flag.

You can run playbooks using the ``ansible-playbook`` command directly,
by using a DIMS wrapper script (``dims.ansible-playbook``) which allows
you to run playbooks, tasks, or roles by name, or via the
``dimscli`` Python CLI program.

.. _ansibleconfiguration:

Configuration and Customization of ``ansible`` and ``ansible-playbook``
-----------------------------------------------------------------------

Like any good Unix program, you can use a global or local `Configuration
file` to customize default settings and/or program behavior. Ansible
provides the following alternatives:

* ``ANSIBLE_CONFIG`` (an environment variable)
* ``ansible.cfg`` (in the current directory)
* ``.ansible.cfg`` (in the home directory)
* ``/etc/ansible/ansible.cfg``

.. _Configuration file: http://docs.ansible.com/ansible/intro_configuration.html

There are many reasons why this configuration customization is useful. The
following subsections describe some.

.. caution::

   Keep in mind that one or more of these configuration files may exist on a
   host causing Ansible to potentially behave differently than expected between
   different accounts, different systems, etc. If something appears to not
   work the way you expected, look for these files and see how they are set,
   add extra levels of verbosity with additional ``-v`` flags, or otherwise
   check how Ansible is being configured to work within scripts that
   run ``ansible`` or ``ansible-playbook``.

   To determine which one of these files might be used in a given working
   directory, you can use the following loop to show which file or files
   may exist:

   .. code-block:: none

      $ pwd
      /home/dittrich/dims/git/ansible-playbooks
      $ for f in $ANSIBLE_CONFIG ansible.cfg ~/.ansible.cfg /etc/ansible/ansible.cfg; \
      do [ -f $f ] && echo $f exists; done
      /etc/ansible/ansible.cfg exists

      $ cp /etc/ansible.cfg myconfig.cfg
      $ vi myconfig.cfg
        [ ... ]
      $ ANSIBLE_CONFIG=myconfig.cfg
      $ for f in $ANSIBLE_CONFIG ansible.cfg ~/.ansible.cfg /etc/ansible/ansible.cfg; \
      do [ -f $f ] && echo $f exists; done
      myconfig.cfg exists
      /etc/ansible/ansible.cfg exists

   ..

..

Controlling account, SSH port, etc.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

There are several parameters that affect SSH connections and
the number of simultaneous forked connections useful for accelerating
parallel execution of Ansible tasks across a hosts in an
inventory.  In the example here, we set the number of forks
to ``10``, the default sudo user to ``root``, the default
SSH port to ``8422`` and the transport mechanism to ``smart``:

.. code-block:: none
   :emphasize-lines: 18,20,23,24

    # config file for ansible -- http://ansible.com/
    # ==============================================

    # nearly all parameters can be overridden in ansible-playbook
    # or with command line flags. ansible will read ANSIBLE_CONFIG,
    # ansible.cfg in the current working directory, .ansible.cfg in
    # the home directory or /etc/ansible/ansible.cfg, whichever it
    # finds first

    [defaults]

    # some basic default values...

    #hostfile       = /etc/ansible/hosts
    #library        = /usr/share/ansible
    #remote_tmp     = $HOME/.ansible/tmp
    #pattern        = *
    forks          = 10
    #poll_interval  = 15
    sudo_user      = root
    #ask_sudo_pass = True
    #ask_pass      = True
    transport      = smart
    remote_port    = 8422
    module_lang    = C
     . . .

..

.. _bestpractices:

Ansible Best Practices and Related Documentation
------------------------------------------------

Before doing too much writing of Ansible playbooks, you should familiarize
yourself with the recommended *best practices* for using Ansible for automating
program installation and system configuration tasks in a general, repeatable,
and scalable manner. Ansible provides recommended `Best Practices`_ guidelines
in the the `Ansible Documentation`_, but sometimes these don't go far
enough in guiding a new Ansible user.

.. _Best Practices: http://docs.ansible.com/ansible/playbooks_best_practices.html
.. _Ansible: http://www.ansible.com/
.. _Ansible Documentation: http://docs.ansible.com/ansible/

Two other sources of highly useful information are the following
books and related code examples:

* `Ansible for DevOps`_, by Jeff Geerling
   + `geerlingguy/ansible-for-devops`_

* `The DevOps 2.0 Toolkit`_, by Victor Farcic
   + `vfarcic/vfarcic.github.io`_

.. _Ansible for DevOps: https://leanpub.com/ansible-for-devops
.. _geerlingguy/ansible-for-devops: https://github.com/geerlingguy/ansible-for-devops
.. _The DevOps 2.0 Toolkit: https://leanpub.com/the-devops-2-toolkit
.. _vfarcic/vfarcic.github.io: https://github.com/vfarcic/vfarcic.github.io

