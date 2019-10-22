//
//  SketchPad.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 8/8/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.

// patreon post(about features)
// setup tiers, new name editor, icon,
// fb-beta test post habr?

// 0.72

// class for slider with text
// refactor init values setup in editor? Outlets?
// refactor update sliders // observers

// not pixelate ruler numbers number of rulers as NSTextFields
// show only two text fields
// reset to zero in what distance?
// show size of rect when create or resize?

// snap to rulers reduce power

// frame when move with arrows? slow come back after key up

// popup menu (locker image on top of curve) (top down stack )

// 0.73
// gestures without drag
// mutable path
// separate edit and create

// rotate&resize image gradient stable

// 0.74
// maybe not combine but merge paths in one object and add at the end
// groups resize, rotate, move, update sliders, update stack
// show groups together in one stack-button?
// group numbers?
// flatneess curve mitter limits fillRule (union)

// 0.75
// add control points to text
// 0.77
// Undo Redo
//0.8
// Filters
//0.9
// lock in side panel
// table view for layers
// editable text in layers
// movable layers in stack
// names for stacks members?
// scrool stack to bottom

// 1.0
// save svg
// open svg

// 2.0
// save before cmd-w cmd-q AppDelegate
// Bugs save blur

// add?
// allow move lineWidth inside outside
// add curve to exist group
// add more canvases with handles above sketchview
// hightlightt control dots sides or cursor change
// rulers for hiiden shapes?
// text next line
// add text immediately in the cursor position

import Cocoa

class SketchPad: NSView {
    var parent: NSViewController?
    weak var sketchUI: SketchStack!
    weak var toolUI: NSStackView!
    weak var frameUI: FrameButtons!
    weak var textUI: TextTool!
    weak var colorUI: NSStackView!

    weak var curveWidth: NSSlider!
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
    var rulers: Ruler!

    var sketchDir: URL?
    var sketchName: String?
    var sketchExt: String?

    var sketchPath = NSBezierPath()
    let sketchLayer = CAShapeLayer()
    var editedPath = NSBezierPath()
    let editLayer = CAShapeLayer()
    var curvedPath = NSBezierPath()
    let curveLayer = CAShapeLayer()
    var controlPath = NSBezierPath()
    let controlLayer = CAShapeLayer()

    var movePoint: Dot?
    var controlPoint1: Dot?
    var controlPoint2: Dot?
    var controlPoints: [ControlPoint] = []

    var dotSize: CGFloat = setup.dotSize
    var dotRadius: CGFloat = setup.dotRadius
    var dotMag: CGFloat = setup.dotRadius / 2
    var lineWidth: CGFloat = setup.lineWidth

    var copiedCurve: Curve?
    var selectedCurve: Curve?
    var curves: [Curve] = []
    var groups: [[Curve]] = [[]]

    var startPos = CGPoint(x: 0, y: 0)

    var editDone: Bool = false
    var closedCurve: Bool = false
    var filledCurve: Bool = true
    var roundedCurve: CGPoint?

    var zoomed: CGFloat = 1.0
    var zoomOrigin = CGPoint(x: setup.screenWidth/2,
                             y: setup.screenHeight/2)
    var tool = Tools.drag

    override init(frame: NSRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        let options: NSTrackingArea.Options = [
            .mouseMoved, .activeInActiveApp, .inVisibleRect]
        self.trackArea = NSTrackingArea(rect: self.bounds,
                                  options: options, owner: self)
        self.addTrackingArea(self.trackArea!)

        self.zoomSketch(value: Double(self.zoomed * 100))

        self.rulers = Ruler(parent: self)
        self.rulers.parent = self

        self.setupLayers()

        // filters
        self.layerUsesCoreImageFilters = true
    }

//    override func updateLayer() { }
//    override func makeBackingLayer() -> CALayer { }
//    override func draw(_ dirtyRect: NSRect) {
//        super.draw(dirtyRect)
        // fill background
//        NSColor.white.setStroke()
//        __NSFrameRect(dirtyRect)
//    }
    override func viewWillDraw() {
        self.updateWithPath(layer: self.editLayer, path: self.editedPath)
        self.updateWithPath(layer: self.curveLayer, path: self.curvedPath)
        self.updateWithPath(layer: self.controlLayer, path: self.controlPath)
        rulers.updateRulers()
        self.updateWithPath(layer: self.sketchLayer, path: self.sketchPath)
    }

