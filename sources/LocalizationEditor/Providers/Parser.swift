//
//  Parser.swift
//  LocalizationEditor
//
//  Created by Andreas Neusüß on 25.12.18.
//  Copyright © 2018 Andreas Neusüß. All rights reserved.
//
// swiftlint:disable file_length

import Foundation

/**
 The Parser is responsible for transferring an input string into an array of model objects.
 
 The input is given as an argument during initialization. Call ```parse``` to start the process.
 
 It uses a two-setps approach to accomplish the extraction. In the first step tokens are produced that contain information about the type of information (using a state machine).
 In the second step, those tokens are inspected and model objects are constructed.
 */
class Parser {
    /// Possible state of the parser. Determines what operations need to be done in the next step.
    /// - readingKey The parser is currently reading a key since an opening " is recognized. The following text (until another " is found) must be interpreted as key-token.
    /// - readingValue The parser is currently reading a value since an opening " is recognized. The following text (until another " is found) must be interpreted as value-token.
    /// - readingMessage The parser is currently reading a message since an opening /* is recognized. The following text (until another */ is found) must be interpreted as message-token.
    /// - other The parser needs to decide which token comes next. In this state, the upcoming control character needs to be inspected and the state must be changed accordingly.
    fileprivate enum ParserState {
        case readingKey
        case readingValue
        case readingMessage(isSingleLine: Bool)
        case other
    }
    /// The current state of the parser.
    fileprivate var state: ParserState = .other
    /// The tokens that are produced during the first step.
    var tokens: [Token] = .init()
    /// The input text from which model information should be extracted from.
    fileprivate var input: String
    /// The results that are produced by the parser.
    fileprivate var results: [LocalizationString] = .init()
    /// Init the parser with a given input string.
    ///
    /// - Parameter input: The input from which model information should be extracted.
    init(input: String) {
        self.input = input
    }
    /// Call this function to start the parsing process. Will return the extracted model information or throw an error if the parser could not make any sense from the input. In this case, maybe a fallback to another extraction method should be used.
    ///
    /// - Returns: The model data.
    /// - Throws: A ```ParserError``` when the input string could not be parsed.
    func parse() throws -> [LocalizationString] {
        try tokenize()
        try results = interpretTokens()
        return results
    }

