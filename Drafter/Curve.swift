//
//  Curve.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 8/26/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

class Curve: Equatable {
    static func == (lhs: Curve, rhs: Curve) -> Bool {
        return lhs.path == rhs.path
    }
    var parent: SketchPad?
    var path: NSBezierPath
    let gradientMask = CAShapeLayer()
    let gradientLayer = CAGradientLayer()
    let imageLayer = CAShapeLayer()
    var imageScaleX: CGFloat = 1
    var imageScaleY: CGFloat = 1
    let canvasMask = CAShapeLayer()
    let canvas = CAShapeLayer()

    var layers: [CALayer] = []

    var text: String = ""
    var textDelta: CGPoint?

    var rounded: CGPoint?
    var gradient: Bool = false
    var fill: Bool = false
    var mask: Bool = false
    var edit: Bool = false
    var lock: Bool = false

    var name: String = ""

    var controlDot: Dot?
    var controlDots: [ControlPoint] = []
    var controlFrame: ControlFrame?

    var groups: [Curve] = []

    init(parent: SketchPad,
         path: NSBezierPath, fill: Bool = true, rounded: CGPoint?) {

        self.parent = parent
        self.path = path

        self.fill = fill
        self.rounded = rounded
        self.groups = [self]

        self.layers = [imageLayer, gradientLayer]

        for layer in self.layers {
            layer.actions = setEditor.disabledActions
            layer.contentsGravity = .center
            self.canvas.addSublayer(layer)
        }

        self.canvas.filters = []

        self.canvas.contentsGravity = .center
        self.canvas.actions = setEditor.disabledActions
        self.updateLayer()
    }

    var angle: CGFloat = 0.0
    var lineWidth = setCurve.lineWidth {
        willSet(value) {
            self.canvas.lineWidth = value
            self.imageLayer.lineWidth = value
        }
    }

    var cap: Int = setCurve.lineCap
    var join: Int = setCurve.lineJoin

    var miter = setCurve.miterLimit {
        willSet(value) {
            self.canvas.miterLimit = value
            self.imageLayer.miterLimit = value
        }
    }

    var dash: [NSNumber] = setCurve.lineDashPattern
    var windingRule: Int = setCurve.windingRule
    var maskRule: Int = setCurve.maskRule
    var colors: [NSColor] = setCurve.colors {
        willSet(value) {
            var gradColors: [CGColor] = []
            for (i, color) in value.enumerated() {
                switch i {
                case 0:
                    let clr = color.cgColor.sRGB(alpha: self.alpha[0])
                    if self.imageLayer.contents == nil {
                        if self.filterRadius > 0 {
                            self.canvas.strokeColor = clr.sRGB(
                                alpha: CGFloat(0))
                            self.imageLayer.strokeColor = clr
                        } else {
                            self.canvas.strokeColor = clr
                            self.imageLayer.strokeColor = clr.sRGB(
                                alpha: CGFloat(0))
                        }
                    }
                case 1:
                    let clr = color.cgColor.sRGB(alpha: self.alpha[1])
                    if self.imageLayer.contents == nil {
                        if self.filterRadius > 0 {
                            self.canvas.fillColor = clr.sRGB(
                                alpha: CGFloat(0))
                            self.imageLayer.fillColor = clr
                        } else {
                            self.canvas.fillColor = clr
                            self.imageLayer.fillColor = clr.sRGB(
                                alpha: CGFloat(0))
                        }
                    }
                case 2:
                    let clr = color.cgColor
                    self.canvas.shadowColor = clr
                case 3, 4, 5:
                    let clr = color.cgColor.sRGB(alpha: self.alpha[i])
                    gradColors.append(clr)
                default:
                    break
                }
            }
            self.gradientLayer.colors = gradColors
        }
    }

