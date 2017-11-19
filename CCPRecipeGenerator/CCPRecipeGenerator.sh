#!/bin/sh
# Autopkg Recipe overrides generator for Adobe CC
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Developed for use at ETH Zurich by Max Schlapfer
# 2017-03-09 - Initial Release
# 2017-11-11 - Adapted for the new AutoPKG processor
# 2017-11-19 - Made some code optimisation and added AutoPkg install logic
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Version 2.0
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Based on scripts and ideas from 
# - AutoPkg recipes for Creative Cloud Packager workflows:
	CCPRepo="https://github.com/autopkg/adobe-ccp-recipes"
#
# - A lot of discussions on the MacAdmins slack channels
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # #
# Definition of needed variables                #
# See the README.md for a detailed explanation  #
# # # # # # # # # # # # # # # # # # # # # # # # #

# Definition of environment specific variables
Organisation="ENTER YOUR ORGNAME HERE"
SerialNumber="ENTERYOURSERIALNUMBERHERE"
LicenseType="enterprise"								# this is either "enterprise" or "team"
Identifier="com.dummyorg.adobe"
LanguageShort=(EN DE)
Language=(en_US de_DE)
adminPrivilegesEnabled=false							# this is either true or false
matchOSLanguage=false									# this is either true or false
rumEnabled=false										# this is either true or false
updatesEnabled=false									# this is either true or false
appsPanelEnabled=false									# this is either true or false

# other variables
MasterRecipe="CreativeCloudApp.pkg.recipe"				# Overrides are based on this recipe
AUTOPKG=/usr/local/bin/autopkg							# Change if you change the AutoPkg defaults
PLISTBUDDY=/usr/libexec/PlistBuddy						# Path to PlistBuddy
AdobeList="./BaseList_AdobeFeed.txt"					# Adapted feed from Adobe, products and versions
AutoPKGRunSource="./AutoPKGRunSource.txt"				# A list of generated overrides, used for automation

# AutoPkg specific variables
AutoPkgBaseURL="https://github.com/autopkg/autopkg/releases/latest"
AutoPkgVersion=$(curl -sL ${AutoPkgBaseURL} | grep "css-truncate-target" | sed -n '1 p' | sed 's/<span class=\"css-truncate-target\">//;s/<\/span>//' | tr -d 'v' | xargs)
AutoPkgDownloadURL="https://github.com/autopkg/autopkg/releases/download/v${Version}/autopkg-${Version}.pkg"

# Default CCP path, should not be changed.
CCPPath="/Applications/Utilities/Adobe Application Manager/CCP/CreativeCloudPackager.app/Contents/MacOS/CreativeCloudPackager"

# # # # # # # # # # # # # # # # # # # # # # # # #
# Various checks to ensure all                  #
# packages/helpers are installed                #
# # # # # # # # # # # # # # # # # # # # # # # # #

# Check if Xcode command line tools are installed (especially git)
GitInstalled=$(which git)
if [ -z "${GitInstalled// }" ]; then
	echo "\Git is not installed on this machine\nInstalling the Xcode command line tools first before continuing.\n"
	exit 0
fi

# Check if AutoPkg is installed/available if not try to install it
AutoPkgInstalled=$(which autopkg)
if [ -z "${AutoPkgInstalled// }" ]; then
	echo "\nAutoPkg is not installed on this machine\nInstalling it now.\n"
	curl -Lo /tmp/autopkg-${AutoPkgVersion}.pkg ${AutoPkgDownloadURL}
	installer -pkg "/tmp/autopkg-${AutoPkgVersion}.pkg" -target /
	echo "\nAutoPkg is now in Version ${AutoPkgVersion} installed. Continuing...\n"
else
	echo "\nAutoPkg is installed. Continuing...\n"
fi

