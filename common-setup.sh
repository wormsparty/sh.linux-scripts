#!/bin/sh

#############################################################################
# This is the part that is not specific to a particular Linux distribution. #
#############################################################################

# 1. rclone service for Google Drive
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
	rclone sync gdrive:\${folder} ~/GdriveSync/\${folder} -i --exclude //Notes/.obsidian/**
elif [ "\$mode" = "push" ]; then
	rclone sync ~/GdriveSync/\${folder} gdrive:/\${folder} -i --exclude //Notes/.obsidian/**
else
	echo "Unknown mode \$mode"
	exit 1
fi
EOT

	sudo chmod +x /usr/local/bin/gsync
else
	echo "gsync seems to be already present, skipping."
fi

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

if [ ! -f /usr/local/bin/rpi ]; then
	cat << EOT > sudo tee /usr/local/bin/rpi
#!/bin/sh

ssh raspberrypi
EOT
	sudo chmod +x /usr/local/bin/rpi
fi

if [ ! -f /usr/local/bin/rpi-upload ]; then
	cat << EOT > sudo tee /usr/local/bin/rpi-upload
#!/bin/sh

echo "Is it a film (f), a TV show (t), or other (o)?"
printf "> "
read CHOICE
	
if [ "\$CHOICE" = "f" ]; then
	echo "Copying to film directory..."
	scp -r "\$@" raspberrypi:Video/Films
elif [ "\$CHOICE" = "t" ]; then
	echo "Copying to TV shows directory..."
	scp -r "\$@" raspberrypi:Video/TVShows
elif [ "\$CHOICE" = "o" ]; then
	echo "Copying to Downloads directory..."
	scp -r "\$@" raspberrypi:Downloads
else
	echo "Unknown type: \$CHOICE, aborting"
	exit 1
fi

if [ \$? -ne 0 ]; then
	echo "Failed to upload."
else
	echo "Done!"
fi
EOT
	sudo chmod +x /usr/local/bin/rpi-upload
fi

if [ ! -f /usr/local/bin/rename ]; then
	cat << EOT > sudo tee /usr/local/bin/rename
#!/bin/sh

regex=\$1
shift

for x in "\$@"; do
	mv "\$x" "\`echo "\$x" | sed "\$regex"\`"
done
EOT
	sudo chmod +x /usr/local/bin/rename
fi

# 2. Disable wifi & bluetooth
if [ ! -f /etc/modprobe.d/rtw88_8821ce.conf ]; then
	# To find your wifi kernel module: lspci -v, and the driver name is the last line
	sudo bash -c "echo 'blacklist rtw88_8821ce' >> /etc/modprobe.d/rtw88_8821ce.conf"
	sudo bash -c "echo 'blacklist mwifiex_pcie' >> /etc/modprobe.d/mwifiex_pcie.conf"
	sudo bash -c "echo 'blacklist bluetooth' >> /etc/modprobe.d/bluetooth.conf"

	if which dracut; then
		# OpenSUSE, Fedora, etc.
		sudo dracut -f --regenerate-all
 	else
		# Debian version
		sudo depmod -ae
  	fi

   	if which mkinitrd; then
    		# OpenSUSE version
    		sudo mkinitrd
      	else
       		# Debian version
		sudo update-initramfs -u
  	fi
	

	sudo modprobe -r rtw88_8821ce
	sudo modprobe -r mwifiex_pcie
	sudo modprobe -r bluetooth
	sudo bash -c "echo 'iface wlp2s0 inet manual' > /etc/network/interfaces.d/no-wifi" 
	sudo systemctl disable bluetooth.service
	sudo sed -i 's/AutoEnable=true/AutoEnable=false/' /etc/bluetooth/main.conf
	sudo sed -i 's/#AutoEnable=true/AutoEnable=false/' /etc/bluetooth/main.conf
else
	echo "Ignoring blacklist and bluetooth, looks already done."
fi

# 3. Various config
if ! grep -q QT_QPA_PLATFORMTHEME /etc/environment; then
	echo "export QT_QPA_PLATFORMTHEME=qt5ct" | sudo tee -a /etc/environment
else
	echo "Ignoring modifying environment, looks already done."
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

# 4. Raspberry
if ! grep -q raspberry /etc/hosts; then
	echo "172.22.22.77    raspberrypi" >> /etc/hosts
else
	echo "Ignoring modifying hosts, looks already done."
fi

if [ ! -f ~/.unison/mini2raspberry.prf ]; then	
	cat << EOT > ~/.unison/mini2raspberry.prf
# Unison preferences
label = Backup Google drive folder
root = /home/$USER/GdriveSync
root = ssh://$USER@raspberrypi/GdriveSync
sshargs = -C
EOT

	SSH_KEY=$(find ~/.ssh -name \*.pub)

	if [ -z "${SSH_KEY}" ]; then
		ssh-keygen -t ed25519 -C "wormsparty@gmail.com"
		SSH_KEY=$(find ~/.ssh -name \*.pub)

		if [ -z "${SSH_KEY}" ]; then
			echo "Failed to find SSH key."
			exit 1
		fi

		ssh raspberrypi "echo '$(cat $SSH_KEY)' >> ~/.ssh/authorized_keys"
	fi

	cat << EOT > ./unison.cron
SHELL=/bin/sh
PATH=/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=$USER
HOME=/home/$USER/

# For details see man 4 crontabs

# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  * command to be executed
  0  *  *  *  * unison mini2raspberry -batch -sshargs='-i /home/$USER/.ssh/${SSH_KEY%.*}'
EOT

	crontab ./unison.cron
else
	echo "Ignoring unison config, looks already done."
fi

echo "Manual steps:"
echo " 1. Install Gnome Shell extensions (Dash to Dock + Tray Icon Reloaded)"
echo " 2. Install Retroarch from https://docs.libretro.com/development/retroarch/compilation/ubuntu/"
echo " 3. Setup profile 'mini2raspberry' in unison for Raspberry PI backup"
echo "That's it !"

