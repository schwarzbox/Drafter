//
//  SketchPad.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 8/8/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.

// 0.67
// Rounded rect
// add more info to readme
// Refactor select curves

// Fast rotate (bug)
// Undo Redo

//0.7
// Rulers (Figma style)

// 0.75
// Crop tool
// Selection frame (new tool)
// Group curves

//0.8
// Custom filters (proportional)
// CA Filters
// 0.9
// blur?

// 1.0
// refactor frame (when zoom smaller dot size) (animation for labels)
// flatneess mitter limits fillRule
// phase (use line dash phase to animate frame)

// 1.5
// save svg
// open svg

// 2.0
// disable unused actions

// save before cmd-w cmd-q AppDelegate
// resize image?
// TextTool (position)?
// move border path?

import Cocoa

class SketchPad: NSView {
    var parent: NSViewController?
    weak var toolUI: NSStackView?
    weak var frameUI: FrameButtons!
    weak var textUI: TextTool!

    // refactor outlets
    weak var colorUI: NSStackView!

    weak var curveWidth: NSSlider!
    weak var curveCap: NSSegmentedControl!
    weak var curveJoin: NSSegmentedControl!
    weak var curveDashGap: NSStackView!

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

    weak var curveBlur: NSSlider!

    var trackArea: NSTrackingArea!

    var sketchDir: URL?
    var sketchName: String?
    var sketchExt: String?
    var sketchBorder = NSBezierPath()
    // change to zero when save image
    var sketchWidth: CGFloat = setup.lineWidth
    var sketchColor = setup.guiColor

    var editedPath: NSBezierPath = NSBezierPath()
    let editLayer = CAShapeLayer()
    let editColor = setup.strokeColor
    var editDone: Bool = false

    var startPoint: CGPoint?

    var copiedCurve: Curve?
    var selectedCurve: Curve?
    var curves: [Curve] = []
    var groups: [[Curve]] = []

    var movePoint: Dot?
    var controlPoint1: Dot?
    var controlPoint2: Dot?
    var controlPoints: [ControlPoint] = []

    var curvedPath: NSBezierPath = NSBezierPath()
    let curveLayer = CAShapeLayer()
    let curveColor = setup.fillColor

    var controlPath: NSBezierPath = NSBezierPath()
    let controlLayer = CAShapeLayer()

    let dotSize: CGFloat =  setup.dotSize
    let dotRadius: CGFloat = setup.dotRadius

    var closedCurve: Bool = false
    var filledCurve: Bool = true
    var roundedCurve: CGPoint?

    var zoomed: CGFloat = 1.0
    var zoomOrigin = CGPoint(x: 0, y: 0)

    enum Tools: Int {
        case drag, pen, line, oval, triangle, rectangle, arc, curve, text
    }
    var tool = Tools.drag

