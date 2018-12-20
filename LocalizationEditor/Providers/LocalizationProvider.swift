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

/**
Service for working with the strings files
 */
final class LocalizationProvider {
    /**
     List of folder that should be ignored when searching for localization files
     */
    private let ignoredDirectories: Set<String> = ["Pods", "Carthage", "build", ".framework"]

    // MARK: Actions

    /**
     Updates given localization values in given localization file. Basially regenerates the whole localization files changing the given value

     - Parameter localization: localization to update
     - Parameter key: localization string key
     - Parameter value: new value for the localization string
     */
    func updateLocalization(localization: Localization, key: String, with value: String) {
        if let existing = localization.translations.first(where: { $0.key == key }), existing.value == value {
            Log.debug?.message("Same value provided for \(existing), not updating")
            return
        }

        Log.debug?.message("Updating \(key) in \(value)")

        localization.update(key: key, value: value)

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

    /**
     Finds and constructs localiations for given directory path

     - Parameter url: diretcory URL to start the search
     - Returns: list of localization groups
     */
    func getLocalizations(url: URL) -> [LocalizationGroup] {
        Log.debug?.message("Searching \(url) for Localizable.strings")

        guard let folder = try? Folder(path: url.path) else {
            return []
        }

        let localizationFiles = Dictionary(grouping: folder.makeFileSequence(recursive: true).filter { file in
            file.name.hasSuffix(".strings") && !ignoredDirectories.contains(where: { file.path.contains($0) })
        }, by: { $0.path.components(separatedBy: "/").filter({ !$0.hasSuffix(".lproj") }).joined(separator: "/") })

        Log.debug?.message("Found \(localizationFiles.count) localization files")

        return localizationFiles.map({ path, files in
            let name = URL(fileURLWithPath: path).lastPathComponent
            return LocalizationGroup(name: name, localizations: files.map({ file in
                let parts = file.path.split(separator: "/")
                let lang = String(parts[parts.count - 2]).replacingOccurrences(of: ".lproj", with: "")
                return Localization(language: lang, translations: getLocalizationStrings(path: file.path), path: file.path)
            }), path: path)
        }).sorted(by: { $0.name < $1.name })
    }

    // MARK: Internal implementation

    /**
     Reads given strings file and constructs an array of localization strings from it

     - Parameter path: strings file path
     - Returns: array of localization strings
     */
    private func getLocalizationStrings(path: String) -> [LocalizationString] {
        guard let dict = NSDictionary(contentsOfFile: path) as? [String: String] else {
            Log.error?.message("Could not parse \(path) as dictionary")
            return []
        }

        let localizationStrings: [LocalizationString] = dict.map({ LocalizationString(key: $0.key, value: $0.value) })

        Log.debug?.message("Found \(localizationStrings.count) keys for in \(path)")

        return localizationStrings.sorted(by: { lhs, rhs -> Bool in
            lhs.key < rhs.key
        })
    }
}
