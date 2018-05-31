//
//  LocalizationString.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Teamwire. All rights reserved.
//

import Foundation

class LocalizationString {
    let key: String
    private(set) var value: String

    init(key: String, value: String) {
        self.key = key
        self.value = value
    }

    func update(value: String) {
        self.value = value
    }
}

extension LocalizationString: CustomStringConvertible {
    var description: String {
        return "\(key) = \(value)"
    }
}
