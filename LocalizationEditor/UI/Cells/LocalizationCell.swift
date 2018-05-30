//
//  LocalizationCell.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Teamwire. All rights reserved.
//

import Cocoa

protocol LocalizationCellDelegate: class {
    func userDidUpdateLocalizationString(language: String, string: LocalizationString)
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
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        setup()
    }
    
    private func setup() {
        
    }
}

extension LocalizationCell: NSTextFieldDelegate {
    override func controlTextDidEndEditing(_ obj: Notification) {
        guard let language = language, let value = value else {
            return
        }
        
        delegate?.userDidUpdateLocalizationString(language: language, string: LocalizationString(key: value.key, value: valueTextField.stringValue))
    }
}
