//
//  LocalizationsDataSource.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import Cocoa
import Foundation
import os

typealias LocalizationsDataSourceData = ([String], String?, [LocalizationGroup])

enum Filter: Int, CaseIterable, CustomStringConvertible {
    case all
    case missing
    case autotranslated

    var description: String {
        switch self {
        case .all:
            return "all".localized
        case .missing:
            return "missing".localized
        case .autotranslated:
            return "autotranslated".localized
        }
    }
}

/**
 Data source for the NSTableView with localizations
 */
final class LocalizationsDataSource: NSObject {
    // MARK: - Properties

    private let localizationProvider = LocalizationProvider()
    private var localizationGroups: [LocalizationGroup] = []
    private var selectedLocalizationGroup: LocalizationGroup?
    private var languagesCount = 0
    private var mainLocalization: Localization?

    /**
     Dictionary indexed by localization key on the first level and by language on the second level for easier access
     */
    private var data: [String: [String: LocalizationString?]] = [:]

    /**
     Keys for the consumer. Depend on applied filter.
     */
    private var filteredKeys: [String] = []

    // MARK: - Actions

    /**
     Loads data for directory at given path

     - Parameter folder: directory path to start the search
     - Parameter onCompletion: callback with data
     */
    func load(folder: URL, onCompletion: @escaping (LocalizationsDataSourceData) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let localizationGroups = self.localizationProvider.getLocalizations(url: folder)
            guard localizationGroups.count > 0, let group = localizationGroups.first(where: { $0.name == "Localizable.strings" }) ?? localizationGroups.first else {
                os_log("No localization data found", type: OSLogType.error)
                DispatchQueue.main.async {
                    onCompletion(([], nil, []))
                }
                return
            }

            self.localizationGroups = localizationGroups
            let languages = self.select(group: group)

            DispatchQueue.main.async {
                onCompletion((languages, group.name, localizationGroups))
            }
        }
    }

    /**
     Selects given localization group, converting its data to a more usable form and returning an array of available languages

     - Parameter group: group to select
     - Returns: an array of available languages
     */
    private func select(group: LocalizationGroup) -> [String] {
        selectedLocalizationGroup = group

        let localizations = group.localizations.sorted(by: { lhs, rhs in
            if lhs.language.lowercased() == "base" {
                return true
            }

            if rhs.language.lowercased() == "base" {
                return false
            }

            return lhs.translations.count > rhs.translations.count
        })
        mainLocalization = localizations.first
        languagesCount = group.localizations.count

        data = [:]
        for key in mainLocalization!.translations.map({ $0.key }) {
            data[key] = [:]
            for localization in localizations {
                data[key]![localization.language] = localization.translations.first(where: { $0.key == key })
            }
        }

        // making sure filteredKeys are computed
        filter(by: Filter.all, searchString: nil)

        return localizations.map({ $0.language })
    }

    /**
     Selects given group and gets available languages

     - Parameter group: group name
     - Returns: array of languages
     */
    func selectGroupAndGetLanguages(for group: String) -> [String] {
        let group = localizationGroups.first(where: { $0.name == group })!
        let languages = select(group: group)
        return languages
    }

    func currentLocalizationGroupName() -> String? { selectedLocalizationGroup?.name }

    /**
     Filters the data by given filter and search string. Empty search string means all data us included.

     Filtering is done by setting the filteredKeys property. A key is included if it matches the search string or any of its translations matches.
     */
    func filter(by filter: Filter, searchString: String?) {
        os_log("Filtering by %@", type: OSLogType.debug, "\(filter)")

        let data: [String: [String: LocalizationString?]]
        switch filter {
            // no filtering
            case .all: data = self.data
            // filter all locKeys, that have missing localizations
            case .missing: data = self.data.filter { dict in
                return dict.value.keys.count != self.languagesCount || !dict.value.values.allSatisfy({ $0?.value.isEmpty == false })
            }
            // filter all locKeys that have autotranslated tag in message
            case .autotranslated: data = self.data.filter { (locKey, locPairs) in
                locPairs.contains { $0.value?.message?.contains(kAutotranslatedTag) ?? false }
            }
        }

        // no search string, just use teh filtered data
        guard let searchString = searchString, !searchString.isEmpty else {
            filteredKeys = data.keys.map({ $0 }).sorted(by: { $0<$1 })
            return
        }

        os_log("Searching for %@", type: OSLogType.debug, searchString)

        var keys: [String] = []
        for (key, value) in data {
            // include if key matches (no need to check further)
            if key.normalized.contains(searchString.normalized) {
                keys.append(key)
                continue
            }

            // include if any of the translations matches
            if value.compactMap({ $0.value }).map({ $0.value }).contains(where: { $0.normalized.contains(searchString.normalized) }) {
                keys.append(key)
            }
        }

        // sorting because the dictionary does not keep the sort
        filteredKeys = keys.sorted(by: { $0<$1 })
    }

    /**
     Gets key for speficied row

     - Parameter row: row number
     - Returns: key if valid
     */
    func getKey(row: Int) -> String? {
        return row < filteredKeys.count ? filteredKeys[row] : nil
    }

    /**
     Gets the message for specified row

     - Parameter row: row number
     - Returns: message if any
     */
    func getMessage(row: Int) -> String? {
        guard let key = getKey(row: row), let part = data[key], let firstKey = part.keys.map({ $0 }).first  else {
            return nil
        }

        return part[firstKey]??.message
    }

    /**
     Gets localization for specified language and row. The language should be always valid. The localization might be missing, returning it with empty value in that case

     - Parameter language: language to get the localization for
     - Parameter row: row number
     - Returns: localization string
     */
    func getLocalization(language: String, row: Int) -> LocalizationString {
        guard let key = getKey(row: row) else {
            // should not happen but you never know
            fatalError("No key for given row")
        }

        guard let section = data[key], let data = section[language], let localization = data else {
            return LocalizationString(key: key, value: "", message: "")
        }

        return localization
    }

    func getLocalizations(forKey locKey: String) -> [String: LocalizationString?]? { data[locKey] }

    /**
     Updates given localization values in given language

     - Parameter language: language to update
     - Parameter key: localization string key
     - Parameter value: new value for the localization string
     */
    func updateLocalization(language: String, key: String, with value: String, message: String?) {
        guard let localization = selectedLocalizationGroup?.localizations.first(where: { $0.language == language }) else {
            return
        }
        localizationProvider.updateLocalization(localization: localization, key: key, with: value, message: message)
    }

    /**
     Deletes given key from all the localizations

     - Parameter key: key to delete
     */
    func deleteLocalization(key: String) {
        guard let selectedLocalizationGroup = selectedLocalizationGroup else {
            return
        }

        selectedLocalizationGroup.localizations.forEach { localization in
            self.localizationProvider.deleteKeyFromLocalization(localization: localization, key: key)
        }
        data.removeValue(forKey: key)
    }

    func deleteAutotranslations(forKey locKey: String) {
        (data[locKey]?.filter { $0.value?.message?.contains(kAutotranslatedTag) ?? false })?
            .forEach { (locLang, locString) in
                guard locString?.message?.contains(kAutotranslatedTag) ?? false else { return }
                updateLocalization(language: locLang,
                                   key: locKey,
                                   with: "",
                                   message: locString?.message?.replacingOccurrences(of: kAutotranslatedTag, with: ""))
                locString?.update(newValue: "")
                locString?.updateMessage(locString?.message?.replacingOccurrences(of: kAutotranslatedTag, with: ""))
        }
    }

    /**
     Adds new localization key with a message to all the localizations

     - Parameter key: key to add
     - Parameter message: message (optional)
     */
    func addLocalizationKey(key: String, message: String?) {
        guard let selectedLocalizationGroup = selectedLocalizationGroup else {
            return
        }

        selectedLocalizationGroup.localizations.forEach({ localization in
            let newTranslation = localizationProvider.addKeyToLocalization(localization: localization, key: key, message: message)
            // If we already created the entry in the data dict, do not overwrite the entry entirely.
            // Instead just add the data to the already present entry.
            if data[key] != nil {
                data[key]?[localization.language] = newTranslation
            } else {
                data[key] = [localization.language: newTranslation]
            }
        })
    }

    /**
     Returns row number for given key

     - Parameter key: key to check

     - Returns: row number (if any)
     */
    func getRowForKey(key: String) -> Int? {
        return filteredKeys.firstIndex(of: key)
    }
}

extension LocalizationsDataSource {
    func getIncompleteLocalizations() -> [String: [String: LocalizationString?]] {
        return data.filter { locKey, locPair in
            (locPair.contains { lang, loc in loc == nil || (loc?.value.isEmpty ?? true) })
        }
    }
}

// MARK: - Delegate

extension LocalizationsDataSource: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        return filteredKeys.count
    }
}
