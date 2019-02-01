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

/**
 Data source for the NSTableView with localizations
 */
final class LocalizationsDataSource: NSObject, NSTableViewDataSource {
    // MARK: - Properties

    private var localizationGroups: [LocalizationGroup] = []
    private var selectedLocalizationGroup: LocalizationGroup?
    private var localizations: [Localization] = []
    private var masterLocalization: Localization?
    private let localizationProvider = LocalizationProvider()
    private var numberOfKeys = 0

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
            self.selectedLocalizationGroup = group
            let languages = self.getLanguages(for: group)

            DispatchQueue.main.async {
                onCompletion((languages, group.name, localizationGroups))
            }
        }
    }

    /**
     Selects given group and gets available languages

     - Parameter group: group name
     - Returns: array of languages
     */
    func selectGroupAndGetLanguages(for group: String) -> [String] {
        let group = localizationGroups.first(where: { $0.name == group })!
        selectedLocalizationGroup = group
        return getLanguages(for: group)
    }

    /**
     Gets available languges for given group

     - Parameter group: localization group
     - Returns: array of languages
     */
    private func getLanguages(for group: LocalizationGroup) -> [String] {
        localizations = selectedLocalizationGroup?.localizations ?? []
        numberOfKeys = localizations.map({ $0.translations.count }).max() ?? 0
        masterLocalization = localizations.first(where: { $0.translations.count == numberOfKeys })

        return localizations.map({ $0.language })
    }

    /**
     Gets key for speficied row

     - Parameter row: row number
     - Returns: key if valid
     */
    func getKey(row: Int) -> String? {
        return (row < masterLocalization?.translations.count ?? 0) ? masterLocalization?.translations[row].key : nil
    }
    func getMessage(row: Int) -> String? {
        return (row < masterLocalization?.translations.count ?? 0) ? masterLocalization?.translations[row].message : nil
    }

    /**
     Gets localization for specified language and row. The language should be always valid. The localization might be missing, returning it with empty value in that case

     - Parameter language: language to get the localization for
     - Parameter row: row number
     - Returns: localiyation string
     */
    func getLocalization(language: String, row: Int) -> LocalizationString {
        guard let localization = localizations.first(where: { $0.language == language }), let masterLocalization = masterLocalization else {
            fatalError("Could not get localization for \(language) or master localization not present")
        }
        return localization.translations.first(where: { $0.key == masterLocalization.translations[row].key }) ?? LocalizationString(key: masterLocalization.translations[row].key, value: "", message: "message")
    }

    /**
     Updates given localization values in given language

     - Parameter language: language to update
     - Parameter key: localization string key
     - Parameter value: new value for the localization string
     */
    func updateLocalization(language: String, key: String, with value: String, message: String?) {
        guard let localization = localizations.first(where: { $0.language == language }) else {
            return
        }
        localizationProvider.updateLocalization(localization: localization, key: key, with: value, message: message)
    }

    // MARK: - Delegate

    func numberOfRows(in _: NSTableView) -> Int {
        return numberOfKeys
    }
}
