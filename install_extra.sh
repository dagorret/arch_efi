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

cecho
cecho "       +-------------------------+"
cecho "       | ArchLinux EFI Installer |"
cecho "       +-------------------------+"
cecho
cecho "Ready to install further? Right on!"


# Questions
MEDIA=''
while [ "$MEDIA" != "y" ] && [ "$MEDIA" != "n" ]
do
	qecho "Install media and codecs? (y/n)"
	read MEDIA
done

Fonts=''
while [ "$Fonts" != "y" ] && [ "$Fonts" != "n" ]
do
	qecho "Install DejaVu, Liberation and Roboto fonts? (y/n)"
	read Fonts
done


TEX=''
while [ "$TEX" != "y" ] && [ "$TEX" != "n" ]
do
	qecho "Install TexLive? (y/n)"
	read TEX
done

YAY=''
while [ "$YAY" != "y" ] && [ "$YAY" != "n" ]
do
	qecho "Install yay and AUR packages? (y/n)"
	read YAY
done




cecho
cecho "+-------------------------+"
cecho "|         SUMMARY         |"
cecho "+-------------------------+"
cecho
cecho "TexLive:   $TEX"
cecho "Media:     $MEDIA"
cecho "Fonts:     $Fonts"
cecho "Yay/AUR:   $YAY"
cecho "-------------------------------"
kitarida





BASIC='chrome-gnome-shell chromium code libxss hunspell hunspell-en_GB hunspell-el pacman-contrib openssh openvpn networkmanager-openvpn r xdg-utils'

TTF=''
if [ "$Fonts" = "y" ]; then
	TTF='ttf-dejavu ttf-liberation ttf-roboto'
fi

TEXLIVE=''
if [ "$TEX" = "y" ]; then
	TEXLIVE='texlive-bin texlive-core texlive-bibtexextra texlive-latexextra'
fi


CODECS=''
if [ "$MEDIA" = "y" ]; then
	CODECS='gst-plugins-base gst-libav gst-plugins-good gst-plugins-bad gst-plugins-ugly mpv rhythmbox'
fi

cecho "Will now install basic packages and other goodies"
sudo pacman -S --needed $BASIC $TTF $TEXLIVE $CODECS



AUR=''
if [ "$YAY" = "y" ]; then
	AUR='pcloud-drive pcloudcc dropbox spotify-adblock-git skypeforlinux-preview-bin chromium-widevine adwaita-qt qgnomeplatform'
	sudo pacman -S --needed base-devel git
	git config --global user.name  "coxackie"
	git config --global user.email "kostas.kardaras@gmail.com"
	git config --global credential.helper /usr/lib/git-core/git-credential-libsecret
	cd ~ && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -sirc && cd ~ && rm -rf yay-bin
fi

yay -S --needed $AUR



#End
cecho
cecho "Installation finished."
cecho "Press ENTER to exit the install script."
read
