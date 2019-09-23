//
//  Curve.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 8/26/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Foundation
import Cocoa

class Curve: Equatable {
    static func == (lhs: Curve, rhs: Curve) -> Bool {
        return lhs.path == rhs.path
    }
    var parent: SketchPad?
    var path: NSBezierPath
    var shape = CAShapeLayer()
    var mask = CAShapeLayer()
    var gradient = CAGradientLayer()
    let canvas = CALayer()

    let dotSize: CGFloat =  set.dotSize
    let dotRadius: CGFloat = set.dotRadius

    var strokeColor = set.strokeColor {
        willSet(value) {
            self.shape.strokeColor = value.cgColor.sRGB(alpha: self.alpha[0])
        }
    }
    var fillColor = set.fillColor {
        willSet(value) {
            if self.fill {
                self.shape.fillColor = value.cgColor.sRGB(alpha: self.alpha[1])
            } else {
                self.shape.fillColor = nil
            }
        }
    }

    var lineWidth: CGFloat = 0.0 {
        willSet(value) {
            self.shape.lineWidth = value
        }
    }
    var angle: CGFloat = 0.0
    var alpha: [CGFloat] = [1.0,1.0] {
        willSet(value) {
            self.shape.strokeColor = self.shape.strokeColor?.sRGB(alpha: value[0])
            if self.fill {
                self.shape.fillColor = self.shape.fillColor?.sRGB(alpha: value[1])
            } else {
                self.shape.fillColor = nil
            }
        }
    }

    var blur: Double = 0.0 {
        willSet(value) {
            self.canvas.setValue(value,
                forKeyPath: "filters.CIGaussianBlur.inputRadius")
        }
    }

    var shadow: [CGFloat] = set.shadow {
        willSet(value) {
            self.canvas.shadowRadius = value[0]
            self.canvas.shadowOpacity = Float(value[1])
            self.canvas.shadowOffset = CGSize(width: value[2],
                                                   height: value[3])
        }
    }

    var shadowColor: NSColor = set.shadowColor {
        willSet(value) {
            self.canvas.shadowColor = value.cgColor
        }
    }

    var gradientColor: [NSColor] = set.gradientColor {
        willSet(value) {
            var alphaColors: [NSColor] = []
            for (i, color) in value.enumerated(){
                let srgb = color.sRGB(alpha: self.gradientOpacity[i])
                alphaColors.append(srgb)

            }
            self.gradient.colors = [alphaColors[0].cgColor,
                                    alphaColors[1].cgColor,
                                    alphaColors[2].cgColor]

        }
    }

    var gradientOpacity: [CGFloat] = [0.0,0.0,0.0] {
        willSet(value) {
            var alphaColors: [NSColor] = []
            for (i, color) in self.gradientColor.enumerated(){
                let srgb = color.sRGB(alpha: value[i])
                alphaColors.append(srgb)

            }
            self.gradient.colors = [alphaColors[0].cgColor,
                                    alphaColors[1].cgColor,
                                    alphaColors[2].cgColor]
        }
    }

    var gradientDirection: [CGPoint] = set.gradientDirection {
        willSet(value) {
            self.gradient.startPoint = value[0]
            self.gradient.endPoint = value[1]
        }
    }

    var gradientLocation: [NSNumber] = set.gradientLocation {
        willSet(value) {
            self.gradient.locations = value
        }
    }

    var cap: Int = 1
    var join: Int = 1
    var dash: [NSNumber] = []

    var rounded: CGPoint?
    var lock: Bool = false
    var points: [ControlPoint] = []
    var edit: Bool = false
    var fill: Bool

    var controlDot: Dot?
    var controlFrame: ControlFrame?
    var frameAngle: CGFloat = 0

    init(parent: SketchPad, path: NSBezierPath,
         fill: Bool = true, rounded: CGPoint?) {
        self.parent = parent
        self.path = path
        self.fill = fill
        self.rounded = rounded
        // filters
        self.canvas.filters = []
    
        self.canvas.backgroundColor = NSColor.clear.cgColor
        // CIPointillize
        for filterName in ["CIGaussianBlur"] {
            if let filter = CIFilter(name: filterName, parameters: ["inputRadius": 0]) {
                self.canvas.filters?.append(filter)
            }
        }

        self.shape.actions = ["position" : NSNull(),
                               "bounds" : NSNull(),
                               "strokeColor" : NSNull(),
                               "fillColor" : NSNull(),
                               "lineWidth" : NSNull()]
        self.gradient.actions = ["position" : NSNull(),
                                 "bounds": NSNull()]
        self.canvas.actions = ["position" : NSNull(),
                               "bounds" : NSNull(),
                               "filters" : NSNull(),
                               "shadowRadius": NSNull(),
                               "shadowOpacity": NSNull(),
                               "shadowOffset": NSNull(),
                               "shadowColor": NSNull()]

        self.canvas.addSublayer(self.shape)
        self.canvas.addSublayer(self.gradient)
        self.parent!.layer?.addSublayer(self.canvas)
        self.updateLayer()
    }