    func setupLayers() {
        self.wantsLayer = true
        let layers = [
            self.editLayer: setup.fillColor.cgColor,
            self.curveLayer: setup.controlColor.cgColor,
            self.controlLayer: setup.fillColor.cgColor,
            self.sketchLayer: setup.guiColor.cgColor]

        for (layer, color) in layers {
            layer.strokeColor = color
            layer.fillColor = nil
            layer.lineWidth = self.lineWidth
            layer.actions = setup.disabledActions
            if layer != self.sketchLayer {
                layer.makeShape(path: NSBezierPath(),
                            strokeColor: setup.strokeColor,
                            dashPattern: setup.controlDashPattern,
                            actions: setup.disabledActions)
            }
        }

        let sketchBorder = NSRect(x: 0, y: 0,
                            width: setup.screenWidth,
                            height: setup.screenHeight)
        self.sketchPath = NSBezierPath(rect: sketchBorder)
    }

//    MARK: Mouse func
    override func mouseEntered(with event: NSEvent) {
        let pos = convert(event.locationInWindow, from: nil)
        self.showCurvedPath(pos: pos)

        if let curve = self.selectedCurve {
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
        let ctrl: Bool = event.modifierFlags.contains(.control) ? true : false
        self.startPos = convert(event.locationInWindow, from: nil)

        if let mp = self.movePoint, let cp1 = self.controlPoint1 {
            self.moveCurvedPath(move: mp.position,
                                to: self.startPos,
                                cp1: mp.position,
                                cp2: cp1.position)

        }

        if let curve = self.selectedCurve, curve.edit {
            self.clearPathLayer(layer: self.editLayer, path: self.editedPath)
            for point in curve.points {
                if point.collidedPoint(pos: self.startPos) != nil {
                    rulers.clearRulers()
                    return
                }
            }

            if curve.path.rectPath(
                curve.path, pad: setup.dotRadius).contains(self.startPos),
                let segment = curve.path.findPath(pos: self.startPos) {

                var mpPoints: [CGPoint] = []
                for cp in curve.points {
                    mpPoints.append(cp.mp.position)
                }

                let snap = self.snapToRulers(points: [self.startPos],
                                             curves: [curve],
                                             curvePoints: mpPoints,
                                             ctrl: ctrl)
                self.startPos.x -= snap.x
                self.startPos.y -= snap.y

                self.editedPath = curve.path.insertCurve(
                    to: self.startPos, at: segment.index, with: segment.points)

            } else {
                rulers.clearRulers()
            }
        } else {
            if self.tool != .drag {
               var mpPoints: [CGPoint] = []
               for cp in self.controlPoints {
                   mpPoints.append(cp.mp.position)
               }
               if let mp = self.movePoint {
                   mpPoints.append(mp.position)
               }

               let snap = self.snapToRulers(points: [self.startPos],
                                            curves: self.curves,
                                            curvePoints: mpPoints,
                                            ctrl: ctrl)
               self.startPos.x -= snap.x
               self.startPos.y -= snap.y
            }
        }
        self.needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let cmd: Bool = event.modifierFlags.contains(.command) ? true : false
        let opt: Bool = event.modifierFlags.contains(.option) ? true : false
        let ctrl: Bool = event.modifierFlags.contains(.control) ? true : false

        var finPos = convert(event.locationInWindow, from: nil)

        if let curve = self.selectedCurve, curve.edit {
            self.clearPathLayer(layer: self.editLayer, path: self.editedPath)
            self.clearControls(curve: curve, updatePoints: ())

            if let dot = curve.controlDot, dot.tag == 2 {
                var mpPoints: [CGPoint] = []
                for cp in curve.points {
                    if cp.mp != dot || opt {
                        mpPoints.append(cp.mp.position)
                    }
                }
                let snap = self.snapToRulers(points: [finPos],
                                             curves: [curve],
                                             curvePoints: mpPoints,
                                             ctrl: ctrl)
                finPos.x -= snap.x
                finPos.y -= snap.y
            }
            curve.editPoint(pos: finPos, opt: opt)

        } else if let curve = self.selectedCurve, let dot = curve.controlDot {
            self.dragFrameControlDots(curve: curve, finPos: finPos,
                                      deltaX: event.deltaX,
                                      deltaY: event.deltaY,
                                      dot: dot, cmd: cmd, ctrl: ctrl)
        } else {
            if self.tool != .drag {
                var mpPoints: [CGPoint] = [startPos]
                if self.tool == .curve {
                    for cp in self.controlPoints {
                        mpPoints.append(cp.mp.position)
                    }
                    if let mp = self.movePoint {
                        mpPoints.append(mp.position)
                    }
                }
                let snap = self.snapToRulers(points: [finPos],
                                             curves: self.curves,
                                             curvePoints: mpPoints,
                                             ctrl: ctrl)
                finPos.x -= snap.x
                finPos.y -= snap.y
            }
            switch self.tool {
            case .drag:
                self.dragCurve(deltaX: event.deltaX,
                               deltaY: event.deltaY, ctrl: ctrl)
            case .line:
                self.useTool(createLine(
                    topLeft: self.startPos, bottomRight: finPos))
                self.filledCurve = false
            case .triangle:
                self.useTool(createPolygon(topLeft: self.startPos,
                                           bottomRight: finPos,
                                           sides: 3, angle: 120))
            case .rect:
                self.useTool(createRectangle(
                    topLeft: self.startPos, bottomRight: finPos, cmd: cmd))
            case .pent:
                self.useTool(createPolygon(topLeft: self.startPos,
                                           bottomRight: finPos,
                                           sides: 5, angle: 72))
            case .hex:
                self.useTool(createPolygon(topLeft: self.startPos,
                                           bottomRight: finPos,
                                           sides: 6, angle: 60))
            case .arc:
                self.useTool(createArc(
                    topLeft: self.startPos, bottomRight: finPos))
            case .oval:
                self.useTool(createOval(
                    topLeft: self.startPos, bottomRight: finPos, cmd: cmd))
            case .stylus:
                if abs(self.startPos.x - finPos.x) > self.dotSize ||
                    abs(self.startPos.y - finPos.y) > self.dotSize {
                    self.createStylusLine(topLeft: self.startPos,
                                          bottomRight: finPos)
                    self.startPos = finPos
                    self.editDone = true
                }
                self.filledCurve = false

            case .curve:
                if self.editDone { return }
                self.dragCurvedPath(topLeft: self.startPos,
                                    bottomRight: finPos)
            case .text:
                self.createText(pos: finPos)
            }
        }
        self.needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        print("down")
        self.startPos = convert(event.locationInWindow, from: nil)

        let cmd: Bool = event.modifierFlags.contains(.command) ? true : false
        let opt: Bool = event.modifierFlags.contains(.option) ? true : false

        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("abortTextFields"), object: nil)

        if let curve = self.selectedCurve, curve.edit {
            curve.selectPoint(pos: self.startPos)
            self.clearPathLayer(layer: self.editLayer, path: self.editedPath)
        } else if let curve = self.selectedCurve,
            let dot = curve.controlFrame?.collideControlDot(pos: self.startPos),
            !curve.lock {
            curve.controlDot = dot
            if dot.tag == 9 {
                curve.gradient = !curve.gradient
            }
        } else if let curve = self.selectedCurve,
            let frame = curve.controlFrame?.groupFrame,
            let dot = frame.collideControlDot(pos: self.startPos), !curve.lock {
            curve.controlDot = dot
        } else if let mp = self.movePoint,
            mp.collide(pos: self.startPos, radius: mp.bounds.width),
            self.controlPoints.count>0 {
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
            case .stylus:
                self.controlPoints = []
                self.editedPath.removeAllPoints()
                self.editedPath.move(to: self.startPos)
            case .line, .triangle, .rect, .pent, .hex, .arc, .oval:
                self.controlPoints = []
                self.editedPath.removeAllPoints()
            case .curve:
                self.createCurve(topLeft: self.startPos)
            case .text:
                self.createText(pos: self.startPos)
            }
        }

