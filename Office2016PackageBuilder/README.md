**Please test before using it in your production environment.**


# Package Build script for Microsoft Office 2016

**Important:** You need a Volume License from Microsoft to use this script.

This scripts downloads the Full Installer for Microsoft Office, adds the Volume License Installer and some configurations and generates a package without changing the original package from Microsoft. After that it puts the PKG in a diskimage and cleans the temp. directory.

When deploying with the final package, sending Telemetry Data to Microsoft is disabled, the "First Run" and "What's New" dialogs are turned off and the AutoUpdater will be set to manually check for updates and the insider program feature is disabled.

This script was tested under OS X El Capitan 10.11.3.


###Based on ideas and scripts from:
- Rich Trouton:
  - https://derflounder.wordpress.com/2015/08/05/creating-an-office-2016-15-12-3-installer/
  - https://derflounder.wordpress.com/2016/01/14/creating-an-office-2016-15-18-0-installer/
  - https://derflounder.wordpress.com/2016/01/17/suppressing-office-2016s-first-run-dialog-windows/

- Tim Sutton
  - http://macops.ca/disabling-first-run-dialogs-in-office-2016-for-mac/

- Clayton Burlison
  - https://clburlison.com/demystify-office2016/
 
- Eric Holtam
  - https://osxbytes.wordpress.com/2015/09/17/not-much-whats-new-with-you/

- The Slack Microsoft Office channel and all the people there: A big thank you goes to this community!

- Thanks to Jan for his scripting help!
  - https://github.com/schnoddelbotz 
 
###How to use the script?

1.	Save the MS_Office_2016_PKGBuilder-Script in a folder on your local machine.

2.	Generate a folder called "volume_license" in the same directory as this script and put the Microsoft_Office_2016_VL_Serializer.pkg in this folder. You can get this PKG directly from Microsoft: https://www.microsoft.com/Licensing/servicecenter/default.aspx
	
	**Attention: You need a login and a valid Volume Licensing contract with Microsoft to access this package.** 

3.	make the script executable:
	`chmod 755 MS_Office_2016_PKGBuilder.sh`
	
4.	Make sure to have enough disk space, the scripts needs around 4.5 GB during execution when building the Full Installer package.

5.	Make sure you have a working internet connection, as the script will download the full office installer from the Microsoft server (for version 15.18 the size is about 1.4 GB).

6.	Run the MS_Office_2016_PKGBuilder script.
	The process will take a few minutes to complete with a fast internet connection

	If you want to exclude some packages you can do with the argument `--exclude` plus a quoted list of Apps or Office parts to exclude (this will generate an InstallerChoices.xml that is used during the Office installation):
	
	The following Installer Choices are available (with version 15.18):
	`word` `excel` `powerpoint` `onenote.mac` `outlook` and `autoupdate`

	**Important: Please do not deactivate the installation of the fonts, frameworks and proofing tools, as you might end up with unstable and unsupported setup.**

	for example `./MS_Office_2016_PKGBuilder.sh --exclude "onenote.mac autoupdate"` to exclude OneNote and the AutoUpdater app or run `./MS_Office_2016_PKGBuilder.sh`without any arguments to install everything.
	
7.	When the script has finished, you will find the final DMG containing the package inside the results folder.

8.	You can now use this package to distribute inside your organization.


###What can you configure?
The following parameters are used and might be changed to fit your needs. The default value is defined below:

1.	`PRODUCT="Microsoft_Office_2016"`

	This is the product name, on which the final output name is based.

2.	`PKG_LANGUAGE="ML"`
	
	As Office 2016 is multi-language this tag is pre-set to ML.

3.	`MAINURL="http://macadmins.software/versions.xml"`
	
	This site is officially maintained by Microsoft.
	You should not change this value.

4.	`FULL_VERSION`
	
	The most recent version is extracted from the MAINURL and is automatically set.

5.	`FULL_INSTALLER="http://go.microsoft.com/fwlink/?linkid=532572"`
	
	This URL depends on what you need or where you are based in the world. Default link is the Full Installer from the European server from Microsoft, change it according to your needs:

		AMERICAS:	http://go.microsoft.com/fwlink/?linkid=525133
		EUROPE:		http://go.microsoft.com/fwlink/?linkid=532572
		ASIA:		http://go.microsoft.com/fwlink/?linkid=532577
		
	More URLs (single Packages, Update Information) are available from http://macadmins.software.
	
6.	`OUTNAME="${PRODUCT}_${FULL_VERSION}_${PKG_LANGUAGE}"`
	
	The outname defines our naming convention for the resulting package, feel free to edit.

7.	`PKG_ID="com.company.myname.pkg.${PRODUCT}.${PKG_LANGUAGE}"`
	
	The package ID, adapt to reflect your company infos.


The scripts generates a postinstall script to apply all the desired settings. To change the defaults you need to edit the following variables within the postinstall part:

8.	`submit_diagnostic_data_to_microsoft=false`
	
	This defines if you send telemetry data to Microsoft. It is unclear what kind of data is collected (by Office 2016 for Mac) and send. Default of this script is to turn it off.
	
9.	`turn_off_first_run_setup=true`
	
	This settings defines if you want to show the first run and "What's new" dialogs for each application. The default is to turn this off in a managed environment.

10.	`Office2016Apps=(Excel OneNote Outlook PowerPoint Word)`
	
	This is the list of Apps inside the Office package, change this list if Microsoft adds some new apps in the future.

11.	`LOGFILE="/var/log/MyLogs/MS_Office_2016.log"`
	
	Defines the Logfile and path were the postinstall output writes the script output.


### Known Issues
- Under some circumstances the "What's new" dialog within OneNote still shows up. Haven't found out where the problem is as it should not show up for VL serialized installations.
