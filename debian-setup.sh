#!/bin/sh

if [ "`id -u`" -eq 0 ]; then
	echo "Do NOT run this script as root. It will call 'sudo' as needed."
	exit 1
fi

# VSCodium repository
if [ ! -f /usr/share/keyrings/vscodium-archive-keyring.gpg ]; then
	wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
	    | gpg --dearmor \
	    | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg

	echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' \
	    | sudo tee /etc/apt/sources.list.d/vscodium.list

	sudo apt-get update
else
	echo "Ignoring vscodium keyring, looks already done."
fi

# 2. Install packages
sudo apt-get install curl rclone gimp inkscape vlc transmission-gtk blender goldendict-webengine audacious libreoffice-writer firefox-esr qt5ct qt5-style-kvantum neovim codium flatpak gnome-software-plugin-flatpak
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

if [ ! -f /usr/local/bin/up ]; then
	cat << EOT | sudo tee -a /usr/local/bin/up
 #!/bin/sh

sudo apt-get update
sudo apt-get dist-upgrade
sudo apt-get autoremove
sudo flatpak update
sudo flatpak uninstall --unused
EOT
	sudo chmod +x /usr/local/bin/up
fi

sh "`dirname $0`/common-setup.sh"
