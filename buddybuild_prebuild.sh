#!/usr/bin/env bash

# Example for adding a key to the Plist
/usr/libexec/PlistBuddy -c "Add APP_BRANCH String $BUDDYBUILD_BRANCH" "swift-2048/Info.plist"
