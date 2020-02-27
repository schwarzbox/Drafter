//
//  ActionSlider.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 10/24/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

class ActionSlider: NSStackView {

    @IBOutlet weak var slider: NSSlider!
    @IBOutlet weak var field: NSTextField!

    var integerValue: Int = 0 {
        willSet {
            slider.intValue = Int32(newValue)
            field.intValue = Int32(newValue)
        }
    }

    var doubleValue: Double = 0 {
        willSet {
            slider.doubleValue = newValue
            field.doubleValue = newValue
        }
    }

    var minValue: Double = 0 {
        willSet {
            slider.minValue = newValue
        }
    }

    var maxValue: Double = 1 {
        willSet {
            slider.maxValue = newValue
        }
    }


}
