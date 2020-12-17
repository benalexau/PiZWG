#!/bin/bash

cat <<EOM >>/boot/config.txt
dtoverlay=rpi-poe
dtparam=poe_fan_temp0=10000,poe_fan_temp0_hyst=1000
dtparam=poe_fan_temp1=55000,poe_fan_temp1_hyst=5000
dtparam=poe_fan_temp2=60000,poe_fan_temp2_hyst=5000
dtparam=poe_fan_temp3=65000,poe_fan_temp3_hyst=5000
EOM
