#!/bin/sh

sudo apt-get install vim kodi kodi-peripheral-joystick openssh-server unison lightdm 

cat << EOT | sudo tee /etc/locale.gen
en_GB.UTF-8 UTF-8
fr_CH.UTF-8 UTF-8
EOT

sudo locale-gen
sudo localectl set-locale LANG=en_GB.UTF-8

cat << EOT | sudo tee /etc/modprobe.d/raspi-blacklist.conf 
blacklist brcmfmac
blacklist brcmutil
blacklist bluetooth
EOT

sudo modprobe -r brcmfmac
sudo modprobe -r brcmutil
sudo depmod -ae
sudo update-initramfs -u

sudo systemctl disable bluetooth
sudo systemctl enable ssh

cat << EOT | sudo tee /etc/lightdm/lightdm.conf
[SeatDefaults]
autologin-user=$USER
user-session=kodi
EOT

echo "Manual steps:"
echo "- Make sure you have a fixed IP."
echo "- Update the PS1 color."
