#!/bin/sh

sudo apt-get install vim kodi kodi-peripheral-joystick openssh-server unison lightdm 

if ! grep UTF-8 /etc/locale.gen; then
	cat << EOT | sudo tee /etc/locale.gen
en_GB.UTF-8 UTF-8
fr_CH.UTF-8 UTF-8
EOT
	
	sudo locale-gen
	sudo localectl set-locale LANG=en_GB.UTF-8
fi

if ! grep brcmfmac /etc/modprobe.d/raspi-blacklist.conf; then
	cat << EOT | sudo tee /etc/modprobe.d/raspi-blacklist.conf 
blacklist brcmfmac
blacklist brcmutil
blacklist bluetooth
EOT

	sudo modprobe -r brcmfmac
	sudo modprobe -r brcmutil
	sudo depmod -ae
	sudo update-initramfs -u
fi

sudo systemctl disable bluetooth
sudo systemctl enable ssh

if ! grep kodi /lib/systemd/system/kodi.service; then
	cat << EOT | sudo tee /lib/systemd/system/kodi.service
[Unit]
Description = Kodi Media Center
After = remote-fs.target network-online.target
Wants = network-online.target

[Service]
User = ${USER}
Group = ${USER}
Type = simple
ExecStart = /usr/bin/kodi-standalone
Restart = on-abort
RestartSec = 5

[Install]
WantedBy = multi-user.target
EOT

	sudo systemctl disable lightdm
	sudo systemctl enable kodi.service
fi

# Replace default green to orange prompt 
sed -i 's/\[\\033\[01;32m\\\]/\[\\033\[01;33m\\\]/g' ~/.bashrc

echo "> Please make sure you have a fixed IP !"
