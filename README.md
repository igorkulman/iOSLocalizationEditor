  <p align="center">
  <img src="https://github.com/igorkulman/iOSLocalizationEditor/raw/master/sources/LocalizationEditor/Assets.xcassets/AppIcon.appiconset/icon_128%401x.png">
 </p>

<h1 align="center"><a id="user-content-localization-editor" class="anchor" aria-hidden="true" href="#localization-editor"><svg class="octicon octicon-link" viewBox="0 0 16 16" version="1.1" width="16" height="16" aria-hidden="true"><path fill-rule="evenodd" d="M7.775 3.275a.75.75 0 001.06 1.06l1.25-1.25a2 2 0 112.83 2.83l-2.5 2.5a2 2 0 01-2.83 0 .75.75 0 00-1.06 1.06 3.5 3.5 0 004.95 0l2.5-2.5a3.5 3.5 0 00-4.95-4.95l-1.25 1.25zm-4.69 9.64a2 2 0 010-2.83l2.5-2.5a2 2 0 012.83 0 .75.75 0 001.06-1.06 3.5 3.5 0 00-4.95 0l-2.5 2.5a3.5 3.5 0 004.95 4.95l1.25-1.25a.75.75 0 00-1.06-1.06l-1.25 1.25a2 2 0 01-2.83 0z"></path></svg></a>Localization Editor</h1>

<p align="center">
   <a href="https://opensource.org/licenses/MIT">
        <img src="https://camo.githubusercontent.com/78f47a09877ba9d28da1887a93e5c3bc2efb309c1e910eb21135becd2998238a/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f4c6963656e73652d4d49542d79656c6c6f772e737667" alt="License: MIT" />
    </a>
   <a href="https://camo.githubusercontent.com/e948575bb276fa2ffac99e1491d13e1ad8e28d7cc5e17153d3ea5bfa8b9784a6/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f706c6174666f726d2d6d61634f532d6c69676874677265792e737667">
        <img src="https://camo.githubusercontent.com/e948575bb276fa2ffac99e1491d13e1ad8e28d7cc5e17153d3ea5bfa8b9784a6/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f706c6174666f726d2d6d61634f532d6c69676874677265792e737667" alt="Platforms" />
    </a>
    <a href="https://developer.apple.com/swift">
        <img src="https://img.shields.io/badge/Swift-5.2-F16D39.svg?style=flat" alt="Swift Version" />
    </a>
    <a href="https://twitter.com/igorkulman">
        <img src="https://img.shields.io/badge/twitter-@igorkulman-blue.svg" alt="Twitter: @igorkulman" />
    </a>
  <a href="https://www.buymeacoffee.com/igorkulman" target="_blank"><img height="22" src="https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png" alt="Buy Me A Coffee"></a>
</p>

Simple macOS editor app to help you manage iOS app localizations by allowing you to edit all the translations side by side, highlighting missing translations

![Localization Editor](https://github.com/igorkulman/iOSLocalizationEditor/raw/master/screenshots/editor.png)

## Motivation

Managing localization files (`Localizable.strings`) is a pain, there is no tooling for it. There is no easy way to know what strings are missing or to compare them across languages. 

## What does this tool do?

Start the Localization Editor, choose File | Open folder with localization files and point it to the folder where your localization files are stored. The tool finds all the `Localizable.strings`, detects their language and displays your strings side by side as shown on the screenshot above. You can point it to the root of your project but it will take longer to process. 

All the translations are sorted by their key (shown as first column) and you can see and compare them quickly, you can also see missing translations in any language. 

When you change any of the translations the corresponding `Localizable.strings` gets updated.

## Installation

### Homebrew

```bash
brew install --cask localizationeditor
```

### Manual

To download and run the app

- Go to [Releases](https://github.com/igorkulman/iOSLocalizationEditor/releases) and download the built app archive **LocalizationEditor.app.zip** from the latest release
- Unzip **LocalizationEditor.app.zip**
- Right click on the extracted **LocalizationEditor.app** and choose Open (just a double-clicking will show a warning because the app is only signed with a development certificate)

## Support the project

<a href="https://www.buymeacoffee.com/igorkulman" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png" alt="Buy Me A Coffee" style="height: 41px !important;width: 174px !important;box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;-webkit-box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;" ></a>

## Contributing

All contributions are welcomed, including bug reports and pull requests with new features. Please read [CONTRIBUTING](CONTRIBUTING.md) for more details.

### Localizing the app

The app is currently localized into English and Chinese. If you want to add localization for your language, just translate the [Localizable.strings](https://github.com/igorkulman/iOSLocalizationEditor/blob/master/sources/LocalizationEditor/Resources/en.lproj/Localizable.strings) files. You can use this app to do it!

## Author

- **Igor Kulman** - *Initial work* - igor@kulman.sk

See also the list of [contributors](https://github.com/igorkulman/iOSLocalizationEditor/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Icon

App icon created by [@sergeykushner](https://github.com/sergeykushner)
