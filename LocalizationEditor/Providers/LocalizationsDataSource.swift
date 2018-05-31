//
//  LocalizationsDataSource.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Teamwire. All rights reserved.
//

import Cocoa
import Foundation

class LocalizationsDataSource: NSObject, NSTableViewDataSource {

    // MARK: - Properties

    private var localizations: [Localization] = []
    private var masterLocalization: Localization?
    private let localizationProvider = LocalizationProvider()
    private var numberOfKeys = 0

    // MARK: - Action

    func load(folder: URL) -> [String] {
        localizations = localizationProvider.getLocalizations(url: folder)
        numberOfKeys = localizations.map({ $0.translations.count }).max() ?? 0
        masterLocalization = localizations.first(where: { $0.translations.count == numberOfKeys })
        return localizations.map({ $0.language })
    }

    func getKey(row: Int) -> String? {
        return masterLocalization?.translations[row].key
    }

    func getLocalization(language: String, row: Int) -> LocalizationString {
        guard let localization = localizations.first(where: { $0.language == language }), let masterLocalization = masterLocalization else {
            fatalError()
        }
        return localization.translations.first(where: { $0.key == masterLocalization.translations[row].key }) ?? LocalizationString(key: masterLocalization.translations[row].key, value: "")
    }

    func updateLocalization(language: String, string: LocalizationString, with value: String) {
        guard let localization = localizations.first(where: { $0.language == language }) else {
            return
        }
        localizationProvider.updateLocalization(localization: localization, string: string, with: value)
    }

    // MARK: - Delegate

    func numberOfRows(in _: NSTableView) -> Int {
        return numberOfKeys
    }
}
