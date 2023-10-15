#!/bin/sh

if [ "`id -u`" -eq 0 ]; then
	echo "Do NOT run this script as root. It will call 'sudo' as needed."
	exit 1
fi

if ! which vlc; then
	sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
	sudo dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
	sudo dnf install vlc
fi

if ! which codium; then
	sudo rpmkeys --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg
	printf "[gitlab.com_paulcarroty_vscodium_repo]\nname=download.vscodium.com\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg\nmetadata_expire=1h" | sudo tee -a /etc/yum.repos.d/vscodium.repo
	sudo dnf install codium
fi

sudo yum install rclone gimp inkscape transmission-gtk blender goldendict audacious libreoffice-writer qt5ct kvantum neovim flatpak gnome-tweaks gnome-extensions-app
sudo flatpak install org.signal.Signal
sudo flatpak install com.github.johnfactotum.Foliate

if [ ! -f /usr/local/bin/up ]; then
	cat << EOT | sudo tee -a /usr/local/bin/up
 #!/bin/sh

sudo yum update
sudo flatpak update
EOT
	sudo chmod +x /usr/local/bin/up
fi

sh "`dirname $0`/common-setup.sh"
