//
//  InputTool.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 11/18/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

class InputTool: NSTextField {
    override func textShouldEndEditing(_ textObject: NSText) -> Bool {
        var st = ""
        for ch in textObject.string {
            if !(ch.isASCII) {
                continue
            }
            st += String(ch)
        }
        textObject.string = st
        return true
    }

    override func textDidChange(_ notification: Notification) {
        self.resize()
    }

    func hide() {
        self.isHidden = true
        self.isEnabled = false
    }

    func show() {
        self.resize()
        self.isHidden = false
        self.isEnabled = true
        self.selectText(self)
    }

    func resize() {
        if let cell = self.cell, let font = self.font {
            let txt = cell.stringValue.count < 5
                ? "Text"
                : cell.stringValue
            let sz = txt.sizeOfString(usingFont: font,
                                      upper: true)
            if let lastChar = txt.last {
                let lastSz = String(lastChar).sizeOfString(usingFont: font, upper: true)
                self.setFrameSize(
                    CGSize(width: sz.width+lastSz.width,
                           height: cell.cellSize.height))
            }

        }
    }
}