    var alpha: [CGFloat] = setCurve.alpha {
        willSet(value) {
            self.setStrokeFillAlpha(radius: self.filterRadius,
                stroke: value[0], fill: value[1])

            self.canvas.shadowOpacity = Float(value[2])
            var gradColors: [CGColor] = []
            for (i, color) in self.colors.enumerated() where i>2 {
                let srgb = color.cgColor.sRGB(alpha: value[i])
                gradColors.append(srgb)
            }
            self.gradientLayer.colors = gradColors
        }
    }

    var shadow: [CGFloat] = setCurve.shadow {
        willSet(value) {
            self.canvas.shadowRadius = value[0]
            self.canvas.shadowOffset = CGSize(width: value[1],
                                              height: value[2])
        }
    }

    var gradientDirection: [CGPoint] = setCurve.gradientDirection {
        willSet(value) {
            self.gradientLayer.startPoint = value[0]
            self.gradientLayer.endPoint = value[1]
        }
    }

    var gradientLocation: [NSNumber] = setCurve.gradientLocation {
        willSet(value) {
            self.gradientLayer.locations = value
        }
    }

    var filterRadius: Double = setCurve.minFilterRadius {
        willSet(value) {
            self.setStrokeFillAlpha(radius: value,
                stroke: self.alpha[0], fill: self.alpha[1])
            if let filter = CIFilter(
                name: "CIGaussianBlur",
                parameters: ["inputRadius": value]),
                value>0 {
                self.canvas.filters = [filter]
            } else {
                self.canvas.filters = []
            }
        }
    }

    func setStrokeFillAlpha(radius: Double,
                            stroke: CGFloat, fill: CGFloat) {
        let strokeColor = self.canvas.strokeColor?.sRGB(
            alpha: stroke)
        let fillColor = self.canvas.fillColor?.sRGB(
            alpha: fill)
        let zeroStroke = strokeColor?.sRGB(alpha: CGFloat(0))
        let zeroFill = fillColor?.sRGB(alpha: CGFloat(0))
        if self.imageLayer.contents == nil {
            if radius > 0 {
                self.canvas.strokeColor = zeroStroke
                self.canvas.fillColor = zeroFill
                if self.imageLayer.contents == nil {
                    self.imageLayer.strokeColor = strokeColor
                    self.imageLayer.fillColor = fillColor
                }
                self.imageLayer.opacity = Float(fill)
            } else {
                self.canvas.strokeColor = strokeColor
                self.canvas.fillColor = fillColor
                self.imageLayer.strokeColor = zeroStroke
                self.imageLayer.fillColor = zeroFill
            }
        } else {
            self.imageLayer.opacity = Float(fill)
        }
    }

    var points: [ControlPoint] = []

    var saveAngle: CGFloat?
    var curveAngle: CGFloat = 0

    var saveOrigin: CGPoint?
    var curveOrigin: CGPoint {
        let parentGroups = parent?.groups ?? []
        let bounds = self.groups.count>1
        ? self.groupRect(curves: self.groups, includeStroke: false)
        : self.groupRect(curves: parentGroups, includeStroke: false)
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }

    let lineCapStyles: [CAShapeLayerLineCap] = [
        .square, .butt, .round
    ]

    func setLineCap(value: Int) {
        self.cap = value
        self.canvas.lineCap = lineCapStyles[value]
        self.imageLayer.lineCap = lineCapStyles[value]
    }

    let lineJoinStyles: [CAShapeLayerLineJoin] = [
        .miter, .bevel, .round
    ]

    func setLineJoin(value: Int) {
        self.join = value
        self.canvas.lineJoin = lineJoinStyles[value]
        self.imageLayer.lineJoin = lineJoinStyles[value]
    }

    let windingRules: [CAShapeLayerFillRule] = [
        .nonZero, .evenOdd
    ]

    func setWindingRule(value: Int) {
        self.windingRule = value
        self.canvas.fillRule = windingRules[value]
    }

    func setMaskRule(value: Int) {
        self.maskRule = value
    }

