.. _bootstrapping:

Bootstrapping a VM Host as an Ansible Controller
------------------------------------------------

This chapter walks through the process of bootstrapping a
baremetal machine to serve as a Virtualbox hypervisor
for hosting multiple Virtual Machine guests, serving as
the Ansible control host for managing their configuration.

.. note::

    We are assuming that you have set up ``/etc/ansible/ansible.cfg``, or a
    perhaps ``~/.ansible.cfg``, to point to the correct inventory directory.
    You can see what the default is using ``ansible --help``:

    .. code-block:: none

        Usage: ansible <host-pattern> [options]

        Options:
          . . .
          -i INVENTORY, --inventory-file=INVENTORY
                                specify inventory host path
                                (default=/Users/dittrich/dims/git/ansible-dims-
                                playbooks/inventory) or comma separated host list.
          . . .

        ..

    If this is set up properly, you should be able to list the ``all`` group
    and see results like this:

    .. code-block:: none

        $ ansible --list-hosts
        hosts (11):
          blue14.devops.local
          purple.devops.local
          node03.devops.local
          vmhost.devops.local
          node02.devops.local
          yellow.devops.local
          node01.devops.local
          orange.devops.local
          red.devops.local
          blue16.devops.local
          hub.devops.local

    ..

..

The first step in putting hosts under Ansible control is to add them to an
inventory, setting parameters allowing access to them. We will add them to a
local "private" configuration repository, rooted at ``$GIT/private-develop``.
Since these are systems newly installed using an Ubuntu Kickstart USB drive,
they only have a password on the ansible account that we set up, and were installed
with IP addresses that were assigned by DHCP on the local subnet at installation
time. Until they have been fully configured, they have been assigned an address
on (the original DHCP assignments are commented out on lines 12 and 15, and the
actively working addresses set on lines 24 and 26.)
were manually set up on ports connected to an internal VLAN.
The relevant portions of the YAML inventory file are shown here, listed in the
``servers`` inventory, with host variables defined in the ``children`` subgroup
named ``bootstrap`` that we can refer to in Ansible ad-hoc mode:

.. code-block:: yaml
   :linenos:
   :emphasize-lines: 11,13,22,24

    ---

    # File: inventory/servers/nodes.yml

    servers:
      vars:
        ansible_port: 8422
      hosts:
        'other-hosts-not-shown':
        'stirling.devops.develop':
          #ansible_host: '140.142.29.161'
        'dellr510.devops.develop':
          #ansible_host: '140.142.29.186'
      children:
        bootstrap:
          vars:
            ansible_port: 22
            http_proxy: ''
            https_proxy: ''
          hosts:
            'stirling.devops.develop':
                ansible_host: '10.142.29.161'
            'dellr510.devops.develop':
                ansible_host: '10.142.29.186'

    # vim: ft=ansible :

..

Validate the temporary ``bootstrap`` group that defines the two hosts we are
setting up using the ``debug`` module to show the ``ansible_host`` variable and
ensure they match what we set them to.

.. code-block:: none

    $ ansible -i inventory/ -m debug -a 'var=vars.ansible_host' bootstrap
    stirling.devops.develop | SUCCESS => {
        "changed": false,
        "vars.ansible_host": "10.142.29.161"
    }
    dellr510.devops.develop | SUCCESS => {
        "changed": false,
        "vars.ansible_host": "10.142.29.186"
    }

..

Now use the password that was set up at install time to validate that
SSH is working using the ``ping`` or ``raw`` module (both are shown
here, though only one test is necessary to validate connectivity).

.. note::

    For this example, SSH host key checking is being temporarily disabled as we
    are using an internal VLAN. The host keys were written down in a journal
    when the installation was performed and SSH used manually to validate the
    key, which will be collected in a later step.

..

.. code-block:: none

    $ export ANSIBLE_HOST_KEY_CHECKING=False
    $ ansible --ask-pass -m ping  bootstrap
    SSH password:
    dellr510.devops.develop | SUCCESS => {
        "changed": false,
        "ping": "pong"
    }
    stirling.devops.develop | SUCCESS => {
        "changed": false,
        "ping": "pong"
    }
    $ ansible -m raw -a uptime --ask-pass bootstrap
    SSH password:
    dellr510.devops.develop | SUCCESS | rc=0 >>
     22:21:50 up  3:37,  3 users,  load average: 0.78, 1.45, 1.29
    Shared connection to 140.142.29.186 closed.


    stirling.devops.develop | SUCCESS | rc=0 >>
     22:21:51 up  4:15,  3 users,  load average: 2.45, 1.49, 1.18
    Shared connection to 140.142.29.161 closed.

..

Use the ``ansible`` account password with ad-hoc mode to invoke the
``authorized_key`` module to insert the ``ansible`` SSH private key in the
account on the remote systems, using the ``file`` lookup and the
``dims.function`` shell utility function to derive the path to the
private key, adding the ``.pub`` extension to get the public key.

.. code-block:: none

    $ ansible -m authorized_key -a "user=ansible state=present \
    > key='{{ lookup('file', '$(dims.function get_ssh_private_key_file ansible).pub') }}'" \
    > --ask-pass bootstrap
    SSH password:
    dellr510.devops.develop | SUCCESS => {
        "changed": true,
        "exclusive": false,
        "key": "ssh-rsa AAAAB3NzaC1yc2...",
        "key_options": null,
        "keyfile": "/home/ansible/.ssh/authorized_keys",
        "manage_dir": true,
        "path": null,
        "state": "present",
        "unique": false,
        "user": "ansible",
        "validate_certs": true
    }
    stirling.devops.develop | SUCCESS => {
        "changed": true,
        "exclusive": false,
        "key": "ssh-rsa AAAAB3NzaC1yc2...",
        "key_options": null,
        "keyfile": "/home/ansible/.ssh/authorized_keys",
        "manage_dir": true,
        "path": null,
        "state": "present",
        "unique": false,
        "user": "ansible",
        "validate_certs": true
    }

..

Now that the SSH public key is in the ``authorized_keys`` files, we can remove
the ``--ask-pass`` option and present the SSH private key to validate that
standard remote access with Ansible will now work.  Let's also use this
opportunity to test outbound network access by sending an ICMP packet
to one of Google's DNS servers.

.. code-block:: none

    $ ansible -i inventory/ --ask-pass -m shell -a "ping -c 1 8.8.8.8"  bootstrap
    SSH password:
    dellr510.devops.develop | SUCCESS | rc=0 >>
    PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
    64 bytes from 8.8.8.8: icmp_seq=1 ttl=57 time=1.39 ms

    --- 8.8.8.8 ping statistics ---
    1 packets transmitted, 1 received, 0% packet loss, time 0ms
    rtt min/avg/max/mdev = 1.395/1.395/1.395/0.000 ms

    stirling.devops.develop | SUCCESS | rc=0 >>
    PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
    64 bytes from 8.8.8.8: icmp_seq=1 ttl=57 time=1.44 ms

    --- 8.8.8.8 ping statistics ---
    1 packets transmitted, 1 received, 0% packet loss, time 0ms
    rtt min/avg/max/mdev = 1.446/1.446/1.446/0.000 ms

