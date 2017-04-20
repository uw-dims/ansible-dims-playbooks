This directory holds filter plugins that are made available to
Ansible by adding this directory to the colon separated list
of directories in the "filter_plugins" setting in the Ansible
configuration file.

See ../roles/ansible-server/templates/ansible.cfg.j2:

  filter_plugins     = {{ ansible_base }}/ansible/filter_plugins:{{ imported_plugins }}/filter_plugins:/usr/share/ansible_plugins/filter_plugins

See also:

http://grokbase.com/t/gg/ansible-project/14btv17s4n/how-to-add-custom-jinja-filters
https://github.com/lxhunter/ansible-filter-plugins

