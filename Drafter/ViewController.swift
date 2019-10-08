//
//  ViewController.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 8/8/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    var window: NSWindow!
    @IBOutlet weak var sketchView: SketchPad!

    @IBOutlet weak var toolUI: NSStackView!
    @IBOutlet weak var frameUI: FrameButtons!
    @IBOutlet weak var textUI: TextTool!
    @IBOutlet weak var actionUI: NSStackView!
    @IBOutlet weak var colorUI: NSStackView!

    @IBOutlet weak var zoomSketch: NSSlider!
    @IBOutlet weak var zoomDefaultSketch: NSPopUpButton!
    @IBOutlet weak var curveX: NSSlider!
    @IBOutlet weak var curveY: NSSlider!
    @IBOutlet weak var curveWid: NSSlider!
    @IBOutlet weak var curveHei: NSSlider!
    @IBOutlet weak var curveRotate: NSSlider!
    @IBOutlet weak var curveOpacityStroke: NSSlider!
    @IBOutlet weak var curveOpacityFill: NSSlider!
    @IBOutlet weak var curveWidth: NSSlider!

    @IBOutlet weak var curveXLabel: NSTextField!
    @IBOutlet weak var curveYLabel: NSTextField!
    @IBOutlet weak var curveWidLabel: NSTextField!
    @IBOutlet weak var curveHeiLabel: NSTextField!
    @IBOutlet weak var curveRotateLabel: NSTextField!
    @IBOutlet weak var curveWidthLabel: NSTextField!
    @IBOutlet weak var curveOpacityStrokeLabel: NSTextField!
    @IBOutlet weak var curveOpacityFillLabel: NSTextField!

    @IBOutlet weak var curveBlur: NSSlider!
    @IBOutlet weak var curveBlurLabel: NSTextField!

    @IBOutlet weak var curveStrokeColorPanel: ColorPanel!
    @IBOutlet weak var curveFillColorPanel: ColorPanel!
    @IBOutlet weak var curveStrokeColor: NSBox!
    @IBOutlet weak var curveFillColor: NSBox!
    @IBOutlet weak var curveStrokeLabel: NSTextField!
    @IBOutlet weak var curveFillLabel: NSTextField!

    @IBOutlet weak var curveGradientStartPanel: ColorPanel!
    @IBOutlet weak var curveGradientMiddlePanel: ColorPanel!
    @IBOutlet weak var curveGradientFinalPanel: ColorPanel!
    @IBOutlet weak var curveGradStartColor: NSBox!
    @IBOutlet weak var curveGradMiddleColor: NSBox!
    @IBOutlet weak var curveGradFinalColor: NSBox!
    @IBOutlet weak var curveGradStLab: NSTextField!
    @IBOutlet weak var curveGradMidLab: NSTextField!
    @IBOutlet weak var curveGradFinLab: NSTextField!

    @IBOutlet weak var curveGradStOpacity: NSSlider!
    @IBOutlet weak var curveGradStOpacityLab: NSTextField!
    @IBOutlet weak var curveGradMidOpacity: NSSlider!
    @IBOutlet weak var curveGradMidOpacityLab: NSTextField!
    @IBOutlet weak var curveGradFinOpacity: NSSlider!
    @IBOutlet weak var curveGradFinOpacityLab: NSTextField!

    @IBOutlet weak var curveShadowColorPanel: ColorPanel!
    @IBOutlet weak var curveShadowColor: NSBox!
    @IBOutlet weak var curveShadowLabel: NSTextField!
    @IBOutlet weak var curveShadowOpacity: NSSlider!
    @IBOutlet weak var curveShadowOpacityLabel: NSTextField!
    @IBOutlet weak var curveShadowRadius: NSSlider!
    @IBOutlet weak var curveShadowRadiusLabel: NSTextField!
    @IBOutlet weak var curveShadowOffsetX: NSSlider!
    @IBOutlet weak var curveShadowOffsetXLabel: NSTextField!
    @IBOutlet weak var curveShadowOffsetY: NSSlider!
    @IBOutlet weak var curveShadowOffsetYLabel: NSTextField!

    @IBOutlet weak var curveCap: NSSegmentedControl!
    @IBOutlet weak var curveJoin: NSSegmentedControl!
    @IBOutlet weak var curveDashGap: NSStackView!
    @IBOutlet weak var curveDash1Label: NSTextField!
    @IBOutlet weak var curveGap1Label: NSTextField!
    @IBOutlet weak var curveDash2Label: NSTextField!
    @IBOutlet weak var curveGap2Label: NSTextField!

    var textFields: [NSTextField] = []
    var colorPanel: ColorPanel?
    var savePanel: NSSavePanel?

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // mouse
        self.window?.acceptsMouseMovedEvents = true
        // keys
        NSEvent.addLocalMonitorForEvents(
            matching: NSEvent.EventTypeMask.keyDown) {
            if self.keyDownEvent(event: $0) {
                return nil
            } else {
                return $0
            }
        }
    }

