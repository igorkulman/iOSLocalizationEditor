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
    func userDidRequestAutotranslateRemoval(of key: String)
}

final class ActionsCell: NSTableCellView {
    // MARK: - Outlets

    @IBOutlet private weak var deleteButton: NSButton!
    @IBOutlet private weak var deleteAutotranslationsButton: NSButton!

    // MARK: - Properties

    static let identifier = "ActionsCell"

    var key: String?
    var hasAutotranslations: Bool = false {
        didSet {
            deleteAutotranslationsButton.isHidden = !hasAutotranslations
        }
    }
    weak var delegate: ActionsCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        deleteButton.toolTip = "delete".localized
        deleteAutotranslationsButton.toolTip = "delete_autotrans".localized
        deleteAutotranslationsButton.isHidden = !hasAutotranslations
    }

    @IBAction private func removalClicked(_ sender: NSButton) {
        guard let key = key else { return }

        delegate?.userDidRequestRemoval(of: key)
    }

    @IBAction private func deleteAutotranslateClicked(_ sender: NSButton) {
        guard let key = key else { return }

        delegate?.userDidRequestAutotranslateRemoval(of: key)
    }
}
