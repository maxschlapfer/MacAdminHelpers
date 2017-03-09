#!/bin/sh
# Autopkg Recipe generator for Adobe CC workflow
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Developed for use at ETH Zurich by Max Schlapfer
# 2017-03-09 - Initial Release
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Based on scripts and ideas from 
# - AutoPkg recipes for Creative Cloud Packager workflows:
#	 https://github.com/mosen/ccp-recipes
#
# - A lot of discussions on the MacAdmins slack channels
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# # # # # # # # # # # # # # # # # # # # # # # # #
# Definition of needed variables                #
# See the README.md for a detailed explanation  #
# # # # # # # # # # # # # # # # # # # # # # # # #

# Definition of environment specific variables
Organisation="YOUR ORG NAME"
SerialNumber="123456789012345678901234"
LicenseType="enterprise"
Identifier="com.company"
Language=(en_US de_DE)
LanguageShort=(EN DE)

# other variables
AUTOPKG=/usr/local/bin/autopkg							# Change if you change the AutoPkg defaults
AdobeList="./BaseList_AdobeFeed.txt"					# Adapted feed from Adobe, products and versions
AutoPKGRunSource="./AutoPKGRunSource.txt"				# A list of generated overrides, used for automation
MasterRecipe="MasterCreativeCloudApp.pkg.recipe"	# Overrides are based on this recipe

# Default CCP path, should not be changed.
CCPPath="/Applications/Utilities/Adobe Application Manager/CCP/CreativeCloudPackager.app/Contents/MacOS/CreativeCloudPackager"


# # # # # # # # # # # # # # # # # # # # # # # # #
# Various checks to ensure all                  #
# packages/helpers are installed                #
# # # # # # # # # # # # # # # # # # # # # # # # #

# Check if both Language arrays have the same length
if [ ! ${#Language[@]} -eq ${#LanguageShort[@]} ]; then
    echo "There is an error with the language definition:\Check your language variable arrays:\nBoth have to be of the same length."
fi

# Check if AutoPkg ist installed/available
AutoPkgInstalled=$(which autopkg)
if [ -z "${AutoPkgInstalled// }" ]; then
	echo "\nAutoPkg is not installed on this machine\nPlease install AutoPkg before running this script:\nhttp://autopkg.github.io/autopkg/\n"
	exit 0
fi

# Check if CCP recipes from Mosen are installed
# Installs the CCP repo when not present
InstalledRecipes=$(${AUTOPKG} repo-list | grep com.github.mosen.ccp-recipes)
echo "Repo found at ${InstalledRecipes}"
if [ -z "${InstalledRecipes// }" ]; then
	echo "\nCCP-Recipes from mosen are not installed\nAttempting to install the needed recipes\nfrom https://github.com/mosen/ccp-recipes:\n"
	${AUTOPKG} repo-add https://github.com/mosen/ccp-recipes.git
fi

# Moving the MasterRecipe in Place
AutoPkgRecipePath="$(autopkg repo-list | cut -d" " -f1)"
cp ./Custom_CreativeCloudApp.pkg.recipe "${AutoPkgRecipePath}/Adobe/${MasterRecipe}"

# Get an actual list of of Adobe Products and version
# based on the ListFeed.py but edited for better handling within this script
echo "\nGetting Adobe product list with most recent versions...\n"
./Custom_AdobeLstfeed.py | grep -B 1 -e '---' | grep -v -e '---' | grep -v -e "--" > ./${AdobeList}


# Generate the recipe override for each available package
# then replace the defaults with the configurations per product
# loop once for each defined language
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
		ShortPackageName=$(echo "$Vendor"_"$Product"_"$LangShort" | tr " " "_")
	
		# Generate override file
		${AUTOPKG} make-override -n ${PackageName}.pkg ${MasterRecipe}
		
		# Get override path to find the generated files
		OverridePath=$(${AUTOPKG} info | grep RECIPE_OVERRIDE_DIRS | cut -d"'" -f4)

		# replace variables to reflect product specific settings
		sed -i "" -e "s/local.*/${Identifier}.${ShortPackageName}\<\/string\>/g" "${OverridePath}/${PackageName}.pkg.recipe"
		sed -i "" -e "s/XX-ORGNAME-XX/${Organisation}/g" "${OverridePath}/${PackageName}.pkg.recipe"
		sed -i "" -e "s/XX-SAPCODE-XX/${SAPCode}/g" "${OverridePath}/${PackageName}.pkg.recipe"
		sed -i "" -e "s/XX-PKGName-XX/${PackageName}/g" "${OverridePath}/${PackageName}.pkg.recipe"
		sed -i "" -e "s/XX-BASE_VERSION-XX/${BaseVersion}/g" "${OverridePath}/${PackageName}.pkg.recipe"
		sed -i "" -e "s/XX-SERIAL_NUMBER-XX/${SerialNumber}/g" "${OverridePath}/${PackageName}.pkg.recipe"
		sed -i "" -e "s/XX-LICENSE_TYPE-XX/${LicenseType}/g" "${OverridePath}/${PackageName}.pkg.recipe"
		sed -i "" -e "s/XX-LANGUAGE-XX/${LangCode}/g" "${OverridePath}/${PackageName}.pkg.recipe"
	
		# Add override to autopkg run source file
		echo ${PackageName}.pkg.recipe >> ${AutoPKGRunSource}
	
	done < "$AdobeList"
done

# Prepare AutoPKGRunSource (sort entries alphabetically for easier manual configuration)
sort ${AutoPKGRunSource} -o ${AutoPKGRunSource} 

# Update trust information for all generated overrides
RECIPES=*.recipe

for r in "${OverridePath}/${RECIPES}"; do
    echo "Updating trust information for ${r}\n"
    ${AUTOPKG} update-trust-info ${r}
done

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
