#!/bin/bash

# Adapted from https://github.com/pikvm/pi-builder/tree/master/stages/ro
# The image is read-write by default, allowing SSH key generation and alike.
# Once setup is complete root runs /usr/local/bin/ro (which survives reboots).
# Further write access remains possible by running /usr/local/bin/rw.

mkdir -p /var/lib/private
chmod 700 /var/lib/private

cat <<EOM >>/etc/fstab-template
/dev/mmcblk0p1 /boot    vfat   ro,errors=remount-ro    0 0
tmpfs /var/lib/systemd  tmpfs  mode=0755               0 0
tmpfs /var/lib/private  tmpfs  mode=0700               0 0
tmpfs /var/log          tmpfs  nodev,nosuid            0 0
tmpfs /var/tmp          tmpfs  nodev,nosuid            0 0
tmpfs /tmp              tmpfs  nodev,nosuid,mode=1777  0 0
tmpfs /run              tmpfs  nodev,nosuid,mode=0755  0 0
EOM

cat <<EOM >>/usr/local/bin/ro
#!/bin/sh
if [[ -f /etc/fstab-template ]]; then
  sed -i -e "s|\<rw\>|ro|g" /boot/cmdline.txt
  rm /etc/fstab
  mv /etc/fstab-template /etc/fstab
fi
mount -o remount,ro /
mount -o remount,ro /boot
EOM
chmod 550 /usr/local/bin/ro

cat <<EOM >>/usr/local/bin/rw
#!/bin/sh
mount -o remount,rw /
mount -o remount,rw /boot
EOM
chmod 550 /usr/local/bin/rw

cat <<EOM >>/etc/systemd/journald.conf
[Journal]
Storage=volatile
RuntimeMaxUse=100M
EOM

mkdir -p /etc/systemd/system/logrotate.service.d
cat <<EOM >>/etc/systemd/system/logrotate.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/sbin/logrotate --verbose --state /var/tmp/logrotate.status /etc/logrotate.conf
EOM

systemctl disable systemd-random-seed
systemctl disable systemd-update-done
systemctl mask man-db.service
systemctl mask man-db.timer
