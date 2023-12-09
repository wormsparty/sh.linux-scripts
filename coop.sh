#!/bin/bash

#
# This scripts allows to run the same executable twice, and blacklist the joystick assigned to the other window.
# This supposes the executable can be run in windowed mode. If not, you may want to wrap it in a "weston" window.
#
# First, list the joysticks, we expect to have exactly 2.
# It doesn't matter which one we attach to which window, since the executable is strictly
# the same for both, it will have the same configuration / state.
#
CONTROLLER_LIST=$(ls -l /dev/input/by-id/ | grep joystick |  awk '{gsub("-joystick", ""); gsub("-event", ""); print $9}' | uniq)
CONTROLLER_COUNT=$(echo "$CONTROLLER_LIST" | wc -l)

if [ $CONTROLLER_COUNT -ne 2 ]; then
	echo "Found $CONTROLLER_COUNT joysticks, please have exactly 2 plugged in."
	exit 1
fi

CONTROLLER_1=$(echo $CONTROLLER_LIST | sed -n '1 p')
CONTROLLER_2=$(echo $CONTROLLER_LIST | sed -n '2 p')
BLACKLIST_1=$(echo $(ls -l /dev/input/by-id/ | grep joystick | grep -wv $CONTROLLER_1 | awk '{print "--blacklist=/dev/input/by-id/" $9;}' ) )
BLACKLIST_2=$(echo $(ls -l /dev/input/by-id/ | grep joystick | grep -wv $CONTROLLER_2 | awk '{print "--blacklist=/dev/input/by-id/" $9;}' ) ) 

# Run the executable twice. 
# Note: Use win+left and win+right to move the windows to use the left and right half, they may both start at the same position
firejail --noprofile $BLACKLIST_1 $@ &
firejail --noprofile $BLACKLIST_2 $@ &
