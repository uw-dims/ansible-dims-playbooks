Digital Ocean Droplet Provisioning
==================================

Initial experimentation with building out DIMS components using
Digital Ocean droplets involved using the Ansible `digital_ocean`
module. That modules requires the Python "dopy" module first be
installed using pip.

```
$ ansible-playbook -i inventory/ playbooks/do_provision.yml -vvvv
```

See also:

* http://albertogrespan.com/blog/creating-digitalocean-images-with-packer/
* https://www.digitalocean.com/community/tutorials/how-to-create-digitalocean-snapshots-using-packer-on-centos-7

