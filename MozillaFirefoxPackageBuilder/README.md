# Package Build scripts for Mozilla Firefox <br/> Rapid Release (RR) and Extended Support Release (ESR)

These scripts download the Mozilla Firefox installer for the Rapid Release (RR) or the Extended Support Release (ESR). They apply some Firefox configurations and include a Language switcher together with some language packs. After that the PKG is put in a diskimage and the temp. build directory is cleaned.

This script was tested under OS X El Capitan 10.11.3 with Firefox RR and ESR version 45.0.


###Based on ideas and scripts from:
The script was developed by the ITS Client Delivery group of ETH Zurich 
based on input from the following sources:

- Firefox.app/Contents/Resources/defaults/pref/
- https://developer.mozilla.org/en-US/docs/Mozilla/Preferences/A_brief_guide_to_Mozilla_preferences
- https://developer.mozilla.org/en-US/Firefox/Enterprise_deployment
- http://kb.mozillazine.org/Installing_extensions
- http://kb.mozillazine.org/Locking_preferences
- https://mike.kaply.com/2012/03/16/customizing-firefox-autoconfig-files/
- http://mxr.mozilla.org/mozilla-central/source/extensions/pref/autoconfig/src/nsAutoConfig.cpp
- http://web.mit.edu/~firefox/www/maintainers/autoconfig.html
- https://addons.mozilla.org/en-US/firefox/addon/deutsch-de-language-pack/versions/?page=1

 
###How to use the script?

1.	Edit the `firefox-ethz.cfg` file to reflect your needs and company name.

2.	Adapte the `autoconfig-ethz.js` to include your cfg file.
	
3.	If needed change the script to add your own Mozilla Add Ons or language kits and make them executable:
	`chmod 755 FirefoxBuilder_ESR.sh` or `chmod 755 FirefoxBuilder_RR.sh`
	
4.	Make sure to have enough disk space, the scripts needs temporarily less than 0.5 GB during execution when building the installer package.

5.	Make sure you have a working internet connection, as the script will download the full Firefox installer.
	
6.	When the script has finished, you will find the final DMG containing the package inside the results folder.

7.	You can now use this package to distribute inside your organization.


###Content Information
The base packages are the EN-US versions for the Rapid Release (RR) or the Extended Support Release (ESR). The following AddOns are integrated into the package(s) to make Firefox multilingual:

- Locale Switcher <br/>
  https://addons.mozilla.org/en-US/firefox/addon/locale-switcher/?src=ss

- Language Packs <br/>
  German:	https://addons.mozilla.org/en-US/firefox/addon/deutsch-de-language-pack/ <br/>
  French:	https://addons.mozilla.org/en-US/firefox/addon/français-language-pack/ <br/>
  Italian:	https://addons.mozilla.org/en-US/firefox/addon/italiano-it-language-pack/ <br/>
  Rhaeto-Romanic:	https://addons.mozilla.org/en-US/firefox/addon/rumantsch-language-pack/
