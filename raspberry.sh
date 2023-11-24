#!/bin/sh

sudo apt-get install kodi kodi-peripheral-joystick openssh-server unison lightdm 
#xfce4

cat << EOT | sudo tee /etc/modprobe.d/raspi-blacklist.conf 
blacklist brcmfmac
blacklist brcmutil
EOT

sudo modprobe -r brcmfmac
sudo modprobe -r brcmutil
sudo depmod -ae
sudo update-initramrf -u

sudo systemctl disable bluetooth
sudo systemctl enable ssh

cat << EOT | sudo tee /etc/lightdm/lightdm.conf
[SeatDefaults]
autologin-user=mob
user-session=kodi
EOT

echo "Manual steps:"
echo "- Make sure you have a fixed IP."
echo "- Update the PS1 color."
