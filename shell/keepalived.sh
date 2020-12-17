#!/bin/bash
# Install keepalived
pacman -S --noconfirm keepalived

# Create a user to run scripts
useradd -r -s /usr/bin/nologin keepalived_script

# Use writable file system for keepalived.conf
mkdir /etc/systemd/system/keepalived.service.d
cat <<EOM >>/etc/systemd/system/keepalived.service.d/conf-location.conf
[Service]
ExecStartPre=/usr/bin/keepalived-config.sh
ExecStart=
ExecStart=/usr/bin/keepalived -f /var/run/keepalived.conf
EOM

mv /tmp/file-copy/keepalived-config.sh /usr/bin
chmod +x /usr/bin/keepalived-config.sh

mv /tmp/file-copy/keepalived-notify.sh /usr/bin
chmod a+rx /usr/bin/keepalived-notify.sh
pacman -S --noconfirm sudo 
echo '%keepalived_script ALL= NOPASSWD: /usr/bin/reboot' >> /etc/sudoers

mv /tmp/file-copy/keepalived.conf.template /etc/keepalived

systemctl enable keepalived.service
