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
    var excluded: Bool = false
    var size: CGFloat?
    var offset: CGPoint?
    var strokeColor: NSColor?
    var fillColor: NSColor?

    init(x: CGFloat, y: CGFloat, size: CGFloat, offset: CGPoint,
         radius: CGFloat, lineWidth: CGFloat = setup.lineWidth,
         strokeColor: NSColor? = setup.strokeColor,
         fillColor: NSColor? = setup.fillColor,
         hidden: Bool = false) {

        super.init()
        // disable animation
        self.actions = ["position": NSNull()]
        self.frame = CGRect(x: x-offset.y, y: y-offset.x,
                            width: size, height: size)

        self.size = size
        self.offset = offset
        self.strokeColor = strokeColor
        self.fillColor = fillColor
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

    func updateSize(size: CGFloat) {
        let pos = self.position
        let size50 = size/2
        let rect = NSRect(x: pos.x - size50,
                          y: pos.y - size50,
                          width: size, height: size)
        self.frame = rect
    }

    override func copy() -> Any {
        return Dot.init(x: self.frame.midX,
                        y: self.frame.midY,
                        size: self.size ?? 0,
                        offset: self.offset ?? CGPoint(x: 0, y: 0),
                        radius: self.cornerRadius,
                        lineWidth: self.borderWidth,
                        strokeColor: self.strokeColor,
                        fillColor: self.fillColor,
                        hidden: self.isHidden)
    }
}
