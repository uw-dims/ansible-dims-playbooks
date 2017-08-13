.. _introduction:

Introduction 
============


This chapter documents the DIMS Ansible playbooks
(``ansible-dims-playbooks`` for short) repository.

This repository contains the Ansible playbooks and inventory
for a development/test environment. This is conventionally
known as a ``local`` deployment, as it comprises a baremetal
host system intended to serve as an *Ansible control host*,
with a series of virtual machines to provide services.

Installation Steps
------------------

Before diving into the details, it is helpful to understand the
high level tasks that must be performed to bootstrap a functional
deployment.

* Install the base operating system for the initial Ansible
  control host that will be used for configuring the deployment
  (e.g., on a development laptop or server).

* Set up host playbook and vars files for the Ansible control host.

* Pre-populate artifacts on the Ansible control host for use
  by virtual machines under Ansible control.

* Instantiate the virtual machines that will be used to
  provide the selected services and install the base operating
  system on them, including an ``ansible`` account with initial
  password and/or SSH ``authorized_keys`` files allowing access
  from the Ansible control host.

* Set up host playbooks, host vars files, and inventory definitions
  for the selected virtual machines.

* Validate that the Ansible control host is capable of connecting
  to all of the appropriate hosts defined in the inventory using
  Ansible *ad-hoc* mode.

* Finish customizing any templates, installed scripts, and secrets
  (e.g., passwords, certificates) unique to the deployment.
