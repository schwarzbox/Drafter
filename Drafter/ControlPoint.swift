//
//  ControlPoint.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 8/27/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

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
        self.cp1=cp1
        self.cp2=cp2
        self.dots = [self.cp1, self.cp2, self.mp]
        for (i, dot) in self.dots.enumerated() {
            dot.tag = i
            if i<self.dots.count-1 {
                dot.isHidden = true
            }
        }

        self.lines = [self.line1, self.line2]
        for line in self.lines {
            line.isHidden = true
            line.fillColor = nil
            line.strokeColor = setup.fillColor.cgColor
            line.lineWidth = setup.lineWidth
            line.actions = setup.disabledActions
            line.makeShape(path: NSBezierPath(),
                           strokeColor: setup.strokeColor,
                           dashPattern: setup.controlDashPattern,
                           actions: line.actions)
        }
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
        if dot.collide(pos: pos, radius: dot.bounds.width) &&
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
        self.hideControlDots(lineWidth: parent.lineWidth)

        for (index, line) in self.lines.enumerated() {
            if let ex = exclude {
                if ex != index {
                    parent.layer!.addSublayer(line)
                }
            } else {
                parent.layer!.addSublayer(line)
            }
        }
        self.updateLines(lineWidth: parent.lineWidth)

        for dot in self.dots {
            dot.updateSize(width: parent.dotSize,
                           height: parent.dotSize,
                           lineWidth: parent.lineWidth)
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
        self.trackDot(parent: parent, dot: self.mp)
    }

    func clearDots() {
        for dot in self.dots {
            dot.removeFromSuperlayer()
        }
        for line in self.lines {
            line.removeFromSuperlayer()
        }
    }

    func updateLines(lineWidth: CGFloat? = nil) {
        for (index, shape) in self.lines.enumerated() {
            let path = NSBezierPath()
            path.move(to: self.dots[2].position)
            path.line(to: self.dots[index].position)
            shape.path = path.cgPath
            if let wid = lineWidth {
                shape.lineWidth = wid
            }
            if let dashLayer = shape.sublayers?.first as? CAShapeLayer {
                dashLayer.path = shape.path
                if let wid = lineWidth {
                    dashLayer.lineWidth = wid
                }
            }
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

    func showControlDots(dotMag: CGFloat,
                         lineWidth: CGFloat) {
        self.mp.borderWidth = (lineWidth + dotMag)
        self.makeHidden(items: self.dots, last: 1, hide: false)
        self.makeHidden(items: self.lines, last: 0, hide: false)
    }

    func hideControlDots(lineWidth: CGFloat) {
        self.mp.borderWidth = lineWidth
        self.makeHidden(items: self.dots, last: 1, hide: true)
        self.makeHidden(items: self.lines, last: 0, hide: true)
    }
}
