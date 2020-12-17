#!/bin/bash
pacman -S --noconfirm ser2net

# Relatively long timeout (300s) is fail-safe fallback; clients should use far
# smaller timeouts (ie socat -T30 or whatever makes sense for the workload).
# The monitor.service detects any disconnect or reconnect and reboots the host.
cat <<EOM >>/etc/ser2net/ser2net.yaml
connection: &3333
  accepter: ssl(clientauth),tcp,3333
  timeout: 300
  enable: on
  connector: serialdev,/dev/ttyACM0,115200n81,LOCAL
  options:
    authdir: /usr/share/ser2net/auth
    kickolduser: false
EOM

# Ensure ser2net loads with a local control port for use by monitor.py
mkdir /etc/systemd/system/ser2net.service.d
cat <<EOM >>/etc/systemd/system/ser2net.service.d/ser2net-control.conf
[Service]
ExecStart=
ExecStart=/usr/bin/ser2net -n -p localhost,4444
EOM
