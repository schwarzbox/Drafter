//
//  SketchPad.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 8/8/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.

// 0.7

// px sizes

// line stick when not straight
// curve rules to self dots


// Group curves refactor selectedCurve maybe with main frame
// show selected members with numbers

// nice screenshot
// add more info to readme
// update patreon

// refactor init values Outlets
// refactor update sliders
// refactor gestures without drag

// Fast rotate (bug)

// 0.75
// separate edit and create
// Undo Redo
// pen? line?

// 0.77
// add control points to text

//0.8
// Custom filters (proportional)
// CA Filters
// separate blur to filters menu

// 0.9
// change backingLayer on canvas caLayer?(save problen)
// layers with handles above sketchview

// 1.0
// flatneess currve mitter limits fillRule (union)

// 1.5
// save svg
// open svg

// 2.0
// disable unused actions

// save before cmd-w cmd-q AppDelegate

// resize inserted image? in seleected frame
// TextTool (position when zoomed)?
// move lineWidth in out

// drag snap ?
// snapRulers to sketchBounds?

import Cocoa

class SketchPad: NSView {
    var parent: NSViewController?
    weak var toolUI: NSStackView?
    weak var frameUI: FrameButtons!
    weak var textUI: TextTool!
    weak var colorUI: NSStackView!

    weak var curveOpacityStroke: NSSlider!
    weak var curveOpacityFill: NSSlider!

    weak var curveGradStOpacity: NSSlider!
    weak var curveGradMidOpacity: NSSlider!
    weak var curveGradFinOpacity: NSSlider!

    weak var curveStrokeColor: NSBox!
    weak var curveFillColor: NSBox!
    weak var curveShadowColor: NSBox!
    weak var curveGradStartColor: NSBox!
    weak var curveGradMiddleColor: NSBox!
    weak var curveGradFinalColor: NSBox!

    weak var curveShadowOpacity: NSSlider!
    weak var curveShadowRadius: NSSlider!
    weak var curveShadowOffsetX: NSSlider!
    weak var curveShadowOffsetY: NSSlider!

    var trackArea: NSTrackingArea!

    var sketchDir: URL?
    var sketchName: String?
    var sketchExt: String?

    let disabledActions = ["position": NSNull(),
                           "bounds": NSNull(),
                           "path": NSNull()]
    var sketchPath = NSBezierPath()
    let sketchLayer = CAShapeLayer()
    let sketchColor = setup.guiColor

    var editedPath: NSBezierPath = NSBezierPath()
    let editLayer = CAShapeLayer()
    let editColor = setup.strokeColor

    var curvedPath: NSBezierPath = NSBezierPath()
    let curveLayer = CAShapeLayer()
    let curveColor = setup.fillColor

    var controlPath: NSBezierPath = NSBezierPath()
    let controlLayer = CAShapeLayer()

    var rulersPath: NSBezierPath = NSBezierPath()
    let rulersLayer = CAShapeLayer()
    let rulersColor = setup.controlColor
    var movePoint: Dot?

    var controlPoint1: Dot?
    var controlPoint2: Dot?
    var controlPoints: [ControlPoint] = []

    let dotSize: CGFloat =  setup.dotSize
    let dotRadius: CGFloat = setup.dotRadius

    var copiedCurve: Curve?
    var selectedCurve: Curve?
    var curves: [Curve] = []
    var select: [Curve] = []
    var groups: [[Curve]] = []

    var startPos = CGPoint(x: 0, y: 0)

    var editDone: Bool = false
    var closedCurve: Bool = false
    var filledCurve: Bool = true
    var roundedCurve: CGPoint?

    var zoomed: CGFloat = 1.0
    var zoomOrigin = CGPoint(x: 0, y: 0)

    var tool = Tools.drag

    override init(frame: NSRect) {
        super.init(frame: frame)

    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
//        self.layer = CALayer()
        // mouse moved
        let options: NSTrackingArea.Options = [
            .mouseMoved, .activeInActiveApp, .inVisibleRect]
        self.trackArea = NSTrackingArea(rect: self.bounds,
                                  options: options, owner: self)
        self.addTrackingArea(self.trackArea!)

        // edited
        self.editLayer.strokeColor = self.editColor.cgColor
        self.editLayer.fillColor = nil
        self.editLayer.lineWidth = setup.lineWidth
        self.editLayer.lineDashPattern = setup.controlDashPattern
        self.editLayer.path = self.editedPath.cgPath
        self.editLayer.actions = disabledActions
        // curve
        self.curveLayer.strokeColor = self.curveColor.cgColor
        self.curveLayer.fillColor = nil
        self.curveLayer.lineWidth = setup.lineWidth
        self.curveLayer.path = self.curvedPath.cgPath
        self.curveLayer.actions = disabledActions
        // control
        self.controlLayer.strokeColor = self.curveColor.cgColor
        self.controlLayer.fillColor = nil
        self.controlLayer.lineWidth = setup.lineWidth
//        self.controlLayer.lineDashPattern = setup.controlDashPattern
        self.controlLayer.path = self.controlPath.cgPath
        self.controlLayer.actions = disabledActions

        // rulers
        self.rulersLayer.strokeColor = self.rulersColor.cgColor
        self.rulersLayer.fillColor = nil
        self.rulersLayer.lineWidth = setup.lineWidth
        self.rulersLayer.path = self.rulersPath.cgPath
        self.rulersLayer.actions = disabledActions

        // sketch border
        let sketch = NSRect(x: 0, y: 0,
                            width: setup.screenWidth,
                            height: setup.screenHeight)
        self.sketchPath = NSBezierPath(rect: sketch)
        self.sketchLayer.strokeColor = self.sketchColor.cgColor
        self.sketchLayer.fillColor = nil
        self.sketchLayer.lineWidth = setup.lineWidth
        self.sketchLayer.path = self.sketchPath.cgPath
        self.sketchLayer.actions = disabledActions

        self.zoomOrigin = CGPoint(x: self.bounds.midX,
                                  y: self.bounds.midY)

        // filters
        self.layerUsesCoreImageFilters = true
    }

//    MARK: Mouse func
    override func mouseEntered(with event: NSEvent) {
        self.showCurvedPath(event: event)

        if let curve = self.selectedCurve {
            let pos = convert(event.locationInWindow, from: nil)
            curve.showControl(pos: pos)
        }
        self.needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        self.closedCurve = false
        if let curve = self.selectedCurve {
            curve.hideControl()
        }
        self.needsDisplay = true
    }

    override func mouseMoved(with event: NSEvent) {
        self.startPos = convert(event.locationInWindow, from: nil)

        self.clearRulers()
        if self.tool != .drag {
            let snap = self.snapToRulers(points: [self.startPos.x,
                                                  self.startPos.y])
            self.startPos.x -= snap.x
            self.startPos.y -= snap.y
        }

        if let mp = self.movePoint, let cp1 = self.controlPoint1 {
            self.moveCurvedPath(move: mp.position, to: self.startPos,
                                cp1: mp.position,
                                cp2: cp1.position)
            self.updatePathLayer(layer: self.curveLayer,
                                 path: self.curvedPath)
        }

        if let curve = self.selectedCurve, curve.edit {
            self.clearPathLayer(layer: self.editLayer, path: self.editedPath)
            for point in curve.points {
                if point.collidedPoint(pos: self.startPos) != nil {
                    return
                }
            }

            if curve.path.rectPath(
                curve.path, pad: setup.dotRadius).contains(self.startPos),
                let segment = curve.path.findPath(pos: self.startPos) {
                let snap = self.snapToRulers(points: [self.startPos.x,
                                                      self.startPos.y])
                self.startPos.x -= snap.x
                self.startPos.y -= snap.y
                self.editedPath = curve.path.insertCurve(
                    to: self.startPos, at: segment.index, with: segment.points)

                let size = setup.dotSize - (self.zoomed - 1)
                let size50 = size/2

                self.editedPath.appendRect(
                    NSRect(x: self.startPos.x - size50,
                           y: self.startPos.y - size50,
                           width: size, height: size))

                self.updatePathLayer(layer: self.editLayer,
                                     path: self.editedPath)

            }
        }
    }

