//
//  Tools.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 10/9/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Foundation

enum Tools: Int {
    case drag, pen, line, oval, triangle, rectangle, arc, curve, text
}

let toolsKeys: [String: Tools] =
    ["d": .drag, "p": .pen, "l": .line, "o": .oval,
     "t": .triangle, "r": .rectangle, "s": .arc,
     "c": .curve, "f": .text]
