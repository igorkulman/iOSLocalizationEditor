//
//  AutoTranslator.swift
//  LocalizationEditor
//
//  Created by Алексей Лысенко on 23.09.2021.
//  Copyright © 2021 Igor Kulman. All rights reserved.
//

import AppKit

let kAutotranslatedTag = "#autotranslated"

class AutoTranslator {
    typealias TranslationsPack = [String: [String: LocalizationString?]]

    enum TranslationMechanism {
        case googleTranslate
    }

    private let translator: Translator
    init(mechanism: TranslationMechanism = .googleTranslate) {
        switch mechanism {
            case .googleTranslate: translator = GoogleTranslator()
        }
    }

    func makeTranslations(for data: TranslationsPack,
                          onComplete: ((TranslationsPack) -> Void)?,
                          onError: ((Error) -> Void)?) {
        var translated = TranslationsPack()
        do {
            for (locKey, locPair) in data {
                translated[locKey] = .init()
                guard let baseLocation = (locPair.first { $0.key == "ru" }),
                      let stringToTranslate = baseLocation.value?.value,
                      !stringToTranslate.isEmpty else {
                    continue
                }
                for (locLang, locString) in locPair {
                    if baseLocation.key == locLang {
                        translated[locKey]?[locLang] = .init(key: locKey, value: stringToTranslate, message: baseLocation.value?.message)
                    } else if let locString = locString,
                              !locString.value.isEmpty {
                        // Do nothing, because we already have translation
                        continue
                    } else {
                        let res = try translator.translateSync(text: stringToTranslate, targetLang: locLang)
                        var message = locString?.message ?? ""
                        if !message.contains(kAutotranslatedTag) {
                            message = [message, kAutotranslatedTag].joined(separator: " ")
                        }
                        translated[locKey]?[locLang] = .init(key: locKey, value: res, message: message)
                    }
                }
            }
            onComplete?(translated)
        } catch {
            onError?(error)
        }
    }

    func makePreparations(on vc: NSViewController,
                          onComplete: ((AutoTranslator) -> Void)?,
                          onError: ((Error) -> Void)?) {
        translator.makePreparations(on: vc) { [weak self] _ in
            self.map { onComplete?($0) }
        } onError: { onError?($0) }
    }
}
