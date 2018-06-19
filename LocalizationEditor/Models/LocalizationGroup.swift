//
//  LocalizationGroup.swift
//  LocalizationEditor
//
//  Created by Florian Agsteiner on 19.06.18.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import Foundation

class LocalizationGroup {
    let name: String
    let path: String
    let localizations : [Localization]
    
    init(name: String, localizations: [Localization], path: String) {
        self.name = name
        self.localizations = localizations
        self.path = path
    }
}

extension LocalizationGroup: CustomStringConvertible {
    var description: String {
        return name
    }
}
