# Localization Editor

[![Travis CI](https://api.travis-ci.com/igorkulman/iOSLocalizationEditor.svg?branch=master)](https://travis-ci.com/igorkulman/iOSLocalizationEditor)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Platforms](https://img.shields.io/badge/platform-macOS-lightgrey.svg)
[![Swift Version](https://img.shields.io/badge/Swift-4.2-F16D39.svg?style=flat)](https://developer.apple.com/swift)
[![Twitter](https://img.shields.io/badge/twitter-@igorkulman-blue.svg)](http://twitter.com/igorkulman)

Simple macOS editor app to help you manage iOS app localizations by allowing you to edit all the translations side by side, highlighting missing translations

![Localization Editor](https://github.com/igorkulman/iOSLocalizationEditor/raw/master/screenshots/editor.png)

## Motivation

Managing localization files (`Localizable.strings`) is a pain, there is no tooling for it. There is no easy way to know what strings are missing or to compare them across languages. 

## What does this tool do?

Start the Localization Editor, choose File | Open folder with localization files and point it to the folder where your localization files are stored. The tool finds all the `Localizable.strings`, detects their language and displays your strings side by side as shown on the screenshot above. You can point it to the root of your project but it will take longer to process. 

All the translations are sorted by their key (shown as first column) and you can see and compare them quickly, you can also see missing translations in any language. 

When you change any of the translations the corresponding `Localizable.strings` gets updated.

## Running the app

To download and run the app

- Go to [Releases](https://github.com/igorkulman/iOSLocalizationEditor/releases) and download the built app archive **LocalizationEditor.app.zip** from the latest release
- Unzip **LocalizationEditor.app.zip**
- Right click on the extracted **LocalizationEditor.app** and choose Open (just a double-clicking will show a warning because the app is only signed with a development certificate)

## Contributing

All contributions are welcomed. Please read [CONTRIBUTING](CONTRIBUTING.md) for more details.

## Author

- **Igor Kulman** - *Initial work* - igor@kulman.sk

See also the list of [contributors](https://github.com/igorkulman/iOSLocalizationEditor/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
