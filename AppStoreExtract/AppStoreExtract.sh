#!/bin/bash
###
# Script to extract Installer packages from the Apple AppStore for OS X 
###
# last edited: 2017-02-16
###
# This script was tested under
# OS X Mountain Lion v10.8.5
# OS X Mavericks 10.9.x
# OS X El Capitan 10.11.x
# macOS Sierra 10.12.x
# macOS High Sierra 10.13.1
#
# Based on an idea from Rich Trouton for downloading from the AppStore:
# http://derflounder.wordpress.com/2013/10/19/downloading-microsofts-remote-desktop-installer-package-from-the-app-store/
###
# Edited and extended for internal use at ETH Zurich
# by Katiuscia Zehnder, Jan Hacker and Max Schlapfer
###


###
# Short documentation
# - This script needs the temporary download folder from the AppStore App, this is individual by host
#   and is extracted by using "getconf DARWIN_USER_CACHE_DIR".
#   In macOS versions before Sierra (10.11.x and older), you can access the debug menu in the AppStore App: 
#	- Quit the AppStore.app if it is running
#   	- Open the terminal and enter "defaults write com.apple.appstore ShowDebugMenu -bool true"
#   	- Start AppStore.app and browse the menu Debug
#	--> The debug menu is no longer accessible with macOS Sierra v10.12.0 or higher.
# - The folder /Users/Shared/AppStore_Packages is generated and used as the packages output folder
# - Open Terminal and start this script (if needed make it executable first), keep the window open.
#   If the output will be used with munikimport add the option "-m" to make the naming munki-friendly
# - Back in the AppStore.app login in to your account and navigate to your purchases
#   - Click "Install" for all desired packages
#   - Wait till every download/installation has finished
# - Go back to the terminal and continue the script by pressing any key to stop processing downloads
# - Answer the following question with yes (y) to finalize and clean up the downloaded packages
###

###
# Definition of the local temporary AppStore folder
###
AppStoreRoot="$(getconf DARWIN_USER_CACHE_DIR)/com.apple.appstore"

###
# Definition of the local output folder where the extracted packages are stored on your machine
###
mkdir -p /Users/Shared/AppStore_Packages

Destination="/Users/Shared/AppStore_Packages/"

# Let users switch to munki naming convention by using -m as first argument to this script
separator="_"
if [ "$1" = "-m" ]; then
 separator="-"
fi


# Make sure we can find PlistBuddy
if [ -e "/usr/libexec/PlistBuddy" ] ; then
	PBUDDY="/usr/libexec/PlistBuddy"
else
	echo "Can't find PlistBuddy. Aborting configuration script."
	exit
fi

echo "Press any key to finish after downloading new software from AppStore."
myinput=''

if [ -t 0 ]; then stty -echo -icanon -icrnl time 0 min 0; fi
while [ "x${myinput}" = "x" ]
do 
	find "$AppStoreRoot" -name \*.pkg  | xargs -I {} sh -c 'ln "$1" "$2$(basename $1)" 2> /dev/null ; cp -n "$3/manifest.plist" "$2$(basename $1).plist" ' - {} "$Destination" "$AppStoreRoot"
	myinput="`cat -v`"
	sleep 0.05
done
if [ -t 0 ]; then stty sane; fi

echo -e '\n\nDo you want to finalize the packages? (N/y)\n'
read -n 1 -s  myinput
if [ "$myinput" == "y" ]
then
	for swpkg in ${Destination}*.plist
	do
	#    plutil -convert xml1 $swpkg
	    mypackage=`echo  $(basename $swpkg) | perl -pe 's/\.plist$//'`
	   
		i=0
		while [ 1 ]; do
	        pkgname=$($PBUDDY -c "Print :representations:${i}:assets:0:name" "$swpkg" 2>/dev/null)
	        if [ $? -ne 0 ]; then
	                # finish execution
	                break
	                #exit 0
	        fi
			if [ "$pkgname" == "$mypackage" ]; then
		    	version=$($PBUDDY -c "Print :representations:${i}:bundle-version" "$swpkg" 2>/dev/null)
		    	appname=$($PBUDDY -c "Print :representations:${i}:title" "$swpkg" 2>/dev/null)
		    	appname=`echo $appname | perl -pe 's/\ //g'`
				echo "Softwarepackage will be renamed from ${Destination}${mypackage} to ${Destination}${appname}${separator}${version}.pkg"
				mv "${Destination}${mypackage}" "${Destination}${appname}${separator}${version}.pkg" 2>/dev/null
				rm "${Destination}${mypackage}.plist"
	        fi
	        i=$(($i+1))
		done
	done

	echo -e '\nThe packages will be converted into dmg files. This could take a while.' 
	for swpkg in ${Destination}*.pkg
	do
		finaldmg=`echo ${swpkg} | perl -pe 's/\.pkg$//'`
		echo -e "\ncreating ${finaldmg}.dmg"
		hdiutil create -srcfolder "${swpkg}" -format UDRO "${finaldmg}"
		rm "${swpkg}"
	done

fi
