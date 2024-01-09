#!/bin/bash

set -e

cd "$(dirname "$0")"

echo "[*] Picasso Build Script"
#chmod a+rwx ./bin/swiftshield

#if [ ! -d "Picasso_obfuscated" ]; then
#    mkdir Picasso_obfuscated
#
#    cp -r TSRootHelper Picasso_obfuscated
#    cp -r Picasso Picasso_obfuscated
#    cp -r Picasso.xcodeproj Picasso_obfuscated
#
#    # COPIED_FILES=true
#fi

#cd Picasso_obfuscated

rm -rf build
# rm -rf .git
# rm -rf bin

rm -rf Picasso_obfuscated*
# try removing *.tipa, but don't fail if there are no files
if ls *.tipa 1> /dev/null 2>&1; then
    rm -rf *.tipa
fi

WORKING_LOCATION="$(pwd)"
APPLICATION_NAME=Picasso

if [ ! -d "build" ]; then
    mkdir build
fi

cd build

# echo $WORKING_LOCATION/$APPLICATION_NAME
echo $WORKING_LOCATION/$APPLICATION_NAME.xcodeproj

#echo "[*] Obfuscating..."
#chmod a+rwx ./../../bin/swiftshield-ultra
#if [  -d "~/Library/Developer/Xcode/DerivedData/Picasso*" ]; then
echo "[*] Permissions set"
#chmod -R 777 ~/Library/Developer/Xcode/DerivedData/Picasso* # such a terrible code :skull:
#fi

echo "[*] Building..."
if [[ $* == *--debug* ]]; then
xcodebuild -project "$WORKING_LOCATION/$APPLICATION_NAME.xcodeproj" \
    -scheme "$APPLICATION_NAME" \
    -configuration Debug \
    -derivedDataPath "$WORKING_LOCATION/build/DerivedDataApp" \
    -destination 'generic/platform=iOS' \
    clean build \
    CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGN_ENTITLEMENTS="" CODE_SIGNING_ALLOWED="NO"

DD_APP_PATH="$WORKING_LOCATION/build/DerivedDataApp/Build/Products/Debug-iphoneos/$APPLICATION_NAME.app"
TARGET_APP="$WORKING_LOCATION/build/$APPLICATION_NAME.app"
cp -r "$DD_APP_PATH" "$TARGET_APP"
else
xcodebuild -project "$WORKING_LOCATION/$APPLICATION_NAME.xcodeproj" \
    -scheme "$APPLICATION_NAME" \
    -configuration Release \
    -derivedDataPath "$WORKING_LOCATION/build/DerivedDataApp" \
    -destination 'generic/platform=iOS' \
    clean build \
    CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGN_ENTITLEMENTS="" CODE_SIGNING_ALLOWED="NO"

DD_APP_PATH="$WORKING_LOCATION/build/DerivedDataApp/Build/Products/Release-iphoneos/$APPLICATION_NAME.app"
TARGET_APP="$WORKING_LOCATION/build/$APPLICATION_NAME.app"
cp -r "$DD_APP_PATH" "$TARGET_APP"
fi

echo "[*] Stripping signature..."
codesign --remove "$TARGET_APP"
if [ -e "$TARGET_APP/_CodeSignature" ]; then
    rm -rf "$TARGET_APP/_CodeSignature"
fi
if [ -e "$TARGET_APP/embedded.mobileprovision" ]; then
    rm -rf "$TARGET_APP/embedded.mobileprovision"
fi

# TODO: TS root helper

echo "[*] Adding entitlements..."
chmod a+x "$WORKING_LOCATION/bin/ldid"
"$WORKING_LOCATION/bin/ldid" -S"$WORKING_LOCATION/Picasso/PicassoTroll.entitlements" $TARGET_APP


echo "[*] Building RootHelper..."
if [[ $* == *--debug* ]]; then
cd $WORKING_LOCATION/TSRootHelper
if ! type "gmake" > /dev/null; then
    echo "[!] gmake not found, using macOS bundled make instead"
    make clean
    make
else
    gmake clean
    gmake -j"$(nproc --ignore 1)"
fi
cp $WORKING_LOCATION/TSRootHelper/.theos/obj/debug/PicassoRootHelper $WORKING_LOCATION/build/Picasso.app/picassoroothelper
cd -

else
cd $WORKING_LOCATION/TSRootHelper
if ! type "gmake" > /dev/null; then
    echo "[!] gmake not found, using macOS bundled make instead"
    make clean
    make FINALPACKAGE=1
else
    gmake clean
    gmake -j"$(nproc --ignore 1)" FINALPACKAGE=1
fi
cp $WORKING_LOCATION/TSRootHelper/.theos/obj/PicassoRootHelper $WORKING_LOCATION/build/Picasso.app/picassoroothelper
cd -
fi

echo "[*] Packaging..."
mkdir Payload
cp -r Picasso.app Payload/Picasso.app
#strip Payload/Picasso.app/Picasso
zip -vr OpenPicasso.ipa Payload

echo "[*] All done, cleaning up..."
#rm -rf Picasso.app
rm -rf Payload

cd ..
if [[ $* == *--debug* ]]; then
mv "$WORKING_LOCATION/build/OpenPicasso.ipa" ./OpenPicasso.debug.ipa
cp "$WORKING_LOCATION/OpenPicasso.debug.ipa" ./OpenPicasso.debug.tipa
else
mv "$WORKING_LOCATION/build/OpenPicasso.ipa" .
cp "$WORKING_LOCATION/OpenPicasso.ipa" ./OpenPicasso.tipa
fi
rm -rf "$WORKING_LOCATION/build/"

