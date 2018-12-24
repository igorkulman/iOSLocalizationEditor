//
//  LocalizationCell.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import Cocoa

protocol LocalizationCellDelegate: AnyObject {
    func userDidUpdateLocalizationString(language: String, key: String, with value: String)
}

final class LocalizationCell: NSTableCellView {
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
            setStateUI()
        }
    }

    private func setStateUI() {
        valueTextField.layer?.borderColor = valueTextField.stringValue.isEmpty ? NSColor.red.cgColor : NSColor.clear.cgColor
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        valueTextField.wantsLayer = true
        valueTextField.layer?.borderWidth = 1.0
        valueTextField.layer?.cornerRadius = 0.0
    }
}

// MARK: - Delegate

extension LocalizationCell: NSTextFieldDelegate {
    func controlTextDidEndEditing(_: Notification) {
        guard let language = language, let value = value else {
            return
        }

        setStateUI()
        delegate?.userDidUpdateLocalizationString(language: language, key: value.key, with: valueTextField.stringValue)
    }
}
