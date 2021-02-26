#!/bin/bash

# Install monitor service dependencies
pacman -S --noconfirm uhubctl
pacman -S --noconfirm inotify-tools
pacman -S --noconfirm python

# Install monitor service
mv /tmp/file-copy/monitor.service /etc/systemd/system
mv /tmp/file-copy/monitor.sh /usr/bin
mv /tmp/file-copy/monitor.py /usr/bin
chmod +x /usr/bin/monitor.sh
chmod +x /usr/bin/monitor.py
systemctl enable monitor.service
