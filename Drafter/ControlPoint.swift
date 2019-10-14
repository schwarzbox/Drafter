//
//  ControlPoint.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 8/27/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Foundation
import Cocoa

class ControlPoint {
    let mp: Dot
    let cp1: Dot
    let cp2: Dot
    var dots: [Dot] = []
    var line1 = CAShapeLayer()
    var line2 = CAShapeLayer()
    var lines: [CAShapeLayer] = []
    var mpArea: NSTrackingArea?
    var cp1Area: NSTrackingArea?
    var cp2Area: NSTrackingArea?

    init(mp: Dot, cp1: Dot, cp2: Dot) {
        self.mp=mp
        self.mp.tag = 2
        self.cp1=cp1
        self.cp1.tag = 0
        self.cp2=cp2
        self.cp2.tag = 1
        self.dots = [self.cp1, self.cp2, self.mp]
        self.hideControlDots()
        self.line1.actions = ["position": NSNull()]
        self.line2.actions = ["position": NSNull()]
        self.lines = [self.line1, self.line2]
    }

    func copy() -> ControlPoint? {
        if let mp = self.mp.copy() as? Dot,
            let cp1 = self.cp1.copy() as? Dot,
            let cp2 = self.cp2.copy() as? Dot {
            return ControlPoint.init(mp: mp, cp1: cp1, cp2: cp2)
        }
        return nil
    }

    func delete() {
        self.clearDots()
        self.dots = []
        self.lines = []
    }

    func collideDot(pos: CGPoint, dot: Dot) -> Bool {
        if dot.collide(origin: pos, width: dot.bounds.width) &&
            !dot.excluded {
            return true
        }
        return false
    }

    func collidedPoint(pos: CGPoint) -> Dot? {
        for i in stride(from: self.dots.count-1, through: 0, by: -1) {
            let dot = self.dots[i]
            if self.collideDot(pos: pos, dot: dot) && !dot.isHidden {
                return dot
            }
        }
        return nil
    }

    func trackDot(parent: SketchPad, dot: Dot) {
        let options: NSTrackingArea.Options = [
            .mouseEnteredAndExited, .activeInActiveApp]
        let area = NSTrackingArea(rect: NSRect(x: dot.frame.minX,
                                               y: dot.frame.minY,
                                               width: dot.frame.width,
                                               height: dot.frame.height),
                                  options: options, owner: parent)
        parent.addTrackingArea(area)
    }

    func createDots(parent: SketchPad, exclude: Int? = nil) {
        self.hideControlDots()
        let size = setup.dotSize - (parent.zoomed - 1)
        for dot in self.dots {
            dot.updateSize(size: size)
            if let ex = exclude {
                if ex == dot.tag {
                    dot.excluded = true
                } else {
                    parent.layer!.addSublayer(dot)
                }
            } else {
                parent.layer!.addSublayer(dot)
            }
        }
        for (index, line) in self.lines.enumerated() {
            if let ex = exclude {
                if ex != index {
                    parent.layer!.addSublayer(line)
                }
            } else {
                parent.layer!.addSublayer(line)
            }
        }
        self.updateLines()
        self.trackDot(parent: parent, dot: self.mp)
    }

    func clearDots() {
        self.hideControlDots()
        for dot in self.dots {
            dot.removeFromSuperlayer()
        }
        for line in self.lines {
            line.removeFromSuperlayer()
        }
    }

    func updateLines() {
        for (index, shape) in self.lines.enumerated() {
            let path = NSBezierPath()
            path.move(to: self.dots[2].position)
            path.line(to: self.dots[index].position)
            shape.path = path.cgPath
            shape.lineWidth = 1
            shape.strokeColor = setup.fillColor.cgColor
        }
    }

    func updateDots(deltax: CGFloat, deltay: CGFloat, parent: SketchPad) {
        for dot in self.dots {
            dot.position = CGPoint(x: dot.position.x + deltax,
                                       y: dot.position.y - deltay)
        }
        self.updateLines()
        self.trackDot(parent: parent, dot: self.mp)
    }

    func multiplyVector(av: CGPoint, bv: CGPoint) -> CGFloat {
        return av.x * bv.x + av.y * bv.y
    }

    func rotate(pos: CGPoint, ox: CGFloat, oy: CGFloat,
                matrix: [CGPoint]) -> CGPoint {
        let vec = CGPoint(x: pos.x - ox, y: pos.y - oy)
        return CGPoint(
            x: self.multiplyVector(av: matrix[0], bv: vec) + ox,
            y: self.multiplyVector(av: matrix[1], bv: vec) + oy)
    }

    func rotateDots(ox: CGFloat, oy: CGFloat,
                    angle: CGFloat, parent: SketchPad) {
        let cs = cos(angle)
        let sn = sin(angle)
        let matrix: [CGPoint] = [CGPoint(x: cs, y: -sn), CGPoint(x: sn, y: cs)]

        for dot in dots {
            dot.position = self.rotate(pos: dot.position,
                                       ox: ox, oy: oy, matrix: matrix)
        }

        self.updateLines()
        self.trackDot(parent: parent, dot: self.mp)
    }

    func scale(ox: CGFloat, oy: CGFloat,
               scalex: CGFloat, scaley: CGFloat,
               pos: CGPoint) -> CGPoint {
        let dirx = pos.x - ox
        let diry = pos.y - oy
        return CGPoint(x: ox + dirx * scalex, y: oy + diry * scaley)
    }

    func scaleDots(ox: CGFloat, oy: CGFloat,
                   scalex: CGFloat, scaley: CGFloat, parent: SketchPad) {
        for dot in dots {
            dot.position = self.scale(ox: ox, oy: oy,
                                      scalex: scalex,
                                      scaley: scaley,
                                      pos: dot.position)
        }

        self.updateLines()
        self.trackDot(parent: parent, dot: self.mp)
    }

    func makeHidden<T: CALayer>(items: [T], last: Int, hide: Bool) {
        for i in 0..<items.count - last {
            items[i].isHidden = hide
        }
    }

    func showControlDots() {
        let size = setup.dotSize + 2
        self.mp.updateSize(size: size)
        self.makeHidden(items: self.dots, last: 1, hide: false)
        self.makeHidden(items: self.lines, last: 0, hide: false)
    }

    func hideControlDots() {
        self.mp.updateSize(size: setup.dotSize)
        self.makeHidden(items: self.dots, last: 1, hide: true)
        self.makeHidden(items: self.lines, last: 0, hide: true)
    }
}
