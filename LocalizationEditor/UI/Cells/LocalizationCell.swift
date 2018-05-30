//
//  LocalizationCell.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Teamwire. All rights reserved.
//

import Cocoa

class LocalizationCell: NSTableCellView {

    // MARK: - Outlets

    @IBOutlet private weak var valueTextField: NSTextField!

    // MARK: - Properties

    static let identifier = "LocalizationCell"

    var value: String? {
        didSet {
            valueTextField.stringValue = value ?? ""
        }
    }
}
