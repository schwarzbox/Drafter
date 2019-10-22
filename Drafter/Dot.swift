//
//  Dot.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 8/27/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa
class Dot: CAShapeLayer {
    var tag: Int?
    var excluded: Bool = false
    var width: CGFloat!
    var height: CGFloat!
    var anchor: CGPoint!
    var strokeNSColor: NSColor!
    var fillNSColor: NSColor!

    init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat,
         rounded: CGFloat, anchor: CGPoint = CGPoint(x: 0.5, y: 0.5),
         lineWidth: CGFloat = 1,
         strokeColor: NSColor = NSColor.white,
         fillColor: NSColor = NSColor.systemBlue,
         path: NSBezierPath = NSBezierPath(),
         dashPattern: [NSNumber]? = nil,
         hidden: Bool = false) {

        super.init()
        // disable animation
        self.actions = ["position": NSNull()]
        self.frame = CGRect(x: x-anchor.x * width,
                            y: y-anchor.y * height,
                            width: width, height: height)

        self.width = width
        self.height = height
        self.anchor = anchor
        self.strokeNSColor = strokeColor
        self.fillNSColor = fillColor
        self.lineWidth = lineWidth
        self.strokeColor = strokeColor.cgColor
        self.fillColor = fillColor.cgColor
        self.cornerRadius = rounded
        self.borderWidth = lineWidth
        self.borderColor = strokeColor.cgColor
        self.backgroundColor = fillColor.cgColor

        self.path = path.cgPath
        if let dash = dashPattern {
            self.lineDashPattern = dash
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

    func updateSize(width: CGFloat, height: CGFloat, circle: Bool = true) {
        let pos = self.position
        let wid50 = width/2
        let hei50 = height/2
        let rect = NSRect(x: pos.x - wid50,
                          y: pos.y - hei50,
                          width: width, height: height)
        self.frame = rect
        if circle {
            self.cornerRadius = wid50 < hei50 ? wid50 : hei50
        }
    }

    override func copy() -> Any {
        return Dot.init(x: self.frame.midX,
                        y: self.frame.midY,
                        width: self.width,
                        height: self.height,
                        rounded: self.cornerRadius,
                        anchor: self.anchor,
                        lineWidth: self.borderWidth,
                        strokeColor: self.strokeNSColor,
                        fillColor: self.fillNSColor,
                        dashPattern: self.lineDashPattern,
                        hidden: self.isHidden)
    }
}
