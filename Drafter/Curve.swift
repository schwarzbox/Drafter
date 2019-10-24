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
    let gradientMask = CAShapeLayer()
    let gradientLayer = CAGradientLayer()
    let imageMask = CAShapeLayer()
    let imageLayer = CAShapeLayer()
    let filterLayer = CAShapeLayer()
    let canvas = CAShapeLayer()
    var layers: [CALayer] = []

    var angle: CGFloat = 0.0

    var lineWidth = setup.lineWidth {
        willSet(value) {
            self.canvas.lineWidth = value
            self.filterLayer.lineWidth = value
        }
    }

    var cap: Int = setup.lineCap
    var join: Int = setup.lineJoin
    var dash: [NSNumber] = setup.lineDashPattern

    var strokeColor = setup.strokeColor {
        willSet(value) {
            self.canvas.strokeColor = value.cgColor.sRGB(alpha: self.alpha[0])
        }
    }
    var fillColor = setup.fillColor {
        willSet(value) {
            self.canvas.fillColor = value.cgColor.sRGB(alpha: self.alpha[1])
        }
    }

    var alpha: [CGFloat] = setup.alpha {
        willSet(value) {
            self.canvas.strokeColor = self.canvas.strokeColor?.sRGB(
                alpha: value[0])
            self.canvas.fillColor = self.canvas.fillColor?.sRGB(
                alpha: value[1])
        }
    }

    var shadow: [CGFloat] = setup.shadow {
        willSet(value) {
            self.canvas.shadowRadius = value[0]
            self.canvas.shadowOpacity = Float(value[1])
            self.canvas.shadowOffset = CGSize(width: value[2],
                                              height: value[3])
        }
    }

    var shadowColor: NSColor = setup.shadowColor {
        willSet(value) {
            self.canvas.shadowColor = value.cgColor
        }
    }

    var gradientColor: [NSColor] = setup.gradientColor {
        willSet(value) {
            var alphaColors: [NSColor] = []
            for (i, color) in value.enumerated() {
                let srgb = color.sRGB(alpha: self.gradientOpacity[i])
                alphaColors.append(srgb)
            }
            self.gradientLayer.colors = [alphaColors[0].cgColor,
                                    alphaColors[1].cgColor,
                                    alphaColors[2].cgColor]
        }
    }

    var gradientOpacity: [CGFloat] = setup.gradientOpacity {
        willSet(value) {
            var alphaColors: [NSColor] = []
            for (i, color) in self.gradientColor.enumerated() {
                let srgb = color.sRGB(alpha: value[i])
                alphaColors.append(srgb)
            }
            self.gradientLayer.colors = [alphaColors[0].cgColor,
                                    alphaColors[1].cgColor,
                                    alphaColors[2].cgColor]
        }
    }

    var gradientDirection: [CGPoint] = setup.gradientDirection {
        willSet(value) {
            self.gradientLayer.startPoint = value[0]
            self.gradientLayer.endPoint = value[1]
        }
    }

    var gradientLocation: [NSNumber] = setup.gradientLocation {
        willSet(value) {
            self.gradientLayer.locations = value
        }
    }

    var filterOpacity: CGFloat = setup.filterOpacity {
        willSet(value) {
            self.filterLayer.strokeColor = self.canvas.strokeColor?.sRGB(
                alpha: value)
            if self.fill {
                self.filterLayer.fillColor = self.canvas.fillColor?.sRGB(
                    alpha: value)
            } else {
                self.self.filterLayer.fillColor = nil
            }
        }
    }

    var blur: Double = setup.minBlur {
          willSet(value) {
              self.filterLayer.setValue(value,
                  forKeyPath: "filters.CIGaussianBlur.inputRadius")
          }
      }

    var boundsPoints: [CGPoint] {
        let line50 = self.lineWidth/2
        return [CGPoint(x: self.path.bounds.midX, y: self.path.bounds.midY),
                CGPoint(x: self.path.bounds.minX-line50,
                        y: self.path.bounds.minY-line50),
                CGPoint(x: self.path.bounds.maxX+line50,
                        y: self.path.bounds.maxY+line50)]
    }

    var rounded: CGPoint?
    var gradient: Bool = false
    var fill: Bool = false

    var points: [ControlPoint] = []
    var edit: Bool = false
    var group: Int = 0
    var lock: Bool = false

    var controlDot: Dot?
    var controlFrame: ControlFrame?
    var frameAngle: CGFloat = 0

    init(parent: SketchPad,
         path: NSBezierPath, fill: Bool = true, rounded: CGPoint?) {
        self.parent = parent
        self.path = path

        self.fill = fill
        self.rounded = rounded

        self.layers = [imageLayer, filterLayer, gradientLayer]
        // filters
        self.filterLayer.filters = []
        self.filterLayer.backgroundColor = NSColor.clear.cgColor
//        // CIPointillize
        for filterName in ["CIGaussianBlur"] {
            if let filter = CIFilter(name: filterName,
                                     parameters: ["inputRadius": 0]) {
                self.filterLayer.filters?.append(filter)
            }
        }

        self.canvas.actions = setup.disabledActions
        for i in 0..<self.layers.count {
            self.layers[i].actions = setup.disabledActions
            self.canvas.addSublayer(layers[i])
        }
        self.updateLayer()
    }

    let lineCapStyles: [CAShapeLayerLineCap] = [
        .square, .butt, .round
    ]

    func setLineCap(value: Int) {
        self.cap = value
        self.canvas.lineCap = lineCapStyles[value]
        self.filterLayer.lineCap = lineCapStyles[value]
    }

    let lineJoinStyles: [CAShapeLayerLineJoin] = [
        .miter, .bevel, .round
    ]

    func setLineJoin(value: Int) {
        self.join = value
        self.canvas.lineJoin = lineJoinStyles[value]
        self.filterLayer.lineJoin = lineJoinStyles[value]
    }

    func setDash(dash: [NSNumber]) {
        self.dash = dash
        if dash.first(where: { num in
            return Int(truncating: num) > 0}) != nil {
            self.canvas.lineDashPattern = dash
             self.filterLayer.lineDashPattern = dash
        }
    }

    func setPoints(points: [ControlPoint]) {
        self.points = points
        // fix points position
        let range = [Int](0..<self.points.count)
        self.moveControlPoints(index: range, tags: [2])
    }

    func insertPoint(pos: CGPoint, index: Int) -> ControlPoint {
        var size = setup.dotSize
        var dotRadius = size/2
        if let parent = self.parent {
            size = parent.dotSize
            dotRadius = parent.dotRadius
        }
        let mp = Dot.init(x: pos.x, y: pos.y,
                          width: size, height: size, rounded: dotRadius)
        let cp1 = Dot.init(x: pos.x, y: pos.y,
                           width: size, height: size, rounded: dotRadius,
                           strokeColor: setup.fillColor,
                           fillColor: setup.strokeColor)
        let cp2 = Dot.init(x: pos.x, y: pos.y,
                           width: size, height: size, rounded: dotRadius,
                           strokeColor: setup.fillColor,
                           fillColor: setup.strokeColor)

        let cp = ControlPoint.init(mp: mp, cp1: cp1, cp2: cp2)
        if index >= self.points.count {
            self.points.append(cp)
        } else {
            self.points.insert(cp, at: index)
        }
        return cp
    }

    func delete() {
        self.imageLayer.removeFromSuperlayer()
        self.filterLayer.removeFromSuperlayer()
        self.gradientLayer.removeFromSuperlayer()
        self.canvas.removeFromSuperlayer()
    }

