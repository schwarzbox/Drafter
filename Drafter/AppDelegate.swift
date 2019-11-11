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

//    func applicationDidUpdate(_ notification: Notification) {
//        print("applicationDidUpdate")
//    }

    func applicationDidBecomeActive(_ notification: Notification) {
        print("applicationDidBecomeActive")
    }

    func applicationDidChangeScreenParameters(_ notification: Notification) {
        print("applicationDidChangeScreenParameters")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        print("applicationWillTerminate")
    }
}
