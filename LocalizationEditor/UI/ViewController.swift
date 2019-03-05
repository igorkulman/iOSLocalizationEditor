//
//  ViewController.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import Cocoa

protocol ViewControllerDelegate: AnyObject {
    func setStringTableLocalizationGroups(groups: [LocalizationGroup])
    func resetSearchAndFilter()
    func setSelectedLocalizationGroup(title: String)
}

final class ViewController: NSViewController {
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
        let cellIdentifiers = [KeyCell.identifier, LocalizationCell.identifier, ActionsCell.identifier]
        cellIdentifiers.forEach { identifier in
            let cell = NSNib(nibNamed: identifier, bundle: nil)
            tableView.register(cell, forIdentifier: NSUserInterfaceItemIdentifier(rawValue: identifier))
        }

        tableView.delegate = self
        tableView.dataSource = dataSource
        tableView.allowsColumnResizing = true
        tableView.usesAutomaticRowHeights = true
    }

    private func setupSetupLocalizationSelectionMenu(files: [LocalizationGroup]) {
        delegate?.setStringTableLocalizationGroups(groups: files)
    }

    private func reloadData(with languages: [String], title: String?) {
        delegate?.resetSearchAndFilter()

        let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        view.window?.title = title.flatMap({ "\(appName) [\($0)]" }) ?? appName

        let columns = tableView.tableColumns
        columns.forEach {
            self.tableView.removeTableColumn($0)
        }

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(FixedColumn.key.rawValue))
        column.title = "Key"
        column.maxWidth = 460
        column.minWidth = 50
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

        let actionsColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(FixedColumn.actions.rawValue))
        actionsColumn.title = "Actions"
        actionsColumn.maxWidth = 48
        actionsColumn.minWidth = 48
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
        dataSource.filter(by: currentFilter, searchString: currentSearchTerm)
        tableView.reloadData()
    }

    @IBAction @objc private func openAction(sender _: NSMenuItem) {
        openFolder()
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
                    self.setupSetupLocalizationSelectionMenu(files: localizationFiles)
                    self.delegate?.setSelectedLocalizationGroup(title: title)
                } else {
                    self.setupMenu()
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

extension ViewController: ActionsCellDelegate {
    func userDidRequestRemoval(of key: String) {
        dataSource.deleteLocalization(key: key)

        // reload keeping scroll position
        let rect = tableView.visibleRect
        filter()
        tableView.scrollToVisible(rect)
    }
}

extension ViewController: WindowControllerToolbarDelegate {
    func userDidRequestFilterChange(filter: Filter) {
        guard currentFilter != filter else {
            return
        }

        currentFilter = filter
        self.filter()
    }

    func userDidRequestSearch(searchTerm: String) {
        guard currentSearchTerm != searchTerm else {
            return
        }

        currentSearchTerm = searchTerm
        filter()
    }

    func userDidRequestStringFileGroupChange(group: String) {
        let languages = dataSource.selectGroupAndGetLanguages(for: group)

        reloadData(with: languages, title: title)
    }

    func userDidRequestFolderOpen() {
        openFolder()
    }
}
