//
//  FileManager+Extension.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 01/02/2019.
//  Copyright © 2019 Igor Kulman. All rights reserved.
//

import Foundation

extension FileManager {
    func getAllFilesRecursively(url: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(atPath: url.path) else {
            return []
        }

        return enumerator.compactMap({ element -> URL? in
            if let path = element as? String {
                let fullUrl = url.appendingPathComponent(path, isDirectory: false)
                 return fullUrl
            }
            return nil
        })
    }
}
