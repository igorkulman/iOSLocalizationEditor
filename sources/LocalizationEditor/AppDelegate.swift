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
