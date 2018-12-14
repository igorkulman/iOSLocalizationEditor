//
//  LocalizationCell.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import Cocoa

protocol LocalizationCellDelegate: AnyObject {
    func userDidUpdateLocalizationString(language: String, string: LocalizationString, with value: String)
}

class LocalizationCell: NSTableCellView {
    // MARK: - Outlets

    @IBOutlet private weak var valueTextField: NSTextField!

    // MARK: - Properties

    static let identifier = "LocalizationCell"

    weak var delegate: LocalizationCellDelegate?

    var language: String?

    var value: LocalizationString? {
        didSet {
            valueTextField.stringValue = value?.value ?? ""
            valueTextField.delegate = self
        }
    }
}

// MARK: - Delegate

extension LocalizationCell: NSTextFieldDelegate {
    func controlTextDidEndEditing(_: Notification) {
        guard let language = language, let value = value else {
            return
        }

        delegate?.userDidUpdateLocalizationString(language: language, string: value, with: valueTextField.stringValue)
    }
}
