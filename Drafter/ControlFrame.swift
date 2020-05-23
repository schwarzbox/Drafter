//
//  ControlFrame.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 8/26/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

class ControlFrame: CAShapeLayer {
    var parent: SketchPad?
    var ctrlPad: CGFloat = setEditor.dotSize * 4
    var ctrlPad50: CGFloat = setEditor.dotSize * 3
    var ctrlRot: CGFloat = setEditor.dotSize * 1.1
    var dotSize: CGFloat = setEditor.dotSize
    var dotRadius: CGFloat = setEditor.dotRadius
    var dotMag: CGFloat = 0

    let frameHandles = [1, 3, 5, 7]

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    init(parent: SketchPad, curve: Curve) {
        super.init()
        self.parent = parent
        self.sublayers = []

        self.frame = parent.groups.count>1
            ? curve.groupRect(curves: parent.groups)
            : curve.groupRect(curves: curve.groups)

        self.dotSize = parent.dotSize
        self.dotRadius = parent.dotRadius
        self.dotMag = parent.dotMag
        self.ctrlPad = self.dotSize * 4
        self.ctrlPad50 = self.dotSize * 3
        self.ctrlRot = self.dotSize * 1.1

        self.lineWidth = parent.lineWidth
        self.lineDashPattern = parent.lineDashPattern

        self.initBorder()

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
            CGPoint(x: self.bounds.minX,
                    y: self.bounds.minY),
            CGPoint(x: self.bounds.minX-self.dotRadius/2,
                    y: self.bounds.midY),
            CGPoint(x: self.bounds.minX,
                    y: self.bounds.maxY),
            CGPoint(x: self.bounds.midX,
                    y: self.bounds.maxY+self.dotRadius/2),
            CGPoint(x: self.bounds.maxX,
                    y: self.bounds.maxY),
            CGPoint(x: self.bounds.maxX+self.dotRadius/2,
                    y: self.bounds.midY),
            CGPoint(x: self.bounds.maxX,
                    y: self.bounds.minY),
            CGPoint(x: self.bounds.midX,
                    y: self.bounds.minY-self.dotRadius/2),
            CGPoint(x: self.bounds.minX-self.ctrlRot,
                    y: self.bounds.minY-self.ctrlRot),
            CGPoint(x: self.bounds.minX-self.ctrlRot,
                    y: self.bounds.maxY+self.ctrlRot),
            CGPoint(x: self.bounds.maxX+self.ctrlRot,
                    y: self.bounds.maxY+self.ctrlRot),
            CGPoint(x: self.bounds.maxX+self.ctrlRot,
                    y: self.bounds.minY-self.ctrlRot),
            CGPoint(x: self.bounds.maxX + self.ctrlPad50, y: self.bounds.minY),
            gradientDirStart, gradientDirFinal,
            gradientLoc[0], gradientLoc[1], gradientLoc[2]
        ]
        defer {
            self.initDots(parent: parent, curve: curve, pnt: points)
            parent.layer?.addSublayer(self)
        }

        guard curve.groups.count == 1 else { return }
        guard parent.groups.count <= 1 else { return }

