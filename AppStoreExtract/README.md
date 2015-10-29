# AppStore Extractor Script
Script to extract Installer packages from the Apple AppStore for OS X 

This script was tested under OS X Mavericks 10.9.5, Yosemite 10.10.5 ans OS X El Capitan 10.11.0

Based on an idea from Tim Sutton and Rich Trouton for downloading from the AppStore:
http://derflounder.wordpress.com/2013/10/19/downloading-microsofts-remote-desktop-installer-package-from-the-app-store/

# How to use
Short documentation
This script needs the temporary download folder from the AppStore App, this is individual by host

- Activate the AppStore debug mode
  - Quit the AppStore.app if it is running
  - open the terminal and enter
  	`defaults write com.apple.appstore ShowDebugMenu -bool true`
  - Start AppStore.app and open the Menu "Debug -> Show Download Folder..."
    - enter this folder path the AppStoreRoot in the script

- The script generates and uses the directory "/Users/Shared/AppStore_Packages" as a destination, if you want to change this, just edit the script

- open terminal and start this script (make it executable first), keep the window open.

- Back in the AppStore.app login in to your account and navigate to your purchases (or buy a new App)
  - Click "Install" for all desired packages
  - wait till every download/installation has finished

- go back to the terminal and continue the script by pressing any key to stop processing downloads

- answer the following question with yes (y) to finalize and clean up the downloaded packages


## known problems
If the App ist to small (didn't find an exact size) the extraction might fail sometime, probably when the installation is finished to fast.