    /**
     This function reads through the input and populates an array of tokens.
     
     Implemented using a state machine. The state machine depends on ```ParserState```. When in .other, the next control character is used to determine the next state. When reading a key/value/message, upcoming text is interpreted as key/value/message until the corresponding closing control character is found.
     Currently, " and friends are escaped by also inspecting the upcoming control character. In Swift 5, String Literals may open the possibility to interpred bachslashed \ as escaping characters.
     */
    private func tokenize() throws {
        // Iterate through the input until it is cleared.
        while !input.isEmpty {
            // Actions depend on the current state.
            switch state {
            case .other:
                // Extract the upcoming control character, also switch the current state and append the extracted token, if any.
                if let extractedToken = try prepareNextState() {
                    tokens.append(extractedToken)
                }
            case .readingKey:
                extractAndAppendIfPossible(for: .key(""), until: .quote)
            case .readingValue:
                extractAndAppendIfPossible(for: .value(""), until: .quote)
            case .readingMessage(let isReadingSingleLine):
                // If the prior token as also a message, DO NOT append it since the prior message could be a license header.
                let endMarker: EnclosingControlCharacters = isReadingSingleLine ? .singleLineMessageClose : .messageBoundaryClose
                let currentMessageText = extractText(until: endMarker)
                let newToken: Token = .message(currentMessageText)
                tokens.append(newToken)
                state = .other
            }
        }
    }
    /// Extracts text from the input until the end marker is reached. Uses that text to create a new token and appends it to a prior extracted token if possible. In any case it updates the current list of extracted tokens.
    ///
    /// - Parameters:
    ///   - token: The type of token that should be created from the text before the end marker. The associated value of the input is ignored.
    ///   - endMarker: Marks the end of the tokens content.
    private func extractAndAppendIfPossible(for token: Token, until endMarker: EnclosingControlCharacters) {
        let currentText = extractText(until: endMarker)
        let potentialNewToken: Token
        switch token {
        case .key:
            potentialNewToken = .key(currentText)
        case .value:
            potentialNewToken = .value(currentText)
        default:
            assertionFailure("Currently, only the .key and .value support joining.")
            return
        }
        // Append to the prior token if possible.
        let newToken = tokenByConcatinatingwithPriorToken(potentialNewToken, seperatingString: endMarker.rawValue)
        tokens.append(newToken)
        // Do not stop reading when a newline or a quote is the next control character. Otherwise an unescaped quote may exclude text from the value. Keep the state unchanged if any other control character follows.
        if let nextControlCharacter = findNextControlCharacter(andExtractFromSource: false) {
            switch nextControlCharacter {
            case SeperatingControlCharacters.newline, EnclosingControlCharacters.singleLineMessageClose, EnclosingControlCharacters.quote:
                // Do not change the state and just continue.
                return
            default:
                break
            }
        }
        state = .other
    }
    /// Call this method when the list of tokens is ready and model object can be created. It will iterate through the tokens and try to map their values into model objects. Whe the mapping failed, an error is thrown.
    ///
    /// - Returns: The extracted model values.
    /// - Throws: In case of an malformatted input or anything unexpected happens, an error is thrown.
    private func interpretTokens() throws -> [LocalizationString] {
        var currentMessage: String?
        var currentKey: String?
        var currentValue: String?
        var results = [LocalizationString]()
        // The token that delimits an entry.
        guard let endToken = entriesEndToken(for: tokens) else {
            throw ParserError.malformattedInput
        }
        // Generates a result and appends it to the list of results if possible.
        func generateResultIfPossible(from processedToken: Token) {
            guard processedToken.isCaseEqual(to: endToken) else { return }
            // Done with that line. Check if values are populated and append them to the results.
            guard let key = currentKey, let value = currentValue else {
                return
            }
            let correctedMessage = removeLeadingTrailingSpaces(from: currentMessage)
            let entry = LocalizationString(key: key, value: value.unescaped, message: correctedMessage)
            results.append(entry)
            // Reset the properties to be ready for the next line.
            currentValue = nil
            currentKey = nil
            currentMessage = nil
        }
        // Iterate through the tokens and transform them into model objects.
        for token in tokens {
            switch token {
            case .message(let containedText):
                currentMessage = containedText
            case .key(let containedText):
                currentKey = containedText
            case .value(let containedText):
                currentValue = containedText
            default:
                ()
            }
            generateResultIfPossible(from: token)
        }
        // Throw an execption to indicate that something went wront when tokens are extracted but they could not be transferred into model objects:
        if !tokens.isEmpty && results.isEmpty {
            throw ParserError.malformattedInput
        }
        return results
    }
    /// Determines the token that ends an entry. An entry can either be ended by a semicolon (if no comment was provided or the comment is above the entry) or a comment located at the end of a line. In the second case the `.message` token marks the end of the entry.
    ///
    /// - Parameter tokens: The tokens that were extracted during tokenization.
    /// - Returns: The token that ends an entry.
    private func entriesEndToken(for tokens: [Token]) -> Token? {
        // Assumption: after the first semicolon comes a new line -> semicolon delimits entry
        // After first semicolon comes a message, followed by a new line -> message delimits entry
        guard let semicolonIndex = tokens.firstIndex(where: { $0.isCaseEqual(to: .semicolon) }) else {
            return nil
        }
        guard let indexAfterSemicolon = tokens.index(semicolonIndex, offsetBy: 1, limitedBy: tokens.endIndex - 1) else { return nil }
        let elementAfterSemicolon = tokens[indexAfterSemicolon]
        switch elementAfterSemicolon {
        case .newline:
            return .semicolon
        default:
            return elementAfterSemicolon
        }
    }
    /// This function removes leading and trailing spaces from the input.
    ///
    /// - Parameter input: The string whose leading and trailing spaces should be removed.
    /// - Returns: The input string without leading or trailing spaces or nil when the input was also nil.
    private func removeLeadingTrailingSpaces(from input: String?) -> String? {
        if let cleanedAndReversed = input?.drop(while: { $0 == " " }).reversed().drop(while: { $0 == " " }) {
            return String(cleanedAndReversed.reversed())
        }
        return nil
    }
    /// This function finds the index where a given enclosing control character can be found. This index determies where this token may be terminated.
    ///
    /// - Parameter control: The enclosing control character whose first appearance should be found.
    /// - Returns: The index of the input control character relative to the start index of the input string.
    private func endIndex(for control: EnclosingControlCharacters) -> String.Index {
        // Search for the end of the command.
        let endIndex: String.Index
        if let closeIndex = input.index(of: control.rawValue) {
            // Closing index found.
            endIndex = closeIndex
        } else {
            // Find another way to end the enclosed text. Most likely the input is not well formatted. Keep on trying.
            print("Badly formatted control characters! Maybe because the user has some \" in the comments that can not be handled, yet.")

            var recoveryIndex: String.Index
            if let messageEndIndex = input.index(of: EnclosingControlCharacters.messageBoundaryClose.rawValue) {
                recoveryIndex = messageEndIndex
            } else if let lineEndIndex = input.index(of: "\n") {
                recoveryIndex = lineEndIndex
            } else if let lineEndIndex = input.index(of: "\r\n") {
                recoveryIndex = lineEndIndex
            } else if let quoteEndIndex = input.index(of: EnclosingControlCharacters.quote.rawValue) {
                recoveryIndex = quoteEndIndex
            } else if let nextSemicolonIndex = input.index(of: SeperatingControlCharacters.semicolon.rawValue) {
                recoveryIndex = nextSemicolonIndex
            } else {
                // Tried everything. Use the end index in order to avoid crashing.
                recoveryIndex = input.endIndex
            }
            endIndex = recoveryIndex
        }
        return endIndex
    }
    /// This function extracts text until a given enclosing control character is found.
    ///
    /// - Parameter endType: The enclosing control charater that terminates a token.
    /// - Returns: The text that is contained form the inputs start until the enclosing control character is found. My be empty if the input string starts with the given control character.
    fileprivate func extractText(until endType: EnclosingControlCharacters) -> String {
        let endIndexOfText = endIndex(for: endType)
        let currentKeyText = extract(until: endIndexOfText, includingControlCharacter: endType)
        return currentKeyText
    }
    /// This function appends a given input token to a prior extracted token if it is of the same type.
    ///
    /// Inspectes the token that was added last and checks its type. If it matches the input token, both values are concatinated. The prior token is removed from the list and the freshly created token is returned for appending it into the list.
    /// - Parameters:
    ///   - inputToken: The input token whose value may be concatinated with the prior token.
    ///   - seperatingString: A seperator string that should be inserted between the text of the lastly added token and the input token.
    /// - Returns: If the last token in the list is of the same type as the input token, their values are concatinated, a new token is produced and returned. If not, the input token is returned.
    private func tokenByConcatinatingwithPriorToken(_ inputToken: Token, seperatingString: String = "") -> Token {
        // check if the prior token is of the same type as the current one.
        // If so, append the input and return the combined tokens.
        // If not, just return the input token
        if let priorToken = tokens.last {
            // When the prior token and the new token are of the same type, combine their values. Otherwise just return the new token.
            switch (priorToken, inputToken) {
            case let (.key(oldText), .key(newText)):
                let combinedText = oldText + seperatingString + newText
                // Also remove the token that is now included in the new token.
                tokens.removeLast()
                return .key(combinedText)
            case let (.value(oldText), .value(newText)):
                let combinedText = oldText + seperatingString + newText
                // Also remove the token that is now included in the new token.
                tokens.removeLast()
                return .value(combinedText)
            case let (.message( oldText), .message(newText)):
                let combinedText = oldText + seperatingString + newText
                // Also remove the token that is now included in the new token.
                tokens.removeLast()
                return .message(combinedText)
            default:
                return inputToken
            }
        } else {
            return inputToken
        }
    }
    /// This function extracts text from the input string. It starts at the beginning of the input and extracts text until the passed argument ```endIndex```. This text is also removed from the input.
    ///
    /// Apart from this, the characters of ```includingControlCharacter``` are also removed.
    ///
    /// - Parameters:
    ///   - endindex: The index until which text should be extracted.
    ///   - includingControlCharacter: The control character that should also be removed from the input string. They will not be part of the returned string.
    /// - Returns: The The string from the beginning of the input string to the given end index. The given control character will not be included but removed from the input.
    private func extract(until endindex: String.Index, includingControlCharacter: ControlCharacterType) -> String {
        // Extract the given range and remove it from the input string.

        let lengthOfControlCharacter: Int = includingControlCharacter.skippingLength
        let endIndexOfExtraction = input.index(endindex, offsetBy: lengthOfControlCharacter, limitedBy: input.endIndex) ?? input.endIndex
        // Remove the range that includes the control character. The input range is used for extracting the text before it.
        let rangeForRemoving = input.startIndex ..< endIndexOfExtraction
        let rangeForExtraction = input.startIndex ..< endindex
        let extracted = String(input[rangeForExtraction])
        input.removeSubrange(rangeForRemoving)
        return extracted
    }
    /// Clears the input string.
    private func clearInput() {
        input = ""
    }
    /// This function finds the next control character and returns it. If no new control character can be found, it returns nil (signaling that the input does not contain any valuable information anymore).
    ///
    /// - Parameter shouldExtract: A flag that determies whether the found control character should also be removed from the input string.
    /// - Returns: The next control character or nil if the input string does not contain any valuable information.
    private func findNextControlCharacter(andExtractFromSource shouldExtract: Bool) -> ControlCharacterType? {
        // Check what the nearest control character is and return it.
        // Also extract the found control character since the input string must be kept up to date.
        //
        // Find the first occurances of each control character. Then pick the first nearest one.
        // Unfortunately, a control character -> Index map can not be build since ControlCharacterType is seperated into two types. Therefore two distinct dictionaries must be used :/
        var matchIndexMapSeperatingControlCharacters = [SeperatingControlCharacters: String.Index]()
        var matchIndexMapEnclosingControlCharacters = [EnclosingControlCharacters: String.Index]()
        // Find the next occurance of any enclosing & seperating control character.
        for enclosingControlCharacter in EnclosingControlCharacters.allCases {
            matchIndexMapEnclosingControlCharacters[enclosingControlCharacter] = input.index(of: enclosingControlCharacter.rawValue)
        }
        for seperatingControlCharacter in SeperatingControlCharacters.allCases {
            matchIndexMapSeperatingControlCharacters[seperatingControlCharacter] = input.index(of: seperatingControlCharacter.rawValue)
        }
        // The Map is build up. Now search for the smallest value:
        let smallestEnclosing = matchIndexMapEnclosingControlCharacters.smallestValue()
        let smallestSeperating = matchIndexMapSeperatingControlCharacters.smallestValue()
        let nextControlCharacter: ControlCharacterType
        let nextControlCharacterIndex: String.Index
        // Determine what of the two elements is smaller:
        switch (smallestEnclosing, smallestSeperating) {
        case (.none, .some(let smallSeperating)):
            nextControlCharacter = smallSeperating.key
            nextControlCharacterIndex = smallSeperating.value
        case (.some(let smallEnclosing), .none):
            nextControlCharacter = smallEnclosing.key
            nextControlCharacterIndex = smallEnclosing.value
        case let (.some(smallEnclosing), .some(smallSeperating)):
            if smallSeperating.value < smallEnclosing.value {
                nextControlCharacter = smallSeperating.key
                nextControlCharacterIndex = smallSeperating.value
            } else {
                nextControlCharacter = smallEnclosing.key
                nextControlCharacterIndex = smallEnclosing.value
            }
        case (.none, .none):
            // No small element found. Apparently the input is parsed completely. Since no token can be found, it is save to assume that the input string does not contain any valuable information. Just remove all of its input and the system can come to a result.
            clearInput()
            return nil
        }
        // Remove til the found control character:
        if shouldExtract {
            _ = extract(until: nextControlCharacterIndex, includingControlCharacter: nextControlCharacter)
        }
        return nextControlCharacter
    }
}

