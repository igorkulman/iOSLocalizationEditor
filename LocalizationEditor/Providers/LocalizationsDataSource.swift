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

    private(set) var localizations: [Localization] = []

    private var masterLocalization: Localization?
    private let localizationProvider = LocalizationProvider()
    private var numberOfKeys = 0

    // MARK: - Action

    func load(folder: URL) {
        localizations = localizationProvider.getLocalizations(url: folder)
        numberOfKeys = localizations.map({ $0.translations.count }).max() ?? 0
        masterLocalization = localizations.first(where: { $0.translations.count == numberOfKeys })
    }

    func getKey(row: Int) -> String? {
        return masterLocalization?.translations[row].key
    }

    func getLocalization(language: String, row: Int) -> LocalizationString? {
        guard let localization = localizations.first(where: { $0.language == language }), let masterLocalization = masterLocalization else {
            return nil
        }
        return localization.translations.first(where: { $0.key == masterLocalization.translations[row].key })
    }

    func updateLocalization(language: String, string: LocalizationString) {
        guard let localization = localizations.first(where: { $0.language == language }) else {
            return
        }
        localizationProvider.updateLocalization(localization: localization, string: string)
    }

    // MARK: - Delegate

    func numberOfRows(in _: NSTableView) -> Int {
        return numberOfKeys
    }
}
