//
//  ActionsCell.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 05/03/2019.
//  Copyright © 2019 Igor Kulman. All rights reserved.
//

import Cocoa

protocol ActionsCellDelegate: AnyObject {
    func userDidRequestRemoval(of key: String)
}

final class ActionsCell: NSTableCellView {
    // MARK: - Outlets

    @IBOutlet private weak var deleteButton: NSButton!

    // MARK: - Properties

    static let identifier = "ActionsCell"

    var key: String?
    weak var delegate: ActionsCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()

        deleteButton.image = NSImage(named: NSImage.stopProgressTemplateName)
    }

    @IBAction private func removalClicked(_ sender: NSButton) {
        guard let key = key else {
            return
        }

        delegate?.userDidRequestRemoval(of: key)
    }
}
