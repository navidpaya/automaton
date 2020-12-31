This is how I manage my Lenovo T430s with ArchLinux on it. The idea is to get it to a stage where Ansible can take over and manage the rest. This setup gives me a fully-encrypted disk with LVM on top of that, with Gnome and a bunch of other packages for my daily needs.

### Partitioning the disk
Use cfdisk or fdisk. We’ll create a /boot which won’t be encrypted and an LVM volume that will be fully encrypted and hold everything else.

    /dev/sda1 > 83 (Linux) for /boot
    /dev/sda2 > 8e (LVM) for lvm

### Create the encrypted volume
    cryptsetup luksFormat /dev/sda2

### Set up the LVM volumes
    cryptsetup open --type luks /dev/sda2 lvm
    pvcreate /dev/mapper/lvm
    vgcreate storage /dev/mapper/lvm
    lvcreate -L 4G storage -n swap-vol
    lvcreate -l +100%FREE storage -n root-vol

### Format and mount the partitions
    mkfs.ext4 /dev/mapper/storage-root-vol
    mount /dev/storage/root-vol /mnt
    mkfs.ext4 /dev/sda1
    mkdir /mnt/boot
    mount /dev/sda1 /mnt/boot
    mkswap /dev/mapper/storage-swap-vol
    swapon /dev/storage/swap-vol

### Connect to the internet
    iwctl
    device list
    station device scan
    station device get-networks
    station device connect SSID
    
### Update the time using NTP
    timedatectl set-ntp true

### Choose your pacman mirror
    vi /etc/pacman/mirrorlist

### Install the base
    pacstrap /mnt base linux linux-firmware

### Generate fstab
    genfstab -U /mnt >> /mnt/etc/fstab

### Chroot to the new environment
    arch-chroot /mnt

### Set the hostname
    echo "harmony" > /etc/hostname

### Adjust the timezone and sync the hardware clock
    ln -sf /usr/share/zoneinfo/Australia/Sydney /etc/localtime
    hwclock --systohc

### Set the locales
    vi /etc/locale.gen
    locale-gen

### Set local preference
    echo LANG=en_US.UTF-8 > /etc/locale.conf

### Adjust the mkinicpio hooks
    vi /etc/mkinitcpio.conf

### Add these two before "filesystem" in the HOOKS section
    encrypt lvm2

### Compile the kernel
    mkinitcpio -P

### Change root password
    passwd

### Install Microcode
    pacman -S amd-ucode

### Install and configure grub
    vi /etc/default/grub
    GRUB_CMDLINE_LINUX="cryptdevice=/dev/sda2:storage root=/dev/mapper/storage-root_vol"
    grub-install --target=i386-pc --recheck --debug /dev/sda
    grub-mkconfig -o /boot/grub/grub.cfg

### Exit and reboot
    exit
    reboot