//    MARK: Layer func
    func updateLayer() {
        self.gradientMask.path = self.path.cgPath
        self.gradientLayer.mask = self.gradientMask
        self.imageMask.path = self.path.cgPath
        self.imageLayer.mask = self.imageMask

        self.filterLayer.path = self.path.cgPath

        self.canvas.path = self.path.cgPath
        self.canvas.bounds = self.path.bounds

        self.canvas.position = CGPoint(
            x: self.path.bounds.midX,
            y: self.path.bounds.midY)

        for i in 0..<self.layers.count {
            self.layers[i].bounds = self.canvas.bounds
            self.layers[i].position = self.canvas.position
        }
    }

//    MARK: ControlPoints func
    func createPoints() {
        for (index, point) in self.points.enumerated() {
            var ex: Int?
            if !self.fill {
                ex = index == 0 ? 1
                    : index == self.points.count-1 ? 0
                    : nil
            }
            point.createDots(parent: self.parent!, exclude: ex)
        }
    }

    func clearPoints() {
        self.clearTrackArea()
        for point in self.points {
            point.hideControlDots(lineWidth: self.parent!.lineWidth)
            point.clearDots()
        }
    }

    func selectPoint(pos: CGPoint) {
        if !self.lock {
            for i in stride(from: self.points.count-1,
                        through: 0, by: -1) {
            let point = self.points[i]
                if let dot = point.collidedPoint(pos: pos) {
                    self.controlDot = dot
                    return
                } else {
                    point.hideControlDots(lineWidth: self.parent!.lineWidth)
                }
            }

            if self.path.rectPath(self.path,
                                  pad: setup.dotRadius).contains(pos),
                let segment = self.path.findPath(pos: pos) {

                let pnt = self.insertPoint(pos: pos,
                                           index: segment.index)
                self.path = self.path.insertCurve(to: pnt.mp.position,
                                      at: segment.index,
                                      with: segment.points)

                self.resetPoints()
                self.controlDot = pnt.mp
                pnt.showControlDots(dotMag: self.parent!.dotMag,
                                    lineWidth: self.parent!.lineWidth)

            }
        }
    }

    func resetPoints() {
        let range = [Int](0..<self.points.count)
        self.moveControlPoints(index: range, tags: [2])
        self.clearPoints()
        self.createPoints()
        self.updateLayer()
    }

    func movePoint(index: Int, point: ControlPoint) {
        var points = [CGPoint](repeating: .zero, count: 3)
        let count = self.path.elementCount
        var indexLeft: Int = index
        var openShift = 1
        if self.fill {
            openShift = 0
        }

        if index==0 {
            indexLeft = count - 3 + openShift
            var pointsStart = [point.mp.position]
            self.path.setAssociatedPoints(&pointsStart, at: 0)
            let count = self.path.elementCount-1
            self.path.setAssociatedPoints(&pointsStart, at: count)

            self.path.element(at: 1, associatedPoints: &points)
            var pointsRight = [point.cp1.position,
                               points[1], points[2]]
            self.path.setAssociatedPoints(&pointsRight, at: 1)
        } else {
            if index+1 < count - 2 + openShift {
                self.path.element(at: index+1, associatedPoints: &points)
                var pointsRight = [point.cp1.position,
                                   points[1], points[2]]
                self.path.setAssociatedPoints(&pointsRight, at: index+1)
            }
        }
        self.path.element(at: indexLeft, associatedPoints: &points)
        var pointsLeft = [points[0],
                          point.cp2.position, point.mp.position]
        self.path.setAssociatedPoints(&pointsLeft, at: indexLeft)

    }

    func moveControlPoints(index: [Int], tags: [Int],
                           offsetX: CGFloat? = nil,
                           offsetY: CGFloat? = nil) {
        for i in index {
            let point = self.points[i]
            let px = offsetX ?? point.mp.position.x
            let py = offsetY ?? point.mp.position.y
            for tag in tags {
                point.dots[tag].position = CGPoint(x: px, y: py)
            }
            self.movePoint(index: i, point: point)
        }
    }

    func editPoint(pos: CGPoint, opt: Bool = false) {
        if !self.lock {
            self.clearTrackArea()
            var find: Bool = false
            for (index, point) in self.points.enumerated() {
                if let dot = self.controlDot {
                    if dot == point.mp {
                        let origin = point.mp.position
                        if opt {
                            point.cp1.position = pos
                            point.cp2.position = CGPoint(
                                x: origin.x - (pos.x - origin.x),
                                y: origin.y - (pos.y - origin.y))
                        } else {
                            let deltaPos = CGPoint(
                                x: pos.x - point.mp.position.x,
                                y: pos.y - point.mp.position.y)
                            point.mp.position = pos
                            point.cp1.position = CGPoint(
                                x: point.cp1.position.x+deltaPos.x,
                                y: point.cp1.position.y+deltaPos.y)
                            point.cp2.position = CGPoint(
                                x: point.cp2.position.x+deltaPos.x,
                                y: point.cp2.position.y+deltaPos.y)
                        }
                        find = true
                    } else if dot == point.cp1 {
                        point.cp1.position = pos
                        find = true
                    } else if dot == point.cp2 {
                        point.cp2.position = pos
                        find = true
                    }
                    if find {
                        self.movePoint(index: index, point: point)
                        point.updateLines()
                    }
                }
                point.trackDot(parent: self.parent!, dot: point.mp)
                self.updateLayer()
            }
        }
    }
