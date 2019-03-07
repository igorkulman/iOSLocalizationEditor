//
//  Flag.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 07/03/2019.
//  Copyright © 2019 Igor Kulman. All rights reserved.
//

import Foundation

struct Flag {
    private let languageCode: String

    init(languageCode: String) {
        self.languageCode = languageCode.uppercased()
    }

    var emoji: String {
        guard let flag = emojiFlag else {
            return languageCode
        }

        return "\(flag) \(languageCode)"
    }

    private var emojiFlag: String? {
        // special cases for zh-Hant and zh-Hans
        if languageCode.hasPrefix("ZH-") && languageCode.count == 7 {
            return "🇨🇳"
        }

        guard languageCode.count == 2 || (languageCode.count == 5 && languageCode.contains("-")) else {
            return nil
        }

        let parts = languageCode.split(separator: "-")

        // language and country code like en-US
        if parts.count == 2 {
            let country = parts[1]
            return emojiFlag(countryCode: String(country))
        }

        // checking iOS supported languages (https://www.ibabbleon.com/iOS-Language-Codes-ISO-639.html)
        let language = String(parts[0])

        switch language {
        case "EN":
            return "🇬🇧"
        case "FR":
            return "🇫🇷"
        case "ES":
            return "🇪🇸"
        case "PT":
            return "🇵🇹"
        case "IT":
            return "🇮🇹"
        case "DE":
            return "🇩🇪"
        case "ZH":
            return "🇨🇳"
        case "NL":
            return "🇳🇱"
        case "JA":
            return "🇯🇵"
        case "VI":
            return "🇻🇳"
        case "RU":
            return "🇷🇺"
        case "SV":
            return "🇸🇪"
        case "DA":
            return "🇩🇰"
        case "FI":
            return "🇫🇮"
        case "NB":
            return "🇳🇴"
        case "TR":
            return "🇹🇷"
        case "EL":
            return "🇬🇷"
        case "ID":
            return "🇮🇩"
        case "MS":
            return "🇲🇾"
        case "TH":
            return "🇹🇭"
        case "HI":
            return "🇮🇳"
        case "HU":
            return "🇭🇺"
        case "PL":
            return "🇵🇱"
        case "CS":
            return "🇨🇿"
        case "SK":
            return "🇸🇰"
        case "UK":
            return "🇺🇦"
        case "CA":
            return "CA" // no emoji flag
        case "RO":
            return "🇷🇴"
        case "HR":
            return "🇭🇷"
        case "HE":
            return "🇮🇱"
        case "AR":
            return "🇱🇧"
        default:
            return emojiFlag(countryCode: language)
        }
    }

    private func emojiFlag(countryCode: String) -> String? {
        var string = ""

        for unicodeScalar in countryCode.unicodeScalars {
            if let scalar = UnicodeScalar(127397 + unicodeScalar.value) {
                string.append(String(scalar))
            }
        }

        return string.isEmpty ? nil : string
    }
}
