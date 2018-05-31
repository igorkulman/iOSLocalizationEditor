//
//  ViewController.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Teamwire. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    // MARK: - Outlets

    @IBOutlet private weak var tableView: NSTableView!
    @IBOutlet private weak var progressIndicator: NSProgressIndicator!

    // MARK: - Properties

    private let dataSource = LocalizationsDataSource()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupMenu()
        setupData()
    }

    // MARK: - Setup

    private func setupMenu() {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.openFolderMenuItem.action = #selector(ViewController.openAction(sender:))
    }

    private func setupData() {
        let cellIdentifiers = [KeyCell.identifier, LocalizationCell.identifier]
        cellIdentifiers.forEach { identifier in
            let cell = NSNib(nibNamed: NSNib.Name(rawValue: identifier), bundle: nil)
            tableView.register(cell, forIdentifier: NSUserInterfaceItemIdentifier(rawValue: identifier))
        }

        tableView.delegate = self
        tableView.dataSource = dataSource
    }

    private func reloadData(with languages: [String]) {
        let columns = tableView.tableColumns
        columns.forEach {
            self.tableView.removeTableColumn($0)
        }

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("key"))
        column.title = ""
        tableView.addTableColumn(column)

        languages.forEach { language in
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(language))
            column.title = language == "Base" ? language : "\(emojiFlag(countryCode: language)) \(language.uppercased())"
            self.tableView.addTableColumn(column)
        }

        tableView.reloadData()
    }

    private func emojiFlag(countryCode: String) -> String {
        var string = ""
        var country = countryCode.uppercased()
        for uS in country.unicodeScalars {
            if let scalar = UnicodeScalar(127_397 + uS.value) {
                string.append(String(scalar))
            }
        }
        return string
    }

    @objc func openAction(sender _: NSMenuItem) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false
        openPanel.begin { [unowned self] (result) -> Void in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                if let url = openPanel.url {
                    self.progressIndicator.startAnimation(self)
                    self.dataSource.load(folder: url) { [unowned self] languages in
                        self.reloadData(with: languages)
                        self.progressIndicator.stopAnimation(self)
                    }
                }
            }
        }
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
            return cell
        default:
            let language = identifier.rawValue
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: LocalizationCell.identifier), owner: self)! as! LocalizationCell
            cell.delegate = self
            cell.language = language
            cell.value = dataSource.getLocalization(language: language, row: row)
            return cell
        }
    }
}

extension ViewController: LocalizationCellDelegate {
    func userDidUpdateLocalizationString(language: String, string: LocalizationString, with value: String) {
        dataSource.updateLocalization(language: language, string: string, with: value)
    }
}
