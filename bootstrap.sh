#!/bin/bash

# dependencies
brew update
brew ls --versions carthage && brew upgrade carthage || brew install carthage
brew ls --versions swiftlint && brew upgrade swiftlint || brew install swiftlint

# Carthage bootstrap
carthage bootstrap --platform macOS --no-use-binaries