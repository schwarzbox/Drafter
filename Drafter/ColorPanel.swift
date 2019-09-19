//
//  ColorPanel.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 9/18/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

class ColorPanel: NSStackView {

    func setColor(color: NSColor, panel: inout NSColorPanel?) {
        let label = self.subviews.first! as! NSTextField
        let box = self.subviews.last! as! NSBox
        label.stringValue = color.hexString
        panel?.color = color
        box.fillColor = color
    }

    func setHexColor(hex: String, panel: inout NSColorPanel?) {
        let color = NSColor.init(
            hex: Int(hex, radix: 16) ?? 0xFFFFFF)
        let label = self.subviews.first! as! NSTextField
        let box = self.subviews.last! as! NSBox
        label.stringValue = color.hexString
        panel?.color = color
        box.fillColor = color
    }

    func updateColor(sender: Any,
                     sharedPanel: inout NSColorPanel?) {
        if let text = sender as? NSTextField {
            self.setHexColor(hex: text.stringValue,
                             panel: &sharedPanel)
        } else if let panel = sender as? NSColorPanel {
            self.setColor(color: panel.color,
                          panel: &sharedPanel)
        }
    }
}
