#!/bin/bash
# Author: maxschlapfer $
###########################################################################
# Disable Automatic 802.1x connection on wired interfaces for all users
###########################################################################

sudo logger "802.1x Setup:   Automatic 802.1x connection on wired interfaces for all existing users disabled."

IFS=$'\n'

for i in $(dscl . -list /Users PrimaryGroupID | grep ' 20$'| cut -d' ' -f1)
do
   sudo -- su - $i -c 'defaults -currentHost write com.apple.network.eapolcontrol EthernetAutoConnect -bool FALSE'
done
