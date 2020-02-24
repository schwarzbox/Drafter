//
//  AppDelegate.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 8/12/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func application(_ sender: NSApplication,
                     openFile filename: String) -> Bool {
        if filename.checkExtension(ext: setEditor.fileTypes) {
            let fileUrl = URL.init(fileURLWithPath: filename)
            let nc = NotificationCenter.default
            nc.post(name: Notification.Name("openFiles"),
                    object: nil,
                    userInfo: ["fileUrl": fileUrl])
            return true
        }
        return false
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("applicationDidFinishLaunching")
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        print("applicationDidBecomeActive")
    }

    func applicationShouldTerminate(
        _ sender: NSApplication) -> NSApplication.TerminateReply {

        if setGlobal.saved {
            let nc = NotificationCenter.default
            nc.post(name: Notification.Name(
                "shouldTerminate"), object: nil)
            return .terminateLater
        }
        return .terminateNow
    }
}
