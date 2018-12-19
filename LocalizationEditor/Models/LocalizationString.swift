//
//  LocalizationString.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import Foundation

/**
 Class representing single localization string in form of key: "value"; as found in strings files
 */
class LocalizationString {
    let key: String
    let value: String

    init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

// MARK: Description

extension LocalizationString: CustomStringConvertible {
    var description: String {
        return "\(key) = \(value)"
    }
}
