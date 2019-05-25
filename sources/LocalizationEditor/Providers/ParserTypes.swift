//
//  ParserTypes.swift
//  LocalizationEditor
//
//  Created by Andreas Neusüß on 31.12.18.
//  Copyright © 2018 Andreas Neusüß. All rights reserved.
//

import Foundation

/// This enum represents the tokens that can be extracted from the input file. They are used in the first step of the parsing until their information are combined into model objects.
///
/// - message: The message of a key-value pair. Text is mandatory since the message is optional and a non-existing message does not have a token.
/// - value: The value and its text.
/// - key: The key and its text.
/// - equal: The equal sign that maps a key to a value: ".
/// - semicolon: The semicolon that ends a line: ;
/// - newline: A new line \n.
enum Token {
    case message(String)
    case value(String)
    case key(String)
    case equal
    case semicolon
    case newline
    /// Checks if `self` is of the same type as `other` without taking the associated values into account.
    ///
    /// - Parameter other: The token to which self should be compared to.
    /// - Returns: `true` when the type of `other` matches the type of `self` without taking associated values into account.
    func isCaseEqual(to other: Token) -> Bool {
        switch (self, other) {
        case (.message, .message):
            return true
        case (.value, .value):
            return true
        case (.key, .key):
            return true
        case (.equal, .equal):
            return true
        case (.semicolon, .semicolon):
            return true
        case (.newline, .newline):
            return true
        default:
            return false
        }
    }
}

/// Control characters define starting and end points of tokens. They can be for example ", /* or ;
protocol ControlCharacterType {
    /// The length of the control character. Used to skip the input string by this amount of characters.
    var skippingLength: Int { get }
}

/// Control characters can enclose text.
protocol EnclosingType: ControlCharacterType {}
/// Other control characters can not contain any text, they only function as a position-marker.
protocol SeperatingType: ControlCharacterType {}

/// Enclosing control characters that wrapp text. They may start or end a message or contain a value/key.
/// - messageBoundaryOpen: Opens a message.
/// - messageBoundaryClose: Ends a message.
/// - quote: Wraps a key or a value.
/// - singleLineMessageOpen: Opens a single line message.
/// - singleLineMessageClose: Closes the single line message.
enum EnclosingControlCharacters: String, EnclosingType, CaseIterable {
    case messageBoundaryOpen = "/*"
    case messageBoundaryClose = "*/"
    case quote = "\""
    case singleLineMessageOpen = "//"
    case singleLineMessageClose = "\n"

    var skippingLength: Int {
        switch self {
        case .messageBoundaryOpen:
            return EnclosingControlCharacters.messageBoundaryOpen.rawValue.count
        case .messageBoundaryClose:
            return EnclosingControlCharacters.messageBoundaryClose.rawValue.count
        case .quote:
            return EnclosingControlCharacters.quote.rawValue.count
        case .singleLineMessageOpen:
            return EnclosingControlCharacters.singleLineMessageOpen.rawValue.count
        case .singleLineMessageClose:
            return EnclosingControlCharacters.singleLineMessageClose.rawValue.count
        }
    }
}

/// Seperating control characters do not wrap text. They function as position markers. For example they seperate a key from its value or end the line.
/// - equal: The equal sign that seperates a key from its value.
/// - semicolon: The semicolon that end a line.
/// - newline: A new line.
enum SeperatingControlCharacters: String, SeperatingType, CaseIterable {
    var skippingLength: Int {
        switch self {
        case .equal:
            return SeperatingControlCharacters.equal.rawValue.count
        case .semicolon:
            return SeperatingControlCharacters.semicolon.rawValue.count
        case .newline:
            return SeperatingControlCharacters.newline.rawValue.count
        }
    }

    case equal = "="
    case semicolon = ";"
    case newline = "\n"
}

/// Errors that may occure during parsing.
///
/// - notParsable: The input can not be parsed.
/// - malformattedInput Probably the input is mal formatted and the parser can not make any sense of it.
enum ParserError: Error {
    case notParsable
    case malformattedInput
}

extension Dictionary where Dictionary.Value: Comparable {
    /// Finds the smallest value of the dictionary. If there is one it returns the value and its corresponding key.
    ///
    /// O(n) time complexity.
    /// - Returns: The smallest value of the dictionary and the corresponding key.
    func smallestValue() -> (key: Key, value: Value)? {
        guard !isEmpty else {
            return nil
        }
        var smallestValue: Value?
        var smallestKey: Key?
        // Iterate through the dictionary and find a value that is smaller than the current smalles. O(n) time complexity.
        for (key, value) in self {
            if let currentSmallest = smallestValue {
                if value < currentSmallest {
                    // New smallest value found.
                    smallestValue = value
                    smallestKey = key
                }
            } else {
                // This must be the smallest since the smalles does not exist, yet.
                smallestValue = value
                smallestKey = key
            }
        }
        assert(smallestKey != nil, "Key must not be nil since at least one pair is stored and it must be identified as smalles.")
        assert(smallestValue != nil, "Value must not be nil since at least one pair is stored and it must be identified as smalles.")
        return (key: smallestKey!, value: smallestValue!)
    }
}

extension String {
    // Find the index of a substring in another string
    /// Finds the index of a substring in a superstring. Uses the build in string searching mechanisms implemented by Foundation.
    ///
    /// - Parameters:
    ///   - substring: The string to search for.
    ///   - startPosition: The start position from where the string should be searched from.
    ///   - options: Searching options.
    /// - Returns: The index where the searched string occures or nil if no match can be found.
    func index(of substring: String, from startPosition: Index? = nil, options: CompareOptions = .literal) -> Index? {
        let start = startPosition ?? startIndex
        let matchedRange = range(of: substring, options: options, range: start ..< endIndex)
        let matchedIndex = matchedRange?.lowerBound
        return matchedIndex
    }
}
