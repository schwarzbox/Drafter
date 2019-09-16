//
//  Dot.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 8/27/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa
class Dot: CALayer {
    init(x: CGFloat, y: CGFloat, size: CGFloat, offset: CGPoint, radius: CGFloat,
         bg: Bool = false, hidden: Bool = false) {

        super.init()
        // disable animation
        self.actions = ["position" : NSNull()]
        self.frame = CGRect(x: x-offset.y, y: y-offset.x,
                            width: size, height: size)

        self.cornerRadius = radius
        self.borderWidth = set.lineWidth
        self.borderColor = set.strokeColor.cgColor
        if bg {
            self.backgroundColor = set.fillColor.cgColor
        }
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


