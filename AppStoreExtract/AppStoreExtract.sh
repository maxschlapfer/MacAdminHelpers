#!/bin/bash
###
# Script to extract Installer packages from the Apple AppStore for OS X 
#
# This script was tested under OS X Mountain Lion v10.8.5 and OS X Mavericks 10.9.x
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
#   and is extracted by "getconf DARWIN_USER_CACHE_DIR"
#   If you want to access the debug mode of the AppStore:
#	- Quit the AppStore.app if it is running
#   	- open the terminal and enter "defaults write com.apple.appstore ShowDebugMenu -bool true"
#   	- Start AppStore.app and browse the menu Debug
# - The folder /Users/Shared/AppStore_Packages is generated and used as the packages output folder
# - open Terminal and start this script (if needed make it executable first), keep the window open.
# - Back in the AppStore.app login in to your account and navigate to your purchases
#   - Click "Install" for all desired packages
#   - wait till every download/installation has finished
# - go back to the terminal and continue the script by pressing any key to stop processing downloads
# - answer the following question with yes to finalize and clean up the downloaded packages
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



# Make sure we can find PlistBuddy
if [ -e "/usr/libexec/PlistBuddy" ] ; then
	PBUDDY="/usr/libexec/PlistBuddy"
else
	echo "Can't find PlistBuddy. Aborting configuration script."
	exit
fi

echo "Press any key to finish after downloading new software from AppStore."
myinput="" 
if [ -t 0 ]; then stty -echo -icanon time 0 min 0; fi
while [ "x${myinput}" == "x" ]
do 
	find "$AppStoreRoot" -name \*.pkg  | xargs -I {} sh -c 'ln "$1" "$2$(basename $1)" 2> /dev/null ; cp -n "$3/manifest.plist" "$2$(basename $1).plist" ' - {} "$Destination" "$AppStoreRoot"
	read myinput
done
if [ -t 0 ]; then stty sane; fi

echo "\n\nDo you want to finalize the packages? (N/y)"
read myinput
if [ "$myinput" == "y" ]
then
	for swpkg in ${Destination}*.plist
	do
	#    plutil -convert xml1 $swpkg
	    mypackage=`echo  $(basename $swpkg) | perl -pe 's/\.plist//g'`
	   
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
				echo "Softwarepackage will be renamed from ${Destination}${mypackage} to ${Destination}${appname}_${version}.pkg"
				mv "${Destination}${mypackage}" "${Destination}${appname}_${version}.pkg" 2>/dev/null
				rm "${Destination}${mypackage}.plist"
	        fi
	        i=$(($i+1))
		done
	done

	echo "\nThe packages will be converted into dmg-Files. This could take a while."
	for swpkg in ${Destination}*.pkg
	do
		finaldmg=`echo ${swpkg} | perl -pe 's/\.pkg$//'`
		echo "\ncreating ${finaldmg}.dmg"
		hdiutil create -srcfolder "${swpkg}" -format UDRO "${finaldmg}"
		rm "${swpkg}"
	done

fi
