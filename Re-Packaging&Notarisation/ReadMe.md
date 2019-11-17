# Notarisation of re-packaged 3rd party Apps

## __DISCLAIMER__  
__This procedure might imply some legal problems, as you resign a third party packages with 
your organisations developer certificate. Please make sure to have the vendor agree on that procedure.__

__Do only use these packages for distribution inside your organisation.__  

## Intro
This documentation shows the procedure to sign and notarise packages that needed 
to be altered to add configurations, license code etc. to the original package.

These packages need a proper signing and (new) notarisation if they are distributed 
outside an MDM solution like Jamf Pro, FileWave etc..

A problem when notarising re-packaged apps is, that the package signed with your orgs 
certificate is different from the signature of the package(s) in your distribution.  

To prevent the notarisation step from failing we need to edit/adapt the package 
and bring our signature inside the package. 

This documentation was tested under macOS Catalina v10.15.1 and will hopefully be 
available in future updates.

I'd like to thank everybody in the MacAdmins community who worked with me to find this 
solution and make life easier for a lot of us!


## Prerequisites:
- A valid Apple Developer ID to sign packages  
  - If your account has 2FA activated, make an app sepcific password and use this for the notarisation steps 
    [https://support.apple.com/en-us/HT204397](https://support.apple.com/en-us/HT204397)
  - Generate a Developer ID Installer to sign your package(s) and store in your local keychain
-	Get the original package from the vendor/reseller etc.  
-	Get the company specific configurations, license codes etc. to include in the package  
-	Prepare the package as you normaly do, then re-package and continue with the next steps
-	Put your yet unsigned package in the working directory and change into this directory:    
	```
	cd "/Users/Shared/Notarise/"
	```
-	Our unsigned example package is called "Sample-1.0.unsigned.pkg"


## Packagage Signing Inception 
-	Expand the unsigned package  
	```
	pkgutil --expand Sample-1.0.unsigned.pkg Sample-1.0
	```

-	Change to the folder containing the original Sample installer package and your installer scripts, add-ons etc. (in our example this is the scripts folder inside the package):    
	```
	cd ./Sample-1.0/Scripts
	```
	
-	Check the signature of the package  
	It should be signed by the original vendor:  
	```
	spctl -a -vvv -t install original.pkg
	```

__Attention__:
If running the following signing commands over an SSH session, you need to unlock the keychain first (if run locally skip this step):  
```
security unlock-keychain ~/Library/Keychains/login.keychain
```

-	Move the original package out of the way  
	```
	mv original.pkg original.pkg.VendorSigned
	```
    
-	Resign with your Developer Certificate  
	```
	productsign --sign 'Developer ID Installer: YourOrg (123456789A)' original.pkg.VendorSigned original.pkg
	```

-	Remove vendor signed package  
	```
	rm original.pkg.VendorSigned
	```
    
-	Check Signature again  
	It should now show YourOrg as the signer:  
	```
	spctl -a -vvv -t install original.pkg
	```
	
-	Change back to folder containing the initial package:  
	```
	cd "/Users/Shared/Notarise/"
	```

-	Make the installer package  
	```	
	pkgutil --flatten Sample-1.0 Sample-1.0.unsigned.pkg
	```
	
-	Sign package with your Developer Certificate  
	```
	productsign --sign 'Developer ID Installer: YourOrg (123456789A)' Sample-1.0.unsigned.pkg Sample-1.0.pkg
	```
    
-	Verify Signature  
	It should show YourOrg as the signer:  
	```	
	spctl -a -vvv -t install Sample-1.0.pkg
	```
	
##	Notarise the signed package
-	Zip the signed package  
	```
	zip Sample-1.0.pkg.zip Sample-1.0.pkg
	```

-	Send zip file to Apple for Notarisation  
	__Attention__  
	-   Use your Developer ID from the Developer Portal and the App specific password!  
	-   Take note of the `RequestUUID` for later use.
	```
	xcrun altool --notarize-app --primary-bundle-id "ch.yourorg.sample" --username developer@yourorg.ch --file Sample-1.0.pkg.zip 
	
	  No errors uploading 'Sample-1.0.pkg.zip'.
	  RequestUUID = 1234ab12-4321-1cc2-a6b7-8d76
	```  
	__Note__  
	This process can take less than a minute to up to a few hours depending on the load on Apples servers.  
	After the process has finished Apple will send you an email with the notarisation result(s), alternatively you could check the status in the command line:
	
	-	Check Notarisation Status  
		```
		xcrun altool --notarization-history 0 -u developer@yourorg.ch
		
		  Notarization History - page 0
		
		  Date                      RequestUUID                  Status      Status Code Status Message   
		  ------------------------- ---------------------------- ----------- ----------- ---------------- 
		  2019-11-12 12:26:59 +0000 1234ab12-4321-1cc2-a6b7-8d76 success     0           Package Approved 
		
		  Next page value: 156399000
		```  
		"Status" might contain various values, during the notarisation it shows "in progress".  
		The process has finished when the status shows "success".
	
-	Get Notarisation Info  
	```
	xcrun altool --notarization-info 1234ab12-4321-1cc2-a6b7-8d76 -u developer@yourorg.ch
	
  	No errors getting notarization info.
  	
  	          Date: 2019-11-12 12:26:59 +0000
  	          Hash: ...
  	    LogFileURL: https://osxapps-ssl.itunes.apple.com/itunes-assets/...
  	   RequestUUID: 1234ab12-4321-1cc2-a6b7-8d76
  	        Status: success
  	   Status Code: 0
  	Status Message: Package Approved
	```
	Look for the "Package approved" status message, if there is an error, check the LogFileURL for more details.
    
# Staple the notarisation ticket to your package
This step is not needed but recommended  

- Staple the package
  ```	
  xcrun stapler staple Sample-1.0.pkg
    Processing: /Users/Shared/Notarise/Sample-1.0.pkg
    The staple and validate action worked!
  ```

-   Check if an application, DMG or package is notarised:
    ```
    stapler validate Sample-1.0.pkg
      Processing: /Users/Shared/Notarise/Sample-1.0.pkg
      The validate action worked!
    ```


ms, 2019-11-12
