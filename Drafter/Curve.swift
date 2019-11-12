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
    let imageMask = CAShapeLayer()
    let imageLayer = CAShapeLayer()
    let filterLayer = CAShapeLayer()
    let canvas = CAShapeLayer()

    var layers: [CALayer] = []

    var angle: CGFloat = 0.0
    var lineWidth = setCurve.lineWidth {
        willSet(value) {
            self.canvas.lineWidth = value
            self.filterLayer.lineWidth = value
        }
    }

    var cap: Int = setCurve.lineCap
    var join: Int = setCurve.lineJoin
    var dash: [NSNumber] = setCurve.lineDashPattern

    var colors: [NSColor] = setCurve.colors {
        willSet(value) {
            var gradColors: [CGColor] = []
            for (i, color) in value.enumerated() {
                switch i {
                case 0:
                    let clr = color.cgColor.sRGB(alpha: self.alpha[0])
                    self.canvas.strokeColor = clr
                case 1:
                    let clr = color.cgColor.sRGB(alpha: self.alpha[1])
                    self.canvas.fillColor = clr
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
            self.canvas.strokeColor = self.canvas.strokeColor?.sRGB(
                alpha: value[0])
            self.canvas.fillColor = self.canvas.fillColor?.sRGB(
                alpha: value[1])
            self.canvas.shadowOpacity = Float(value[2])
            var gradColors: [CGColor] = []
            for (i, color) in self.colors.enumerated() where i>2 {
                let srgb = color.cgColor.sRGB(alpha: value[i])
                gradColors.append(srgb)
            }
            self.gradientLayer.colors = gradColors
            self.filterLayer.strokeColor = self.canvas.strokeColor?.sRGB(
                alpha: value[6])
            self.filterLayer.fillColor = self.canvas.fillColor?.sRGB(
                    alpha: value[6])
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

    var blur: Double = setCurve.minBlur {
        willSet(value) {
            self.filterLayer.setValue(value,
                forKeyPath: "filters.CIGaussianBlur.inputRadius")
        }
    }

    var points: [ControlPoint] = []

    var frameAngle: CGFloat = 0
    var rounded: CGPoint?
    var gradient: Bool = false
    var fill: Bool = false
    var edit: Bool = false
    var lock: Bool = false

    var name: String = "" {
        didSet {
            if !oldValue.isEmpty {
                oldName = oldValue
            }
        }
        willSet {
            if oldName.isEmpty {
                oldName = newValue
            }

        }
    }
    var oldName: String = ""
    var controlDot: Dot?
    var controlFrame: ControlFrame?

    var groups: [Curve] = []

    init(parent: SketchPad,
         path: NSBezierPath, fill: Bool = true, rounded: CGPoint?) {
        self.parent = parent
        self.path = path

        self.fill = fill
        self.rounded = rounded
        self.groups = [self]
        self.layers = [imageLayer, gradientLayer, filterLayer]
        // filters
        self.filterLayer.filters = []
        self.filterLayer.backgroundColor = NSColor.clear.cgColor
        // CIPointillize
        for filterName in ["CIGaussianBlur"] {
            if let filter = CIFilter(name: filterName,
                                     parameters: ["inputRadius": 0]) {
                self.filterLayer.filters?.append(filter)
            }
        }
        self.canvas.actions = setEditor.disabledActions
        for i in 0..<self.layers.count {
            self.layers[i].actions = setEditor.disabledActions
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

        } else {
            self.canvas.lineDashPattern = nil
            self.filterLayer.lineDashPattern = nil
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
       for cur in curves where cur.name == newName {
           count+=1
           newName = name + " " + String(count)
       }
        self.name = newName
    }

    func delete() {
        for curve in self.groups {
            curve.imageLayer.removeFromSuperlayer()
            curve.filterLayer.removeFromSuperlayer()
            curve.gradientLayer.removeFromSuperlayer()
            curve.canvas.removeFromSuperlayer()
        }
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
        self.imageMask.path = self.path.cgPath
        self.imageLayer.mask = self.imageMask

        self.filterLayer.path = self.path.cgPath

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
                                  pad: setEditor.dotRadius).contains(pos),
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
            self.clearTrackArea()
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
                point.trackDot(parent: self.parent!, dot: point.mp)
                self.updateLayer()
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

    func removePoint() {
        for (index, point) in self.points.enumerated() {
            if !point.cp1.isHidden || !point.cp2.isHidden {
                self.points.remove(at: index)
                point.delete()
                self.path = self.path.removePath(at: index+1)
                break
            }
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

    func updatePoints(angle: CGFloat, ox: CGFloat, oy: CGFloat) {
        self.clearTrackArea()
        for point in self.points {
            point.rotateDots(ox: ox, oy: oy, angle: angle,
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
                    }
                }
            }
        }
    }

    func hideControl() {
        if !self.edit {
            if let ctrlF = self.controlFrame {
                ctrlF.decreaseDotSize()
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