        if opt { self.cloneCurve() }
        self.needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        print("up")
        switch self.tool {
        case .stylus:
            if self.editDone {
                self.controlPoints.append(
                    self.addControlPoint(mp: self.startPos,
                                         cp1: self.startPos,
                                         cp2: self.startPos))
                self.editedPath.move(to: self.startPos)
            } else {
                self.controlPoints = []
                self.editedPath.removeAllPoints()
            }
            fallthrough
        case .drag, .line, .triangle, .rect, .pent, .hex, .arc, .oval:
            if let curve = self.selectedCurve {
                self.clearControls(curve: curve)
            }
            if self.editDone {
                self.newCurve()
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
                self.newCurve()
            }
            if let curve = self.selectedCurve, curve.edit || self.editDone {
                curve.frameAngle = 0
                curve.controlDot = nil
                self.createControls(curve: curve)
            }
        default:
            break
        }

        rulers.clearRulers()

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
                   angle: CGFloat, lineWidth: CGFloat,
                   cap: Int, join: Int, dash: [NSNumber],
                   strokeColor: NSColor, fillColor: NSColor,
                   alpha: [CGFloat],
                   shadow: [CGFloat], shadowColor: NSColor,
                   gradientDirection: [CGPoint],
                   gradientColor: [NSColor],
                   gradientOpacity: [CGFloat],
                   gradientLocation: [NSNumber],
                   filterOpacity: CGFloat, blur: Double,
                   points: [ControlPoint]) -> Curve {

        let curve = Curve.init(parent: self, path: path,
                               fill: fill, rounded: rounded)
        curve.angle = angle
        curve.lineWidth =  lineWidth
        curve.setLineCap(value: cap)
        curve.setLineJoin(value: join)
        curve.setDash(dash: dash)
        curve.strokeColor = strokeColor
        curve.fillColor = fillColor
        curve.alpha = alpha
        curve.shadow = shadow
        curve.shadowColor = shadowColor
        curve.gradientDirection = gradientDirection
        curve.gradientColor = gradientColor
        curve.gradientOpacity = gradientOpacity
        curve.gradientLocation = gradientLocation
        curve.filterOpacity = filterOpacity
        curve.blur = blur
        curve.setPoints(points: points)
        return curve
    }

    func newCurve() {
        guard let path = self.editedPath.copy() as? NSBezierPath,
            path.elementCount > 0 else { return }

        let shadowValues: [CGFloat] = [
            CGFloat(self.curveShadowRadius.doubleValue),
            CGFloat(self.curveShadowOpacity.doubleValue),
            CGFloat(self.curveShadowOffsetX.doubleValue),
            CGFloat(self.curveShadowOffsetY.doubleValue)]
        let alpha = self.filledCurve
            ? [CGFloat(self.curveOpacityStroke.doubleValue),
               CGFloat(self.curveOpacityFill.doubleValue)]
            : [1, 0]

        let curve = self.initCurve( path: path,
            fill: self.filledCurve, rounded: self.roundedCurve,
            angle: 0,
            lineWidth: CGFloat(self.curveWidth.doubleValue),
            cap: setup.lineCap, join: setup.lineJoin,
            dash: setup.lineDashPattern,
            strokeColor: self.curveStrokeColor.fillColor,
            fillColor: self.curveFillColor.fillColor,
            alpha: alpha, shadow: shadowValues,
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
            filterOpacity: setup.filterOpacity, blur: setup.minBlur,
            points: self.controlPoints)

        self.addCurve(curve: curve)
    }

    func addCurve(curve: Curve) {
        self.layer?.addSublayer(curve.canvas)
        self.curves.append(curve)
        self.setTool(tag: Tools.drag.rawValue)

        self.groups[0] = [curve]
        self.selectedCurve = curve

        self.sketchUI.appendSketchStackCell(
            index: self.curves.count-1, curve: curve,
            stackAction: { (sender) in
                if let oldCurve = self.selectedCurve, oldCurve.edit {
                   self.sketchUI.isOn(
                    on: self.curves.firstIndex(of: oldCurve) ?? -1)
                    return
                }
                if let oldCurve = self.selectedCurve {
                    self.deselectCurve(curve: oldCurve)
                }
                let actCurve = self.curves[sender.tag]
                if actCurve.canvas.isHidden {
                    self.sketchUI.isOn(on: -1)
                } else {
                    self.selectedCurve = actCurve
                    self.createControls(curve: actCurve)
                    self.updateSliders()
                    self.sketchUI.isOn(on: sender.tag)
                }
            }, visibleAction: { (sender) in
                let actCurve = self.curves[sender.tag]
                if actCurve.edit {
                    sender.state = .on
                } else {

                    actCurve.canvas.isHidden = !actCurve.canvas.isHidden
                    if actCurve.canvas.isHidden {
                        if let oldCurve = self.selectedCurve,
                            actCurve == oldCurve {
                            self.deselectCurve(curve: actCurve)
                        }
                    }
                    self.sketchUI.updateImageButton(index: sender.tag,
                                                    curve: actCurve)
                    if let oldCurve = self.selectedCurve {
                         self.sketchUI.isOn(
                            on: self.curves.firstIndex(of: oldCurve) ?? -1)
                    }
                }
            })
    }

    func deselectCurve(curve: Curve) {
        self.clearControls(curve: curve)
        self.frameUI.isOn(on: -1)
        self.sketchUI.isOn(on: -1)
        self.rulers.clearRulers()
        self.selectedCurve = nil
    }

    func selectCurve(pos: CGPoint, cmd: Bool = false) {
        if let curve = self.selectedCurve {
            self.deselectCurve(curve: curve)
        }

        for (index, curve) in self.curves.enumerated() {
            let wid50 = curve.lineWidth/2
            let bounds = NSRect(
                x: curve.path.bounds.minX - wid50,
                y: curve.path.bounds.minY - wid50,
                width: curve.path.bounds.width + curve.lineWidth,
                height: curve.path.bounds.height + curve.lineWidth)
            if bounds.contains(pos) && !curve.canvas.isHidden {
                self.selectedCurve = curve
                sketchUI.isOn(on: index)
            }
        }

        if let curve = self.selectedCurve {
            _ = self.snapToRulers(points: curve.boundsPoints,
                                  curves: self.curves,
                                  exclude: curve, ctrl: true)
        }

        if let curve = self.selectedCurve, curve.group==0, cmd {
            if self.groups[0].contains(curve) {
                if let index = self.groups[0].firstIndex(of: curve) {
                    self.groups[0].remove(at: index)
                    if self.groups[0].count > 0 {
                        self.selectedCurve = self.groups[0][0]
                    }
                }
            } else {
                self.groups[0].append(curve)
            }
        } else {
            self.groups[0].removeAll()
        }

        if self.groups[0].count == 0 {
            if let curve = self.selectedCurve, curve.group==0 {
                self.groups[0] = [curve]
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
    func snapToRulers(points: [CGPoint],
                      curves: [Curve],
                      curvePoints: [CGPoint] = [],
                      exclude: Curve? = nil,
                      ctrl: Bool = false) -> CGPoint {

        let snap = rulers.createRulers(points: points,
            curves: curves, curvePoints: curvePoints,
            exclude: exclude, ctrl: ctrl)

        return snap
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

        self.dotSize = setup.dotSize - (self.zoomed-1)
        self.dotRadius = self.dotSize/2
        self.dotMag = self.dotRadius / 2
        self.lineWidth = setup.lineWidth - (self.zoomed-1) / setup.dotSize

        if let curve = self.selectedCurve {
            self.clearControls(curve: curve)
            self.createControls(curve: curve)
            if curve.edit {
                curve.clearPoints()
                curve.createPoints()
            }
        }

        self.updateControlSize()
        
        self.needsDisplay = true
    }

    func setZoomOrigin(deltaX: CGFloat, deltaY: CGFloat) {
        self.zoomOrigin = CGPoint(
            x: (self.zoomOrigin.x - deltaX),
            y: (self.zoomOrigin.y - deltaY))
        self.zoomSketch(value: Double(self.zoomed * 100))
    }

//    MARK: Path func
    func updateWithPath(layer: CAShapeLayer, path: NSBezierPath) {
        layer.removeFromSuperlayer()
        layer.lineWidth = self.lineWidth
        if path.elementCount>0 {
            layer.path = path.cgPath
            layer.bounds = path.bounds
            layer.position = CGPoint(x: path.bounds.midX,
                                    y: path.bounds.midY)
            if let dashLayer = layer.sublayers?.first as? CAShapeLayer {
                dashLayer.path = layer.path
                dashLayer.lineWidth = self.lineWidth
            }
            self.layer?.addSublayer(layer)
        }
    }

    func clearPathLayer(layer: CAShapeLayer, path: NSBezierPath) {
        layer.removeFromSuperlayer()
        path.removeAllPoints()
    }

    func addDot(pos: CGPoint,
                lineWidth: CGFloat = setup.lineWidth,
                strokeColor: NSColor = setup.strokeColor,
                fillColor: NSColor = setup.fillColor) -> Dot {
        return Dot.init(x: pos.x, y: pos.y,
                        width: self.dotSize, height: self.dotSize,
                        rounded: self.dotRadius, lineWidth: self.lineWidth,
                        strokeColor: strokeColor, fillColor: fillColor)
    }

    func addControlPoint(mp: CGPoint,
                         cp1: CGPoint, cp2: CGPoint) -> ControlPoint {
        return ControlPoint(
            mp: addDot(pos: mp),
            cp1: addDot(pos: cp1,
                        strokeColor: setup.fillColor,
                        fillColor: setup.strokeColor),
            cp2: addDot(pos: cp2,
                        strokeColor: setup.fillColor,
                        fillColor: setup.strokeColor))
    }

    func addSegment(mp: Dot, cp1: Dot, cp2: Dot) {
        var cPnt = [CGPoint](repeating: .zero, count: 3)
        self.curvedPath.element(at: 1, associatedPoints: &cPnt)
        self.editedPath.curve(to: cPnt[2],
                              controlPoint1: cPnt[0],
                              controlPoint2: cPnt[1])

        self.controlPoints.append(ControlPoint(mp: mp, cp1: cp1, cp2: cp2))
        self.updateControlSize()
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

    func updateControlSize() {
        if let mp = self.movePoint {
            mp.updateSize(width: self.dotSize, height: self.dotSize)
        }
        if let cp1 = self.controlPoint1,
            let cp2 = self.controlPoint2 {
            cp1.updateSize(width: self.dotSize, height: self.dotSize)
            cp2.updateSize(width: self.dotSize, height: self.dotSize)
        }
        for point in self.controlPoints {
            point.hideControlDots(dotSize: self.dotSize)
            point.clearDots()
            for dot in point.dots {
                dot.updateSize(width: self.dotSize, height: self.dotSize)
                self.layer?.addSublayer(dot)
            }
        }
    }

    func dragCurvedPath(topLeft: CGPoint, bottomRight: CGPoint) {
        let finPos = CGPoint(
            x: topLeft.x - (bottomRight.x - topLeft.x),
            y: topLeft.y - (bottomRight.y - topLeft.y))

        self.clearPathLayer(layer: self.curveLayer, path: self.curvedPath)
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

    func showCurvedPath(pos: CGPoint) {
        if editedPath.elementCount>0 {
            for point in controlPoints {
                if let mp = self.movePoint, let cp1 = self.controlPoint1 {
                    if point.collideDot(pos: pos,
                                        dot: point.mp) {
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
        self.clearPathLayer(layer: self.curveLayer,
                            path: self.curvedPath)
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
    func sendCurve(tag: Int) {
        if let curve = self.selectedCurve,
            let index = curves.firstIndex(of: curve), !curve.lock {
            var goal = index
            switch tag {
            case 0:
                if goal>0 {
                    goal -= 1
                }
            case 1:
                if goal<curves.count-1 {
                    goal += 1
                }
            default:
                break
            }
            if goal != index {
                curves.swapAt(goal, index)
                self.layer?.sublayers?.swapAt(goal, index)
                sketchUI.isOn(on: goal)

                for (i, curve) in self.curves.enumerated() {
                    sketchUI.updateImageButton(index: i, curve: curve)
                    sketchUI.updateTag(index: i, with: i)
                }
                self.needsDisplay = true
            }
        }
    }

    func flipCurve(tag: Int) {
        if let curve = self.selectedCurve, !curve.lock {
            let flip: AffineTransform
            var originX: CGFloat = 0
            var originY: CGFloat = 0
            var scalex: CGFloat = 1
            var scaley: CGFloat = 1
            switch tag {
            case 2:
                scalex = -1
                originX = curve.path.bounds.midX
            case 3:
                scaley = -1
                originY = curve.path.bounds.midY
            default:
                break
            }
            flip = AffineTransform(scaleByX: scalex, byY: scaley)

            curve.applyTransform(oX: originX, oY: originY,
                           transform: {curve.path.transform(using: flip)})

            curve.updatePoints(ox: originX, oy: originY,
                               scalex: scalex, scaley: scaley)

            self.needsDisplay = true
            self.updateSliders()
        }
    }

    func editFinished(curve: Curve) {
        curve.edit = false
        curve.clearPoints()
        curve.createControlFrame()
        self.clearPathLayer(layer: self.editLayer, path: self.editedPath)
        self.frameUI.isEnable(all: true)
    }

    func editStarted(curve: Curve) {
        curve.edit = true
        curve.clearControlFrame()
        curve.createPoints()
        self.frameUI.isEnable(tag: 4)
        self.setTool(tag: Tools.drag.rawValue)
    }

    func editCurve(sender: NSButton) {
        if let curve = self.selectedCurve {
            if sender.state == .off {
                self.editFinished(curve: curve)
            } else {
                self.editStarted(curve: curve)
            }
        }
        self.needsDisplay = true
    }

    func groupCurve(sender: NSButton) {
        if sender.state == .on {
            if self.groups[0].count > 1 {
                var emptyIndex = self.groups.count
                for index in 1..<self.groups.count
                    where  self.groups[index].isEmpty {
                        emptyIndex = index
                        break
                }
                for curve in self.groups[0] {
                    curve.group = emptyIndex
                }
                if emptyIndex<self.groups.count {
                    self.groups[emptyIndex].append(contentsOf: self.groups[0])
                } else {
                    self.groups.append(self.groups[0])
                }
                self.groups[0].removeAll()
                if let curve = self.selectedCurve {
                    self.clearControls(curve: curve)
                    self.createControls(curve: curve)
                }
            } else {
                sender.state = .off
            }
        } else {
            if let curve = self.selectedCurve, curve.group > 0 {
                let groupIndex = curve.group
                for curve in self.groups[groupIndex] {
                    curve.group = 0
                }
                self.groups[groupIndex].removeAll()
                self.clearControls(curve: curve)
            }
        }
    }

    func lockCurve(sender: NSButton) {
        if let curve = self.selectedCurve {
            if sender.state == .off {

                sender.image = NSImage.init(
                    imageLiteralResourceName: NSImage.lockUnlockedTemplateName)
                self.frameUI.isEnable(all: true)
                self.groups[curve.group].forEach({$0.lock = false})
            } else {
                sender.image = NSImage.init(
                    imageLiteralResourceName: NSImage.lockLockedTemplateName)
                self.frameUI.isEnable(tag: 6)
                self.groups[curve.group].forEach({$0.lock = true})
            }
        }
    }

//    MARK: Tools func
    func useTool(_ action: @autoclosure () -> Void) {
        self.editedPath = NSBezierPath()
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
        self.groups[0].removeAll()
        self.textUI.hide()
        self.clearCurvedPath()

        if let tool = Tools(rawValue: tag) {
            self.tool = tool
            self.toolUI?.isOn(on: self.tool.rawValue)
        }
    }

    func flipSize(topLeft: CGPoint,
                  bottomRight: CGPoint) -> (wid: CGFloat, hei: CGFloat) {
        return (bottomRight.x - topLeft.x, bottomRight.y - topLeft.y)
    }

    func dragCurve(deltaX: CGFloat, deltaY: CGFloat,
                   ctrl: Bool = false) {
        if let curve = self.selectedCurve, !curve.lock {
            let snap = self.snapToRulers(points: curve.boundsPoints,
                                         curves: self.curves,
                                         exclude: curve, ctrl: ctrl)

            let deltaX = (deltaX - snap.x) / self.zoomed
            let deltaY = (deltaY + snap.y) / self.zoomed

            let move = AffineTransform.init(
                translationByX: deltaX,
                byY: -deltaY)

            curve.path.transform(using: move)
            self.clearControls(curve: curve, updatePoints: (
               curve.updatePoints(deltax: deltaX, deltay: deltaY)
            ))

            self.updateSliders()
        }
    }

    func createLine(topLeft: CGPoint, bottomRight: CGPoint) {
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

    func appendStraightCurves(points: [CGPoint]) {
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

    func createPolygon(topLeft: CGPoint, bottomRight: CGPoint, sides: Int,
                       angle: CGFloat) {
        let size = self.flipSize(topLeft: topLeft,
                                     bottomRight: bottomRight)

        let radius = abs(size.wid) > abs(size.hei)
            ? abs(size.wid/2)
            : abs(size.hei/2)
        let cx: CGFloat = size.wid > 0 ? topLeft.x + radius : topLeft.x - radius
        var cy: CGFloat = topLeft.y - radius
        var turn90 = -CGFloat.pi / 2
        if size.hei > 0 {
            cy = topLeft.y + radius
            turn90 *= -1
        }

        var points: [CGPoint] = []
        if radius>0 {
            let radian = CGFloat(angle * CGFloat.pi / 180)

            for i in 0..<sides {
                let cosX = cos(turn90 + CGFloat(i) * radian)
                let sinY = -sin(turn90 + CGFloat(i) * radian)
                points.append(CGPoint(x: cx + cosX * radius,
                                     y: cy + sinY * radius))
           }
        }
        if points.count>0 {
            self.appendStraightCurves(points: points)
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

    func createOval(topLeft: CGPoint, bottomRight: CGPoint,
                    cmd: Bool = false) {
        let size = self.flipSize(topLeft: topLeft, bottomRight: bottomRight)
        var wid = size.wid
        let hei = size.hei
        if cmd {
            let signWid: CGFloat = wid>0 ? 1 : -1
            wid = abs(hei) * signWid
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

    func createStylusLine(topLeft: CGPoint, bottomRight: CGPoint) {
        self.editedPath.curve(to: bottomRight,
                              controlPoint1: bottomRight,
                              controlPoint2: bottomRight)

        self.controlPoints.append(
            self.addControlPoint(mp: bottomRight,
                                 cp1: bottomRight,
                                 cp2: bottomRight))
    }

    func createCurve(topLeft: CGPoint) {
        if let mp = self.movePoint,
            let cp1 = self.controlPoint1,
            let cp2 = self.controlPoint2 {
            self.moveCurvedPath(move: mp.position, to: topLeft,
                                cp1: cp1.position, cp2: topLeft)
            self.addSegment(mp: mp, cp1: cp1, cp2: cp2)
        }

        self.movePoint = self.addDot(pos: topLeft)
        self.layer?.addSublayer(self.movePoint!)
        self.controlPoint1 = self.addDot(pos: topLeft,
                                         strokeColor: setup.fillColor,
                                         fillColor: setup.strokeColor)
        self.layer?.addSublayer(self.controlPoint1!)
        self.controlPoint2 = self.addDot(pos: topLeft,
                                         strokeColor: setup.fillColor,
                                         fillColor: setup.strokeColor)
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

    func createText(pos: CGPoint? = nil) {
        let topLeft = pos ?? self.startPos
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
                for (index, point) in curve.points.enumerated() {
                    if !point.cp1.isHidden || !point.cp2.isHidden {
                        curve.points.remove(at: index)
                        point.delete()
                        curve.path = curve.path.removePath(at: index+1)
                        break
                    }
                }
                curve.resetPoints()
                self.clearControls(curve: curve)
                self.createControls(curve: curve)
                self.updateSliders()
            } else {
                if let groupIndex = self.groups.firstIndex(
                    of: self.groups[curve.group]),
                    let index = self.groups[groupIndex].firstIndex(
                        of: curve) {

                    self.groups[groupIndex].remove(at: index)
                    if self.groups[groupIndex].count == 1 {
                        let aloneCurve = self.groups[groupIndex][0]
                        aloneCurve.group = 0
                        self.groups[groupIndex].removeAll()
                        frameUI.updateState(curve: aloneCurve)
                    }
                }

                curve.clearPoints()
                curve.delete()
                self.deselectCurve(curve: curve)
                self.curves.remove(at: index)

                sketchUI.remove(at: index)
                for i in 0..<self.curves.count {
                    sketchUI.updateTag(index: i, with: i)
                }
            }
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
                angle: curve.angle,
                lineWidth: curve.lineWidth,
                cap: curve.cap, join: curve.join,
                dash: curve.dash,
                strokeColor: curve.strokeColor,
                fillColor: curve.fillColor,
                alpha: curve.alpha,
                shadow: curve.shadow,
                shadowColor: curve.shadowColor,
                gradientDirection: curve.gradientDirection,
                gradientColor: curve.gradientColor,
                gradientOpacity: curve.gradientOpacity,
                gradientLocation: curve.gradientLocation,
                filterOpacity: curve.filterOpacity,
                blur: curve.blur,
                points: points)
        }
    }

    func pasteCurve(to: CGPoint) {
        let edit = self.selectedCurve?.edit ?? false

        if let clone = self.copiedCurve, !edit {
            if let curve = self.selectedCurve {
                self.clearControls(curve: curve)
            }

            self.addCurve(curve: clone)

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
            self.newCurve()
            if let curve = self.selectedCurve {
                self.createControls(curve: curve)
            }
            self.needsDisplay = true
            self.updateSliders()
        }
    }

//    MARK: Frame func
    func dragFrameControlDots(curve: Curve, finPos: CGPoint,
                              deltaX: CGFloat, deltaY: CGFloat, dot: Dot,
                              cmd: Bool = false, ctrl: Bool = false ) {
        let snap = self.snapToRulers(points: curve.boundsPoints,
                                     curves: self.curves,
                                     exclude: curve, ctrl: ctrl)
        let dX = deltaX / self.zoomed
        let dY = deltaY / self.zoomed
        let dXs = (deltaX - snap.x) / self.zoomed
        let dYs = (deltaY + snap.y) / self.zoomed

        switch dot.tag! {
        case 0:
            let resize = Double(curve.path.bounds.height + dYs)
            self.resizeCurve(tag: 1, value: resize, anchor: CGPoint(x: 0, y: 1),
                             ind: dot.tag!, cmd: cmd)
            fallthrough
        case 1:
            let resize = Double(curve.path.bounds.width - dXs)
            self.resizeCurve(tag: 0, value: resize, anchor: CGPoint(x: 1, y: 0),
                             ind: dot.tag!, cmd: cmd)
        case 2:
            let resize = Double(curve.path.bounds.width - dXs)
            self.resizeCurve(tag: 0, value: resize, anchor: CGPoint(x: 1, y: 0),
                             ind: dot.tag!, cmd: cmd)
            fallthrough
        case 3:
            let resize = Double(curve.path.bounds.height - dYs)
            self.resizeCurve(tag: 1, value: resize, ind: dot.tag!, cmd: cmd)
        case 4:
            let resize = Double(curve.path.bounds.height - dYs)
            self.resizeCurve(tag: 1, value: resize, ind: dot.tag!, cmd: cmd)
            fallthrough
        case 5:
            let resize = Double(curve.path.bounds.width + dXs)
            self.resizeCurve(tag: 0, value: resize, ind: dot.tag!, cmd: cmd)
        case 6:
            let resize = Double(curve.path.bounds.width + dXs)
            self.resizeCurve(tag: 0, value: resize, ind: dot.tag!, cmd: cmd)
            fallthrough
        case 7:
            let resize = Double(curve.path.bounds.height + dYs)
            self.resizeCurve(tag: 1, value: resize,
                             anchor: CGPoint(x: 0, y: 1),
                             ind: dot.tag!, cmd: cmd)
        case 8:
            self.rotateByDelta(curve: curve, pos: finPos,
                               dX: dX, dY: dY)
        case 9:
            break
        case 10:
            self.gradientDirectionCurve(
                tag: 0, value: CGPoint(x: dX, y: dY))
        case 11:
            self.gradientDirectionCurve(
                tag: 1, value: CGPoint(x: dX, y: dY))
        case 12:
            self.gradientLocationCurve(tag: 0, value: dX)
        case 13:
            self.gradientLocationCurve(tag: 1, value: dX)
        case 14:
            self.gradientLocationCurve(tag: 2, value: dX)
        case 15:
            self.roundedCornerCurve(tag: 0, value: dX)
        case 16:
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
            let move = AffineTransform(translationByX: deltax, byY: deltay)
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
                    } else if ind == 6 || ind == 17 {
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

            curve.resetPoints()
            curve.clearPoints()

            // rotate image
//            let rotateImage = CGAffineTransform(rotationAngle: curve.angle)
//            curve.image.setAffineTransform(rotateImage)
//            self.updateSliders()
        }
    }

    func rotateByDelta(curve: Curve, pos: CGPoint, dX: CGFloat, dY: CGFloat) {
        let rotate = atan2(pos.y+dY-curve.path.bounds.midY,
                           pos.x+dX-curve.path.bounds.midX)
        var dt = CGFloat(rotate)-curve.frameAngle
        dt = abs(dt)>0.2 ? dt.truncatingRemainder(dividingBy: 0.2) : dt

        self.rotateCurve(angle: Double(curve.angle+dt))
        curve.frameAngle = rotate
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

//    MARK: Support

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
