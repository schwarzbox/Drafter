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
    var line1 = CAShapeLayer()
    var line2 = CAShapeLayer()
    var mpArea: NSTrackingArea?
    var cp1Area: NSTrackingArea?
    var cp2Area: NSTrackingArea?
    
    init(mp: Dot, cp1: Dot, cp2: Dot) {
        self.mp=mp
        self.cp1=cp1
        self.cp2=cp2
        self.hideControlDots()
        self.line1.actions = ["position" : NSNull()]
        self.line2.actions = ["position" : NSNull()]
    }

    func addLine(line: CAShapeLayer, dest: NSPoint) {
        let path = NSBezierPath()

        path.move(to:self.mp.position)
        path.line(to: dest)
        line.path = path.cgPath
        line.lineWidth = 1
        line.strokeColor = set.fillColor.cgColor
    }
    
    func collideDot(pos: NSPoint, dot: Dot) -> Bool {
        if dot.collide(origin: pos, radius: dot.bounds.width) {
            return true
        }
        return false
    }

    func trackDot(parent: SketchPad, dot: Dot) {
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeInActiveApp]
        let area = NSTrackingArea(rect: NSRect(x: dot.frame.minX,
                                               y: dot.frame.minY,
                                               width: dot.frame.width,
                                               height: dot.frame.height),
                                  options: options, owner: parent)
        parent.addTrackingArea(area)
    }

    func createDots(parent: SketchPad) {
        self.hideControlDots()
        parent.layer!.addSublayer(self.mp)
        parent.layer!.addSublayer(self.cp1)
        parent.layer!.addSublayer(self.cp2)
        parent.layer!.addSublayer(self.line1)
        parent.layer!.addSublayer(self.line2)

        self.updateLines()
        self.trackDot(parent: parent, dot: self.mp)
    }

    func clearDots() {
        self.hideControlDots()
        self.mp.removeFromSuperlayer()
        self.cp1.removeFromSuperlayer()
        self.cp2.removeFromSuperlayer()
        self.line1.removeFromSuperlayer()
        self.line2.removeFromSuperlayer()
    }

    func updateLines() {
        self.addLine(line: self.line1,  dest: self.cp1.position)
        self.addLine(line: self.line2,  dest: self.cp2.position)
    }

    func updateDots(deltax: CGFloat, deltay: CGFloat, parent: SketchPad) {
        self.mp.position = CGPoint(x: self.mp.position.x + deltax,
                                 y: self.mp.position.y - deltay)

        self.cp1.position = CGPoint(x: self.cp1.position.x + deltax,
                                  y: self.cp1.position.y - deltay)
        self.cp2.position = CGPoint(x: self.cp2.position.x + deltax,
                                  y: self.cp2.position.y - deltay)

        self.updateLines()

        self.trackDot(parent: parent, dot: self.mp)
    }

    func dot(a: CGPoint, b: CGPoint) -> CGFloat {
        return a.x * b.x + a.y * b.y
    }

    func rotate(pos: CGPoint, ox: CGFloat, oy: CGFloat, matrix: [CGPoint]) -> CGPoint {
        let v = CGPoint(x: pos.x - ox, y: pos.y - oy)
        return CGPoint(x: self.dot(a: matrix[0], b: v) + ox,
                       y: self.dot(a: matrix[1], b: v) + oy)
    }

    func rotateDots(ox: CGFloat, oy: CGFloat, angle: CGFloat, parent: SketchPad) {
        let cs = cos(angle)
        let sn = sin(angle)
        let matrix: [CGPoint] = [CGPoint(x: cs, y: -sn), CGPoint(x: sn, y: cs)]
        self.mp.position = self.rotate(pos: self.mp.position,
                                       ox: ox, oy: oy, matrix: matrix)
        self.cp1.position = self.rotate(pos: self.cp1.position,
                                        ox: ox, oy: oy, matrix: matrix)
        self.cp2.position = self.rotate(pos: self.cp2.position,
                                        ox: ox, oy: oy, matrix: matrix)

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
        self.mp.position = self.scale(ox: ox, oy: oy,
                                      scalex: scalex,
                                      scaley: scaley,
                                      pos: self.mp.position)
        self.cp1.position = self.scale(ox: ox, oy: oy,
                                       scalex: scalex,
                                       scaley: scaley,
                                       pos: self.cp1.position)
        self.cp2.position = self.scale(ox: ox, oy: oy,
                                       scalex: scalex,
                                       scaley: scaley,
                                       pos: self.cp2.position)

        self.updateLines()

        self.trackDot(parent: parent, dot: self.mp)
    }

    func showControlDots() {
        self.cp1.isHidden = false
        self.cp2.isHidden = false
        self.line1.isHidden = false
        self.line2.isHidden = false
    }

    func hideControlDots() {
        self.cp1.isHidden = true
        self.cp2.isHidden = true
        self.line1.isHidden = true
        self.line2.isHidden = true
    }
}
