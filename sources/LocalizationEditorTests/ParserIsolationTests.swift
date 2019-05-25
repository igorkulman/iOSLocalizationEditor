//
//  ParserIsolationTests.swift
//  LocalizationEditor
//
//  Created by Andreas Neusüß on 30.12.18.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import Foundation
import XCTest
@testable import LocalizationEditor

class LocalizationEditor: XCTestCase {

    func testInputValidNoMessage() {
        let inputString =
"""
"ART_AND_CULTURE" = "Kunst und Kultur";

"BACK" = "Zurück";

"BIRTHDAY_SELECT" = "Bitte wähle deinen Geburtstag aus";
"""
        let parser = Parser(input: inputString)
        let result = try! parser.parse()
        
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].key, "ART_AND_CULTURE")
        XCTAssertEqual(result[1].key, "BACK")
        XCTAssertEqual(result[2].key, "BIRTHDAY_SELECT")
        
        XCTAssertEqual(result[0].value, "Kunst und Kultur")
        XCTAssertEqual(result[1].value, "Zurück")
        XCTAssertEqual(result[2].value, "Bitte wähle deinen Geburtstag aus")
    }
    
    func testInputValidNoMessageNoEscapingNeeded() {
        let inputString =
        """
"ART_"AND"_CULTURE" = "Kunst "und" Kultur";

"BACK" = "Zurück";

"BIRTHDAY_SELECT" = "Bitte wähle deinen Geburtstag aus";
"""
        
        let escapingParser = Parser(input: inputString)
        let escapingResult = try! escapingParser.parse()
        
        XCTAssertEqual(escapingResult.count, 3)
        XCTAssertEqual(escapingResult[0].key, "ART_\"AND\"_CULTURE")
        XCTAssertEqual(escapingResult[1].key, "BACK")
        XCTAssertEqual(escapingResult[2].key, "BIRTHDAY_SELECT")
        
        XCTAssertEqual(escapingResult[0].value, "Kunst \"und\" Kultur")
        XCTAssertEqual(escapingResult[1].value, "Zurück")
        XCTAssertEqual(escapingResult[2].value, "Bitte wähle deinen Geburtstag aus")
        
        XCTAssertNil(escapingResult[0].message)
        XCTAssertNil(escapingResult[1].message)
        XCTAssertNil(escapingResult[2].message)
    }
    
    func testInputValidWithMultilineMessage() {
        let inputString =
        """
/* The string for "the art and culture category */
"ART_"AND"_CULTURE" = "Kunst "und" Kultur";

/* String for back operation */
"BACK" = "Zurück";

/* Select your birhtday */
"BIRTHDAY_SELECT" = "Bitte wähle deinen Geburtstag aus";
"""
        let parser = Parser(input: inputString)
        let result = try! parser.parse()
        
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].key, "ART_\"AND\"_CULTURE")
        XCTAssertEqual(result[1].key, "BACK")
        XCTAssertEqual(result[2].key, "BIRTHDAY_SELECT")
        
        XCTAssertEqual(result[0].value, "Kunst \"und\" Kultur")
        XCTAssertEqual(result[1].value, "Zurück")
        XCTAssertEqual(result[2].value, "Bitte wähle deinen Geburtstag aus")
        
        XCTAssertEqual(result[0].message, "The string for \"the art and culture category")
        XCTAssertEqual(result[1].message, "String for back operation")
        XCTAssertEqual(result[2].message, "Select your birhtday")
    }

    func testInputValidWithSinglelineMessageTrailing() {
        let inputString =
        """
"Start %@" = "Empieza a %@"; // e.g., "Start bouldering", "Start Top Range"

"BACK" = "Zurück"; // String for "back operation"

"BIRTHDAY_SELECT" = "Bitte wähle deinen Geburtstag aus"; // Select your birhtday
"""
        let parser = Parser(input: inputString)
        let result = try! parser.parse()
        
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].key, "Start %@")
        XCTAssertEqual(result[1].key, "BACK")
        XCTAssertEqual(result[2].key, "BIRTHDAY_SELECT")
        
        XCTAssertEqual(result[0].value, "Empieza a %@")
        XCTAssertEqual(result[1].value, "Zurück")
        XCTAssertEqual(result[2].value, "Bitte wähle deinen Geburtstag aus")
        
        XCTAssertEqual(result[0].message, "e.g., \"Start bouldering\", \"Start Top Range\"")
        XCTAssertEqual(result[1].message, "String for \"back operation\"")
        XCTAssertEqual(result[2].message, "Select your birhtday")
    }
    
    func testInputValidWithSinglelineMessage() {
        let inputString =
        """
// e.g., "Start bouldering", "Start Top Range"
"Start %@" = "Empieza a %@";

// String for "back operation"
"BACK" = "Zurück";

// Select your birhtday
"BIRTHDAY_SELECT" = "Bitte wähle deinen Geburtstag aus";
"""
        let parser = Parser(input: inputString)
        let result = try! parser.parse()

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].key, "Start %@")
        XCTAssertEqual(result[1].key, "BACK")
        XCTAssertEqual(result[2].key, "BIRTHDAY_SELECT")

        XCTAssertEqual(result[0].value, "Empieza a %@")
        XCTAssertEqual(result[1].value, "Zurück")
        XCTAssertEqual(result[2].value, "Bitte wähle deinen Geburtstag aus")

        XCTAssertEqual(result[0].message, "e.g., \"Start bouldering\", \"Start Top Range\"")
        XCTAssertEqual(result[1].message, "String for \"back operation\"")
        XCTAssertEqual(result[2].message, "Select your birhtday")
    }
    
    func testInputValidWithMessageContainingGarbage() {
        let inputString =
        """
garbage garbage...
/* The string for "the art and culture category */
garbage garbage...
"ART_"AND"_CULTURE" = "Kunst \"und\" Kultur";

garbage garbage...
/* String for back operation */
"BACK" = "Zurück";

/* Select your birhtday */
"BIRTHDAY_SELECT" = "Bitte wähle deinen Geburtstag aus";
"""
        let parser = Parser(input: inputString)
        let result = try! parser.parse()
        
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].key, "ART_\"AND\"_CULTURE")
        XCTAssertEqual(result[1].key, "BACK")
        XCTAssertEqual(result[2].key, "BIRTHDAY_SELECT")
        
        XCTAssertEqual(result[0].value, "Kunst \"und\" Kultur")
        XCTAssertEqual(result[1].value, "Zurück")
        XCTAssertEqual(result[2].value, "Bitte wähle deinen Geburtstag aus")
        
        XCTAssertEqual(result[0].message, "The string for \"the art and culture category")
        XCTAssertEqual(result[1].message, "String for back operation")
        XCTAssertEqual(result[2].message, "Select your birhtday")
    }
    
    func testInputValidWithMessageContainingLicenseHeader() {
        let inputString =
        """
//
//  ParserIsolationTests.swift
//  LocalizationEditor
//
//  Created by Andreas Neusüß on 30.12.18.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//
/* Another header */

/* The string for "the art and culture category */
"ART_"AND"_CULTURE" = "Kunst "und" Kultur";

/* String for back operation */
"BACK" = "Zurück";

/* Select your birhtday */
"BIRTHDAY_SELECT" = "Bitte wähle deinen Geburtstag aus";
"""
        let parser = Parser(input: inputString)
        let result = try! parser.parse()
        
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].key, "ART_\"AND\"_CULTURE")
        XCTAssertEqual(result[1].key, "BACK")
        XCTAssertEqual(result[2].key, "BIRTHDAY_SELECT")
        
        XCTAssertEqual(result[0].value, "Kunst \"und\" Kultur")
        XCTAssertEqual(result[1].value, "Zurück")
        XCTAssertEqual(result[2].value, "Bitte wähle deinen Geburtstag aus")
        
        XCTAssertEqual(result[0].message, "The string for \"the art and culture category")
        XCTAssertEqual(result[1].message, "String for back operation")
        XCTAssertEqual(result[2].message, "Select your birhtday")
    }
    
    func testInputValidWithTrailingMessage() {
        let inputString =
 """
 //
 //  ParserIsolationTests.swift
 //  LocalizationEditor
 //
 //  Created by Andreas Neusüß on 30.12.18.
 //  Copyright © 2018 Igor Kulman. All rights reserved.
 //
 
 "ART_"AND"_CUL\nTURE" = "Kunst "und" Kultur"; /* The string for "the art and culture category */
 
 "BACK" = "Zurück"; /* String for back operation */
 
 "BIRTHDAY_SELECT" = "Bitte wähle deinen Geburtstag aus"; /* Select your birhtday */
 """

        let parser = Parser(input: inputString)
        let result = try! parser.parse()
        
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].key, "ART_\"AND\"_CUL\nTURE")
        XCTAssertEqual(result[1].key, "BACK")
        XCTAssertEqual(result[2].key, "BIRTHDAY_SELECT")
        
        XCTAssertEqual(result[0].value, "Kunst \"und\" Kultur")
        XCTAssertEqual(result[1].value, "Zurück")
        XCTAssertEqual(result[2].value, "Bitte wähle deinen Geburtstag aus")
        
        XCTAssertEqual(result[0].message, "The string for \"the art and culture category")
        XCTAssertEqual(result[1].message, "String for back operation")
        XCTAssertEqual(result[2].message, "Select your birhtday")
    }
    
    func testMalformattedInput() {
        let inputString1 =
        """
"ART_"AND"_CULTURE" = "Kunst "und" Kultur"
"""
        let parser1 = Parser(input: inputString1)
        let result1 = try? parser1.parse()
        XCTAssertNil(result1)
        
        let inputString2 =
        """
"ART_"AND="_CULTURE" = "Kunst= "und" Kultur"
"""
        let parser2 = Parser(input: inputString2)
        let result2 = try? parser2.parse()
        XCTAssertNil(result2)
        
        
        let inputString3 =
        """
"ART_"AND"_CULTURE" = ;
"""
        let parser3 = Parser(input: inputString3)
        let result3 = try? parser3.parse()
        XCTAssertNil(result3)
        
    }
    
}