    override func mouseDragged(with event: NSEvent) {
        let cmd: Bool = event.modifierFlags.contains(.command) ? true : false

        var finPos = convert(event.locationInWindow, from: nil)

        self.clearRulers()
        if let curve = self.selectedCurve, curve.edit {
            self.clearPathLayer(layer: self.editLayer, path: self.editedPath)
            self.clearControls(curve: curve, updatePoints: ())

            if let dot = curve.controlDot, dot.tag == 2 {
                let snap = self.snapToRulers(points: [finPos.x, finPos.y])
                finPos.x -= snap.x
                finPos.y -= snap.y
            }
            curve.editPoint(pos: finPos, cmd: cmd)

        } else if let curve = self.selectedCurve, let dot = curve.controlDot {
            self.dragFrameControlDots(curve: curve, finPos: finPos,
                                      deltaX: event.deltaX,
                                      deltaY: event.deltaY,
                                      dot: dot, cmd: cmd)
        } else {
            if self.tool != .curve && self.tool != .drag {
                let snap = self.snapToRulers(points: [finPos.x, finPos.y])
                finPos.x -= snap.x
                finPos.y -= snap.y
            }
            switch self.tool {
            case .drag:
                self.dragCurve(event: event)
            case .pen:
                self.editedPath.move(to: self.startPos)
                self.editedPath.line(to: finPos)
                self.self.startPos = convert(event.locationInWindow, from: nil)
                self.editedPath.close()
                self.editDone = true
            case .line:
                self.useTool(createLine(
                    topLeft: self.startPos, bottomRight: finPos))
                self.filledCurve = false
            case .triangle:
                self.useTool(createTriangle(
                    topLeft: self.startPos, bottomRight: finPos, cmd: cmd))
            case .oval:
                self.useTool(createOval(
                    topLeft: self.startPos, bottomRight: finPos, cmd: cmd))
            case .rectangle:
                self.useTool(createRectangle(
                    topLeft: self.startPos, bottomRight: finPos, cmd: cmd))
            case .arc:
                self.useTool(createArc(
                    topLeft: self.startPos, bottomRight: finPos))
            case .curve:
                if self.editDone {
                    return
                }
                self.dragCurvedPath(topLeft: self.startPos,
                                    bottomRight: finPos)
            case .text:
                self.createText(topLeft: finPos)
            }
        }

        self.updatePathLayer(layer: self.editLayer, path: self.editedPath)
        self.updatePathLayer(layer: self.controlLayer,
                             path: self.controlPath)
        self.needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        print("down")
        let cmd: Bool = event.modifierFlags.contains(.command) ? true : false
        let opt: Bool = event.modifierFlags.contains(.option) ? true : false

        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("abortTextFields"), object: nil)

        self.clearRulers()
        if let curve = self.selectedCurve, curve.edit {
            curve.selectPoint(pos: self.startPos)
        } else if let curve = self.selectedCurve,
            let dot = curve.controlFrame?.collideLabel(
                pos: self.startPos), !curve.lock {
            curve.controlDot = dot

        } else if let mp = self.movePoint,
            mp.collide(origin: self.startPos, width: mp.bounds.width) {
            self.filledCurve = false
            self.finalSegment(fin: {mp, cp1, cp2 in
                self.editedPath.move(to: mp.position)
                self.controlPoints.append(
                    ControlPoint(mp: mp, cp1: cp1, cp2: cp2))
            })

        } else if self.movePoint != nil, self.closedCurve {
            self.finalSegment(fin: {mp, cp1, cp2 in
                self.addSegment(mp: mp, cp1: cp1, cp2: cp2)
            })

        } else {
            switch self.tool {
            case .drag:
                self.selectCurve(pos: self.startPos, cmd: cmd)
            case .pen, .line, .triangle, .oval, .rectangle, .arc:
                self.controlPoints = []
                self.editedPath.removeAllPoints()
            case .curve:
                self.createCurve(topLeft: self.startPos)
            case .text:
                self.createText(topLeft: self.startPos)
            }
        }

        if opt {
            self.cloneCurve()
        }

        self.updatePathLayer(layer: self.editLayer, path: self.editedPath)
        self.needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        print("up")
        switch self.tool {
        case .pen, .line, .triangle, .oval, .rectangle, .arc, .drag:
            if let curve = self.selectedCurve {
                self.clearControls(curve: curve)
            }
            if self.editDone {
                self.addCurve()
            }
            if let curve = self.selectedCurve {
                curve.frameAngle = 0
                curve.controlDot = nil
                self.createControls(curve: curve)
            }
        case .curve:
            if let curve = self.selectedCurve, curve.edit || self.editDone {
                self.clearControls(curve: curve)
            }

            if self.editDone {
                self.addCurve()
            }
            if let curve = self.selectedCurve, curve.edit || self.editDone {
                curve.frameAngle = 0
                curve.controlDot = nil
                self.createControls(curve: curve)
            }
        default:
            break
        }

        self.rulersPath.removeAllPoints()
        self.rulersLayer.removeFromSuperlayer()

        self.roundedCurve = nil
        self.closedCurve = false
        self.filledCurve = true
        self.editDone = false

        self.updateSliders()
        self.needsDisplay = true
    }

