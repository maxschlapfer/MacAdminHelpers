##THIS PROJECT IS A WORK IN PROGRESS AND NOT YET FULLY TESTED
### We are still working out some details, please test before using!

This Objective-C project will grant access to the EndNote settings file using the OS to generate a sandbox securebookmarks file for EndNote to work together with Word 2016.

The program was developed by "Schnoddelbotz" (https://github.com/schnoddelbotz) based on input from
http://objcolumnist.com/2012/05/21/security-scoped-file-url-bookmarks


### What does this program?
This helper does grant access to the EndNote settings file on a per user base by touching the file `com.ThomsonResearchSoft.EndNote.plist` and then granting access to this file for Microsoft Word 2016 by generating a file containing the secure bookmark:

```
/Users/USERNAME/Library/Containers/com.microsoft.Word/Data/Library/Preferences/com.ThomsonResearchSoft.EndNote.securebookmarks.plist
````


### How To use?
Generate an App with Xcode, you can use the Xcode-Project or do it on the command line with the main.m file:

```
 clang -framework Foundation -o EndnoteSandboxAccess main.m
 codesign --sign - EndnoteSandboxAccess
```

Then deploy to every machine that you want to deploy EndNote and Office 2016. Make a postinstall script that runs this App in the user context of every existing user on the machine, for example with this code snippet:

```
# Set the Internal Field Separator for the Input to \n otherwise dscl-output is not correctly parsed.
IFS=$'\n'
for i in $(dscl . -list /Users PrimaryGroupID | grep ' 20$'| cut -d' ' -f1)
do
   sudo -- su - $i -c '/PATH/TO/EndnoteSandboxAccess'
done
unset IFS
```
