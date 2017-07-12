Variables for "all" are split out into individual files,
similar to the way roles have defaults/main.yml or
vars/main.yml files. This is an organizational technique
that takes advantage of Ansible's YAML inventory feature.
There must *only* be an "all/" directory in "group_vars/",
not both an "all.yml" file and "all/" directory.
