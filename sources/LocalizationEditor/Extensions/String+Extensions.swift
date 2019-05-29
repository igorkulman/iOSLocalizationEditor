//
//  String+Extensions.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 05/02/2019.
//  Copyright © 2019 Igor Kulman. All rights reserved.
//

import Foundation

extension String {
    var normalized: String {
        return folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }

    var capitalizedFirstLetter: String {
        return prefix(1).uppercased() + self.lowercased().dropFirst()
    }

    var unescaped: String {
        let entities = [
            "\\n": "\n",
            "\\t": "\t",
            "\\r": "\r",
            "\\\"": "\"",
            "\\\'": "\'",
            "\\\\": "\\"
        ]
        var current = self
        for (key, value) in entities {
            current = current.replacingOccurrences(of: key, with: value)
        }
        return current
    }

    var escaped: String {
        return self.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n")
    }
}