//    MARK: Control func
    func initCurve(path: NSBezierPath,
                   fill: Bool, rounded: CGPoint?,
                   strokeColor: NSColor, fillColor: NSColor,
                   lineWidth: CGFloat, angle: CGFloat,
                   alpha: [CGFloat], blur: Double,
                   shadow: [CGFloat], shadowColor: NSColor,
                   gradientDirection: [CGPoint],
                   gradientColor: [NSColor],
                   gradientOpacity: [CGFloat],
                   gradientLocation: [NSNumber],
                   cap: Int, join: Int, dash: [NSNumber],
                   points: [ControlPoint]) -> Curve {

        let curve = Curve.init(parent: self, path: path,
                               fill: fill, rounded: rounded)

        curve.strokeColor = strokeColor
        curve.fillColor = fillColor
        curve.lineWidth =  lineWidth
        curve.angle = angle
        curve.alpha = alpha
        curve.blur = blur
        curve.shadow = shadow
        curve.shadowColor = shadowColor
        curve.gradientDirection = gradientDirection
        curve.gradientColor = gradientColor
        curve.gradientOpacity = gradientOpacity
        curve.gradientLocation = gradientLocation
        curve.setLineCap(value: cap)
        curve.setLineJoin(value: join)
        curve.setDash(dash: dash)
        curve.setPoints(points: points)
        return curve
    }

    func addCurve() {
        self.editedPath.printPath()
        guard let path = self.editedPath.copy() as? NSBezierPath,
            path.elementCount > 0 else {
                return
        }

        var shadowValues: [CGFloat] = setup.shadow
        shadowValues[0] = CGFloat(self.curveShadowRadius.doubleValue)
        shadowValues[1] = CGFloat(self.curveShadowOpacity.doubleValue)
        shadowValues[2] = CGFloat(self.curveShadowOffsetX.doubleValue)
        shadowValues[3] = CGFloat(self.curveShadowOffsetY.doubleValue)

        var lineWidth: CGFloat = 0
        switch self.tool {
        case .pen, .line, .curve:
            lineWidth = setup.lineWidth
        default:
            break
        }
        let curve = self.initCurve(
            path: path, fill: self.filledCurve,
            rounded: self.roundedCurve,
            strokeColor: self.curveStrokeColor.fillColor,
            fillColor: self.curveFillColor.fillColor,
            lineWidth: lineWidth,
            angle: 0,
            alpha: [CGFloat(self.curveOpacityStroke.doubleValue),
                    CGFloat(self.curveOpacityFill.doubleValue)],
            blur: setup.minBlur,
            shadow: shadowValues,
            shadowColor: self.curveShadowColor.fillColor,
            gradientDirection: setup.gradientDirection,
            gradientColor: [
                self.curveGradStartColor.fillColor,
                self.curveGradMiddleColor.fillColor,
                self.curveGradFinalColor.fillColor],
            gradientOpacity: [
                CGFloat(self.curveGradStOpacity.doubleValue),
                CGFloat(self.curveGradMidOpacity.doubleValue),
                CGFloat(self.curveGradFinOpacity.doubleValue)],
            gradientLocation: setup.gradientLocation,
            cap: setup.lineCap,
            join: setup.lineJoin,
            dash: setup.lineDashPattern,
            points: self.controlPoints)

        self.layer?.addSublayer(curve.canvas)
        self.curves.append(curve)
        self.setTool(tag: Tools.drag.rawValue)

        self.selectedCurve = curve
    }

    func deselectCurve(curve: Curve) {
        self.clearControls(curve: curve)
        self.frameUI.isOn(on: -1)
        self.selectedCurve = nil
    }

    func selectCurve(pos: CGPoint, cmd: Bool = false) {
        if let curve = self.selectedCurve {
            self.deselectCurve(curve: curve)
        }

        for curve in curves {
            let wid50 = curve.lineWidth/2
            let bounds = NSRect(
                x: curve.path.bounds.minX - wid50,
                y: curve.path.bounds.minY - wid50,
                width: curve.path.bounds.width + curve.lineWidth,
                height: curve.path.bounds.height + curve.lineWidth)
            if bounds.contains(pos) {
                self.selectedCurve = curve
            }
        }

        self.clearPathLayer(layer: self.controlLayer, path: self.controlPath)

        if let curve = self.selectedCurve, cmd {
            if self.select.contains(curve) {
                if let index = self.select.firstIndex(of: curve) {
                    self.select.remove(at: index)
                }
            } else {
                self.select.append(curve)
            }
            self.showSelected()
        } else {
            self.select.removeAll()
        }
    }

    func showSelected() {
        var allMinX: [CGFloat] = []
        var allMinY: [CGFloat] = []
        var allMaxX: [CGFloat] = []
        var allMaxY: [CGFloat] = []
        for curve in self.select {
            allMinX.append(curve.path.bounds.minX)
            allMinY.append(curve.path.bounds.minY)
            allMaxX.append(curve.path.bounds.maxX)
            allMaxY.append(curve.path.bounds.maxY)
        }
        if let minX = allMinX.min(), let minY = allMinY.min(),
            let maxX = allMaxX.max(), let maxY = allMaxY.max() {
            let rect = CGRect(x: minX, y: minY,
                              width: maxX - minX, height: maxY - minY)
            self.controlPath.appendRect(rect)
            self.updatePathLayer(layer: self.controlLayer,
                                 path: self.controlPath)
        }

    }

    func createControls(curve: Curve) {
        if !curve.edit {
            curve.createControlFrame()
        }
        self.frameUI.updateFrame(view: self)
        self.frameUI.show()
        self.needsDisplay = true
    }

    func clearControls(curve: Curve,
                       updatePoints: @autoclosure () -> Void = ()) {
        if !curve.edit {
            curve.clearControlFrame()
        }
        updatePoints()

        self.frameUI.hide()
        self.needsDisplay = true
    }

//    MARK: Sliders
    func updateSliders() {
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("updateSliders"), object: nil)
    }

//    MARK: Rulers
    func snapToRulers(points: [CGFloat], exclude: CGPoint? = nil) -> CGPoint {
        let pathPnt = self.findRulers(points: points)
        self.showRulers(pathPoints: pathPnt)
        return self.deltaRulers(pathPoints: pathPnt, exclude: exclude)
    }

    func clearRulers() {
        self.rulersPath.removeAllPoints()
        self.rulersLayer.removeFromSuperlayer()
    }

    func showRulers(pathPoints: [(move: CGPoint, line: CGPoint)]) {
        for pnt in pathPoints {
            let mX = abs(pnt.move.x - pnt.line.x) <= setup.rulersDelta
                ? pnt.line.x
                : pnt.move.x
            let mY = abs(pnt.move.y - pnt.line.y) <= setup.rulersDelta
                ? pnt.line.y
                : pnt.move.y
            let move = CGPoint(x: mX, y: mY)
            self.rulersPath.move(to: move)
            self.rulersPath.addPin(pos: move, size: setup.pinSize)
            self.rulersPath.line(to: pnt.line)
            self.rulersPath.addPin(pos: pnt.line, size: setup.pinSize * 2)
            self.rulersPath.close()
        }

        self.updatePathLayer(layer: self.rulersLayer, path: self.rulersPath)
    }

    func deltaRulers(pathPoints: [(move: CGPoint, line: CGPoint)],
                     exclude: CGPoint? = nil) -> CGPoint {
        var deltaX: CGFloat = 0
        var signX: CGFloat = 1
        var deltaY: CGFloat = 0
        var signY: CGFloat = 1

        for pnt in pathPoints {
            if let ex = exclude, pnt.move.x == ex.x, pnt.move.y == ex.y {
                continue
            }
            let dX = pnt.move.x - pnt.line.x
            let dY = pnt.move.y - pnt.line.y
            if abs(dX) < setup.rulersDelta && abs(dX) > deltaX {
                deltaX = abs(dX)
                signX = dX>0 ? 1 : -1
            }
            if abs(dY) < setup.rulersDelta && abs(dY) > deltaY {
                deltaY = abs(dY)
                signY = dY>0 ? 1 : -1
            }
        }
        return CGPoint(x: deltaX * signX, y: deltaY * signY)
    }

    func findRulers(points: [CGFloat]) -> [(move: CGPoint, line: CGPoint)] {
        var pathPoints: [(move: CGPoint, line: CGPoint)] = []
        for cur in self.curves {
            let othPoints = cur.borderedPath
            if points.count == othPoints.count {
                if points[2] == othPoints[2] &&  points[3] == othPoints[3] {
                    continue
                }
            }

            for i in stride(from: 0, to: points.count, by: 2) {
                for j in stride(from: 0, to: othPoints.count, by: 2) {
                    let spx = points[i]
                    let spy = points[i+1]
                    let tpx = othPoints[j]
                    let tpy = othPoints[j+1]
                    if spx < tpx+setup.rulersDelta &&
                        spx > tpx-setup.rulersDelta {
                        var maxSelfY = spy
                        var maxTarY = tpy
                        if i != 2 {
                            let yt1 = abs(othPoints[1] - spy)
                            let yt2 = abs(othPoints[5] - spy)
                            maxTarY = yt1>yt2 ? othPoints[1] : othPoints[5]
                            if points.count > 2 {
                                let ys1 = abs(points[1] - maxTarY)
                                let ys2 = abs(points[5] - maxTarY)
                                maxSelfY = ys1>ys2 ? points[1] : points[5]
                            }
                        }
                        pathPoints.append(
                            (CGPoint(x: spx, y: maxSelfY),
                             CGPoint(x: tpx, y: maxTarY))
                        )
                    }

                    if spy < tpy+setup.rulersDelta &&
                        spy > tpy-setup.rulersDelta {
                        var maxSelfX = spx
                        var maxTarX = tpx
                        if i != 2 {
                            let xt1 = abs(othPoints[0] - spx)
                            let xt2 = abs(othPoints[4] - spx)
                            maxTarX = xt1>xt2 ? othPoints[0] : othPoints[4]
                            if points.count > 2 {
                                let xs1 = abs(points[0] - maxTarX)
                                let xs2 = abs(points[4] - maxTarX)
                                maxSelfX = xs1>xs2 ? points[0] : points[4]
                            }
                        }
                        pathPoints.append(
                            (CGPoint(x: maxSelfX, y: spy),
                             CGPoint(x: maxTarX, y: tpy))
                        )
                    }
                }
            }
        }
        return pathPoints
    }

