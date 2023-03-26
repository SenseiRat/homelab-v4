#!/bin/bash

ANSIBLE_SSH_USER="ansible"
ANSIBLE_SSH_PATH="/home/sean/.ssh/ansible_id_rsa"

if [[ $1 == "discovery" ]]; then
    sudo nmap -sn 192.168.10.0/24
fi

if [[ $1 == "initsd" ]]; then
    xzcat /home/sean/Downloads/20220808_raspi_4_bookworm.img.xz | sudo dd of=/dev/sde bs=64k oflag=dsync status=progress
    sleep 2

    mkdir -p /tmp/rpi
    sudo mount /dev/sde1 /tmp/rpi
    PUB_KEY=$(cat /home/sean/.ssh/id_rsa.pub)
    sudo sed -i "s|#root_authorized_key=|root_authorized_key=$PUB_KEY|" /tmp/rpi/sysconf.txt
    sudo umount /tmp/rpi

    mkdir -p /tmp/rpi2
    sudo mount /dev/sde2 /tmp/rpi2
    read -p 'IP Address: ' IP_ADDRESS
    echo -e "auto eth0\niface eth0 inet static\n  address $IP_ADDRESS\n  netmask 255.255.255.0\n  gateway 192.168.10.1\n  dns-nameservers 8.8.8.8 8.8.4.4\n" > /tmp/rpi2/etc/network/interfaces.d/eth0 
    sudo echo "nameserver 8.8.8.8" > /tmp/rpi2/etc/resolv.conf
    sudo umount /tmp/rpi2
fi

if [[ $1 == "facts" ]]; then
	if [[ -z $2 ]]; then
		HOSTS="all"
	else
		HOSTS=$2
	fi

	ansible "$HOSTS" \
		--inventory ../hosts.yml \
		--user "$ANSIBLE_SSH_USER" \
		--private-key "$ANSIBLE_SSH_PATH" \
		-m setup
fi

if [[ $1 == "forward" ]]; then
    sudo sysctl net.ipv4.ip_forward=1 
fi

if [[ $1 == "portscan" ]]; then
    sudo nmap -sTU "$2"
fi
