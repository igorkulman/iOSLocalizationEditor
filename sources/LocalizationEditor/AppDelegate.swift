//
//  AppDelegate.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var openFolderMenuItem: NSMenuItem!  // WindowController.swift uses these can't be private
    @IBOutlet weak var openLGMenuItem: NSMenuItem!

    @IBAction private func openAppleInternationalizationSite(sender: AnyObject?) {
        let url = URL(string: "https://developer.apple.com/internationalization/")
        NSWorkspace.shared.open(url!)
    }

    @IBAction private func openExtractStringsHelp(sender: AnyObject?) {
        let url = URL(string: "https://rderik.com/blog/text-extraction-tools-for-macos-and-ios-app-localization/")
        NSWorkspace.shared.open(url!)
    }

    func applicationDidFinishLaunching(_: Notification) {}

    func applicationWillTerminate(_: Notification) {}
}
