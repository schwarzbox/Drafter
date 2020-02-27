//
//  PrefViewController.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 2/27/20.
//  Copyright © 2020 Alex Veledzimovich. All rights reserved.
//

import Cocoa

class PrefViewController: NSViewController {

    @IBOutlet weak var history: ActionSlider!
    override func viewDidLoad() {
        super.viewDidLoad()
        history.minValue = 1.0
        history.maxValue = Double(setEditor.maxHistory)
        history.integerValue = setEditor.nowHistory
    }

    @IBAction func setNowHistory(_ sender: Any) {
        if let sl = sender as? NSSlider {
            setEditor.nowHistory = Int(sl.intValue)
            history.integerValue = Int(sl.intValue)
        } else if let tf = sender as? NSTextField {
            setEditor.nowHistory = Int(tf.doubleValue)
            history.integerValue = Int(tf.intValue)
        }
    }
}