..

At this point we have verified Ansible can access the systems and that
they can access the Internet. Those are the basics we need to now run
the ``bootstrap.yml`` playbook to prepare the system for being a
virtual machine hypervisor and Ansible control host. The tasks
performed (at the high level) are seen here:

.. literalinclude:: ../../roles/bootstrap/tasks/main.yml
   :language: yaml

Run the playbook as shown (or substitute the inventory host name
directly, e.g., ``dellr510.ops.ectf``, instead of the group
name ``bootstrap``. Using the group, you can prepare as many hosts
as you wish at one time, in this case we show configuration of
two hosts simultaneously.

.. code-block:: none

    $ ansible-playbook -i inventory/ $PBR/playbooks/bootstrap.yml --ask-sudo-pass --ask-pass --become -e host=bootstrap
    SSH password:
    SUDO password[defaults to SSH password]:

    PLAY [Bootstrapping 'bootstrap'] **********************************************

    TASK [Debugging] **************************************************************
    Sunday 23 July 2017  12:41:06 -0700 (0:00:00.060)       0:00:00.060 ***********
    skipping: [dellr510.devops.develop]
    skipping: [stirling.devops.develop]

    TASK [Include codename-specific variables] ************************************
    Sunday 23 July 2017  12:41:07 -0700 (0:00:01.063)       0:00:01.124 ***********
    ok: [dellr510.devops.develop] => (item=/home/dittrich/dims/git/ansible-dims-playbooks/playbooks/../vars/trusty.yml)
    ok: [stirling.devops.develop] => (item=/home/dittrich/dims/git/ansible-dims-playbooks/playbooks/../vars/trusty.yml)

    TASK [bootstrap : Check for Broadcom device 14e4:43b1] ************************
    Sunday 23 July 2017  12:41:08 -0700 (0:00:01.075)       0:00:02.200 ***********
    changed: [stirling.devops.develop]
    changed: [dellr510.devops.develop]

    TASK [bootstrap : Ensure Broadcom wireless kernel in place] *******************
    Sunday 23 July 2017  12:41:10 -0700 (0:00:01.705)       0:00:03.905 ***********
    skipping: [dellr510.devops.develop]
    skipping: [stirling.devops.develop]

    TASK [bootstrap : Make sure required APT packages are present (Debian)] *******
    Sunday 23 July 2017  12:41:11 -0700 (0:00:01.633)       0:00:05.539 ***********
    ok: [dellr510.devops.develop] => (item=[u'apt-transport-https', u'bash-completion', u'ca-certificates', u'cpanminus', u'curl', u'dconf-tools', u'git-core', u'default-jdk', u'gitk', u'gnupg2',
     u'htop', u'hunspell', u'iptables-persistent', u'ifstat', u'make', u'myrepos', u'netcat', u'nfs-common', u'chrony', u'ntpdate', u'openssh-server', u'patch', u'perl', u'postfix', u'python', u'
    python-apt', u'remake', u'rsync', u'rsyslog', u'sshfs', u'strace', u'tree', u'vim', u'xsltproc', u'chrony', u'nfs-kernel-server', u'smartmontools', u'unzip'])
    ok: [stirling.devops.develop] => (item=[u'apt-transport-https', u'bash-completion', u'ca-certificates', u'cpanminus', u'curl', u'dconf-tools', u'git-core', u'default-jdk', u'gitk', u'gnupg2',
     u'htop', u'hunspell', u'iptables-persistent', u'ifstat', u'make', u'myrepos', u'netcat', u'nfs-common', u'chrony', u'ntpdate', u'openssh-server', u'patch', u'perl', u'postfix', u'python', u'
    python-apt', u'remake', u'rsync', u'rsyslog', u'sshfs', u'strace', u'tree', u'vim', u'xsltproc', u'chrony', u'nfs-kernel-server', u'smartmontools', u'unzip'])

    TASK [bootstrap : Make sure required APT packages are present (RedHat)] *******
    Sunday 23 July 2017  12:41:26 -0700 (0:00:15.023)       0:00:20.562 ***********
    skipping: [dellr510.devops.develop] => (item=[])
    skipping: [stirling.devops.develop] => (item=[])

    TASK [bootstrap : Ensure dims_timezone is set] ********************************
    Sunday 23 July 2017  12:41:27 -0700 (0:00:01.168)       0:00:21.731 ***********
    skipping: [dellr510.devops.develop]
    skipping: [stirling.devops.develop]

    TASK [bootstrap : Set timezone variables] *************************************
    Sunday 23 July 2017  12:41:28 -0700 (0:00:01.069)       0:00:22.800 ***********
    changed: [dellr510.devops.develop]
    changed: [stirling.devops.develop]

    TASK [bootstrap : Ensure Debian chrony package is installed] ******************
    Sunday 23 July 2017  12:41:31 -0700 (0:00:02.035)       0:00:24.836 ***********
    ok: [dellr510.devops.develop]
    ok: [stirling.devops.develop]

    TASK [bootstrap : Ensure chrony is running on Debian] *************************
    Sunday 23 July 2017  12:41:33 -0700 (0:00:02.679)       0:00:27.515 ***********
    ok: [dellr510.devops.develop]
    ok: [stirling.devops.develop]

    TASK [bootstrap : Ensure RedHat chrony package is installed] ******************
    Sunday 23 July 2017  12:41:35 -0700 (0:00:01.601)       0:00:29.116 ***********
    skipping: [dellr510.devops.develop]
    skipping: [stirling.devops.develop]

    TASK [bootstrap : Ensure chrony is running on RedHat] *************************
    Sunday 23 July 2017  12:41:36 -0700 (0:00:01.067)       0:00:30.184 ***********
    skipping: [dellr510.devops.develop]
    skipping: [stirling.devops.develop]

    TASK [bootstrap : Verify that the sudo group exists] **************************
    Sunday 23 July 2017  12:41:37 -0700 (0:00:01.066)       0:00:31.250 ***********
    ok: [dellr510.devops.develop]
    ok: [stirling.devops.develop]

    TASK [bootstrap : Set fact with temp sudoers filename] ************************
    Sunday 23 July 2017  12:41:38 -0700 (0:00:01.462)       0:00:32.712 ***********
    ok: [dellr510.devops.develop]
    ok: [stirling.devops.develop]

    TASK [bootstrap : Copy sudoers template to temporary file] ********************
    Sunday 23 July 2017  12:41:39 -0700 (0:00:01.068)       0:00:33.781 ***********
    changed: [dellr510.devops.develop]
    changed: [stirling.devops.develop]

    TASK [bootstrap : Back up sudoers file] ***************************************
    Sunday 23 July 2017  12:41:41 -0700 (0:00:01.914)       0:00:35.695 ***********
    changed: [dellr510.devops.develop]
    changed: [stirling.devops.develop]

    TASK [bootstrap : Verify sudoers before replacing] ****************************
    Sunday 23 July 2017  12:41:43 -0700 (0:00:01.398)       0:00:37.093 ***********
    changed: [dellr510.devops.develop]
    changed: [stirling.devops.develop]

    TASK [bootstrap : Define variable with ansible public key] ********************
    Sunday 23 July 2017  12:41:44 -0700 (0:00:01.508)       0:00:38.602 ***********
    ok: [dellr510.devops.develop]
    ok: [stirling.devops.develop]

    TASK [bootstrap : Ensure ansible public key in authorized_keys] ***************
    Sunday 23 July 2017  12:41:46 -0700 (0:00:02.083)       0:00:40.686 ***********
    ok: [dellr510.devops.develop]
    changed: [stirling.devops.develop]

    TASK [bootstrap : Show interface details (Debian)] ****************************
    Sunday 23 July 2017  12:41:48 -0700 (0:00:01.710)       0:00:42.397 ***********
    changed: [dellr510.devops.develop]
    changed: [stirling.devops.develop]

    TASK [bootstrap : debug] ******************************************************
    Sunday 23 July 2017  12:41:49 -0700 (0:00:01.397)       0:00:43.794 ***********
    ok: [dellr510.devops.develop] => {
        "_ifconfig.stdout_lines": [
            "em1       Link encap:Ethernet  HWaddr 78:2b:cb:57:9b:e1  ",
            "          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1",
            "",
            "em2       Link encap:Ethernet  HWaddr 78:2b:cb:57:9b:e2  ",
            "          inet addr:10.142.29.186  Bcast:10.142.29.255  Mask:255.255.255.0",
            "          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1",
            "",
            "lo        Link encap:Local Loopback  ",
            "          inet addr:127.0.0.1  Mask:255.0.0.0",
            "          UP LOOPBACK RUNNING  MTU:65536  Metric:1",
            "",
            "p2p1      Link encap:Ethernet  HWaddr 00:1b:21:c0:ff:30  ",
            "          UP BROADCAST MULTICAST  MTU:1500  Metric:1",
            "          Memory:de7c0000-de7dffff ",
            "",
            "p2p2      Link encap:Ethernet  HWaddr 00:1b:21:c0:ff:31  ",
            "          UP BROADCAST MULTICAST  MTU:1500  Metric:1",
            "          Memory:de7e0000-de7fffff ",
            "",
            "p3p1      Link encap:Ethernet  HWaddr 00:1b:21:c1:1c:34  ",
            "          UP BROADCAST MULTICAST  MTU:1500  Metric:1",
            "          Memory:dd7c0000-dd7dffff ",
            "",
            "p3p2      Link encap:Ethernet  HWaddr 00:1b:21:c1:1c:35  ",
            "          UP BROADCAST MULTICAST  MTU:1500  Metric:1",
            "          Memory:dd7e0000-dd7fffff "
        ],
        "changed": false
    }
    ok: [stirling.devops.develop] => {
        "_ifconfig.stdout_lines": [
            "em1       Link encap:Ethernet  HWaddr f0:4d:a2:40:92:1d  ",
            "          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1",
            "",
            "em2       Link encap:Ethernet  HWaddr f0:4d:a2:40:92:1f  ",
            "          inet addr:10.142.29.161  Bcast:10.142.29.255  Mask:255.255.255.0",
            "          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1",
            "",
            "em3       Link encap:Ethernet  HWaddr f0:4d:a2:40:92:21  ",
            "          UP BROADCAST MULTICAST  MTU:1500  Metric:1",
            "",
            "em4       Link encap:Ethernet  HWaddr f0:4d:a2:40:92:23  ",
            "          UP BROADCAST MULTICAST  MTU:1500  Metric:1",
            "",
            "lo        Link encap:Local Loopback  ",
            "          inet addr:127.0.0.1  Mask:255.0.0.0",
            "          UP LOOPBACK RUNNING  MTU:65536  Metric:1"
        ],
        "changed": false
    }

    TASK [bootstrap : Show interface details (MacOSX)] ****************************
    Sunday 23 July 2017  12:41:51 -0700 (0:00:01.071)       0:00:44.866 ***********
    skipping: [dellr510.devops.develop]
    skipping: [stirling.devops.develop]

    TASK [bootstrap : debug] ******************************************************
    Sunday 23 July 2017  12:41:52 -0700 (0:00:01.069)       0:00:45.936 ***********
    skipping: [dellr510.devops.develop]
    skipping: [stirling.devops.develop]

    TASK [bootstrap : Determine SSH host MD5 key fingerprints] ********************
    Sunday 23 July 2017  12:41:53 -0700 (0:00:01.068)       0:00:47.004 ***********
    changed: [dellr510.devops.develop]
    changed: [stirling.devops.develop]

    TASK [bootstrap : debug] ******************************************************
    Sunday 23 July 2017  12:41:54 -0700 (0:00:01.472)       0:00:48.477 ***********
    ok: [dellr510.devops.develop] => {
        "_md5.stdout_lines": [
            "1024 c9:58:58:f3:90:a6:1f:1c:ab:fb:8e:18:42:77:a2:88  root@D-140-142-29-186 (DSA)",
            "256 a2:61:50:25:6b:c3:02:43:55:a7:35:32:cb:96:f5:82  root@D-140-142-29-186 (ECDSA)",
            "256 e6:c8:11:ac:48:28:1f:bc:fd:ad:06:f4:0f:26:9e:5b  root@D-140-142-29-186 (ED25519)",
            "2048 55:ae:94:22:e1:ce:d4:2a:b6:d3:8b:aa:09:70:d1:38  root@D-140-142-29-186 (RSA)"
        ],
        "changed": false
    }
    ok: [stirling.devops.develop] => {
        "_md5.stdout_lines": [
            "1024 b1:41:a2:bd:c2:e8:3b:bd:14:3b:3f:7d:eb:e5:ba:10  root@D-140-142-29-161 (DSA)",
            "256 41:68:1e:59:4e:bd:0c:5b:25:c8:24:60:a8:d6:f1:c6  root@D-140-142-29-161 (ECDSA)",
            "256 bb:4b:89:f5:6b:45:7c:d3:9e:56:54:ea:8c:1b:79:8f  root@D-140-142-29-161 (ED25519)",
            "2048 96:95:e2:45:01:d2:45:2e:49:a8:7c:f6:39:28:0a:a5  root@D-140-142-29-161 (RSA)"
        ],
        "changed": false
    }

    TASK [bootstrap : Determine SSH host SHA256 key fingerprints] *****************
    Sunday 23 July 2017  12:41:55 -0700 (0:00:01.076)       0:00:49.553 ***********
    changed: [dellr510.devops.develop]
    changed: [stirling.devops.develop]

    TASK [bootstrap : debug] ******************************************************
    Sunday 23 July 2017  12:41:57 -0700 (0:00:01.471)       0:00:51.025 ***********
    ok: [dellr510.devops.develop] => {
        "_sha256.stdout_lines": [
            "ssh-dss dl/W3IeTv3aPGZdfX8q3L0yZE8gAbW6IbHw9uZlyYDU. root@D-140-142-29-186",
            "ecdsa-sha2-nistp256 8qqzBI22OGTY29T3WCKnpIPbyl1K0My9xwPiGEt9PmE. root@D-140-142-29-186",
            "ssh-ed25519 K4Bc5IttYf5WHE2nzuxTr9w8QzTMzIKZYUewvwCcuPc. root@D-140-142-29-186",
            "ssh-rsa rVUD1b6raug2Pp01pJLyWEHzxUfGbzOkwUxvhRzvH30. root@D-140-142-29-186"
        ],
        "changed": false
    }
    ok: [stirling.devops.develop] => {
        "_sha256.stdout_lines": [
            "ssh-dss EdHHaFS7LRtVqCKzlzYG68OpQNnKqEygWoEoM9lYtWs. root@D-140-142-29-161",
            "ecdsa-sha2-nistp256 3MicWfvhufEiPRiANS43Z/7MbcHHTythyOAhYluyD+w. root@D-140-142-29-161",
            "ssh-ed25519 gT0duOWxArehJR08iR0iFO4gDUqDCjT6P+lJYPT0MwI. root@D-140-142-29-161",
            "ssh-rsa MQl68HQR5Oip9MPlozLddlXA9Emcz9QTJLk0IJgVJOs. root@D-140-142-29-161"
        ],
        "changed": false
    }

    TASK [bootstrap : Determine SSH host SHA256 key fingerprints] *****************
    Sunday 23 July 2017  12:41:58 -0700 (0:00:01.072)       0:00:52.097 ***********
    skipping: [dellr510.devops.develop]
    skipping: [stirling.devops.develop]

    TASK [bootstrap : debug] ******************************************************
    Sunday 23 July 2017  12:41:59 -0700 (0:00:01.069)       0:00:53.167 ***********
    skipping: [dellr510.devops.develop]
    skipping: [stirling.devops.develop]

    RUNNING HANDLER [bootstrap : Update timezone] *********************************
    Sunday 23 July 2017  12:42:00 -0700 (0:00:01.062)       0:00:54.229 ***********
    changed: [dellr510.devops.develop]
    changed: [stirling.devops.develop]

    PLAY RECAP ********************************************************************
    dellr510.devops.develop    : ok=20   changed=9    unreachable=0    failed=0
    stirling.devops.develop    : ok=20   changed=10   unreachable=0    failed=0

    Sunday 23 July 2017  12:42:02 -0700 (0:00:02.078)       0:00:56.307 ***********
    ===============================================================================
    bootstrap : Make sure required APT packages are present (Debian) ------- 15.02s
    bootstrap : Ensure Debian chrony package is installed ------------------- 2.68s
    bootstrap : Define variable with ansible public key --------------------- 2.08s
    bootstrap : Update timezone --------------------------------------------- 2.08s
    bootstrap : Set timezone variables -------------------------------------- 2.04s
    bootstrap : Copy sudoers template to temporary file --------------------- 1.91s
    bootstrap : Ensure ansible public key in authorized_keys ---------------- 1.71s
    bootstrap : Check for Broadcom device 14e4:43b1 ------------------------- 1.71s
    bootstrap : Ensure Broadcom wireless kernel in place -------------------- 1.63s
    bootstrap : Ensure chrony is running on Debian -------------------------- 1.60s
    bootstrap : Verify sudoers before replacing ----------------------------- 1.51s
    bootstrap : Determine SSH host MD5 key fingerprints --------------------- 1.47s
    bootstrap : Determine SSH host SHA256 key fingerprints ------------------ 1.47s
    bootstrap : Verify that the sudo group exists --------------------------- 1.46s
    bootstrap : Back up sudoers file ---------------------------------------- 1.40s
    bootstrap : Show interface details (Debian) ----------------------------- 1.40s
    bootstrap : Make sure required APT packages are present (RedHat) -------- 1.17s
    bootstrap : debug ------------------------------------------------------- 1.08s
    Include codename-specific variables ------------------------------------- 1.08s
    bootstrap : debug ------------------------------------------------------- 1.07s

..

.. code-block:: none

    $ ansible -m authorized_key -a "user=ansible key=$(dims.function get_ssh_private_key_file ansible).pub"  --ask-pass bootstrap
    SSH password:
    dellr510.devops.develop | FAILED! => {
        "changed": false,
        "failed": true,
        "msg": "invalid key specified: /home/dittrich/dims/git/private-develop/files/ssh-keys/user/ansible/dims_ansible_rsa.pub"
    }
    stirling.devops.develop | FAILED! => {
        "changed": false,
        "failed": true,
        "msg": "invalid key specified: /home/dittrich/dims/git/private-develop/files/ssh-keys/user/ansible/dims_ansible_rsa.pub"
    }
    $ ansible -m authorized_key -a "user=ansible state=present key='$(dims.function get_ssh_private_key_file ansible).pub'"  --ask-pass bootstrap
    SSH password:
    dellr510.devops.develop | FAILED! => {
        "changed": false,
        "failed": true,
        "msg": "invalid key specified: /home/dittrich/dims/git/private-develop/files/ssh-keys/user/ansible/dims_ansible_rsa.pub"
    }
    stirling.devops.develop | FAILED! => {
        "changed": false,
        "failed": true,
        "msg": "invalid key specified: /home/dittrich/dims/git/private-develop/files/ssh-keys/user/ansible/dims_ansible_rsa.pub"
    }
    $ vi files/ssh-keys/user/ansible/dims_ansible_rsa.pub
    $ ansible -m authorized_key -a "user=ansible state=present key='$(dims.function get_ssh_private_key_file ansible).pub'"  --ask-pass bootstrap
    SSH password:
    dellr510.devops.develop | FAILED! => {
        "changed": false,
        "failed": true,
        "msg": "invalid key specified: /home/dittrich/dims/git/private-develop/files/ssh-keys/user/ansible/dims_ansible_rsa.pub"
    }
    stirling.devops.develop | FAILED! => {
        "changed": false,
        "failed": true,
        "msg": "invalid key specified: /home/dittrich/dims/git/private-develop/files/ssh-keys/user/ansible/dims_ansible_rsa.pub"
    }
    $ ansible -m authorized_key -a "user=ansible state=present key='{{ lookup('file', '$(dims.function get_ssh_private_key_file ansible).pub') }}'"  --ask-pass bootstrap
    SSH password:
    dellr510.devops.develop | SUCCESS => {
        "changed": true,
        "exclusive": false,
        "key": "ssh-rsa AAAAB3NzaC1yc...",
        "key_options": null,
        "keyfile": "/home/ansible/.ssh/authorized_keys",
        "manage_dir": true,
        "path": null,
        "state": "present",
        "unique": false,
        "user": "ansible",
        "validate_certs": true
    }
    stirling.devops.develop | SUCCESS => {
        "changed": true,
        "exclusive": false,
        "key": "ssh-rsa AAAAB3NzaC1yc2...",
        "key_options": null,
        "keyfile": "/home/ansible/.ssh/authorized_keys",
        "manage_dir": true,
        "path": null,
        "state": "present",
        "unique": false,
        "user": "ansible",
        "validate_certs": true
    }
    $ ansible -m raw -a uptime  bootstrap
    dellr510.devops.develop | SUCCESS | rc=0 >>
     22:33:44 up  3:49,  3 users,  load average: 1.14, 0.81, 0.99
    Shared connection to 140.142.29.186 closed.


    stirling.devops.develop | SUCCESS | rc=0 >>
     22:33:44 up  4:27,  3 users,  load average: 1.12, 1.10, 1.03
    Shared connection to 140.142.29.161 closed.


    $ ansible-playbook -i inventory /home/dittrich/dims/git/ansible-dims-playbooks/playbooks/hosts/vmhost.devops.local.yml -e host=bootstrap

    PLAY [Configure host "vmhost.devops.local"] ***********************************************************************************************************

    TASK [Gathering Facts] ********************************************************************************************************************************
    Wednesday 19 July 2017  19:52:40 -0700 (0:00:00.122)       0:00:00.122 ********
     [WARNING]: Removed restricted key from module data: ansible_docker_gwbridge = {u'macaddress': u'02:42:f3:d1:a9:0e', u'features':
    {u'tx_checksum_ipv4': u'off [fixed]', u'generic_receive_offload': u'on', u'tx_checksum_ipv6': u'off [fixed]', u'tx_scatter_gather_fraglist': u'on',
    u'rx_all': u'off [fixed]', u'highdma': u'on', u'rx_fcs': u'off [fixed]', u'tx_lockless': u'on [fixed]', u'tx_tcp_ecn_segmentation': u'on',
    u'tx_gso_robust': u'on', u'tx_ipip_segmentation': u'on', u'tx_checksumming': u'on', u'vlan_challenged': u'off [fixed]', u'loopback': u'off [fixed]',
    u'fcoe_mtu': u'off [fixed]', u'tx_checksum_sctp': u'off [fixed]', u'tx_vlan_stag_hw_insert': u'on', u'rx_vlan_stag_hw_parse': u'off [fixed]',
    u'tx_nocache_copy': u'off', u'rx_vlan_stag_filter': u'off [fixed]', u'large_receive_offload': u'off [fixed]', u'tx_checksum_ip_generic': u'on',
    u'rx_checksumming': u'off [fixed]', u'tx_tcp_segmentation': u'on', u'tx_fcoe_segmentation': u'on', u'busy_poll': u'off [fixed]',
    u'generic_segmentation_offload': u'on', u'tx_udp_tnl_segmentation': u'on', u'tcp_segmentation_offload': u'on', u'l2_fwd_offload': u'off [fixed]',
    u'rx_vlan_offload': u'off [fixed]', u'ntuple_filters': u'off [fixed]', u'rx_vlan_filter': u'off [fixed]', u'tx_tcp6_segmentation': u'on',
    u'udp_fragmentation_offload': u'on', u'scatter_gather': u'on', u'tx_sit_segmentation': u'on', u'tx_checksum_fcoe_crc': u'off [fixed]',
    u'hw_tc_offload': u'off [fixed]', u'tx_scatter_gather': u'on', u'netns_local': u'on [fixed]', u'tx_vlan_offload': u'on', u'receive_hashing': u'off
    [fixed]', u'tx_gre_segmentation': u'on'}, u'interfaces': [], u'mtu': 1500, u'active': False, u'promisc': False, u'stp': False, u'ipv4': {u'broadcast':
    u'global', u'netmask': u'255.255.0.0', u'network': u'172.18.0.0', u'address': u'172.18.0.1'}, u'device': u'docker_gwbridge', u'type': u'bridge',
    u'id': u'8000.0242f3d1a90e'}

     [WARNING]: Removed restricted key from module data: ansible_docker_gwbridge = {u'macaddress': u'02:42:f3:d1:a9:0e', u'features':
    {u'tx_checksum_ipv4': u'off [fixed]', u'generic_receive_offload': u'on', u'tx_checksum_ipv6': u'off [fixed]', u'tx_scatter_gather_fraglist': u'on',
    u'rx_all': u'off [fixed]', u'highdma': u'on', u'rx_fcs': u'off [fixed]', u'tx_lockless': u'on [fixed]', u'tx_tcp_ecn_segmentation': u'on',
    u'tx_gso_robust': u'on', u'tx_ipip_segmentation': u'on', u'tx_checksumming': u'on', u'vlan_challenged': u'off [fixed]', u'loopback': u'off [fixed]',
    u'fcoe_mtu': u'off [fixed]', u'tx_checksum_sctp': u'off [fixed]', u'tx_vlan_stag_hw_insert': u'on', u'rx_vlan_stag_hw_parse': u'off [fixed]',
    u'tx_nocache_copy': u'off', u'rx_vlan_stag_filter': u'off [fixed]', u'large_receive_offload': u'off [fixed]', u'tx_checksum_ip_generic': u'on',
    u'rx_checksumming': u'off [fixed]', u'tx_tcp_segmentation': u'on', u'tx_fcoe_segmentation': u'on', u'busy_poll': u'off [fixed]',
    u'generic_segmentation_offload': u'on', u'tx_udp_tnl_segmentation': u'on', u'tcp_segmentation_offload': u'on', u'l2_fwd_offload': u'off [fixed]',
    u'rx_vlan_offload': u'off [fixed]', u'ntuple_filters': u'off [fixed]', u'rx_vlan_filter': u'off [fixed]', u'tx_tcp6_segmentation': u'on',
    u'udp_fragmentation_offload': u'on', u'scatter_gather': u'on', u'tx_sit_segmentation': u'on', u'tx_checksum_fcoe_crc': u'off [fixed]',
    u'hw_tc_offload': u'off [fixed]', u'tx_scatter_gather': u'on', u'netns_local': u'on [fixed]', u'tx_vlan_offload': u'on', u'receive_hashing': u'off
    [fixed]', u'tx_gre_segmentation': u'on'}, u'interfaces': [], u'mtu': 1500, u'active': False, u'promisc': False, u'stp': False, u'ipv4': {u'broadcast':
    u'global', u'netmask': u'255.255.0.0', u'network': u'172.18.0.0', u'address': u'172.18.0.1'}, u'device': u'docker_gwbridge', u'type': u'bridge',
    u'id': u'8000.0242f3d1a90e'}

    ok: [stirling.devops.develop]
    ok: [dellr510.devops.develop]

    TASK [base : Check for ansible 2.x] *******************************************************************************************************************
    Wednesday 19 July 2017  19:52:43 -0700 (0:00:02.306)       0:00:02.429 ********
    included: /home/dittrich/dims/git/ansible-dims-playbooks/tasks/ansible2check.yml for dellr510.devops.develop, stirling.devops.develop

    TASK [base : Validate Ansible 2.x is being used] ******************************************************************************************************
    Wednesday 19 July 2017  19:52:44 -0700 (0:00:01.137)       0:00:03.566 ********
    skipping: [dellr510.devops.develop]
    skipping: [stirling.devops.develop]

    TASK [base : debug] ***********************************************************************************************************************************
    Wednesday 19 July 2017  19:52:45 -0700 (0:00:01.077)       0:00:04.644 ********
    skipping: [dellr510.devops.develop]
    skipping: [stirling.devops.develop]

    TASK [base : Check proxy availability] ****************************************************************************************************************
    Wednesday 19 July 2017  19:52:46 -0700 (0:00:01.058)       0:00:05.702 ********
    included: /home/dittrich/dims/git/ansible-dims-playbooks/tasks/proxy_check.yml for dellr510.devops.develop, stirling.devops.develop

    TASK [base : Check to see if http_proxy is working] ***************************************************************************************************
    Wednesday 19 July 2017  19:52:47 -0700 (0:00:01.157)       0:00:06.860 ********
    changed: [stirling.devops.develop]
    changed: [dellr510.devops.develop]

    TASK [base : Disable http_proxy if it is not working] *************************************************************************************************
    Wednesday 19 July 2017  19:52:49 -0700 (0:00:01.562)       0:00:08.423 ********
    skipping: [dellr510.devops.develop]
    skipping: [stirling.devops.develop]

    TASK [base : Check to see if https_proxy is working] **************************************************************************************************
    Wednesday 19 July 2017  19:52:50 -0700 (0:00:01.106)       0:00:09.530 ********
    changed: [dellr510.devops.develop]
    changed: [stirling.devops.develop]

    TASK [base : Disable https_proxy if it is not working] ************************************************************************************************
    Wednesday 19 July 2017  19:52:52 -0700 (0:00:01.850)       0:00:11.380 ********
    skipping: [dellr510.devops.develop]
    skipping: [stirling.devops.develop]

    TASK [base : Ensure dims group exists] ****************************************************************************************************************
    Wednesday 19 July 2017  19:52:53 -0700 (0:00:01.063)       0:00:12.443 ********
    ok: [dellr510.devops.develop]
    ok: [stirling.devops.develop]

    TASK [base : Ensure ansible user is in dims group] ****************************************************************************************************
    Wednesday 19 July 2017  19:52:54 -0700 (0:00:01.222)       0:00:13.666 ********
    ok: [dellr510.devops.develop]
    ok: [stirling.devops.develop]

    TASK [base : Ensure dims service account exists] ******************************************************************************************************
    Wednesday 19 July 2017  19:52:55 -0700 (0:00:01.338)       0:00:15.004 ********
    ok: [dellr510.devops.develop]
    ok: [stirling.devops.develop]

    TASK [base : Ensure dims top level directory exists] **************************************************************************************************
    Wednesday 19 July 2017  19:52:56 -0700 (0:00:01.158)       0:00:16.162 ********
    ok: [dellr510.devops.develop]
    ok: [stirling.devops.develop]

    TASK [base : Ensure tests directory absent if initializing clean-up] **********************************************************************************
    Wednesday 19 July 2017  19:52:58 -0700 (0:00:01.188)       0:00:17.351 ********
    skipping: [dellr510.devops.develop]
    skipping: [stirling.devops.develop]

    TASK [base : Ensure dims (system-level) subdirectories exist] *****************************************************************************************
    Wednesday 19 July 2017  19:52:59 -0700 (0:00:01.061)       0:00:18.412 ********
    ok: [dellr510.devops.develop] => (item=/opt/dims/backups)
    ok: [stirling.devops.develop] => (item=/opt/dims/backups)
    ok: [dellr510.devops.develop] => (item=/opt/dims/bin)
    ok: [stirling.devops.develop] => (item=/opt/dims/bin)
    ok: [dellr510.devops.develop] => (item=/opt/dims/data)
    ok: [stirling.devops.develop] => (item=/opt/dims/data)
    ok: [dellr510.devops.develop] => (item=/opt/dims/deploy)
    ok: [stirling.devops.develop] => (item=/opt/dims/deploy)
    ok: [dellr510.devops.develop] => (item=/opt/dims/docs)
    ok: [stirling.devops.develop] => (item=/opt/dims/docs)
    ok: [dellr510.devops.develop] => (item=/opt/dims/etc)
    ok: [stirling.devops.develop] => (item=/opt/dims/etc)
    ok: [dellr510.devops.develop] => (item=/opt/dims/etc/bashrc.dims.d)
    ok: [stirling.devops.develop] => (item=/opt/dims/etc/bashrc.dims.d)
    ok: [dellr510.devops.develop] => (item=/opt/dims/git)
    ok: [stirling.devops.develop] => (item=/opt/dims/git)
    ok: [dellr510.devops.develop] => (item=/opt/dims/lib)
    ok: [stirling.devops.develop] => (item=/opt/dims/lib)
    ok: [dellr510.devops.develop] => (item=/opt/dims/tests.d)
    ok: [stirling.devops.develop] => (item=/opt/dims/tests.d)
    ok: [dellr510.devops.develop] => (item=/opt/dims/triggers.d)
    ok: [stirling.devops.develop] => (item=/opt/dims/triggers.d)
    ok: [dellr510.devops.develop] => (item=/opt/dims/data/logmon)
    ok: [stirling.devops.develop] => (item=/opt/dims/data/logmon)
    ok: [dellr510.devops.develop] => (item=/opt/dims/src)
    ok: [stirling.devops.develop] => (item=/opt/dims/src)
    ok: [dellr510.devops.develop] => (item=/opt/dims/srv)
    ok: [stirling.devops.develop] => (item=/opt/dims/srv)

    TASK [base : Ensure private directory ("secrets" storage) is present] *********************************************************************************
    Wednesday 19 July 2017  19:53:14 -0700 (0:00:15.401)       0:00:33.814 ********
    changed: [dellr510.devops.develop]
    ok: [stirling.devops.develop]

    TASK [base : Populate /etc/environment (Debian, CoreOS)] **********************************************************************************************
    Wednesday 19 July 2017  19:53:15 -0700 (0:00:01.172)       0:00:34.986 ********
    changed: [dellr510.devops.develop] => (item=/home/dittrich/dims/git/ansible-dims-playbooks/roles/base/templates/environment/environment.j2)
    changed: [stirling.devops.develop] => (item=/home/dittrich/dims/git/ansible-dims-playbooks/roles/base/templates/environment/environment.j2)

    TASK [base : Make DIMS bash shell functions present] **************************************************************************************************
    Wednesday 19 July 2017  19:53:17 -0700 (0:00:01.413)       0:00:36.399 ********
    ok: [dellr510.devops.develop]
    ok: [stirling.devops.develop]

    TASK [base : Ensure DIMS system shell init hook is present (Debian, CoreOS)] **************************************************************************
    Wednesday 19 July 2017  19:53:18 -0700 (0:00:01.225)       0:00:37.625 ********
    changed: [dellr510.devops.develop] => (item=/home/dittrich/dims/git/ansible-dims-playbooks/roles/base/templates/bash.bashrc/bash.bashrc.j2)
    ok: [stirling.devops.develop] => (item=/home/dittrich/dims/git/ansible-dims-playbooks/roles/base/templates/bash.bashrc/bash.bashrc.j2)

    TASK [base : Make DIMS system level profile present] **************************************************************************************************
    Wednesday 19 July 2017  19:53:19 -0700 (0:00:01.307)       0:00:38.933 ********
    changed: [dellr510.devops.develop] => (item=/home/dittrich/dims/git/ansible-dims-playbooks/roles/base/templates/profile.d/dims.sh.j2)
    ok: [stirling.devops.develop] => (item=/home/dittrich/dims/git/ansible-dims-playbooks/roles/base/templates/profile.d/dims.sh.j2)

    TASK [base : Make directory for DIMS bashrc plugins present] ******************************************************************************************
    Wednesday 19 July 2017  19:53:21 -0700 (0:00:01.259)       0:00:40.193 ********
    ok: [dellr510.devops.develop]
    ok: [stirling.devops.develop]

    TASK [base : Make DIMS-specific bashrc setup file present] ********************************************************************************************
    Wednesday 19 July 2017  19:53:22 -0700 (0:00:01.145)       0:00:41.338 ********
    changed: [dellr510.devops.develop] => (item=/home/dittrich/dims/git/ansible-dims-playbooks/roles/base/templates/bashrc.dims/bashrc.dims.j2)
    ok: [stirling.devops.develop] => (item=/home/dittrich/dims/git/ansible-dims-playbooks/roles/base/templates/bashrc.dims/bashrc.dims.j2)

    TASK [base : Add group for rsyslog] *******************************************************************************************************************
    Wednesday 19 July 2017  19:53:23 -0700 (0:00:01.254)       0:00:42.593 ********
    ok: [dellr510.devops.develop]
    ok: [stirling.devops.develop]

    TASK [base : Add non-privileged user for rsyslog] *****************************************************************************************************
    Wednesday 19 July 2017  19:53:24 -0700 (0:00:01.137)       0:00:43.730 ********
    ok: [dellr510.devops.develop]
    ok: [stirling.devops.develop]

    TASK [base : Make DIMS logging directory present] *****************************************************************************************************
    Wednesday 19 July 2017  19:53:25 -0700 (0:00:01.162)       0:00:44.893 ********
    ok: [dellr510.devops.develop]
    ok: [stirling.devops.develop]

    TASK [base : Make /etc/rsyslog.conf present] **********************************************************************************************************
    Wednesday 19 July 2017  19:53:26 -0700 (0:00:01.155)       0:00:46.048 ********
    changed: [stirling.devops.develop] => (item=/home/dittrich/dims/git/ansible-dims-playbooks/roles/base/templates/rsyslog/rsyslog.conf.j2)
    changed: [dellr510.devops.develop] => (item=/home/dittrich/dims/git/ansible-dims-playbooks/roles/base/templates/rsyslog/rsyslog.conf.j2)

    TASK [base : Ensure /etc/rsyslog.d present] ***********************************************************************************************************
    Wednesday 19 July 2017  19:53:28 -0700 (0:00:01.255)       0:00:47.304 ********
    ok: [dellr510.devops.develop]
    ok: [stirling.devops.develop]

    TASK [base : Make /etc/rsyslog.d/00-ignore.conf present] **********************************************************************************************
    Wednesday 19 July 2017  19:53:29 -0700 (0:00:01.137)       0:00:48.441 ********
    changed: [dellr510.devops.develop] => (item=/home/dittrich/dims/git/ansible-dims-playbooks/roles/base/templates/rsyslog.d/00-ignore.conf.j2)
    ok: [stirling.devops.develop] => (item=/home/dittrich/dims/git/ansible-dims-playbooks/roles/base/templates/rsyslog.d/00-ignore.conf.j2)

    TASK [base : Make /etc/rsyslog.d/49-consolidation.conf present] ***************************************************************************************
    Wednesday 19 July 2017  19:53:30 -0700 (0:00:01.245)       0:00:49.686 ********
    changed: [dellr510.devops.develop] => (item=/home/dittrich/dims/git/ansible-dims-playbooks/roles/base/templates/rsyslog.d/49-consolidation.conf.j2)
    changed: [stirling.devops.develop] => (item=/home/dittrich/dims/git/ansible-dims-playbooks/roles/base/templates/rsyslog.d/49-consolidation.conf.j2)

    TASK [base : Make /etc/rsyslog.d/50-default.conf present] *********************************************************************************************
    Wednesday 19 July 2017  19:53:31 -0700 (0:00:01.286)       0:00:50.973 ********
    changed: [dellr510.devops.develop] => (item=/home/dittrich/dims/git/ansible-dims-playbooks/roles/base/templates/rsyslog.d/50-default.conf.j2)
    ok: [stirling.devops.develop] => (item=/home/dittrich/dims/git/ansible-dims-playbooks/roles/base/templates/rsyslog.d/50-default.conf.j2)

    TASK [base : restart rsyslog] *************************************************************************************************************************
    Wednesday 19 July 2017  19:53:33 -0700 (0:00:01.246)       0:00:52.220 ********
    changed: [stirling.devops.develop]
    changed: [dellr510.devops.develop]

    TASK [base : /etc/logrotate.d/dims] *******************************************************************************************************************
    Wednesday 19 July 2017  19:53:34 -0700 (0:00:01.475)       0:00:53.695 ********
    changed: [stirling.devops.develop] => (item=/home/dittrich/dims/git/ansible-dims-playbooks/roles/base/templates/logrotate/dims.j2)
    ok: [dellr510.devops.develop] => (item=/home/dittrich/dims/git/ansible-dims-playbooks/roles/base/templates/logrotate/dims.j2)

    TASK [base : Set hostname (runtime) (Debian, CoreOS)] *************************************************************************************************
    Wednesday 19 July 2017  19:53:35 -0700 (0:00:01.275)       0:00:54.971 ********
    changed: [dellr510.devops.develop]
    changed: [stirling.devops.develop]

    TASK [base : Make /etc/hostname present (Debian, CoreOS)] *********************************************************************************************
    Wednesday 19 July 2017  19:53:36 -0700 (0:00:01.139)       0:00:56.110 ********
    changed: [dellr510.devops.develop]
    changed: [stirling.devops.develop]

    TASK [base : Set domainname (Debian, CoreOS)] *********************************************************************************************************
    Wednesday 19 July 2017  19:53:38 -0700 (0:00:01.143)       0:00:57.254 ********
    changed: [dellr510.devops.develop]
    changed: [stirling.devops.develop]

    TASK [base : Set domainname (MacOSX)] *****************************************************************************************************************
    Wednesday 19 July 2017  19:53:39 -0700 (0:00:01.139)       0:00:58.393 ********
    skipping: [dellr510.devops.develop]
    skipping: [stirling.devops.develop]

    TASK [base : Make resolv.conf file present on Debian] *************************************************************************************************
    Wednesday 19 July 2017  19:53:40 -0700 (0:00:01.064)       0:00:59.458 ********
    changed: [dellr510.devops.develop] => (item=/home/dittrich/dims/git/ansible-dims-playbooks/roles/base/templates/resolv.conf/resolv.conf.j2)
    ok: [stirling.devops.develop] => (item=/home/dittrich/dims/git/ansible-dims-playbooks/roles/base/templates/resolv.conf/resolv.conf.j2)

    TASK [base : Make appropriate NetworkManager configruation present] ***********************************************************************************
    Wednesday 19 July 2017  19:53:41 -0700 (0:00:01.242)       0:01:00.700 ********
    changed: [dellr510.devops.develop] => (item=/home/dittrich/dims/git/ansible-dims-playbooks/roles/base/templates/NetworkManager/NetworkManager.conf.j2)
    ok: [stirling.devops.develop] => (item=/home/dittrich/dims/git/ansible-dims-playbooks/roles/base/templates/NetworkManager/NetworkManager.conf.j2)

    TASK [base : include] *********************************************************************************************************************************
    Wednesday 19 July 2017  19:53:42 -0700 (0:00:01.283)       0:01:01.983 ********
    included: /home/dittrich/dims/git/ansible-dims-playbooks/tasks/dnsmasq.yml for dellr510.devops.develop, stirling.devops.develop

    TASK [base : Only "update_cache=yes" if >3600s since last update] *************************************************************************************
    Wednesday 19 July 2017  19:53:43 -0700 (0:00:01.153)       0:01:03.136 ********
    fatal: [dellr510.devops.develop]: FAILED! => {
        "changed": false,
        "failed": true
    }

    MSG:

    Failed to lock apt for exclusive operation

    changed: [stirling.devops.develop]

    TASK [base : Make backports present for APT on Debian jessie] *****************************************************************************************
    Wednesday 19 July 2017  19:54:02 -0700 (0:00:18.053)       0:01:21.190 ********
    skipping: [stirling.devops.develop]

     . . .

    TASK [base : iptables v6 rules (CoreOS)] **************************************************************************************************************
    Wednesday 19 July 2017  19:54:55 -0700 (0:00:01.547)       0:02:14.954 ********
    skipping: [stirling.devops.develop] => (item=/home/dittrich/dims/git/ansible-dims-playbooks/roles/base/templates/iptables/rules.v6.j2)

    RUNNING HANDLER [base : restart dnsmasq] **************************************************************************************************************
    Wednesday 19 July 2017  19:54:56 -0700 (0:00:01.074)       0:02:16.029 ********
    ^C [ERROR]: User interrupted execution


    $ ansible -m shell -a "ps auxwww | grep dpkg"  bootstrap
    dellr510.devops.develop | SUCCESS | rc=0 >>
    ansible  18600  0.0  0.0   4460   872 ?        S    19:58   0:00 /bin/sh -c ps auxwww | grep dpkg
    ansible  18602  0.0  0.0  15956  2240 ?        S    19:58   0:00 grep dpkg

    stirling.devops.develop | SUCCESS | rc=0 >>
    ansible  26519  0.0  0.0   4460   796 ?        S    19:58   0:00 /bin/sh -c ps auxwww | grep dpkg
    ansible  26521  0.0  0.0  15956  2164 ?        S    19:58   0:00 grep dpkg

    $ ansible -m shell -a "ps auxwww | grep apt"  bootstrap
    dellr510.devops.develop | SUCCESS | rc=0 >>
    ansible  18614  0.0  0.0   4460   776 ?        S    19:58   0:00 /bin/sh -c ps auxwww | grep apt
    ansible  18616  0.0  0.0  15956  2268 ?        S    19:58   0:00 grep apt

    stirling.devops.develop | SUCCESS | rc=0 >>
    ansible  26533  0.0  0.0   4460   648 ?        S    19:58   0:00 /bin/sh -c ps auxwww | grep apt
    ansible  26535  0.0  0.0  15956  2132 ?        S    19:58   0:00 grep apt

    $ ansible -m shell -a "ps auxwww | egrep -i 'apt|dpkg|package|update'" bootstrap
    stirling.devops.develop | SUCCESS | rc=0 >>
    ansible   4278  0.0  0.0 506496 19956 ?        Sl   Jul18   0:00 update-notifier
    ansible  26548  0.0  0.0   4460   684 ?        S    19:58   0:00 /bin/sh -c ps auxwww | egrep -i 'apt|dpkg|package|update'
    ansible  26550  0.0  0.0  13656  2112 ?        S    19:58   0:00 egrep -i apt|dpkg|package|update

    dellr510.devops.develop | SUCCESS | rc=0 >>
    ansible   2680  0.0  0.1 506492 21928 ?        Sl   Jul18   0:00 update-notifier
    ansible  18625  0.0  0.0   4460   780 ?        S    19:58   0:00 /bin/sh -c ps auxwww | egrep -i 'apt|dpkg|package|update'
    ansible  18627  0.0  0.0  13660  2240 ?        S    19:58   0:00 egrep -i apt|dpkg|package|update

    $ ansible -m shell -a "sudo killall update-notifier"  bootstrap
     [WARNING]: Consider using 'become', 'become_method', and 'become_user' rather than running sudo

    dellr510.devops.develop | FAILED | rc=1 >>
    sudo: no tty present and no askpass program specified

    stirling.devops.develop | FAILED | rc=1 >>
    sudo: no tty present and no askpass program specified

    $ ansible -m shell -a "killall update-notifier"  bootstrap
    dellr510.devops.develop | SUCCESS | rc=0 >>


    stirling.devops.develop | SUCCESS | rc=0 >>


    $ ansible -m shell -a "ps auxwww | egrep -i 'apt|dpkg|package|update'" bootstrap
    dellr510.devops.develop | SUCCESS | rc=0 >>
    ansible  18652  0.0  0.0   4460   760 ?        S    20:00   0:00 /bin/sh -c ps auxwww | egrep -i 'apt|dpkg|package|update'
    ansible  18654  0.0  0.0  13656  2104 ?        S    20:00   0:00 egrep -i apt|dpkg|package|update

    stirling.devops.develop | SUCCESS | rc=0 >>
    ansible  26583  0.0  0.0   4460   792 ?        S    20:00   0:00 /bin/sh -c ps auxwww | egrep -i 'apt|dpkg|package|update'
    ansible  26585  0.0  0.0  13656  2108 ?        S    20:00   0:00 egrep -i apt|dpkg|package|update

    $ ansible-playbook -i inventory /home/dittrich/dims/git/ansible-dims-playbooks/playbooks/hosts/vmhost.devops.local.yml -e host=bootstrap

..


.. attention::

    Do not forget to add the host being bootstrapped to the ``all`` group in the
    inventory. While it may be accessible by simply being listed in the ``children``
    subgroup with an ``ansible_host`` value like shown earlier, it won't have its
    ``host_vars`` file be loaded unless it is included in the ``all`` group.

    This problem would go away if all of the variables formerly placed in
    ``host_vars`` files were moved directly into the inventory files instead.

..
