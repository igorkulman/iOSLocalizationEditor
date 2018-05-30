//
//  Localization.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Teamwire. All rights reserved.
//

import Foundation

struct Localization {
    let language: String
    let translations: [LocalizationString]
    let path: String
}

extension Localization: CustomStringConvertible {
    var description: String {
        return language.uppercased()
    }
}
