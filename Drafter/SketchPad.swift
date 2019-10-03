//
//  SketchPad.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 8/8/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.

//0.6
// Rulers (Figma style)
// Grid (NSDrawTiledRect & snap to grid)
// edit curves with control dots?
// CapJoin UI
// DashPattern UI

//0.7
// undo redo history
// Crop tool
// Selection frame (new tool)
// Group curves

//0.8
// Custom filters (proportional)
// CA Filters
// blur?

// 1.0

// refactor CGPoint NSPoint
// refactor frame (when zoom smaller dot size) (animation for labels)
// refactor dash pattern
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
    weak var ToolBox: NSStackView?
    weak var FrameButtons: NSStackView!
    weak var TextTool: NSStackView!

    weak var CurveOpacityStroke: NSSlider!
    weak var CurveOpacityFill: NSSlider!
    weak var CurveWidth: NSSlider!
    weak var CurveBlur: NSSlider!

    weak var ColorPanel: NSColorPanel?
    weak var CurveColors: NSStackView!

    weak var CurveStrokeColor: NSBox!
    weak var CurveFillColor: NSBox!
    weak var CurveShadowColor: NSBox!
    weak var CurveGradientStartColor: NSBox!
    weak var CurveGradientMiddleColor: NSBox!
    weak var CurveGradientFinalColor: NSBox!

    weak var CurveGradientStartOpacity: NSSlider!
    weak var CurveGradientMiddleOpacity: NSSlider!
    weak var CurveGradientFinalOpacity: NSSlider!

    weak var CurveShadowOpacity: NSSlider!
    weak var CurveShadowRadius: NSSlider!

    weak var CurveShadowOffsetX: NSSlider!
    weak var CurveShadowOffsetY: NSSlider!

    weak var CurveCap: NSSegmentedControl!
    weak var CurveJoin: NSSegmentedControl!
    weak var CurveDashGap: NSStackView!

    var TrackArea: NSTrackingArea!

    var sketchDir: URL?
    var sketchName: String?
    var sketchExt: String?
    var sketchBorder = NSBezierPath()
    // change to zero when save image
    var sketchWidth: CGFloat = set.lineWidth
    var sketchColor = set.guiColor

    var editedPath: NSBezierPath = NSBezierPath()
    let editLayer = CAShapeLayer()
    let editColor = set.strokeColor
    var editDone: Bool = false

    var startPoint: NSPoint?

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
    let curveColor = set.fillColor

    var controlPath: NSBezierPath = NSBezierPath()
    let controlLayer = CAShapeLayer()

    let dotSize: CGFloat =  set.dotSize
    let dotRadius: CGFloat = set.dotRadius

    var closedCurve: Bool = false
    var filledCurve: Bool = true
    var roundedCurve: CGPoint?

    var zoomed: CGFloat = 1.0
    var zoomOrigin = CGPoint(x: 0, y: 0)

    enum Tools {
        case Pen, Line, Triangle, Oval, Rectangle, Arc,
        Curve, Text, Drag
        mutating func set(_ tool: String) {
            switch tool {
            case "pen":
                self = .Pen
            case "line":
                self = .Line
            case "triangle":
                self = .Triangle
            case "oval":
                self = .Oval
            case "rectangle":
                self = .Rectangle
            case "arc":
                self = .Arc
            case "curve":
                self = .Curve
            case "text":
                self = .Text
            default:
                self = .Drag
            }
        }
    }
    var tool = Tools.Drag

    override init(frame: NSRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // mouse moved
        let options: NSTrackingArea.Options = [.mouseMoved, .activeInActiveApp, .inVisibleRect]
        self.TrackArea = NSTrackingArea(rect: self.bounds,
                                  options: options, owner: self)
        self.addTrackingArea(self.TrackArea!)

        // edited
        self.editLayer.strokeColor = self.editColor.cgColor
        self.editLayer.fillColor = nil
        self.editLayer.lineWidth = set.lineWidth - 0.4
        self.editLayer.path = self.editedPath.cgPath
        self.editLayer.actions = ["position": NSNull(),"bounds": NSNull(),"path": NSNull()]
        // curve
        self.curveLayer.strokeColor = self.curveColor.cgColor
        self.curveLayer.fillColor = nil
        self.curveLayer.lineWidth = set.lineWidth
        self.curveLayer.path = self.curvedPath.cgPath
        self.curveLayer.actions = ["position": NSNull(),"bounds": NSNull(),"path": NSNull()]
        // control
        self.controlLayer.strokeColor = self.curveColor.cgColor
        self.controlLayer.fillColor = nil
        self.controlLayer.lineWidth = set.lineWidth
        self.controlLayer.path = self.controlPath.cgPath
        self.controlLayer.actions = ["position": NSNull(),"bounds": NSNull(),"path": NSNull()]

        // canvas border
        let sketch = NSRect(x: 0, y: 0,
                            width: set.screenWidth,
                            height: set.screenHeight)
        self.sketchBorder = NSBezierPath(rect: sketch)
        self.zoomOrigin = CGPoint(x: self.bounds.midX,
                                  y: self.bounds.midY)

        // filters
//        self.wantsLayer = true
        self.layerUsesCoreImageFilters = true

    }

