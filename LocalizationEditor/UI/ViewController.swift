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

    func reloadData() {
        let columns = tableView.tableColumns
        columns.forEach {
            self.tableView.removeTableColumn($0)
        }

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("key"))
        column.title = ""
        column.width = 200
        tableView.addTableColumn(column)

        dataSource.localizations.forEach { localization in
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(localization.language))
            column.title = localization.language.uppercased()
            column.width = (self.view.bounds.width - 200.0) / CGFloat(self.dataSource.localizations.count)
            self.tableView.addTableColumn(column)
        }

        tableView.reloadData()
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
                    self.dataSource.load(folder: url)
                    self.reloadData()
                }
            }
        }
    }
}

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
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: LocalizationCell.identifier), owner: self)! as! LocalizationCell
            let value = dataSource.getLocalization(language: identifier.rawValue, row: row)
            cell.value = value
            return cell
        }
    }
}
