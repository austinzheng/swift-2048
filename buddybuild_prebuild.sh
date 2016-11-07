#!/usr/bin/env bash

# Example for adding a key to the Plist
echo password | sudo -S gem install slather
slather coverage -s --scheme swift-2048 $BUDDYBUILD_WORKSPACE swift-2048.xcodeproj
