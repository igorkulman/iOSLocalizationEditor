//
//  LocalizationString.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Teamwire. All rights reserved.
//

import Foundation

struct LocalizationString {
    let key: String
    let value: String
}

extension LocalizationString: CustomStringConvertible {
    var description: String {
        return "\(key) = \(value)"
    }
}
