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

.. todo::

     Missing steps here...

..

We now validate the temporary ``bootstrap`` group that defines the two hosts we
are setting up.

.. code-block:: none

    $ export ANSIBLE_HOST_KEY_CHECKING=False
    $ ansible -m raw -a uptime --ask-pass bootstrap
    SSH password:
    dellr510.devops.develop | SUCCESS | rc=0 >>
     22:21:50 up  3:37,  3 users,  load average: 0.78, 1.45, 1.29
    Shared connection to 140.142.29.186 closed.


    stirling.devops.develop | SUCCESS | rc=0 >>
     22:21:51 up  4:15,  3 users,  load average: 2.45, 1.49, 1.18
    Shared connection to 140.142.29.161 closed.

..

Use the ``ansible`` account password to now use Ansible
ad-hoc mode with the ``authorized_key`` module to insert the
``ansible`` SSH private key in the account on the remote
systems, using the ``file`` lookup and the ``dims.function``
shell utility function to get the path to the private
key, adding the ``.pub`` extension for the public key.

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

Now remove the ``--ask-pass`` option to instead use the specified
SSH private key to validate that standard remote access with
Ansible will work.

.. code-block:: none

    $ ansible -m raw -a uptime  bootstrap
    dellr510.devops.develop | SUCCESS | rc=0 >>
     22:33:44 up  3:49,  3 users,  load average: 1.14, 0.81, 0.99
    Shared connection to 140.142.29.186 closed.


    stirling.devops.develop | SUCCESS | rc=0 >>
     22:33:44 up  4:27,  3 users,  load average: 1.12, 1.10, 1.03
    Shared connection to 140.142.29.161 closed.

..
