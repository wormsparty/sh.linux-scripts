#!/bin/sh

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
sudo apt-get install rclone rclone-browser gimp inkscape vlc transmission-gtk blender goldendict-webengine foliate audacious signal-desktop libreoffice-writer firefox-esr qt5ct qt5-style-kvantum neovim codium

# 3. Disable wifi & bluetooth
if [ ! -f /etc/modprobe.d/rtw88_8821ce.conf ]; then
	# To find your wifi kernel module: lspci -v, and the driver name is the last line
	sudo bash -c "echo 'blacklist rtw88_8821ce' >> /etc/modprobe.d/rtw88_8821ce.conf"
	sudo bash -c "echo 'blacklist mwifiex_pcie' >> /etc/modprobe.d/mwifiex_pcie.conf"
	sudo depmod -a
	sudo update-initramfs -u
	sudo modprobe -r rtw88_8821ce
	sudo modprobe -r mwifiex_pcie
	sudo bash -c "echo 'iface wlp2s0 inet manual' > /etc/network/interfaces.d/no-wifi" 
	sudo systemctl disable bluetooth.service
	sudo sed -i 's/AutoEnable=true/AutoEnable=false/' /etc/bluetooth/main.conf
else
	echo "Ignoring blacklist and bluetooth, looks already done."
fi

# 4. rclone service
if ! grep -q '\[gdrive\]' "${HOME}/.config/rclone/rclone.conf"; then
	echo "Please add your Google Drive account and name it 'gdrive'"
	rclone-browser

	if ! grep -q '\[gdrive\]' "${HOME}/.config/rclone/rclone.conf"; then
		echo "'gdrive' doesn't seem to be configured. Please configure it with rclone-browser and re-run this script"
		exit 1
	fi
fi

mkdir -p ~/.config/systemd/user

if [ ! -f ~/.config/systemd/user/rclone-drive.service ]; then
	cat <<EOT > ~/.config/systemd/user/rclone-drive.service
[Unit]
Description=RClone Service
Wants=network-online.target
After=network-online.target

[Service]
Type=notify
KillMode=none
RestartSec=5
ExecStartPre=/usr/bin/mkdir -p $HOME/Gdrive
ExecStart=/usr/bin/rclone mount --dir-cache-time 1000h gdrive: $HOME/Gdrive
ExecStop=/bin/fusermount -uz $HOME/Gdrive
Restart=on-failure

[Install]
WantedBy=default.target
EOT

	systemctl --user enable rclone-drive.service
	systemctl --user start rclone-drive.service
else
	echo "rclone-drive service looks already configured, skipping."
fi

# 6. Config
if ! grep -q QT_QPA_PLATFORMTHEME ~/.profile; then
	echo "export QT_QPA_PLATFORMTHEME=qt5ct" >> ~/.profile
else
	echo "Ignoring modifying .profile, looks already done."
fi

if ! grep -q "gdrive-download" ~/.bashrc; then
	echo "alias gdrive-download='rclone sync gdrive: ~/GdriveSync -i'" >> ~/.bashrc
	echo "alias gdrive-upload='rclone sync ~/GdriveSync gdrive: -i'" >> ~/.bashrc
	echo "alias vim='nvim'" >> ~/.bashrc

	mkdir -p ~/GdriveSync
fi

if [ ! -d ~/.config/qt5ct ]; then
	mkdir -p ~/.config/qt5ct

	cat <<EOT >> ~/.config/qt5ct/qt5ct.conf
[Appearance]
style=kvantum-dark
EOT
fi

gsettings set org.gnome.desktop.privacy remember-recent-files false

if [ ! -d ~/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com ]; then
	if [ ! -f gnome-shell.extension-installer ]; then
		wget -O gnome-shell-extension-installer "https://github.com/brunelli/gnome-shell-extension-installer/raw/master/gnome-shell-extension-installer"
		chmod +x gnome-shell-extension-installer
	fi

	./gnome-shell-extension-installer 307
else
	echo "Dock to dash looks already installed, skipping."
fi

if [ ! -d ~/.local/share/gnome-shell/extensions/trayIconsReloaded@selfmade.pl ]; then
	if [ ! -f gnome-shell.extension-installer ]; then
		wget -O gnome-shell-extension-installer "https://github.com/brunelli/gnome-shell-extension-installer/raw/master/gnome-shell-extension-installer"
		chmod +x gnome-shell-extension-installer
	fi
	
	./gnome-shell-extension-installer 2890
else
	echo "Tray icon reloaded looks already installed, skipping."
fi

rm -f ./gnome-shell-extension-installer

open "https://github.com/obsidianmd/obsidian-releases/releases"

echo "All done! Congrats! Now you can install the .slob files for GoldenDict & others."