    func setDash(dash: [NSNumber]) {
        self.dash = dash
        if dash.first(where: { num in
            return Int(truncating: num) > 0}) != nil {
            self.canvas.lineDashPattern = dash
            self.imageLayer.lineDashPattern = dash

        } else {
            self.canvas.lineDashPattern = nil
            self.imageLayer.lineDashPattern = nil
        }
    }

    func setPoints(points: [ControlPoint]) {
        self.points = points
        // fix points position
        let range = [Int](0..<self.points.count)
        self.moveControlPoints(index: range, tags: [2])
    }

    func setGroups(curves: [Curve]) {
        self.groups.append(contentsOf: curves)
    }

    func setName(name: String, curves: [Curve]) {
        var count = 1
        var newName = name + " " + String(count)
        var names: [String] = []
        for cur in curves {
            names.append(contentsOf: cur.groups.map { $0.name })
        }
        while names.contains(newName) {
            count+=1
            newName = name + " " + String(count)
        }
        self.name = newName
    }

    func delete() {
        for curve in self.groups {
            curve.imageLayer.removeFromSuperlayer()
            curve.gradientLayer.removeFromSuperlayer()
            curve.canvas.removeFromSuperlayer()
        }
        self.groups.removeAll()
    }

    func boundsPoints(curves: [Curve]) -> [CGPoint] {
        let bounds = self.groupRect(curves: curves, includeStroke: false)
        return [CGPoint(x: bounds.minX, y: bounds.minY),
                CGPoint(x: bounds.midX, y: bounds.midY),
                CGPoint(x: bounds.maxX, y: bounds.maxY)]
    }

    func groupRect(curves: [Curve],
                   includeStroke: Bool = true) -> CGRect {
        var rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        if curves.count>1 {
            var allMinX: [CGFloat] = []
            var allMinY: [CGFloat] = []
            var allMaxX: [CGFloat] = []
            var allMaxY: [CGFloat] = []
            for curve in curves {
                let line50: CGFloat = includeStroke
                    ? curve.lineWidth / 2
                    : 0
                allMinX.append(curve.path.bounds.minX - line50)
                allMinY.append(curve.path.bounds.minY - line50)
                allMaxX.append(curve.path.bounds.maxX + line50)
                allMaxY.append(curve.path.bounds.maxY + line50)
            }
            if let minX = allMinX.min(), let minY = allMinY.min(),
                let maxX = allMaxX.max(), let maxY = allMaxY.max() {

                rect = CGRect(x: minX, y: minY,
                              width: maxX - minX, height: maxY - minY)
            }
        } else {
            let line50: CGFloat = includeStroke
                ? self.lineWidth / 2
                : 0
            rect = CGRect(
                x: self.path.bounds.minX - line50,
                y: self.path.bounds.minY - line50,
                width: self.path.bounds.width + line50 * 2,
                height: self.path.bounds.height + line50 * 2)
        }
        return rect
    }

//    MARK: Layer func
    func updateLayer() {
        self.gradientMask.path = self.path.cgPath
        self.gradientLayer.mask = self.gradientMask

        self.imageLayer.path = self.path.cgPath

        self.canvas.path = self.path.cgPath

        self.canvas.bounds = self.path.bounds
        self.canvas.position = CGPoint(
            x: self.path.bounds.midX,
            y: self.path.bounds.midY)

        for layer in self.layers {
            layer.bounds = self.canvas.bounds
            layer.position = self.canvas.position
        }
    }

//    MARK: Mask
    func reversed() -> Bool {
        let tmpPath = NSBezierPath(rect: self.path.bounds)
        tmpPath.lineWidth = 0
        tmpPath.append(self.path)
        let pnt = CGPoint(x: self.path.bounds.midX,
                          y: self.path.bounds.midY)

        if (tmpPath.contains(pnt) && self.path.contains(pnt)) ||
            (!tmpPath.contains(pnt) && !self.path.contains(pnt)) {
            return true
        }
        return false
    }

