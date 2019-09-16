//
//  SketchPad.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 8/8/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.

// git

//0.5
//Save blur to .png
//Gradients
//Font panel
//Open file panel
//Show filename and select extension in save panel
//Selection frame
//Group images

//0.6
// Same increments
// Blueprint with grid (NS Draw TiledRect)
// Snap to grid

//0.7
// edit curves
// custom filters (proportional)

//0.8
// edit to round rect

// filters
// flatneess
// mitter limits
// fillcRule // strokeStart strokeEnd
// phase // use line dash phase to animate frame

// 1.0
// refactor init curve
// layers
// disable unused actions

// open svg
// create layers
// ark and other figures

import Cocoa

class SketchPad: NSView {
    var parent: NSViewController?
    weak var ToolBox: NSStackView?
    weak var FrameButtons: NSStackView?
    weak var CurveX: NSSlider!
    weak var CurveY: NSSlider!
    weak var CurveWid: NSSlider!
    weak var CurveHei: NSSlider!
    weak var CurveRotate: NSSlider!
    weak var CurveOpacity: NSSlider!
    weak var CurveWidth: NSSlider!
    weak var CurveBlur: NSSlider!

    weak var CurveXLabel: TextField!
    weak var CurveYLabel: TextField!
    weak var CurveWidLabel: TextField!
    weak var CurveHeiLabel: TextField!
    weak var CurveRotateLabel: TextField!
    weak var CurveOpacityLabel: TextField!
    weak var CurveWidthLabel: TextField!
    weak var CurveBlurLabel: TextField!

    weak var ColorPanel: NSColorPanel?
    weak var CurveStrokeColorPanel: ColorBox!
    weak var CurveFillColorPanel: ColorBox!
    weak var CurveShadowColorPanel: ColorBox!
    weak var CurveStrokeColor: NSBox!
    weak var CurveFillColor: NSBox!
    weak var CurveShadowColor: NSBox!
    weak var CurveStrokeLabel: TextField!
    weak var CurveFillLabel: TextField!

    weak var CurveShadowLabel: TextField!
    weak var CurveShadowRadius: TextField!
    weak var CurveShadowOpacity: TextField!
    weak var CurveShadowOffsetX: TextField!
    weak var CurveShadowOffsetY: TextField!
    weak var CurveRadiusStepper: NSStepper!
    weak var CurveOpacityStepper: NSStepper!
    weak var CurveOffsetXStepper: NSStepper!
    weak var CurveOffsetYStepper: NSStepper!

    weak var CurveCap: NSSegmentedControl!
    weak var CurveJoin: NSSegmentedControl!
    weak var CurveDashGap: NSStackView!

    var TrackArea: NSTrackingArea!

    var tempTextField: TextField?
    var textFields: [TextField] = []

    var sketchDir: URL?
    var sketchName: String?
    var sketchBorder = NSBezierPath()
    // change to zero when save image
    var sketchWidth: CGFloat = set.lineWidth
    var sketchColor = set.guiColor

    var editedPath: NSBezierPath = NSBezierPath()
    let editLayer = CAShapeLayer()
    let editColor = set.guiColor
    var editDone: Bool = false

    var startPoint: NSPoint?

    var selectedCurve: Curve?
    var curves: [Curve] = []

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

    var zoomed: CGFloat = 1.0
    var zoomOrigin = CGPoint(x: 0, y: 0)

    enum Tools {
        case pen, line, triangle, oval, rectangle,
        curve, text, drag
        mutating func set(_ tool: String) {
            switch tool {
            case "pen":
                self = .pen
            case "line":
                self = .line
            case "triangle":
                self = .triangle
            case "oval":
                self = .oval
            case "rectangle":
                self = .rectangle
            case "curve":
                self = .curve
            case "text":
                self = .text
            default:
                self = .drag
            }
        }
    }
    var tool = Tools.drag

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
        self.editLayer.lineWidth = set.lineWidth
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
        // text fields
        self.abortTextFields()

