//
//  ViewController.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import Cocoa
import os
/**
Protocol for announcing changes to the toolbar. Needed because the VC does not have direct access to the toolbar (handled by WindowController)
 */
protocol ViewControllerDelegate: AnyObject {
    /**
     Invoked when localization groups should be set in the toolbar's dropdown list
     */
    func shouldSetLocalizationGroups(groups: [LocalizationGroup])

    /**
     Invoiked when search and filter should be reset in the toolbar
     */
    func shouldResetSearchTermAndFilter()

    /**
     Invoked when localization group should be selected in the toolbar's dropdown list
     */
    func shouldSelectLocalizationGroup(title: String)
}

final class ViewController: NSViewController, XMLParserDelegate {
    enum FixedColumn: String {
        case key
        case actions
    }

    // MARK: - Outlets

    @IBOutlet private weak var tableView: NSTableView!
    @IBOutlet private weak var progressIndicator: NSProgressIndicator!

    // MARK: - Properties

    weak var delegate: ViewControllerDelegate?

    private var currentFilter: Filter = .all
    private var currentSearchTerm: String = ""
    private let dataSource = LocalizationsDataSource()
    private var presendedAddViewController: AddViewController?

// XML Parser..
    fileprivate var LGresults: [LocalizationString] = .init()
    private var elementLGName: String = ""
    private var eLGBase: String = ""
    private var eLGBaseLocal: String = ""
    private var eLGTran: String = ""
    private var eLGTranLocal: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        setupData()
    }

	// MARK: - XML of Apple Glossary (.lg)

    private func openLGFile() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.begin { [unowned self] result -> Void in
            guard result.rawValue == NSApplication.ModalResponse.OK.rawValue
                else {
                return
            }
            os_log("\nSelected LG...", type: OSLogType.info)

            openPanel.urls.forEach({ aUrl in // Process/merge all .lg files.
                os_log("\n\t%@\n", type: OSLogType.info, aUrl.description)

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
                }
             })

            // dump(myArray)
            // Apply to missing translations (set filtering?)
            self.dataSource.filter(by: .missing, searchString: self.currentSearchTerm)
            let theGroup: LocalizationGroup = self.dataSource.getSelectedGroup()
            os_log("\n>>> [%@] -> [%@] appling to %@... %d", type: OSLogType.info, self.eLGBaseLocal, self.eLGTranLocal, theGroup.name, self.LGresults.count)

            // confirm we have source and trans language and apply to missing.
            let lang = self.dataSource.selectGroupAndGetLanguages(for: theGroup.name)
            // dump(lang)
            if lang.contains(self.eLGBaseLocal) && lang.contains(self.eLGTranLocal) {
                let base = theGroup.localizations.first(where: { $0.language == self.eLGBaseLocal })!
              // dump(base)

                let toDo = theGroup.localizations.first(where: { $0.language == self.eLGTranLocal })!
               // dump(toDo)
                let rowcnt = self.dataSource.numberOfRows(in: self.tableView)
                var row: Int = 0
                while row < rowcnt {
                    let akey = self.dataSource.getKey(row: row)
                    let aMsg = self.dataSource.getMessage(row: row)
                    let value: LocalizationString? =  self.LGresults.first(where: { $0.key == akey })
                    if value != nil && akey != nil {
                        self.dataSource.updateLocalization(language: self.eLGTranLocal, key: akey!, with: value!.value, message: aMsg)
                    //    self.dataSource.updateLocalization(self.eLGTranLocal, key: String, with: value: String, message: String?)
                      //  dump(akey)
                      //   dump(value)
                      //   dump(aMsg)
                    }

                 //   os_log("%d. [%@] -> [%@] %@", type: OSLogType.info, row, akey ?? "nil", aMsg  ?? "nil", (value?.value ?? nil) ??    )
                    row += 1
                }



            } else {
                os_log("\n>>>%@ not setup for this translation [%@] -> [%@]", type: OSLogType.error, theGroup.name, self.eLGBaseLocal,self.eLGTranLocal)
            }

            self.dataSource.filter(by: self.currentFilter, searchString: self.currentSearchTerm)
            self.tableView.reloadData()

        } // end OpenPanel
    }

