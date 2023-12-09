#!/bin/bash

cd "`dirname $0`"

#
# List joysticks, we expect to have exactly 2.
# It doesn't matter which one we attach to which window, since the executable is stictly
# the same for both, it will have the same configuration / state
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

EXEC="/home/mob/Documents/sm64ex-coop/build/us_pc/run.sh"

firejail --noprofile $BLACKLIST_1 "$EXEC" &
firejail --noprofile $BLACKLIST_2 "$EXEC" &
