//
//  LoalizationProviderUpdatingTests.swift
//  LocalizationEditorTests
//
//  Created by Igor Kulman on 16/12/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import Foundation
import XCTest
@testable import LocalizationEditor

class LoalizationProviderUpdatingTests: XCTestCase {

    func testUpdatingValuesInSingleLanguage() {
        let directoryUrl = createTestingDirectory(with: [TestFile(originalFileName: "LocalizableStrings-en.strings", destinationFileName: "LocalizableStrings.strings", destinationFolder: "Base.lproj")])
        let provider = LocalizationProvider()
        let groups = provider.getLocalizations(url: directoryUrl)

        let baseLocalization = groups[0].localizations[0]
        provider.updateLocalization(localization: baseLocalization, key: baseLocalization.translations[2].key, with: "New value line 2", message: baseLocalization.translations[2].message)
        let updated = provider.getLocalizations(url: directoryUrl)

        let changes: [String: [String: String]] = ["Base": [baseLocalization.translations[2].key : "New value line 2"]]
        testLocalizationsMatch(base: groups, updated: updated, changes: changes)
    }

    func testUpdatingValuesInMultipleLanguage() {
        let directoryUrl = createTestingDirectory(with: [TestFile(originalFileName: "LocalizableStrings-en.strings", destinationFileName: "LocalizableStrings.strings", destinationFolder: "Base.lproj"), TestFile(originalFileName: "LocalizableStrings-sk.strings", destinationFileName: "LocalizableStrings.strings", destinationFolder: "sk.lproj")])
        let provider = LocalizationProvider()
        let groups = provider.getLocalizations(url: directoryUrl)

        let baseLocalization = groups[0].localizations[0]
        provider.updateLocalization(localization: baseLocalization, key: baseLocalization.translations[2].key, with: "New value line 2", message: baseLocalization.translations[2].message)
        let updated = provider.getLocalizations(url: directoryUrl)

        let changes: [String: [String: String]] = ["Base": [baseLocalization.translations[2].key : "New value line 2"]]
        testLocalizationsMatch(base: groups, updated: updated, changes: changes)
    }

    func testUpdatingValuesInMultipleLanguagesForSecondLanguage() {
        let directoryUrl = createTestingDirectory(with: [TestFile(originalFileName: "LocalizableStrings-en.strings", destinationFileName: "LocalizableStrings.strings", destinationFolder: "Base.lproj"), TestFile(originalFileName: "LocalizableStrings-sk.strings", destinationFileName: "LocalizableStrings.strings", destinationFolder: "sk.lproj")])
        let provider = LocalizationProvider()
        let groups = provider.getLocalizations(url: directoryUrl)

        let skLocalization = groups[0].localizations[1]
        provider.updateLocalization(localization: skLocalization, key: skLocalization.translations[2].key, with: "New value line 2 SK", message: skLocalization.translations[2].message)
        let updated = provider.getLocalizations(url: directoryUrl)

        let changes: [String: [String: String]] = ["sk": [skLocalization.translations[2].key : "New value line 2 SK"]]
        testLocalizationsMatch(base: groups, updated: updated, changes: changes)
    }

    func testUpdatingMissingValue() {
        let directoryUrl = createTestingDirectory(with: [TestFile(originalFileName: "LocalizableStrings-en.strings", destinationFileName: "LocalizableStrings.strings", destinationFolder: "Base.lproj"), TestFile(originalFileName: "LocalizableStrings-sk-missing.strings", destinationFileName: "LocalizableStrings.strings", destinationFolder: "sk.lproj")])
        let provider = LocalizationProvider()
        let groups = provider.getLocalizations(url: directoryUrl)

        let skLocalization = groups[0].localizations[1]
        provider.updateLocalization(localization: skLocalization, key: "about", with: "O aplikácií", message: nil)
        let updated = provider.getLocalizations(url: directoryUrl)

        let changes: [String: [String: String]] = ["sk": ["about" : "O aplikácií"]]
        testLocalizationsMatch(base: groups, updated: updated, changes: changes)
    }

    private func testLocalizationsMatch(base:  [LocalizationGroup], updated:  [LocalizationGroup], changes: [String: [String: String]]) {
        XCTAssertEqual(base.count, updated.count)
        for i in 0..<base.count { // group
            XCTAssertEqual(base[i].localizations.count, updated[i].localizations.count)

            for j in 0..<base[i].localizations.count { // localization / language
                let baseKeys = base[i].localizations[j].translations.map({ $0.key })
                let updatedKeys = updated[i].localizations[j].translations.map({ $0.key })
                // nothing was deleted but a missing value might have been added
                XCTAssert(baseKeys.count <= updatedKeys.count)

                if let changesForLanguage = changes[base[i].localizations[j].language] {
                    let existingKeys = updated[i].localizations[j].translations.filter { (string: LocalizationString) -> Bool in
                        return changesForLanguage.map({$0.key}).contains(string.key)
                    }
                    XCTAssertEqual(changesForLanguage.count, existingKeys.count)
                }

                for key in baseKeys {
                    let originalValue = base[i].localizations[j].translations.first(where: { $0.key == key })?.value
                    let updatedValue = updated[i].localizations[j].translations.first(where: { $0.key == key })?.value

                    XCTAssertFalse(originalValue == nil)
                    
                    let originalMessage = base[i].localizations[j].translations.first(where: { $0.key == key })?.message
                    let updatedMessage = updated[i].localizations[j].translations.first(where: { $0.key == key })?.message
                    

                    if let lang = changes[base[i].localizations[j].language], let newValue = lang[key] {
                        XCTAssertEqual(updatedValue, newValue)
                        XCTAssertEqual(originalMessage, updatedMessage)
                    } else {
                         XCTAssertEqual(originalValue, updatedValue)
                    }
                }
            }
        }
    }
}
