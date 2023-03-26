#!/bin/bash

ANSIBLE_SSH_USER="ansible"
ANSIBLE_SSH_PATH="/home/sean/.ssh/ansible_id_rsa"

if [[ ! -z $1 ]]; then
	   ANS_TAGS="-t ${@}"
fi

ansible-playbook \
    --forks 5 \
    --inventory ../hosts.yml \
    --user "$ANSIBLE_SSH_USER" \
    --private-key "$ANSIBLE_SSH_PATH" \
    ../playbooks/deploy_infrastructure.yml 

tput bel
