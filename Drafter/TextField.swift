//
//  TextField.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 9/13/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

class TextField: NSTextField {
    override func abortEditing() -> Bool {
        let orig = super.abortEditing()
        set.activeTextField(find: false)
        return orig
    }

    override func becomeFirstResponder() -> Bool {
        set.activeTextField(find: true)
        return super.becomeFirstResponder()
    }
}
