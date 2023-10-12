#!/bin/sh

flatpak install obsidian

mkdir -p ~/GdriveSync

if [ ! -f /usr/local/bin/gsync ]; then
	cat << EOT | sudo tee -a /usr/local/bin/gsync
#!/bin/sh

mode=\$1
folder=\$2

if test \$# -ne 1 && test \$# -ne 2; then
	echo "Usage: \$(basename \$0) pull|push (folder)"
	exit 1
fi

if [ -n "\${folder}" ]; then
	if [ ! -d "\$HOME/GdriveSync/\${folder}" ]; then
		echo "Folder not found: \$HOME/GdriveSync/\$folder"
		exit 1
	fi
fi

if [ "\$mode" = "pull" ]; then
	rclone sync gdrive:\${folder} ~/GdriveSync/\${folder} -i
elif [ "\$mode" = "push" ]; then
	rclone sync ~/GdriveSync/\${folder} gdrive:/\${folder} -i
else
	echo "Unknown mode \$mode"
	exit 1
fi
EOT

	sudo chmod +x /usr/local/bin/gsync
else
	echo "gsync seems to be already present, skipping."
fi


# 3. Disable wifi & bluetooth
if [ ! -f /etc/modprobe.d/rtw88_8821ce.conf ]; then
	# To find your wifi kernel module: lspci -v, and the driver name is the last line
	sudo bash -c "echo 'blacklist rtw88_8821ce' >> /etc/modprobe.d/rtw88_8821ce.conf"
	sudo bash -c "echo 'blacklist mwifiex_pcie' >> /etc/modprobe.d/mwifiex_pcie.conf"

	# debian version
	sudo depmod -ae
	sudo update-initramfs -u
	
	# OpenSUSE version
	sudo dracut -f --regenerate-all

	sudo modprobe -r rtw88_8821ce
	sudo modprobe -r mwifiex_pcie
	sudo bash -c "echo 'iface wlp2s0 inet manual' > /etc/network/interfaces.d/no-wifi" 
	sudo systemctl disable bluetooth.service
	sudo sed -i 's/AutoEnable=true/AutoEnable=false/' /etc/bluetooth/main.conf
else
	echo "Ignoring blacklist and bluetooth, looks already done."
fi

# 4. rclone service
mkdir -p "${HOME}/.config/rclone"
touch "${HOME}/.config/rclone/rclone.conf"

if ! grep -q '\[gdrive\]' "${HOME}/.config/rclone/rclone.conf"; then
	echo "Please add your Google Drive account and name it 'gdrive'"
	rclone config

	if ! grep -q '\[gdrive\]' "${HOME}/.config/rclone/rclone.conf"; then
		echo "'gdrive' doesn't seem to be configured. Please configure it and re-run this script"
		exit 1
	fi
fi

# 6. Config
if ! grep -q QT_QPA_PLATFORMTHEME ~/.profile; then
	echo "export QT_QPA_PLATFORMTHEME=qt5ct" >> ~/.profile
else
	echo "Ignoring modifying .profile, looks already done."
fi

if ! grep -q "nvim" ~/.bashrc; then
	echo "alias vim='nvim'" >> ~/.bashrc
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

echo "All done! Congrats! Now you can install the .slob files for GoldenDict & others."