//    MARK: KeyDown
    func keyDownEvent(event: NSEvent) -> Bool {
        guard NSApplication.shared.keyWindow === self.window else {
            return false
        }

        if !event.modifierFlags.contains(.command),
            let resp = self.window.firstResponder,
            resp.isKind(of: NSWindow.self) {
            let keys: [String] = ["v", "p", "l", "o",
                                  "t", "r", "s", "c", "f"]
            if let ch = event.charactersIgnoringModifiers {
                if let tag = keys.firstIndex(of: ch) {
                    sketchView.setTool(tag: tag)
                    return true
                }
            }
        }
        return false
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        window = self.view.window!

        actionUI.layer = CALayer()
        actionUI.layer?.backgroundColor = setup.guiColor.cgColor

        toolUI.layer = CALayer()
        toolUI.layer?.backgroundColor = setup.guiColor.cgColor

        zoomSketch.minValue = setup.minZoom * 2
        zoomSketch.maxValue = setup.maxZoom
        zoomDefaultSketch.removeAllItems()
        var zoom: [String] = []
        for step in stride(from: Int(setup.minZoom),
                           to: Int(setup.maxZoom) + 1,
                           by: Int(setup.minZoom)) {
            zoom.append(String(step))
        }
        zoomDefaultSketch.addItems(withTitles: zoom)
        let index100 = zoomDefaultSketch.indexOfItem(withTitle: "100")
        zoomDefaultSketch.select(zoomDefaultSketch.item(at: index100))
        zoomDefaultSketch.setTitle("100")

        curveX.maxValue = setup.maxScreenWidth
        curveY.maxValue = setup.maxScreenHeight
        curveX.minValue = setup.minResize
        curveY.minValue = setup.minResize
        curveWid.maxValue = setup.maxScreenWidth
        curveHei.maxValue = setup.maxScreenHeight
        curveWid.doubleValue = setup.screenWidth
        curveHei.doubleValue = setup.screenHeight
        curveRotate.minValue = setup.minRotate
        curveRotate.maxValue = setup.maxRotate
        curveWidth.doubleValue = Double(setup.lineWidth)
        curveWidth.maxValue = Double(setup.maxLineWidth)
        curveOpacityStroke.maxValue = 1
        curveOpacityStroke.doubleValue = curveOpacityStroke.maxValue
        curveOpacityFill.maxValue = 1
        curveOpacityFill.doubleValue = curveOpacityFill.maxValue

        for view in curveDashGap.subviews {
            if let slider = view as? NSSlider {
                slider.maxValue = setup.maxDash
            }
        }

        curveWidLabel.doubleValue = setup.screenWidth
        curveHeiLabel.doubleValue = setup.screenHeight
        curveWidthLabel.doubleValue = Double(setup.lineWidth)
        curveOpacityStrokeLabel.doubleValue =  curveOpacityStroke.doubleValue
        curveOpacityFillLabel.doubleValue =  curveOpacityFill.doubleValue

        curveStrokeColor.borderColor = setup.guiColor
        curveStrokeColor.fillColor = setup.strokeColor
        curveFillColor.borderColor = setup.guiColor
        curveFillColor.fillColor = setup.fillColor

        curveStrokeLabel.stringValue = setup.strokeColor.hexStr
        curveFillLabel.stringValue = setup.fillColor.hexStr

        curveShadowColor.borderColor =  setup.guiColor
        curveShadowColor.fillColor = setup.shadowColor
        curveShadowLabel.stringValue = setup.shadowColor.hexStr

        let shadow = setup.shadow.map {(fl) in Double(fl)}
        curveShadowRadius.maxValue = setup.maxShadowRadius
        curveShadowOpacity.maxValue = 1

        curveShadowOffsetX.minValue = -setup.maxShadowOffsetX
        curveShadowOffsetY.minValue = -setup.maxShadowOffsetY
        curveShadowOffsetX.maxValue = setup.maxShadowOffsetX
        curveShadowOffsetY.maxValue = setup.maxShadowOffsetY
        curveShadowRadius.doubleValue = shadow[0]
        curveShadowOpacity.doubleValue = shadow[1]
        curveShadowOffsetX.doubleValue = shadow[2]
        curveShadowOffsetY.doubleValue = shadow[3]

        curveShadowRadiusLabel.doubleValue = shadow[0]
        curveShadowOpacityLabel.doubleValue = shadow[1]
        curveShadowOffsetXLabel.doubleValue = shadow[2]
        curveShadowOffsetYLabel.doubleValue = shadow[3]

        curveGradStartColor.borderColor = setup.guiColor
        curveGradStartColor.fillColor = setup.gradientColor[0]
        curveGradMiddleColor.borderColor = setup.guiColor
        curveGradMiddleColor.fillColor = setup.gradientColor[1]
        curveGradFinalColor.borderColor = setup.guiColor
        curveGradFinalColor.fillColor = setup.gradientColor[2]
        curveGradStOpacity.doubleValue = Double(setup.gradientOpacity[0])
        curveGradStOpacity.maxValue = 1
        curveGradStOpacityLab.doubleValue = curveGradStOpacity.doubleValue
        curveGradMidOpacity.doubleValue = Double(setup.gradientOpacity[1])
        curveGradMidOpacity.maxValue = 1
        curveGradMidOpacityLab.doubleValue = curveGradMidOpacity.doubleValue
        curveGradFinOpacity.doubleValue = Double(setup.gradientOpacity[2])
        curveGradFinOpacity.maxValue = 1
        curveGradFinOpacityLab.doubleValue = curveGradFinOpacity.doubleValue

        curveGradStLab.stringValue = setup.gradientColor[0].hexStr
        curveGradMidLab.stringValue = setup.gradientColor[1].hexStr
        curveGradFinLab.stringValue = setup.gradientColor[2].hexStr

        curveBlur.maxValue = setup.maxBlur

        self.setupSketchView()
        textUI!.setupTextTool()

        // for precision position create and remove panel
        ColorPanel.setupSharedColorPanel()

        self.findAllTextFields(root: self.view)

        self.setupObservers()
        self.showFileName()
    }

    func setupSketchView() {
        sketchView.parent = self
        sketchView.toolUI = toolUI
        sketchView.frameUI = frameUI
        sketchView.textUI = textUI
        sketchView.colorUI = colorUI

        sketchView.curveOpacityStroke = curveOpacityStroke
        sketchView.curveOpacityFill = curveOpacityFill
        sketchView.curveWidth = curveWidth

        sketchView.curveCap = curveCap
        sketchView.curveJoin = curveJoin
        sketchView.curveDashGap = curveDashGap

        sketchView.curveStrokeColor = curveStrokeColor
        sketchView.curveFillColor = curveFillColor
        sketchView.curveShadowColor = curveShadowColor
        sketchView.curveShadowRadius = curveShadowRadius
        sketchView.curveShadowOpacity = curveShadowOpacity

        sketchView.curveShadowOffsetX = curveShadowOffsetX
        sketchView.curveShadowOffsetY = curveShadowOffsetY
        sketchView.curveGradStartColor = curveGradStartColor
        sketchView.curveGradMiddleColor = curveGradMiddleColor
        sketchView.curveGradFinalColor = curveGradFinalColor

        sketchView.curveGradStOpacity = curveGradStOpacity
        sketchView.curveGradMidOpacity = curveGradMidOpacity
        sketchView.curveGradFinOpacity = curveGradFinOpacity

        sketchView.curveBlur = curveBlur

    }

