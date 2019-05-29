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
        let entities = ["\0", "\t", "\n", "\r", "\"", "\'", "\\"]
        var current = self
        for entity in entities {
            let descriptionCharacters = entity.debugDescription.dropFirst().dropLast()
            let description = String(descriptionCharacters)
            current = current.replacingOccurrences(of: description, with: entity)
        }
        return current
    }

    var escaped: String {
        return self.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\\n")
    }
}
