//
//  ControlFrame.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 8/26/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

class ControlFrame: CALayer {
    var parent: SketchPad?
    static let dotSize: CGFloat = set.dotSize
    static let dot50Size: CGFloat = dotSize / 2
    static let labelSize: CGFloat = dotSize + 6
    static let label50Size: CGFloat = labelSize / 2
    static let defaultWidth: CGFloat = set.lineWidth
    static let defaultColor: CGColor = set.fillColor.cgColor
    static let rotatePad: CGFloat = 32
    
    init(parent: SketchPad, curve: Curve) {
        self.parent = parent
        super.init()

        self.frame = CGRect(x: curve.path.bounds.minX - curve.lineWidth/2,
                             y:  curve.path.bounds.minY - curve.lineWidth/2,
                             width: curve.path.bounds.width + curve.lineWidth,
                             height: curve.path.bounds.height + curve.lineWidth)
        self.borderWidth = ControlFrame.defaultWidth
        self.borderColor = ControlFrame.defaultColor


        let dots: [CGPoint] = [
            CGPoint(x: self.bounds.minX, y: self.bounds.minY),
            CGPoint(x: self.bounds.minX, y: self.bounds.midY),
            CGPoint(x: self.bounds.minX, y: self.bounds.maxY),
            CGPoint(x: self.bounds.midX, y: self.bounds.maxY),
            CGPoint(x: self.bounds.maxX, y: self.bounds.maxY),
            CGPoint(x: self.bounds.maxX, y: self.bounds.midY),
            CGPoint(x: self.bounds.maxX, y: self.bounds.minY),
            CGPoint(x: self.bounds.midX, y: self.bounds.minY),
            CGPoint(x: self.bounds.maxX+ControlFrame.rotatePad, y: self.bounds.midY)]

        let path = NSBezierPath()
        path.move(to: CGPoint(x: self.bounds.maxX,
                              y: self.bounds.midY))
        path.line(to: CGPoint(x: self.bounds.maxX+ControlFrame.rotatePad,
                              y: self.bounds.midY))
        let line = CAShapeLayer()
        line.path = path.cgPath
        line.lineWidth = ControlFrame.defaultWidth
        line.strokeColor = ControlFrame.defaultColor
        self.addSublayer(line)

        for i in 0..<dots.count {
            var radius: CGFloat = 0
            if i==dots.count-1 {
                radius = ControlFrame.dot50Size
            }
            let cp = Dot.init(x: dots[i].x,y: dots[i].y,
                              size: ControlFrame.dotSize,
                              offset: CGPoint(x: ControlFrame.dot50Size,
                                              y: ControlFrame.dot50Size),
                              radius: radius, bg: true)
            // mouse track dots
            let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeInActiveApp]
            let area = NSTrackingArea(rect: NSRect(x: self.frame.minX + cp.frame.minX,
                                                   y: self.frame.minY + cp.frame.minY,
                                                   width: cp.frame.width,
                                                   height: cp.frame.height),
                                      options: options, owner: parent)
    
            parent.addTrackingArea(area)

            cp.name = String(i)
            let label = Dot.init(x: cp.bounds.midX,y: cp.bounds.midY,
                                 size: ControlFrame.labelSize,
                                 offset: CGPoint(x: ControlFrame.label50Size,
                                                 y: ControlFrame.label50Size),
                                 radius: ControlFrame.label50Size,  hidden: true)
            cp.addSublayer(label)
            self.addSublayer(cp)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func collideLabel(pos: NSPoint) -> Dot? {
        let mpos = NSPoint(x: pos.x - self.frame.minX,
                           y: pos.y - self.frame.minY)
        for layer in self.sublayers! {
            if let dot = layer as? Dot {
                if dot.collide(origin: mpos, radius: ControlFrame.label50Size) {
                    return dot
                }
            }
        }
        return nil
    }

    func showLabel(layer: CALayer) {
        layer.sublayers?.forEach({$0.isHidden=false})
    }

    func hideLabels() {
        for layer in self.sublayers! {
            layer.sublayers?.forEach({$0.isHidden=true})
        }
    }
}