//    MARK Obserevers func
    func setupObservers() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(abortTextFields),
                       name: Notification.Name("abortTextFields"),
                       object: nil)
        nc.addObserver(self, selector: #selector(updateSketchColor),
                       name: Notification.Name("updateSketchColor"),
                       object: nil)
        nc.addObserver(self, selector: #selector(updateSliders),
                       name: Notification.Name("updateSliders"),
                       object: nil)
        nc.post(name: Notification.Name("abortTextFields"), object: nil)
    }

    func findAllTextFields(root: NSView) {
        for view in root.subviews {
            for child in view.subviews {
                if let textField = child as? NSTextField,
                    textField.isEditable {
                    self.textFields.append(textField)
                } else {
                    self.findAllTextFields(root: child)
                }
            }
        }
    }

    @objc func abortTextFields() {
        for field in self.textFields {
            field.abortEditing()
        }
    }

    @objc func updateSketchColor() {
        sketchView!.colorCurve()
    }

    @objc func updateSliders() {
        let view = sketchView!
        if let curve = view.selectedCurve {
            self.curveX.doubleValue = Double(curve.path.bounds.midX)
            self.curveY.doubleValue = Double(curve.path.bounds.midY)
            self.curveWid.doubleValue = Double(curve.path.bounds.width)
            self.curveHei.doubleValue = Double(curve.path.bounds.height)
            self.curveRotate.doubleValue = Double(curve.angle)

            let opacity = curve.alpha.map {(fl) in Double(fl)}
            self.curveOpacityStroke.doubleValue = opacity[0]
            self.curveOpacityFill.doubleValue = opacity[1]
            self.curveWidth.doubleValue = Double(curve.lineWidth)
            self.curveBlur.doubleValue = Double(curve.blur)

            self.curveStrokeColor.fillColor = curve.strokeColor
            self.curveFillColor.fillColor = curve.fillColor
            self.curveShadowColor.fillColor = curve.shadowColor

            let shadow = curve.shadow.map {(fl) in Double(fl)}
            self.curveShadowRadius.doubleValue = shadow[0]
            self.curveShadowOpacity.doubleValue = shadow[1]
            self.curveShadowOffsetX.doubleValue = shadow[2]
            self.curveShadowOffsetY.doubleValue = shadow[3]

            self.curveGradStartColor.fillColor = curve.gradientColor[0]
            self.curveGradMiddleColor.fillColor = curve.gradientColor[1]
            self.curveGradFinalColor.fillColor = curve.gradientColor[2]

            let gradOpacity = curve.gradientOpacity.map {(fl) in Double(fl)}
            self.curveGradStOpacity.doubleValue = gradOpacity[0]
            self.curveGradMidOpacity.doubleValue = gradOpacity[1]
            self.curveGradFinOpacity.doubleValue = gradOpacity[2]

            self.curveXLabel.doubleValue = self.curveX.doubleValue
            self.curveYLabel.doubleValue = self.curveY.doubleValue
            self.curveWidLabel.doubleValue = self.curveWid.doubleValue
            self.curveHeiLabel.doubleValue =  self.curveHei.doubleValue
            self.curveRotateLabel.doubleValue =  self.curveRotate.doubleValue
            self.curveOpacityStrokeLabel.doubleValue = opacity[0]
            self.curveOpacityFillLabel.doubleValue =  opacity[1]
            self.curveWidthLabel.doubleValue = self.curveWidth.doubleValue
            self.curveBlurLabel.doubleValue = self.curveBlur.doubleValue

            self.curveStrokeLabel.stringValue = curve.strokeColor.hexStr
            self.curveFillLabel.stringValue = curve.fillColor.hexStr
            self.curveShadowLabel.stringValue = curve.shadowColor.hexStr
            self.curveShadowRadiusLabel.doubleValue = round(shadow[0])
            self.curveShadowOpacityLabel.doubleValue = shadow[1]
            self.curveShadowOffsetXLabel.doubleValue = shadow[2]
            self.curveShadowOffsetYLabel.doubleValue = shadow[3]

            self.curveGradStLab.stringValue = curve.gradientColor[0].hexStr
            self.curveGradMidLab.stringValue = curve.gradientColor[1].hexStr
            self.curveGradFinLab.stringValue = curve.gradientColor[2].hexStr

            self.curveGradStOpacityLab.doubleValue = gradOpacity[0]
            self.curveGradMidOpacityLab.doubleValue = gradOpacity[1]
            self.curveGradFinOpacityLab.doubleValue = gradOpacity[2]

            self.curveCap.selectedSegment = curve.cap
            self.curveJoin.selectedSegment = curve.join

            for (index, item) in curveDashGap.subviews.enumerated() {
                if let slider = item as? NSSlider {
                    slider.doubleValue = Double(truncating: curve.dash[index])
                }
            }
        } else {
            self.curveX!.doubleValue = Double(view.sketchBorder.bounds.minX)
            self.curveY!.doubleValue = Double(view.sketchBorder.bounds.minY)
            self.curveWid!.doubleValue = Double(view.sketchBorder.bounds.width)
            self.curveHei!.doubleValue = Double(view.sketchBorder.bounds.height)
            self.curveXLabel!.doubleValue = self.curveX!.doubleValue
            self.curveYLabel!.doubleValue = self.curveY!.doubleValue
            self.curveWidLabel!.doubleValue = self.curveWid!.doubleValue
            self.curveHeiLabel!.doubleValue = self.curveHei!.doubleValue
        }
    }

