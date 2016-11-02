#!/usr/bin/env bash


defaults write com.apple.iphonesimulator DebugLogging -bool YES
defaults write com.apple.CoreSimulator DebugLogging -bool YES
defaults write com.apple.dt.Xcode iOSSimulatorLogLevel 3