    override init(frame: NSRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // mouse moved
        let options: NSTrackingArea.Options = [
            .mouseMoved, .activeInActiveApp, .inVisibleRect]
        self.trackArea = NSTrackingArea(rect: self.bounds,
                                  options: options, owner: self)
        self.addTrackingArea(self.trackArea!)

        // edited
        self.editLayer.strokeColor = self.editColor.cgColor
        self.editLayer.fillColor = nil
        self.editLayer.lineWidth = setup.lineWidth - 0.4
        self.editLayer.path = self.editedPath.cgPath
        self.editLayer.actions = ["position": NSNull(), "bounds": NSNull(),
                                  "path": NSNull()]
        // curve
        self.curveLayer.strokeColor = self.curveColor.cgColor
        self.curveLayer.fillColor = nil
        self.curveLayer.lineWidth = setup.lineWidth
        self.curveLayer.path = self.curvedPath.cgPath
        self.curveLayer.actions = ["position": NSNull(), "bounds": NSNull(),
                                   "path": NSNull()]
        // control
        self.controlLayer.strokeColor = self.curveColor.cgColor
        self.controlLayer.fillColor = nil
        self.controlLayer.lineWidth = setup.lineWidth
        self.controlLayer.path = self.controlPath.cgPath
        self.controlLayer.actions = ["position": NSNull(), "bounds": NSNull(),
                                     "path": NSNull()]

        // canvas border
        let sketch = NSRect(x: 0, y: 0,
                            width: setup.screenWidth,
                            height: setup.screenHeight)
        self.sketchBorder = NSBezierPath(rect: sketch)
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
        let pos: CGPoint = convert(event.locationInWindow, from: nil)
        if let mp = self.movePoint, let cp1 = self.controlPoint1 {
            self.moveCurvedPath(move: mp.position, to: pos,
                                cp1: mp.position,
                                cp2: cp1.position)
            self.updatePathLayer(layer: self.curveLayer, path: self.curvedPath)
        }
        if let curve = self.selectedCurve, curve.edit {
            self.editedPath.removeAllPoints()
            self.editLayer.removeFromSuperlayer()

            let collider = NSRect(x: curve.path.bounds.minX-2,
                                  y: curve.path.bounds.minY-2,
                                  width: curve.path.bounds.width+4,
                                  height: curve.path.bounds.height+4)
            if collider.contains(pos),
                let segment = curve.path.findPath(pos: pos) {
                let path = curve.insertPoint(at: pos, index: segment.index,
                                             points: segment.points)
                self.editedPath = path
                self.editedPath.appendRect(NSRect(x: pos.x - self.dotRadius,
                                                  y: pos.y - self.dotRadius,
                                                  width: self.dotSize,
                                                  height: self.dotSize))
                self.updatePathLayer(layer: self.editLayer,
                                     path: self.editedPath)
            }
        }
    }

    override func mouseDragged(with event: NSEvent) {
        let cmd: Bool = event.modifierFlags.contains(.command) ? true : false

        let theEnd = convert(event.locationInWindow, from: nil)
        if let curve = self.selectedCurve, curve.edit {
            self.editedPath.removeAllPoints()
            self.editLayer.removeFromSuperlayer()
            self.clearControls(curve: curve, updatePoints: {})
            curve.editPoint(pos: theEnd)
        } else if let curve = self.selectedCurve, let dot = curve.controlDot {
            self.dragFrameControlDots(curve: curve, theEnd: theEnd,
                                      deltaX: event.deltaX,
                                      deltaY: event.deltaY,
                                      dot: dot, cmd: cmd)
        } else {
            if let theStart = self.startPoint {
                switch self.tool {
                case .pen:
                    self.editedPath.move(to: theStart)
                    self.editedPath.line(to: theEnd)
                    self.startPoint = convert(event.locationInWindow, from: nil)
                    self.editDone = true
                    self.editedPath.close()
                case .line:
                    self.editedPath.removeAllPoints()
                    self.createLine(topLeft: theStart, bottomRight: theEnd)
                    self.editDone = true
                    self.filledCurve = false
                    self.editedPath.close()
                case .triangle:
                    self.editedPath.removeAllPoints()
                    self.createTriangle(topLeft: theStart, bottomRight: theEnd,
                                        cmd: cmd)
                    self.editDone = true
                    self.editedPath.close()
                case .oval:
                    self.editedPath.removeAllPoints()
                    self.createOval(topLeft: theStart,
                                    bottomRight: theEnd, cmd: cmd)
                    self.editDone = true
                    self.editedPath.close()
                case .rectangle:
                    self.editedPath.removeAllPoints()
                    self.createRectangle(topLeft: theStart,
                                         bottomRight: theEnd, cmd: cmd)
                    self.editDone = true
                case .arc:
                    self.editedPath.removeAllPoints()
                    self.createArc(topLeft: theStart, bottomRight: theEnd)
                    self.editDone = true
                    self.editedPath.close()
                case .curve:
                    if self.editDone {
                        return
                    }
                    self.dragCurvedPath(topLeft: theStart, bottomRight: theEnd)
                case .text:
                    self.createText(topLeft: theEnd)
                default:
                    self.dragCurve(event: event)
                }
            }
        }
        self.updatePathLayer(layer: self.editLayer, path: self.editedPath)
        self.updatePathLayer(layer: self.controlLayer, path: self.controlPath)
        self.needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        print("down")
        self.startPoint = convert(event.locationInWindow, from: nil)

        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("abortTextFields"), object: nil)

