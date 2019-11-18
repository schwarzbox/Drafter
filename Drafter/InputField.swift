//
//  InputField.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 11/18/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

class InputField: NSTextField {
    func resize() {
        if let text = self.cell?.stringValue, let font = self.font {
            let wid = text.sizeOfString(usingFont: font).width
            if wid > setEditor.inputFieldSize {
                if let parent = self.superview,
                    let stack = parent as? NSStackView {
                    stack.setFrameSize(
                        CGSize(width: wid,
                               height: stack.fittingSize.height))

                    stack.translatesAutoresizingMaskIntoConstraints=true
                }
            }
        }
    }

    override func textDidChange(_ notification: Notification) {
        print(self.acceptsFirstResponder)
        self.resize()
    }
}
