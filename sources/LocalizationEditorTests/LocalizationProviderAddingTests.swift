//
//  LocalizationProviderAddingTests.swift
//  LocalizationEditorTests
//
//  Created by Igor Kulman on 14/03/2019.
//  Copyright © 2019 Igor Kulman. All rights reserved.
//

import Foundation
import XCTest
@testable import LocalizationEditor

class LocalizationProviderAddingTests: XCTestCase {
    func testAddingValuesInSingleLanguage() {
        let directoryUrl = createTestingDirectory(with: [TestFile(originalFileName: "LocalizableStrings-en.strings", destinationFileName: "LocalizableStrings.strings", destinationFolder: "Base.lproj")])
        let provider = LocalizationProvider()
        let groups = provider.getLocalizations(url: directoryUrl)

        let baseLocalization = groups[0].localizations[0]
        let count = groups[0].localizations[0].translations.count
        _ = provider.addKeyToLocalization(localization: baseLocalization, key: "test", message: "test key")
        let updated = provider.getLocalizations(url: directoryUrl)

        XCTAssertEqual(updated.count, groups.count)
        XCTAssertEqual(groups[0].localizations.count, groups[0].localizations.count)
        XCTAssertEqual(groups[0].localizations[0].translations.count, count + 1)
        XCTAssert(groups[0].localizations[0].translations.contains(where: { $0.key ==  "test"}))
        XCTAssertEqual(updated[0].localizations.count, groups[0].localizations.count)
        XCTAssertEqual(updated[0].localizations[0].translations.count, count + 1)
        XCTAssert(updated[0].localizations[0].translations.contains(where: { $0.key ==  "test"}))
    }

    func testAddingValuesInMultipleLanguage() {
        let directoryUrl = createTestingDirectory(with: [TestFile(originalFileName: "LocalizableStrings-en.strings", destinationFileName: "LocalizableStrings.strings", destinationFolder: "Base.lproj"), TestFile(originalFileName: "LocalizableStrings-sk.strings", destinationFileName: "LocalizableStrings.strings", destinationFolder: "sk.lproj")])
        let provider = LocalizationProvider()
        let groups = provider.getLocalizations(url: directoryUrl)

        let baseLocalization = groups[0].localizations[0]
        let count = groups[0].localizations[0].translations.count
        let countOther = groups[0].localizations[1].translations.count
        _ = provider.addKeyToLocalization(localization: baseLocalization, key: "test", message: "test key")
        let updated = provider.getLocalizations(url: directoryUrl)

        XCTAssertEqual(updated.count, groups.count)
        XCTAssertEqual(groups[0].localizations.count, groups[0].localizations.count)
        XCTAssertEqual(groups[0].localizations[0].translations.count, count + 1)
        XCTAssertEqual(groups[0].localizations[1].translations.count, countOther)
        XCTAssert(groups[0].localizations[0].translations.contains(where: { $0.key ==  "test"}))
        XCTAssertEqual(updated[0].localizations.count, groups[0].localizations.count)
        XCTAssertEqual(updated[0].localizations[0].translations.count, count + 1)
        XCTAssertEqual(updated[0].localizations[1].translations.count, countOther)
        XCTAssert(updated[0].localizations[0].translations.contains(where: { $0.key ==  "test"}))
        XCTAssert(!updated[0].localizations[1].translations.contains(where: { $0.key ==  "test"}))
    }
}
