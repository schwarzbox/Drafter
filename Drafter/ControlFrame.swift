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
    static let labelSize: CGFloat = dotSize + 4
    static let label50Size: CGFloat = labelSize / 2
    static let defaultWidth: CGFloat = set.lineWidth
    static let defaultFillColor: NSColor = set.fillColor
    static let defaultStrokeColor: NSColor = set.strokeColor
    static let controlPad: CGFloat = set.dotSize * 4
    static let controlPad50: CGFloat = set.dotSize * 2

    init(parent: SketchPad, curve: Curve) {
        self.parent = parent
        super.init()

        self.frame = CGRect(x: curve.path.bounds.minX - curve.lineWidth/2,
                             y:  curve.path.bounds.minY - curve.lineWidth/2,
                             width: curve.path.bounds.width + curve.lineWidth,
                             height: curve.path.bounds.height + curve.lineWidth)

        self.borderWidth = ControlFrame.defaultWidth
        self.borderColor = ControlFrame.defaultFillColor.cgColor

        let gradientLoc0 = self.bounds.minX + CGFloat(truncating: curve.gradientLocation[0]) * self.bounds.width
        let gradientLoc1 = self.bounds.minX + CGFloat(truncating: curve.gradientLocation[1]) * self.bounds.width
        let gradientLoc2 = self.bounds.minX + CGFloat(truncating: curve.gradientLocation[2]) * self.bounds.width

        let minX =  self.bounds.minX + ControlFrame.controlPad50
        let width = self.bounds.width - ControlFrame.controlPad
        let minY = self.bounds.minY + ControlFrame.controlPad50
        let height = self.bounds.height - ControlFrame.controlPad
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
            CGPoint(x: self.bounds.maxX + ControlFrame.controlPad,
                    y: self.bounds.midY),
            gradientDirStart,
            gradientDirFinal,
            CGPoint(x: gradientLoc0,
                    y: self.bounds.minY - ControlFrame.controlPad50),
            CGPoint(x: gradientLoc1,
                    y: self.bounds.minY - ControlFrame.controlPad50),
            CGPoint(x: gradientLoc2,
                    y: self.bounds.minY - ControlFrame.controlPad50)
        ]

        let path = NSBezierPath()
        path.move(to: CGPoint(x: self.bounds.maxX,
                              y: self.bounds.midY))
        path.line(to: CGPoint(x: self.bounds.maxX+ControlFrame.controlPad,
                              y: self.bounds.midY))
        for grad in [gradientLoc0, gradientLoc1, gradientLoc2] {
            path.move(to: CGPoint(x: grad,
                                  y: self.bounds.minY))
            path.line(to: CGPoint(x: grad,
                                  y: self.bounds.minY - ControlFrame.controlPad50))
        }

        self.makeShape(path: path, color: ControlFrame.defaultFillColor,
                       width: ControlFrame.defaultWidth)

        path.removeAllPoints()
        path.move(to: gradientDirStart)
        path.line(to: gradientDirFinal)
        self.makeShape(path: path, color: ControlFrame.defaultStrokeColor,
                       width: ControlFrame.defaultWidth)

        var fillColor = ControlFrame.defaultFillColor
        var strokeColor = ControlFrame.defaultStrokeColor
        var gradIndex = 0
        for i in 0..<dots.count {
            var radius: CGFloat = 0
            if i==dots.count-6 {
                radius = ControlFrame.dot50Size
            } else if i==dots.count-5 || i==dots.count-4 {
                radius = ControlFrame.dot50Size
                fillColor = ControlFrame.defaultStrokeColor
                strokeColor = ControlFrame.defaultFillColor
            } else if i==dots.count-3 || i==dots.count-2 || i==dots.count-1 {
                radius = ControlFrame.dot50Size/2
                fillColor = curve.gradientColor[gradIndex]
                strokeColor = ControlFrame.defaultStrokeColor
                gradIndex += 1
            }
            self.makeDot(parent: parent, tag: i,
                         x: dots[i].x, y: dots[i].y, radius: radius,
                         strokeColor: strokeColor, fillColor: fillColor)
        }
        // rounded rectangle controls
        if let rounded = curve.rounded {
            let fillColor = NSColor.green
            let strokeColor = ControlFrame.defaultStrokeColor

            let wid = self.bounds.width/2
            let hei = self.bounds.height/2
            let roundedX = CGPoint(
                x: self.bounds.maxX - rounded.x * wid,
                y: self.bounds.maxY + ControlFrame.controlPad50)
            let roundedY = CGPoint(
                x: self.bounds.maxX + ControlFrame.controlPad50,
                y: self.bounds.maxY - rounded.y * hei)

            path.removeAllPoints()
            path.move(to: CGPoint(x: roundedX.x,y: self.bounds.maxY))
            path.line(to: roundedX)
     
            path.move(to: CGPoint(x: self.bounds.maxX,y: roundedY.y))
            path.line(to: roundedY)
            self.makeShape(path: path, color: ControlFrame.defaultFillColor,
                           width: ControlFrame.defaultWidth)

            self.makeDot(parent: parent, tag: dots.count,
                         x: roundedX.x, y: roundedX.y,
                         radius: ControlFrame.dot50Size,
                         strokeColor: strokeColor,
                         fillColor: fillColor)

            self.makeDot(parent: parent, tag: dots.count+1,
                         x: roundedY.x, y: roundedY.y,
                         radius: ControlFrame.dot50Size,
                         strokeColor: strokeColor,
                         fillColor: fillColor)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func makeDot(parent: SketchPad, tag: Int, x: CGFloat, y: CGFloat,
                 radius: CGFloat,
                 strokeColor: NSColor, fillColor: NSColor) {
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
            .mouseEnteredAndExited,.activeInActiveApp]
        let area = NSTrackingArea(
            rect: NSRect(
                x: self.frame.minX + cp.frame.minX,
                y: self.frame.minY + cp.frame.minY,
                width: cp.frame.width,height: cp.frame.height),
            options: options, owner: parent)

        parent.addTrackingArea(area)

        cp.tag = tag
        let label = Dot.init(x: cp.bounds.midX,y: cp.bounds.midY,
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

    func collideLabel(pos: NSPoint) -> Dot? {
        let mpos = NSPoint(x: pos.x - self.frame.minX,
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
