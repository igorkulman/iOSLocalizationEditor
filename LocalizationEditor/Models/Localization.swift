//
//  Localization.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import Foundation

/**
Complete localization for a single language. Represents a single strings file for a single language
 */
class Localization {
    let language: String
    private(set) var translations: [LocalizationString]
    let path: String

    init(language: String, translations: [LocalizationString], path: String) {
        self.language = language
        self.translations = translations
        self.path = path
    }

    func update(key: String, value: String) {
        if let existing = translations.first(where: { $0.key == key }) {
            existing.update(newValue: value)
            return
        }

        let newTranslation = LocalizationString(key: key, value: value)
        translations = (translations + [newTranslation]).sorted()
    }
}

// MARK: Description

extension Localization: CustomStringConvertible {
    var description: String {
        return language.uppercased()
    }
}

extension Localization: Equatable {
    static func == (lhs: Localization, rhs: Localization) -> Bool {
        return lhs.language == rhs.language && lhs.translations == rhs.translations && lhs.path == rhs.path
    }
}
