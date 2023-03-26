#!/bin/bash

INIT_SSH_USER="root"
INIT_SSH_PATH="/home/sean/.ssh/ansible_id_rsa"

display_help() {
    echo "Bootstrap new network devices."
    echo "Syntax: ./bootstrap.sh -t <IP> -s <IP> -n <hostname>"
    echo -e "\t-t: Target host IP address (required)."
    echo -e "\t-s: Static IP address to be assigned (required)."
    echo -e "\t-n: Hostname desired for device (required)."
}

while getopts ":t:s:n:h" option; do
   case $option in
      t) TARGET_HOST=$OPTARG;;
      s) STATIC_IP=$OPTARG;;
      n) HOSTNAME=$OPTARG;;
      *) display_help
         exit;;
   esac
done

if [[ -z $TARGET_HOST ]]; then
    echo "No target IP address specified."
    exit 1
fi
if [[ -z $STATIC_IP ]]; then
    echo "No static IP address specified."
    exit 1
fi
if [[ -z $HOSTNAME ]]; then
    echo "No hostname specified."
    exit 1
fi

# TODO: This didn't work when bootstrapping the system
ssh -t -i "$INIT_SSH_PATH" "$INIT_SSH_USER"@"$TARGET_HOST" \
    "export DEBIAN_FRONTEND=noninteractive; apt update -yqq && apt install -yqq python3"

#ssh -t -i "$INIT_SSH_PATH" "$INIT_SSH_USER"@"$TARGET_HOST" \
#    "DEBIAN_FRONTEND=noninteractive apt install -yqq python3"

ansible-playbook \
    --forks 5 \
    --inventory "$TARGET_HOST", \
    --user "$INIT_SSH_USER" \
    --private-key "$INIT_SSH_PATH" \
    --extra-vars "@.env_bootstrap.json" \
    --extra-vars "host_ip_address=$STATIC_IP" \
    --extra-vars "host_name=$HOSTNAME" \
    ../playbooks/bootstrap.yml
