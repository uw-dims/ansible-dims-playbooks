#!/bin/bash

ansible-playbook -i ~/localhost_inv \
    -e "rabbitmq_default_user=guest" \
    -e "rabbitmq_default_user_pass=guest" \
    -e "rabbitmq_admin_user=admin" \
    -e "rabbitmq_admin_user_pass=admin" \
    $GIT/ansible-playbooks/v2/rabbitmq-docker.yml -vvvv
