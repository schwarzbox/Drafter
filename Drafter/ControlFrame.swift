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
    var dot50Size: CGFloat = setup.dotSize / 2

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    init(parent: SketchPad) {
        super.init()
        self.parent = parent
        if let layer = self.parent!.layer {
            layer.addSublayer(self)
        }
    }

    init(parent: SketchPad, curve: Curve) {
        super.init()
        self.parent = parent
        let line50 = curve.lineWidth/2

        self.frame = CGRect(x: curve.path.bounds.minX - line50,
                            y: curve.path.bounds.minY - line50,
                            width: curve.path.bounds.width + curve.lineWidth,
                            height: curve.path.bounds.height + curve.lineWidth)

        self.borderWidth = setup.lineWidth
        self.borderColor = setup.fillColor.cgColor

        self.dotSize = setup.dotSize - (parent.zoomed-1)
        self.dot50Size = self.dotSize / 2
        self.ctrlPad = self.dotSize * 4
        self.ctrlPad50 = self.dotSize * 2

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
            gradientDirStart, gradientDirFinal,
            gradientLoc[0], gradientLoc[1], gradientLoc[2]
        ]

        self.initShapes(gradientLoc: gradientLoc,
                        gradientDirStart: gradientDirStart,
                        gradientDirFinal: gradientDirFinal)

        self.initDots(parent: parent, curve: curve, pnt: points)

        self.initRoundedCornerDots(parent: parent, curve: curve,
                                      numDots: points.count)

        let curves = parent.groups[curve.group]

        let numberDots = curve.rounded != nil
            ? points.count + 2
            : points.count

        if curves.count>1 {
            groupFrame = GroupFrame(parent: parent, curves: curves,
                                    numberDots: numberDots)
        }

        if let layer = self.parent!.layer {
            layer.addSublayer(self)
        }
    }

    deinit {
        self.groupFrame?.removeFromSuperlayer()
        self.groupFrame = nil
    }

    func initShapes(gradientLoc: [CGPoint],
                    gradientDirStart: CGPoint,
                    gradientDirFinal: CGPoint) {
        let path = NSBezierPath()
        // rotate handle
        path.move(to: CGPoint(x: self.bounds.maxX, y: self.bounds.midY))
        path.line(to: CGPoint(x: self.bounds.maxX + self.ctrlPad,
                              y: self.bounds.midY))

        for point in gradientLoc {
            path.move(to: CGPoint(x: point.x,
                                  y: point.y + self.ctrlPad50))
            path.line(to: point)
        }

        self.makeShape(path: path, strokeColor: setup.fillColor,
                       lineWidth: setup.lineWidth)

        path.removeAllPoints()
        path.move(to: gradientDirStart)
        path.line(to: gradientDirFinal)
        self.makeShape(path: path, strokeColor: setup.strokeColor,
                       lineWidth: setup.lineWidth)
        self.makeShape(path: path, strokeColor: setup.fillColor,
                       lineWidth: setup.lineWidth,
                       dashPattern: setup.controlDashPattern)
    }

    func initDots(parent: SketchPad, curve: Curve, pnt: [CGPoint]) {
        var fillColor = setup.fillColor
        var strokeColor = setup.strokeColor
        var gradIndex = 0
        for i in 0..<pnt.count {
            var rounded: CGFloat = 0
            if i==pnt.count-6 {
                rounded = self.dot50Size
            } else if i==pnt.count-5 || i==pnt.count-4 {
                fillColor = setup.strokeColor
                strokeColor = setup.fillColor
                rounded = self.dot50Size
            } else if i==pnt.count-3 || i==pnt.count-2 || i==pnt.count-1 {
                rounded = self.dot50Size/2
                fillColor = curve.gradientColor[gradIndex]
                strokeColor = setup.strokeColor
                gradIndex += 1
            }
            self.makeDot(parent: parent, tag: i,
                         x: pnt[i].x, y: pnt[i].y, radius: rounded,
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
                           lineWidth: setup.lineWidth)

            self.makeDot(parent: parent, tag: numDots,
                         x: roundedX.x, y: roundedX.y,
                         radius: self.dot50Size,
                         strokeColor: strokeColor,
                         fillColor: fillColor)

            self.makeDot(parent: parent, tag: numDots+1,
                         x: roundedY.x, y: roundedY.y,
                         radius: self.dot50Size,
                         strokeColor: strokeColor,
                         fillColor: fillColor)
        }
    }

    func makeDot(parent: SketchPad, tag: Int, x: CGFloat, y: CGFloat,
                 radius: CGFloat, strokeColor: NSColor, fillColor: NSColor) {
        let cp = Dot.init(x: x, y: y, size: self.dotSize,
                          offset: CGPoint(
                            x: self.dot50Size,
                            y: self.dot50Size),
                          radius: radius,
                          strokeColor: strokeColor,
                          fillColor: fillColor)

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

                if dot.collide(pos: mpos,
                               width: self.dotSize) {
                    return dot
                }
            }
        }
        return nil
    }

    func increaseDotSize(layer: Dot) {
        layer.updateSize(size: self.dotSize + 2)
    }

    func decreaseDotSize() {
        for layer in self.sublayers ?? [] {
            if let dot = layer as? Dot {
                dot.updateSize(size: self.dotSize)
            }
        }
    }
}