//    MARK: Zoom Actions
    @IBAction func zoomOrigin(_ sender: NSPanGestureRecognizer) {
        let view = sketchView!
        let vel = sender.velocity(in: sketchView)
        let deltaX = vel.x / setup.reduceZoom
        let deltaY = vel.y / setup.reduceZoom
        view.setZoomOrigin(deltaX: deltaX, deltaY: deltaY)
    }

    @IBAction func zoomGesture(_ sender: NSMagnificationGestureRecognizer) {
        let view = sketchView!
        let zoomed = Double(view.zoomed)
        let mag = Double(sender.magnification / setup.reduceZoom)
        var zoom = (zoomed + mag) * 100

        if zoom < setup.minZoom * 2 || zoom > setup.maxZoom {
            zoom = zoomed * 100
        }
        view.zoomSketch(value: zoom)
        zoomSketch.doubleValue = zoom
        zoomDefaultSketch.title = String(Int(zoom))
    }

    @IBAction func zoomSketch(_ sender: NSSlider) {
        sketchView!.zoomSketch(value: sender.doubleValue)
        zoomDefaultSketch.title = String(sender.intValue)
    }

    @IBAction func zoomDefaultSketch(_ sender: NSPopUpButton) {
        let view = sketchView!
        if let value = Double(sender.itemTitle(
            at: sender.indexOfSelectedItem)) {
            view.zoomOrigin = CGPoint(x: view.frame.midX,
                                      y: view.frame.midY)
            sender.title = sender.itemTitle(at: sender.indexOfSelectedItem)
            zoomSketch.doubleValue = value
            view.zoomSketch(value: value)
        }
    }

