//
//  WindowController.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 05/03/2019.
//  Copyright © 2019 Igor Kulman. All rights reserved.
//

import Cocoa

/**
Protocol for announcing user interaction with the toolbar
 */
protocol WindowControllerToolbarDelegate: AnyObject {
    /**
     Invoked when user requests opening a folder
     */
    func userDidRequestFolderOpen()

    /**
     Invoked when user requests filter change

     - Parameter filter: new filter setting
     */
    func userDidRequestFilterChange(filter: Filter)

    /**
     Invoked when user requests searching

     - Parameter searchTerm: new search term
     */
    func userDidRequestSearch(searchTerm: String)

    /**
     Invoked when user requests change of the selected localization group

     - Parameter group: new localization group title
     */
    func userDidRequestLocalizationGroupChange(group: String)

    /**
     Invoked when user requests adding a new translation
     */
    func userDidRequestAddNewTranslation()

    /**
     Invoked when user requests generating new translations
     */
    func userDidRequestGenerateTranslations()
}

final class WindowController: NSWindowController {

    // MARK: - Outlets

    @IBOutlet private weak var openButton: NSToolbarItem!
    @IBOutlet private weak var searchField: NSSearchField!
    @IBOutlet private weak var selectButton: NSPopUpButton!
    @IBOutlet private weak var filterButton: NSPopUpButton!
    @IBOutlet private weak var newButton: NSToolbarItem!
    @IBOutlet private weak var generateTranslButton: NSToolbarItem!

    // MARK: - Properties

    weak var delegate: WindowControllerToolbarDelegate?

    override func windowDidLoad() {
        super.windowDidLoad()

        setupUI()
        setupSearch()
        setupFilter()
        setupMenu()
        setupDelegates()
    }

    // MARK: - Setup

    private func setupDelegates() {
        guard let contentViewController = window?.contentViewController, let mainViewController = contentViewController as? ViewController else {
            fatalError("Broken window hierarchy")
        }

        // informing the window about toolbar appearence
        mainViewController.delegate = self

        // informing the VC about user interacting with the toolbar
        self.delegate = mainViewController
    }

    private func setupUI() {
        openButton.toolTip = "open_folder".localized
        searchField.toolTip = "search".localized
        filterButton.toolTip = "filter".localized
        selectButton.toolTip = "string_table".localized
        newButton.toolTip = "new_translation".localized
        generateTranslButton.toolTip = "generate_translation".localized

        newButton.isEnabled = false
    }

    private func setupMenu() {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.openFolderMenuItem.action = #selector(WindowController.openAction(sender:))
    }

    private func setupSearch() {
        searchField.delegate = self
        searchField.stringValue = ""

        _ = searchField.resignFirstResponder()
    }

    private func setupFilter() {
        filterButton.menu?.removeAllItems()

        for option in Filter.allCases {
            let item = NSMenuItem(title: "\(option.description)".capitalizedFirstLetter, action: #selector(WindowController.filterAction(sender:)), keyEquivalent: "")
            item.tag = option.rawValue
            filterButton.menu?.addItem(item)
        }
    }

    private func enableControls() {
        searchField.isEnabled = true
        filterButton.isEnabled = true
        selectButton.isEnabled = true
        newButton.isEnabled = true
    }

    // MARK: - Actions

    @objc private func selectAction(sender: NSMenuItem) {
        let groupName = sender.title
        delegate?.userDidRequestLocalizationGroupChange(group: groupName)
    }

    @objc private func filterAction(sender: NSMenuItem) {
        guard let filter = Filter(rawValue: sender.tag) else {
            return
        }

        delegate?.userDidRequestFilterChange(filter: filter)
    }

    @IBAction private func openFolder(_ sender: Any) {
        delegate?.userDidRequestFolderOpen()
    }

    @IBAction private func addAction(_ sender: Any) {
        delegate?.userDidRequestAddNewTranslation()
    }

    @objc private func openAction(sender _: NSMenuItem) {
       delegate?.userDidRequestFolderOpen()
    }

    @IBAction private func generateTranslationsAction(_ sender: Any) {
        delegate?.userDidRequestGenerateTranslations()
    }
}

// MARK: - NSSearchFieldDelegate

extension WindowController: NSSearchFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        delegate?.userDidRequestSearch(searchTerm: searchField.stringValue)
    }
}

extension WindowController: NSToolbarItemValidation {
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        if item == generateTranslButton {
            guard let contentViewController = window?.contentViewController,
                  let mainViewController = contentViewController as? ViewController else {
                fatalError("Broken window hierarchy")
            }
            return !mainViewController.autoTranslationInProgress
                && selectButton.isEnabled
        }
        return item.isEnabled
    }
}

// MARK: - ViewControllerDelegate

extension WindowController: ViewControllerDelegate {
    /**
     Invoked when localization groups should be set in the toolbar's dropdown list
     */
    func shouldSetLocalizationGroups(groups: [LocalizationGroup]) {
        selectButton.menu?.removeAllItems()
        groups.map({ NSMenuItem(title: $0.name, action: #selector(WindowController.selectAction(sender:)), keyEquivalent: "") }).forEach({ selectButton.menu?.addItem($0) })
    }

    /**
     Invoiked when search and filter should be reset in the toolbar
     */
    func shouldResetSearchTermAndFilter() {
        setupSearch()
        setupFilter()

        delegate?.userDidRequestSearch(searchTerm: "")
        delegate?.userDidRequestFilterChange(filter: .all)
    }

    /**
     Invoked when localization group should be selected in the toolbar's dropdown list
     */
    func shouldSelectLocalizationGroup(title: String) {
        enableControls()
        selectButton.selectItem(at: selectButton.indexOfItem(withTitle: title))
    }
}
