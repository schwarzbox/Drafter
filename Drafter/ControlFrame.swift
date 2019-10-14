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
    var ctrlPad: CGFloat = setup.dotSize * 4
    var ctrlPad50: CGFloat = setup.dotSize * 2
    var dotSize: CGFloat = setup.dotSize
    var dot50Size: CGFloat = setup.dotSize / 2

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    init(parent: SketchPad, curve: Curve) {
        self.parent = parent
        super.init()
        let line50 = curve.lineWidth/2
        self.frame = CGRect(
            x: curve.path.bounds.minX - line50,
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

        let minX =  self.bounds.minX + self.ctrlPad50
        let width = self.bounds.width - self.ctrlPad
        let minY = self.bounds.minY + self.ctrlPad50
        let height = self.bounds.height - self.ctrlPad
        let gradientDirStart = CGPoint(
            x: minX + curve.gradientDirection[0].x * width,
            y: minY + curve.gradientDirection[0].y * height)
        let gradientDirFinal = CGPoint(
            x: minX + curve.gradientDirection[1].x * width,
            y: minY + curve.gradientDirection[1].y * height)

        let dots: [CGPoint] = [
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

        var fillColor = setup.fillColor
        var strokeColor = setup.strokeColor
        var gradIndex = 0
        for i in 0..<dots.count {
            var radius: CGFloat = 0
            if i==dots.count-6 {
                radius = self.dot50Size
            } else if i==dots.count-5 || i==dots.count-4 {
                fillColor = setup.strokeColor
                strokeColor = setup.fillColor
                radius = self.dot50Size
            } else if i==dots.count-3 || i==dots.count-2 || i==dots.count-1 {
                radius = self.dot50Size/2
                fillColor = curve.gradientColor[gradIndex]
                strokeColor = setup.strokeColor
                gradIndex += 1
            }
            self.makeDot(parent: parent, tag: i,
                         x: dots[i].x, y: dots[i].y, radius: radius,
                         strokeColor: strokeColor, fillColor: fillColor)
        }

        self.initRoundedCornerControl(parent: parent, curve: curve,
                                      numDots: dots.count)
    }

    func initShapes(gradientLoc: [CGPoint],
                    gradientDirStart: CGPoint,
                    gradientDirFinal: CGPoint) {
        let path = NSBezierPath()
        path.move(to: CGPoint(x: self.bounds.maxX, y: self.bounds.midY))
        path.line(to: CGPoint(x: self.bounds.maxX + self.ctrlPad,
                              y: self.bounds.midY))
        for point in gradientLoc {
            path.move(to: CGPoint(x: point.x,
                                  y: point.y + self.ctrlPad50))
            path.line(to: point)
        }

        self.makeShape(path: path, color: setup.fillColor,
                       width: setup.lineWidth)

        path.removeAllPoints()
        path.move(to: gradientDirStart)
        path.line(to: gradientDirFinal)
        self.makeShape(path: path, color: setup.strokeColor,
                       width: setup.lineWidth)

    }

    func initRoundedCornerControl(parent: SketchPad,
                                  curve: Curve, numDots: Int) {
        if let rounded = curve.rounded {
            let fillColor = setup.controlColor
            let strokeColor = setup.strokeColor

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
            self.makeShape(path: path, color: setup.fillColor,
                           width: setup.lineWidth)

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
        let cp = Dot.init(x: x, y: y,
                          size: self.dotSize,
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

    func collideLabel(pos: CGPoint) -> Dot? {
        let mpos = CGPoint(x: pos.x - self.frame.minX,
                           y: pos.y - self.frame.minY)
        for layer in self.sublayers! {
            if let dot = layer as? Dot {
                if dot.collide(origin: mpos,
                               width: self.dotSize) {
                    return dot
                }
            }
        }
        return nil
    }

    func showLabel(layer: Dot) {
        layer.updateSize(size: self.dotSize + 2)
    }

    func hideLabels() {
        for layer in self.sublayers ?? [] {
            if let dot = layer as? Dot {
                dot.updateSize(size: self.dotSize)
            }
        }
    }
}
