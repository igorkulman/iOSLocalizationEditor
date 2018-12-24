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
    func updateLocalization(localization: Localization, key: String, with value: String, message: String?) {
        if let existing = localization.translations.first(where: { $0.key == key }), existing.value == value {
            Log.debug?.message("Same value provided for \(existing), not updating")
            return
        }

        Log.debug?.message("Updating \(key) in \(value) with Message: \(message ?? "No Message.")")

        localization.update(key: key, value: value, message: message)

        let data = localization.translations.map { string -> String in
            let stringForMessage: String
            if let message = string.message {
                stringForMessage = "/* \(message) */"
            } else {
                stringForMessage = ""
            }
            return """
            \(stringForMessage)
            \"\(string.key)\" = \"\(string.value.replacingOccurrences(of: "\"", with: "\\\""))\";\n
            """
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
        }).sorted()
    }

    // MARK: Internal implementation

    /**
     Reads given strings file and constructs an array of localization strings from it

     - Parameter path: strings file path
     - Returns: array of localization strings
     */
    private func getLocalizationStrings(path: String) -> [LocalizationString] {
        
        // Patterns for searching for key, value and message:
        let patternComments = "\\*([^*]|[\\r\\n]|(\\*+([^*/]|[\\r\\n])))*\\*+"
        let patternKeyValueMatching = "([\"])(?:(?=(\\\\?))\\2.)*?\\1"

        // Read the input as string in oder to apply regex matching to it.
        guard let contentOfFileAsString = try? String(contentsOfFile: path) else {
            Log.error?.message("Could not parse \(path) as String")
            return []
        }
        // Regex for searching messages.
        let regexMessages = try! NSRegularExpression(pattern: patternComments, options: [.caseInsensitive])
        // Regex for searching keys and values.
        let regexKeysAndValues = try! NSRegularExpression(pattern: patternKeyValueMatching, options: [.caseInsensitive])
        
        // Executing the regex:
        let messagesMatching = regexMessages.matches(in: contentOfFileAsString, options: [], range: NSRange(location: 0, length: contentOfFileAsString.count))
        let keyAndValueMatching = regexKeysAndValues.matches(in: contentOfFileAsString, options: [], range: NSRange(location: 0, length: contentOfFileAsString.count))
        
        // Extract the actual keys and comments from the matching regex-range
        let keysAndComments = keyAndValueMatching.map { (match) -> String in
            let range = Range(match.range, in: contentOfFileAsString)!
            return String(contentOfFileAsString[range])
        }
        
        // Assuming that the first element (key) corresponds to the second element (value). Therefore, the every other element acts as the value.
        let keys = keysAndComments.enumerated().filter { (index, _) -> Bool in
            return index % 2 == 0
        }
        let values = keysAndComments.enumerated().filter { (index, _) -> Bool in
            return index % 2 != 0
        }
        
        // Will store the extraction results as LocalizationString
        var localizationStrings: [LocalizationString] = []
        
        
        /// This function removes the first and last character that may be still present as an artifact of the regex matching.
        ///
        /// - Parameter input: The string which first and last character should be removed.
        /// - Returns: The input without first and last character.
        func removeRegexBoundingCharacters(from input: String) -> String {
            return String(input.dropFirst().dropLast())
        }
        
        
        /// This function sorts the input according to the contained keys. Apply this function before an array is returned.
        ///
        /// - Parameter input: The array that should be sorted.
        /// - Returns: The sorted array, ready to be returned.
        func sort(_ input: [LocalizationString]) -> [LocalizationString] {
            return input.sorted(by: { lhs, rhs -> Bool in
                lhs.key < rhs.key
            })
        }
        
        // Check if the number of keys match the number of values:
        guard keys.count == values.count else {
            
            // Oh no, the number of keys and values do not match! Fall back to the old and automatic extraction method:
            if let dict = NSDictionary(contentsOfFile: path) as? [String: String] {
                
                var localizationStrings: [LocalizationString] = []
                for (key, value) in dict {
                    let localizationString = LocalizationString(key: key, value: value, message: nil)
                    localizationStrings.append(localizationString)
                }
                Log.debug?.message("Found \(localizationStrings.count) keys for in \(path)")
                
                return sort(localizationStrings)
            }
            else {
                Log.error?.message("Could not parse \(path) as String")
                return []
            }
        }
        
        // Check if a valid number of comments were extracted. That is the case if the number matches the number of keys.
        if messagesMatching.count == keys.count {
            // Comments matching keys
            
            // It seems like that every key got one message. We can assume that a comment corresponds to a key.
            
            // Will store the extracted messages
            var messages: [String] = .init()
            
            // Extract the message as strings:
            messages = messagesMatching.map { (match) -> String in
                let range = Range(match.range, in: contentOfFileAsString)!
                return String(contentOfFileAsString[range])
            }
            
            // Create the return of the function:
            // As many keys as values as messages, so one index is enough
            for index in 0..<keys.count {
                let key = removeRegexBoundingCharacters(from: keys[index].element)
                let value = removeRegexBoundingCharacters(from: values[index].element)
                let message = removeRegexBoundingCharacters(from: messages[index])
                
                let localizationString = LocalizationString(key: key, value: value, message: message)
                localizationStrings.append(localizationString)
            }
        }
        else {
            
            //Comments NOT matching keys. Discard messages and only use keys and values.
            for (key, value) in zip(keys, values) {

                let key = removeRegexBoundingCharacters(from: key.element)
                let value = removeRegexBoundingCharacters(from: value.element)
                
                let localizationString = LocalizationString(key: key, value: value, message: nil)
                localizationStrings.append(localizationString)
            }
        }
        
        Log.debug?.message("Found \(localizationStrings.count) keys for in \(path)")

        return localizationStrings.sorted()
    }
}
