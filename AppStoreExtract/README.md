# AppStore Extractor Script
Script to extract Installer packages from the Apple AppStore for macOS. 

### IMPORTANT
Before you start using this script, please make sure to have the needed licenses covered (for example by site license, Apps&Books or single licenses).

This script was tested under OS X Mavericks 10.9.5, Yosemite 10.10.5, OS X El Capitan 10.11.0, macOS Sierra 10.12.6, macOS High Sierra 10.13.1 and macOS Mojave 10.14.6. Compatibility with Catalina, see below.

__Attention__:  
If you extract on High Sierra (or higher), please be aware of the fact, that `hdiutil` will build DMGs with APFS as default filesystem. If you need to re-use your dmgs on older plattforms (10.11.x or older), please ad `-fs HFS+` to the hdiutil command.

__Compatibility with macOS Catalina__:
The scripts runs on macOS Catalina, but the finalize step (renaming the package) is not working as Apple has changed the way this information is distributed to the client. Until now, I do not have a solution for this, but a work around:

If you do not manually download the App(s) from the AppStore, but using the `mas-cli` [https://github.com/mas-cli/mas](https://github.com/mas-cli/mas) to install the apps on your Mac, my script is still able to pick-up the right version/name.


### Information
Based on an idea from Tim Sutton and Rich Trouton for downloading from the AppStore:
http://derflounder.wordpress.com/2013/10/19/downloading-microsofts-remote-desktop-installer-package-from-the-app-store/

Rich although published a detailed tutorial on how to use the script:
https://derflounder.wordpress.com/2015/11/19/downloading-installer-packages-from-the-mac-app-store-with-appstoreextract/


### How to use
This script needs the temporary download folder from the AppStore App, this is individual by host and is extracted from within the script using "getconf DARWIN_USER_CACHE_DIR".

If you want to check what folder is used by the AppStore.app, enter this command into your terminal:
`getconf DARWIN_USER_CACHE_DIR`

- The script generates and uses the directory "/Users/Shared/AppStore_Packages" as a destination, if you want to change this, just edit the script

- Open terminal and start this script (make it executable first), keep the window open. To make the package naming more munki friendly (using a "-" instead of "_") use the "-m" option to start the script: `AppStoreExtract.sh -m`

- Back in the AppStore.app, login in to your account and navigate to your purchases (or buy a new App)
  - Click "Install" for all desired packages
  - wait till every download/installation has finished

- go back to the terminal and continue the script by pressing any key to stop processing downloads

- answer the following question with yes (y) to finalize and clean up the downloaded packages

### other known problems
If the App ist to small (didn't find an exact size) the extraction might fail sometimes, probably when the installation is finished to fast.


### Alternatives
 -  __mas-cli project__ https://github.com/mas-cli/mas
 -  __AppStoreXtractor__ as a GO project https://github.com/schnoddelbotz/golang-playground (no longer maintained)

