#! /bin/bash

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

# Processor identification
Proc=''
while [ "$Proc" != "I" ] && [ "$Proc" != "V" ] && [ "$Proc" != "A" ]
do
	qecho "Processor? (I)ntel, (A)MD, (V)irtual machine"
	read Proc
done

qecho $Proc

qecho '======================'

cecho
cecho "Identifying installation disk. Check the output of fdisk below."
cecho
fdisk -l
#Asignar a Disk
Disk='sda'
cecho
qecho "Disk to install Arch on? (Fill the xxx in /dev/xxx)"
#read Disk

cecho $Disk
cecho
