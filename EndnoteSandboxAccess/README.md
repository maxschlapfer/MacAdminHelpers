##EndNote Sandbox Access Helper App

####unsuccessful atempt
This Objective-C project tried to grant access to the EndNote settings file using the OS to generate a sandbox securebookmarks file for EndNote to work together with Word 2016. We weren't successful reaching our goal, but the code may help to implement security-scoped bookmarks in your projects.

###Background information
The program was developed by "Schnoddelbotz" (https://github.com/schnoddelbotz) based on the findings from
http://objcolumnist.com/2012/05/21/security-scoped-file-url-bookmarks

But after intense testing we weren't able to reach our goal: We would probably need a valid certificate to sign our app either from Thomson Reuters or Microsoft to successfully write this file.

More information from Apple about sandboxing apps and especially about security-scoped bookmarks can be found in this video (starting at 21:30): https://developer.apple.com/videos/play/wwdc2012-700/

Based on that: This is not working as expected as the sandbox environment checks some signing to prevent other apps to sneek in and place some malicious code, which is actually a good thing, but a show stopper for our idea.


### What was the goal of this program?
This helper should grant access to the EndNote settings file on a per user base by touching the file `com.ThomsonResearchSoft.EndNote.plist` and then granting access to this file for Microsoft Word 2016 by generating a file containing the secure bookmark:

```
/Users/USERNAME/Library/Containers/com.microsoft.Word/Data/Library/Preferences/com.ThomsonResearchSoft.EndNote.securebookmarks.plist
````


### How To use?
Generate the app with Xcode, you can use the Xcode-Project or do it on the command line with the main.m file:

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
