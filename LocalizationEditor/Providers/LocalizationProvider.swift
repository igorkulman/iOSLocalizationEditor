//
//  LocalizationProvider.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import CleanroomLogger
import Files
import Foundation

class LocalizationProvider {
    private let ignoredDirectories = ["Pods", "Carthage", "build", ".framework"]
    
    func getLocalizations(url: URL) -> [LocalizationGroup] {
        Log.debug?.message("Searching \(url) for Localizable.strings")

        guard let folder = try? Folder(path: url.path) else {
            return []
        }

        let localizationFiles = Dictionary(grouping: folder.makeFileSequence(recursive: true).filter { file in
            return file.name.hasSuffix(".strings") && ignoredDirectories.map({file.path.contains("\($0)/")}).filter({$0}).count == 0
        }, by: {$0.path.components(separatedBy:"/").filter({!$0.hasSuffix(".lproj")}).joined(separator:"/")})
        
        Log.debug?.message("Found \(localizationFiles) localization files")
        
        return localizationFiles.map({ (path, files) in
            let name = URL(fileURLWithPath: path).lastPathComponent
            return LocalizationGroup(name: name, localizations: files.map({ file in
                let parts = file.path.split(separator: "/")
                let lang = String(parts[parts.count - 2]).replacingOccurrences(of: ".lproj", with: "")
                return Localization(language: lang, translations: getLocalizationStrings(path: file.path), path: file.path)
            }), path: path)
        }).sorted(by: {$0.name < $1.name})
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

    func updateLocalization(localization: Localization, string: LocalizationString, with value: String) {
        guard string.value != value else {
            Log.debug?.message("Same value provided for \(string)")
            return
        }

        Log.debug?.message("Updating \(string) with \(value) in \(localization)")

        string.update(value: value)

        let data = localization.translations.map { string in
            "\"\(string.key)\" = \"\(string.value.replacingOccurrences(of: "\"", with: "\\\""))\";"
        }.reduce("") { prev, next in
            "\(prev)\n\(next)"
        }

        do {
            try data.write(toFile: localization.path, atomically: false, encoding: .utf8)
            Log.debug?.message("Localization file for \(localization) updated")
        } catch {
            Log.error?.message("Writing localization file for \(localization) failed with \(error)")
        }
    }
}
