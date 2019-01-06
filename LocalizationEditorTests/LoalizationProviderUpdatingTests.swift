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
    
    func testUpdatingValuesInSingleLanguageWithCompleteComments() {
        let directoryUrl = createTestingDirectory(with: [TestFile(originalFileName: "LocalizableStrings-en-with-complete-messages.strings", destinationFileName: "LocalizableStrings.strings", destinationFolder: "Base.lproj")])
        let provider = LocalizationProvider()
        let groups = provider.getLocalizations(url: directoryUrl)
        
        let baseLocalization = groups[0].localizations[0]
        provider.updateLocalization(localization: baseLocalization, key: baseLocalization.translations[2].key, with: "New value line 2", message: baseLocalization.translations[2].message)
        let updated = provider.getLocalizations(url: directoryUrl)
        
        let changes: [String: [String: String]] = ["Base": [baseLocalization.translations[2].key : "New value line 2"]]
        testLocalizationsMatch(base: groups, updated: updated, changes: changes)
    }
    
    func testUpdatingValuesInSingleLanguageWithIncompleteComments() {
        let directoryUrl = createTestingDirectory(with: [TestFile(originalFileName: "LocalizableStrings-en-with-incomplete-messages.strings", destinationFileName: "LocalizableStrings.strings", destinationFolder: "Base.lproj")])
        let provider = LocalizationProvider()
        let groups = provider.getLocalizations(url: directoryUrl)
        
        let baseLocalization = groups[0].localizations[0]
        provider.updateLocalization(localization: baseLocalization, key: baseLocalization.translations[2].key, with: "New value line 2", message: baseLocalization.translations[2].message)
        let updated = provider.getLocalizations(url: directoryUrl)
        
        let changes: [String: [String: String]] = ["Base": [baseLocalization.translations[2].key : "New value line 2"]]
        testLocalizationsMatch(base: groups, updated: updated, changes: changes)
    }
    
    
    func testUpdatingMessagesInSingleLanguageWithCompleteComments() {
        let directoryUrl = createTestingDirectory(with: [TestFile(originalFileName: "LocalizableStrings-en-with-complete-messages.strings", destinationFileName: "LocalizableStrings.strings", destinationFolder: "Base.lproj")])
        let provider = LocalizationProvider()
        let groups = provider.getLocalizations(url: directoryUrl)
        
        let baseLocalization = groups[0].localizations[0]
        provider.updateLocalization(localization: baseLocalization, key: baseLocalization.translations[2].key, with: baseLocalization.translations[2].value, message: "New Message line 2")
        let updated = provider.getLocalizations(url: directoryUrl)
        
        let changes: [String: [String: String]] = ["Base": [baseLocalization.translations[2].message! : "New Message line 2"]]
        testLocalizationsMatch(base: groups, updated: updated, changes: changes, onlyMessagesChanged: true)
    }
    
    func testUpdatingMessagesInSingleLanguageWithIncompleteComments() {
        let directoryUrl = createTestingDirectory(with: [TestFile(originalFileName: "LocalizableStrings-en-with-incomplete-messages.strings", destinationFileName: "LocalizableStrings.strings", destinationFolder: "Base.lproj")])
        let provider = LocalizationProvider()
        let groups = provider.getLocalizations(url: directoryUrl)
        
        let baseLocalization = groups[0].localizations[0]
        provider.updateLocalization(localization: baseLocalization, key: baseLocalization.translations[2].key, with: baseLocalization.translations[2].value, message: "New Message line 2")
        let updated = provider.getLocalizations(url: directoryUrl)
        
        let changes: [String: [String: String]] = ["Base": [baseLocalization.translations[2].message! : "New Message line 2"]]
        testLocalizationsMatch(base: groups, updated: updated, changes: changes, onlyMessagesChanged: true)
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
        testLocalizationsMatch(base: groups, updated: updated, changes: changes, onlyMessagesChanged: true)
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

    private func testLocalizationsMatch(base:  [LocalizationGroup], updated:  [LocalizationGroup], changes: [String: [String: String]], onlyMessagesChanged: Bool = false) {
        XCTAssertEqual(base.count, updated.count)
        for i in 0..<base.count { // group
            XCTAssertEqual(base[i].localizations.count, updated[i].localizations.count)

            for j in 0..<base[i].localizations.count { // localization / language
                let baseKeys = base[i].localizations[j].translations.map({ $0.key })
                let updatedKeys = updated[i].localizations[j].translations.map({ $0.key })
                // nothing was deleted but a missing value might have been added
                XCTAssert(baseKeys.count <= updatedKeys.count)

                // The current method only counts changed keys/values, messages are not counted as change. Therefore this flag prevents test from failing whre only a message was changed. The equality of messages are checked later.
                if !onlyMessagesChanged {
                    if let changesForLanguage = changes[base[i].localizations[j].language] {
                        let existingKeys = updated[i].localizations[j].translations.filter { (string: LocalizationString) -> Bool in
                            return changesForLanguage.map({$0.key}).contains(string.key)
                        }
                        XCTAssertEqual(changesForLanguage.count, existingKeys.count)
                    }
                }

                for key in baseKeys {
                    let originalValue = base[i].localizations[j].translations.first(where: { $0.key == key })?.value
                    let updatedValue = updated[i].localizations[j].translations.first(where: { $0.key == key })?.value

                    XCTAssertFalse(originalValue == nil)
                    
                    let originalMessage = base[i].localizations[j].translations.first(where: { $0.key == key })?.message
                    let updatedMessage = updated[i].localizations[j].translations.first(where: { $0.key == key })?.message
                    XCTAssertEqual(originalMessage, updatedMessage)
                    
                    if let lang = changes[base[i].localizations[j].language], let newValue = lang[key] {
                        XCTAssertEqual(updatedValue, newValue)
                    } else {
                         XCTAssertEqual(originalValue, updatedValue)
                    }
                }
            }
        }
    }
}
