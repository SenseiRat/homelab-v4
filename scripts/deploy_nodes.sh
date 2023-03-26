#!/bin/bash

ANSIBLE_SSH_USER="ansible"
ANSIBLE_SSH_PATH="/home/sean/.ssh/ansible_id_rsa"

if [[ ! -z $1 ]]; then
   ANS_TAGS="-t ${@}"
else
   ANS_TAGS=""
fi
set -x
ansible-playbook \
    --forks 5 \
    --inventory ../hosts.yml \
    --user "$ANSIBLE_SSH_USER" \
    --private-key "$ANSIBLE_SSH_PATH" \
    $ANS_TAGS \
    ../playbooks/deploy_nodes.yml