        if let theStart = self.startPoint {
            if let curve = self.selectedCurve, curve.edit {
                curve.selectPoint(pos: theStart)
            } else if let curve = self.selectedCurve,
                let dot = curve.controlFrame?.collideLabel(
                    pos: theStart), !curve.lock {
                curve.controlDot = dot
                self.setTool(tag: 0)

            } else if let mp = self.movePoint,
                mp.collide(origin: theStart, width: mp.bounds.width) {
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
                let theEnd: CGPoint = convert(event.locationInWindow, from: nil)
                switch self.tool {
                case .pen:
                    self.createLine(topLeft: theStart, bottomRight: theEnd)
                    self.editedPath.removeAllPoints()
                case .line:
                    self.createLine(topLeft: theStart, bottomRight: theEnd)
                    self.controlPoints = []
                    self.editedPath.removeAllPoints()
                case .triangle:
                    self.createLine(topLeft: theStart, bottomRight: theEnd)
                    self.controlPoints = []
                    self.editedPath.removeAllPoints()
                case .oval:
                    self.createOval(topLeft: theStart, bottomRight: theEnd)
                    self.editedPath.removeAllPoints()
                case .rectangle:
                    self.createRectangle(topLeft: theStart, bottomRight: theEnd)
                    self.editedPath.removeAllPoints()
                case .arc:
                    self.createArc(topLeft: theStart, bottomRight: theEnd)
                    self.editedPath.removeAllPoints()
                case .curve:
                    self.createCurve(topLeft: theStart)
                case .text:
                    self.createText(topLeft: theStart)
                default:
                    self.selectCurve(pos: theStart)
                }
            }
        }

