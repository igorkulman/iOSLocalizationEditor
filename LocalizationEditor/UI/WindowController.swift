//
//  WindowController.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 05/03/2019.
//  Copyright © 2019 Igor Kulman. All rights reserved.
//

import Cocoa

protocol WindowControllerToolbarDelegate: AnyObject {
    func userDidRequestFolderOpen()
    func userDidRequestFilterChange(filter: Filter)
    func userDidRequestSearch(searchTerm: String)
    func userDidRequestStringFileGroupChange(group: String)
}

class WindowController: NSWindowController {

    @IBOutlet private weak var openButton: NSToolbarItem!
    @IBOutlet private weak var searchField: NSSearchField!
    @IBOutlet private weak var selectButton: NSPopUpButton!
    @IBOutlet private weak var filterButton: NSPopUpButton!

    weak var delegate: WindowControllerToolbarDelegate?

    override func windowDidLoad() {
        super.windowDidLoad()

        setupSearch()
        setupFilter()

        openButton.image = NSImage(named: NSImage.folderName)

        let mainViewController = window!.contentViewController as! ViewController
        mainViewController.delegate = self

        delegate = mainViewController
    }

    private func setupSearch() {
        searchField.delegate = self
        searchField.stringValue = ""

        _ = searchField.resignFirstResponder()
    }

    private func setupFilter() {
        filterButton.menu?.removeAllItems()

        for option in Filter.allCases {
            let item = NSMenuItem(title: "\(option)", action: #selector(WindowController.filterAction(sender:)), keyEquivalent: "")
            item.tag = option.rawValue
            filterButton.menu?.addItem(item)
        }
    }

    // MARK: - Actions

    @objc private func selectAction(sender: NSMenuItem) {
        let groupName = sender.title
        delegate?.userDidRequestStringFileGroupChange(group: groupName)
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
}

// MARK: - Search

extension WindowController: NSSearchFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        delegate?.userDidRequestSearch(searchTerm: searchField.stringValue)
    }
}

// MARK: - ViewController delegate

extension WindowController: ViewControllerDelegate {
    func setStringTableLocalizationGroups(groups: [LocalizationGroup]) {
        selectButton.menu?.removeAllItems()
        groups.map({ NSMenuItem(title: $0.name, action: #selector(WindowController.selectAction(sender:)), keyEquivalent: "") }).forEach({ selectButton.menu?.addItem($0) })
    }

    func resetSearchAndFilter() {
        setupSearch()
        setupFilter()

        delegate?.userDidRequestSearch(searchTerm: "")
        delegate?.userDidRequestFilterChange(filter: .all)
    }

    func setSelectedLocalizationGroup(title: String) {
         selectButton.selectItem(at: selectButton.indexOfItem(withTitle: title))
    }
}

extension Filter: CustomStringConvertible {
    var description: String {
        switch self {
        case .all:
            return "All"
        case .missing:
            return "Missing"
        }
    }
}