//    MARK: Tools Actions
    @IBAction func setTool(_ sender: NSButton) {
        sketchView!.setTool(tag: sender.tag)
    }

    func getTagValue(sender: Any) -> (tag: Int, value: Double) {
        var tag: Int = 0
        var doubleValue: Double = 0
        if let sl = sender as? NSSlider {
            tag = sl.tag
            doubleValue = sl.doubleValue
        }
        if let tf = sender as? NSTextField {
            tag = tf.tag
            doubleValue = tf.doubleValue
        }
        return (tag: tag, value: doubleValue)
    }

    func restoreControlFrame(view: SketchPad) {
        if NSEvent.pressedMouseButtons == 0 {
            if let curve = view.selectedCurve {
                view.createControls(curve: curve)
            }
        }
    }

    @IBAction func alignLeftRightCurve(_ sender: NSSegmentedControl) {
        sketchView!.alignLeftRightCurve(value: sender.indexOfSelectedItem)
    }
    @IBAction func alignUpDownCurve(_ sender: NSSegmentedControl) {
        sketchView!.alignUpDownCurve(value: sender.indexOfSelectedItem)
    }

    @IBAction func moveCurve(_ sender: Any) {
        let view = sketchView!
        let val = self.getTagValue(sender: sender)
        if val.tag == 0 {
            self.curveXLabel.doubleValue = val.value
        } else {
            self.curveYLabel.doubleValue = val.value
        }
        view.moveCurve(tag: val.tag, value: val.value)
        self.restoreControlFrame(view: view)
    }

    @IBAction func resizeCurve(_ sender: Any) {
        let view = sketchView!
        let val = self.getTagValue(sender: sender)
        let lim = val.value < 0 ? setup.minResize : val.value
        if val.tag == 0 {
            self.curveWidLabel.doubleValue = lim
        } else {
            self.curveHeiLabel.doubleValue = lim
        }
        view.resizeCurve(tag: val.tag, value: lim)
        self.restoreControlFrame(view: view)
    }

    @IBAction func rotateCurve(_ sender: Any) {
        let view = sketchView!
        let val = self.getTagValue(sender: sender)
        let minR = setup.minRotate
        let maxR = setup.maxRotate
       let lim = val.value > maxR ? maxR : val.value < minR ? minR : val.value

        self.curveRotateLabel.doubleValue = lim

        view.rotateCurve(angle: lim)
        self.restoreControlFrame(view: view)
    }

    @IBAction func widthCurve(_ sender: Any) {
        let view = sketchView!
        let val = self.getTagValue(sender: sender)
        let lim = val.value < 0 ? 0 : val.value
        self.curveWidthLabel.doubleValue = lim
        view.borderWidthCurve(value: lim)
        self.restoreControlFrame(view: view)
    }

    @IBAction func capCurve(_ sender: NSSegmentedControl) {
        sketchView!.capCurve(value: sender.indexOfSelectedItem)
    }

    @IBAction func joinCurve(_ sender: NSSegmentedControl) {
        sketchView!.joinCurve(value: sender.indexOfSelectedItem)
    }

    @IBAction func dashCurve(_ sender: Any) {
        let view = sketchView!
        let val = self.getTagValue(sender: sender)
        let lim = val.value < 0 ? 0 : val.value
        switch val.tag {
        case 0:
            self.curveDash1Label.doubleValue = lim
        case 1:
            self.curveGap1Label.doubleValue = lim
        case 2:
            self.curveDash2Label.doubleValue = lim
        case 3:
            self.curveGap2Label.doubleValue = lim
        default:
            break
        }
        view.dashCurve(tag: val.tag, value: lim)
        self.restoreControlFrame(view: view)
    }

    @IBAction func blurCurve(_ sender: Any) {
        let view = sketchView!
        let val = self.getTagValue(sender: sender)
        let lim = val.value < 0 ? 0 : val.value
        self.curveBlurLabel.doubleValue = lim
        view.blurCurve(value: lim)
        self.restoreControlFrame(view: view)
    }