//    MARK: Zoom func
    func zoomSketch(value: Double) {
        let delta = value / 100

        self.bounds = self.frame
        self.zoomed = CGFloat(delta)
        let originX = self.zoomOrigin.x
        let originY = self.zoomOrigin.y
        self.translateOrigin(to: CGPoint(x: self.frame.midX,
                                         y: self.frame.midY))
        self.scaleUnitSquare(to: NSSize(width: delta,
                                        height: delta))

        self.translateOrigin(to: CGPoint(x: -originX,
                                         y: -originY))
        if let curve = self.selectedCurve {
            self.clearControls(curve: curve)
            self.createControls(curve: curve)
            if curve.edit {
                curve.clearPoints()
                curve.createPoints()
            }
        }
        self.updateControlSize()

        self.updatePathLayer(layer: self.sketchLayer,
                             path: self.sketchPath)

        self.needsDisplay = true
    }

    func setZoomOrigin(deltaX: CGFloat, deltaY: CGFloat) {
        self.zoomOrigin = CGPoint(
            x: (self.zoomOrigin.x - deltaX),
            y: (self.zoomOrigin.y - deltaY))
        self.zoomSketch(value: Double(self.zoomed * 100))
    }

//    MARK: Path func
    func updatePathLayer(layer: CAShapeLayer, path: NSBezierPath) {
        layer.removeFromSuperlayer()
        if path.elementCount>0 {
            layer.path = path.cgPath
            layer.bounds = path.bounds
            layer.position = CGPoint(x: path.bounds.midX,
                                     y: path.bounds.midY)
            self.layer?.addSublayer(layer)
        }
    }

    func clearPathLayer(layer: CAShapeLayer, path: NSBezierPath) {
        layer.removeFromSuperlayer()
        path.removeAllPoints()
    }

    func addDot(pos: CGPoint, radius: CGFloat,
                color: NSColor? = setup.fillColor) -> Dot {
        let size = setup.dotSize - (self.zoomed - 1)
        let offset = size / 2
        return Dot.init(x: pos.x, y: pos.y, size: size,
                        offset: CGPoint(x: offset, y: offset),
                        radius: radius, fillColor: color)
    }

    func addControlPoint(mp: CGPoint,
                         cp1: CGPoint,
                         cp2: CGPoint) -> ControlPoint {
        return ControlPoint(
            mp: addDot(pos: mp, radius: 0),
            cp1: addDot(pos: cp1, radius: self.dotRadius),
            cp2: addDot(pos: cp2, radius: self.dotRadius))
    }

    func addSegment(mp: Dot, cp1: Dot, cp2: Dot) {
        var cPnt = [CGPoint](repeating: .zero, count: 3)
        self.curvedPath.element(at: 1, associatedPoints: &cPnt)
        self.editedPath.curve(to: cPnt[2],
                              controlPoint1: cPnt[0],
                              controlPoint2: cPnt[1])

        self.controlPoints.append(ControlPoint(mp: mp, cp1: cp1, cp2: cp2))
    }

    func updateControlSize() {
        let size = setup.dotSize - (self.zoomed - 1)
        if let mp = self.movePoint {
            mp.updateSize(size: size)
        }
        if let cp1 = self.controlPoint1,
            let cp2 = self.controlPoint2 {
            cp1.updateSize(size: size)
            cp2.updateSize(size: size)
        }
        for point in self.controlPoints {
            point.clearDots()
            for dot in point.dots {
                dot.updateSize(size: size)
                self.layer?.addSublayer(dot)
            }
        }
    }

    func finalSegment(fin: (_ mp: Dot, _ cp1: Dot, _ cp2: Dot) -> Void ) {
        if let mp = self.movePoint,
            let cp1 = self.controlPoint1,
            let cp2 = self.controlPoint2 {

            fin(mp, cp1, cp2)

            if self.filledCurve {
                self.editedPath.close()
            }

            self.clearPathLayer(layer: self.curveLayer,
                                path: self.curvedPath)
            self.clearPathLayer(layer: self.controlLayer,
                                path: self.controlPath)
            self.editDone = true
        }
    }

    func dragCurvedPath(topLeft: CGPoint, bottomRight: CGPoint) {
        let finPos = CGPoint(
            x: topLeft.x - (bottomRight.x - topLeft.x),
            y: topLeft.y - (bottomRight.y - topLeft.y))

        self.clearPathLayer(layer: self.controlLayer, path: self.controlPath)

        self.controlPath.move(to: bottomRight)
        self.controlPath.line(to: finPos)
        if let cp1 = self.controlPoint1,
            let cp2 = self.controlPoint2 {
            cp1.position = CGPoint(x: bottomRight.x, y: bottomRight.y)
            cp2.position = CGPoint(x: finPos.x, y: finPos.y)
            if self.editedPath.elementCount>1 {
                let index = self.editedPath.elementCount-1
                let count = self.controlPoints.count
                let last = self.controlPoints[count-1].cp1
                var cPnt = [last.position, cp2.position, topLeft]
                self.editedPath.setAssociatedPoints(&cPnt, at: index)
            }
        }
    }

    func showCurvedPath(event: NSEvent) {
        let pos = convert(event.locationInWindow, from: nil)
        if editedPath.elementCount>0 {
            for point in controlPoints {
                if let mp = self.movePoint, let cp1 = self.controlPoint1 {
                    if point.collideDot(pos: pos, dot: point.mp) {
                        self.moveCurvedPath(move: mp.position,
                                            to: point.mp.position,
                                            cp1: cp1.position,
                                            cp2: point.cp2.position)
                        self.closedCurve = true
                        return
                    }
                }
            }
        }
    }

    func moveCurvedPath(move: CGPoint, to: CGPoint,
                        cp1: CGPoint, cp2: CGPoint) {
        if self.closedCurve {
            return
        }
        self.clearPathLayer(layer: self.curveLayer, path: self.curvedPath)
        self.curvedPath.move(to: move)
        self.curvedPath.curve(to: to,
                              controlPoint1: cp1,
                              controlPoint2: cp2)
    }

    func clearCurvedPath() {
        self.clearPathLayer(layer: self.editLayer, path: self.editedPath)
        self.clearPathLayer(layer: self.curveLayer, path: self.curvedPath)
        self.clearPathLayer(layer: self.controlLayer, path: self.controlPath)

        for point in self.controlPoints {
            point.mp.removeFromSuperlayer()
            point.cp1.removeFromSuperlayer()
            point.cp2.removeFromSuperlayer()
        }
        self.controlPoints = []

        if let mp = self.movePoint,
            let cp1 = self.controlPoint1,
            let cp2 = self.controlPoint2 {
            mp.removeFromSuperlayer()
            self.movePoint = nil
            self.controlPoint1 = nil
            cp1.removeFromSuperlayer()
            self.controlPoint2 = nil
            cp2.removeFromSuperlayer()
        }

    }

