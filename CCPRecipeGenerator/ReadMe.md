# Automating the generation of Adobe CC package override files for AutoPkg
  
This script helps you customize the build process for your organisation.
Then generates an override file for each Adobe product and builds all packages.

This script is based on the AutoPkg project and the CCP-Recipes from "Mosen" [https://github.com/mosen/ccp-recipes](https://github.com/mosen/ccp-recipes). The master recipe file and the Adobe list feed script used for this project have been taken and adapted from Mosen's project.

This workflow has been tested on macOS Sierra 10.12.3.

### Prerequisites

To start on a newly installed (build) machine, install the following packages before using the script:

- __AutoPkg__  
Install and configure the AutoPkg environment as you need it. [http://autopkg.github.io/autopkg](http://autopkg.github.io/autopkg)  
  - If you want to move some folders to other destinations, please define at least the AutoPkg Cache and Overrides folders:  
    `defaults write com.github.autopkg CACHE_DIR /path/to/cache/dir`  
    `defaults write com.github.autopkg RECIPE_OVERRIDE_DIRS /path/to/override/dir`
    
- __Creative Cloud Packager from Adobe__  
Get you CCP installer from the Adobe Dashboard or your responsible Adobe contact at your organisation.

- __Xcode Command Line Tools__  
Make sure the Xcode Command Line Tools are installed.

- __Free disk space__  
Make sure you have enough free space available on the build machine, as a full CC package set is about 35 GB per language.

### Configuration	
- Edit the __Custom_CreativeCloudApp.pkg.recipe__  
_Important_: Do not change the XX-tags! They will be filled automatically by the script according to your definitions.

    Possible configurations (default settings in bold):
    - __Identifier__  
Enter your organisations name. (com.company.XY)
    - __INCLUDE_UPDATES__  
[__true__/false] :set to true if you want to include all updates with the base package.
    - __RUM_ENABLED__  
[true/__false__] : Include RUM in the package or not.
    - __UPDATES_ENABLED__  
[true/__false__] : Define if the end user should be able to update the app.
    - __APPS_PANEL_ENABLED__  
[true/__false__] : Show the app panel to the end user.
    - __ADMIN_PRIVILEGES_ENABLED__  
[true/__false__] : Enable this to allow the CC Desktop application to run with admin rights, to let the end user install/update CC apps.
    - __DEPLOYMENT_POOL__  
If your organisation is using "Deployment Pools", please enter it here.
    - __MATCH_OS_LANGUAGE__  
[true/__false__] : packages are built based on the active language of the logged in user. As we define the languags later, this is set to false.

- Edit the script __CCPReceiptGenerator.sh__  
    - __Organisation__: The name of your Organisation based on the Adobe Dashboard naming  
    - __SerialNumber__: The serialnumber provided from Adobe, remove the dashes  
    - __LicenseType__: Is either `enterprise` or `team`  
    - __Identifier__: Set the identifier based on your needs (com.company.XY)  
    - __Language__: Add the languages of the install packages as an array: (en_US de_DE)  
    - __LanguageShort__: This short string is only used for naming the final packages, should be in the same order as the language array: (EN DE)


### Have the work done
- Run the Creative Cloud Packager one time manually, log in and configure the app as you need it in your organisation.

- Run the generator script `ReceiptGenerator.sh`  
The recipes are saved in the AutoPkg overrides folder. At the same time
a file with all recipes is generated and can be used to run all recipes at once.  
After the overrides have successfully been generated, you can start the build process. If you don't need all packages built, then edit 'AutoPKGRunSource.txt' and delete all packages you don^t want to build.

- Run autopkg to build all packages based on the generated overrides  
`autopkg run --recipe-list ./AutoPKGRunFile.txt` 

- Or run autopkg manually for a single override:  
`autopkg run "PackageName"`


### Known issues
- The following packages failed during build and need to be investigated further:
  - Adobe_Edge_Code_CC_(Preview)_1.0_ML.pkg.recipe
  - Adobe_Experience_Design_CC_(Beta)_0.6.16_ML.pkg.recipe
  - Adobe_Application_Manager_6.2.10_ML.pkg.recipe
  - Adobe_Edge_Inspect_CC_1.5_ML.pkg.recipe
  - Adobe_Edge_Reflow_CC_(Preview)_2.0_ML.pkg.recipe
  - Adobe_Edge_Animate_CC_(2015)_6.0_ML.pkg.recipe
  - Adobe_Touch_App_Plugins_1.0_ML.pkg.recipe