//    MARK: TextTool action
    @IBAction func glyphsCurve(_ sender: NSTextField) {
        sketchView!.glyphsCurve(value: sender.stringValue,
                                sharedFont: textUI!.sharedFont)
    }

//    MARK: ColorPanel actions
    @IBAction func openColorPanel(_ sender: ColorBox) {
        let tag = sender.tag
        switch tag {
        case 0:
            self.colorPanel = curveStrokeColorPanel
        case 1:
            self.colorPanel = curveFillColorPanel
        case 2:
            self.colorPanel = curveShadowColorPanel
        case 3:
            self.colorPanel = curveGradientStartPanel
        case 4:
            self.colorPanel = curveGradientMiddlePanel
        case 5:
            self.colorPanel = curveGradientFinalPanel
        default:
            break
        }

        if sender.state == .off {
            self.colorPanel?.closeSharedColorPanel()
        } else {
            let abMin = CGPoint(x: actionUI.frame.minX,
                                y: actionUI.frame.minY)
            let deltaX = abMin.x + colorUI.frame.width
            let deltaY = (abMin.y + colorUI.frame.minY)
            let rect = NSRect(x: deltaX + (window?.frame.minX)!,
                              y: deltaY + (window?.frame.minY)!,
                              width: colorUI.frame.width,
                              height: colorUI.frame.height)

            self.colorPanel?.createSharedColorPanel(
                frame: rect, sender: sender)
            self.window.makeKeyAndOrderFront(self)
        }
    }

//    MARK: Opacity actions
    @IBAction func opacityCurve(_ sender: Any) {
        let view = sketchView!
        let val = self.getTagValue(sender: sender)

        let lim = val.value > 1 ? 1 : val.value < 0 ? 0 : val.value
        if val.tag==0 {
            self.curveOpacityStrokeLabel.doubleValue = lim
        } else if val.tag==1 {
            self.curveOpacityFillLabel.doubleValue = lim
        }
        view.opacityCurve(tag: val.tag, value: lim)
        self.restoreControlFrame(view: view)
    }

    @IBAction func setShadow(_ sender: Any) {
        let view = sketchView!
        let val = self.getTagValue(sender: sender)
        var lim = val.value
        switch val.tag {
        case 0:
            lim = lim < 0 ? 0 : lim
            self.curveShadowRadiusLabel.doubleValue = lim
        case 1:
            lim = lim > 1 ? 1 : lim < 0 ? 0 : lim
            self.curveShadowOpacityLabel.doubleValue = lim
        case 2:
            self.curveShadowOffsetXLabel.doubleValue = lim
        case 3:
            self.curveShadowOffsetYLabel.doubleValue = lim
        default: break
        }
        view.shadowCurve(tag: val.tag, value: lim)
        self.restoreControlFrame(view: view)
    }

    @IBAction func opacityGradientCurve(_ sender: Any) {
        let view = sketchView!
        let val = self.getTagValue(sender: sender)

        let lim = val.value > 1 ? 1 : val.value < 0 ? 0 : val.value
        if val.tag == 0 {
            curveGradStOpacityLab.doubleValue = lim
        } else if val.tag == 1 {
            curveGradMidOpacityLab.doubleValue = lim
        } else if val.tag == 2 {
            curveGradFinOpacityLab.doubleValue = lim
        }
        view.opacityGradientCurve(tag: val.tag, value: lim)
        self.restoreControlFrame(view: view)
    }

