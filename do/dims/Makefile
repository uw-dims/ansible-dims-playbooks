# vim:ft=make:

SHELL=/bin/bash
INVENTORY=../../environments/dev_digitalocean/inventory
INVENTORY_GENERATED=$(INVENTORY)/digital_ocean/nodes-generated.yml

.PHONY: help
help:
	@echo "Usage: make [something]"
	@echo ""
	@echo "Where 'something' is one of these:"
	@echo " init - initialize terraform state (this is automatic)"
	@echo " hosts - show list of hosts in group 'do'"
	@echo " plan - show the terraform plan for the current state"
	@echo " provider - generate terraform provider.tf file for creating nodes in group 'do'"
	@echo " create - applies terraform plan to create droplets for hosts in group 'do'"
	@echo " destroy - destroys droplets for hosts in group 'do'"
	@echo " graph - generate terraform graph (output is 'graph.png')"
	@echo " ping - does Ansible ad-hoc ping of hosts in group 'do'"
	@echo " addkeys - adds SSH host public keys to selected known_hosts files"
	@echo " removekeys - removes SSH host public keys from selected known_hosts files"
	@echo " dumpvars - produces Ansible debug output of vars for hosts in group 'do'"
	@echo " images - lists available digitalocean images"
	@echo " test - run pre-requisite tests for using terraform with digitalocean"
	@echo ""
	@echo " The default if you just type 'make' is the same as 'make pdf'"

.PHONY: init
init: terraform.tfstate

terraform.tfstate:
	terraform init

.PHONY: droplets
droplets:
	ansible -i $(INVENTORY)/digital_ocean.py $(DIMS_ANSIBLE_ARGS) --list-hosts all |\
	       sed 's/ *//g' |\
	       tail -n +2

.PHONY: hosts
hosts:
	$(MAKE) --always-make inventory/hosts

inventory/hosts:
	(echo "[droplets]"; ansible -i $(INVENTORY) $(DIMS_ANSIBLE_ARGS) --list-hosts do|sed 's/ *//g'|tail -n +2) | tee inventory/hosts

.PHONY: etchosts
etchosts:
	@#ansible -i $(INVENTORY) -m debug -a 'msg="{{ hostvars[inventory_hostname].ansible_default_ipv4.address }} {{ inventory_hostname }}"' do | grep '\"msg\":' | awk -F\" '{print $$4; }'
	@ansible -i $(INVENTORY) -m debug -a 'msg="{{ hostvars[inventory_hostname].ansible_host }} {{ inventory_hostname }}"' do | grep '\"msg\":' | awk -F\" '{print $$4; }'

.PHONY: images
images:
	curl -X GET --silent "https://api.digitalocean.com/v2/images?per_page=999" -H "Authorization: Bearer $(DO_API_TOKEN)" | python -m json.tool | less

.PHONY: provider
provider:
	ansible-playbook -i $(INVENTORY) $(DIMS_ANSIBLE_ARGS) -vvvv create-provider.tf.yml

.PHONY: plan
plan: init
	terraform plan

.PHONY: graph
graph: graph.png
	@if [[ "$(shell uname -s)" == "Darwin" ]]; then open graph.png; fi
	@if [[ "$(shell uname -s)" == "Linux" && ! -z "$(shell which evince)" ]] ; then (evince graph.png &); fi
	@if [[ "$(shell uname -s)" == "Linux" && ! -z "$(shell which xdg-open)" ]] ; then (xdg-open graph.png &); fi

graph.png: init
	terraform graph | dot -Tpng -o graph.png

inventory/nodes-generated.yml:
	./do_post.sh inventory/

$(INVENTORY_GENERATED): inventory/nodes-generated.yml
	cp inventory/nodes-generated.yml $(INVENTORY_GENERATED)

.PHONY: sshkeys
	../../files/common-scripts/keys.host.extract.sh < terraform.log

.PHONY: insertpubkey
insertpubkey:
	terraform apply -target=digitalocean_ssh_key.default -auto-approve

.PHONY: destroypubkey
destroypubkey:
	terraform destroy -target=digitalocean_ssh_key.default --force

.PHONY: create
create: init hosts provider
	$(MAKE) insertpubkey && sleep 2
	terraform apply | tee -a terraform.log | ../../files/common-scripts/keys.host.extract.sh
	$(MAKE) --always-make $(INVENTORY_GENERATED)
	$(MAKE) addkeys
	$(MAKE) ping

.PHONY: bootstrap
bootstrap: init
	(terraform plan | grep -q "No changes") || $(MAKE) create
	ansible-playbook -i $(INVENTORY) $(DIMS_ANSIBLE_ARGS) ../../playbooks/bootstrap.yml \
		-e host=do
	ansible-playbook -i $(INVENTORY) $(DIMS_ANSIBLE_ARGS) ../../playbooks/groups/ca-certs.yml \
		-e host=infra \
		-e ca_init=true \
		-e ca_force_certify_nodes=true \
		-e ca_force_create=true
	ansible-playbook -i $(INVENTORY) $(DIMS_ANSIBLE_ARGS) ../../playbooks/groups/ca-certs.yml \
		-e host=instances

.PHONY: addkeys
addkeys:
	ansible-playbook -i $(INVENTORY) $(DIMS_ANSILE_ARGS) ../../playbooks/do_rekey.yml \
		-e known_hosts_root=$(shell pwd)/known_hosts \
		--ask-sudo-pass

.PHONY: removekeys
removekeys:
	-ansible-playbook -i $(INVENTORY) $(DIMS_ANSIBLE_ARGS) ../../playbooks/do_rekey.yml \
		-e remove_keys=true \
		--ask-sudo-pass

.PHONY: dumpvars
dumpvars:
	ansible -i $(INVENTORY) $(DIMS_ANSIBLE_ARGS) \
		-m debug -a "var=hostvars[inventory_hostname]" do |\
		pygmentize -ljson |\
		less -R

.PHONY: ping
ping:
	ansible -i $(INVENTORY) $(DIMS_ANSIBLE_ARGS) -m ping do

.PHONY: test
test:
	bats do.bats

.PHONY: destroy
destroy:
	terraform destroy --force
	-$(MAKE) removekeys
	-rm -rf fingerprints/ known_hosts/
	-rm -f ansible-digital_ocean.cache
	-rm -f inventory/hosts inventory/nodes-generated.yml $(INVENTORY_GENERATED)
	-rm -f do_post.log provider.tf graph.png
	-$(MAKE) destroypubkey

.PHONY: spotless
spotless:
	-rm -f terraform.log
	-rm -f terraform.tfstate terraform.tfstate.backup

# vim: ft=make:
