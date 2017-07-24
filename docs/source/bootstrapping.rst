.. _bootstrapping:

Bootstrapping a VM Host as an Ansible Controller
------------------------------------------------

This chapter walks through the process of bootstrapping a
baremetal machine to serve as a Virtualbox hypervisor
for hosting multiple Virtual Machine guests, serving as
the Ansible control host for managing their configuration.

.. todo::

    Steps here...

..

We now validate the temporary ``bootstrap`` group that defines
the two hosts we are setting up.

.. block: none

    $ export ANSIBLE_HOST_KEY_CHECKING=False
    $ ansible -i inventory/ -m raw -a uptime --ask-pass bootstrap
    SSH password:
     [WARNING]: While constructing a mapping from /home/dittrich/dims/git/private-develop/inventory/servers/nodes.yml, line 22, column 7, found a
    duplicate dict key (ansible_host). Using last defined value only.
    
     [WARNING]: While constructing a mapping from /home/dittrich/dims/git/private-develop/inventory/servers/nodes.yml, line 28, column 7, found a
    duplicate dict key (ansible_host). Using last defined value only.
    
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

.. block: none

    $ ansible -i inventory/ -m authorized_key -a "user=ansible state=present \
    > key='{{ lookup('file', '$(dims.function get_ssh_private_key_file ansible).pub') }}'" \
    > --ask-pass bootstrap
    SSH password:
     [WARNING]: While constructing a mapping from /home/dittrich/dims/git/private-develop/inventory/servers/nodes.yml, line 22, column 7, found a
    duplicate dict key (ansible_host). Using last defined value only.
    
     [WARNING]: While constructing a mapping from /home/dittrich/dims/git/private-develop/inventory/servers/nodes.yml, line 28, column 7, found a
    duplicate dict key (ansible_host). Using last defined value only.
    
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

.. block: none

    $ ansible -i inventory/ -m raw -a uptime  bootstrap
     [WARNING]: While constructing a mapping from /home/dittrich/dims/git/private-develop/inventory/servers/nodes.yml, line 22, column 7, found a
    duplicate dict key (ansible_host). Using last defined value only.
    
     [WARNING]: While constructing a mapping from /home/dittrich/dims/git/private-develop/inventory/servers/nodes.yml, line 28, column 7, found a
    duplicate dict key (ansible_host). Using last defined value only.
    
    dellr510.devops.develop | SUCCESS | rc=0 >>
     22:33:44 up  3:49,  3 users,  load average: 1.14, 0.81, 0.99
    Shared connection to 140.142.29.186 closed.
    
    
    stirling.devops.develop | SUCCESS | rc=0 >>
     22:33:44 up  4:27,  3 users,  load average: 1.12, 1.10, 1.03
    Shared connection to 140.142.29.161 closed.

.. 