//    MARK: Buttons actions
    @IBAction func sendCurve(_ sender: NSButton) {
        sketchView!.sendCurve(name: sender.alternateTitle)
    }

    @IBAction func flipCurve(_ sender: NSButton) {
        sketchView!.flipCurve(name: sender.alternateTitle)
    }

    @IBAction func cloneCurve(_ sender: NSButton) {
        sketchView!.cloneCurve()
    }

    @IBAction func editCurve(_ sender: NSButton) {
        sketchView!.editCurve(sender: sender)
    }

    @IBAction func lockCurve(_ sender: NSButton) {
        sketchView!.lockCurve(sender: sender)
    }

    @IBAction func groupCurve(_ sender: NSButton) {
        sketchView!.groupCurve()
    }

//    MARK: Menu actions
    @IBAction func copy(_ sender: NSMenuItem) {
        sketchView!.copyCurve()
    }

    @IBAction func paste(_ sender: NSMenuItem) {
        let view = sketchView!
        let pos = NSEvent.mouseLocation
        let deltaX = (pos.x - (window?.frame.minX)!)/view.zoomed
        let deltaY =  (pos.y - (window?.frame.minY)!)/view.zoomed
        sketchView!.pasteCurve(to: CGPoint(
            x: deltaX + view.bounds.minX ,
            y: deltaY + view.bounds.minY))
    }

    @IBAction func cut(_ sender: NSMenuItem) {
        sketchView!.copyCurve()
        sketchView!.deleteCurve()
    }

    @IBAction func undo(_ sender: NSMenuItem) {
        print("undo")
//        SketchView!.undoCurve()
    }

    @IBAction func redo(_ sender: NSMenuItem) {
        print("redo")
        //        SketchView!.undoCurve()
    }

    @IBAction func delete(_ sender: NSMenuItem) {
        sketchView!.deleteCurve()
    }

    func showFileName() {
        let fileName = sketchView!.sketchName ?? setup.filename
        self.window!.title = fileName
    }

    func openPng(filePath: URL) {
        let view = sketchView!
        let image = NSImage(contentsOf: filePath)
        if let wid = image?.size.width, let hei = image?.size.height {

            let topLeft = CGPoint(x: view.frame.midX - wid/2,
                                  y: view.frame.midY - hei/2)
            let bottomRight = CGPoint(x: view.frame.midX + wid/2,
                                      y: view.frame.midY + hei/2)
            view.createRectangle(topLeft: topLeft,
                                 bottomRight: bottomRight)
            if let curve = view.selectedCurve {
                view.clearControls(curve: curve, updatePoints: {})
            }
            view.addCurve()
            if let curve = view.selectedCurve {
                curve.alpha = [CGFloat](repeating: 0, count: 2)

                curve.image.contents = image
                curve.image.bounds = curve.path.bounds
                curve.image.position = CGPoint(
                    x: curve.path.bounds.midX,
                    y: curve.path.bounds.midY)
                view.createControls(curve: curve)
                self.updateSliders()
            }
        }

    }

    func openSvg(filePath: URL) {
        print("open svg")
    }

    @IBAction func newDocument(_ sender: NSMenuItem) {
        self.saveDocument(sender)
    }

    func clearSketch() {
        let view = sketchView!
        view.zoomOrigin = CGPoint(x: view.frame.midX,
                                  y: view.frame.midY)
        view.zoomSketch(value: 100)
        if let curve = view.selectedCurve {
            curve.clearControlFrame()
            curve.clearPoints()
        }
        view.editedPath.removeAllPoints()
        view.editLayer.removeFromSuperlayer()
        frameUI.hide()
    }

    func newSketch() {
        let view = sketchView!
        self.clearSketch()
        view.selectedCurve = nil
        view.sketchName = nil
        view.sketchExt = nil

        for curve in view.curves {
            curve.delete()
        }
        view.curves.removeAll()

        view.moveCurve(tag: 0, value: 0)
        view.moveCurve(tag: 1, value: 0)
        view.resizeCurve(tag: 0, value: setup.screenWidth)
        view.resizeCurve(tag: 1, value: setup.screenHeight)

        view.frameUI.isOn(on: -1)
        textUI.hide()
        self.updateSliders()
    }

    @IBAction func openDocument(_ sender: NSMenuItem) {
        self.colorPanel?.closeSharedColorPanel()
        let openPanel = NSOpenPanel()
        openPanel.setupPanel()
        openPanel.beginSheetModal(
            for: self.window!,
            completionHandler: {(result) -> Void in
                if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                    if openPanel.urls.count>0 {
                        let filePath = openPanel.urls[0]
                        let ext = filePath.pathExtension
                        if ext == "png" {
                            self.openPng(filePath: filePath)
                        } else if ext == "svg" {
                            self.openSvg(filePath: filePath)
                        }
                    }
                } else {
                    openPanel.close()
                }
        })
    }

    func saveSketch(url: URL, name: String, ext: String) {
        let view = sketchView!

        view.sketchWidth = 0
        view.sketchColor = NSColor.clear
        let zoomed = view.zoomed
        let zoomOrigin = view.zoomOrigin

        self.clearSketch()

        let filePath = url.appendingPathComponent(name + "." + ext)

        if ext == "png" {
            if let image = view.imageData() {
                do {
                    try image.write(to: filePath, options: .atomic)

                } catch {
                    print("error save \(ext)")
                }
            }
        } else if ext == "svg" {
            print("save svg")
        }

        if let curve = view.selectedCurve {
            view.createControls(curve: curve)
            if curve.edit {
                curve.createPoints()
            }
        }
        view.sketchWidth = setup.lineWidth
        view.sketchColor = setup.guiColor
        view.zoomOrigin = zoomOrigin
        view.zoomSketch(value: Double(zoomed * 100))
    }

    @objc func setFileType(_ sender: NSPopUpButton) {
        let index = sender.indexOfSelectedItem
        sender.setTitle(sender.itemTitle(at: index))
        if let savePanel = savePanel {
            var types = savePanel.allowedFileTypes ?? []
            let typeIndex = types.firstIndex(of: sender.title.lowercased())
            if let ind = typeIndex {
                if ind>0 {
                    types.swapAt(0, ind)
                } else {
                    savePanel.allowedFileTypes = []
                }
                savePanel.allowedFileTypes = types
            }
        }
    }

    @IBAction func saveDocument(_ sender: NSMenuItem) {
        let view = sketchView!
        if let name = view.sketchName,
            let dir = view.sketchDir,
            let ext = view.sketchExt {
            self.saveSketch(url: dir, name: name, ext: ext)
            if sender.title == "New" {
                self.newSketch()
                self.showFileName()
            }
        } else {
            self.saveDocumentAs(sender)
        }
    }

    @IBAction func saveDocumentAs(_ sender: NSMenuItem) {
        let view = sketchView!
        self.colorPanel?.closeSharedColorPanel()

        savePanel = NSSavePanel()
        if let savePanel = savePanel {

            let popup = savePanel.setupPanel(fileName: setup.filename)
            popup.target = self
            popup.action = #selector(self.setFileType)

            savePanel.beginSheetModal(
                for: self.window!,
                completionHandler: {(result) in
                    let ok = NSApplication.ModalResponse.OK.rawValue
                    if result.rawValue == ok {
                        let name = savePanel.nameFieldStringValue
                        let indexDot = name.firstIndex(of: ".")
                        var trimName = name
                        if let dot = indexDot {
                            trimName  = String(trimName.prefix(upTo: dot))
                        }
                        if trimName != setup.filename {
                            view.sketchName = trimName
                        } else {
                            view.sketchName = nil
                        }
                        if let url = savePanel.directoryURL {
                            view.sketchDir = url
                            let index = popup.indexOfSelectedItem
                            let ext = popup.itemTitle(at: index).lowercased()
                            view.sketchExt = ext
                            self.saveSketch(url: url, name: trimName, ext: ext)
                        }
                    } else {
                        savePanel.close()
                    }
                    if sender.title == "New" {
                        self.newSketch()
                    }
                    self.showFileName()
            })
        }
    }

    @IBAction func performClose(_ sender: NSMenuItem) {
        print("close")
    }

    @IBAction func terminate(_ sender: NSMenuItem) {
        print("quit")
    }
}