//    MARK: Update points
    func updatePoints(deltax: CGFloat, deltay: CGFloat) {
        self.clearTrackArea()
        for point in self.points {
            point.updateDots(deltax: deltax, deltay: deltay,
                             parent: self.parent!)
        }
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

//    MARK: ControlFrame func
    func createControlFrame() {
        self.controlFrame = ControlFrame.init(parent: self.parent!,
                                              curve: self)
    }

    func clearControlFrame() {
        self.clearTrackArea()
        self.controlFrame?.removeFromSuperlayer()
        self.controlFrame = nil
    }

//    MARK: Global Control
    func showControl(pos: CGPoint) {
        if !self.lock {
            if self.edit {
                if self.controlDot == nil {
                    var find = false
                    for i in stride(from: self.points.count-1,
                                    through: 0, by: -1) {
                        let point = self.points[i]
                        if point.collideDot(pos: pos, dot: point.mp) &&
                            !find {
                            point.showControlDots(
                                dotMag: self.parent!.dotMag,
                                lineWidth: self.parent!.lineWidth)
                            find = true
                        } else {
                            point.hideControlDots(
                                lineWidth: self.parent!.lineWidth)
                        }
                    }
                }
            } else {
                if let ctrlF = self.controlFrame {
                    if let dot = ctrlF.collideControlDot(pos: pos) {
                        ctrlF.increaseDotSize(layer: dot)
                    } else if let groupF = ctrlF.groupFrame,
                        let dot = groupF.collideControlDot(pos: pos) {
                        groupF.increaseDotSize(layer: dot)
                    }
                }
            }
        }
    }

    func hideControl() {
        if !self.edit {
            if let ctrlF = self.controlFrame {
                ctrlF.decreaseDotSize()
                if let groupF = ctrlF.groupFrame {
                    groupF.decreaseDotSize()
                }
            }
        }
    }

//    MARK: TrackArea
    func clearTrackArea() {
        for trackingArea in self.parent!.trackingAreas
            where trackingArea != self.parent!.trackArea {
                self.parent!.removeTrackingArea(trackingArea)
        }
    }

//    MARK: Transform
    func applyTransform(oX: CGFloat, oY: CGFloat, transform: () -> Void) {
        let move = AffineTransform(translationByX: -oX, byY: -oY)
        self.path.transform(using: move)

        transform()

        let moveorigin = AffineTransform(translationByX: oX, byY: oY)
        self.path.transform(using: moveorigin)
    }
}
