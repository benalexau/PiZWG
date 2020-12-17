#!/bin/bash
pacman-key --init
pacman-key --populate archlinuxarm

pacman -Syu --noconfirm

# Small utilities to help with administration over SSH
pacman -S --noconfirm mg rxvt-unicode-terminfo bash-completion

# Recover space
rm /var/cache/pacman/pkg/*.xz
