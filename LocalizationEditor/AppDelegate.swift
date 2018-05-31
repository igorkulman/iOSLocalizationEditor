//
//  AppDelegate.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import CleanroomLogger
import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var openFolderMenuItem: NSMenuItem!

    func applicationDidFinishLaunching(_: Notification) {
        setupLogging()
    }

    func applicationWillTerminate(_: Notification) {
    }

    private func setupLogging() {
        var configs = [LogConfiguration]()

        // create a recorder for logging to stdout & stderr
        // and add a configuration that references it
        let stderr = StandardStreamsLogRecorder(formatters: [XcodeLogFormatter()])
        configs.append(BasicLogConfiguration(minimumSeverity: .debug, recorders: [stderr]))

        // create a recorder for logging via OSLog (if possible)
        // and add a configuration that references it
        if let osLog = OSLogRecorder(formatters: [ReadableLogFormatter()]) {
            // the OSLogRecorder initializer will fail if running on
            // a platform that doesn’t support the os_log() function
            configs.append(BasicLogConfiguration(recorders: [osLog]))
        }

        let documentsPath = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0])
        let logsPath = documentsPath.appendingPathComponent("logs")

        #if DEBUG
            let minimumSeverity: CleanroomLogger.LogSeverity = .debug
        #else
            let minimumSeverity: CleanroomLogger.LogSeverity = .info
        #endif

        // create a configuration for a 15-day rotating log directory
        let fileCfg = RotatingLogFileConfiguration(minimumSeverity: minimumSeverity,
                                                   daysToKeep: 15,
                                                   directoryPath: logsPath!.path,
                                                   formatters: [ReadableLogFormatter()])

        // crash if the log directory doesn’t exist yet & can’t be created
        try! fileCfg.createLogDirectory()

        configs.append(fileCfg)

        // enable logging using the LogRecorders created above
        Log.enable(configuration: configs)
    }
}