# Check if CCP recipes from Mosen are installed
# Installs the CCP repo when not present
InstalledRecipes=$(${AUTOPKG} repo-list | grep com.github.autopkg.adobe-ccp-recipes)
if [ -z "${InstalledRecipes// }" ]; then
	echo "\nCCP-Recipes from mosen are not installed\nAttempting to install the needed recipes\nfrom ${CCPRepo}:\n"
	${AUTOPKG} repo-add ${CCPRepo}
else
	echo "CCP autopkg repo found at ${InstalledRecipes}"
fi

# Get override path to find the generated files. If empty, set it to a default value
OverridePath=$(${AUTOPKG} info | grep RECIPE_OVERRIDE_DIRS | cut -d"'" -f4)
if [ -z "${OverridePath// }" ]; then
	echo "\nAutoPkg override path not defined, using standard destination (~/Library/AutoPkg/RecipeOverrides)\n"
	ActiveUser=$(id -un)
	OverridePath="/Users/${ActiveUser}/Library/AutoPkg/RecipeOverrides"
else
	echo "Override path already defined, using ${OverridePath}"
fi

# Set Name convention for output packages
AutoPkgRecipePath="$(autopkg repo-list | grep adobe-ccp | cut -d" " -f1)"
$PLISTBUDDY "${AutoPkgRecipePath}/Adobe/${MasterRecipe}" -c "set :Process:1:Arguments:package_name %NAME%_%version%_%LANGUAGESHORT%"

