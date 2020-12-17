#!/bin/bash

# userdel -r -f alarm

mkdir -p /root/.ssh
touch /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config

sed -i 's/-account   \[success=1 default=ignore\]  pam_systemd_home.so/# -account   \[success=1 default=ignore\]  pam_systemd_home.so  as per https:\/\/github.com\/systemd\/systemd\/issues\/17266/' /etc/pam.d/system-auth

systemctl enable sshd.service
