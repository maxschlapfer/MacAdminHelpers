#!/bin/sh -x
#
# Build script for MS Office 2016 Standard for Mac for Volume Licensing Distribution
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Based on scripts and ideas from 
# Rich Trouton:
# https://derflounder.wordpress.com/2015/08/05/creating-an-office-2016-15-12-3-installer/
# https://derflounder.wordpress.com/2016/01/14/creating-an-office-2016-15-18-0-installer/
# https://derflounder.wordpress.com/2016/01/17/suppressing-office-2016s-first-run-dialog-windows/
#
# Tim Sutton
# http://macops.ca/disabling-first-run-dialogs-in-office-2016-for-mac/
#
# Clayton Burlison
# https://clburlison.com/demystify-office2016/
#
# Eric Holtam
# https://osxbytes.wordpress.com/2015/09/17/not-much-whats-new-with-you/
# 
# The Slack Microsoft Office channel and all the people there: 
# A big thank you goes to this community!
# 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Adapted for use at ETH Zurich by Max Schlapfer
# Edited for newest release: 2016-01-18 (15.18)
# Edited to configure AutoUpdate: 2016-01-24
# Edited to check the parameter inputs: 2016-01-29
# Edited to reflect package name change of Microsoft original package: 2016-04-13
# Added change from zone11 to make the package more Munik and Filewave friendly: 2016-04-19
# Changed Serializer name to reflect new naming from Microsoft: 2016-08-13
# HTTPS for macadmins.software connection: 2017-01-23
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # # # # # # # # # # # #
# Definition of needed variables                #
# See the README.md for a detailed explanation  #
# # # # # # # # # # # # # # # # # # # # # # # # #

# Product name and Language
PRODUCT="Microsoft_Office_2016"
PKG_LANGUAGE="ML"

# Define main URL (https://macadmins.software)
MAINURL="https://macadmins.software/versions.xml"

# Get latest version number
FULL_VERSION=$(curl -s $MAINURL | xmllint --xpath '//latest/o365/text()' -)
 
# Determine working directory
EXE_DIR=$(dirname "$0")

# Excluding packages from installing, all listed Apps are excluded from the installation
# this is done with an InstallerChoices.xml that is generated based on the arguments.
if [ "$1" = "--exclude" ]; then
	DisabledPackages=($2)
else
	DisabledPackages=()
fi

for DisabledPKG in ${DisabledPackages[*]}
do
	echo $DisabledPKG | egrep -v '(word|excel|powerpoint|onenote.mac|outlook|autoupdate)'
	
	if [ $? -eq 0 ]; then
		echo "Sorry, bad arguments: You can only disable the installation of Word, Excel, PowerPoint, Outlook, OneNote or the AutoUpdater."
		echo "The only valid options are: word excel powerpoint onenote.mac outlook and autoupdate, each separated by space."
		echo "For Example to disable OneNote and the AutoUpdater."
		echo "./MS_Office_2016_PKGBuilder.sh --exclude \"onenote.mac autoupdate\""
		exit 1
	fi
done


# Use the URL from macadmins.software from the nearest site to your location
# 	AMERICAS:	https://go.microsoft.com/fwlink/?linkid=525133
# 	EUROPE:		https://go.microsoft.com/fwlink/?linkid=532572
# 	ASIA:		https://go.microsoft.com/fwlink/?linkid=532577
# Default setting is the European distribution server from Microsoft
FULL_INSTALLER="https://go.microsoft.com/fwlink/?linkid=532572"

# Define output name based on naming convention
OUTNAME="${PRODUCT}_${FULL_VERSION}_${PKG_LANGUAGE}"
PKG_ID="ch.ethz.mac.pkg.${PRODUCT}.${PKG_LANGUAGE}"

# needed directories 
# IMPORTANT:
# The following directory has to exist and must contain
# your Microsoft_Office_2016_VL_Serializer_2.0.pkg
# You can get this PKG from Microsoft:
# https://www.microsoft.com/Licensing/servicecenter/default.aspx
# Attention: You need a login and a valid contract with Microsoft!

LICENSE_DIR="${EXE_DIR}/volume_license"
								
	if [[ -e "${LICENSE_DIR}/Microsoft_Office_2016_VL_Serializer_2.0.pkg" ]]; then
	    echo "Valid license PKG found."
	else
    	echo "NO VALID LICENSING PKG FOUND! EXITING NOW"
    	echo "Download your licensing package and try again."
	    exit 0
	fi

