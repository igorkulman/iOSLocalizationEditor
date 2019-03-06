//
//  LocalizationProviderDeletingTests.swift
//  LocalizationEditorTests
//
//  Created by Igor Kulman on 06/03/2019.
//  Copyright © 2019 Igor Kulman. All rights reserved.
//

import Foundation
import XCTest
@testable import LocalizationEditor

class LocalizationProviderDeletingTests: XCTestCase {
    func testDeletingValuesInSingleLanguage() {
        let directoryUrl = createTestingDirectory(with: [TestFile(originalFileName: "LocalizableStrings-en.strings", destinationFileName: "LocalizableStrings.strings", destinationFolder: "Base.lproj")])
        let provider = LocalizationProvider()
        let groups = provider.getLocalizations(url: directoryUrl)

        let baseLocalization = groups[0].localizations[0]
        provider.deleteKeyFromLocalization(localization: baseLocalization, key: baseLocalization.translations[2].key)
        let updated = provider.getLocalizations(url: directoryUrl)

        XCTAssertEqual(updated.count, groups.count)
        XCTAssertEqual(updated[0].localizations.count, groups[0].localizations.count)
        XCTAssertEqual(updated[0].localizations[0].translations.count, groups[0].localizations[0].translations.count - 1)
        XCTAssert(!updated[0].localizations[0].translations.contains(where: { $0.key ==  baseLocalization.translations[2].key}))
    }

    func testDeletingValuesInMultipleLanguage() {
        let directoryUrl = createTestingDirectory(with: [TestFile(originalFileName: "LocalizableStrings-en.strings", destinationFileName: "LocalizableStrings.strings", destinationFolder: "Base.lproj"), TestFile(originalFileName: "LocalizableStrings-sk.strings", destinationFileName: "LocalizableStrings.strings", destinationFolder: "sk.lproj")])
        let provider = LocalizationProvider()
        let groups = provider.getLocalizations(url: directoryUrl)

        let baseLocalization = groups[0].localizations[0]
         provider.deleteKeyFromLocalization(localization: baseLocalization, key: baseLocalization.translations[2].key)
        let updated = provider.getLocalizations(url: directoryUrl)

        XCTAssertEqual(updated.count, groups.count)
        XCTAssertEqual(updated[0].localizations.count, groups[0].localizations.count)
        XCTAssertEqual(updated[0].localizations[0].translations.count, groups[0].localizations[0].translations.count - 1)
        XCTAssertEqual(updated[0].localizations[1].translations.count, groups[0].localizations[1].translations.count)
        XCTAssert(!updated[0].localizations[0].translations.contains(where: { $0.key ==  baseLocalization.translations[2].key}))
    }
}