        self.initGradient(curve: curve, gradientLoc: gradientLoc,
                          gradientDirStart: gradientDirStart,
                          gradientDirFinal: gradientDirFinal)
        self.initRoundedCornerDots(parent: parent, curve: curve,
                                   numDots: points.count)
    }

    func initBorder() {
        let path = NSBezierPath()
        path.appendRect(self.bounds)
        self.makeShape(path: path,
                       strokeColor: setEditor.strokeColor,
                       lineWidth: self.lineWidth)
        path.removeAllPoints()
        path.appendRect(self.bounds)
        self.makeShape(path: path,
                       strokeColor: setEditor.fillColor,
                       lineWidth: self.lineWidth,
                       dashPattern: self.lineDashPattern)
    }

    func initGradient(curve: Curve, gradientLoc: [CGPoint],
                      gradientDirStart: CGPoint,
                      gradientDirFinal: CGPoint) {
        let path = NSBezierPath()

        path.move(to: CGPoint(x: self.bounds.maxX,
                              y: self.bounds.minY))
        path.line(to: CGPoint(x: self.bounds.maxX + self.ctrlPad50,
                              y: self.bounds.minY))
        self.makeShape(path: path,
                       strokeColor: setEditor.fillColor,
                       lineWidth: self.lineWidth)

        if curve.gradient {
            path.removeAllPoints()
            for point in gradientLoc {
                path.move(to: CGPoint(x: point.x,
                                      y: point.y + self.ctrlPad50))
                path.line(to: point)
            }

            self.makeShape(path: path,
                           strokeColor: setEditor.fillColor,
                           lineWidth: self.lineWidth)

            path.removeAllPoints()
            path.move(to: gradientDirStart)
            path.line(to: gradientDirFinal)
            self.makeShape(path: path, strokeColor: setEditor.strokeColor,
                           lineWidth: self.lineWidth)
            self.makeShape(path: path,
                           strokeColor: setEditor.fillColor,
                           lineWidth: self.lineWidth,
                           dashPattern: self.lineDashPattern)
        }

    }

    func initDots(parent: SketchPad, curve: Curve, pnt: [CGPoint]) {
        var fillColor = setEditor.fillColor
        var strokeColor = setEditor.strokeColor
        var gradIndex = 3
        var rounded: CGFloat = 0

        for i in 0..<pnt.count {
            if self.frameHandles.contains(i) {
                let pad = self.dotSize
                var width = self.frame.width - pad
                width = width>0 ? width : 0
                var height: CGFloat = self.dotRadius
                if i==1 || i==5 {
                    width = self.dotRadius
                    height = self.frame.height - pad
                    height = height>0 ? height : 0
                }
                self.makeDot(parent: parent, tag: i,
                             x: pnt[i].x, y: pnt[i].y,
                             width: width, height: height,
                             lineWidth: 0,
                             strokeColor: NSColor.clear,
                             fillColor: NSColor.clear)
                continue
            }
            if i>pnt.count-11 && i<=pnt.count-7 {
                rounded = self.dotRadius
//                fillColor = NSColor.clear
//                strokeColor = NSColor.clear
            }
            if (curve.groups.count>1 || parent.groups.count>1) &&
                i==pnt.count-6 {
                break
            }
            if i==pnt.count-6 {
                fillColor = setEditor.strokeColor
                strokeColor = setEditor.fillColor
                rounded = self.dotRadius/2
            }
            if !curve.gradient && i==pnt.count-5 {
                break
            }

            if i==pnt.count-3 || i==pnt.count-2 || i==pnt.count-1 {
                fillColor = curve.colors[gradIndex]
                strokeColor = setEditor.strokeColor
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
        if let rounded = curve.rounded, curve.points.count>7,
            curve.imageLayer.contents == nil {
            let fillColor = setEditor.strokeColor
            let strokeColor = setEditor.fillColor

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
            self.makeShape(path: path,
                           strokeColor: setEditor.fillColor,
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
                 rounded: CGFloat = 0,
                 lineWidth: CGFloat = setEditor.lineWidth,
                 strokeColor: NSColor = setEditor.strokeColor,
                 fillColor: NSColor = setEditor.fillColor,
                 path: NSBezierPath = NSBezierPath()) {
        let cp = Dot.init(x: x, y: y, width: width, height: height,
                          rounded: rounded, anchor: anchor,
                          lineWidth: lineWidth,
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
        for layer in self.sublayers ?? [] {
            if let dot = layer as? Dot {
                var circular = true
                if self.frameHandles.contains(dot.tag ?? -1) {
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

    func showInteractiveElement(layer: Dot) {
        switch layer.tag {
        case 12:
            let size = self.dotSize + self.dotMag
                       layer.updateSize(width: size, height: size,
                                        lineWidth: self.lineWidth,
                                        circle: false)
//        case 0, 4: setCursor.resizeNESW.set()
//        case 1, 5: setCursor.resizeWE.set()
//        case 2, 6: setCursor.resizeNWSE.set()
//        case 3, 7: setCursor.resizeNS.set()
//        case 8, 10: setCursor.rotateW.set()
//        case 9, 11: setCursor.rotateE.set()
        default:
            break
        }
    }

    func hideInteractiveElement() {
        parent?.tool.cursor.set()

        for layer in self.sublayers ?? [] {
            if let dot = layer as? Dot, dot.tag == 12 {
                let size = self.dotSize
                dot.updateSize(width: size, height: size,
                               lineWidth: self.lineWidth,
                               circle: false)
            }
        }
    }
}
