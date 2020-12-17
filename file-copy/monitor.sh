#!/bin/bash

###########################################################################
# Initially verify and then deactivate USB serial device
###########################################################################

if [[ ! -f /etc/ser2net/ser2net.key ]]; then
  echo "/etc/ser2net/ser2net.key not found; run pizwg-setup or pizwg-restore"
  exit 1
fi

###########################################################################
# Initially verify and then deactivate USB serial device
###########################################################################

echo "Verifying USB serial device available (should be on boot)"
if [ ! -c /dev/ttyACM0 ]; then
  echo "Error: USB serial device not found"
  exit 1
fi

echo "Powering off the USB serial device hub"
uhubctl -l 1-1 -a off

echo "Removing USB serial device"
udevadm trigger --action=remove /sys/bus/usb/devices/1-1*

echo "Verifying USB serial device removed"
while [ -c /dev/ttyACM0 ]; do
  inotifywait -t 30 -e delete --format '%f' --quiet /dev
  if [ $? -eq 2 ] && [ -c /dev/ttyACM0 ]; then
    echo "Error: USB serial device remains available despite hub power down"
    exit 1
  fi
done

###########################################################################
# Wait for notice this node is required to be active (ie keepalived master)
###########################################################################

echo "Waiting for /tmp/ser2net-enable to exist"
while [ ! -f /tmp/ser2net-enable ]; do
  inotifywait -e create --format '%f' --quiet /tmp
done

###########################################################################
# Activate USB serial device
###########################################################################

echo "Powering up the USB serial device port"
uhubctl -l 1-1 -a on

echo "Waiting for the USB serial device to appear as a device"
while [ ! -c /dev/ttyACM0 ]; do
  inotifywait -t 10 -e create --format '%f' --quiet /dev
  if [ $? -eq 2 ] && [ ! -c /dev/ttyACM0 ]; then
    echo "Error: USB serial device remains unavailable despite port power"
    exit 1
  fi
done

###########################################################################
# Activate ser2net and wait until it exits or times out
# (while a USB serial device may be removed while waiting for an incoming
# connection, or even be removed during an active connection, eventually a
# connection will happen and either ser2net and/or the remote socat will
# time out and close the TCP/IP connection, which in turn triggers
# monitor.py to exit)
###########################################################################

echo "Starting ser2net"
systemctl start ser2net.service

echo "Running port monitor"
/usr/bin/monitor.py

###########################################################################
# Restart with a clean slate
###########################################################################

echo "Rebooting"
reboot
