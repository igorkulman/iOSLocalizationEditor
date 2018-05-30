//
//  LocalizationProvider.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Teamwire. All rights reserved.
//

import Foundation
import Files

class LocalizationProvider {
    func getLocalizations(url: URL) -> [Localization] {
        guard let folder = try? Folder(path: url.path) else {
            return []
        }

        let localizationFiles = folder.makeFileSequence(recursive: true).filter({ $0.name == "Localizable.strings" })

        return localizationFiles.map({ file in
            let parts = file.path.split(separator: "/")
            let lang = String(parts[parts.count - 2]).replacingOccurrences(of: ".lproj", with: "")
            return Localization(language: lang, translations: getLocalizationStrings(path: file.path))
        })
    }

    private func getLocalizationStrings(path: String) -> [LocalizationString] {
        guard let dict = NSDictionary(contentsOfFile: path) as? [String: String] else {
            return []
        }

        var strings: [LocalizationString] = []
        for (key, value) in dict {
            let s = LocalizationString(key: key, value: value)
            strings.append(s)
        }
        return strings.sorted(by: { (lhs, rhs) -> Bool in
            lhs.key < rhs.key
        })
    }
}
