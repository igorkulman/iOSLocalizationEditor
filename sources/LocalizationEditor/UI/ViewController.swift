//
//  ViewController.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import Cocoa

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
    private var presendedAddViewController: AddViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupData()
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
        column.title = "Key"
        tableView.addTableColumn(column)

        languages.forEach { language in
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(language))
            column.title = Flag(languageCode: language).emoji
            column.maxWidth = 460
            column.minWidth = 50
            self.tableView.addTableColumn(column)
        }

        let actionsColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(FixedColumn.actions.rawValue))
        actionsColumn.title = "Actions"
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
