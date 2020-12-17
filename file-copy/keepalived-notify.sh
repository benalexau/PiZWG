#!/bin/bash

TYPE=$1
NAME=$2
STATE=$3

if [ "$STATE" == "MASTER" ]; then
  # Enable monitor.sh to activate USB serial device and ser2net service
  touch /tmp/ser2net-enable
else
  if [ -f /tmp/ser2net-enable ]; then
    # Reboot immediately due to unexpected loss of master state
    sudo reboot
  fi
fi
