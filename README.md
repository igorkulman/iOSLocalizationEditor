# Localization Editor
Simple macOS editor app to help you manage iOS app localizations by allowing you to edit all the translations side by side

![Localization Editor](https://github.com/igorkulman/iOSLocalizationEditor/raw/master/editor.png)

## Motivation

Managing localization files (`Localizable.strings`) is a pain, there is no tooling for it. There is no easy way to know what strings are missing or to compare them across languages. 

## What does this tool do?

Start the Localization Editor, choose File | Open folder with localization files and point it to the folder where your localization files are stored. The tool find all the `Localizable.strings`, detects their language and displays your strings side by side as shown on the screenshot above. 

All the translations are sorted by their key (shown as first column) and you cansee and compare them quickly, you can also see missing translations in any language. 

When you change any of the translation the corresponding `Localizable.strings` gets updated.

## Requirements

- Xcode 9+
- Carthage

## Getting started

Run `carthage bootstrap` to download and build all the Carthage dependencies before opening the Xcode project for the first time.
