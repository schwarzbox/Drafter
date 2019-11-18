//
//  FrameButtons.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 10/8/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

class FrameButtons: NSStackView {

    func updateFrame(view: SketchPad, pos: CGPoint) {
        if let curve = view.selectedCurve {
            self.frame = NSRect(
                x: pos.x - self.bounds.width,
                y: pos.y - self.bounds.height,
            width: self.bounds.width,
            height: self.bounds.height)

            self.updateState(curve: curve)
            self.show()
        }
    }

    func updateState(curve: Curve) {

        if let group = self.subviews[5] as? NSButton {
            group.state = curve.groups.count > 1 ? .on : .off
        }
        if let mask = self.subviews[6] as? NSButton {
            mask.state = curve.mask ? .on : .off
        }
        if let lock = self.subviews[7] as? NSButton {
            lock.state = curve.lock ? .on : .off
        }

        if curve.edit {
            self.isEnabled(tag: 4)
        } else if curve.lock {
            self.isEnabled(tag: 7)
        } else {
            self.isEnabled(all: true)
        }

        if !curve.fill {
            self.setEnabled(tag: 6, bool: false)
        }
        
        if curve.groups.count>1 {
            self.setEnabled(tag: 4, bool: false)
            self.setEnabled(tag: 6, bool: false)
        }
    }

    func hide() {
        self.isHidden = true
    }

    func show() {
        self.isHidden = false
    }
}
