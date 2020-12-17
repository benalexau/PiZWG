#!/bin/bash
pacman -S --noconfirm prometheus-node-exporter
echo 'NODE_EXPORTER_ARGS="--collector.systemd"' > /etc/conf.d/prometheus-node-exporter
systemctl enable prometheus-node-exporter.service
