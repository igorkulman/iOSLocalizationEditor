//
//  LGParser.swift
//  LocalizationEditor
//
//  Given loaded a Loaded Apple LG localization for specified language.
//  Locate localization that are  missing, and update them if they exist in Apple Glossary
//  Help menu:
//
// Apple Internationalization and Localization
// https://developer.apple.com/internationalization/
// https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/Introduction/Introduction.html

// Language and Locale IDs (two-letter ISO 639-1 standard)
// https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/LanguageandLocaleIDs/LanguageandLocaleIDs.html#//apple_ref/doc/uid/10000171i-CH15-SW1

// There is a nice step-by-step instruction (see 'Localizing Strings Files Using AppleGlot')
// Adding Languages.
// https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/LocalizingYourApp/LocalizingYourApp.html#//apple_ref/doc/uid/10000171i-CH5-SW2
// Extracting from source file strings.
// https://rderik.com/blog/text-extraction-tools-for-macos-and-ios-app-localization/
// google translate
// https://translate.google.ca/?hl=%@&tab=kT#view=home&op=translate&sl=auto&tl=%@&text=%@
// https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=11&cad=rja&uact=8&ved=2ahUKEwii7cz7wdTlAhWWTxUIHUSIDQkQFjAKegQIBhAB&url=https%3A%2F%2Fglot-multilingual-translation-dictionary-for-english-dutch--ios.soft112.com%2Fdownload.html&usg=AOvVaw2PwKkfRCkPRe_DJlpaN7x5

//  Created by Mark Fleming
//  Copyright © 2019 Mark Fleming. All rights reserved.
//

import Cocoa
import Foundation
import os

/**
 The Parser is responsible for transferring an AppleGlot Glossary string into an array of model objects.
 
 The input is given as an argument during initialization. Call ```parse``` to start the process.
 */
final class LGParser: NSObject, XMLParserDelegate {
   // var description: String
    override var description: String {
               return "\(eLGBaseLocal): \(eLGTranLocal) -> \(LGresults.count) translations (\(fileList))"
           }

    // MARK: Debug description
    override var debugDescription: String {
            return "\(eLGBaseLocal): \(eLGTranLocal) -> \(LGresults.count) translations (\(fileList))"
        }

    private weak var tableView: NSTableView!

    // XML Parser..
        fileprivate var LGresults: [LocalizationString] = .init()
        fileprivate var elementLGName: String = ""
        fileprivate var eLGBase: String = ""
        fileprivate var eLGBaseLocal: String = ""
        fileprivate var eLGTran: String = ""
        fileprivate var eLGTranLocal: String = ""
        fileprivate var fileList: [URL]

    ///
    /// - Parameter input: The input from which model information should be extracted.
    init(urls: [URL], theTableView: NSTableView!) {
        self.fileList = urls
        self.tableView = theTableView
    }

    /// Call this function to start the parsing process. Will return the extracted model information or throw an error if the parser could not make any sense from the input. In this case, maybe a fallback to another extraction method should be used.
    ///
    /// - Returns: The model data.
    /// - Throws: A ```ParserError``` when the input string could not be parsed.
    func parse() throws -> [LocalizationString] {

            self.fileList.forEach({ aUrl in // Process/merge all .lg files.
                os_log("\n\nLGParser\t%@\n", type: OSLogType.info, aUrl.description)

                if let parser = XMLParser(contentsOf: aUrl) {
                parser.delegate = self
                parser.parse()

                // self.LGresults = self.LGresults.uniques
                self.LGresults = self.LGresults.sorted()
                let tcnt = self.LGresults.count
                // remove duplicates from glossary
                let mySet = Set(self.LGresults)
                // dump(mySet)
                self.LGresults = Array(mySet)
                os_log("\n>>> LGresults %d terms, removed... %d duplicates", type: OSLogType.debug, self.LGresults.count, tcnt - self.LGresults.count)
                // os_log("\n>>>\nLGresults... %d\n%@", type: OSLogType.info, self.LGresults.count, self.LGresults.description)
                } else {
                     os_log("\n>>> XMLParser failed", type: OSLogType.info)
                } //end XMLParser
            })

        os_log("\n>>> Loaded [%@] -> [%@] ... %d", type: OSLogType.info, self.eLGBaseLocal, self.eLGTranLocal, self.LGresults.count)

        return LGresults
    }

