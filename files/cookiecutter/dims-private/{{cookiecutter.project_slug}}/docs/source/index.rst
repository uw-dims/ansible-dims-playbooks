.. {{ cookiecutter.project_slug }} documentation master file, created by
   cookiecutter on {{ cookiecutter.release_date }}.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

{{ cookiecutter.project_name }} v |release|
.. FIX_UNDERLINE

This document (version |release|) describes the
{{ cookiecutter.project_name }} (``{{ cookiecutter.project_slug }}``
for short) repository contents.

.. warning::

    This repo is *NOT FOR PUBLICATION*.
    
    It should *NOT BE PUSHED* to any public repository.

..

This repository holds configuration related information that
is not for publication, but are required for instantiating
a system or service using a public open source repository.

* The former -- configuration and related information
  -- includes secrets and sensitive information (e.g.,
  SSH private keys, Ansible vault passwords, SSL
  certificate authority files), and sensitive
  configuration details or proprietary information (e.g.,
  Ansible inventory details, template contents that
  may include firewall rules or IP addresses, sensitive
  email addresses), that are not appropriate for storage
  in a public source repository.

* The latter -- open source repository contents --
  includes Ansible playbooks that describe how to
  configure a system, program source code, and
  generic user documentation.


.. toctree::
   :maxdepth: 3
   :numbered:
   :caption: Contents:

   introduction
   license

.. sectionauthor:: {{ cookiecutter.full_name }} {{ cookiecutter.email }}

.. include:: <isonum.txt>

Copyright |copy| {{ cookiecutter.project_copyright_date }} {{ cookiecutter.project_copyright_name }}. All rights reserved.
