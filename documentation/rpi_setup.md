# Setting up the Raspberry Pi's

## Manual settings to prep SD card
1. Download the most current version of the tested Debian for Raspberry Pi
   - *https://raspi.debian.net/tested-images/*
2. Flash to SD card with `dd`
   - `xzcat <file> | sudo dd of=/dev/<SD card> bs=64k oflag=dsync status=progress`
   - *https://raspi.debian.net/how-to-image/*
3. Mount the first partition on the SD card
4. Edit sysconf.txt and add a root password
5. If networking needs to be configured
   1. mount the second partition
   2. edit /etc/network/interfaces.d/eth0
   3. add these lines to it, changing the static to the correct IP
      ```
      auto eth0
      iface eth0 inet static
         address 192.168.10.XX
         netmask 255.255.255.0
         gateway 192.168.10.1
         dns-nameservers 8.8.4.4 8.8.8.8
      ```
5. Boot the Raspberry Pi with the SD card in it

## Ansible network config should take over here
1. Set static IP address and disable IPv6
   - `echo -e "auto eth0\niface eth0 inet static\n address 192.168.1.200\n netmask 255.255.255.0\n gateway 192.168.1.1\n dns-domain nomad-00.starnes.cloud\n dns-nameservers 8.8.8.8" > /etc/network/interfaces.d/eth0`
2. Set hostname `echo PL-NOMAD-00 > /etc/hostname && sed -i 's/localhost/localhost PL-NOMAD-00/g' /etc/hosts && hostnamectl set-hostname PL-NOMAD-00`
   - *https://www.cyberciti.biz/faq/debian-change-hostname-permanently/*
3. ~~Install NTP and configure to sync times for devices~~ *installed and configured by default on debian systems*
4. Set DNS servers to local IPs and one failover DNS

## Ansible userconfig should take over here
1. Create admin user `useradd -d /home/sean -s /bin/bash -m -U sean`
2. Add admin user to sudoer's group `usermod -aG sudo sean`
3. Add ssh key to admin user `mkdir /home/sean/.ssh && vim /home/sean/.ssh/authorized_keys && chown -R sean:sean /home/sean/.ssh `
4. Set password for admin user `passwd sean`
5. Create ansible user `useradd -d /home/ansible -s /bin/bash -m -U -r ansible`
6. Add ansible user to sudoer's group `usermod -aG sudo ansible`
7. Allow ansible user passwordless sudo `echo "ansible ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/ansible-sudoers-rule`
8. Add ssh key to ansible user `mkdir /home/ansible/.ssh && vim /home/ansible/.ssh/authorized_keys && chown -R ansible:ansible /home/ansible/.ssh `
9. Test ssh keys for both users

## Ansible security config should take over here
1. apt update && apt upgrade
2. install sudo
3. Disable PasswordAuthentication in SSH
4. Disable PermitRootLogin in SSH
5. Remove authorized_keys file from root
6. Remove password from root account `passwd -l root`
7. Install rkhunter
8. Install clamav
9. Install LMD
10. Install Lynis
11. Install AIDE
12. Install tiger
13. Install chkrootkit

## Deploy NFS to storage device and configure on servers and clients
1. Clients just need nfs-common and no service running

## Install Docker role
*https://docs.docker.com/engine/install/debian/*
1. Install ca-certificates, curl, gnupg
2. Add Docker GPG key `curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg`
3. Add Docker repository `echo "deb [arch=arm64 signed-by=/etc/apt/trusted.gpg.d/docker.gpg] https://download.docker.com/linux/debian bullseye stable" > /etc/apt/sources.list.d/docker.list`
4. `apt update`
5. `apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin`
6. Start and enable docker service

## Install Consul role

## Install Vault
1. Install curl, gnupg
2. Add Hashicorp GPG key `curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/hashicorp.gpg`
3. Add Hashicorp repository to apt `echo "deb [arch=arm64] https://apt.releases.hashicorp.com bookworm main" > /etc/apt/sources.list.d/hashicorp.list`
4. `apt update`
5. `apt install vault`
6. Configure Vault: https://developer.hashicorp.com/vault/tutorials/day-one-consul/ha-with-consul

```
root@PL-NOMAD-00:/etc/vault.d# vault operator init
Get "https://127.0.0.1:8200/v1/sys/seal-status": dial tcp 127.0.0.1:8200: connect: connection refused
root@PL-NOMAD-00:/etc/vault.d# vault operator init -address=http://192.168.1.200:8200
```
7. Output and store Vault Root Tokens
8. ~~Add nomad user to vault group~~
7. Loadbalance vault: https://www.simplecto.com/make-traefik-loadbalance-docker-and-external-services/