//    MARK: Buttons func
    func sendCurve(name: String) {
        if let curve = self.selectedCurve,
            let index = curves.firstIndex(of: curve), !curve.lock {
            switch name {
            case "up":
                if index<curves.count-1 {
                    curves.swapAt(index + 1, index)
                    self.layer?.sublayers?.swapAt(index + 1, index)
                }
            default:
                if index>0 {
                    curves.swapAt(index - 1, index)
                    self.layer?.sublayers?.swapAt(index - 1, index)
                }
            }
            self.needsDisplay = true
        }
    }

    func flipCurve(name: String) {
        if let curve = self.selectedCurve, !curve.lock {
            let flip: AffineTransform
            var originX: CGFloat = 0
            var originY: CGFloat = 0
            var scalex: CGFloat = 1
            var scaley: CGFloat = 1
            switch name {
            case "hflip":
                scalex = -1
                originX = curve.path.bounds.midX
            default:
                scaley = -1
                originY = curve.path.bounds.midY
            }
            flip = AffineTransform(scaleByX: scalex, byY: scaley)

            curve.applyTransform(oX: originX, oY: originY,
                           transform: {curve.path.transform(using: flip)})

            curve.updatePoints(ox: originX, oy: originY,
                               scalex: scalex, scaley: scaley)

            self.needsDisplay = true
        }
    }

    func copyCurve() {
        if let curve = self.selectedCurve, !curve.edit,
            let path = curve.path.copy() as? NSBezierPath {
            var points: [ControlPoint] = []
            for point in curve.points {
                if let copyPoint = point.copy() {
                     points.append(copyPoint)
                }
            }

            self.copiedCurve = self.initCurve(
                path: path, fill: curve.fill, rounded: curve.rounded,
                strokeColor: curve.strokeColor,
                fillColor: curve.fillColor,
                lineWidth: curve.lineWidth,
                angle: curve.angle,
                alpha: curve.alpha, blur: curve.blur,
                shadow: curve.shadow,
                shadowColor: curve.shadowColor,
                gradientDirection: curve.gradientDirection,
                gradientColor: curve.gradientColor,
                gradientOpacity: curve.gradientOpacity,
                gradientLocation: curve.gradientLocation,
                cap: curve.cap, join: curve.join,
                dash: curve.dash,
                points: points)
        }
    }

    func pasteCurve(to: CGPoint) {
        let edit = self.selectedCurve?.edit ?? false

        if let clone = self.copiedCurve, !edit {
            self.layer?.addSublayer(clone.canvas)
            self.curves.append(clone)
            self.setTool(tag: Tools.drag.rawValue)

            if let curve = self.selectedCurve {
                self.clearControls(curve: curve)
            }

            self.selectedCurve = clone

            self.moveCurve(
                tag: 0, value: Double(to.x))
            self.moveCurve(
                tag: 1, value: Double(to.y))

            self.createControls(curve: clone)
            self.copyCurve()
            self.needsDisplay = true
        }
    }

    func cloneCurve() {
        self.copyCurve()
        if let curve = self.selectedCurve {
            self.pasteCurve(to: CGPoint(
                x: curve.path.bounds.midX, y: curve.path.bounds.midY))
        }
    }

    func editCurve(sender: NSButton) {
        if let curve = self.selectedCurve {
            if sender.state == .off {
                sender.alternateTitle = "done"
                curve.edit = false
                curve.clearPoints()
                curve.createControlFrame()
                self.frameUI.isEnable(all: true)
            } else {
                sender.alternateTitle = "edit"
                curve.edit = true
                curve.clearControlFrame()
                curve.createPoints()
                self.frameUI.isEnable(title: sender.alternateTitle)
                self.setTool(tag: Tools.drag.rawValue)

            }
        }
    }

    func lockCurve(sender: NSButton) {
        if let curve = self.selectedCurve {
            if sender.state == .off {
                sender.title = "🔓"
                self.frameUI.isEnable(all: true)
                curve.lock = false
            } else {
                sender.title = "🔒"
                self.frameUI.isEnable(
                    title: sender.alternateTitle)
                curve.lock = true
            }
        }
    }

    func groupCurve(sender: NSButton) {
        if sender.state == .on {
            if self.select.count > 1 {
                for curve in self.select {
                    curve.group = self.groups.count
                }
                self.groups.append(self.select)
                self.select.removeAll()
                self.clearPathLayer(layer: self.controlLayer,
                                    path: self.controlPath)
                if let curve = self.selectedCurve {
                    self.clearControls(curve: curve)
                }
                print(self.groups)
            }
        } else {
            print("ungroup")
        }
    }

