//
//  GoogleTranslator.swift
//  LocalizationEditor
//
//  Created by Алексей Лысенко on 23.09.2021.
//  Copyright © 2021 Igor Kulman. All rights reserved.
//

import AppKit

class GoogleTranslator: Translator {
    // MARK: - data structures
    enum TranslatorError: Error {
        case unknownRequestError
        case noTranslationsInResponse
        case userDoesNotProvidedApiKey
    }

    private struct TranslationResponse: Decodable {
        struct Data: Decodable {
            struct Translation: Decodable {
                var translatedText: String
                var detectedSourceLanguage: String
            }
            var translations: [Translation]
        }
        var data: Data
    }

    struct GoogleGenericError: Error, Decodable {
        var message: String
        var domain: String
        var reason: String
    }

    struct TranslationNetworkError: Error, Decodable {
        var code: Int
        var message: String
        var errors: [GoogleGenericError]
    }

    private struct TranslationNetworkErrorResponse: Decodable {
        var error: TranslationNetworkError
    }

    // MARK: - props
    private var apiKey: String = ""

    // MARK: - lifecycle
    init() {
        loadApiKey()
    }

    // MARK: - public
    func translate(text: String, targetLang: String, onComplete: ((String) -> Void)?, onError: ((Error) -> Void)?) {
        var requestURLComponents = URLComponents(string: "https://translation.googleapis.com/language/translate/v2")
        requestURLComponents!.queryItems = [
            URLQueryItem(name: "q", value: text),
            URLQueryItem(name: "target", value: getLangCode(forLocalizationId: targetLang)),
            URLQueryItem(name: "key", value: apiKey)
        ]
        let requestURL = requestURLComponents!.url!
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            do {
                guard let data = data else {
                    throw error ?? TranslatorError.unknownRequestError
                }

                if let err = try? JSONDecoder().decode(TranslationNetworkErrorResponse.self, from: data) {
                    throw err.error
                }
                let res = try JSONDecoder().decode(TranslationResponse.self, from: data)
                guard let translatedText = res.data.translations.first?.translatedText else {
                    throw TranslatorError.noTranslationsInResponse
                }
                onComplete?(translatedText)
            } catch {
                onError?(error)
            }
        }

        task.resume()
    }

    func translateSync(text: String, targetLang: String) throws -> String {
        var res: String?
        var err: Error?
        let semaphore = DispatchSemaphore(value: 0)
        translate(text: text, targetLang: targetLang) {
            res = $0
            semaphore.signal()
        } onError: {
            err = $0
            semaphore.signal()
        }
        semaphore.wait()
        if let err = err {
            throw err
        } else if let res = res {
            return res
        } else {
           fatalError()
           // Need to be revised later
        }
    }

    func makePreparations(on vc: NSViewController, onComplete: ((Translator) -> Void)?, onError: ((Error) -> Void)?) {
        guard apiKey.isEmpty else {
            onComplete?(self)
            return
        }

        let msg = NSAlert()
        msg.addButton(withTitle: "OK")
        msg.addButton(withTitle: "cancel".localized)
        msg.messageText = "need_google_api_key_title".localized
        msg.informativeText = "need_google_api_key_text".localized

        let txt = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        txt.placeholderString = "API KEY"

        msg.accessoryView = txt
        let response = msg.runModal()

        if (response == .alertFirstButtonReturn) {
            let response = txt.stringValue
            guard !response.isEmpty else {
                onError?(TranslatorError.userDoesNotProvidedApiKey)
                return
            }
            apiKey = response
            saveApiKey()
            onComplete?(self)
        } else {
            onError?(TranslatorError.userDoesNotProvidedApiKey)
        }
    }

    // MARK: - privates
    private let kGoogleTranslator_ApiKey = "GoogleTranslator_ApiKey"
    private func loadApiKey() {
        apiKey = UserDefaults.standard.string(forKey: kGoogleTranslator_ApiKey) ?? ""
    }

    private func saveApiKey() {
        UserDefaults.standard.set(apiKey, forKey: kGoogleTranslator_ApiKey)
    }

    // MARK: - privates
    private func getLangCode(forLocalizationId locId: String) -> String {
        // На данный момент считаем, что гугл кушоет по 2 символа.
        // en-GB не проходит, например
        return String(locId.prefix(2))
    }
}
