//
//  Localization.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Teamwire. All rights reserved.
//

import Foundation

class Localization {
    let language: String
    let translations: [LocalizationString]
    let path: String

    init(language: String, translations: [LocalizationString], path: String) {
        self.language = language
        self.translations = translations
        self.path = path
    }
}

extension Localization: CustomStringConvertible {
    var description: String {
        return language.uppercased()
    }
}
