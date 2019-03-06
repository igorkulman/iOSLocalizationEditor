//
//  XCTestCase+Extensions.swift
//  LocalizationEditorTests
//
//  Created by Igor Kulman on 16/12/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import Foundation
import XCTest

extension XCTest {
    private func getFullPath(for fileName: String) -> URL {
        let bundle = Bundle(for: type(of: self))
        return bundle.bundleURL.appendingPathComponent("Contents").appendingPathComponent("Resources").appendingPathComponent(fileName)
    }

    func createTestingDirectory(with files: [TestFile]) -> URL {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
        for file in try! FileManager.default.contentsOfDirectory(atPath: tmp.path) {
            try? FileManager.default.removeItem(at: tmp.appendingPathComponent(file))
        }
        for file in files {
            try? FileManager.default.createDirectory(at: tmp.appendingPathComponent(file.destinationFolder), withIntermediateDirectories: false, attributes: nil)
            try? FileManager.default.removeItem(at: tmp.appendingPathComponent(file.destinationFolder).appendingPathComponent(file.destinationFileName))
            try! FileManager.default.copyItem(at: getFullPath(for: file.originalFileName), to: tmp.appendingPathComponent(file.destinationFolder).appendingPathComponent(file.destinationFileName))
        }
        return tmp
    }
}
