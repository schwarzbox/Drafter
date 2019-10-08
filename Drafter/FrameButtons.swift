//
//  FrameButtons.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 10/8/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

class FrameButtons: NSStackView {

    func updateFrame(view: SketchPad) {
        if let curve = view.selectedCurve {
            let deltaX = view.bounds.minX
            let deltaY = view.bounds.minY
            let width50 = curve.lineWidth/2

            let x = curve.path.bounds.minX - setup.dotSize - width50
            let y = curve.path.bounds.maxY + width50
            self.frame = NSRect(
                x: (x-deltaX) * view.zoomed - self.bounds.width,
                y: (y-deltaY) * view.zoomed - self.bounds.height,
                width: self.bounds.width,
                height: self.bounds.height)

            self.updateState(curve: curve)
        }
    }

    func updateState(curve: Curve) {
        if let lock = self.subviews.last as? NSButton {
            lock.state = curve.lock ? .on : .off
            if curve.lock {
                self.isEnable(title: "lock")
            } else if curve.edit {
                self.isEnable(title: "edit")
            } else {
                self.isEnable(all: true)
            }
        }
    }

    func hide() {
        self.isHidden = true
    }

    func show() {
        self.isHidden = false
    }
}
