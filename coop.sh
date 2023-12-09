#!/bin/bash

cd "`dirname $0`"
DIR_CO_OP_CONT=./controller_blacklists

# Ask the user for which controller to use 
rm -rf $DIR_CO_OP_CONT
mkdir $DIR_CO_OP_CONT
CONTROLLER_LIST=$(ls -l /dev/input/by-id/ | grep joystick |  awk '{gsub("-joystick", ""); gsub("-event", ""); print $9}' | uniq)
CONTROLLER_1=$(zenity --list --title="Choose controller for player 1" --text="" --column=Controllers \ $CONTROLLER_LIST)
CONTROLLER_2=$(zenity --list --title="Choose controller for player 2" --text="" --column=Controllers \ $CONTROLLER_LIST)
echo $(ls -l /dev/input/by-id/ | grep joystick | grep -wv $CONTROLLER_1 | awk '{print "--blacklist=/dev/input/by-id/" $9;}' ) >> $DIR_CO_OP_CONT/Player1_Controller_Blacklist
echo $(ls -l /dev/input/by-id/ | grep joystick | grep -wv $CONTROLLER_2 | awk '{print "--blacklist=/dev/input/by-id/" $9;}' ) >> $DIR_CO_OP_CONT/Player2_Controller_Blacklist 

GAMERUN="/home/mob/Documents/sm64ex-coop/build/us_pc/run.sh"
WIDTH=960
HEIGHT=1080

firejail --noprofile $(cat $DIR_CO_OP_CONT/Player1_Controller_Blacklist ) "$GAMERUN" &
firejail --noprofile $(cat $DIR_CO_OP_CONT/Player2_Controller_Blacklist ) "$GAMERUN" &
