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
    static let dotSize: CGFloat = setup.dotSize
    static let dot50Size: CGFloat = dotSize / 2
    static let labelSize: CGFloat = dotSize + 4
    static let label50Size: CGFloat = labelSize / 2
    static let ctrlPad: CGFloat = setup.dotSize * 4
    static let ctrlPad50: CGFloat = setup.dotSize * 2

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

        var gradientLoc: [CGPoint] = []
        for i in curve.gradientLocation {
            let locX = self.bounds.minX + CGFloat(
                truncating: i) * self.bounds.width
            let locY = self.bounds.minY - ControlFrame.ctrlPad50
            gradientLoc.append(CGPoint(x: locX, y: locY))
        }

        let minX =  self.bounds.minX + ControlFrame.ctrlPad50
        let width = self.bounds.width - ControlFrame.ctrlPad
        let minY = self.bounds.minY + ControlFrame.ctrlPad50
        let height = self.bounds.height - ControlFrame.ctrlPad
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
            CGPoint(x: self.bounds.maxX + ControlFrame.ctrlPad,
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
                radius = ControlFrame.dot50Size
            } else if i==dots.count-5 || i==dots.count-4 {
                fillColor = setup.strokeColor
                strokeColor = setup.fillColor
            } else if i==dots.count-3 || i==dots.count-2 || i==dots.count-1 {
                radius = ControlFrame.dot50Size/2
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
        path.line(to: CGPoint(x: self.bounds.maxX + ControlFrame.ctrlPad,
                              y: self.bounds.midY))
        for point in gradientLoc {
            path.move(to: CGPoint(x: point.x,
                                  y: point.y + ControlFrame.ctrlPad50))
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
                y: self.bounds.maxY + ControlFrame.ctrlPad50)
            let roundedY = CGPoint(
                x: self.bounds.maxX + ControlFrame.ctrlPad50,
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
                         radius: ControlFrame.dot50Size,
                         strokeColor: strokeColor,
                         fillColor: fillColor)

            self.makeDot(parent: parent, tag: numDots+1,
                         x: roundedY.x, y: roundedY.y,
                         radius: ControlFrame.dot50Size,
                         strokeColor: strokeColor,
                         fillColor: fillColor)
        }
    }

    func makeDot(parent: SketchPad, tag: Int, x: CGFloat, y: CGFloat,
                 radius: CGFloat, strokeColor: NSColor, fillColor: NSColor) {
        let cp = Dot.init(x: x, y: y,
                          size: ControlFrame.dotSize,
                          offset: CGPoint(
                            x: ControlFrame.dot50Size,
                            y: ControlFrame.dot50Size),
                          radius: radius,
                          strokeColor: strokeColor,
                          fillColor: fillColor)
        // mouse track dots
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
        let label = Dot.init(x: cp.bounds.midX, y: cp.bounds.midY,
                             size: ControlFrame.labelSize,
                             offset: CGPoint(
                                x: ControlFrame.label50Size,
                                y: ControlFrame.label50Size),
                             radius: ControlFrame.label50Size,
                             fillColor: nil,
                             hidden: true)
        cp.addSublayer(label)
        self.addSublayer(cp)
    }

    func collideLabel(pos: CGPoint) -> Dot? {
        let mpos = CGPoint(x: pos.x - self.frame.minX,
                           y: pos.y - self.frame.minY)
        for layer in self.sublayers! {
            if let dot = layer as? Dot {
                if dot.collide(origin: mpos,
                               width: ControlFrame.label50Size) {
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