## Install Nomad role
*https://developer.hashicorp.com/nomad/docs/install*
1. Install curl, gnupg
2. Add Hashicorp GPG key `curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/hashicorp.gpg`
3. Add Hashicorp repository to apt `echo "deb [arch=arm64] https://apt.releases.hashicorp.com bookworm main" > /etc/apt/sources.list.d/hashicorp.list`
4. `apt update`
5. `apt install nomad`
6. Configure nomad to run in a datacenter
6. Start and enable nomad service

## Utilize Ansible to deploy Nomad jobs in this order
1. Deploy Vault (https://github.com/hashicorp/nomad-guides/blob/master/application-deployment/vault/vault_exec.hcl)
1. Storage Controller (https://gitlab.com/rocketduck/csi-plugin-nfs/-/tree/main/nomad)
   - also using (https://github.com/kubernetes-csi/csi-driver-nfs)
      - reference: https://github.com/thatsk/nfs-csi
2. Storage Node
3. Traefik
   - https://doc.traefik.io/traefik/
   - letsencrypt volume
4. Watchtower
4. Bitwarden
5. Pihole
   - Pihole Storage Volume
   - dnsmasq
6. PostGres
   - Postgres database volume
   - Create gitea user
   - Create gitea database
7. PG Admin
8. Gitea
   - Gitea Storage Volume
9. Drone.io
   - https://docs.drone.io/server/provider/gitea/
10. SSL certificates
11. Authelia
12. Docker Registry (or other container registry)
12. Redis
12. RabbitMQ
12. AWX
12. Mediawiki



## TODO
1. Automatically import scheduled security scans into SIEM solution
2. Set up dynamic dns script to run on schedule
3. Set up HTTPS over 53 for bypassing wifi paywalls
4. Work through lynis findings
  - libpam-tmpdir, apt-listbugs, apt-listchanges, needrestart, fail2ban
5. The bootstrap script fails to set the hostname properly, which seems to cause some issues
6. Set up prometheus or another metrics solution and configure traefik to talk to it
7. Get Lets Encrypt SSL certificates working via Traefik
8. Set up DNS entries for various services on local network
9. Implement a firewall on servers (iptables)
10. DNS forwarding for Consul (https://developer.hashicorp.com/consul/tutorials/networking/dns-forwarding#unbound-setup)
11. Fix vault domain name
12. Implement proper groups and namespaces in nomad
13. The job to restart traefik needs to add new DNS servers to the Rasp Pis before restarting the traefik job
14. Vault/Traefik integrations: https://www.hashicorp.com/partners/tech/traefik-labs
15. Add update and check stanzas to services like in this example https://github.com/hashicorp/nomad-guides/blob/master/application-deployment/redis/redis.nomad
16. Add fail2ban to security applications deployment and configure
17. Update nomad config files to dynamically apply the number of servers in the cluster
18. Store consul tokens and vault token/keys in vault after it has been initialized
19. Stop traefik and other big jobs from deploying to the small Rasp Pi
20. Investigate Adminer to replace pgadmin (and phpMyAdmin)
21. Figure out what permissions gitea needs so I can change that directory from being 777 perms

## Notes
1. Clear unused nomad jobs: `nomad job stop -purge <job name>`
2. Clear failed allocs from jobs: `nomad system reconcile summaries`
3. CF_DNS_API_KEY: `FNMa4fnLZPJ43p26PB1xvZ3hL90lKgTB11_9txbJ`
4. Initial Vault Root Token: `hvs.qGo3FpQqEnvcxqsZd2Qjl3VZ`
5. Vault Unseal Keys
      ```
      Unseal Key 1: l/NDzUnYBQcRNVnQa72Tlt61XihH+dSAWqATufnqXweI
      Unseal Key 2: slHxGqgt7EJ95savxsDz67b6aEFRzHkkyHPmgQjiTRA2
      Unseal Key 3: yJXHEYcTQD5TnGsD1L3+1nRoO9vzDNI7v4cL2T1E5FUB
      Unseal Key 4: heiI9HH2vEwA+k6fCbRLKNQVMDpYNNGgKNCtiL32KhVy
      Unseal Key 5: fz+EQnGilV9Row8YDrO7Wqv3WHMSCxgVjezCeiX+rEM0
      ```
6. Consul Token: `1uR6BsxRj9Yx188ggu8qjaoLJJI+2ek3ThcOJABBmIw=`
7. Consul Bootstrap Token: `50be2d98-e902-a115-861a-d64a2063b2b7`
8. Consul Node Token: `1f1fa6e8-45f2-cf02-2aa8-63adf4a762c9`