        self.updatePathLayer(layer: self.editLayer, path: self.editedPath)
        self.needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        print("up")
        switch self.tool {
        case .pen, .line, .triangle, .oval, .rectangle, .arc, .drag:
            if let curve = self.selectedCurve {
                self.clearControls(curve: curve, updatePoints: {})
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
                self.clearControls(curve: curve, updatePoints: {})
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

        self.startPoint = nil
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
        curve.setCap(value: cap)
        curve.setJoin(value: join)
        curve.setDash(dash: dash)
        curve.setPoints(points: points)
        return curve
    }

    func addCurve() {
        guard let path = self.editedPath.copy() as? NSBezierPath,
            path.elementCount > 0 else {
             return
        }

        var shadowValues: [CGFloat] = setup.shadow
        shadowValues[0] = CGFloat(self.curveShadowRadius.doubleValue)
        shadowValues[1] = CGFloat(self.curveShadowOpacity.doubleValue)
        shadowValues[2] = CGFloat(self.curveShadowOffsetX.doubleValue)
        shadowValues[3] = CGFloat(self.curveShadowOffsetY.doubleValue)

        var dashPattern: [NSNumber] = []
        for view in self.curveDashGap?.subviews ?? [] {
            if let slider = view as? NSSlider {
                dashPattern.append(NSNumber(value: slider.doubleValue))
            }
        }

        let curve = self.initCurve(
            path: path, fill: self.filledCurve,
            rounded: self.roundedCurve,
            strokeColor: self.curveStrokeColor.fillColor,
            fillColor: self.curveFillColor.fillColor,
            lineWidth: CGFloat(self.curveWidth.doubleValue),
            angle: 0,
            alpha: [CGFloat(self.curveOpacityStroke.doubleValue),
                    CGFloat(self.curveOpacityFill.doubleValue)],
            blur: self.curveBlur.doubleValue,
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
            cap: self.curveCap.indexOfSelectedItem,
            join: self.curveJoin.indexOfSelectedItem,
            dash: dashPattern,
            points: self.controlPoints)

        self.layer?.addSublayer(curve.canvas)
        self.curves.append(curve)
        self.setTool(tag: 0)

        self.selectedCurve = curve
    }

    func selectCurve(pos: CGPoint) {
        if let curve = self.selectedCurve {
            self.clearControls(curve: curve, updatePoints: {})
            self.frameUI.isOn(on: -1)
            curve.edit = false
            self.selectedCurve = nil
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
    }

    func createControls(curve: Curve) {
        if !curve.edit {
            curve.createControlFrame()
        }
        self.frameUI.updateFrame(view: self)
        self.frameUI.show()
        self.needsDisplay = true
    }

    func clearControls(curve: Curve, updatePoints: () -> Void) {
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

        self.frameUI.updateFrame(view: self)
        self.needsDisplay = true
    }

    func setZoomOrigin(deltaX: CGFloat, deltaY: CGFloat) {
        self.zoomOrigin = CGPoint(
            x: (self.zoomOrigin.x - deltaX),
            y: (self.zoomOrigin.y - deltaY))
        self.zoomSketch(value: Double(self.zoomed * 100))
    }

//    MARK: Curve func
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

    func addDot(pos: CGPoint, radius: CGFloat,
                color: NSColor? = setup.fillColor) -> Dot {
        return Dot.init(x: pos.x, y: pos.y, size: self.dotSize,
                        offset: CGPoint(x: self.dotRadius, y: self.dotRadius),
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

    func finalSegment(fin: (_ mp: Dot, _ cp1: Dot, _ cp2: Dot) -> Void ) {
        if let mp = self.movePoint,
            let cp1 = self.controlPoint1,
            let cp2 = self.controlPoint2 {

            fin(mp, cp1, cp2)

            self.editedPath.close()
            self.curvedPath.removeAllPoints()
            self.controlPath.removeAllPoints()
            self.curveLayer.removeFromSuperlayer()
            self.controlLayer.removeFromSuperlayer()
            self.editDone = true
        }
    }

    func dragCurvedPath(topLeft: CGPoint, bottomRight: CGPoint) {
        let theEnd2 = CGPoint(
            x: topLeft.x - (bottomRight.x - topLeft.x),
            y: topLeft.y - (bottomRight.y - topLeft.y))
        self.controlPath.removeAllPoints()
        self.controlLayer.removeFromSuperlayer()
        self.controlPath.move(to: bottomRight)
        self.controlPath.line(to: theEnd2)
        if let cp1 = self.controlPoint1,
            let cp2 = self.controlPoint2 {
            cp1.position = CGPoint(x: bottomRight.x, y: bottomRight.y)
            cp2.position = CGPoint(x: theEnd2.x, y: theEnd2.y)
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
        self.curvedPath.removeAllPoints()
        self.curveLayer.removeFromSuperlayer()
        self.curvedPath.move(to: move)
        self.curvedPath.curve(to: to,
                              controlPoint1: cp1,
                              controlPoint2: cp2)
    }

    func clearCurvedPath() {
        self.editedPath.removeAllPoints()
        self.editLayer.removeFromSuperlayer()

        self.curvedPath.removeAllPoints()
        self.controlPath.removeAllPoints()
        self.curveLayer.removeFromSuperlayer()
        self.controlLayer.removeFromSuperlayer()

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
            self.setTool(tag: 0)

            if let curve = self.selectedCurve {
                self.clearControls(curve: curve, updatePoints: {})
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
                x: curve.path.bounds.midX+setup.dotSize,
                y: curve.path.bounds.midY-setup.dotSize))
        }
    }

    func editCurve(sender: NSButton) {
        if let curve = self.selectedCurve {
            if sender.state == .off {
                sender.alternateTitle = "done"
            } else {
                sender.alternateTitle = "edit"
            }
            switch sender.alternateTitle {
            case "edit":
                curve.edit = true
                curve.clearControlFrame()
                curve.createPoints()
                self.frameUI.isEnable(title: "edit")
            default:
                curve.edit = false
                curve.clearPoints()
                curve.createControlFrame()
                self.frameUI.isEnable(all: true)
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

    func groupCurve() {
        print("group")
    }

//    MARK: Tools func
    func setTool(tag: Int) {
        self.textUI.hide()
        self.clearCurvedPath()
        if let tool = Tools(rawValue: tag) {
            self.tool = tool
            self.toolUI?.isOn(on: self.tool.rawValue)
        }
    }

    func dragCurve(event: NSEvent) {
        if let curve = self.selectedCurve, !curve.lock {
            let deltax = event.deltaX / self.zoomed
            let deltay = event.deltaY / self.zoomed
            let move = AffineTransform.init(
                translationByX: deltax,
                byY: -deltay)
            curve.path.transform(using: move)

            self.clearControls(curve: curve, updatePoints: {
                curve.updatePoints(deltax: event.deltaX,
                                   deltay: event.deltaY)
            })
        }
        self.updateSliders()
    }

    func createLine(topLeft: CGPoint, bottomRight: CGPoint) {
        self.editedPath = NSBezierPath()
        self.editedPath.move(to: topLeft)
        self.editedPath.curve(to: bottomRight,
                              controlPoint1: bottomRight,
                              controlPoint2: bottomRight)
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
        let p1 = CGPoint(x: topLeft.x + wid / 2, y: topLeft.y)
        let p2 = CGPoint(x: topLeft.x, y: topLeft.y + hei)
        let p3 = CGPoint(x: topLeft.x + wid, y: topLeft.y + hei)

        self.editedPath.move(to: p1)
        self.editedPath.curve(to: p2, controlPoint1: p2, controlPoint2: p2)
        self.editedPath.curve(to: p3, controlPoint1: p3, controlPoint2: p3)
        self.editedPath.curve(to: p1, controlPoint1: p1, controlPoint2: p1)

        self.controlPoints = [self.addControlPoint(mp: p1, cp1: p1, cp2: p1),
                              self.addControlPoint(mp: p2, cp1: p2, cp2: p2),
                              self.addControlPoint(mp: p3, cp1: p3, cp2: p3)]
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
                         xRad: CGFloat = 0.00001, yRad: CGFloat = 0.00001,
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

        self.editedPath = NSBezierPath(
            roundedRect: NSRect(x: botLeft.x, y: botLeft.y,
                                width: wid, height: hei),
            xRadius: xRad, yRadius: yRad)
        self.roundedCurve = CGPoint(x: 0, y: 0)

        var path = NSBezierPath()
        var lastElem = 0
        for i in 0..<self.editedPath.elementCount {
            var lPnt = [CGPoint](repeating: .zero, count: 3)
            let type = self.editedPath.element(at: i, associatedPoints: &lPnt)
            if type == .lineTo {
                self.editedPath.placeCurve(
                    at: i, with: [lPnt[0], lPnt[0], lPnt[0]], to: path)

                if let newPath = path.copy() as? NSBezierPath {
                    self.editedPath = newPath
                }
                path = NSBezierPath()
            } else if type == .closePath {
                lastElem = i
            }
        }
        path = NSBezierPath()
        if lastElem>0 {
            self.editedPath.placeCurve(
                at: lastElem, with: [topRight, topRight, topRight],
                to: path, replace: false)
        }
        self.editedPath = path
        let points = self.editedPath.findPoints(.curveTo)

        if points.count > 0 {
            self.controlPoints = [
                self.addControlPoint(mp: topRight,
                                     cp1: topRight, cp2: topRight)]
            for i in 0..<points.count-1 {
                self.controlPoints.append(
                    self.addControlPoint(mp: points[i][2],
                                         cp1: points[i][2], cp2: points[i][2]))
            }
        }
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

        let path = NSBezierPath()
        self.editedPath.placeCurve(
            at: 1, with: [lPnt[0], lPnt[0], lPnt[0]], to: path)

        var fPnt = [CGPoint](repeating: .zero, count: 3)
        path.element(at: path.elementCount-1, associatedPoints: &fPnt)
        path.curve(to: mPnt[0], controlPoint1: fPnt[2], controlPoint2: fPnt[2])
        self.editedPath = path

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

        self.controlPath.removeAllPoints()
        self.controlLayer.removeFromSuperlayer()

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
        if let curve = self.selectedCurve, !curve.edit, !curve.lock,
            let index = self.curves.firstIndex(of: curve) {
            self.curves.remove(at: index)
            curve.delete()
            self.clearControls(curve: curve, updatePoints: {})

            self.selectedCurve = nil
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
                self.clearControls(curve: curve, updatePoints: {})
            }
            self.addCurve()
            if let curve = self.selectedCurve {
                self.createControls(curve: curve)
            }
        }
        self.updateSliders()
        self.needsDisplay = true
    }

//    MARK: Frame func
    func dragFrameControlDots(curve: Curve, theEnd: CGPoint,
                              deltaX: CGFloat, deltaY: CGFloat,
                              dot: Dot, cmd: Bool ) {
        let dX = deltaX / self.zoomed
        let dY = deltaY / self.zoomed

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
            let rotate = atan2(theEnd.y+dY-curve.path.bounds.midY,
                               theEnd.x+dX-curve.path.bounds.midX)

            var dt = CGFloat(rotate)-curve.frameAngle
            if abs(dt) > 0.05 {
                dt = dt.truncatingRemainder(dividingBy: 0.05)
            }
            print(dt)
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
                self.sketchBorder.bounds.minX + wid50 + lineWidth,
                self.sketchBorder.bounds.midX,
                self.sketchBorder.bounds.maxX - wid50 - lineWidth
            ]
            self.moveCurve(tag: 0, value: Double(alignLeftRight[value]))
        }
    }

    func alignUpDownCurve(value: Int) {
        if let curve = self.selectedCurve, !curve.lock {
            let hei50 = curve.path.bounds.height/2
            let lineWidth = curve.lineWidth/2
            let alignLeftRight: [CGFloat] = [
                self.sketchBorder.bounds.maxY - hei50 - lineWidth,
                self.sketchBorder.bounds.midY,
                self.sketchBorder.bounds.minY + hei50 + lineWidth
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

            self.clearControls(curve: curve, updatePoints: {
                curve.updatePoints(deltax: deltax, deltay: -deltay)
            })
        } else {
            if tag==0 {
                deltax = CGFloat(value) - self.sketchBorder.bounds.minX
            } else {
                deltay = CGFloat(value) - self.sketchBorder.bounds.minY
            }
            let move = AffineTransform.init(translationByX: deltax, byY: deltay)
            self.sketchBorder.transform(using: move)
        }
        self.updateSliders()
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

            self.clearControls(curve: curve, updatePoints: {
                curve.updatePoints(
                    ox: originX, oy: originY,
                    scalex: scaleX, scaley: scaleY)
            })

        } else {
            if tag == 0 {
                scaleX = CGFloat(value) / self.sketchBorder.bounds.width
            } else {
                scaleY = CGFloat(value) / self.sketchBorder.bounds.height
            }
            let originX = self.sketchBorder.bounds.minX
            let originY = self.sketchBorder.bounds.minY

            let origin = AffineTransform.init(
                translationByX: -originX, byY: -originY)
            self.sketchBorder.transform(using: origin)
            let scale = AffineTransform(scaleByX: scaleX, byY: scaleY)

            self.sketchBorder.transform(using: scale)

            let def = AffineTransform.init(
                translationByX: originX, byY: originY)
            self.sketchBorder.transform(using: def)
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

            self.clearControls(curve: curve, updatePoints: {
                    curve.updatePoints(angle: ang - curve.angle)
                }
            )
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
            self.clearControls(curve: curve, updatePoints: {})
            self.updateSliders()
        }
    }

    func capCurve(value: Int) {
        if let curve = self.selectedCurve, !curve.lock {
            curve.setCap(value: value)
            self.needsDisplay = true
        }
    }

    func joinCurve(value: Int) {
        if let curve = self.selectedCurve, !curve.lock {
            curve.setJoin(value: value)
            self.needsDisplay = true
        }
    }

    func dashCurve(tag: Int, value: Double) {
        if let curve = self.selectedCurve, !curve.lock {
            var pattern = curve.dash
            pattern[tag] = NSNumber(value: value)
            curve.setDash(dash: pattern)
            self.clearControls(curve: curve, updatePoints: {})
            self.updateSliders()
        }
    }

    func blurCurve(value: Double) {
        if let curve = self.selectedCurve, !curve.lock {
            curve.blur = value
            self.clearControls(curve: curve, updatePoints: {})
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

            self.clearControls(curve: curve, updatePoints: {})
            self.createControls(curve: curve)
            self.needsDisplay = true
        }
    }

    func opacityCurve(tag: Int, value: Double) {
        if let curve = self.selectedCurve, !curve.lock {
            curve.alpha[tag] = CGFloat(value)
            self.clearControls(curve: curve, updatePoints: {})
            self.updateSliders()
        }
    }

    func shadowCurve(tag: Int, value: Double) {
        if let curve = self.selectedCurve, !curve.lock {
            var shadow = curve.shadow
            shadow[tag] = CGFloat(value)
            curve.shadow = shadow
            self.clearControls(curve: curve, updatePoints: {})
            self.updateSliders()
        }
    }

    func opacityGradientCurve(tag: Int, value: Double) {
        if let curve = self.selectedCurve, !curve.lock {
            curve.gradientOpacity[tag] = CGFloat(value)
            self.clearControls(curve: curve, updatePoints: {})
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
            self.clearControls(curve: curve, updatePoints: {})
        }
    }

    func gradientLocationCurve(tag: Int, value: CGFloat) {
        if let curve = self.selectedCurve, !curve.lock {
            let value =  Double(value / curve.path.bounds.width)
            var location = curve.gradientLocation
            let num = Double(truncating: location[tag]) + value
            location[tag] = num < 0 ? 0 : num > 1 ? 1 : NSNumber(value: num)

            curve.gradientLocation = location
            self.clearControls(curve: curve, updatePoints: {})
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
                curve.movePoints(index: [4, 7],
                                 types: ["mp", "cp1", "cp2"],
                                 offsetX: offsetXLeft)
                let offsetXRight = minX + x * wid50
                curve.movePoints(index: [0, 3],
                                 types: ["mp", "cp1", "cp2"],
                                 offsetX: offsetXRight)
            } else if tag==1 {
                var y = rounded.y + value/hei50
                y  = y < 0 ? 0 : y > 1 ? 1 : y
                curve.rounded = CGPoint(x: rounded.x, y: y)
                let offsetYDown = maxY - y * hei50
                curve.movePoints(index: [1],
                                 types: ["mp", "cp1"],
                                 offsetY: offsetYDown)
                curve.movePoints(index: [6],
                                 types: ["mp", "cp2"],
                                 offsetY: offsetYDown)
                let offsetYUp = minY + y * hei50
                curve.movePoints(index: [2],
                                 types: ["mp", "cp2"],
                                 offsetY: offsetYUp)
                curve.movePoints(index: [5],
                                 types: ["mp", "cp1"],
                                 offsetY: offsetYUp)
            }
            curve.updateLayer()
            self.clearControls(curve: curve, updatePoints: {})
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // fill background
//        NSColor.white.setStroke()
//        __NSFrameRect(dirtyRect)

        self.sketchBorder.lineWidth = self.sketchWidth
        self.sketchColor.setStroke()
        self.sketchBorder.stroke()
    }

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
            in: self.sketchBorder.bounds) {
            self.cacheDisplay(in: self.sketchBorder.bounds, to: imageRep)

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
