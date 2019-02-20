//
//  ViewController.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import Cocoa

final class ViewController: NSViewController {
    // MARK: - Outlets

    @IBOutlet private weak var tableView: NSTableView!
    @IBOutlet private weak var selectButton: NSPopUpButton!
    @IBOutlet private weak var progressIndicator: NSProgressIndicator!
    @IBOutlet private var defaultSelectItem: NSMenuItem!
    @IBOutlet private weak var searchField: NSSearchField!
    @IBOutlet private weak var filterButton: NSPopUpButton!

    // MARK: - Properties

    private let dataSource = LocalizationsDataSource()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupMenu()
        setupSearch()
        setupFilter()
        setupData()
    }

    // MARK: - Setup

    private func setupMenu() {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.openFolderMenuItem.action = #selector(ViewController.openAction(sender:))
        selectButton.menu?.removeAllItems()
        selectButton.menu?.addItem(defaultSelectItem)
    }

    private func setupData() {
        let cellIdentifiers = [KeyCell.identifier, LocalizationCell.identifier]
        cellIdentifiers.forEach { identifier in
            let cell = NSNib(nibNamed: identifier, bundle: nil)
            tableView.register(cell, forIdentifier: NSUserInterfaceItemIdentifier(rawValue: identifier))
        }

        tableView.delegate = self
        tableView.dataSource = dataSource
        tableView.allowsColumnResizing = true
        tableView.usesAutomaticRowHeights = true
    }

    private func setupSearch() {
        searchField.delegate = self
        searchField.stringValue = ""

        _ = searchField.resignFirstResponder()
    }

    private func setupFilter() {
        filterButton.select(filterButton.item(at: 0)!)
    }

    private func setupSetupLocalizationSelectionMenu(files: [LocalizationGroup]) {
        selectButton.menu?.removeAllItems()
        files.map({ NSMenuItem(title: $0.name, action: #selector(ViewController.selectAction(sender:)), keyEquivalent: "") }).forEach({ selectButton.menu?.addItem($0) })
    }

    private func reloadData(with languages: [String], title: String?) {
        setupSearch()
        setupFilter()

        let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        view.window?.title = title.flatMap({ "\(appName) [\($0)]" }) ?? appName

        let columns = tableView.tableColumns
        columns.forEach {
            self.tableView.removeTableColumn($0)
        }

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("key"))
        column.title = ""
        tableView.addTableColumn(column)

        languages.forEach { language in
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(language))
            if language.count == 2 || (language.count == 4 && language.contains("-")) { // country code
                column.title = "\(emojiFlag(countryCode: language)) \(language.uppercased())"
            } else {
                column.title = language
            }
            column.maxWidth = 460
            column.minWidth = 50
            self.tableView.addTableColumn(column)
        }

        tableView.reloadData()

        // Also resize the columns:
        tableView.sizeToFit()
    }

    private func emojiFlag(countryCode: String) -> String {
        var string = ""
        var country = (countryCode == "en" ? "gb" : countryCode).uppercased()
        for unicodeScalar in country.unicodeScalars {
            if let scalar = UnicodeScalar(127397 + unicodeScalar.value) {
                string.append(String(scalar))
            }
        }
        return string
    }

    private func filter() {
        let filter = filterButton.selectedItem?.tag == 1 ? Filter.missing : Filter.all
        dataSource.filter(by: filter, searchString: searchField.stringValue)
        tableView.reloadData()
    }

    // MARK: - Actions

    @IBAction @objc private func selectAction(sender: NSMenuItem) {
        let groupName = sender.title
        let languages = dataSource.selectGroupAndGetLanguages(for: groupName)

        reloadData(with: languages, title: title)
    }

    @IBAction private func filterAll(_ sender: NSMenuItem) {
        filter()
    }

    @IBAction private func filterMissing(_ sender: NSMenuItem) {
        filter()
    }

    @IBAction @objc private func openAction(sender _: NSMenuItem) {
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
                    self.setupSetupLocalizationSelectionMenu(files: localizationFiles)
                    self.selectButton.selectItem(at: self.selectButton.indexOfItem(withTitle: title))
                } else {
                    self.setupMenu()
                }
            }
        }
    }
}

// MARK: - Search

extension ViewController: NSSearchFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        filter()
    }
}

// MARK: - Delegate

extension ViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let identifier = tableColumn?.identifier else {
            return nil
        }

        switch identifier.rawValue {
        case "key":
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: KeyCell.identifier), owner: self)! as! KeyCell
            cell.key = dataSource.getKey(row: row)
            cell.message = dataSource.getMessage(row: row)
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

extension ViewController: LocalizationCellDelegate {
    func userDidUpdateLocalizationString(language: String, key: String, with value: String, message: String?) {
        dataSource.updateLocalization(language: language, key: key, with: value, message: message)
    }
}

extension ViewController: NSTableViewClickableDelegate {
    @nonobjc func tableView(_ tableView: NSTableView, didClickRow row: Int, didClickColumn column: Int) {
        guard column > 0 else { // ignore click on the key label
            return
        }

        guard let cell = tableView.view(atColumn: column, row: row, makeIfNecessary: false) as? LocalizationCell else {
            return
        }

        cell.focus()
    }
}
