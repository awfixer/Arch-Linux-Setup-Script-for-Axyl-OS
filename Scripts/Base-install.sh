#!/bin/bash

pacman -S git

git clone https://github.com/rubixcube199/configs-2.0

configs-2.0/etc/pacman.d/setup.sh

sgdisk -Z /dev/vda

sgdisk -n1:0:+512M -t1:ef00 -c1:EFI -N2 -t2:8304 -c2:LINUXROOT /dev/vda

partprobe -s /dev/vda

cryptsetup luksFormat --type luks2 /dev/vda2

cryptsetup luksOpen /dev/vda2 linuxroot

mkfs.vfat -F32 -n EFI /dev/vda1

mkfs.btrfs -f -L linuxroot /dev/mapper/linuxroot

mount /dev/mapper/linuxroot /mnt

mkdir /mnt/efi

mount /dev/vda1 /mnt/efi

btrfs subvolume create /mnt/home

btrfs subvolume create /mnt/srv

btrfs subvolume create /mnt/var

btrfs subvolume create /mnt/var/log

btrfs subvolume create /mnt/var/cache

btrfs subvolume create /mnt/var/tmp

pacstrap -K /mnt base base-devel linux-zen linux-zen-headers linux-firmware amd-ucode vim neovim vim-plugins cryptsetup btrfs-progs dosfstools util-linux git unzip sbctl kitty networkmanager sudo foot yay

sed -i -e "/^#"en_US.UTF-8"/s/^#//" /mnt/etc/locale.gen

systemd-firstboot --root /mnt --prompt

arch-chroot /mnt locale-gen

arch-chroot /mnt useradd -G wheel -m judge

arch-chroot /mnt passwd judge

sed -i -e '/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/s/^# //' /mnt/etc/sudoers

echo "quiet rw" >/mnt/etc/kernel/cmdline

mkdir -p /mnt/efi/EFI/Linux

cp ./mkinitcpio.conf /mnt/etc/mkinitcpio.conf

cp ./mkinitcpio.d/linux-zen.preset /etc/mkinitcpio.conf

arch-chroot /mnt mkinitcpio -P

systemctl --root /mnt enable systemd-resolved systemd-timesyncd NetworkManager

systemctl --root /mnt mask systemd-networkd

arch-chroot /mnt bootctl install --esp-path=/efi

sync

systemctl reboot --firmware-setup