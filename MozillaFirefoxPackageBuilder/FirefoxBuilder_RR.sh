#!/bin/sh -x
#
# Build script for Mozilla Firefox RR (Rapid Release) for Mac
# The script includes a language switcher and various language packs to make Firefox
# multilingual, it although configures various settings to define the app behaviour,
# feel free to adapt the cfg file as you need it or add your own extensions and add-ons.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# The script was developed based on input from the following sources:
#
# Firefox.app/Contents/Resources/defaults/pref/
# https://developer.mozilla.org/en-US/docs/Mozilla/Preferences/A_brief_guide_to_Mozilla_preferences
# https://developer.mozilla.org/en-US/Firefox/Enterprise_deployment
# http://kb.mozillazine.org/Installing_extensions
# http://kb.mozillazine.org/Locking_preferences
# https://mike.kaply.com/2012/03/16/customizing-firefox-autoconfig-files/
# http://mxr.mozilla.org/mozilla-central/source/extensions/pref/autoconfig/src/nsAutoConfig.cpp
# http://web.mit.edu/~firefox/www/maintainers/autoconfig.html
# https://addons.mozilla.org/en-US/firefox/addon/deutsch-de-language-pack/versions/?page=1#version-37.0
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Initial GIT release with documentation: 2016-03-09 by Max Schlapfer
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

PKG_VENDOR="Mozilla"
PKG_PRODUCT="Firefox"
PKG_LANGUAGE="ML"
PKG_ID="ch.ethz.mac.pkg.${PKG_VENDOR}_${PKG_PRODUCT}.${PKG_LANGUAGE}"

# Download URL (Version will be filled in later)
PKG_URL="https://download.mozilla.org/?product=firefox-#VERSION#-SSL&os=osx&lang=en-US"

# fetch info about current version from website
PKG_VERSION=$(curl -s https://www.mozilla.org/en-US/firefox/new/ | xmllint --html --xpath 'string(/html/@data-latest-firefox)' - 2>/dev/null  )

# replace placeholder with correct version
PKG_URL=$(echo $PKG_URL | sed -e "s@#VERSION#@$PKG_VERSION@")

# define output name
OUTNAME="${PKG_VENDOR}_${PKG_PRODUCT}_${PKG_VERSION}_${PKG_LANGUAGE}"

# Download Firefox.dmg
curl -Lso "Firefox ${PKG_VERSION}.dmg" "$PKG_URL"

# Download language packs
LANGPACKS="de=417164 fr=417178 it=417194 rm=417234"
for lang in $LANGPACKS; do
  mylang=$(echo $lang | cut -d= -f1)
  mycode=$(echo $lang | cut -d= -f2)
  myfile="langpack-${mylang}@firefox.mozilla.org.xpi"
  DLURL="https://addons.mozilla.org/firefox/downloads/latest/${mycode}/addon-${mycode}-latest.xpi"
  [ -f "$myfile" ] || curl -Lso "$myfile" "$DLURL"
done

# Download language Switcher
curl -Lso locale_switcher-3-fx.xpi 'https://addons.mozilla.org/firefox/downloads/latest/356/addon-356-latest.xpi?src=ss'

# Check version-compat of addons. As grep may return non-zero, temporarily set bash +e
echo "# Checking version sanity"
echo "# Firefox ................................. $PKG_VERSION"
echo "# langswitcher ............................ 4.0+ (not checked, bad maxVersion)"
for lang in $LANGPACKS; do
  mylang=$(echo $lang | cut -d= -f1)
  myfile="langpack-${mylang}@firefox.mozilla.org.xpi"
  myversion=`unzip -c "$myfile" install.rdf | grep maxVersion | perl -pe 's/\s+<em:maxVersion>([^<]+).*/$1/;'`
  echo "# $myfile  .... $myversion"
  set +e
  echo $PKG_VERSION | grep -q $myversion
  if [ $? != 0 ]; then
    echo " FATAL ERROR: langpack maxVersion does not match Firefox version (${PKG_VERSION})!"
    exit 1
  fi
  set -e
done
echo "# Seems versions of addons are ok, proceeding..."

if [ ! -d root/Applications/Firefox.app ]; then
  mkdir -p root/Applications mnt
  hdiutil attach "Firefox ${PKG_VERSION}.dmg" -quiet -nobrowse -mountpoint mnt
  ditto mnt/Firefox.app root/Applications/Firefox.app
  hdiutil eject mnt -quiet
fi

mkdir -p root/Applications/Firefox.app/Contents/Resources/langpacks
cp locale_switcher-3-fx.xpi langpack-*.xpi root/Applications/Firefox.app/Contents/Resources/langpacks
cp firefox-ethz.cfg root/Applications/Firefox.app/Contents/Resources
cp autoconfig-ethz.js root/Applications/Firefox.app/Contents/Resources/defaults/pref
perl -pi -e "s@#FIREFOX_VERSION#@$PKG_VERSION@" root/Applications/Firefox.app/Contents/Resources/firefox-ethz.cfg

# build the package
echo "Creating package from root/ directory as ${OUTNAME}.pkg ..."

pkgbuild --identifier "$PKG_ID" --version "$PKG_VERSION" --root root "${OUTNAME}.pkg"

hdiutil create -volname "${OUTNAME}" -srcfolder "${OUTNAME}.pkg" -format UDRO "${OUTNAME}.dmg"

echo "PKG and DMG created successfully."

# clean up workspace
CleanerList=(root mnt *.xpi "Firefox ${PKG_VERSION}.dmg" *.pkg)
  echo "Trashing build artefacts in CWD..."
  for f in "${CleanerList[@]}"; do
    echo "  + removing artefact $f"
    rm -rf "$f"
  done
  