        // filters
//        self.wantsLayer = true
        self.layerUsesCoreImageFilters = true

    }

    func setTextField(field: TextField) {
        self.textFields.append(field)
    }

    func abortTextFields() {
        for field in self.textFields {
            let _ = field.abortEditing()
        }
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

        if let curve = self.selectedCurve {
            curve.updateButtons()
        }
        self.needsDisplay = true
    }

    func setZoomOrigin(deltaX: CGFloat, deltaY: CGFloat) {
        self.zoomOrigin = CGPoint(
            x: (self.zoomOrigin.x - deltaX),
            y: (self.zoomOrigin.y - deltaY))
        self.zoomSketch(value: Double(self.zoomed * 100))
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
        if let mp = self.movePoint, let cp1 = self.controlPoint1 {
            let pos: NSPoint = convert(event.locationInWindow, from:nil)
            self.moveCurvedPath(move: mp.position, to: pos,
                                cp1: mp.position,
                                cp2: cp1.position)
            self.updatePathLayer(layer: self.curveLayer, path: self.curvedPath)
            self.needsDisplay = true
        }
    }

    override func mouseDragged(with event: NSEvent) {
        let theEnd = convert(event.locationInWindow, from:nil)
        if let curve = self.selectedCurve, curve.edit {
            self.clearControls(curve: curve, updatePoints: {})
            curve.editPoint(pos: theEnd)
        } else if let curve = self.selectedCurve, let dot = curve.controlDot {
            let deltax = event.deltaX / self.zoomed
            let deltay = event.deltaY / self.zoomed
            switch dot.name! {
            case "0":
                let resize = Double(curve.path.bounds.height + deltay)
                self.resizeCurve(tag: 1, value: resize,anchor: CGPoint(x: 0, y: 1))
                fallthrough
            case "1":
                let resize = Double(curve.path.bounds.width - deltax)
                self.resizeCurve(tag: 0, value: resize, anchor: CGPoint(x: 1, y: 0))
            case "2":
                let resize = Double(curve.path.bounds.width - deltax)
                self.resizeCurve(tag: 0, value: resize, anchor: CGPoint(x: 1, y: 0))
                fallthrough
            case "3":
                let resize = Double(curve.path.bounds.height - deltay)
                self.resizeCurve(tag: 1, value: resize)
            case "4":
                let resize = Double(curve.path.bounds.height - deltay)
                self.resizeCurve(tag: 1, value: resize)
                fallthrough
            case "5":
                let resize = Double(curve.path.bounds.width + deltax)
                self.resizeCurve(tag: 0, value: resize)
            case "6":
                let resize = Double(curve.path.bounds.width + deltax)
                self.resizeCurve(tag: 0, value: resize)
                fallthrough
            case "7":
                let resize = Double(curve.path.bounds.height + deltay)
                self.resizeCurve(tag: 1, value: resize,anchor: CGPoint(x: 0, y: 1))
            case "8":
                let rotate = atan2(theEnd.y+event.deltaY-curve.path.bounds.midY,
                            theEnd.x+event.deltaX-curve.path.bounds.midX)
                let dt = rotate-curve.frameAngle
                self.rotateCurve(angle:  Double(curve.angle+dt))
                curve.frameAngle = rotate
            default:
                break
            }
        } else {
            if let theStart = self.startPoint {
                switch self.tool {
                case .pen:
                    self.editedPath.move(to: theStart)
                    self.editedPath.line(to: theEnd)
                    self.startPoint = convert(event.locationInWindow, from:nil)
                    self.editDone = true
                    self.editedPath.close()
                case .line:
                    self.editedPath.removeAllPoints()
                    self.createDot(topLeft: theStart,  bottomRight: theEnd)
                    self.editDone = true
                    self.editedPath.close()
                case .triangle:
                    self.editedPath.removeAllPoints()
                    let size = self.flipSize(topLeft: theStart, bottomRight: theEnd)
                    self.editedPath.move(to: NSPoint(x: theStart.x + size.wid / 2,
                                                     y: theStart.y))
                    self.editedPath.line(to: NSPoint(x: theStart.x, y: theStart.y + size.hei ))
                    self.editedPath.line(to: NSPoint(x: theStart.x + size.wid,
                                                     y: theStart.y + size.hei))
                    self.editDone = true
                    self.editedPath.close()
                case .oval:
                    self.editedPath.removeAllPoints()
                    self.createOval(topLeft: theStart, bottomRight: theEnd)
                    self.editDone = true
                    self.editedPath.close()
                case .rectangle:
                    self.editedPath.removeAllPoints()
                    self.createRectangle(topLeft: theStart, bottomRight: theEnd)
                    self.editDone = true
                    self.editedPath.close()
                case .curve:
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
                case .text:
                    self.createText(topLeft: theStart, bottomRight: theEnd)
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

        self.abortTextFields()
        if let theStart = self.startPoint {
            if let curve = self.selectedCurve, curve.edit {
                curve.selectPoint(pos: theStart)
            } else if let curve = self.selectedCurve,
                let dot = curve.controlFrame?.collideLabel(pos: theStart), !curve.lock  {
                curve.controlDot = dot
                self.tool = Tools.drag
                ToolBox?.isOn(title: "drag")
            } else if let mp = self.movePoint,
                mp.collide(origin: theStart, radius: mp.bounds.width) {
                self.filledCurve = false
                self.finalSegment(fin: {mp,cp1,cp2 in
                    self.editedPath.move(to: mp.position)
                    self.controlPoints.append(ControlPoint(mp: mp, cp1: cp1, cp2: cp2))
                    self.controlPoint1 = nil
                    cp1.removeFromSuperlayer()
                    self.controlPoint2 = nil
                    cp2.removeFromSuperlayer()
                })

            } else if let _ = self.movePoint, self.closedCurve {
                self.finalSegment(fin: {
                    mp,cp1,cp2 in self.addSegment(mp: mp, cp1: cp1, cp2: cp2)
                })
            } else  {
                let theEnd: NSPoint = convert(event.locationInWindow, from:nil)
                switch self.tool {
                case .pen:
                    self.createDot(topLeft: theStart, bottomRight: theEnd)
                    self.editedPath.removeAllPoints()
                case .line:
                    self.createDot(topLeft: theStart, bottomRight: theEnd)
                    self.editedPath.removeAllPoints()
                case .triangle:
                    self.createDot(topLeft: theStart, bottomRight: theEnd)
                    self.editedPath.removeAllPoints()
                case .oval:
                    self.createOval(topLeft: theStart, bottomRight: theEnd)
                    self.editedPath.removeAllPoints()
                case .rectangle:
                    self.createRectangle(topLeft: theStart, bottomRight: theEnd)
                    self.editedPath.removeAllPoints()
                case .curve:
                    self.createCurve(topLeft: theStart)
                case .text:
                    self.createText(topLeft: theStart, bottomRight: theEnd)
                default:
                    self.selectCurve(pos: theStart)
                }
            }
        }
        self.needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        print("up")
        switch self.tool {
        case .pen, .line, .triangle, .oval, .rectangle, .drag:
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
        case .curve, .text:
            fallthrough
        default:
            break
        }

        self.startPoint = nil

        self.closedCurve = false
        self.filledCurve = true
        self.editDone = false

        self.updateSliders()
        self.needsDisplay = true
    }

//    MARK: Control func
    func initCurve(path: NSBezierPath,
                   filled: Bool, strokeColor: NSColor, fillColor: NSColor,
                   lineWidth: CGFloat, angle: CGFloat, alpha: CGFloat, blur: Double,
                   shadow: [CGFloat], shadowColor: NSColor,
                   cap: Int, join: Int, dash: [NSNumber],
                   points: [ControlPoint]) -> Curve {

        let curve = Curve.init(parent: self, path: path, isFilled: filled)

        curve.strokeColor = strokeColor
        curve.fillColor = fillColor
        curve.lineWidth =  lineWidth
        curve.angle = angle
        curve.alpha = alpha
        curve.blur = blur
        curve.shadow = shadow
        curve.shadowColor = shadowColor
        curve.setCap(value: cap)
        curve.setJoin(value: join)
        curve.setDash(dash: dash)
        curve.setPoints(points: points)
        return curve
    }

    func addCurve() {
        let path = self.editedPath.copy() as! NSBezierPath
        self.editedPath.removeAllPoints()
        self.editLayer.removeFromSuperlayer()

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

        let curve = self.initCurve(path: path, filled: self.filledCurve,
               strokeColor: self.CurveStrokeColor?.fillColor ?? set.strokeColor,
               fillColor: self.CurveFillColor?.fillColor ?? set.fillColor,
               lineWidth: CGFloat(self.CurveWidth?.doubleValue ?? 1),
               angle: 0, alpha: CGFloat(self.CurveOpacity?.doubleValue ?? 1),
               blur: self.CurveBlur?.doubleValue ?? 0,
               shadow: shadowValues,
               shadowColor: self.CurveShadowColor?.fillColor ?? set.shadowColor,
               cap: self.CurveCap?.indexOfSelectedItem ?? 0,
               join: self.CurveJoin?.indexOfSelectedItem ?? 0,
               dash: dashPattern,
               points:  self.controlPoints)

        self.curves.append(curve)

        for point in self.controlPoints {
            point.mp.removeFromSuperlayer()
            point.cp1.removeFromSuperlayer()
            point.cp2.removeFromSuperlayer()
        }
        self.controlPoints = []
        self.movePoint = nil
        self.selectedCurve = curve
    }

    func selectCurve(pos: NSPoint) {
        if let curve = self.selectedCurve {
            self.clearControls(curve:curve, updatePoints: {})
            // reset edit curve button
            self.FrameButtons?.isOn(title: "")
            curve.edit = false
            self.selectedCurve = nil
        } else {
            if let panel = self.ColorPanel {
                panel.close()
                self.ColorPanel = nil
                self.CurveStrokeColorPanel.state = .off
                self.CurveStrokeColorPanel.restore()
                self.CurveFillColorPanel.state = .off
                self.CurveFillColorPanel.restore()
                self.CurveShadowColorPanel.state = .off
                self.CurveShadowColorPanel.restore()
            }
        }

        for curve in curves {
            let wid50 = curve.lineWidth/2
            let bounds = NSRect(x: curve.path.bounds.minX - wid50,
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
        curve.updateButtons()
        curve.showButtons()
        self.needsDisplay = true
    }

    func clearControls(curve: Curve, updatePoints: ()->Void) {
        if !curve.edit {
            curve.clearControlFrame()
        }
        updatePoints()

        curve.hideButtons()
        self.needsDisplay = true
    }

//    MARK: Sliders
    func updateSliders() {
        if let curve = selectedCurve {
            let x = round(Double(curve.path.bounds.midX)*10)/10
            let y = round(Double(curve.path.bounds.midY)*10)/10
            let wid = round(Double(curve.path.bounds.width)*10)/10
            let hei = round(Double(curve.path.bounds.height)*10)/10
            let angle = round(Double(curve.angle)*10)/10
            let opacity = round(Double(curve.alpha)*10)/10
            let width = round(Double(curve.lineWidth)*10)/10
            let blur = round(Double(curve.blur)*10)/10

            let strokeColor = curve.strokeColor
            let fillColor = curve.fillColor
            let shadowColor = curve.shadowColor
            let shadow = curve.shadow
            let rad = Double(shadow[0])
            let opa = Double(shadow[1])
            let offx = Double(shadow[2])
            let offy = Double(shadow[3])

            self.CurveX!.doubleValue = x
            self.CurveY!.doubleValue = y
            self.CurveWid!.doubleValue = wid
            self.CurveHei!.doubleValue = hei
            self.CurveRotate!.doubleValue = angle
            self.CurveOpacity!.doubleValue = opacity
            self.CurveWidth!.doubleValue = width
            self.CurveBlur!.doubleValue = blur

            self.CurveStrokeColor.fillColor = strokeColor
            self.CurveFillColor.fillColor = fillColor
            self.CurveShadowColor.fillColor = shadowColor

            self.CurveRadiusStepper.doubleValue = rad
            self.CurveOpacityStepper.doubleValue = opa
            self.CurveOffsetXStepper.doubleValue = offx
            self.CurveOffsetYStepper.doubleValue = offy

            self.CurveXLabel!.doubleValue = x
            self.CurveYLabel!.doubleValue = y
            self.CurveWidLabel!.doubleValue = wid
            self.CurveHeiLabel!.doubleValue = hei
            self.CurveRotateLabel!.doubleValue = angle
            self.CurveOpacityLabel!.doubleValue = opacity
            self.CurveWidthLabel!.doubleValue = width
            self.CurveBlurLabel!.doubleValue = blur

            self.CurveStrokeLabel.stringValue = strokeColor.hexString
            self.CurveFillLabel.stringValue = fillColor.hexString
            self.CurveShadowLabel.stringValue = shadowColor.hexString
            self.CurveShadowRadius.stringValue = String(Int(rad))
            self.CurveShadowOpacity.stringValue = String(opa)
            self.CurveShadowOffsetX.stringValue = String(Int(offx))
            self.CurveShadowOffsetY.stringValue = String(Int(offy))

            self.CurveCap.selectedSegment = curve.cap
            self.CurveJoin.selectedSegment = curve.join
            var index = 0
            for item in CurveDashGap.subviews {
                if let slider = item as? NSSlider {
                    slider.doubleValue = Double(truncating: curve.dash[index])
                    index += 1
                }
            }

        } else {
            let x = round(Double(self.sketchBorder.bounds.minX)*10)/10
            let y = round(Double(self.sketchBorder.bounds.minY)*10)/10
            let wid = round(Double(self.sketchBorder.bounds.width)*10)/10
            let hei = round(Double(self.sketchBorder.bounds.height)*10)/10
            self.CurveX!.doubleValue = x
            self.CurveY!.doubleValue = y
            self.CurveWid!.doubleValue = wid
            self.CurveHei!.doubleValue = hei
            self.CurveXLabel!.doubleValue = x
            self.CurveYLabel!.doubleValue = y
            self.CurveWidLabel!.doubleValue = wid
            self.CurveHeiLabel!.doubleValue = hei
        }
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
        self.controlPoint1 = nil
        cp1.removeFromSuperlayer()
        self.controlPoint2 = nil
        cp2.removeFromSuperlayer()
    }

    func finalSegment(fin: (_ mp: Dot, _ cp1: Dot, _ cp2: Dot) -> Void ) {
        if let mp = self.movePoint, let cp1 = self.controlPoint1, let cp2 = self.controlPoint2 {
            fin(mp, cp1, cp2)
            self.editedPath.close()
            self.curvedPath.removeAllPoints()
            self.controlPath.removeAllPoints()
            self.curveLayer.removeFromSuperlayer()
            self.controlLayer.removeFromSuperlayer()
            self.tool = Tools.drag
            ToolBox?.isOn(title: "drag")
            self.editDone = true
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

    func cloneCurve() {
        if let curve = self.selectedCurve, let index = self.curves.firstIndex(of: curve) {
            let curve = self.curves[index]
            let clone = self.initCurve(path: curve.path.copy() as! NSBezierPath,
                                       filled: curve.isFilled,
                                       strokeColor: curve.strokeColor,
                                       fillColor: curve.fillColor,
                                       lineWidth: curve.lineWidth,
                                       angle: curve.angle,
                                       alpha: curve.alpha, blur: curve.blur,
                                       shadow: curve.shadow, shadowColor: curve.shadowColor,
                                       cap: curve.cap, join: curve.join, dash: curve.dash,
                                       points: curve.points)
            self.curves.insert(clone, at: index)
            self.clearControls(curve: curve, updatePoints: {})
            self.selectedCurve = clone
            self.moveCurve(tag: 0,
                           value: Double(clone.path.bounds.midX+set.dotSize))
            self.moveCurve(tag: 1,
                           value: Double(clone.path.bounds.midY-set.dotSize))
            self.createControls(curve: clone)
            self.needsDisplay = true
        }
    }

    func editCurve(name: String) {
        if let curve = self.selectedCurve {
            switch name {
            case "edit":
                curve.edit = true
                curve.clearControlFrame()
                curve.createPoints()
                if let buttons = self.FrameButtons {
                    buttons.isEnable(title: "edit")
                }
            default:
                curve.edit = false
                curve.clearPoints()
                curve.createControlFrame()
                if let buttons = self.FrameButtons {
                    buttons.isEnable(all: true)
                }
            }
        }
    }

    func lockCurve() {
        if let curve = self.selectedCurve {
            curve.lock = !curve.lock
        }
    }

//    MARK: Tools func
    func deleteCurve() {
        if let curve = self.selectedCurve,
            let index = self.curves.firstIndex(of: curve) {
            self.curves.remove(at: index)
            curve.shape.removeFromSuperlayer()
            curve.canvas.removeFromSuperlayer()
            self.clearControls(curve: curve, updatePoints: {})

            self.selectedCurve = nil
            self.needsDisplay = true
        }
    }

    func createDot(topLeft: NSPoint, bottomRight: NSPoint) {
        self.editedPath = NSBezierPath()
        self.editedPath.move(to: topLeft)
        self.editedPath.line(to: NSPoint(x: bottomRight.x,
                                         y: bottomRight.y))
    }

    func createOval(topLeft: NSPoint, bottomRight: NSPoint) {
        let size = self.flipSize(topLeft: topLeft, bottomRight: bottomRight)
        self.editedPath = NSBezierPath(
            ovalIn: NSRect(x: topLeft.x, y: topLeft.y,
                   width: size.wid,height: size.hei))
    }

    func createRectangle(topLeft: NSPoint, bottomRight: NSPoint) {
        let size = self.flipSize(topLeft: topLeft, bottomRight: bottomRight)
        self.editedPath = NSBezierPath(
            rect: NSRect(x: topLeft.x,y: topLeft.y,
                                width: size.wid,height: size.hei))
    }


    func createCurve(topLeft: NSPoint) {
        if let mp = self.movePoint, let cp1 = self.controlPoint1, let cp2 = self.controlPoint2 {
            self.moveCurvedPath(move: mp.position, to: topLeft,
                                cp1: cp1.position, cp2: topLeft)
            self.addSegment(mp: mp, cp1: cp1, cp2: cp2)
        }

        self.movePoint = Dot.init(x: topLeft.x, y: topLeft.y, size: self.dotSize,
                                  offset: CGPoint(x: self.dotRadius,
                                                  y: self.dotRadius), radius: 0)
        self.layer?.addSublayer(self.movePoint!)

        self.controlPoint1 = Dot.init(x: topLeft.x, y: topLeft.y, size: self.dotSize,
                                      offset: CGPoint(x: self.dotRadius, y: self.dotRadius),
                                      radius: self.dotRadius, bg: true)
        self.layer?.addSublayer(self.controlPoint1!)

        self.controlPoint2 = Dot.init(x: topLeft.x, y: topLeft.y, size: self.dotSize,
                                      offset: CGPoint(x: self.dotRadius, y: self.dotRadius),
                                      radius: self.dotRadius, bg: true)
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

    func removeText() {
        if let txt = self.tempTextField {
            if let index = self.textFields.firstIndex(of: txt) {
                self.textFields.remove(at: index)
            }
            txt.removeFromSuperview()
        }
    }

    func createText(topLeft: NSPoint, bottomRight: NSPoint) {
        self.removeText()
        let wid = bottomRight.x - topLeft.x
        let rect = NSRect(x: topLeft.x,y: topLeft.y,
                         width: wid, height: set.textHeight)
        self.tempTextField = TextField.init(frame: rect)

        if let txt = self.tempTextField {
            txt.stringValue = "text"
            txt.isBordered = true
            txt.backgroundColor = NSColor.clear
            txt.cell?.sendsActionOnEndEditing = true

            txt.target = self
            txt.action = #selector(self.setGlyphs)

            self.setTextField(field: txt)
            self.addSubview(txt)
        }
    }

    @objc func setGlyphs(sender: TextField) {
        self.editedPath = NSBezierPath()

        if let txt = self.tempTextField,
            let font = NSFont(name: set.fontName, size: set.fontSize) {
            let topLeft = NSPoint(x: txt.frame.minX,
                                  y: txt.frame.minY)
            self.editedPath.move(to: topLeft)
            for char in sender.stringValue {
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
        self.removeText()
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
                     anchor: CGPoint = CGPoint(x: 0, y: 0)) {
        var scalex: CGFloat = 1
        var scaley: CGFloat = 1
        if let curve = selectedCurve, !curve.lock {
            if curve.path.bounds.width == 0 || curve.path.bounds.height == 0 {
                self.rotateCurve(angle: 0.001)
                curve.angle = 0
                return
            }
            if tag == 0 {
                scalex = (CGFloat(value) / curve.path.bounds.width)
            } else {
                scaley = (CGFloat(value) / curve.path.bounds.height)
            }
            let scale = AffineTransform(scaleByX: scalex,byY: scaley)
            let originX = curve.path.bounds.minX + curve.path.bounds.width * anchor.x
            let originY = curve.path.bounds.minY + curve.path.bounds.height * anchor.y
            
            curve.applyTransform(oX: originX, oY: originY,
                           transform: {curve.path.transform(using: scale)})

            self.clearControls(curve: curve, updatePoints: {
                curve.updatePoints(ox: originX, oy: originY,
                                       scalex: scalex, scaley: scaley)
            })
        } else {
            if tag == 0 {
                scalex = CGFloat(value) / self.sketchBorder.bounds.width
            } else {
                scaley = CGFloat(value) / self.sketchBorder.bounds.height
            }
            let originX = self.sketchBorder.bounds.minX
            let originY = self.sketchBorder.bounds.minY

            let origin = AffineTransform.init(
                translationByX: -originX, byY: -originY)
            self.sketchBorder.transform(using: origin)
            let scale = AffineTransform(scaleByX: scalex,byY: scaley)

            self.sketchBorder.transform(using: scale)

            let def = AffineTransform.init(
                translationByX: originX,byY: originY)
            self.sketchBorder.transform(using: def)
        }
        self.updateSliders()
    }

    func rotateCurve(angle: Double) {
        if let curve = self.selectedCurve, !curve.lock {
            let ang = CGFloat(angle)
            let rotate = AffineTransform(rotationByRadians: ang - curve.angle)
            let originX = curve.path.bounds.midX
            let originY = curve.path.bounds.midY
            curve.applyTransform(oX: originX, oY: originY,
                           transform: {curve.path.transform(using: rotate)})

            self.clearControls(curve: curve, updatePoints: {
                    curve.updatePoints(angle: ang - curve.angle)
                }
            )
            curve.angle = ang
            self.updateSliders()
        }
    }

    func opacityCurve(value: Double) {
        if let curve = self.selectedCurve, !curve.lock {
            curve.alpha = CGFloat(value)
            self.clearControls(curve: curve, updatePoints: {})
        }
    }

    func widthCurve(value: Double) {
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
            let stroke = self.CurveStrokeColor?.fillColor ?? set.strokeColor
            let fill = self.CurveFillColor?.fillColor ?? set.fillColor
            
            curve.strokeColor = stroke
            curve.fillColor = fill
            self.needsDisplay = true
        }
    }

    func shadowColorCurve() {
        if let curve = self.selectedCurve, !curve.lock {
            let shadow = self.CurveShadowColor?.fillColor ?? set.shadowColor
            curve.shadowColor = shadow
            self.needsDisplay = true
        }
    }

    func shadowCurve(value: [CGFloat]) {
        if let curve = self.selectedCurve, !curve.lock {
            curve.shadow = value
            self.needsDisplay = true
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
            let alignLeftRight: [CGFloat] = [
                self.sketchBorder.bounds.minX+curve.path.bounds.width/2,
                self.sketchBorder.bounds.midX,
                self.sketchBorder.bounds.maxX-curve.path.bounds.width/2
            ]
            self.moveCurve(tag: 0, value: Double(alignLeftRight[value]))
        }
    }

    func alignUpDownCurve(value: Int) {
        if let curve = self.selectedCurve, !curve.lock {
            let alignLeftRight: [CGFloat] = [
                self.sketchBorder.bounds.maxY-curve.path.bounds.height/2,
                self.sketchBorder.bounds.midY,
                self.sketchBorder.bounds.minY+curve.path.bounds.height/2
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
        let wid = bottomRight.x - topLeft.x
        let hei = bottomRight.y - topLeft.y
        return (wid, hei)
    }

    func imageData(fileType: NSBitmapImageRep.FileType = .png,
                       properties: [NSBitmapImageRep.PropertyKey : Any] = [:]) -> Data? {

        if let imageRep = self.bitmapImageRepForCachingDisplay(in: self.sketchBorder.bounds) {

            self.cacheDisplay(in: self.sketchBorder.bounds, to: imageRep)
            return imageRep.representation(using: fileType, properties: properties)!
        }

//        if let imageRep = bitmapImageRepForCachingDisplay(in: self.sketchBorder.bounds) {
//
//            let context = NSGraphicsContext(bitmapImageRep: imageRep)!
//            let cgCtx = context.cgContext
//
////            var index = 0
//            if let layer = self.layer, let sublayers = layer.sublayers {
//                 layer.render(in: cgCtx)
//                for sublayer in sublayers {

//                    let curve = self.curves[index]
//                    if let ciImg = sublayer.ciImage() {
//                        let filter = CIFilter(name: "CIGaussianBlur")
//                        filter?.setValue(ciImg, forKey: kCIInputImageKey)
//                        filter?.setValue(curve.blur, forKey: kCIInputRadiusKey)
//                        if let output = filter?.outputImage {
//                            let data = NSBitmapImageRep(ciImage: output)
//                            print(output)
//                            let x = sublayer.bounds.minX
//                            let y = sublayer.bounds.minY
//                            print(x,y)
//
//                            let rect = CGRect(x: 0, y: 0,
//                                              width: x + sublayer.bounds.width,
//                                              height: y + sublayer.bounds.height)
//                            print(rect.midX,rect.midY, rect)
//
//
//                            print(sublayer.bounds,sublayer.frame)
//                            cgCtx.draw(data.cgImage!, in: rect)
//
//                        }
//                    }
//                    index += 1
//                }

//                if let img = cgCtx.makeImage() {
//                    let data = NSBitmapImageRep(cgImage: img)
//                    return data.representation(using: fileType, properties: properties)!
//                }
//            }
//        }
        return nil
    }
}
