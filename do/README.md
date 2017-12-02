DIMS Build Out on DigitalOcean
==============================

This directory contains helper scripts for generating Terraform plans to
create droplets using [DigitalOcean](https://www.digitalocean.com/).
These droplets can then be provisioned
using [ansible-dims-playbooks](https://github.com/uw-dims/ansible-dims-playbooks)
playbooks and inventory files.

Droplet Provisioning Using Ansible
----------------------------------

Initial experimentation with building out DIMS components using
DigitalOcean droplets involved using the Ansible `digital_ocean`
module. That modules requires the Python "dopy" module first be
installed using pip.

```
$ ansible-playbook -i inventory/ playbooks/do_provision.yml -vvvv
```

See also:

* http://albertogrespan.com/blog/creating-digitalocean-images-with-packer/
* https://www.digitalocean.com/community/tutorials/how-to-create-digitalocean-snapshots-using-packer-on-centos-7


Droplet Provisioning Using Terraform
------------------------------------

While researching how to use Terraform on DigitalOcean, the Cisco
[Mantl](https://github.com/mantl/mantl) was found. Mantl follows a very similar
path as the DIMS Project took, combining multiple open source components into a
small-scale distributed system.

Mantl uses a multi-cloud provisioning model that includes Terraform as just one
of many cloud providers. Experimentation turned to following this model for
provisioning DIMS components.

For information on how to use the DigitalOcean provider with Terraform,
see:

* https://www.digitalocean.com/community/tutorials/how-to-use-terraform-with-digitalocean
* https://gist.github.com/thisismitch/91815a582c27bd8aa44d

To get a list of available DigitalOcean images, do:


```
$ curl -X GET --silent "https://api.digitalocean.com/v2/images?per_page=999" -H "Authorization: Bearer $DO_API_TOKEN" | python -m json.tool | less
```

A modified version of the `digital\_ocean.py` dynamic inventory file is
being used for augmenting the YAML inventory files in the `$PBR/inventory/`
directory.

```
$ make hosts
red.devops.local
orange.devops.local
purple.devops.local
blue.devops.local
```

When droplets are created using `make create`, the SSH public keys and
fingerprints are extracted from the `terraform` log output. The files are
placed in the `fingerprints` and `known\_hosts` directories.

```
$ tree fingerprints known_hosts
fingerprints
├── blue.devops.local
│   └── ssh-rsa.fingerprint
├── orange.devops.local
│   ├── ssh-ed25519.fingerprint
│   └── ssh-rsa.fingerprint
├── purple.devops.local
│   ├── ssh-ed25519.fingerprint
│   └── ssh-rsa.fingerprint
└── red.devops.local
    ├── ssh-ed25519.fingerprint
    └── ssh-rsa.fingerprint
known_hosts
├── blue.devops.local
│   └── ssh-rsa.known_hosts
├── orange.devops.local
│   ├── ssh-ed25519.known_hosts
│   └── ssh-rsa.known_hosts
├── purple.devops.local
│   ├── ssh-ed25519.known_hosts
│   └── ssh-rsa.known_hosts
└── red.devops.local
    ├── ssh-ed25519.known_hosts
    └── ssh-rsa.known_hosts

8 directories, 14 files
```

See also:

* https://github.com/landro/terraform-digitalocean/blob/master/terraform.tf

* How to create a VPN using Terraform in DigitalOcean - Infrastructure
  tutorial part one
  https://techpunch.co.uk/development/how-to-create-a-vpn-using-terraform-in-digital-ocean-infrastructure-tutorial-part-one
