#!/bin/sh

if [ "`id -u`" -eq 0 ]; then
	echo "Do NOT run this script as root. It will call 'sudo' as needed."
	exit 1
fi

# 1. Install signal repository
# TODO

# VSCodium repository
if [ ! -f /etc/zypp/repos.d/vscodium.repo ]; then
	sudo rpmkeys --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg

	printf "[gitlab.com_paulcarroty_vscodium_repo]\nname=gitlab.com_paulcarroty_vscodium_repo\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg\nmetadata_expire=1h" | sudo tee -a /etc/zypp/repos.d/vscodium.repo

	sudo zypper update
fi

sudo zypper ar -cfp 90 -n Packman http://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman
sudo zypper ref
sudo zypper install vlc vlc-codecs
sudo zypper dup --from packman --allow-vendor-change

# 2. Install packages
sudo zypper install rclone gimp inkscape foliate goldendict-ng blender audacious neovim codium qt5ct kvantum-qt5 kvantum-qt6 flatpak

if [ ! -f /usr/local/bin/up ]; then
	cat << EOT | sudo tee -a /usr/local/bin/up
 #!/bin/sh

sudo zypper update
zypper packages --unneeded | awk -F'|' 'NR==0 || NR==1 || NR==2 || NR==3 || NR==4 {next} {print \$3}' | grep -v Name | sudo xargs zypper rm --clean-deps
sudo flatpak update
EOT
	sudo chmod +x /usr/local/bin/up
fi
 
sh "`dirname $0`/common-setup.sh"
