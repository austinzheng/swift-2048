#!/usr/bin/env bash

# Install swiftlint if necessary
if ! which swiftlint >/dev/null; then
brew install swiftlint
fi

swiftlint
