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