//    MARK: Mouse func
    override func mouseEntered(with event: NSEvent) {
        self.showCurvedPath(event: event)

        if let curve = self.selectedCurve {
            let pos = convert(event.locationInWindow, from:nil)
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
        let pos: NSPoint = convert(event.locationInWindow, from:nil)
        if let mp = self.movePoint, let cp1 = self.controlPoint1 {
            self.moveCurvedPath(move: mp.position, to: pos,
                                cp1: mp.position,
                                cp2: cp1.position)
            self.updatePathLayer(layer: self.curveLayer, path: self.curvedPath)
        }
        if let curve = self.selectedCurve, curve.edit {
            self.editedPath.removeAllPoints()
            self.editLayer.removeFromSuperlayer()

            let collider = NSRect(x:curve.path.bounds.minX-2, y: curve.path.bounds.minY-2,
                                  width: curve.path.bounds.width+4,
                                  height: curve.path.bounds.height+4)
            if collider.contains(pos), let segment = curve.path.findPath(pos: pos) {

                let path = curve.insertCurve(at: pos, index: segment.index,
                                             points: segment.points)
                self.editedPath = path
                self.editedPath.appendRect(NSRect(x: pos.x - self.dotRadius,
                                                  y:  pos.y - self.dotRadius,
                                                  width: self.dotSize,
                                                  height: self.dotSize))
                self.updatePathLayer(layer: self.editLayer, path: self.editedPath)
            }
        }
    }

    override func mouseDragged(with event: NSEvent) {
        var cmd: Bool = false
        if event.modifierFlags.contains(.command) {
            cmd = true
        }
        let theEnd = convert(event.locationInWindow, from:nil)
        if let curve = self.selectedCurve, curve.edit {
            self.editedPath.removeAllPoints()
            self.editLayer.removeFromSuperlayer()
            self.clearControls(curve: curve, updatePoints: {})
            curve.editPoint(pos: theEnd)
        } else if let curve = self.selectedCurve, let dot = curve.controlDot {
            let deltax = event.deltaX / self.zoomed
            let deltay = event.deltaY / self.zoomed
            switch dot.tag! {
            case 0:
                let resize = Double(curve.path.bounds.height + deltay)
                self.resizeCurve(tag: 1,
                                 value: resize, anchor: CGPoint(x: 0, y: 1),
                                 ind: dot.tag!, cmd: cmd)
                fallthrough
            case 1:
                let resize = Double(curve.path.bounds.width - deltax)
                self.resizeCurve(tag: 0,
                                 value: resize, anchor: CGPoint(x: 1, y: 0),
                                 ind: dot.tag!, cmd: cmd)
            case 2:
                let resize = Double(curve.path.bounds.width - deltax)
                self.resizeCurve(tag: 0,
                                 value: resize, anchor: CGPoint(x: 1, y: 0),
                                 ind: dot.tag!, cmd: cmd)
                fallthrough
            case 3:
                let resize = Double(curve.path.bounds.height - deltay)
                self.resizeCurve(tag: 1,
                                 value: resize,
                                 ind: dot.tag!, cmd: cmd)
            case 4:
                let resize = Double(curve.path.bounds.height - deltay)
                self.resizeCurve(tag: 1,
                                 value: resize,
                                 ind: dot.tag!, cmd: cmd)
                fallthrough
            case 5:
                let resize = Double(curve.path.bounds.width + deltax)
                self.resizeCurve(tag: 0,
                                 value: resize,
                                 ind: dot.tag!,cmd: cmd)
            case 6:
                let resize = Double(curve.path.bounds.width + deltax)
                self.resizeCurve(tag: 0,
                                 value: resize,
                                 ind: dot.tag!, cmd: cmd)
                fallthrough
            case 7:
                let resize = Double(curve.path.bounds.height + deltay)
                self.resizeCurve(tag: 1,
                                 value: resize,anchor: CGPoint(x: 0, y: 1),
                                 ind: dot.tag!, cmd: cmd)
            case 8:
                let rotate = atan2(theEnd.y+deltay-curve.path.bounds.midY,
                            theEnd.x+deltax-curve.path.bounds.midX)
                let dt = rotate-curve.frameAngle
                self.rotateCurve(angle:  Double(curve.angle+dt))
                curve.frameAngle = rotate
            case 9:
                self.gradientDirectionCurve(
                    tag: 0, value: CGPoint(x: deltax, y:deltay))
            case 10:
                self.gradientDirectionCurve(
                    tag: 1, value: CGPoint(x: deltax, y:deltay))
            case 11:
                self.gradientLocationCurve(tag: 0, value: deltax)
            case 12:
                self.gradientLocationCurve(tag: 1, value: deltax)
            case 13:
                self.gradientLocationCurve(tag: 2, value: deltax)
            case 14:
                self.roundedCornerCurve(tag: 0, value: deltax)
            case 15:
                self.roundedCornerCurve(tag: 1, value: deltay)
            default:
                break
            }
        } else {
            if let theStart = self.startPoint {
                switch self.tool {
                case .Pen:
                    self.editedPath.move(to: theStart)
                    self.editedPath.line(to: theEnd)
                    self.startPoint = convert(event.locationInWindow, from:nil)
                    self.editDone = true
                    self.editedPath.close()
                case .Line:
                    self.editedPath.removeAllPoints()
                    self.createLine(topLeft: theStart,  bottomRight: theEnd)
                    self.editDone = true
                    self.editedPath.close()
                case .Triangle:
                    self.editedPath.removeAllPoints()
                    self.createTriangle(topLeft: theStart,bottomRight: theEnd, cmd: cmd)
                    self.editDone = true
                    self.editedPath.close()
                case .Oval:
                    self.editedPath.removeAllPoints()
                    self.createOval(topLeft: theStart, bottomRight: theEnd, cmd: cmd)
                    self.editDone = true
                    self.editedPath.close()
                case .Rectangle:
                    self.editedPath.removeAllPoints()
                    self.createRectangle(topLeft: theStart,
                                         bottomRight: theEnd, cmd: cmd)
                    self.editDone = true
                    self.editedPath.close()
                case .Arc:
                    self.editedPath.removeAllPoints()
                    self.createArc(topLeft: theStart, bottomRight: theEnd)
                    self.editDone = true
                    self.editedPath.close()
                case .Curve:
                    if self.editDone {
                        return
                    }
                    let theEnd2 = NSPoint(
                        x: theStart.x - (theEnd.x - theStart.x),
                        y: theStart.y - (theEnd.y - theStart.y))
                    self.controlPath.removeAllPoints()
                    self.controlLayer.removeFromSuperlayer()
                    self.controlPath.move(to: theEnd)
                    self.controlPath.line(to: theEnd2)
                    if let cp1 = self.controlPoint1, let cp2 = self.controlPoint2 {
                        cp1.position = CGPoint(x: theEnd.x, y: theEnd.y)
                        cp2.position = CGPoint(x: theEnd2.x, y: theEnd2.y)
                        if self.editedPath.elementCount>1 {
                            let index = self.editedPath.elementCount-1
                            let last = self.controlPoints[self.controlPoints.count-1].cp1
                            var points = [last.position,cp2.position,theStart]
                            self.editedPath.setAssociatedPoints(&points, at: index)
                        }
                    }
                case .Text:
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

    override func mouseDown(with event: NSEvent){
        print("down")
        self.startPoint = convert(event.locationInWindow, from: nil)

        // unfocus text fields
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("abortTextFields"), object: nil)
        
        if let theStart = self.startPoint {
            if let curve = self.selectedCurve, curve.edit {
                curve.selectPoint(pos: theStart)
            } else if let curve = self.selectedCurve,
                let dot = curve.controlFrame?.collideLabel(pos: theStart), !curve.lock  {
                curve.controlDot = dot
                self.tool = Tools.Drag
                ToolBox?.isOn(title: "drag")
            } else if let mp = self.movePoint,
                mp.collide(origin: theStart, width: mp.bounds.width) {
                self.filledCurve = false
                self.finalSegment(fin: {mp,cp1,cp2 in
                    self.editedPath.move(to: mp.position)
                    self.controlPoints.append(ControlPoint(mp: mp, cp1: cp1, cp2: cp2))
                })
            } else if let _ = self.movePoint, self.closedCurve {
                self.finalSegment(fin: {
                    mp,cp1,cp2 in self.addSegment(mp: mp, cp1: cp1, cp2: cp2)
                })
            } else  {
                let theEnd: NSPoint = convert(event.locationInWindow, from:nil)
                switch self.tool {
                case .Pen:
                    self.createLine(topLeft: theStart, bottomRight: theEnd)
                    self.editedPath.removeAllPoints()
                case .Line:
                    self.createLine(topLeft: theStart, bottomRight: theEnd)
                    self.editedPath.removeAllPoints()
                case .Triangle:
                    self.createLine(topLeft: theStart, bottomRight: theEnd)
                    self.editedPath.removeAllPoints()
                case .Oval:
                    self.createOval(topLeft: theStart, bottomRight: theEnd)
                    self.editedPath.removeAllPoints()
                case .Rectangle:
                    self.createRectangle(topLeft: theStart, bottomRight: theEnd)
                    self.editedPath.removeAllPoints()
                case .Arc:
                    self.createArc(topLeft: theStart, bottomRight: theEnd)
                    self.editedPath.removeAllPoints()
                case .Curve:
                    self.createCurve(topLeft: theStart)
                case .Text:
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
        case .Pen, .Line, .Triangle, .Oval, .Rectangle, .Arc, .Drag:
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
        case .Curve:
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
        case .Text:
            fallthrough
        default:
            break
        }

        self.startPoint = nil
        self.roundedCurve=nil
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
                   lineWidth: CGFloat, angle: CGFloat, alpha: [CGFloat], blur: Double,
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
        let path = self.editedPath.copy() as! NSBezierPath

        if path.elementCount == 0 {
            return
        }

        var shadowValues: [CGFloat] = set.shadow
        shadowValues[0] = CGFloat(self.CurveShadowRadius.doubleValue)
        shadowValues[1] = CGFloat(self.CurveShadowOpacity.doubleValue)
        shadowValues[2] = CGFloat(self.CurveShadowOffsetX.doubleValue)
        shadowValues[3] = CGFloat(self.CurveShadowOffsetY.doubleValue)

        var dashPattern: [NSNumber] = []
        for slider in self.CurveDashGap?.subviews ?? [] {
            if let s = slider as? NSSlider {
                dashPattern.append(NSNumber(value: s.doubleValue))
            }
        }

        let curve = self.initCurve(
            path: path, fill: self.filledCurve, rounded: self.roundedCurve,
            strokeColor: self.CurveStrokeColor.fillColor,
            fillColor: self.CurveFillColor.fillColor,
            lineWidth: CGFloat(self.CurveWidth.doubleValue),
            angle: 0,
            alpha: [CGFloat(self.CurveOpacityStroke.doubleValue),
                    CGFloat(self.CurveOpacityFill.doubleValue)],
            blur: self.CurveBlur.doubleValue,
            shadow: shadowValues,
            shadowColor: self.CurveShadowColor.fillColor,
            gradientDirection: set.gradientDirection,
            gradientColor: [
                self.CurveGradientStartColor.fillColor,
                self.CurveGradientMiddleColor.fillColor,
                self.CurveGradientFinalColor.fillColor],
            gradientOpacity: [
                CGFloat(self.CurveGradientStartOpacity.doubleValue),
                CGFloat(self.CurveGradientMiddleOpacity.doubleValue),
                CGFloat(self.CurveGradientFinalOpacity.doubleValue)],
            gradientLocation: set.gradientLocation,
            cap: self.CurveCap.indexOfSelectedItem,
            join: self.CurveJoin.indexOfSelectedItem,
            dash: dashPattern,
            points: self.controlPoints)

        self.layer?.addSublayer(curve.canvas)
        self.curves.append(curve)

        self.clearCurvedPath()
        self.selectedCurve = curve
    }

    func selectCurve(pos: NSPoint) {
        if let curve = self.selectedCurve {
            self.clearControls(curve:curve, updatePoints: {})
            // reset edit curve button
            self.FrameButtons.isOn(title: "")
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
        self.updateFrameButtons()
        self.showFrameButtons()
        self.needsDisplay = true
    }

    func clearControls(curve: Curve, updatePoints: ()->Void) {
        if !curve.edit {
            curve.clearControlFrame()
        }
        updatePoints()

        self.hideFrameButtons()
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
        self.translateOrigin(to: NSPoint(x: self.frame.midX,
                                         y: self.frame.midY))
        self.scaleUnitSquare(to: NSSize(width: delta,
                                        height: delta))


        self.translateOrigin(to: NSPoint(x: -originX,
                                         y:  -originY))

        self.updateFrameButtons()

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
            layer.position = CGPoint(x: path.bounds.midX,y: path.bounds.midY)

            self.layer?.addSublayer(layer)
        }
    }
    func showCurvedPath(event: NSEvent) {
        let pos = convert(event.locationInWindow, from:nil)
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

    func moveCurvedPath(move: NSPoint, to: NSPoint, cp1: NSPoint, cp2: NSPoint) {
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

    func addSegment(mp: Dot, cp1: Dot, cp2: Dot) {
        var points = [NSPoint](repeating: .zero, count: 3)
        self.curvedPath.element(at: 1, associatedPoints: &points)
        self.editedPath.curve(to: points[2],
                              controlPoint1: points[0],
                              controlPoint2: points[1])

        self.controlPoints.append(ControlPoint(mp: mp, cp1: cp1, cp2: cp2))
    }

    func finalSegment(fin: (_ mp: Dot, _ cp1: Dot, _ cp2: Dot) -> Void ) {
        if let mp = self.movePoint, let cp1 = self.controlPoint1, let cp2 = self.controlPoint2 {
            fin(mp, cp1, cp2)
            
            self.editedPath.close()
            self.curvedPath.removeAllPoints()
            self.controlPath.removeAllPoints()
            self.curveLayer.removeFromSuperlayer()
            self.controlLayer.removeFromSuperlayer()
            self.editDone = true
        }
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
        if let curve = self.selectedCurve, let index = curves.firstIndex(of: curve), !curve.lock {
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
        if let curve = self.selectedCurve, let index = self.curves.firstIndex(of: curve) {
            let curve = self.curves[index]
            self.copiedCurve = self.initCurve(
                path: curve.path.copy() as! NSBezierPath,
                fill: curve.fill, rounded: curve.rounded,
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
                points: curve.points)
        }
    }

    func pasteCurve(to: CGPoint) {
        if let clone = self.copiedCurve {
            self.layer?.addSublayer(clone.canvas)
            self.curves.append(clone)

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
                x: curve.path.bounds.midX+set.dotSize,
                y: curve.path.bounds.midY-set.dotSize))
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
                self.FrameButtons.isEnable(title: "edit")
            default:
                curve.edit = false
                curve.clearPoints()
                curve.createControlFrame()
                self.FrameButtons.isEnable(all: true)
            }
        }
    }

    func lockCurve(sender: NSButton) {
        if let curve = self.selectedCurve {
            if sender.state == .off {
                sender.title = "🔓"
                self.FrameButtons.isEnable(all: true)
                curve.lock = false
            } else {
                sender.title = "🔒"
                self.FrameButtons.isEnable(
                    title: sender.alternateTitle)
                curve.lock = true
            }
        }
    }

    func groupCurve() {

    }

//    MARK: Tools func
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

    func createLine(topLeft: NSPoint, bottomRight: NSPoint) {
        self.editedPath = NSBezierPath()
        self.editedPath.move(to: topLeft)
        self.editedPath.line(to: NSPoint(x: bottomRight.x,
                                         y: bottomRight.y))
    }

    func createTriangle(topLeft: NSPoint, bottomRight: NSPoint, cmd: Bool = false) {
        let size = self.flipSize(topLeft: topLeft, bottomRight:  bottomRight)
        let wid = size.wid
        var hei = size.hei
        if cmd {
            let signHei: CGFloat = hei>0 ? 1 : -1
            hei = abs(wid) * signHei
        }
        self.editedPath.move(to: NSPoint(x: topLeft.x + wid / 2,
                                         y: topLeft.y))
        self.editedPath.line(to: NSPoint(x: topLeft.x,
                                         y: topLeft.y + hei ))
        self.editedPath.line(to: NSPoint(x: topLeft.x + wid,
                                         y: topLeft.y + hei))
    }

    func createOval(topLeft: NSPoint, bottomRight: NSPoint,cmd: Bool = false) {
        let size = self.flipSize(topLeft: topLeft, bottomRight: bottomRight)
        let wid = size.wid
        var hei = size.hei
        if cmd {
            let signHei: CGFloat = hei>0 ? 1 : -1
            hei = abs(wid) * signHei
        }
        self.editedPath = NSBezierPath(
            ovalIn: NSRect(x: topLeft.x, y: topLeft.y,
                   width: wid, height: hei))
    }

    func createRectangle(topLeft: NSPoint, bottomRight: NSPoint,
                         xRad: CGFloat = 0.00001, yRad: CGFloat = 0.00001,
                         cmd: Bool = false) {

        var botLeft: NSPoint
        var topRight: NSPoint

        if topLeft.x < bottomRight.x &&  topLeft.y > bottomRight.y {
            botLeft = NSPoint(x: topLeft.x, y: bottomRight.y)
            topRight = NSPoint(x: bottomRight.x, y: topLeft.y)
        } else if topLeft.x < bottomRight.x  && topLeft.y < bottomRight.y {
            botLeft = NSPoint(x: topLeft.x, y: topLeft.y)
            topRight = NSPoint(x: bottomRight.x, y: bottomRight.y)
        } else if topLeft.x > bottomRight.x && topLeft.y > bottomRight.y {
            botLeft = NSPoint(x: bottomRight.x, y: bottomRight.y)
            topRight = NSPoint(x: topLeft.x, y: topLeft.y)
        } else {
            botLeft = NSPoint(x: bottomRight.x,y: topLeft.y)
            topRight = NSPoint(x: topLeft.x, y: bottomRight.y)
        }
        // use cmd for create equal width and height
        let size = self.flipSize(topLeft: botLeft, bottomRight: topRight)
        var wid = size.wid
        var hei = size.hei

        if cmd && (topLeft.x < bottomRight.x) {
            wid = hei
        } else if cmd && (topLeft.x > bottomRight.x) && (topLeft.y < bottomRight.y){
             hei = wid
        } else if cmd && (topLeft.x > bottomRight.x) && (topLeft.y > bottomRight.y) {
            wid = hei
            botLeft.x = topRight.x - wid
            botLeft.y = topRight.y - wid
        }

        self.editedPath = NSBezierPath(
            roundedRect: NSRect(x: botLeft.x, y: botLeft.y,
                                width: wid, height: hei),
            xRadius: xRad, yRadius: yRad)
        self.roundedCurve = CGPoint(x: 0, y: 0)
    }

    func createArc(topLeft: NSPoint, bottomRight: NSPoint) {
        let size = self.flipSize(topLeft: topLeft, bottomRight: bottomRight)
        self.editedPath = NSBezierPath()

        let delta = remainder(abs(size.hei/2), 360)

        let startAngle = -delta
        let endAngle = delta

        self.editedPath.move(to: topLeft)
        self.editedPath.appendArc(withCenter: topLeft, radius: size.wid,
                                  startAngle: startAngle, endAngle: endAngle,
                                  clockwise: false)
    }

    func createCurve(topLeft: NSPoint) {
        if let mp = self.movePoint, let cp1 = self.controlPoint1, let cp2 = self.controlPoint2 {
            self.moveCurvedPath(move: mp.position, to: topLeft,
                                cp1: cp1.position, cp2: topLeft)
            self.addSegment(mp: mp, cp1: cp1, cp2: cp2)
        }

        self.movePoint = Dot.init(x: topLeft.x, y: topLeft.y, size: self.dotSize,
                                  offset: CGPoint(x: self.dotRadius,
                                                  y: self.dotRadius),
                                  radius: 0,
                                fillColor: nil)
        self.layer?.addSublayer(self.movePoint!)

        self.controlPoint1 = Dot.init(x: topLeft.x, y: topLeft.y, size: self.dotSize,
                                      offset: CGPoint(x: self.dotRadius,
                                                      y: self.dotRadius),
                                      radius: self.dotRadius)
        self.layer?.addSublayer(self.controlPoint1!)

        self.controlPoint2 = Dot.init(x: topLeft.x, y: topLeft.y, size: self.dotSize,
                                      offset: CGPoint(x: self.dotRadius,
                                                      y: self.dotRadius),
                                      radius: self.dotRadius)
        self.layer?.addSublayer(self.controlPoint2!)

        self.controlPath.removeAllPoints()
        self.controlLayer.removeFromSuperlayer()

        if let mp = self.movePoint {
            let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeInActiveApp]
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

    func createText(topLeft: NSPoint) {
        self.showTextTool()
        let width = self.TextTool.frame.width/2
        let height = self.TextTool.frame.height/2
        let deltaX = topLeft.x-self.bounds.minX
        let deltaY = topLeft.y-self.bounds.minY
        self.TextTool.setFrameOrigin(NSPoint(
            x: deltaX * self.zoomed - width,
            y: deltaY * self.zoomed - height))
    }

//    MARK: Key func
    func deleteCurve() {
        if tool == .Curve && self.movePoint != nil {
            self.clearCurvedPath()
            return
        }
        if let curve = self.selectedCurve,
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

        if let font = sharedFont {
            let height = self.TextTool.subviews[1].frame.height + set.dotSize * 2
            let x = (self.TextTool.frame.minX) / self.zoomed
            let y = (self.TextTool.frame.minY + height) / self.zoomed

            let pos = NSPoint(x: x + self.bounds.minX,
                              y: y + self.bounds.minY )
            self.editedPath.move(to: pos)
            for char in value {
                let glyph = font.glyph(withName: String(char))
                self.editedPath.append(withCGGlyph: CGGlyph(glyph), in: font)
            }
        }

        if let curve = self.selectedCurve {
            self.clearControls(curve: curve, updatePoints: {})
        }
        self.addCurve()
        if let curve = self.selectedCurve {
            self.createControls(curve: curve)
        }
        self.updateSliders()
        self.hideTextTool()
    }


    func hideTextTool() {
        self.TextTool.isHidden = true
    }

    func showTextTool() {
        self.TextTool.isHidden = false
    }

    //    MARK: FrameButtons func
    func updateFrameButtons() {
        if let curve = self.selectedCurve {
            let deltaX = self.bounds.minX
            let deltaY = self.bounds.minY
            let width50 = curve.lineWidth/2

            let x = curve.path.bounds.minX - set.dotSize - width50
            let y = curve.path.bounds.maxY + width50
            self.FrameButtons.frame = NSRect(
                x: (x-deltaX) * self.zoomed - self.FrameButtons.bounds.width,
                y: (y-deltaY) * self.zoomed - self.FrameButtons.bounds.height,
                width: self.FrameButtons.bounds.width,
                height: self.FrameButtons.bounds.height)

            if let lock = self.FrameButtons.subviews.last as? NSButton {
                lock.state = curve.lock ? .on : .off
                if curve.lock {
                    self.FrameButtons.isEnable(title: "lock")
                } else if curve.edit {
                    self.FrameButtons.isEnable(title: "edit")
                } else {
                    self.FrameButtons.isEnable(all: true)
                }
            }
        }
    }

    func hideFrameButtons() {
        self.FrameButtons.isHidden = true
    }

    func showFrameButtons() {
        self.FrameButtons.isHidden = false
    }

//    MARK: Action func
    func moveCurve(tag: Int, value: Double) {
        var deltax: CGFloat = 0
        var deltay: CGFloat = 0
        if let curve = self.selectedCurve, !curve.lock {
            if tag==0 {
                deltax = CGFloat(value) - curve.path.bounds.midX
            } else {
                deltay = CGFloat(value) - curve.path.bounds.midY
            }
            let  move = AffineTransform(translationByX: deltax,byY: deltay)
            curve.path.transform(using: move)

            self.clearControls(curve: curve, updatePoints: {
                curve.updatePoints(deltax: deltax,deltay: -deltay)
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
                     ind: Int? = nil ,cmd: Bool = false) {
        var scaleX: CGFloat = 1
        var scaleY: CGFloat = 1
        if let curve = selectedCurve, !curve.lock {
            if curve.path.bounds.width == 0 || curve.path.bounds.height == 0 {
                self.rotateCurve(angle: 0.001)
                curve.angle = 0
                return
            }
            var anchorX = anchor.x
            var anchorY = anchor.y

            if tag == 0 {
                scaleX = (CGFloat(value) / curve.path.bounds.width)
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
                scaleY = (CGFloat(value) / curve.path.bounds.height)
                if cmd {
                    scaleX = scaleY
                    if ind == 0 {
                        anchorX = 1
                        anchorY = 1
                    } else if ind == 2 {
                        anchorX = 1
                        anchorY = 0
                    } else if ind == 4  {
                        anchorX = 0
                    }
                }
            }
            let scale = AffineTransform(scaleByX: scaleX,byY: scaleY)

            let originX = curve.path.bounds.minX + curve.path.bounds.width * anchorX
            let originY = curve.path.bounds.minY + curve.path.bounds.height * anchorY
            
            curve.applyTransform(oX: originX, oY: originY,
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
            let scale = AffineTransform(scaleByX: scaleX,byY: scaleY)

            self.sketchBorder.transform(using: scale)

            let def = AffineTransform.init(
                translationByX: originX,byY: originY)
            self.sketchBorder.transform(using: def)
            self.needsDisplay = true
        }
        self.updateSliders()
    }

    func rotateCurve(angle: Double) {
        if let curve = self.selectedCurve, !curve.lock {
            let ang = CGFloat(angle)
            let rotate = AffineTransform(rotationByRadians: ang - curve.angle)

            let originX = curve.path.bounds.midX
            let originY = curve.path.bounds.midY
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

    func opacityCurve(tag: Int, value: Double) {
        if let curve = self.selectedCurve, !curve.lock {
            curve.alpha[tag] = CGFloat(value)
            self.clearControls(curve: curve, updatePoints: {})
        }
    }

    func borderWidthCurve(value: Double) {
        if let curve = self.selectedCurve, !curve.lock {
            curve.lineWidth = CGFloat(value)
            self.clearControls(curve: curve, updatePoints: {})
        }
    }

    func blurCurve(value: Double) {
        if let curve = self.selectedCurve, !curve.lock {
            curve.blur = value
            self.clearControls(curve: curve, updatePoints: {})
        }
    }

    func colorCurve() {
        if let curve = self.selectedCurve, !curve.lock {
            curve.strokeColor = self.CurveStrokeColor.fillColor
            curve.fillColor = self.CurveFillColor.fillColor
            self.needsDisplay = true
        }
    }

    func shadowColorCurve() {
        if let curve = self.selectedCurve, !curve.lock {
            curve.shadowColor = self.CurveShadowColor.fillColor
            self.needsDisplay = true
        }
    }

    func shadowCurve(value: [CGFloat]) {
        if let curve = self.selectedCurve, !curve.lock {
            curve.shadow = value
            self.clearControls(curve: curve, updatePoints: {})
        }
    }

    func gradientCurve() {
        if let curve = self.selectedCurve, !curve.lock {
            let start = CurveGradientStartColor.fillColor
            let middle = CurveGradientMiddleColor.fillColor
            let final = CurveGradientFinalColor.fillColor
            curve.gradientColor = [start, middle, final]

            self.clearControls(curve: curve, updatePoints: {})
            self.createControls(curve: curve)
            self.needsDisplay = true
        }
    }

    func opacityGradientCurve(tag: Int, value: Double) {
        if let curve = self.selectedCurve, !curve.lock {
            curve.gradientOpacity[tag] = CGFloat(value)
            self.clearControls(curve: curve, updatePoints: {})
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
            location[tag] = num < 0 ? 0 : num > 1 ? 1 : NSNumber(value:  num)

            curve.gradientLocation = location
            self.clearControls(curve: curve, updatePoints: {})
        }

    }

    func roundedCornerCurve(tag: Int, value: CGFloat) {
        if let curve = self.selectedCurve, !curve.lock, let rounded = curve.rounded {
            let wid = (curve.path.bounds.width + curve.lineWidth)/2
            let hei = (curve.path.bounds.height + curve.lineWidth)/2

            if tag==0 {
                var x = rounded.x - value/wid
                x  = x < 0 ? 0 : x > 1 ? 1 : x
                curve.rounded = CGPoint(x: x, y: rounded.y)
            } else if tag==1 {
                var y = rounded.y + value/hei
                y  = y < 0 ? 0 : y > 1 ? 1 : y
                curve.rounded = CGPoint(x: rounded.x, y: y)
            }
            let angle = curve.angle
            self.rotateCurve(angle: 0)
            let path = NSBezierPath.init(
                roundedRect: curve.path.bounds,
                xRadius: rounded.x * wid, yRadius: rounded.y * hei)
            curve.path = path
            self.rotateCurve(angle: Double(angle))
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

    func dashCurve(value: [NSNumber]) {
        if let curve = self.selectedCurve, !curve.lock {
            curve.setDash(dash: value)
            self.needsDisplay = true
        }
    }

    func alignLeftRightCurve(value: Int) {
        if let curve = self.selectedCurve, !curve.lock {
            let lineWidth = curve.lineWidth/2
            let alignLeftRight: [CGFloat] = [
                self.sketchBorder.bounds.minX+curve.path.bounds.width/2+lineWidth,
                self.sketchBorder.bounds.midX,
                self.sketchBorder.bounds.maxX-curve.path.bounds.width/2-lineWidth
            ]
            self.moveCurve(tag: 0, value: Double(alignLeftRight[value]))
        }
    }

    func alignUpDownCurve(value: Int) {
        if let curve = self.selectedCurve, !curve.lock {
            let lineWidth = curve.lineWidth/2
            let alignLeftRight: [CGFloat] = [
                self.sketchBorder.bounds.maxY-curve.path.bounds.height/2-lineWidth,
                self.sketchBorder.bounds.midY,
                self.sketchBorder.bounds.minY+curve.path.bounds.height/2+lineWidth
            ]
            self.moveCurve(tag: 1, value: Double(alignLeftRight[value]))
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
    func flipSize(topLeft: NSPoint,
                  bottomRight: NSPoint) -> (wid: CGFloat,hei: CGFloat) {
        return (bottomRight.x - topLeft.x, bottomRight.y - topLeft.y)
    }

    func cgImageFrom(ciImage: CIImage) -> CGImage? {
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            return cgImage
        }
        return nil
    }

    func imageData(fileType: NSBitmapImageRep.FileType = .png,
                       properties: [NSBitmapImageRep.PropertyKey : Any] = [:]) -> Data? {
        if let imageRep = bitmapImageRepForCachingDisplay(in: self.sketchBorder.bounds) {
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
//                        filter?.setValue(ciImg, forKey: kCIInputImageKey)
//                        filter?.setValue(curve.blur, forKey: kCIInputRadiusKey)
//                        if let output = filter?.outputImage {
//                            if let cgImage = self.cgImageFrom(ciImage: output) {
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
                return imageRep.representation(using: fileType, properties: properties)!
//            }
        }
        return nil
    }
}
