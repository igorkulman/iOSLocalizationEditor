//
//  LocalizationProvider.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Teamwire. All rights reserved.
//

import Files
import Foundation
import CleanroomLogger

class LocalizationProvider {
    func getLocalizations(url: URL) -> [Localization] {
        Log.debug?.message("Searching \(url) for Localizable.strings")
        
        guard let folder = try? Folder(path: url.path) else {
            return []
        }

        let localizationFiles = folder.makeFileSequence(recursive: true).filter({ $0.name == "Localizable.strings" })
        
        Log.debug?.message("Found \(localizationFiles) localization files")

        return localizationFiles.map({ file in
            let parts = file.path.split(separator: "/")
            let lang = String(parts[parts.count - 2]).replacingOccurrences(of: ".lproj", with: "")
            return Localization(language: lang, translations: getLocalizationStrings(path: file.path), path: file.path)
        })
    }

    private func getLocalizationStrings(path: String) -> [LocalizationString] {
        guard let dict = NSDictionary(contentsOfFile: path) as? [String: String] else {
            Log.error?.message("Could not parse \(path) as dictionary")
            return []
        }

        var strings: [LocalizationString] = []
        for (key, value) in dict {
            let s = LocalizationString(key: key, value: value)
            strings.append(s)
        }
        
        Log.debug?.message("Found \(strings.count) keys for in \(path)")
        
        return strings.sorted(by: { (lhs, rhs) -> Bool in
            lhs.key < rhs.key
        })
    }

    func updateLocalization(localization: Localization, string: LocalizationString) {
        Log.debug?.message("Updating \(localization) with \(string)")
    }
}