//    MARK: Tools func
    func useTool(_ action: @autoclosure () -> Void) {
        self.editedPath.removeAllPoints()
        action()
        if self.filledCurve {
            self.editedPath.close()
        } 
        self.editDone = true
    }

    func setTool(tag: Int) {
        var tag = tag
        if let curve = self.selectedCurve {
            if curve.edit {
                tag = Tools.drag.rawValue
            } else {
                self.deselectCurve(curve: curve)
            }
        }
        self.select.removeAll()
        self.textUI.hide()
        self.clearCurvedPath()

        if let tool = Tools(rawValue: tag) {
            self.tool = tool
            self.toolUI?.isOn(on: self.tool.rawValue)
        }
    }

    func dragCurve(event: NSEvent) {
        if let curve = self.selectedCurve, !curve.lock {
            let snap = self.snapToRulers(points: curve.borderedPath)

            let deltaX = (event.deltaX - snap.x) / self.zoomed
            let deltaY = (event.deltaY + snap.y) / self.zoomed

            let move = AffineTransform.init(
                translationByX: deltaX,
                byY: -deltaY)
            curve.path.transform(using: move)

            self.clearControls(curve: curve, updatePoints: (
                curve.updatePoints(deltax: deltaX,
                                   deltay: deltaY)
            ))
            self.updateSliders()
        }
    }

    func createLine(topLeft: CGPoint, bottomRight: CGPoint) {
        self.editedPath = NSBezierPath()
        self.editedPath.move(to: topLeft)
        self.editedPath.curve(to: bottomRight,
                              controlPoint1: bottomRight,
                              controlPoint2: bottomRight)
        self.editedPath.move(to: bottomRight)
        self.editedPath.move(to: bottomRight)

        self.controlPoints = [
            self.addControlPoint(mp: topLeft,
                                 cp1: topLeft, cp2: topLeft),
            self.addControlPoint(mp: bottomRight,
                                 cp1: bottomRight, cp2: bottomRight)]
    }

    func createTriangle(topLeft: CGPoint, bottomRight: CGPoint,
                        cmd: Bool = false) {
        let size = self.flipSize(topLeft: topLeft, bottomRight: bottomRight)
        let wid = size.wid
        var hei = size.hei
        if cmd {
            let signHei: CGFloat = hei>0 ? 1 : -1
            hei = abs(wid) * signHei
        }
        let points: [CGPoint] = [
            CGPoint(x: topLeft.x, y: topLeft.y),
            CGPoint(x: topLeft.x, y: topLeft.y + hei),
            CGPoint(x: topLeft.x + wid, y: topLeft.y + hei)
        ]

        self.editedPath = NSBezierPath()
        self.controlPoints = []
        self.editedPath.move(to: points[0])
        for i in 0..<points.count {
            let pnt = points[i]
            self.controlPoints.append(
                self.addControlPoint(mp: pnt, cp1: pnt, cp2: pnt))
            if i == points.count-1 {
                self.editedPath.curve(to: points[0],
                                      controlPoint1: points[0],
                                      controlPoint2: points[0])
            } else {
                self.editedPath.curve(to: points[i+1],
                                      controlPoint1: points[i+1],
                                      controlPoint2: points[i+1])
            }
        }
    }

    func createOval(topLeft: CGPoint, bottomRight: CGPoint, cmd: Bool = false) {
        let size = self.flipSize(topLeft: topLeft, bottomRight: bottomRight)
        let wid = size.wid
        var hei = size.hei
        if cmd {
            let signHei: CGFloat = hei>0 ? 1 : -1
            hei = abs(wid) * signHei
        }

        self.editedPath.appendOval(in: NSRect(x: topLeft.x, y: topLeft.y,
                                              width: wid, height: hei))

        let points = self.editedPath.findPoints(.curveTo)
        if points.count == 4 {
            self.controlPoints = [
                self.addControlPoint(mp: points[3][2],
                                     cp1: points[0][0], cp2: points[3][1]),
                self.addControlPoint(mp: points[0][2],
                                     cp1: points[1][0], cp2: points[0][1]),
                self.addControlPoint(mp: points[1][2],
                                     cp1: points[2][0], cp2: points[1][1]),
                self.addControlPoint(mp: points[2][2],
                                     cp1: points[3][0], cp2: points[2][1])]
        }
    }

    func createRectangle(topLeft: CGPoint, bottomRight: CGPoint,
                         cmd: Bool = false) {
        var botLeft: CGPoint
        var topRight: CGPoint

        if topLeft.x < bottomRight.x && topLeft.y > bottomRight.y {
            botLeft = CGPoint(x: topLeft.x, y: bottomRight.y)
            topRight = CGPoint(x: bottomRight.x, y: topLeft.y)
        } else if topLeft.x < bottomRight.x  && topLeft.y < bottomRight.y {
            botLeft = CGPoint(x: topLeft.x, y: topLeft.y)
            topRight = CGPoint(x: bottomRight.x, y: bottomRight.y)
        } else if topLeft.x > bottomRight.x && topLeft.y > bottomRight.y {
            botLeft = CGPoint(x: bottomRight.x, y: bottomRight.y)
            topRight = CGPoint(x: topLeft.x, y: topLeft.y)
        } else {
            botLeft = CGPoint(x: bottomRight.x, y: topLeft.y)
            topRight = CGPoint(x: topLeft.x, y: bottomRight.y)
        }

        let size = self.flipSize(topLeft: botLeft, bottomRight: topRight)
        var wid = size.wid
        var hei = size.hei

        if cmd && (topLeft.x < bottomRight.x) {
            wid = hei
        } else if cmd && (topLeft.x > bottomRight.x) &&
            (topLeft.y < bottomRight.y) {
             hei = wid
        } else if cmd && (topLeft.x > bottomRight.x) &&
            (topLeft.y > bottomRight.y) {
            wid = hei
            botLeft.x = topRight.x - wid
            botLeft.y = topRight.y - wid
        }

        let points: [CGPoint] = [
            CGPoint(x: botLeft.x, y: botLeft.y + hei),
            CGPoint(x: botLeft.x, y: botLeft.y),
            CGPoint(x: botLeft.x + wid, y: botLeft.y),
            CGPoint(x: botLeft.x + wid, y: botLeft.y + hei)]

        self.editedPath = NSBezierPath()
        self.controlPoints = []
        self.editedPath.move(to: points[0])
        for i in 0..<points.count {
            let pnt = points[i]
            self.controlPoints.append(
                self.addControlPoint(mp: pnt, cp1: pnt, cp2: pnt))
            self.controlPoints.append(
                self.addControlPoint(mp: pnt, cp1: pnt, cp2: pnt))

            self.editedPath.curve(to: pnt,
                                  controlPoint1: pnt, controlPoint2: pnt)
            if i == points.count-1 {
                self.editedPath.curve(to: points[0],
                                      controlPoint1: points[0],
                                      controlPoint2: points[0])
            } else {
                self.editedPath.curve(to: points[i+1],
                                      controlPoint1: points[i+1],
                                      controlPoint2: points[i+1])
            }
        }
        self.roundedCurve = CGPoint(x: 0, y: 0)
    }

    func createArc(topLeft: CGPoint, bottomRight: CGPoint) {
        let size = self.flipSize(topLeft: topLeft,
                                 bottomRight: bottomRight)
        self.editedPath = NSBezierPath()

        let delta = remainder(abs(size.hei/2), 360)

        let startAngle = -delta
        let endAngle = delta

        self.editedPath.move(to: topLeft)
        self.editedPath.appendArc(withCenter: topLeft, radius: size.wid,
                                  startAngle: startAngle, endAngle: endAngle,
                                  clockwise: false)

        var mPnt = [CGPoint](repeating: .zero, count: 1)
        self.editedPath.element(at: 0, associatedPoints: &mPnt)
        var lPnt = [CGPoint](repeating: .zero, count: 1)
        self.editedPath.element(at: 1, associatedPoints: &lPnt)

        self.editedPath = self.editedPath.placeCurve(
            at: 1, with: [lPnt[0], lPnt[0], lPnt[0]], replace: false)

        var fPnt = [CGPoint](repeating: .zero, count: 3)
        self.editedPath.element(
            at: self.editedPath.elementCount-1, associatedPoints: &fPnt)
        self.editedPath = self.editedPath.placeCurve(
            at: self.editedPath.elementCount,
            with: [fPnt[2], fPnt[2], mPnt[0]])

        let points = self.editedPath.findPoints(.curveTo)

        let lst = points.count-1
        if lst > 0 {
            self.controlPoints = [
                self.addControlPoint(mp: points[lst][2],
                                     cp1: points[lst][2], cp2: points[lst][2]),
                self.addControlPoint(mp: points[0][2],
                                     cp1: points[1][0], cp2: points[0][2])]
        }
        if lst > 1 {
            for i in 1..<lst-1 {
                self.controlPoints.append(
                    self.addControlPoint(mp: points[i][2],
                                         cp1: points[i+1][0],
                                         cp2: points[i][1]))
            }
            self.controlPoints.append(
                self.addControlPoint(mp: points[lst-1][2],
                                     cp1: points[lst-1][2],
                                     cp2: points[lst-1][1]))
        }
    }

    func createCurve(topLeft: CGPoint) {
        if let mp = self.movePoint,
            let cp1 = self.controlPoint1,
            let cp2 = self.controlPoint2 {
            self.moveCurvedPath(move: mp.position, to: topLeft,
                                cp1: cp1.position, cp2: topLeft)
            self.addSegment(mp: mp, cp1: cp1, cp2: cp2)
        }

        self.movePoint = addDot(pos: topLeft, radius: 0)
        self.layer?.addSublayer(self.movePoint!)
        self.controlPoint1 = addDot(pos: topLeft, radius: self.dotRadius)
        self.layer?.addSublayer(self.controlPoint1!)
        self.controlPoint2 = addDot(pos: topLeft, radius: self.dotRadius)
        self.layer?.addSublayer(self.controlPoint2!)

        self.clearPathLayer(layer: self.controlLayer, path: self.controlPath)

        if let mp = self.movePoint {
            let options: NSTrackingArea.Options = [
                .mouseEnteredAndExited, .activeInActiveApp]
            let area = NSTrackingArea(rect: NSRect(x: mp.frame.minX,
                                                   y: mp.frame.minY,
                                                   width: mp.frame.width,
                                                   height: mp.frame.height),
                                      options: options, owner: self)
            self.addTrackingArea(area)
        }

        if self.editedPath.elementCount==0 {
            self.editedPath.move(to: topLeft)
        }
    }

    func createText(topLeft: CGPoint) {
        self.textUI.show()
        let deltaX = topLeft.x-self.bounds.minX
        let deltaY = topLeft.y-self.bounds.minY
        self.textUI.setFrameOrigin(CGPoint(
            x: deltaX * self.zoomed,
            y: deltaY * self.zoomed))
    }

//    MARK: Key func
    func deleteCurve() {
        if tool == .curve && self.movePoint != nil {
            self.clearCurvedPath()
            return
        }
        if let curve = self.selectedCurve, !curve.lock,
            let index = self.curves.firstIndex(of: curve) {
            if curve.edit && curve.points.count > 2 {
                curve.path.printPath()
                for (index, point) in curve.points.enumerated() {
                    if !point.cp1.isHidden || !point.cp2.isHidden {
                        curve.points.remove(at: index)
                        point.delete()

                        curve.path = curve.path.removePath(at: index+1)
                        curve.path = curve.path.moveMovePath()
                        break
                    }
                }
                curve.path.printPath()
                curve.resetPoints()
                self.clearControls(curve: curve)
                self.createControls(curve: curve)
            } else {
                curve.clearPoints()
                self.curves.remove(at: index)
                curve.delete()
                self.deselectCurve(curve: curve)

            }
            self.needsDisplay = true
        }
    }

//    MARK: TextTool func
    func glyphsCurve(value: String, sharedFont: NSFont?) {
        self.editedPath = NSBezierPath()
        if value.count > 0 {
            if let font = sharedFont {
                let hei = self.textUI.bounds.height / 2
                let x = (self.textUI.frame.minX) / self.zoomed
                let y = (self.textUI.frame.minY + hei) / self.zoomed

                let pos = CGPoint(x: x + self.bounds.minX,
                                  y: y + self.bounds.minY )
                self.editedPath.move(to: pos)
                for char in value {
                    let glyph = font.glyph(withName: String(char))
                    self.editedPath.append(
                        withCGGlyph: CGGlyph(glyph), in: font)
                }
            }

            if let curve = self.selectedCurve {
                self.clearControls(curve: curve)
            }
            self.addCurve()
            if let curve = self.selectedCurve {
                self.createControls(curve: curve)
            }
            self.needsDisplay = true
            self.updateSliders()
        }
    }

