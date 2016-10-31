#!/usr/bin/env bash
# GET DSYMS
echo "Generating dSYMs" 
cd $BUDDYBUILD_PRODUCT_DIR 
ls -la 
cd Release-iphoneos
ls -la
cd dSYMs 
ls -la 
zip -r mydSYMs.app.dSYM.zip * 
pwd 
ls -la

echo "Uploading to HockeyApp" 
curl \ 
-F "ipa=@$BUDDYBUILD_IPA_PATH" \ 
#-F "dsym=@$BUDDYBUILD_PRODUCT_DIR/swift-2048.app.dSYM/dSYMs/mydSYMs.app.dSYM.zip" \ 
-H "X-HockeyAppToken: 3c2b4783db2447518590a3a7d946ab67" \ https://rink.hockeyapp.net/api/2/apps/9934149eb72b4e6ab617feb1d822dae0/app_versions/upload
