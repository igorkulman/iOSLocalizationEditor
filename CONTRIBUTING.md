# Contributing to iOSLocalizationEditor

First off, thank you for considering contributing to Localization Editor. It's people like you that make Localization Editor such a great tool.

Following these guidelines helps to communicate that you respect the time of the developers managing and developing this open source project. In return, they should reciprocate that respect in addressing your issue, assessing changes, and helping you finalize your pull requests.

There are many ways to contribute, from submitting bug reports and feature requests to writing code which can be incorporated into the project.

## Issues and feature requests

Feel free to submit issues and feature requests.

## Contributing code

All code should be contributed using a Pull request. Before opening a Pull request it is advisable to first create an issue describing the bug being fixed or the new functionality being added.

### Code style

Make sure you have [SwiftLint](https://github.com/realm/SwiftLint) installed and it does not give you any errors or warnings. SwiftLint is integrated into the build process so there is no need to invoke it manually, just build and run the app.

### Tests

Make sure all the unit tests still pass after your changes. If you add a new functionality to the localization parser or provider, please include a unit test for the new functionality.