//    MARK: Frame func
    func dragFrameControlDots(curve: Curve, finPos: CGPoint,
                              deltaX: CGFloat, deltaY: CGFloat,
                              dot: Dot, cmd: Bool ) {
//        let exclude = CGPoint(x: curve.path.bounds.midX,
//                              y: curve.path.bounds.midY)
//        let snap = self.snapToRulers(points: curve.borderedPath)
        // tmp
        let pathPnt = self.findRulers(points: curve.borderedPath)
        self.showRulers(pathPoints: pathPnt)

        let dX = (deltaX / self.zoomed)
        let dY = (deltaY / self.zoomed)

        switch dot.tag! {
        case 0:
            let resize = Double(curve.path.bounds.height + dY)
            self.resizeCurve(tag: 1, value: resize, anchor: CGPoint(x: 0, y: 1),
                             ind: dot.tag!, cmd: cmd)
            fallthrough
        case 1:
            let resize = Double(curve.path.bounds.width - dX)
            self.resizeCurve(tag: 0, value: resize, anchor: CGPoint(x: 1, y: 0),
                             ind: dot.tag!, cmd: cmd)
        case 2:
            let resize = Double(curve.path.bounds.width - dX)
            self.resizeCurve(tag: 0, value: resize, anchor: CGPoint(x: 1, y: 0),
                             ind: dot.tag!, cmd: cmd)
            fallthrough
        case 3:
            let resize = Double(curve.path.bounds.height - dY)
            self.resizeCurve(tag: 1, value: resize, ind: dot.tag!, cmd: cmd)
        case 4:
            let resize = Double(curve.path.bounds.height - dY)
            self.resizeCurve(tag: 1, value: resize, ind: dot.tag!, cmd: cmd)
            fallthrough
        case 5:
            let resize = Double(curve.path.bounds.width + dX)
            self.resizeCurve(tag: 0, value: resize, ind: dot.tag!, cmd: cmd)
        case 6:
            let resize = Double(curve.path.bounds.width + dX)
            self.resizeCurve(tag: 0, value: resize, ind: dot.tag!, cmd: cmd)
            fallthrough
        case 7:
            let resize = Double(curve.path.bounds.height + dY)
            self.resizeCurve(tag: 1, value: resize,
                             anchor: CGPoint(x: 0, y: 1),
                             ind: dot.tag!, cmd: cmd)
        case 8:
            let rotate = atan2(finPos.y+dY-curve.path.bounds.midY,
                               finPos.x+dX-curve.path.bounds.midX)

            var dt = CGFloat(rotate)-curve.frameAngle
            if abs(dt) > 0.1 {
                dt = dt.truncatingRemainder(dividingBy: 0.1)
            }
            self.rotateCurve(angle: Double(curve.angle+dt))
            curve.frameAngle = rotate
        case 9:
            self.gradientDirectionCurve(
                tag: 0, value: CGPoint(x: dX, y: dY))
        case 10:
            self.gradientDirectionCurve(
                tag: 1, value: CGPoint(x: dX, y: dY))
        case 11:
            self.gradientLocationCurve(tag: 0, value: dX)
        case 12:
            self.gradientLocationCurve(tag: 1, value: dX)
        case 13:
            self.gradientLocationCurve(tag: 2, value: dX)
        case 14:
            self.roundedCornerCurve(tag: 0, value: dX)
        case 15:
            self.roundedCornerCurve(tag: 1, value: dY)
        default:
            break
        }
    }

