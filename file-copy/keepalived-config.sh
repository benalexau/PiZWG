#!/bin/bash

until ip addr show eth0 | grep -q 'inet '; do
  sleep 1
done

MAC=$(ip link show eth0 | grep link/ether | awk '{print $2}' | sed 's/://g')
HOST_OCTET=$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d '/' -f 1 | cut -d '.' -f 4)
SUBNET=$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d '/' -f 1 | cut -d '.' -f 1,2,3)

cp /etc/keepalived/keepalived.conf.template /var/run/keepalived.conf

sed -i "s/_ROUTER_ID_/$MAC/g"       /var/run/keepalived.conf
sed -i "s/_PRIORITY_/$HOST_OCTET/g" /var/run/keepalived.conf
sed -i "s/_VIP_/$SUBNET.254/g"      /var/run/keepalived.conf