    /// Apply to missing translations (set filtering?) before process to translate only missing items.
    ///  ie.   self.dataSource.filter(by: .missing, searchString: self.currentSearchTerm)
    /// - Parameter theGroup: the currently loaded .string files.
    /// - Parameter dataSource: the currently loaded .string files.
    /// - Returns: # item transalted with loaded Glossary
    func applytranslation(theGroup: LocalizationGroup, dataSource: LocalizationsDataSource) -> Int {
    let rowcnt = dataSource.numberOfRows(in: self.tableView)
    var baseTerm: String = ""
    var row: Int = 0
    //  let theGroup: LocalizationGroup = self.dataSource.getSelectedGroup()
    os_log("\n>>> [%@] -> [%@] appling to %@... %d", type: OSLogType.debug, self.eLGBaseLocal, self.eLGTranLocal, theGroup.name, self.LGresults.count)

    // confirm we have source and trans language and apply to missing.
    let lang = dataSource.selectGroupAndGetLanguages(for: theGroup.name)
  //  dump(lang)    // list languages loaded for translation.

    if lang.contains(self.eLGBaseLocal) &&
       lang.contains(self.eLGTranLocal) {
        let base: Localization = theGroup.localizations.first(where: { $0.language == self.eLGBaseLocal })!
        let toDo: Localization! = theGroup.localizations.first(where: { $0.language == self.eLGTranLocal })!

        if toDo == nil {
            if lang.contains(self.eLGTranLocal) {
                os_log("need to setup for transaltion of [%@]", type: OSLogType.info, self.eLGTranLocal)
                return -2
            }
        }

        // Key to transaltion, lookup base value to lookup term.
        // Note: Key sometime are often not same as term.  We also ignore case.
        var cnt: Int = 0
        while row < rowcnt {
            let akey = dataSource.getKey(row: row)  // key for missing term.
            if let existing = base.translations.first(where: { $0.key == akey }) {
                baseTerm = existing.value;  // base translated term to translate.
                os_log("%d. key [%@] -> Base Term: [%@]", type: OSLogType.debug, row, akey ?? "", baseTerm)
            } else {
                os_log("%d. base is missing key [%@]", type: OSLogType.debug, row, akey ?? "")
            }

                // lookup by key in Glossary
            var value: LocalizationString? =  self.LGresults.first(where: { $0.key == akey?.lowercased() })
            if value == nil {
                // key does not exists, so try by term of base translation.
                value = self.LGresults.first(where: { $0.key == baseTerm.lowercased() })
                if value != nil {
                    os_log("%d. [%@] -> [%@] by term %@", type: OSLogType.debug, row, akey ?? "", value!.value, baseTerm)
                }
            } else {
                os_log("%d. [%@] -> [%@] by key %@", type: OSLogType.debug, row, akey ?? "", value!.value, baseTerm)
            }

            if value != nil && akey != nil {
                // Found translation
                 let aMsg = dataSource.getMessage(row: row)
                dataSource.updateLocalization(language: self.eLGTranLocal, key: akey!, with: value!.value, message: aMsg)
                cnt += 1
              //  dump(akey) dump(value) dump(aMsg)
            }
            row += 1
        }
        return cnt
    } else {
        os_log("\n>>>%@ not setup for this translation [%@] -> [%@]", type: OSLogType.error, theGroup.name, self.eLGBaseLocal, self.eLGTranLocal)
    }
        return -1
}

    /* Sample LG XML file:

    <?xml version="1.0" encoding="UTF-8"?>
    <Proj>
      <ProjName>SharedFileList</ProjName>
      <File>
        <Filepath>SharedFileList/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/SharedFileList.framework/Versions/A/Resources/en.lproj/Localized.strings</Filepath>
        <TextItem>
          <Description>
      Localized.strings
      SharedFileList

      Created by Alex Carter on 12/20/14.
      Copyright © 2014 Apple Inc. All rights reserved.
    </Description>
          <Position>PUBLIC_SHAREPOINT_NAME</Position>
          <TranslationSet>
            <base loc="en">%@’s Public Folder</base>
            <tran loc="ja">%@のパブリックフォルダ</tran>
          </TranslationSet>
        </TextItem>
      </File>
    </Proj>
    */

    // 1 Parse XML file...
    //   Look for <TranslationSet> term a build LocalizationString for each.
    //   Extract the base language and translated language from atributes "loc"
    //
    //  <TranslationSet>
    //  <base loc="en">%@’s Public Folder</base>
    //  <tran loc="ja">%@のパブリックフォルダ</tran>
    //  </TranslationSet>

        internal func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [ : ]) {

         //  os_log("parser 1 %@ - %@", type: OSLogType.info, elementName, attributeDict.description)
            self.elementLGName = elementName
            if elementName == "TranslationSet" {
              //  os_log("parser 1 qName - %@ - %@", type: OSLogType.info, qName!.description)
                eLGBase = String()
                eLGTran = String()
            } else
            /*
            if elementName == "TextItem" {
             //   os_log("parser 1 %@ - %@", type: OSLogType.info, elementName, attributeDict.description)
            } else
            if elementName == "Description" {
             //   os_log("parser 1 %@ - %@", type: OSLogType.info, elementName, attributeDict.description)
            } else
            if elementName == "Position" {
             //   os_log("parser 1 %@ - %@", type: OSLogType.info, elementName, attributeDict.description)
            } else
                */
            if elementName == "base" {
                eLGBaseLocal = attributeDict["loc"] ??  "en"
            } else
            if elementName == "tran" {
                eLGTranLocal = attributeDict["loc"] ??  "en"
            } else {
         //   os_log("parser 1 started ignore - %@", type: OSLogType.info, elementName)
            }
    }

    // 2 when TranslationSet is complete make LocalizationString from values collected.
        internal func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {

        if elementName == "TranslationSet" {
         //   os_log("parser 2 - TranslationSet\n\t%@ [%@] - %@ [%@]", type: OSLogType.info, eLGBase, eLGBaseLocal, eLGTran, eLGTranLocal  )
            let entry = LocalizationString(key: eLGBase.unescaped.lowercased(), value: eLGTran.unescaped, message: eLGTranLocal)
            LGresults.append(entry)

        } else {
        //    os_log("parser 2  - %@ Ended", type: OSLogType.info, elementName )
            }
    }

    // 3 Collect the data for the transaltions
        internal func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        if !data.isEmpty {
            if self.elementLGName == "base" {
                eLGBase += data
            } else if self.elementLGName == "tran" {
                eLGTran += data
            }
        }
    }

}