RESULT_DIR="${EXE_DIR}/result"
	if [[ -e "${RESULT_DIR}" ]]; then
	    echo "Directory for final output found."
	else
    	echo "Directory for final output not found! Generating now."
	    mkdir -p "${RESULT_DIR}"
	fi

SCRIPT_DIR="${EXE_DIR}/${OUTNAME}/scripts"
	if [[ -e "${SCRIPT_DIR}" ]]; then
	    echo "Temp. working directory found."
	else
    	echo "Temp. directory not found! Generating now."
	    mkdir -p "${SCRIPT_DIR}"
	fi

EMPTY_DIR="${EXE_DIR}/empty"
	if [[ -e "${EMPTY_DIR}" ]]; then
	    echo "Directory for empty PKG found."
	else
    	echo "Directory for empty PKG not found! Generating now."
	    mkdir -p "${EMPTY_DIR}"
	fi

# # # # # # # # # # # # # # # # # #
# Building the package now        #
# # # # # # # # # # # # # # # # # #

# Download all needed files and put them together
# copy licensing package
cp -rp "${LICENSE_DIR}"/Microsoft_Office_2016_VL_Serializer_2.0.pkg "${SCRIPT_DIR}"

# Putting the InstallerChoices file into place when needed
if [ ${#DisabledPackages[@]} -eq 0 ]; then
	echo "No InstallerChoices needed continue."
else
	echo "Setup for InstallerChoices found, generating choices.xml now."
	cat <<- 'EOF' > "${SCRIPT_DIR}"/choices.xml
	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	<array>
	EOF

	for DisabledPKG in ${DisabledPackages[*]}
	do
		echo "<dict>\n<key>attributeSetting</key>\n<integer>0</integer>\n<key>choiceAttribute</key>\n<string>selected</string>\n<key>choiceIdentifier</key>\n<string>com.microsoft.${DisabledPKG}</string>\n</dict>" >> "${SCRIPT_DIR}"/choices.xml
	done
	echo "</array>\n</plist>" >> "${SCRIPT_DIR}"/choices.xml
fi

# get most recent full installer
curl -LsJ $FULL_INSTALLER -o "${SCRIPT_DIR}"/Microsoft_Office_2016_Installer.pkg

# generate postinstall script
cat <<- 'EOF' > "${SCRIPT_DIR}"/postinstall
#!/bin/bash
# automatically generated by the Office build script

# Define variables
submit_diagnostic_data_to_microsoft=false
turn_off_first_run_setup=true
one_note_int_array="-int 23 -int 18 -int 19 -int 17 -int 16 -int 5 -int 10 -int 1 -int 11 -int 13 -int 4 -int 9 -int 14 -int 2 -int 7 -int 12"

# Define what Apps are part of Office 2016, if anything changes in the future
Office2016Apps=(Excel OneNote Outlook PowerPoint Word)

# Determine working directory
WORKING_DIR=`dirname $0`

# Set Log File
LOGFILE="/var/log/MyLogs/MS_Office_2016.log"
LOGPATH=$(dirname "${LOGFILE}")

if [[ -e "${LOGFILE}" ]]; then
    echo "Log file found! Using this it!"
else
    echo "Log file not found! Generating one now."
    mkdir -p "${LOGPATH}"
    touch $LOGFILE
fi

# Define first run configure function
ConfigureOffice2016FirstRun()
{
    # This function will configure the first run dialog windows for all Office 2016 apps.
    # It will also set the desired diagnostic info settings for Office application.
    
    # Special check for OneNote as the application name and PLIST name are not the same.
    if [[ $app == OneNote ]]
    then
        app="onenote.mac";
    fi

   /usr/bin/defaults write /Library/Preferences/com.microsoft."$app" kSubUIAppCompletedFirstRunSetup1507 -bool "$turn_off_first_run_setup"
   /usr/bin/defaults write /Library/Preferences/com.microsoft."$app" SendAllTelemetryEnabled -bool "$submit_diagnostic_data_to_microsoft"

    # Outlook requires one additional first run setting to be disabled
    if [[ $app == "Outlook" ]]; then
        /usr/bin/defaults write /Library/Preferences/com.microsoft."$app" FirstRunExperienceCompletedO15 -bool "$turn_off_first_run_setup"
    fi
    
    # OneNote has a different structure for suppressing the "What's New" dialogs - an array of ints
    if [[ $app == "onenote.mac" ]]; then
        /usr/bin/defaults write /Library/Preferences/com.microsoft."$app" ONWhatsNewShownItemIds -array ${one_note_int_array}
        /usr/bin/defaults write /Library/Preferences/com.microsoft."$app" FirstRunExperienceCompletedO15 -bool "$turn_off_first_run_setup"
    fi
        
}

# Remove an old 2016 volume licensing file
# due to an error in the licensing file, old versions will stop working in Q2/2016
# check for existance of Office 2016 licensing file and remove it if found
if [[ -e "/Library/Preferences/com.microsoft.office.licensingV2.plist" ]]; then
    echo "$(date): old Volume License file found. Removing it before installing new one."      2>&1 | tee -a $LOGFILE
        rm /Library/Preferences/com.microsoft.office.licensingV2.plist
else
    echo "$(date): Volume License file not found! Installing new one now."      2>&1 | tee -a $LOGFILE
fi

# Install Microsoft Office 2016
if [[ -e "$WORKING_DIR/choices.xml" ]]; then
    echo "InstallerChoices file found! Using this it!"      2>&1 | tee -a $LOGFILE
    /usr/sbin/installer -dumplog -verbose -pkg "$WORKING_DIR/Microsoft_Office_2016_Installer.pkg" -applyChoiceChangesXML "$WORKING_DIR/choices.xml" -target "$3"   2>&1 | tee -a $LOGFILE
else
    echo "InstallerChoices file not found! Continuing!"      2>&1 | tee -a $LOGFILE
    /usr/sbin/installer -dumplog -verbose -pkg "$WORKING_DIR/Microsoft_Office_2016_Installer.pkg" -target "$3"   2>&1 | tee -a $LOGFILE
fi

# Install the Microsoft Office 2016 Volume License file from
/usr/sbin/installer -dumplog -verbose -pkg "$WORKING_DIR/Microsoft_Office_2016_VL_Serializer_2.0.pkg" -target "$3"   2>&1 | tee -a $LOGFILE

# Configure AutoUpdate behaviour (set to manual check and hide insider program)
/usr/bin/defaults write /Library/Preferences/com.microsoft.autoupdate2 HowToCheck -string 'Manual'
/usr/bin/defaults write /Library/Preferences/com.microsoft.autoupdate2 LastUpdate -date '2016-01-13T15:00:00Z'
/usr/bin/defaults write /Library/Preferences/com.microsoft.autoupdate2 DisableInsiderCheckbox -bool TRUE

# Configure the default save location for Office for all existing users
# Set the Internal Field Separator for the Input to \n otherwise dscl-output is not correctly parsed.
IFS=$'\n'
for i in $(dscl . -list /Users PrimaryGroupID | grep ' 20$'| cut -d' ' -f1)
do
   sudo -- su - $i -c 'defaults write ~/Library/Group\ Containers/UBF8T346G9.Office/com.microsoft.officeprefs DefaultsToLocalOpenSave -bool TRUE'
done
unset IFS


# Configure Office First Run behaviour now
for APPNAME in ${Office2016Apps[*]}
do
    if [[ -e "/Applications/Microsoft $APPNAME.app" ]]; then
        app=$APPNAME
        ConfigureOffice2016FirstRun
    fi
done

exit 0
EOF

chmod +x "${SCRIPT_DIR}"/postinstall


# build final installer PKG with dummy payload
pkgbuild --identifier "$PKG_ID" --version "$FULL_VERSION" --root "${EMPTY_DIR}" --scripts "${SCRIPT_DIR}" "${EXE_DIR}/${OUTNAME}.pkg"

# make DMG containing the configured Microsoft Office Full Installer package
hdiutil create -volname ${OUTNAME} -srcfolder "${EXE_DIR}/${OUTNAME}.pkg" -format UDRO "${RESULT_DIR}/${OUTNAME}.dmg"


# clean up after building
rm -rf "${EXE_DIR}/${OUTNAME}"
rm -f "${EXE_DIR}/${OUTNAME}.pkg"

echo "DONE"

exit 0
