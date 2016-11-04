#!/usr/bin/env bash
# GET DSYMS
echo "Generating dSYMs" 
cd $BUDDYBUILD_PRODUCT_DIR 
echo "whats in here"
ls -la
cd Release-iphoneos
echo "whats in here"
ls -la
cd swift-2048.app.dSYM
echo "whats in here"
ls -la 
zip -r mydSYMs.app.dSYM.zip * 
echo "the path here is" 
pwd 
echo "whats in here"
ls -la 


echo "Uploading to HockeyApp with command" 
echo curl -F "ipa=@$BUDDYBUILD_IPA_PATH" -F "dsym=@$BUDDYBUILD_PRODUCT_DIR/Release-iphoneos/swift-2048.app.dSYM/mydSYMs.app.dsym.zip" -H "X-HockeyAppToken: 3c2b4783db2447518590a3a7d946ab67" https://rink.hockeyapp.net/api/2/apps/9934149eb72b4e6ab617feb1d822dae0/app_versions/upload

curl -F "ipa=@$BUDDYBUILD_IPA_PATH" -F "dsym=@$BUDDYBUILD_PRODUCT_DIR/Release-iphoneos/swift-2048.app.dSYM/mydSYMs.app.dsym.zip" -H "X-HockeyAppToken: 3c2b4783db2447518590a3a7d946ab67" https://rink.hockeyapp.net/api/2/apps/9934149eb72b4e6ab617feb1d822dae0/app_versions/upload

cd $BUDDYBUILD_PRODUCT_DIR 
echo "whats in here"
ls -lR
#find . -name "*.dSYM" | xargs -I \{\} Pods/Fabric/upload-symbols -a 4e398883f5a51079e0cfd9aa715683d57ac5a235 -p ios
