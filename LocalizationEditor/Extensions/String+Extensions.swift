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
}