//    MARK: Action func
    func alignLeftRightCurve(value: Int) {
        if let curve = self.selectedCurve, !curve.lock {
            let wid50 = curve.path.bounds.width/2
            let lineWidth = curve.lineWidth/2
            let alignLeftRight: [CGFloat] = [
                self.sketchPath.bounds.minX + wid50 + lineWidth,
                self.sketchPath.bounds.midX,
                self.sketchPath.bounds.maxX - wid50 - lineWidth
            ]
            self.moveCurve(tag: 0, value: Double(alignLeftRight[value]))
        }
    }

    func alignUpDownCurve(value: Int) {
        if let curve = self.selectedCurve, !curve.lock {
            let hei50 = curve.path.bounds.height/2
            let lineWidth = curve.lineWidth/2
            let alignLeftRight: [CGFloat] = [
                self.sketchPath.bounds.maxY - hei50 - lineWidth,
                self.sketchPath.bounds.midY,
                self.sketchPath.bounds.minY + hei50 + lineWidth
            ]
            self.moveCurve(tag: 1, value: Double(alignLeftRight[value]))
        }
    }

    func moveCurve(tag: Int, value: Double) {
        var deltax: CGFloat = 0
        var deltay: CGFloat = 0
        if let curve = self.selectedCurve, !curve.lock {
            if tag==0 {
                deltax = CGFloat(value) - curve.path.bounds.midX
            } else {
                deltay = CGFloat(value) - curve.path.bounds.midY
            }
            let  move = AffineTransform(translationByX: deltax, byY: deltay)
            curve.path.transform(using: move)

            self.clearControls(curve: curve, updatePoints: (
                curve.updatePoints(deltax: deltax, deltay: -deltay)
            ))
            self.updateSliders()
        }
    }

    func resizeCurve(tag: Int, value: Double,
                     anchor: CGPoint = CGPoint(x: 0, y: 0),
                     ind: Int? = nil, cmd: Bool = false) {
        var scaleX: CGFloat = 1
        var scaleY: CGFloat = 1
        if let curve = selectedCurve, !curve.lock {
            let wid = curve.path.bounds.width
            let hei = curve.path.bounds.height
            if wid == 0 || hei == 0 {
                self.rotateCurve(angle: 0.001)
                curve.angle = 0
                return
            }
            var anchorX = anchor.x
            var anchorY = anchor.y

            if tag == 0 {
                scaleX = (CGFloat(value) / wid)
                if cmd {
                    scaleY = scaleX
                    if ind == 0 {
                        anchorX = 1
                        anchorY = 1
                    } else if ind == 2 {
                        anchorX = 1
                        anchorY = 0
                    } else if ind == 6 {
                        anchorY = 1
                    }
                }
            } else {
                scaleY = (CGFloat(value) / hei)
                if cmd {
                    scaleX = scaleY
                    if ind == 0 {
                        anchorX = 1
                        anchorY = 1
                    } else if ind == 2 {
                        anchorX = 1
                        anchorY = 0
                    } else if ind == 4 {
                        anchorX = 0
                    }
                }
            }
            let scale = AffineTransform(scaleByX: scaleX, byY: scaleY)

            let originX = curve.path.bounds.minX + wid * anchorX
            let originY = curve.path.bounds.minY + hei * anchorY

            curve.applyTransform(
                oX: originX, oY: originY,
                transform: {curve.path.transform(using: scale)})

            self.clearControls(curve: curve, updatePoints: (
                curve.updatePoints(
                    ox: originX, oy: originY,
                    scalex: scaleX, scaley: scaleY)
            ))

        } else {
            if tag == 0 {
                scaleX = CGFloat(value) / self.sketchPath.bounds.width
            } else {
                scaleY = CGFloat(value) / self.sketchPath.bounds.height
            }
            let originX = self.sketchPath.bounds.minX
            let originY = self.sketchPath.bounds.minY

            let origin = AffineTransform.init(
                translationByX: -originX, byY: -originY)
            self.sketchPath.transform(using: origin)
            let scale = AffineTransform(scaleByX: scaleX, byY: scaleY)

            self.sketchPath.transform(using: scale)

            let def = AffineTransform.init(
                translationByX: originX, byY: originY)
            self.sketchPath.transform(using: def)

            self.updatePathLayer(layer: self.sketchLayer,
                                 path: self.sketchPath)

            self.needsDisplay = true
        }
        self.updateSliders()
    }

    func rotateCurve(angle: Double) {
        if let curve = self.selectedCurve, !curve.lock {
            let ang = CGFloat(angle)
            let originX = curve.path.bounds.midX
            let originY = curve.path.bounds.midY
            let rotate = AffineTransform(rotationByRadians: ang - curve.angle)

            curve.applyTransform(
                oX: originX, oY: originY,
                transform: {
                    curve.path.transform(using: rotate)})

            self.clearControls(curve: curve, updatePoints: (
                    curve.updatePoints(angle: ang - curve.angle)
            ))
            curve.angle = ang
            // rotate image
            let rotateCanvas = CGAffineTransform(rotationAngle: curve.angle)
            curve.image.setAffineTransform(rotateCanvas)
            self.updateSliders()
        }
    }

    func borderWidthCurve(value: Double) {
        if let curve = self.selectedCurve, !curve.lock {
            curve.lineWidth = CGFloat(value)
            self.clearControls(curve: curve)
            self.updateSliders()
        }
    }

    func capCurve(value: Int) {
        if let curve = self.selectedCurve, !curve.lock {
            curve.setLineCap(value: value)
            self.needsDisplay = true
        }
    }

    func joinCurve(value: Int) {
        if let curve = self.selectedCurve, !curve.lock {
            curve.setLineJoin(value: value)
            self.needsDisplay = true
        }
    }

    func dashCurve(tag: Int, value: Double) {
        if let curve = self.selectedCurve, !curve.lock {
            var pattern = curve.dash
            pattern[tag] = NSNumber(value: value)
            curve.setDash(dash: pattern)
            self.clearControls(curve: curve)
            self.updateSliders()
        }
    }

    func blurCurve(value: Double) {
        if let curve = self.selectedCurve, !curve.lock {
            curve.blur = value
            self.clearControls(curve: curve)
            self.updateSliders()
        }
    }

    func colorCurve() {
        if let curve = self.selectedCurve, !curve.lock {
            curve.strokeColor = self.curveStrokeColor.fillColor
            curve.fillColor = self.curveFillColor.fillColor
            curve.shadowColor = self.curveShadowColor.fillColor
            let start = curveGradStartColor.fillColor
            let middle = curveGradMiddleColor.fillColor
            let final = curveGradFinalColor.fillColor
            curve.gradientColor = [start, middle, final]

            self.clearControls(curve: curve)
            self.createControls(curve: curve)
            self.needsDisplay = true
        }
    }

    func opacityCurve(tag: Int, value: Double) {
        if let curve = self.selectedCurve, !curve.lock {
            curve.alpha[tag] = CGFloat(value)
            self.clearControls(curve: curve)
            self.updateSliders()
        }
    }

    func shadowCurve(tag: Int, value: Double) {
        if let curve = self.selectedCurve, !curve.lock {
            var shadow = curve.shadow
            shadow[tag] = CGFloat(value)
            curve.shadow = shadow
            self.clearControls(curve: curve)
            self.updateSliders()
        }
    }

    func opacityGradientCurve(tag: Int, value: Double) {
        if let curve = self.selectedCurve, !curve.lock {
            curve.gradientOpacity[tag] = CGFloat(value)
            self.clearControls(curve: curve)
            self.updateSliders()
        }
    }

    func gradientDirectionCurve(tag: Int, value: CGPoint) {
        if let curve = self.selectedCurve, !curve.lock {
            let oldpoint = curve.gradientDirection[tag]
            var x = oldpoint.x + value.x / curve.path.bounds.width
            var y = oldpoint.y - value.y / curve.path.bounds.height
            x = x < 0 ? 0 : x > 1 ? 1 : x
            y = y < 0 ? 0 : y > 1 ? 1 : y

            curve.gradientDirection[tag] = CGPoint(x: x, y: y)
            self.clearControls(curve: curve)
        }
    }

    func gradientLocationCurve(tag: Int, value: CGFloat) {
        if let curve = self.selectedCurve, !curve.lock {
            let value =  Double(value / curve.path.bounds.width)
            var location = curve.gradientLocation
            let num = Double(truncating: location[tag]) + value
            location[tag] = num < 0 ? 0 : num > 1 ? 1 : NSNumber(value: num)

            curve.gradientLocation = location
            self.clearControls(curve: curve)
        }

    }

    func roundedCornerCurve(tag: Int, value: CGFloat) {
        if let curve = self.selectedCurve, let rounded = curve.rounded,
            !curve.lock {
            let wid50 = (curve.path.bounds.width)/2
            let hei50 = (curve.path.bounds.height)/2
            let minX = curve.path.bounds.minX
            let minY = curve.path.bounds.minY
            let maxX = curve.path.bounds.maxX
            let maxY = curve.path.bounds.maxY

            if tag==0 {
                var x = rounded.x - value/wid50
                x  = x < 0 ? 0 : x > 1 ? 1 : x
                curve.rounded = CGPoint(x: x, y: rounded.y)
                let offsetXLeft = maxX - x * wid50
                curve.moveControlPoints(index: [4, 7],
                                 tags: [0, 1, 2],
                                 offsetX: offsetXLeft)
                let offsetXRight = minX + x * wid50
                curve.moveControlPoints(index: [0, 3],
                                 tags: [0, 1, 2],
                                 offsetX: offsetXRight)
            } else if tag==1 {
                var y = rounded.y + value/hei50
                y  = y < 0 ? 0 : y > 1 ? 1 : y
                curve.rounded = CGPoint(x: rounded.x, y: y)
                let offsetYDown = maxY - y * hei50
                curve.moveControlPoints(index: [1],
                                 tags: [0, 2],
                                 offsetY: offsetYDown)
                curve.moveControlPoints(index: [6],
                                 tags: [1, 2],
                                 offsetY: offsetYDown)
                let offsetYUp = minY + y * hei50
                curve.moveControlPoints(index: [2],
                                 tags: [1, 2],
                                 offsetY: offsetYUp)
                curve.moveControlPoints(index: [5],
                                 tags: [0, 2],
                                 offsetY: offsetYUp)
            }
            curve.updateLayer()
            self.clearControls(curve: curve)
        }
    }

//    override func draw(_ dirtyRect: NSRect) {
//        super.draw(dirtyRect)
        // fill background
//        NSColor.white.setStroke()
//        __NSFrameRect(dirtyRect)
//    }

//    MARK: Support
    func flipSize(topLeft: CGPoint,
                  bottomRight: CGPoint) -> (wid: CGFloat, hei: CGFloat) {
        return (bottomRight.x - topLeft.x, bottomRight.y - topLeft.y)
    }

    func cgImageFrom(ciImage: CIImage) -> CGImage? {
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            return cgImage
        }
        return nil
    }

    func imageData(
        fileType: NSBitmapImageRep.FileType = .png,
        properties: [NSBitmapImageRep.PropertyKey: Any] = [:]) -> Data? {
        if let imageRep = bitmapImageRepForCachingDisplay(
            in: self.sketchPath.bounds) {
            self.cacheDisplay(in: self.sketchPath.bounds, to: imageRep)

//            let context = NSGraphicsContext(bitmapImageRep: imageRep)!
//            let cgCtx = context.cgContext
//            cgCtx.clear(self.sketchBorder.bounds)
//
//            var index = 0
//            if let layer = self.layer, let sublayers = layer.sublayers {
//                for sublayer in sublayers {
//                    let curve = self.curves[index]
//                    if curve.blur > 0, let cgImg = sublayer.cgImage() {
//
//                        let ciImg = CIImage(cgImage: cgImg)
//                        let filter = CIFilter(name: "CIGaussianBlur")
//                        filter?.setValue(ciImg,
//                                         forKey: kCIInputImageKey)
//                        filter?.setValue(curve.blur,
//                                         forKey: kCIInputRadiusKey)
//                        if let output = filter?.outputImage {
//                            if let cgImage = self.cgImageFrom(
//                                ciImage: output) {
//                                cgCtx.draw(cgImage, in: sublayer.bounds)
//                            }
//                            print(sublayer.position,
//                                  sublayer.frame)
//                            print(sublayer.position,
//                                  sublayer.frame)
//
//                        }
//                    } else {
//                        sublayer.render(in: cgCtx)
//                    }
//                    index += 1
//                }
                return imageRep.representation(
                    using: fileType, properties: properties)!
            }
//        }
        return nil
    }
}
