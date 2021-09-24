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
final class LocalizationString {
    let key: String
    private(set) var value: String
    private (set) var message: String?

    init(key: String, value: String, message: String?) {
        self.key = key
        self.value = value
        self.message = message
    }

    func update(newValue: String) {
        value = newValue
    }

    func updateMessage(_ message: String?) {
        self.message = message
    }
}

// MARK: Description

extension LocalizationString: CustomStringConvertible {
    var description: String {
        return "\(key) = \(value)"
    }
}

// MARK: Comparison

extension LocalizationString: Comparable {
    static func < (lhs: LocalizationString, rhs: LocalizationString) -> Bool {
        return lhs.key < rhs.key
    }

    static func == (lhs: LocalizationString, rhs: LocalizationString) -> Bool {
        return lhs.key == rhs.key && lhs.value == rhs.value
    }
}
