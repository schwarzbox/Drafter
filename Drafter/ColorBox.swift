//
//  ColorBox.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 9/15/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

class ColorBox: NSControl {
    @IBInspectable var alternateTitle: String = ""
    var state: StateValue = .off

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.tag = 0
    }

    func restore() {
        if self.state == .on {
            if let view = self.superview, let box = view as? NSBox {
                box.borderColor = setup.strokeColor
            }
        } else {
            if let view = self.superview, let box = view as? NSBox {
                box.borderColor = setup.guiColor
            }
        }
    }

    override func mouseDown(with event: NSEvent) {
        if self.isEnabled {
            if self.state == .off {
                self.state = .on
            } else {
                self.state = .off
            }
            if let action = self.action {
                NSApp.sendAction(action, to: self.target, from: self)
            }
        }
    }

}
