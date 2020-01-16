#! /bin/bash

# Standard root partition label; change as needed
RootLabel="ArchLinux"


# Functions for colored (Light Cyan) output. Using default \e[39m to return after echo. qecho does not change line and adds semicolon - good for waiting for input.
cecho() {
	echo -e "\e[96m$1\e[39m"
} 

qecho() {
	echo -ne "\e[96m$1\e[39m: "
} 

kitarida() {
	cecho "Press CTRL-C to exit; ENTER to continue."
	read
}

arun() {
	arch-chroot /mnt $1
}


cecho
cecho "       +-------------------------+"
cecho "       | ArchLinux EFI Installer |"
cecho "       +-------------------------+"
cecho
cecho "Ready to install Arch Linux? Right on!"
cecho "Assumptions are that you:"
cecho "- have a working internet connection;"
cecho "- want a plain vanilla Arch installation with GNOME DE;"
cecho "- EFI boot is enabled (tested below)."
cecho
cecho "Checking UEFI..."
cecho
ls /sys/firmware/efi/efivars
cecho
cecho "If you do not see anything listed above, EFI boot is not enabled."
kitarida

timedatectl set-ntp true

cecho
cecho "Identifying installation disk. Check the output of fdisk below."
cecho
fdisk -l
#Asignar a Disk
Disk= 'sda'
cecho
qecho "Disk to install Arch on? (Fill the xxx in /dev/xxx)"
#read Disk

cecho
cecho "Disk /dev/${Disk} will be used. Two partitions will be created:"
cecho
cecho "1) EFI, size 500MiB, for bootloader."
cecho "2) Linux, ext4, for the root filesystem. Root label will be $RootLabel."
cecho "A 4GiB swap file may also be created later on."
kitarida

cecho "Backing up partition in backup-${Disk}.bin; you can restore the partiotion table if something goes wrong."

#sgdisk -b backup-$Disk.bin /dev/$Disk
#sgdisk -o /dev/$Disk
#sgdisk -n 1:0:+500MiB -t 1:ef00 -c 1:boot /dev/$Disk
#sgdisk -n 2:0:0 -t 2:8300 -c 2:root /dev/$Disk
#sgdisk -w /dev/$Disk

cecho
cecho "Partition completed. Look below to check that you are happy:"
gdisk -l /dev/$Disk
cecho
cecho "If not, you can restore the precious partition by running sgdisk -l=backup-$Disk.bin /dev/$Disk."
kitarida

cecho "Making and mounting filesystems..."
#mkfs.vfat -F32 /dev/${Disk}1
#Particion Root es sda6
mkfs.ext4 -L $RootLabel /dev/${Disk}6
mount /dev/${Disk}6 /mnt
mkdir -p /mnt/boot/efi
#uefi - EFI particion es sda2
mount /dev/${Disk}2 /mnt/boot/efi

cecho
curl -s "https://www.archlinux.org/mirrorlist/?country=BR&protocol=http&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' > /etc/pacman.d/mirrorlist
cecho "Updated list for BR mirrors; here it is:"
cat /etc/pacman.d/mirrorlist
cecho "Pacstraping..."
pacstrap /mnt 
cecho
cecho "Generating fstab..."
genfstab -U /mnt > /mnt/etc/fstab

cecho
cecho "       +------------------------+"
cecho "       |     System Details     |"
cecho "       +------------------------+"
cecho


# Processor identification
Proc=''
while [ "$Proc" != "I" ] && [ "$Proc" != "V" ] && [ "$Proc" != "A" ]
do
	qecho "Processor? (I)ntel, (A)MD, (V)irtual machine"
	read Proc
done


# Graphics identification
Graphics=''
if [ "$Proc" != V ]; then
	while [ "$Graphics" != "I" ] && [ "$Graphics" != "N" ] && [ "$Graphics" != "A" ]
	do
		qecho "Graphics card? (N)vidia, (I)ntel, (A)MD"
		read Graphics
	done
fi


# Hostname
qecho "Hostname"
read HostName


# Swap file?
Swap=''
while [ "$Swap" != "y" ] && [ "$Swap" != "n" ]
do
	qecho "Swap file size (12 GiB)? (y/n)"
	read Swap
done

cecho
cecho "+-------------------------+"
cecho "|         SUMMARY         |"
cecho "+-------------------------+"
cecho
cecho "Processor:        $Proc"
cecho "Graphics:         $Graphics"
cecho "Root label:       $RootLabel"
cecho "Host name:        $HostName"
cecho "Swap file (4GiB): $Swap"
cecho "---------------------------"
cecho
kitarida



