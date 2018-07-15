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

    private var localizationGroups: [LocalizationGroup] = []
    private var selectedLocalizationGroup: LocalizationGroup? = nil
    private var localizations: [Localization] = []
    private var masterLocalization: Localization?
    private let localizationProvider = LocalizationProvider()
    private var numberOfKeys = 0

    // MARK: - Action

    func load(folder: URL, onCompletion: @escaping ([String], String?, [LocalizationGroup]) -> Void) {
        DispatchQueue.global(qos: .background).async {
            
            self.localizationGroups = self.localizationProvider.getLocalizations(url: folder)
            if let group = self.localizationGroups.filter({$0.name == "Localizable.strings" }).first ?? self.localizationGroups.first {
                let languages = self.select(group: group)
                
                DispatchQueue.main.async {
                    onCompletion(languages, self.selectedLocalizationGroup?.name, self.localizationGroups)
                }
            }
        }
    }
    
    func select(name: String) -> [String]{
        let group = self.localizationGroups.filter({$0.name == name}).first!
        return select(group: group)
    }
    
    func select(group: LocalizationGroup) -> [String]{
        self.selectedLocalizationGroup = group
        self.localizations = self.selectedLocalizationGroup?.localizations ?? []
        self.numberOfKeys = self.localizations.map({ $0.translations.count }).max() ?? 0
        self.masterLocalization = self.localizations.first(where: { $0.translations.count == self.numberOfKeys })
        
        return self.localizations.map({ $0.language })
    }

    func getKey(row: Int) -> String? {
        return (row < masterLocalization?.translations.count ?? 0) ? masterLocalization?.translations[row].key : nil
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
