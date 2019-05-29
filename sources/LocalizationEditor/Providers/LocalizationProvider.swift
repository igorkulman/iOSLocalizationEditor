//
//  LocalizationProvider.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import Foundation
import os

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
    func updateLocalization(localization: Localization, key: String, with value: String, message: String?) {
        if let existing = localization.translations.first(where: { $0.key == key }), existing.value == value, existing.message == message {
            os_log("Same value provided for %@, not updating", type: OSLogType.debug, existing.description)
            return
        }

        os_log("Updating %@ in %@ with Message: %@)", type: OSLogType.debug, key, value, message ?? "No Message.")

        localization.update(key: key, value: value, message: message)

        writeToFile(localization: localization)
    }

    /**
     Writes given translations to a file at given path

     - Parameter translatins: trabslations to write
     - Parameter path: file path
     */
    private func writeToFile(localization: Localization) {
        let data = localization.translations.map { string -> String in
            let stringForMessage: String
            if let newMessage = string.message {
                stringForMessage = "/* \(newMessage) */"
            } else {
                stringForMessage = ""
            }

            return """
            \(stringForMessage)
            \"\(string.key)\" = \"\(string.value.escaped)\";\n
            """
        }.reduce("") { prev, next in
            "\(prev)\n\(next)"
        }

        do {
            try data.write(toFile: localization.path, atomically: false, encoding: .utf8)
            os_log("Localization file for %@ updated", type: OSLogType.debug, localization.path)
        } catch {
            os_log("Writing localization file for %@ failed with %@", type: OSLogType.error, localization.path, error.localizedDescription)
        }
    }

    /**
     Deletes key from given localization

     - Parameter localization: localization to update
     - Parameter key: key to delete
     */
    func deleteKeyFromLocalization(localization: Localization, key: String) {
        localization.remove(key: key)
        writeToFile(localization: localization)
    }

    /**
     Adds new key with a message to given localization

     - Parameter localization: localization to add the data to
     - Parameter key: new key to add
     - Parameter message: message for the key

     - Returns: new localization string
     */
    func addKeyToLocalization(localization: Localization, key: String, message: String?) -> LocalizationString {
        let newTranslation = localization.add(key: key, message: message)
        writeToFile(localization: localization)
        return newTranslation
    }

    /**
     Finds and constructs localiations for given directory path

     - Parameter url: directory URL to start the search
     - Returns: list of localization groups
     */
    func getLocalizations(url: URL) -> [LocalizationGroup] {
        os_log("Searching %@ for Localizable.strings", type: OSLogType.debug, url.description)

        let localizationFiles = Dictionary(grouping: FileManager.default.getAllFilesRecursively(url: url).filter { file in
            file.pathExtension == "strings" && !ignoredDirectories.contains(where: { file.path.contains($0) })
        }, by: { $0.path.components(separatedBy: "/").filter({ !$0.hasSuffix(".lproj") }).joined(separator: "/") })

        os_log("Found %d localization files", type: OSLogType.info, localizationFiles.count)

        return localizationFiles.map({ path, files in
            let name = URL(fileURLWithPath: path).lastPathComponent
            return LocalizationGroup(name: name, localizations: files.map({ file in
                let parts = file.path.split(separator: "/")
                let lang = String(parts[parts.count - 2]).replacingOccurrences(of: ".lproj", with: "")
                return Localization(language: lang, translations: getLocalizationStrings(path: file.path), path: file.path)
            }).sorted(by: { $0.language < $1.language }), path: path)
        }).sorted()
    }

    // MARK: Internal implementation

    /**
     Reads given strings file and constructs an array of localization strings from it

     - Parameter path: strings file path
     - Returns: array of localization strings
     */
    private func getLocalizationStrings(path: String) -> [LocalizationString] {
        do {
            let contentOfFileAsString = try String(contentsOfFile: path)
            let parser = Parser(input: contentOfFileAsString)
            let localizationStrings = try parser.parse()
            os_log("Found %d keys for in %@ using built-in parser.", type: OSLogType.debug, localizationStrings.count, path.description)
            return localizationStrings.sorted()
        } catch {
            // The parser could not parse the input. Fallback to NSDictionary
            os_log("Could not parse %@ as String", type: OSLogType.error, path.description)
            if let dict = NSDictionary(contentsOfFile: path) as? [String: String] {
                var localizationStrings: [LocalizationString] = []
                for (key, value) in dict {
                    let localizationString = LocalizationString(key: key, value: value, message: nil)
                    localizationStrings.append(localizationString)
                }
                os_log("Found %d keys for in %@.", type: OSLogType.debug, localizationStrings.count, path.description)
                return localizationStrings.sorted()
            } else {
                os_log("Could not parse %@ as dictionary.", type: OSLogType.error, path.description)
                return []
            }
        }
    }
}
