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
    var groupFrame: GroupFrame?
    var ctrlPad: CGFloat = setup.dotSize * 4
    var ctrlPad50: CGFloat = setup.dotSize * 2
    var dotSize: CGFloat = setup.dotSize
    var dotRadius: CGFloat = setup.dotRadius
    var dotMag: CGFloat = 0
    var lineWidth: CGFloat = setup.lineWidth
    let lines = [1, 3, 5, 7]

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    init(parent: SketchPad) {
        super.init()
        self.parent = parent
        self.sublayers = []
        if let layer = self.parent!.layer {
            layer.addSublayer(self)
        }
    }

    init(parent: SketchPad, curve: Curve) {
        super.init()
        self.parent = parent
        self.sublayers = []
        let line50 = curve.lineWidth/2

        self.frame = CGRect(x: curve.path.bounds.minX - line50,
                            y: curve.path.bounds.minY - line50,
                            width: curve.path.bounds.width + curve.lineWidth,
                            height: curve.path.bounds.height + curve.lineWidth)

        self.dotSize = parent.dotSize
        self.dotRadius = parent.dotRadius
        self.dotMag = parent.dotMag
        self.ctrlPad = self.dotSize * 4
        self.ctrlPad50 = self.dotSize * 2

        self.lineWidth = parent.lineWidth

        self.borderWidth = self.lineWidth
        self.borderColor = setup.fillColor.cgColor

        var gradientLoc: [CGPoint] = []
        for i in curve.gradientLocation {
            let locX = self.bounds.minX + CGFloat(
                truncating: i) * self.bounds.width
            let locY = self.bounds.minY - self.ctrlPad50
            gradientLoc.append(CGPoint(x: locX, y: locY))
        }

        let gradMinX =  self.bounds.minX + self.ctrlPad50
        let width = self.bounds.width - self.ctrlPad
        let gradMinY = self.bounds.minY + self.ctrlPad50
        let height = self.bounds.height - self.ctrlPad
        let gradientDirStart = CGPoint(
            x: gradMinX + curve.gradientDirection[0].x * width,
            y: gradMinY + curve.gradientDirection[0].y * height)
        let gradientDirFinal = CGPoint(
            x: gradMinX + curve.gradientDirection[1].x * width,
            y: gradMinY + curve.gradientDirection[1].y * height)

        let points: [CGPoint] = [
            CGPoint(x: self.bounds.minX, y: self.bounds.minY),
            CGPoint(x: self.bounds.minX, y: self.bounds.midY),
            CGPoint(x: self.bounds.minX, y: self.bounds.maxY),
            CGPoint(x: self.bounds.midX, y: self.bounds.maxY),
            CGPoint(x: self.bounds.maxX, y: self.bounds.maxY),
            CGPoint(x: self.bounds.maxX, y: self.bounds.midY),
            CGPoint(x: self.bounds.maxX, y: self.bounds.minY),
            CGPoint(x: self.bounds.midX, y: self.bounds.minY),
            CGPoint(x: self.bounds.maxX + self.ctrlPad,
                    y: self.bounds.midY),
            CGPoint(x: self.bounds.maxX + self.ctrlPad50, y: self.bounds.minY),
            gradientDirStart, gradientDirFinal,
            gradientLoc[0], gradientLoc[1], gradientLoc[2]
        ]

        self.initShapes(curve: curve, gradientLoc: gradientLoc,
                        gradientDirStart: gradientDirStart,
                        gradientDirFinal: gradientDirFinal)

        self.initDots(parent: parent, curve: curve, pnt: points)

        self.initRoundedCornerDots(parent: parent, curve: curve,
                                      numDots: points.count)

        let curves = parent.groups[curve.group]

        if curves.count>1 {
            groupFrame = GroupFrame(parent: parent, curves: curves)
        }
        parent.layer?.addSublayer(self)
    }

    deinit {
        self.groupFrame?.removeFromSuperlayer()
        self.groupFrame = nil
    }

    func initShapes(curve: Curve, gradientLoc: [CGPoint],
                    gradientDirStart: CGPoint,
                    gradientDirFinal: CGPoint) {
        let path = NSBezierPath()
        // rotate handle
        path.move(to: CGPoint(x: self.bounds.maxX, y: self.bounds.midY))
        path.line(to: CGPoint(x: self.bounds.maxX + self.ctrlPad,
                              y: self.bounds.midY))
        // gradient on
        path.move(to: CGPoint(x: self.bounds.minX, y: self.bounds.minY))
        path.line(to: CGPoint(x: self.bounds.maxX + self.ctrlPad50,
                              y: self.bounds.minY))
        self.makeShape(path: path, strokeColor: setup.fillColor,
                       lineWidth: self.lineWidth)

        if curve.gradient {
            path.removeAllPoints()
            for point in gradientLoc {
                path.move(to: CGPoint(x: point.x,
                                      y: point.y + self.ctrlPad50))
                path.line(to: point)
            }

            self.makeShape(path: path, strokeColor: setup.fillColor,
                           lineWidth: self.lineWidth)

            path.removeAllPoints()
            path.move(to: gradientDirStart)
            path.line(to: gradientDirFinal)
            self.makeShape(path: path, strokeColor: setup.strokeColor,
                           lineWidth: self.lineWidth)
            self.makeShape(path: path, strokeColor: setup.fillColor,
                           lineWidth: self.lineWidth,
                           dashPattern: setup.controlDashPattern)
        }
    }

    func initDots(parent: SketchPad, curve: Curve, pnt: [CGPoint]) {
        var fillColor = setup.fillColor
        var strokeColor = setup.strokeColor
        var gradIndex = 0
        var rounded = self.dotRadius

        for i in 0..<pnt.count {
            if self.lines.contains(i) {
                var dx: CGFloat = 0
                var dy: CGFloat = 0
                var width = self.frame.width - self.dotSize
                var height: CGFloat = self.dotRadius
                let dt = self.dotMag
                if i==1 || i==5 {
                    dx = i==1 ? -dt : dt
                    width = self.dotRadius
                    height = self.frame.height - self.dotSize
                } else {
                    dy = i==3 ? dt : -dt
                }
                self.makeDot(parent: parent, tag: i,
                             x: pnt[i].x + dx, y: pnt[i].y + dy,
                             width: width, height: height,
                             lineWidth: 0,
                             strokeColor: NSColor.clear,
                             fillColor: NSColor.clear)
                continue
            }
            if i==pnt.count-6 {
                fillColor = setup.strokeColor
                strokeColor = setup.fillColor
                rounded = self.dotRadius/2
            }
            if !curve.gradient && i==pnt.count-5 {
                break
            }

            if i==pnt.count-3 || i==pnt.count-2 || i==pnt.count-1 {
                fillColor = curve.gradientColor[gradIndex]
                strokeColor = setup.strokeColor
                gradIndex += 1
            }
            self.makeDot(parent: parent, tag: i,
                         x: pnt[i].x, y: pnt[i].y,
                         width: self.dotSize, height: self.dotSize,
                         rounded: rounded, lineWidth: self.lineWidth,
                         strokeColor: strokeColor,
                         fillColor: fillColor)
        }
    }

    func initRoundedCornerDots(parent: SketchPad,
                               curve: Curve, numDots: Int) {
        if let rounded = curve.rounded {
            let fillColor = setup.strokeColor
            let strokeColor = setup.fillColor

            let wid50 = self.bounds.width/2
            let hei50 = self.bounds.height/2
            let roundedX = CGPoint(
                x: self.bounds.maxX - rounded.x * wid50,
                y: self.bounds.maxY + self.ctrlPad50)
            let roundedY = CGPoint(
                x: self.bounds.maxX + self.ctrlPad50,
                y: self.bounds.maxY - rounded.y * hei50)

            let path = NSBezierPath()
            path.move(to: CGPoint(x: roundedX.x, y: self.bounds.maxY))
            path.line(to: roundedX)

            path.move(to: CGPoint(x: self.bounds.maxX, y: roundedY.y))
            path.line(to: roundedY)
            self.makeShape(path: path, strokeColor: setup.fillColor,
                           lineWidth: self.lineWidth)

            self.makeDot(parent: parent, tag: numDots,
                         x: roundedX.x, y: roundedX.y,
                         width: self.dotSize, height: self.dotSize,
                         rounded: self.dotRadius, lineWidth: self.lineWidth,
                         strokeColor: strokeColor,
                         fillColor: fillColor)

            self.makeDot(parent: parent, tag: numDots+1,
                         x: roundedY.x, y: roundedY.y,
                         width: self.dotSize, height: self.dotSize,
                         rounded: self.dotRadius, lineWidth: self.lineWidth,
                         strokeColor: strokeColor,
                         fillColor: fillColor)
        }
    }

    func makeDot(parent: SketchPad, tag: Int, x: CGFloat, y: CGFloat,
                 width: CGFloat, height: CGFloat,
                 anchor: CGPoint = CGPoint(x: 0.5, y: 0.5),
                 rounded: CGFloat = 0, lineWidth: CGFloat = setup.lineWidth,
                 strokeColor: NSColor = setup.strokeColor,
                 fillColor: NSColor = setup.fillColor,
                 path: NSBezierPath = NSBezierPath(),
                 dashPattern: [NSNumber] = setup.controlDashPattern) {
        let cp = Dot.init(x: x, y: y, width: width, height: height,
                          rounded: rounded, anchor: anchor,
                          lineWidth: lineWidth,
                          strokeColor: strokeColor,
                          fillColor: fillColor,
                          path: path, dashPattern: dashPattern)

        let options: NSTrackingArea.Options = [
            .mouseEnteredAndExited, .activeInActiveApp]
        let area = NSTrackingArea(
            rect: NSRect(
                x: self.frame.minX + cp.frame.minX,
                y: self.frame.minY + cp.frame.minY,
                width: cp.frame.width, height: cp.frame.height),
            options: options, owner: parent)

        parent.addTrackingArea(area)

        cp.tag = tag
        self.addSublayer(cp)
    }

    func collideControlDot(pos: CGPoint) -> Dot? {
        let mpos = CGPoint(x: pos.x - self.frame.minX,
                           y: pos.y - self.frame.minY)
        for layer in self.sublayers! {
            if let dot = layer as? Dot {
                var circular = true
                if self.lines.contains(dot.tag ?? -1) {
                    circular = false
                }
                if dot.collide(pos: mpos, radius: self.dotSize,
                               circular: circular) {
                    return dot
                }
            }
        }
        return nil
    }

    func increaseDotSize(layer: Dot) {
        if layer.tag == 9 {
            let size = self.dotSize + self.dotMag
            layer.updateSize(width: size, height: size, circle: false)
        }
    }

    func decreaseDotSize() {
        for layer in self.sublayers ?? [] {
            if let dot = layer as? Dot, dot.tag == 9 {
                let size = self.dotSize
                dot.updateSize(width: size, height: size, circle: false)
            }
        }
    }
}