# ---------------------------------------
# Create locale and host files

cecho "Creating US, GB and GR locale; time zone and default language GB"
arun "ln -sf /usr/share/zoneinfo/GB /etc/localtime"
arun "hwclock --systohc"
echo -e "#\n# My locales\nes_AR.UTF-8 UTF-8\nen_US.UTF-8  >> /mnt/etc/locale.gen
arun "locale-gen"
echo "LANG=es_AR.UTF-8" > /mnt/etc/locale.conf

cecho "Creating hosts"
echo $HostName > /mnt/etc/hostname
echo -e "127.0.0.1    ${HostName}\n::1          ${HostName}\n127.0.1.1    ${HostName}.localdomain    ${HostName}" > /mnt/etc/hosts





# ---------------------------------------
# Microcodes
case $Proc in
	I)	ProcMicro='intel-ucode'   ;;
	A)	ProcMicro='amd-ucode'     ;;
	*)	ProcMicro=''              ;;
esac

# ---------------------------------------
# Graphics drivers
case $Graphics in
	N)	GraphicsDrivers='nvidia nvidia-utils libva-vdpau-driver'   ;;
	I)	GraphicsDrivers='mesa libva-intel-driver'                  ;;
	A)	GraphicsDrivers='mesa libva-mesa-driver mesa-vdpau'        ;;
	*)	GraphicsDrivers=''                                         ;;
esac



# Essential packages
Linux='linux linux-firmware'
Goodies='dhcpcd nano sudo bash-completion chromium chrome-gnome-shell man-db'
Gnome='eog evince evolution evolution-ews file-roller gdm gedit gnome-calculator gnome-calendar gnome-clocks gnome-control-center gnome-disk-utility gnome-font-viewer gnome-keyring gnome-logs gnome-session gnome-settings-daemon gnome-shell gnome-system-monitor gnome-terminal gnome-tweaks gnome-weather gvfs gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs mutter nautilus networkmanager sushi tracker tracker-miners xdg-user-dirs-gtk'

cecho
cecho "Install linux and other goodies."
cecho
arun "pacman -S --needed base $Linux $Goodies $Gnome $ProcMicro $GraphicsDrivers"


# Swap file
if [ "$Swap" = "y" ]; then
	cecho
	cecho "Making swap file..."
	cecho
	arun "fallocate -l 12G /swapfile"
	arun "chmod 600 /swapfile"
	arun "mkswap /swapfile" 
	arun "swapon /swapfile"
	echo -e "# swapfile\n/swapfile\tnone\tswap\tdefaults\t0 0" >> /mnt/etc/fstab
fi



# Install and configure systemd-boot

cecho
cecho "Installing bootloader"

arun "bootctl --path=/boot/ install"


# DRM if NVIDIA
DRMIFNVIDIA=''
if [ "$Graphics" = "N" ]; then
	DRMIFNVIDIA='nvidia-drm.modeset=1'
fi


BootConf='/boot/loader/entries/arch.conf'
echo -e "title   Arch Linux\nlinux   /vmlinuz-linux" > /mnt/$BootConf
if [ "$Proc" != "V" ]; then
	echo "initrd  /${ProcMicro}.img" >>  /mnt/$BootConf
fi
echo -e "initrd  /initramfs-linux.img\noptions root=LABEL=$RootLabel rw $DRMIFNVIDIA" >>  /mnt/$BootConf 


# Root password and add user

cecho
cecho "Set root password."
arun "passwd"

qecho "User (with admin rights) name"
read UserName
arun "useradd -m -G wheel ${UserName}"
cecho "Set password for user ${UserName}."
arun "passwd ${UserName}"
echo -e "\n# Make all wheel users admin.\n%wheel ALL=(ALL) ALL" >> /mnt/etc/sudoers


cecho "Touching configuration files..."
sed -i s/'tar.*z'/'tar'/ /mnt/etc/makepkg.conf
sed -i s/'#Color'/'Color\nILoveCandy'/ /mnt/etc/pacman.conf
sed -i s/'#TotalDownload'/'TotalDownload'/ /mnt/etc/pacman.conf
sed -i s/'#VerbosePkgLists'/'VerbosePkgLists'/ /mnt/etc/pacman.conf


#Enable services
cecho "Enabling DHCP, Network Manager and GDM."
arun "systemctl enable dhcpcd NetworkManager gdm"


#End
cecho "Basic installation finished."
cecho "Press CTRL-C to exit the install script; ENTER to reboot."
read
umount -R /mnt
reboot
