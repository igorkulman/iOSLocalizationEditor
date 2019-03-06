//
//  NSTableView+Click.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 02/01/2019.
//  Copyright © 2019 Igor Kulman. All rights reserved.
//
// Taken from https://stackoverflow.com/a/30106728/581164 and adjusted

import Cocoa
import Foundation

extension NSTableView {
    open override func mouseDown(with event: NSEvent) {
        let globalLocation = event.locationInWindow
        let localLocation = self.convert(globalLocation, to: nil)
        let clickedRow = self.row(at: localLocation)
        let clickedColumn = self.column(at: localLocation)

        super.mouseDown(with: event)

        guard clickedRow >= 0, clickedColumn >= 0 else {
            return
        }

        (self.delegate as? NSTableViewClickableDelegate)?.tableView(self, didClickRow: clickedRow, didClickColumn: clickedColumn)
    }
}

protocol NSTableViewClickableDelegate: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, didClickRow row: Int, didClickColumn: Int)
}
