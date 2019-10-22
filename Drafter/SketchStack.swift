//
//  SketchStack.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 10/19/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

class SketchStack: NSStackView {
    var stackAction: (_ : NSButton) -> Void = {(index) in }
    var visibleAction: (_ : NSButton) -> Void = {(index) in}
    func moveToZero(curve: Curve, action: () -> NSImage?) -> NSImage? {
        var image: NSImage?
        curve.applyTransform(oX: curve.canvas.bounds.minX,
                             oY: curve.canvas.bounds.minY,
            transform: {
                curve.updateLayer()
                image = action()
        })
        curve.updateLayer()
        return image
    }

    func getImage(index: Int, curve: Curve) -> NSImage? {
        return self.moveToZero(curve: curve, action: {
             if let img = curve.canvas.cgImage() {
                 return NSImage(cgImage: img,
                                size: setup.stackSketchButtonSize)
             }
            return nil
        })
    }

    func appendSketchStackCell(
        index: Int, curve: Curve,
        stackAction:  @escaping (_ : NSButton) -> Void,
        visibleAction:  @escaping (_ : NSButton) -> Void) {
        self.isOn(on: -1)
        self.stackAction = stackAction
        self.visibleAction = visibleAction

        let curveButton = NSButton()
        curveButton.image = self.getImage(index: index, curve: curve)
        curveButton.bezelStyle = .shadowlessSquare
        curveButton.action = #selector(self.selectCurveFromStack)
        let eyeButton = NSButton()
        eyeButton.image = NSImage.init(
                   named: NSImage.quickLookTemplateName)
        eyeButton.bezelStyle = .inline
        eyeButton.action = #selector(self.visibleCurve)

        for button in [curveButton, eyeButton] {
            button.target = self
            button.tag = index
            button.imageScaling = .scaleProportionallyDown
            button.setButtonType(.onOff)
            button.setFrameSize(setup.stackSketchButtonSize)
            button.state = .on
        }

//        let groupLabel = NSTextField()
//        groupLabel.placeholderString = ""
//        groupLabel.alignment = .right
//        groupLabel.drawsBackground = false
//        groupLabel.isBordered = false
//        groupLabel.bezelStyle = .squareBezel
//        groupLabel.isSelectable = false
//        groupLabel.isEditable = false

        let stack = NSStackView()
        stack.spacing = 4
        stack.addArrangedSubview(curveButton)
        stack.addArrangedSubview(eyeButton)
//        stack.addArrangedSubview(groupLabel)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.addArrangedSubview(stack)
    }

    @objc func selectCurveFromStack(_ sender: NSButton) {
        self.stackAction(sender)
    }

    @objc func visibleCurve(_ sender: NSButton) {
         self.visibleAction(sender)
    }

    func remove(at: Int) {
       self.subviews.remove(at: at)
    }

    func updateGroup(index: Int, group: Int) {
        if let stack =  self.arrangedSubviews[index] as? NSStackView {
            if let field = stack.arrangedSubviews.last as? NSTextField {
                field.placeholderString = String(group)
            }
        }
    }

    func updateTag(index: Int, with: Int) {
        if let stack =  self.arrangedSubviews[index] as? NSStackView {
            for view in stack.arrangedSubviews {
                if let button = view as? NSButton {
                    button.tag = with
                }
                if let field = view as? NSTextField {
                    field.tag = with
                }
            }
        }
    }

    func updateImageButton(index: Int, curve: Curve) {
        if let stack = self.arrangedSubviews[index] as? NSStackView {
            if let button = stack.arrangedSubviews[0] as? NSButton {
                button.image = self.getImage(index: index, curve: curve)
            }
            if let button = stack.arrangedSubviews[1] as? NSButton {
                if curve.canvas.isHidden {
                    button.state = .off
                } else {
                    button.state = .on
                }
            }
        }
    }
}
