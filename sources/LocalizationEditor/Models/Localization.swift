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
final class Localization {
    let language: String
    private(set) var translations: [LocalizationString]
    let path: String

    init(language: String, translations: [LocalizationString], path: String) {
        self.language = language
        self.translations = translations
        self.path = path
    }

    func update(key: String, value: String, message: String?) {
        if let object = translations.first(where: { string in
            string.message != nil && string.message!.contains("\n ")
        }), let index = translations.firstIndex(of: object) {
            let setObject = LocalizationString(key: object.key, value: object.value, message: "/*[Header]\(object.message!.replacingOccurrences(of: "/*", with: "").replacingOccurrences(of: "*/", with: ""))*/")
            translations.insert(setObject, at: 0)
            translations.remove(at: index + 1)
        }
        if let existing = translations.first(where: { $0.key == key }) {
            existing.update(newValue: value)
            return
        }
        let newTranslation = LocalizationString(key: key, value: value, message: message)
        translations.append(newTranslation)
    }

    func add(key: String, message: String?) -> LocalizationString {
        let newTranslation = LocalizationString(key: key, value: "", message: message)
        translations.append(newTranslation)
        return newTranslation
    }

    func remove(key: String) {
        translations = translations.filter({ $0.key != key })
    }
}

// MARK: Description

extension Localization: CustomStringConvertible {
    var description: String {
        return language.uppercased()
    }
}

// MARK: Equality

extension Localization: Equatable {
    static func == (lhs: Localization, rhs: Localization) -> Bool {
        return lhs.language == rhs.language && lhs.translations == rhs.translations && lhs.path == rhs.path
    }
}

// MARK: Debug description

extension Localization: CustomDebugStringConvertible {
    var debugDescription: String {
        return "\(language.uppercased()): \(translations.count) translations (\(path))"
    }
}
