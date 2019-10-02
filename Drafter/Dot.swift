//
//  Dot.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 8/27/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa
class Dot: CALayer {
    var tag: Int?
    init(x: CGFloat, y: CGFloat, size: CGFloat, offset: CGPoint,
         radius: CGFloat, lineWidth: CGFloat = set.lineWidth,
         strokeColor: NSColor? = set.strokeColor,
         fillColor: NSColor? = set.fillColor,
         hidden: Bool = false) {

        super.init()
        // disable animation
        self.actions = ["position" : NSNull()]
        self.frame = CGRect(x: x-offset.y, y: y-offset.x,
                            width: size, height: size)

        self.cornerRadius = radius
        self.borderWidth = lineWidth
        self.borderColor = strokeColor?.cgColor
        self.backgroundColor = fillColor?.cgColor

        self.isHidden = hidden
    }
    // need for change position
    override init(layer: Any) {
        super.init(layer: layer)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}


