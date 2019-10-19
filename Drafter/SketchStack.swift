//
//  SketchStack.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 10/19/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

class SketchStack: NSStackView {
    var action: (_ : Int) -> Void = {(index) in }

    func moveToZero(curve: Curve, action: () -> Void) {
        let oX = curve.canvas.bounds.minX
        let oY = curve.canvas.bounds.minY
        curve.applyTransform(oX: oX, oY: oY,
            transform: {
                curve.updatePoints(deltax: oX, deltay: -oY)
                action()
        })
        curve.updatePoints(deltax: -oX, deltay: oY)
    }

    func appendContolStack() {

    }

    func appendImageButton(index: Int, curve: Curve,
                           action:  @escaping (_ : Int) -> Void ) {
        self.action = action
        self.moveToZero(curve: curve, action: {
            if let img = curve.canvas.cgImage() {
                let button = NSButton()
                button.image =  NSImage(cgImage: img,
                                        size: setup.sketchIconSize)

                button.target = self
                button.isSpringLoaded = true
                button.action =  #selector(self.selectCurveFromStack)
                button.tag = index
                button.isBordered = true

                button.imageScaling = .scaleProportionallyDown
                button.isTransparent = false
                button.bezelStyle = .regularSquare
                button.setButtonType(.onOff)
                button.setFrameSize(setup.sketchIconSize)
                self.isOn(on: -1)
                button.state = .on
                self.addArrangedSubview(button)
            }
       })
    }

    @objc func selectCurveFromStack(_ sender: NSButton) {
        self.action(sender.tag)
        self.isOn(on: sender.tag)
    }

    func remove(at: Int) {
       self.subviews.remove(at: at)
    }

    func updateImageButton(index: Int, curve: Curve) {
       if let button = self.arrangedSubviews[index] as? NSButton {
            self.moveToZero(curve: curve, action: {
                if let img = curve.canvas.cgImage() {
                    button.image = NSImage(cgImage: img,
                                           size: setup.sketchIconSize)
                    button.tag = index
                    self.isOn(on: button.tag)
                }
            })
       }
    }
}
