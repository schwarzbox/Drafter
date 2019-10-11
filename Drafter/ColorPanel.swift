//
//  ColorPanel.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 9/18/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

class ColorPanel: NSStackView {
    var sharedColorPanel: NSColorPanel?

    static func setupSharedColorPanel() {
        NSColorPanel.setPickerMask(NSColorPanel.Options.wheelModeMask)
        let panel = NSColorPanel.shared
        panel.close()
    }

    func createSharedColorPanel(frame: NSRect?, sender: ColorBox?) {
        NSColorPanel.setPickerMask(NSColorPanel.Options.wheelModeMask)
        self.sharedColorPanel = NSColorPanel.shared
        if let frm = frame {
            self.sharedColorPanel?.setFrame(frm, display: true)
        }
        self.sharedColorPanel?.styleMask = .titled

        self.sharedColorPanel?.backgroundColor = setup.guiColor
        self.sharedColorPanel?.makeKeyAndOrderFront(self)
        self.sharedColorPanel?.setTarget(self)
        self.sharedColorPanel?.isContinuous = true
        self.sharedColorPanel?.mode = NSColorPanel.Mode.wheel

        self.sharedColorPanel?.setAction(
                        #selector(self.setSharedColor))

        let title = sender?.alternateTitle ?? ""
        let tag = sender?.tag ?? -1

        self.sharedColorPanel?.title = title.capitalized

        if let parent = self.superview as? NSStackView {
            parent.isOn(on: tag)
        }
    }

    func closeSharedColorPanel() {
        if let panel = self.sharedColorPanel {
            panel.close()
            self.sharedColorPanel = nil
            if let parent = self.superview as? NSStackView {
                parent.isOn(on: -1)
            }
        }
    }

    func setColor(color: NSColor) -> NSColor {
        if let label = self.subviews.first as? NSTextField,
            let box = self.subviews.last as? NSBox {
            label.stringValue = color.hexStr
            box.fillColor = color
        }
        return color
    }

    func setHexColor(hex: String) -> NSColor {
        let color = NSColor.init(
            hex: Int(hex, radix: 16) ?? 0xFFFFFF)
        if let label = self.subviews.first as? NSTextField,
            let box = self.subviews.last as? NSBox {
            label.stringValue = color.hexStr
            box.fillColor = color
        }
        return color
    }

    @IBAction func setSharedColor(sender: Any) {
        var color = NSColor.black
        if let text = sender as? NSTextField {
            color = self.setHexColor(hex: text.stringValue)
        } else if let panel = sender as? NSColorPanel {
            color = self.setColor(color: panel.color)
        }
        self.sharedColorPanel?.color = color

        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("updateSketchColor"),
                object: nil)
    }
}
