#!/bin/bash
echo 'NTP=0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org' >> /etc/systemd/timesyncd.conf

echo pizwg > /etc/hostname

rm -fv /etc/resolv.conf
echo 'nameserver 1.1.1.1' >> /etc/resolv.conf
chmod 664 /etc/resolv.conf
