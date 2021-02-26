#!/bin/bash

# Add Arch Linux ARM AUR repo:
echo '[benalexau-archarm-aur-repo]' >> /etc/pacman.conf
echo 'SigLevel = Optional TrustAll' >> /etc/pacman.conf
echo "Server = https://github.com/benalexau/archarm-aur-repo/releases/download/$(uname -m)" >> /etc/pacman.conf

pacman-key --init
pacman-key --populate archlinuxarm

pacman -Syu --noconfirm

# Small utilities to help with administration over SSH
pacman -S --noconfirm mg rxvt-unicode-terminfo bash-completion

# Recover space
rm /var/cache/pacman/pkg/*.xz
