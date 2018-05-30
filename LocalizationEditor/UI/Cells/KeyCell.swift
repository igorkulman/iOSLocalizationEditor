//
//  KeyCell.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Teamwire. All rights reserved.
//

import Cocoa
import Foundation

class KeyCell: NSTableCellView {

    // MARK: - Outlets

    @IBOutlet private weak var keyLabel: NSTextField!

    // MARK: - Properties

    static let identifier = "KeyCell"

    var key: String? {
        didSet {
            keyLabel.stringValue = key ?? ""
        }
    }
}
