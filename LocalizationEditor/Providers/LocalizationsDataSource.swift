//
//  LocalizationsDataSource.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import Cocoa
import Foundation

class LocalizationsDataSource: NSObject, NSTableViewDataSource {

    // MARK: - Properties

    private var localizationGroup: LocalizationGroup? = nil
    private var localizations: [Localization] = []
    private var masterLocalization: Localization?
    private let localizationProvider = LocalizationProvider()
    private var numberOfKeys = 0

    // MARK: - Action

    func load(folder: URL, onCompletion: @escaping ([String]) -> Void) {
        DispatchQueue.global(qos: .background).async {
            
            self.localizationGroup = self.localizationProvider.getLocalizations(url: folder).filter({$0.name == "Localizable.strings" }).first
            self.localizations = self.localizationGroup?.localizations ?? []
            self.numberOfKeys = self.localizations.map({ $0.translations.count }).max() ?? 0
            self.masterLocalization = self.localizations.first(where: { $0.translations.count == self.numberOfKeys })

            DispatchQueue.main.async {
                onCompletion(self.localizations.map({ $0.language }))
            }
        }
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