// 1
//  <TranslationSet>
//  <base loc="en">%@’s Public Folder</base>
//  <tran loc="ja">%@のパブリックフォルダ</tran>
//  </TranslationSet>

    internal func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [ : ]) {

    //    os_log("parser 1 %@ - %@", type: OSLogType.info, elementName, attributeDict.description)
        self.elementLGName = elementName
        if elementName == "TranslationSet" {
          //  os_log("parser 1 qName - %@ - %@", type: OSLogType.info, qName!.description)
            eLGBase = String()
            eLGTran = String()
        } else
        if elementName == "Position" {
         //   os_log("parser 1 %@ - %@", type: OSLogType.info, elementName, attributeDict.description)

        } else
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
        let entry = LocalizationString(key: eLGBase.unescaped, value: eLGTran.unescaped, message: eLGTranLocal)
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

    // MARK: - Setup

    private func setupData() {
        let cellIdentifiers = [KeyCell.identifier, LocalizationCell.identifier, ActionsCell.identifier]
        cellIdentifiers.forEach { identifier in
            let cell = NSNib(nibNamed: identifier, bundle: nil)
            tableView.register(cell, forIdentifier: NSUserInterfaceItemIdentifier(rawValue: identifier))
        }

        tableView.delegate = self
        tableView.dataSource = dataSource
        tableView.allowsColumnResizing = true
        tableView.usesAutomaticRowHeights = true

        tableView.selectionHighlightStyle = .none
    }

    private func reloadData(with languages: [String], title: String?) {
        delegate?.shouldResetSearchTermAndFilter()

        let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        view.window?.title = title.flatMap({ "\(appName) [\($0)]" }) ?? appName

        let columns = tableView.tableColumns
        columns.forEach {
            self.tableView.removeTableColumn($0)
        }

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(FixedColumn.key.rawValue))
        column.title = "key".localized
        tableView.addTableColumn(column)

        languages.forEach { language in
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(language))
            column.title = Flag(languageCode: language).emoji
            column.maxWidth = 460
            column.minWidth = 50
            self.tableView.addTableColumn(column)
        }

        let actionsColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(FixedColumn.actions.rawValue))
        actionsColumn.title = "actions".localized
        actionsColumn.maxWidth = 48
        actionsColumn.minWidth = 32
        tableView.addTableColumn(actionsColumn)

        tableView.reloadData()

        // Also resize the columns:
        tableView.sizeToFit()

        // Needed to properly size the actions column
        DispatchQueue.main.async {
            self.tableView.sizeToFit()
            self.tableView.layout()
        }
    }

    private func filter() {
        dataSource.filter(by: currentFilter, searchString: currentSearchTerm)
        tableView.reloadData()
    }

    private func openFolder() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false
        openPanel.begin { [unowned self] result -> Void in
            guard result.rawValue == NSApplication.ModalResponse.OK.rawValue, let url = openPanel.url else {
                return
            }

            self.progressIndicator.startAnimation(self)
            self.dataSource.load(folder: url) { [unowned self] languages, title, localizationFiles in
                self.reloadData(with: languages, title: title)
                self.progressIndicator.stopAnimation(self)

                if let title = title {
                    self.delegate?.shouldSetLocalizationGroups(groups: localizationFiles)
                    self.delegate?.shouldSelectLocalizationGroup(title: title)
                }
            }
        }
    }
}

// MARK: - NSTableViewDelegate

extension ViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let identifier = tableColumn?.identifier else {
            return nil
        }

        switch identifier.rawValue {
        case FixedColumn.key.rawValue:
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: KeyCell.identifier), owner: self)! as! KeyCell
            cell.key = dataSource.getKey(row: row)
            cell.message = dataSource.getMessage(row: row)
            return cell
        case FixedColumn.actions.rawValue:
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: ActionsCell.identifier), owner: self)! as! ActionsCell
            cell.delegate = self
            cell.key = dataSource.getKey(row: row)
            return cell
        default:
            let language = identifier.rawValue
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: LocalizationCell.identifier), owner: self)! as! LocalizationCell
            cell.delegate = self
            cell.language = language
            cell.value = row < dataSource.numberOfRows(in: tableView) ? dataSource.getLocalization(language: language, row: row) : nil
            return cell
        }
    }
}

// MARK: - LocalizationCellDelegate

extension ViewController: LocalizationCellDelegate {
    func userDidUpdateLocalizationString(language: String, key: String, with value: String, message: String?) {
        dataSource.updateLocalization(language: language, key: key, with: value, message: message)
    }
}

// MARK: - ActionsCellDelegate

extension ViewController: ActionsCellDelegate {
    func userDidRequestRemoval(of key: String) {
        dataSource.deleteLocalization(key: key)

        // reload keeping scroll position
        let rect = tableView.visibleRect
        filter()
        tableView.scrollToVisible(rect)
    }
}

// MARK: - WindowControllerToolbarDelegate

extension ViewController: WindowControllerToolbarDelegate {
    func userDidRequestApplyGlossary() {
        // Not implemented yet..

		openLGFile()

    }

    /**
     Invoked when user requests adding a new translation
     */
    func userDidRequestAddNewTranslation() {
        let addViewController = storyboard!.instantiateController(withIdentifier: "Add") as! AddViewController
        addViewController.delegate = self
        presendedAddViewController = addViewController
        presentAsSheet(addViewController)
    }

    /**
     Invoked when user requests filter change

     - Parameter filter: new filter setting
     */
    func userDidRequestFilterChange(filter: Filter) {
        guard currentFilter != filter else {
            return
        }

        currentFilter = filter
        self.filter()
    }

    /**
     Invoked when user requests searching

     - Parameter searchTerm: new search term
     */
    func userDidRequestSearch(searchTerm: String) {
        guard currentSearchTerm != searchTerm else {
            return
        }

        currentSearchTerm = searchTerm
        filter()
    }

    /**
     Invoked when user request change of the selected localization group

     - Parameter group: new localization group title
     */
    func userDidRequestLocalizationGroupChange(group: String) {
        let languages = dataSource.selectGroupAndGetLanguages(for: group)
        reloadData(with: languages, title: title)
    }

    /**
     Invoked when user requests opening a folder
     */
    func userDidRequestFolderOpen() {
        openFolder()
    }
}

// MARK: - AddViewControllerDelegate

extension ViewController: AddViewControllerDelegate {
    func userDidCancel() {
        dismiss()
    }

    func userDidAddTranslation(key: String, message: String?) {
        dismiss()

        dataSource.addLocalizationKey(key: key, message: message)
        filter()

        if let row = dataSource.getRowForKey(key: key) {
            DispatchQueue.main.async {
                self.tableView.scrollRowToVisible(row)
            }
        }
    }

    private func dismiss() {
        guard let presendedAddViewController = presendedAddViewController else {
            return
        }

        dismiss(presendedAddViewController)
    }
}
