//
//  ColorPanel.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 9/18/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

class ColorPanel: NSStackView {

    func setColor(color: NSColor) -> NSColor  {
        let label = self.subviews.first! as! NSTextField
        let box = self.subviews.last! as! NSBox
        label.stringValue = color.hexString
        box.fillColor = color
        return color
    }

    func setHexColor(hex: String) -> NSColor {
        let color = NSColor.init(
            hex: Int(hex, radix: 16) ?? 0xFFFFFF)
        let label = self.subviews.first! as! NSTextField
        let box = self.subviews.last! as! NSBox
        label.stringValue = color.hexString

        box.fillColor = color
        return color
    }

    func updateColor(sender: Any,
                     color: inout NSColor) {
        if let text = sender as? NSTextField {
            
            color = self.setHexColor(hex: text.stringValue)
        } else if let panel = sender as? NSColorPanel {
           color = self.setColor(color: panel.color)
        }
    }
}