    func removeMaskBorderEdge() -> NSBezierPath? {
        let rev = self.reversed()
        let initPath = rev ? self.path : self.path.reversed

        if let path = initPath.copy() as? NSBezierPath {
            let bounds = path.bounds
            let originX: CGFloat = bounds.midX
            let originY: CGFloat = bounds.midY
            let scaleX = (bounds.width+1) / bounds.width
            let scaleY = (bounds.height+1) / bounds.height
            let scale = AffineTransform(scaleByX: scaleX, byY: scaleY)
            path.applyTransform(
                oX: originX, oY: originY,
                transform: {path.transform(using: scale)
            })
            rev ? path.append(self.path.reversed)
                : path.append(self.path)

            return path
        }
        return nil
    }

    func updateMask() {
        if let par = self.parent, self.mask {
            var path = NSBezierPath()
            if self.maskRule==0 {
                path = self.reversed() ? self.path : self.path.reversed
                if let copyPath = path.copy() as? NSBezierPath {
                    path = copyPath
                }
            }
            let bounds = self.groupRect(curves: self.groups)
            for curve in par.curves {
                for cur in curve.groups where cur != self &&
                    cur.fill && !cur.canvas.isHidden {
                    let curBounds = cur.groupRect(curves: cur.groups)
                    if bounds.intersects(curBounds) {
                        if cur.reversed() {
                            path.append(cur.path.reversed)
                        } else {
                            path.append(cur.path)
                        }
                    }
                }
            }
            if path.elementCount>0 {
                if self.maskRule==0, self.lineWidth==0,
                    let scalePath = removeMaskBorderEdge() {
                    path.append(scalePath)
                }
                self.canvasMask.path = path.cgPath
                self.canvas.mask = self.canvasMask
            } else {
                self.canvas.mask = nil
            }
        } else {
            self.canvas.mask = nil
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

    func insertPoint(pos: CGPoint, index: Int) -> ControlPoint {
        let size = parent!.dotSize
        let dotRadius = parent!.dotRadius

        let mp = Dot.init(x: pos.x, y: pos.y,
                         width: size, height: size, rounded: dotRadius)
        let cp1 = Dot.init(x: pos.x, y: pos.y,
                          width: size, height: size, rounded: dotRadius,
                          strokeColor: setEditor.fillColor,
                          fillColor: setEditor.strokeColor)
        let cp2 = Dot.init(x: pos.x, y: pos.y,
                          width: size, height: size, rounded: dotRadius,
                          strokeColor: setEditor.fillColor,
                          fillColor: setEditor.strokeColor)

        let cp = ControlPoint.init(cp1: cp1, cp2: cp2, mp: mp)
        if index >= self.points.count {
            self.points.append(cp)
        } else {
            self.points.insert(cp, at: index)
        }
        return cp
    }

    func findControlDots(pos: CGPoint, ctrl: Bool) -> Bool {
        var find = false
        for i in stride(from: self.points.count-1,
                        through: 0, by: -1) {
            let point = self.points[i]
            if let dot = point.collidedPoint(pos: pos) {
                if ctrl {
                    if find { return find }
                    find = true
                    self.controlDot = dot
                    if !self.controlDots.contains(point) {
                        point.showControlDots(
                            dotMag: self.parent!.dotMag,
                            lineWidth: self.parent!.lineWidth)
                        self.controlDots.append(point)
                    } else {
                        if let ind = self.controlDots.firstIndex(
                            of: point) {
                            point.hideControlDots(
                                lineWidth: self.parent!.lineWidth)
                            self.controlDots.remove(at: ind)
                        }
                    }
                } else {
                    if !find {
                        find = true
                        self.controlDot = dot
                        if !self.controlDots.contains(point) {
                            point.showControlDots(
                                dotMag: self.parent!.dotMag,
                                lineWidth: self.parent!.lineWidth)
                            self.resetControlDots()
                            self.controlDots.append(point)
                        }
                    } else {
                        if !self.controlDots.contains(point) {
                            point.hideControlDots(
                                lineWidth: self.parent!.lineWidth)
                        }
                    }
                }
            }
        }
        return find
    }

    func selectPoint(pos: CGPoint, ctrl: Bool) {
        if self.findControlDots(pos: pos, ctrl: ctrl) {
            return
        }

        self.resetControlDots()

        if !ctrl, self.path.rectPath(self.path,
            pad: setEditor.pathPad).contains(pos),
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
            self.controlDots.append(pnt)
        }
    }

    func centerPoint() -> CGPoint {
        var minX = CGFloat(MAXFLOAT)
        var minY = CGFloat(MAXFLOAT)
        var maxX = CGFloat()
        var maxY = CGFloat()
        for point in self.controlDots {
            minX = min(minX, point.mp.position.x)
            minY = min(minY, point.mp.position.y)
            maxX = max(maxX, point.mp.position.x)
            maxY = max(maxY, point.mp.position.y)
        }
        let rect = CGRect(x: minX, y: minY,
                          width: maxX-minX, height: maxY-minY)
        return CGPoint(x: rect.midX, y: rect.midY)
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

    func editPoint(pos: CGPoint, cmd: Bool = false, opt: Bool = false) {
        if !self.lock {
//            self.clearTrackArea()
            var find: Bool = false
            for (index, point) in self.points.enumerated() {
                if let dot = self.controlDot {
                    let origin = point.mp.position
                    let cp1 = point.cp1.position
                    let cp2 = point.cp2.position
                    let pos2 = CGPoint(x: origin.x - (pos.x - origin.x),
                                       y: origin.y - (pos.y - origin.y))
                    let sameLine = origin.sameLine(cp1: cp1, cp2: cp2)
                    if dot == point.mp {
                        if cmd {
                            point.cp1.position = pos
                            point.cp2.position = pos2
                        } else {
                            let deltaPos = CGPoint(
                                x: pos.x - origin.x,
                                y: pos.y - origin.y)
                            point.mp.position = pos
                            point.cp1.position = CGPoint(
                                x: cp1.x+deltaPos.x,
                                y: cp1.y+deltaPos.y)
                            point.cp2.position = CGPoint(
                                x: cp2.x+deltaPos.x,
                                y: cp2.y+deltaPos.y)
                        }
                        find = true
                    } else if dot == point.cp1 {
                        if (cmd || sameLine) && !opt {
                            point.cp1.position = pos
                            point.cp2.position = pos2
                        } else {
                            point.cp1.position = pos
                        }
                        find = true
                    } else if dot == point.cp2 {
                        if (cmd || sameLine) && !opt {
                            point.cp2.position = pos
                            point.cp1.position = pos2
                        } else {
                            point.cp2.position = pos
                        }
                        find = true
                    }
                    if find {
                        self.movePoint(index: index, point: point)
                        point.updateLines()
                    }
                }
//                point.trackDot(parent: self.parent!, dot: point.mp)
            }
//            self.updateLayer()
        }
    }

    func reset() {
        self.saveAngle = nil
        self.curveAngle = 0
        self.saveOrigin = nil
        self.controlDot = nil
    }

    func resetControlDots() {
        for point in self.controlDots {
            point.hideControlDots(lineWidth: self.parent!.lineWidth)
        }
        self.controlDots.removeAll()
    }

    func resetPoints() {
         let range = [Int](0..<self.points.count)
         self.moveControlPoints(index: range, tags: [2])
         self.clearPoints()
         self.createPoints()
         self.updateLayer()
    }

    func removePoint(pnt: ControlPoint) {
        for (index, point) in self.points.enumerated()
            where point == pnt {
            self.points.remove(at: index)
            point.delete()
            let removeAt = index == self.points.count
                ? index
                : index+1
            self.path = self.path.removePath(at: removeAt)
            break

        }
        self.resetPoints()
    }

//    MARK: Update points
    func updatePoints(deltaX: CGFloat, deltaY: CGFloat) {
        self.clearTrackArea()

        for point in self.points {
            point.updateDots(deltax: deltaX, deltay: deltaY,
                             parent: self.parent!)
        }
        self.updateLayer()
    }

    func updatePoints(matrix: AffineTransform, ox: CGFloat, oy: CGFloat) {
        self.clearTrackArea()

        let matrix: [CGPoint] = [
            CGPoint(x: matrix.m11, y: matrix.m21),
            CGPoint(x: matrix.m12, y: matrix.m22)]
        for point in self.points {
            point.rotateDots(ox: ox, oy: oy, matrix: matrix,
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
    func showControl(pos: CGPoint, ctrl: Bool) {
        if !self.lock {
            if self.edit {
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
                        if !self.controlDots.contains(point) &&
                            self.controlDot != point.mp {
                            point.hideControlDots(
                                lineWidth: self.parent!.lineWidth)
                        }
                    }
                }
            } else {
                if let ctrlF = self.controlFrame {
                    if let dot = ctrlF.collideControlDot(pos: pos) {
                        ctrlF.showInteractiveElement(layer: dot)
                    }
                }
            }
        }
    }

    func hideControl() {
        if self.edit {
            for i in stride(from: self.points.count-1,
                            through: 0, by: -1) {
                let point = self.points[i]
                if !self.controlDots.contains(point) &&
                    self.controlDot != point.mp {
                    point.hideControlDots(
                        lineWidth: self.parent!.lineWidth)
                }
            }
        } else {
            if let ctrlF = self.controlFrame {
                ctrlF.hideInteractiveElement()
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
//  MARK: ImageLayer
    func initImageLayer(image: Any?,
                        scaleX: CGFloat,
                        scaleY: CGFloat) {
        self.alpha = [CGFloat](repeating: 0,
                                count: setCurve.alpha.count)

        self.imageLayer.contents = image
        self.alpha[1] = 1
        self.lineWidth = 0

        self.imageScaleX = scaleX
        self.imageScaleY = scaleY
        self.transformImageLayer()
    }

    func transformImageLayer() {
        if self.imageLayer.contents != nil {
            self.imageLayer.transform = CATransform3DMakeRotation(
                self.angle, 0, 0, 1)
            self.imageLayer.transform = CATransform3DScale(
                self.imageLayer.transform,
                self.imageScaleX, self.imageScaleY, 1)
        }
    }

    func clearFilter() {
        self.canvas.contents = nil
        self.imageLayer.isHidden = false
        self.gradientLayer.isHidden = false
    }

    func applyFilter() {
        let line = self.lineWidth
        let oX = self.canvas.bounds.minX - line / 2
        let oY = self.canvas.bounds.minY - line / 2
        var image: CIImage?
        let wid = Int(self.canvas.bounds.width+line)
        let hei = Int(self.canvas.bounds.height+line)

        self.path.applyTransform(oX: oX, oY: oY,
        transform: {
            self.updateLayer()
            if let img = self.canvas.ciImage(width: wid,
                                             height: hei) {
                image = img
            }
        })
        self.updateLayer()
        self.imageLayer.isHidden = true
        self.gradientLayer.isHidden = true

        if let filter = CIFilter(name: "CIGaussianBlur") {
            filter.setDefaults()
            filter.setValue(image, forKey: kCIInputImageKey)
            filter.setValue(self.filterRadius, forKey: kCIInputRadiusKey)
            if let cImg = filter.value(
                forKey: kCIOutputImageKey) as? CIImage {
                let outputImageRect = NSRectFromCGRect(cImg.extent)

                let canvasImg = NSImage(size: outputImageRect.size)
                canvasImg.lockFocus()
                cImg.draw(at: NSPoint(x: 0, y: 0),
                             from: outputImageRect,
                             operation: .copy,
                             fraction: 1)

                canvasImg.unlockFocus()

                self.canvas.contents = canvasImg.resized(
                    scaleX: 0.5, scaleY: 0.5)
            }
        }
    }
}