extension Parser {
    // Handling .other case here.
    //
    /// This function should be called when the current state is .other. It finds the upcoming control character and switches the state accordingly.
    ///
    /// - Returns: A token that was extracted from the input or nil if no token can be found.
    /// - Throws: Throws an execption when a parse error occured.
    fileprivate func prepareNextState() throws -> Token? {
        // Read input until the next control command is found.
        // Extract the control command.
        guard let nextControlCharacter = findNextControlCharacter(andExtractFromSource: true) else {
            // No new control character is found which means that the input does not contain any information. Return so that the system can finish.
            return nil
        }
        // Token taht will be returned if appropriate:
        var returnToken: Token?
        // Switch state to reflect the upcoming input.
        switch nextControlCharacter {
        case EnclosingControlCharacters.quote:
            // Handle this case in a seperate function:
            prepareStateForCurrentQuoteToken()
        case EnclosingControlCharacters.messageBoundaryOpen:
            // A new message begins.
            // Set the state to expect a message.
            state = .readingMessage(isSingleLine: false)
        case EnclosingControlCharacters.messageBoundaryClose:
            // Message-end markers should only be detected when the lexer is reading a message. If they occure 'in the wild' the input must be ill formatted.
            break
        case SeperatingControlCharacters.equal:
            // Extract equal sign as token. A quote will follow as next control character but for now the state remains .other in order to detect that quote.
            returnToken = .equal
            state = .other
        case SeperatingControlCharacters.semicolon:
            // Extract semicolon as token. A quote or message-start mark will follow as next control character but for now the state remains .other in order to detect that quote.
            returnToken = .semicolon
            state = .other
        case SeperatingControlCharacters.newline:
            returnToken = .newline
        case EnclosingControlCharacters.singleLineMessageOpen:
            state = .readingMessage(isSingleLine: true)
        case EnclosingControlCharacters.singleLineMessageClose:
            returnToken = .newline
        default:
            // New types need to be registered.
            throw ParserError.notParsable
        }
        // Maybe tell only available options/tokens to the system.
        return returnToken
    }
    /// This function should be called when the upcoming control character is a quote. It inspects the most recently added tokens and decides whether the upcoming text should be interpreted as key or value. This procedure is neccessary since no escaping characters (\) are available. This may change in Swift 5 String Literal functions.
    private func prepareStateForCurrentQuoteToken() {
        // Check whether a key or value is to be exected:
        // Use heuristics like 'equal before' or 'semicolon before'.
        // If value before: value follows that was not escaped.
            // Set the state to expect a value as the next token
        // If key before: unescaped key follows.
            // Set the state to expect a key as the next token
        // If equal before: value follows.
        // Else: key follows.
        if let valueBefore = tokens.last {
            switch valueBefore {
            case .key:
                state = .readingKey
            case .value:
                state = .readingValue
            case .equal:
                state = .readingValue
            case .semicolon:
                state = .readingKey
            default:
                state = .readingKey
            }
        } else {
            // A key will follow this quote.
            state = .readingKey
        }
    }
}
