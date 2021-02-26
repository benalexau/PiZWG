# PiZWG

*PiZWG* allows you to easily and securely expose Z-Wave USB gateways (ZWG) to
remote clients using Raspberry Pi 4 units.

## Features

* Ten minutes from download to a production-quality Z-Wave deployment
* [Keepalived](https://github.com/acassen/keepalived) configured to deliver a
  highly available network service
* Optimised for widely available and low cost Raspberry Pi 4 hosts
* Easy backup and restore approaches for peace of mind
* File systems operate in read-only mode (eliminating SD card wear failure)
* [Prometheus](https://prometheus.io/) enabled for easy HTTP-based monitoring
* Easy, optional upgrades (minimal packages, rolling
  [Arch Linux ARM](https://archlinuxarm.org/) distribution)
* [uhubctl](https://github.com/mvp/uhubctl) disables USB ports until master
* Hosts reboot for a known-clean state after any client disconnect or timeout
* [PoE HAT](https://www.raspberrypi.org/products/poe-hat/) configured for near
  silent operation

## Motivation

Home automation systems frequently incorporate specialised low-power radio mesh
protocols like Z-Wave and ZigBee. At the centre of these meshes is a "gateway"
(or "controller"). At a hardware level these gateways are usually USB sticks
(eg the very popular [Aeotech Z-Stick](https://aeotec.com/z-wave-usb-stick/)).
Operating systems expose the USB sticks as devices (eg `/dev/ttyACM0`) and then
software like [openHAB](https://www.openhab.org/) or
[OpenZWave](http://www.openzwave.com/) uses the gateway to monitor and control
individual devices.

While the "simplest thing that could possibly work" is to install the Z-Wave
gateway on the same host as running the home automation software, there are
frequently situations where this is infeasible. For example:

* Multiple meshes (eg due to significant traffic volumes or deployed devices)
* Physical constraints (eg large home, can't centrally locate gateway, racks)
* 99.99%+ uptime SLA (eg limited traditional electrical controls like switches)
* Cluster architectures (eg using Kubernetes to transparently relocate pods)
* Engineering best practice (eg hardware hot spares, backup verification)

The usual recommendation in such situations is to deploy a single board computer
(eg a Raspberry Pi) so its attached Z-Wave gateway can be placed in a desirable
physical location. `ser2net` is then run on the single board computer and a
remote client uses `socat` to connect to it over TCP. While this approach is
mature and widely understood, it does not provide:

* High availability (what if the remote computer or its attached gateway fails?)
* Security (are unauthorised hosts prevented from using the `ser2net` port?)
* Backup verification (when was the "backup" computer and gateway last tested?)
* Fast provisioning (how long does it take to recover if the computer fails?)

## How It Works

*PiZWG* is a ready to use Raspberry Pi 4 image that uses:

* `ser2net` to expose the Z-Wave gateway as a `socat` accessible TCP service
* `keepalived` to implement VRRP for automatic virtual IP address (VIP) failover
* `uhubctl` to power on the USB hub (and Z-Wave gateway) only when "master"
* Client and server certificates to authenticate and encrypt `ser2net` traffic
* Scripts that provision the certificates and simplify their backup and restore
* Services that automatically supervise, control and reboot hosts as appropriate

This combination facilitates fast and simple deployment of a secure, highly
available Z-Wave service.

## Scope and Limitations

*PiZWG* has been tested with Aeotec Z-Stick 5 and Aeotec Z-Stick Gen 5+ USB
gateways. It will likely work with other gateways. The main requirement is that
the gateway mounts on a Linux machine as `/dev/ttyACM0`.

*PiZWG* does not use the Z-Wave serial protocol in any way. It simply powers on
and off a USB hub connected to the Raspberry Pi. This means you must:

* Provide a USB hub that can be controlled by `uhubctl`
* Properly backup and restore the Z-Wave gateway NVRAM following mesh changes

*PiZWG* does not encrypt the file system or certificates. This is because most
people prefer a Z-Wave service to be very highly available with minimal delays
or dependencies. While those interested in network bound disk encryption may
find [PiTang](https://github.com/benalexau/PiTang) helpful, there are no plans
for PiZWG to support Tang given doing so would substantially increase deployment
complexity and failure modes with very few compensating benefits.

## Getting Started

Start by preparing your hardware:

1. You will need a Raspberry Pi 4 with wired network access (PoE is optional)
2. Use a quality SD card (at least 2 GB in size) and reliable power source
3. Plug a USB hub (that can be controlled by `uhubctl`) into the Pi's upper
   black USB port
4. Plug the Z-Wave gateway into the aforementioned USB hub (not the Pi)

Next prepare the subnet that *PiZWG* host(s) will be deployed on as follows:

1. Ensure a DHCP IPv4 server is operating (address reservations not required)
2. Ensure `xxx.xxx.xxx.254` is available for use as the *PiZWG* virtual IP (VIP)
3. Ensure any existing VRRP deployment is not using router ID 254

You will need the *PiZWG* Raspberry Pi image. You can build it yourself using
the instructions at the bottom of this file, or you can [download the latest
image](https://github.com/benalexau/PiZWG/releases/tag/latest) created by
[GitHub Actions](https://github.com/benalexau/PiZWG/actions).

Write the image file to an SD card using a command such as:

```
sudo dd if=pizwg-rp4.img of=/dev/sdd bs=4M && sync
```

Put the SD card in a Raspberry Pi and boot it. The system will obtain a DHCP
address, after which you can SSH in as root (password is also "root"). Next:

1. Append your SSH key to `/root/.ssh/authorized_keys` (or use `ssh-copy-id`)
2. Logout and login again over SSH to verify the certificate was used
3. Edit `/etc/ssh/sshd_config`, changing `PermitRootLogin yes` to
   `PermitRootLogin without-password` (`mg`, `vi` and `nano` are installed)
4. Disable the root password using `passwd --lock root`

If this is your **first** *PiZWG* host, you need to:

1. Run `pizwg-setup` to generate certificates and `/root/backup.tar`
2. Copy `/root/backup.tar` (~20 KB) to a suitable remote location for backup
3. Run `ro` to make the system read only (this survives reboots)
4. Run `reboot` to verify everything works

If this is **NOT your first** *PiZWG* host, you need to:

1. Copy `/root/backup.tar` from your first host (or backup) to the same filename
   on your new host
2. Run `pizwg-restore` to install the certificates in their correct locations
3. Run `ro` to make the system read only (this survives reboots)
4. Run `reboot` to verify everything works

Once you've booted up you should be able to `ping` the virtual IP address (VIP)
mentioned earlier. If you have more than one PiZWG host you will notice that
only the current master will have its Z-Wave gateway remain energised.

## Client Configuration

`socat` allows a client to access the `ser2net` service active on the current
*PiZWG* master. The client references the virtual IP address (VIP) rather than a
specific *PiZWG* host. A complete example command is shown below:

```
socat -d -d -s -T30 pty,link=/dev/ttyUSB254,raw,user=root,group=root,mode=777 \
openssl-connect:192.168.1.254:3333,cafile=etc/ser2net/ser2net.crt,commonname=pizwg-server,cert=root/pizwg-client.pem
```

The above creates a `/dev/ttyUSB254` device connected to a *PiZWG* master VIP at
`192.168.1.254`. The `crt` and `pem` certificate files should be extracted from
`/root/backup.tar`. These provide encryption and mutual certificate
authentication.

The example command also used `-T30`. This ensures the connection is dropped if
no traffic is sent or received in 30 seconds. Most Z-Wave networks have enough
background traffic to allow such a timeout (or a power plug, light or similar
can probably be configured to regularly report energy consumption). You can use
a longer timeout if this is not the case. Once the timeout is reached the client
will disconnect its TCP connection, in turn causing the master *PiZWG* to
restart. In a high availability deployment a backup *PiZWG* host will
immediately acquire the VIP and be ready to receive a client connection.

In addition to client-initiated timeouts, the active master *PiZWG* host also
implements a 300 second inactivity timeout on the client TCP connection. This
ensures that the *PiZWG* host will reboot even if the remote client failed to
detect inactivity and drop the TCP connection.

## Monitoring

In general you don't need to track which *PiZWG* host is master. However you
may monitor individual hosts by HTTP requests to `http://host:9100/metrics`.
This is a standard Prometheus Node Exporter endpoint.

You may also SSH into the *PiZWG* host as root to view the status of
services. The important ones are:

* `keepalived.service`: Configures VRRP settings (using MAC and DHCP-assigned
   subnet) and allocates VIP to active master
* `monitor.service`: Controls USB power, waits until active master, waits for
   `ser2net` TCP loss (timeout, disconnect), then reboots host

You should not need to monitor `ser2net.service` as this is only started by the
`monitor.service` when appropriate (ie once active master, USB powered up etc).

## Security

*PiZWG* is secure by design:

* Image builds always include the latest available software from a popular
  rolling Linux distribution (Arch Linux)
* Downloads are built by GitHub Actions (with a public commit and build log)
* Arch Linux's normal user account (`alarm`) is deleted
* Unnecessary packages are not installed
* Included packages are all mature and commonly used in production environments
* SSH keys are generated on first boot (ie they're not in the image)
* The setup instructions guide users to enhance security of the SSH daemon
* `ser2net` keys are generated via `pizwg-setup` (they're not in the image)
* `ser2net` monitoring is not network accessible (ie `localhost:4444` only)
* `ser2net` performs mutual certificate authentication with clients

There are three open ports bound to network-accessible IPv4 addresses:

* `ser2net` opens port 3333 so a client can connect to the USB serial port
  (the client must authenticate using the expected client certificate)
* Prometheus Node Exporter opens port 9100 to allow remote HTTP monitoring
* SSH opens port 22 for administrative control (root password is disabled if
  above setup instructions followed)

You should consider your threat model and apply appropriate mitigations.
Some of the areas which may require consideration include:

* Ensuring setup instructions were fully completed (eg SSH, root password)
* Ensuring the `/root/backup.tar` is securely backed up (NB file is unencrypted)
* Network level attacks such as ARP spoofing, denial of service etc
* Physical access to the Raspberry Pi and/or the Z-Wave gateway
* Exploiting unknown or unpatched vulnerabilities or misconfigurations

## Software Updates

The PiZWG image uses Arch Linux, which is a popular rolling distribution. While
the author has operated Arch Linux for over 15 years and updates very rarely
fail, the reality is that any upgrade brings with it some risk of failure and
any potential benefits must be considered against that risk.

If later software is required, the recommended upgrade path is to download and
deploy the latest version of PiZWG, using the `backup.tar` backup and restore
approach so that certificates can be transferred to the latest version. Deploy
the new version on a separate SD card from your existing deployment, therefore
ensuring there is a simple rollback plan for your existing service.

If you wish to attempt a rolling software update without installing a new
version of PiZWG:

1. Consider copying the production SD card to a file on another machine (eg
   `sudo dd if=/dev/sdd of=~/pizwg-prod.img bs=4M`)
2. SSH into the PiZWG server as root
3. Ensure that you have an up-to-date, remote backup of `backup.tar`
4. Run `rw` to obtain a read-write file system
5. Run `pacman -Syu` to perform the actual Arch Linux upgrade
6. Run `ro` to return to a read-only file system
7. Run `reboot` to test the upgrade was successful

If the above fails, you can either restore your PiZWG environment using the
SD card backup image, or you can download a new PiZWG version and restore the
`backup.tar` as per the usual backup and restore procedure.

## Building

[packer-builder-arm](https://github.com/mkaczanowski/packer-builder-arm) is used
to build a standard image file that can be written to SD cards.

To build your own image, run:

```
PACKER_LOG=1 sudo packer build pizwg-rp4.json
```
## Contributing

Pull requests that reflect the project's priorities (reliability, security) are
welcome. If you would like to make more substantial changes or add new features,
please firstly open a GitHub ticket so that we can discuss it.

## Support

Please open a GitHub ticket if you have any questions.
