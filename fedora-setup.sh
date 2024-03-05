#!/bin/sh

###############################################
# This is the part that is specific to Debian #
###############################################

cd "`dirname $0`"

# 0. Check we are not admin
if [ "`id -u`" -eq 0 ]; then
	echo "Do NOT run this script as root. It will call 'sudo' as needed."
	exit 1
fi

# 1. Install signal repository
# TODO: Signal?

# 2. Install package
sudo dnf install rclone krita vlc transmission-gtk blender gnome-music vim-enhanced

# 3. Call the common script for non-specific configuration
sh ./common-setup.sh