# Check if both Language arrays have the same length
if [ ! ${#Language[@]} -eq ${#LanguageShort[@]} ]; then
    echo "There is an error with the language definition:\Check your language variable arrays:\nBoth have to be of the same length."
fi

# prepare special version of list_ccp_feed.py
# based on the list_ccp_feed.py but edited for better handling within this script
# make a copy
cp ${AutoPkgRecipePath}/list_ccp_feed ./custom_list_ccp_feed.py

# replacing some text/commands
sed -i -e 's/print("SAP Code: {}".format(sapcode))//g' ./custom_list_ccp_feed.py 
sed -i -e 's/name,/sapcode, name,/g' ./custom_list_ccp_feed.py 
sed -i -e 's/print("\\t{0: <60}\\tBaseVersion: {1: <14}\\tVersion: {2: <14}"./print("{0},Adobe,{1},{2},{3}"./g' ./custom_list_ccp_feed.py 
sed -i -e 's/print("")/print("---")/g' ./custom_list_ccp_feed.py 

# Get an actual list of of Adobe Products and versions
echo "\nGetting Adobe product list with most recent versions...\n"
./custom_list_ccp_feed.py | grep -B 1 -e '---' | grep -v -e '---' | grep -v -e "--" > ./${AdobeList}

# Generate the recipe override for each available package
# then replace the defaults with the configurations per product
# loop once for each defined language
echo "\n* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
echo "Generating the recipe override for each available package."
echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"

for ((i=0;i<${#Language[@]};++i)); do
	LangCode=${Language[i]}
	LangShort=${LanguageShort[i]}
	
	while IFS=, read SAPCode Vendor Product BaseVersion Version; do
		if [ "$BaseVersion" == "N/A" ]; then
			BaseVersion=""
		fi
		
		# define package name
		Product=$(echo $Product | sed -e '/Adobe / s/// ; /Adobe /! s//0/')
		PackageName=$(echo "$Vendor"_"$Product"_"$Version"_"$LangShort" | tr " " "_")
		OverrideName=$(echo "$Vendor"_"$Product"_"$LangShort" | tr " " "_")
		ShortPackageName=$(echo "$Vendor"_"$Product" | tr " " "_")

		# Looping over each product in List
		echo "\n* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
		echo "${Product} in ${LangShort}"
		echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *"
	
		# Generate override file
		${AUTOPKG} make-override -n ${OverrideName}.pkg ${MasterRecipe}
		
		# replace variables to reflect product specific settings
		echo "Replacing the variables and parameters for ${OverrideName}.pkg."
		
		# Set the defined values for the Override
		$PLISTBUDDY "${OverridePath}/${OverrideName}.pkg.recipe" -c "set Identifier ${Identifier}.${ShortPackageName}"
		$PLISTBUDDY "${OverridePath}/${OverrideName}.pkg.recipe" -c "set Input:NAME ${ShortPackageName}"
		$PLISTBUDDY "${OverridePath}/${OverrideName}.pkg.recipe" -c "set Input:ccpinfo:adminPrivilegesEnabled ${adminPrivilegesEnabled}"
		$PLISTBUDDY "${OverridePath}/${OverrideName}.pkg.recipe" -c "set Input:ccpinfo:matchOSLanguage ${matchOSLanguage}"
		$PLISTBUDDY "${OverridePath}/${OverrideName}.pkg.recipe" -c "set Input:ccpinfo:rumEnabled ${rumEnabled}"
		$PLISTBUDDY "${OverridePath}/${OverrideName}.pkg.recipe" -c "set Input:ccpinfo:updatesEnabled ${updatesEnabled}"
		$PLISTBUDDY "${OverridePath}/${OverrideName}.pkg.recipe" -c "set Input:ccpinfo:appsPanelEnabled ${appsPanelEnabled}"
		$PLISTBUDDY "${OverridePath}/${OverrideName}.pkg.recipe" -c "set Input:ccpinfo:organizationName ${Organisation}"
		$PLISTBUDDY "${OverridePath}/${OverrideName}.pkg.recipe" -c "add Input:ccpinfo:serialNumber string ${SerialNumber}"
		$PLISTBUDDY "${OverridePath}/${OverrideName}.pkg.recipe" -c "set Input:ccpinfo:customerType ${LicenseType}"
		$PLISTBUDDY "${OverridePath}/${OverrideName}.pkg.recipe" -c "set Input:ccpinfo:Language ${LangCode}"
		$PLISTBUDDY "${OverridePath}/${OverrideName}.pkg.recipe" -c "add Input:LANGUAGESHORT string ${LangShort}"
		$PLISTBUDDY "${OverridePath}/${OverrideName}.pkg.recipe" -c "set :Input:ccpinfo:Products:0:baseVersion ${BaseVersion}"
		$PLISTBUDDY "${OverridePath}/${OverrideName}.pkg.recipe" -c "set :Input:ccpinfo:Products:0:sapCode ${SAPCode}"

		# Update Trust Information
		echo "Updating Trust Information for ${OverrideName}.pkg."
		${AUTOPKG} update-trust-info "${OverrideName}.pkg"

		# Add override to autopkg run source file
		echo "Writing ${OverrideName}.pkg.recipe to ${AutoPKGRunSource}."
		echo ${OverrideName}.pkg >> ${AutoPKGRunSource}

	done < "$AdobeList"
done

# Prepare AutoPKGRunSource
# sorting entries alphabetically for easier manual configuration
sort ${AutoPKGRunSource} -o ${AutoPKGRunSource} 

echo "\nAll overrides successfully generated!"

# Check if CreativeCloudPackager is installed:
if [ ! -f "${CCPPath}" ]; then
	echo "\nAdobe Creative Cloud Packager is not installed on this machine\nPlease install it before starting the build process/\n"
	exit 0
fi

# Successfully finished, continue?
echo "\nAll prerequisites are present, you can now start building your packages."

myinput=''
echo "\nDo you want to start building all packages now? (N/y)\n"
read -n 1 -s  myinput
if [ "$myinput" == "y" ]; then
	echo "Building the packages now, this may take some time, please stand by..."
	echo "Build process started at: $(date "+%Y-%m-%d - %H:%M:%S")"
	${AUTOPKG} run --recipe-list ${AutoPKGRunSource}
	echo "Build process finished at: $(date "+%Y-%m-%d - %H:%M:%S")"
	echo "\n\nThe packages build process has finished. Please find your Adobe packages in the AutoPkg Cache folder."
else
	echo "\n\nTo start the build process when you are ready, run: \n\nautopkg run --recipe-list ${AutoPKGRunSource}\n"
fi