    let CapStyle: [CAShapeLayerLineCap] = [
        .square, .butt, .round
    ]

    func setCap(value: Int) {
        self.cap = value
        self.shape.lineCap = CapStyle[value]
    }

    let JoinStyle: [CAShapeLayerLineJoin] = [
        .miter, .bevel, .round
    ]

    func setJoin(value: Int) {
        self.join = value
        self.shape.lineJoin = JoinStyle[value]
    }

    func setDash(dash: [NSNumber]) {
        self.dash = dash
        if dash.first(where: {
            point in return Int(truncating: point) > 0}) != nil {
            self.shape.lineDashPattern = dash
            self.shape.lineDashPhase = 0
        }
    }

    func setPoints(points: [ControlPoint]) {
        self.points = points
    }

    func insertPoint(pos: NSPoint, index: Int) -> ControlPoint {
        let mp = Dot.init(x: pos.x, y: pos.y, size: self.dotSize,
                          offset: CGPoint(x: self.dotRadius,
                                          y: self.dotRadius),
                          radius: 0,
                          bgColor: nil)

        let cp1 = Dot.init(x: pos.x, y: pos.y, size: self.dotSize,
                           offset: CGPoint(x: self.dotRadius,
                                           y: self.dotRadius),
                           radius: self.dotRadius)

        let cp2 = Dot.init(x: pos.x, y: pos.y, size: self.dotSize,
                           offset: CGPoint(x: self.dotRadius,
                                           y: self.dotRadius),
                           radius: self.dotRadius)

        let cp = ControlPoint.init(mp: mp, cp1: cp1, cp2: cp2)
        if index >= self.points.count {
            self.points.append(cp)
        } else {
            self.points.insert(cp, at: index)
        }
        return cp
    }



//    MARK: Layer func
    func updateLayer() {
        self.shape.path = self.path.cgPath
        self.mask.path = self.path.cgPath
        self.gradient.mask = self.mask

        self.canvas.bounds = self.path.bounds
        self.gradient.bounds = self.canvas.bounds

        self.canvas.position = CGPoint(
            x: self.path.bounds.midX,
            y: self.path.bounds.midY)
        self.gradient.position = self.canvas.position
    }

//    MARK: ControlFrame func
    func createControlFrame() {
        let control = ControlFrame.init(parent: self.parent!,
                                        curve: self)
        self.parent!.layer!.addSublayer(control)
        self.controlFrame = control
    }

    func clearControlFrame() {
        self.clearTrackArea()
        if let control = self.controlFrame {
            control.removeFromSuperlayer()
            self.controlFrame = nil
        }
    }

//    MARK: ControlPoints func
    func createPoints() {
        for point in self.points {
            point.createDots(parent: self.parent!)
        }
    }

    func clearPoints() {
        self.clearTrackArea()
        for point in self.points {
            point.clearDots()
        }
    }

    func insertCurve(at pos: NSPoint, index: Int, points: [NSPoint]) -> NSBezierPath {
        let path = NSBezierPath()
        self.path.copyPath(to: path, start: 0, final: index)
        path.curve(to: pos, controlPoint1: points[0],
                 controlPoint2: pos)
        path.curve(to: points[2], controlPoint1: pos,
                 controlPoint2: points[1])
        self.path.copyPath(to: path, start: index + 1,
                           final: self.path.elementCount)
        return path
    }

    func selectPoint(pos: NSPoint) {
        if !self.lock {
            for point in self.points {
                if point.collideDot(pos: pos, dot: point.mp) {
                    self.controlDot = point.mp
                    return
                } else if point.collideDot(pos: pos, dot: point.cp1) &&
                    !point.cp1.isHidden{
                    self.controlDot = point.cp1
                    return
                } else if point.collideDot(pos: pos, dot: point.cp2) &&
                    !point.cp1.isHidden{
                    self.controlDot = point.cp2
                    return
                } else {
                    point.hideControlDots()
                }
            }
            let collider = NSRect(x:self.path.bounds.minX-2,
                                  y: self.path.bounds.minY-2,
                                  width: self.path.bounds.width+4,
                                  height: self.path.bounds.height+4)
            if collider.contains(pos), let segment = self.path.findPath(pos: pos) {

                let point = self.insertPoint(pos: pos, index: segment.index)
                
                self.controlDot = point.mp

                let path = insertCurve(at: point.mp.position,
                                       index: segment.index,
                                       points: segment.points)
                self.path = path

                self.clearPoints()
                self.createPoints()
                self.updateLayer()
            }
        }
    }

