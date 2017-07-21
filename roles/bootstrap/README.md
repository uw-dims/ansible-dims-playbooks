Role Name
=========

This role is used to facilitate bootstrapping a new computer, be it a server to act as a baremetal host, a developer laptop, or even a new virtual machine.

Requirements
------------

The host being bootstrapped must be accessible remotely, preferably using an account 'ansible' that will be used as the ``ansible_user`` account, via SSH. You can set a password for initial access and use ``--ask-pass`` to enter the password.

Role Variables
--------------


Dependencies
------------

This role is dependant on DIMS Ansible playbooks (``ansible-dims-playbooks``) global variables, operating system codename-specific variables for required packages, and a private directory that includes the site-specific inventory defining variables to use for configuring the host.

Example Playbook
----------------

A playbook exists in the ``ansible-dims-playbooks`` repository in the directory ``playbooks/bootstrap.yml``. Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    $ ansible-playbook --become -i $GIT/private-develop/inventory \
    > $PBR/playbooks/bootstrap.yml -e host=red.devops.local

License
-------

Berkely Three Clause License (see LICENSE.txt).

Author Information
------------------

David Dittrich  dittrich@u.washington.edu
