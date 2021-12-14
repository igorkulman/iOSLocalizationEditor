//
//  AppDelegate.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//
// swiftlint:disable private_outlet

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var openFolderMenuItem: NSMenuItem!

    private static var editorWindow: NSWindow? {
        return NSApp.windows.first(where: { $0.windowController is WindowController })
    }

    func applicationDidFinishLaunching(_: Notification) {}

    func applicationWillTerminate(_: Notification) {}

    func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
        showEditorWindow()
        return true
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: filename, isDirectory: &isDirectory), isDirectory.boolValue == true {
            showEditorWindow()
            let windowController = (Self.editorWindow?.windowController) as! WindowController
            windowController.openFolder(withPath: filename)
            return true
        }
        return false
    }

    private func showEditorWindow() {
        if let editorWindow = Self.editorWindow {
            editorWindow.makeKeyAndOrderFront(nil)
        } else {
            let mainStoryboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
            let editorWindowController = mainStoryboard.instantiateInitialController() as! WindowController
            editorWindowController.showWindow(self)
        }
    }
}