    func editPoint(pos: NSPoint) {
        if !self.lock {
            self.clearTrackArea()
            var find: Bool = false
            for (i, point) in self.points.enumerated() {
                if let dot = self.controlDot {
                    // drag after create
                    if dot == point.mp && point.collideDot(pos: pos, dot: point.cp1)  {
                        let cp2pos = NSPoint(
                            x: dot.position.x - (pos.x - dot.position.x),
                            y: dot.position.y  - (pos.y - dot.position.y))
                        point.cp1.position = pos
                        point.cp2.position = cp2pos
                        find = true
                    } else if dot == point.mp {
                        let deltaPos = NSPoint(
                            x: pos.x - point.mp.position.x,
                            y: pos.y - point.mp.position.y)
                        point.mp.position = pos
                        point.cp1.position = NSPoint(
                            x: point.cp1.position.x+deltaPos.x,
                            y: point.cp1.position.y+deltaPos.y)
                        point.cp2.position = NSPoint(
                            x: point.cp2.position.x+deltaPos.x,
                            y: point.cp2.position.y+deltaPos.y)
                        find = true
                    } else if dot == point.cp1 {
                        point.cp1.position = pos
                        find = true
                    } else if dot == point.cp2 {
                        point.cp2.position = pos
                        find = true
                    }
                    if find {
                        var points = [NSPoint](repeating: .zero, count: 3)
                        let elements = self.path.elementCount
                        var indexLeft: Int = i
                        if i==0  {
                            indexLeft =  elements - 3
                            var pointsStart = [point.mp.position]
                            self.path.setAssociatedPoints(&pointsStart, at: 0)

                            self.path.element(at: 1, associatedPoints: &points)
                            var pointsRight = [point.cp1.position,
                                               points[1], points[2]]
                            self.path.setAssociatedPoints(&pointsRight, at: 1)
                        } else {
                            if i+1<elements-2 {
                                self.path.element(at: i+1, associatedPoints: &points)
                                var pointsRight = [point.cp1.position,
                                                   points[1], points[2]]
                                self.path.setAssociatedPoints(&pointsRight, at: i+1)
                            }
                        }
                        self.path.element(at: indexLeft,associatedPoints: &points)
                        var pointsLeft = [points[0],
                                          point.cp2.position, point.mp.position]
                        self.path.setAssociatedPoints(&pointsLeft,at: indexLeft)
                        point.updateLines()
                    }
                }
                point.trackDot(parent: self.parent!, dot: point.mp)
                self.updateLayer()
            }
        }
    }

    func updatePoints(deltax: CGFloat, deltay: CGFloat) {
        self.clearTrackArea()
        for point in self.points {
            point.updateDots(deltax: deltax, deltay: deltay,
                             parent: self.parent!)
        }
        // update shapes and cgPath
        self.updateLayer()
    }

    func updatePoints(angle: CGFloat) {
        self.clearTrackArea()
        for point in self.points {
            point.rotateDots(ox: self.path.bounds.midX,
                             oy: self.path.bounds.midY,
                             angle: angle,
                             parent: self.parent!)
        }
        self.updateLayer()
    }

    func updatePoints(ox: CGFloat, oy: CGFloat,
                      scalex: CGFloat, scaley: CGFloat) {
        self.clearTrackArea()
        for point in self.points {
            point.scaleDots(ox: ox, oy: oy,
                            scalex: scalex, scaley: scaley,
                            parent: self.parent!)
        }
        self.updateLayer()
    }

//    MARK: Global Control
    func showControl(pos: NSPoint) {
        if !self.lock {
            if self.edit {
                for point in self.points {
                    if point.collideDot(pos: pos, dot: point.mp) {
                        point.showControlDots()
                    } else {
                        point.hideControlDots()
                    }
                }
            } else {
                if let control = self.controlFrame {
                    if let dot = control.collideLabel(pos: pos) {
                        control.showLabel(layer: dot)
                    }
                }
            }
        }
    }

    func hideControl() {
        if !self.edit {
            if let control = self.controlFrame {
                control.hideLabels()
            }
        }
    }


//    MARK: TrackArea
    func clearTrackArea() {
        for trackingArea in self.parent!.trackingAreas {
            if trackingArea != self.parent!.TrackArea {
                self.parent!.removeTrackingArea(trackingArea)
            }
        }
    }

//    MARK: Transform
    func applyTransform(oX: CGFloat, oY: CGFloat, transform: ()->Void) {
        let move = AffineTransform(translationByX: -oX,byY:-oY)
        self.path.transform(using: move)

        transform()

        let moveorigin = AffineTransform(translationByX: oX,byY: oY)
        self.path.transform(using: moveorigin)
    }
}

