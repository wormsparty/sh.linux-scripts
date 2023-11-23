#!/bin/sh

###############################################
# This is the part that is specific to Debian #
###############################################

# 0. Check we are not admin
if [ "`id -u`" -eq 0 ]; then
	echo "Do NOT run this script as root. It will call 'sudo' as needed."
	exit 1
fi

# 1. Install signal repository
if [ ! -f /usr/share/keyrings/signal-desktop-keyring.gpg ]; then
	sudo bash -c "wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > /usr/share/keyrings/signal-desktop-keyring.gpg"
	echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' | sudo tee /etc/apt/sources.list.d/signal-xenial.list
	sudo apt-get update
else
	echo "Ignoring signal keyring, looks already done."
fi

# 2. Install packages
sudo apt-get install curl rclone gimp inkscape vlc transmission-gtk blender audacious signal-desktop libreoffice-writer firefox-esr qt5ct qt5-style-kvantum neovim manuskript kodi retroarch gnome-builder

# sudo apt-get install gnome-shell-pomodoro

if [ ! -f /usr/local/bin/up ]; then
	cat << EOT | sudo tee -a /usr/local/bin/up
 #!/bin/sh

sudo apt-get update
sudo apt-get dist-upgrade
sudo apt-get autoremove
EOT
	sudo chmod +x /usr/local/bin/up
fi

# 3. Call the common script for non-specific configuration
sh "`dirname $0`/common-setup.sh"
