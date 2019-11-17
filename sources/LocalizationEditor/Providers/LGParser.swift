//
//  LGParser.swift
//  LocalizationEditor
//
//  Created by Andreas Neusüß on 25.12.18.
//  Copyright © 2018 Andreas Neusüß. All rights reserved.
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

  //  private let dataSource = LocalizationsDataSource()
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
                os_log("\n>>> LGresults %d terms, removed... %d duplicates", type: OSLogType.info, self.LGresults.count, tcnt - self.LGresults.count)
                // os_log("\n>>>\nLGresults... %d\n%@", type: OSLogType.info, self.LGresults.count, self.LGresults.description)
                } else {
                     os_log("\n>>> XMLParser failed", type: OSLogType.info)
                } //end XMLParser
            })

        os_log("\n>>> [%@] -> [%@] ... %d", type: OSLogType.info, self.eLGBaseLocal, self.eLGTranLocal, self.LGresults.count)

        return LGresults
    }

            // Apply to missing translations (set filtering?) before process to translate only missing items.
    func applytranslation(theGroup: LocalizationGroup, dataSource: LocalizationsDataSource) {
    //   self.dataSource.filter(by: .missing, searchString: self.currentSearchTerm)
    let rowcnt = dataSource.numberOfRows(in: self.tableView)
    var baseTerm: String = ""
    var row: Int = 0
    //  let theGroup: LocalizationGroup = self.dataSource.getSelectedGroup()
    os_log("\n>>> [%@] -> [%@] appling to %@... %d", type: OSLogType.info, self.eLGBaseLocal, self.eLGTranLocal, theGroup.name, self.LGresults.count)

    // confirm we have source and trans language and apply to missing.
    let lang = dataSource.selectGroupAndGetLanguages(for: theGroup.name)
    dump(lang)
    if lang.contains(self.eLGBaseLocal) && lang.contains(self.eLGTranLocal) {
        let base: Localization = theGroup.localizations.first(where: { $0.language == self.eLGBaseLocal })!
        dump(base)

        let toDo: Localization! = theGroup.localizations.first(where: { $0.language == self.eLGTranLocal })!
        if toDo == nil {
            os_log("need to setup for transaltion of [%@]", type: OSLogType.info, self.eLGTranLocal)
        }
       // dump(toDo)
        while row < rowcnt {
            let akey = dataSource.getKey(row: row)
            if let existing = base.translations.first(where: { $0.key == akey }) {
                baseTerm = existing.value;  // base translated term from key.
                os_log("%d. [%@] -> [%@] -- lookup 2", type: OSLogType.info, row, akey ?? "", baseTerm)

                   }
        if true {

            let aMsg = dataSource.getMessage(row: row)
            //     let value: LocalizationString? =  self.LGresults.first(where: { $0.key.caseInsensitiveCompare(akey) == .orderedSame })

            var value: LocalizationString? =  self.LGresults.first(where: { $0.key == akey?.lowercased() })
            if value != nil {
                value = self.LGresults.first(where: { $0.key == baseTerm.lowercased() })
            }
            if value != nil && akey != nil {
                dataSource.updateLocalization(language: self.eLGTranLocal, key: akey!, with: value!.value, message: aMsg)
            //    self.dataSource.updateLocalization(self.eLGTranLocal, key: String, with: value: String, message: String?)
              //  dump(akey) dump(value) dump(aMsg)
            }

        } else {
            let akey = dataSource.getKey(row: row)
            let aMsg = dataSource.getMessage(row: row)
            //     let value: LocalizationString? =  self.LGresults.first(where: { $0.key.caseInsensitiveCompare(akey) == .orderedSame })

            let value: LocalizationString? =  self.LGresults.first(where: { $0.key == akey?.lowercased() })
            if value != nil && akey != nil {
                dataSource.updateLocalization(language: self.eLGTranLocal, key: akey!, with: value!.value, message: aMsg)
            //    self.dataSource.updateLocalization(self.eLGTranLocal, key: String, with: value: String, message: String?)
              //  dump(akey) dump(value) dump(aMsg)
            }
        }
         //   os_log("%d. [%@] -> [%@] %@", type: OSLogType.info, row, akey ?? "nil", aMsg  ?? "nil", (value?.value ?? nil) ??    )
            row += 1
        }
    } else {
        os_log("\n>>>%@ not setup for this translation [%@] -> [%@]", type: OSLogType.error, theGroup.name, self.eLGBaseLocal, self.eLGTranLocal)
    }

}

    // 1
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

    // 2
        internal func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {

        if elementName == "TranslationSet" {
         //   os_log("parser 2 - TranslationSet\n\t%@ [%@] - %@ [%@]", type: OSLogType.info, eLGBase, eLGBaseLocal, eLGTran, eLGTranLocal  )
            let entry = LocalizationString(key: eLGBase.unescaped.lowercased(), value: eLGTran.unescaped, message: eLGTranLocal)
            LGresults.append(entry)

        } else {
        //    os_log("parser 2  - %@ Ended", type: OSLogType.info, elementName )
            }
    }

    // 3
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
