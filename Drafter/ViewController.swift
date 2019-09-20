//
//  ViewController.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 8/8/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    var Window: NSWindow?
    @IBOutlet weak var ToolBox: NSStackView!
    @IBOutlet weak var SketchView: SketchPad!
    @IBOutlet weak var FrameButtons: NSStackView!
    @IBOutlet weak var ActionBox: NSStackView!

    @IBOutlet weak var ZoomSketch: NSSlider!
    @IBOutlet weak var ZoomDefaultSketch: NSPopUpButton!

    @IBOutlet weak var CurveX: NSSlider!
    @IBOutlet weak var CurveY: NSSlider!
    @IBOutlet weak var CurveWid: NSSlider!
    @IBOutlet weak var CurveHei: NSSlider!
    @IBOutlet weak var CurveRotate: NSSlider!
    @IBOutlet weak var CurveOpacityStroke: NSSlider!
    @IBOutlet weak var CurveOpacityFill: NSSlider!
    @IBOutlet weak var CurveWidth: NSSlider!
    @IBOutlet weak var CurveBlur: NSSlider!
    @IBOutlet weak var CurveXLabel: NSTextField!
    @IBOutlet weak var CurveYLabel: NSTextField!
    @IBOutlet weak var CurveWidLabel: NSTextField!
    @IBOutlet weak var CurveHeiLabel: NSTextField!
    @IBOutlet weak var CurveRotateLabel: NSTextField!
    @IBOutlet weak var CurveWidthLabel: NSTextField!
    @IBOutlet weak var CurveOpacityStrokeLabel: NSTextField!
    @IBOutlet weak var CurveOpacityFillLabel: NSTextField!
    @IBOutlet weak var CurveBlurLabel: NSTextField!

    @IBOutlet weak var CurveColorBox: NSBox!
    @IBOutlet weak var CurveColors: NSStackView!
    @IBOutlet weak var CurveStrokeColorPanel: ColorPanel!
    @IBOutlet weak var CurveFillColorPanel: ColorPanel!
    @IBOutlet weak var CurveStrokeColor: NSBox!
    @IBOutlet weak var CurveFillColor: NSBox!
    @IBOutlet weak var CurveStrokeLabel: NSTextField!
    @IBOutlet weak var CurveFillLabel: NSTextField!

    @IBOutlet weak var CurveGradientStartPanel: ColorPanel!
    @IBOutlet weak var CurveGradientMiddlePanel: ColorPanel!
    @IBOutlet weak var CurveGradientFinalPanel: ColorPanel!
    @IBOutlet weak var CurveGradientStartColor: NSBox!
    @IBOutlet weak var CurveGradientMiddleColor: NSBox!
    @IBOutlet weak var CurveGradientFinalColor: NSBox!
    @IBOutlet weak var CurveGradientStartLabel: NSTextField!
    @IBOutlet weak var CurveGradientMiddleLabel: NSTextField!
    @IBOutlet weak var CurveGradientFinalLabel: NSTextField!

    @IBOutlet weak var CurveGradientStartOpacity: NSSlider!
    @IBOutlet weak var CurveGradientStartOpacityLabel: NSTextField!
    @IBOutlet weak var CurveGradientMiddleOpacity: NSSlider!
    @IBOutlet weak var CurveGradientMiddleOpacityLabel: NSTextField!
    @IBOutlet weak var CurveGradientFinalOpacity: NSSlider!
    @IBOutlet weak var CurveGradientFinalOpacityLabel: NSTextField!

    @IBOutlet weak var CurveShadowColorPanel: ColorPanel!
    @IBOutlet weak var CurveShadowColor: NSBox!
    @IBOutlet weak var CurveShadowLabel: NSTextField!
    @IBOutlet weak var CurveShadowOpacity: NSSlider!
    @IBOutlet weak var CurveShadowOpacityLabel: NSTextField!
    @IBOutlet weak var CurveShadowRadius: NSSlider!
    @IBOutlet weak var CurveShadowRadiusLabel: NSTextField!
    @IBOutlet weak var CurveShadowOffsetX: NSSlider!
    @IBOutlet weak var CurveShadowOffsetY: NSSlider!

    @IBOutlet weak var CurveCap: NSSegmentedControl!
    @IBOutlet weak var CurveJoin: NSSegmentedControl!
    @IBOutlet weak var CurveDashGap: NSStackView!

    @IBOutlet weak var CurveTextTool: NSStackView!
    @IBOutlet weak var CurveTextField: NSTextField!

    var textFields: [NSTextField] = []

    var SharedColorPanel: NSColorPanel?
    var SharedFontPanel: NSFontPanel?

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // mouse
        self.view.window?.acceptsMouseMovedEvents = true
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        Window = self.view.window!

//      MARK: Set
        ZoomSketch.minValue = set.minZoom
        ZoomSketch.maxValue = set.maxZoom
        ZoomDefaultSketch.removeAllItems()
        var zoom: [String] = []
        for step in stride(from: Int(set.minZoom),
                           to: Int(set.maxZoom) + 1,
                           by: Int(set.minZoom)) {
            zoom.append(String(step))
        }
        ZoomDefaultSketch.addItems(withTitles: zoom)
        let index100 = ZoomDefaultSketch.indexOfItem(withTitle: "100")
        ZoomDefaultSketch.select(ZoomDefaultSketch.item(at: index100))
        ZoomDefaultSketch.setTitle("100")

        CurveX.maxValue = set.maxScreenWidth
        CurveY.maxValue = set.maxScreenHeight
        CurveWid.maxValue = set.maxScreenWidth
        CurveHei.maxValue = set.maxScreenHeight
        CurveWid.doubleValue = set.screenWidth
        CurveHei.doubleValue = set.screenHeight
        CurveRotate.minValue = set.minRotate
        CurveRotate.maxValue = set.maxRotate
        CurveWidth.doubleValue = Double(set.lineWidth)
        CurveWidth.maxValue = Double(set.maxLineWidth)
        CurveOpacityStroke.maxValue = 1
        CurveOpacityStroke.doubleValue =  CurveOpacityStroke.maxValue
        CurveOpacityFill.maxValue = 1
        CurveOpacityFill.doubleValue =  CurveOpacityFill.maxValue
        CurveBlur.maxValue = set.maxBlur

        CurveWidLabel.doubleValue = set.screenWidth
        CurveHeiLabel.doubleValue = set.screenHeight
        CurveWidthLabel.doubleValue = Double(set.lineWidth)
        CurveOpacityStrokeLabel.doubleValue =  CurveOpacityStroke.doubleValue
        CurveOpacityFillLabel.doubleValue =  CurveOpacityFill.doubleValue

        CurveStrokeColor.borderColor = set.guiColor
        CurveStrokeColor.fillColor = set.strokeColor
        CurveFillColor.borderColor = set.guiColor
        CurveFillColor.fillColor = set.fillColor

        CurveStrokeLabel.stringValue = set.strokeColor.hexString
        CurveFillLabel.stringValue = set.fillColor.hexString

        CurveShadowColor.borderColor = set.guiColor
        CurveShadowColor.fillColor = set.shadowColor
        CurveShadowLabel.stringValue = set.shadowColor.hexString

        let rad = Double(set.shadow[0])
        let opa = Double(set.shadow[1])
        let offX = Double(set.shadow[2])
        let offY = Double(set.shadow[3])
        CurveShadowRadius.maxValue = set.maxShadowRadius
        CurveShadowOpacity.maxValue = 1

        CurveShadowOffsetX.minValue = -set.screenWidth
        CurveShadowOffsetY.minValue = -set.screenHeight
        CurveShadowOffsetX.maxValue = set.screenWidth
        CurveShadowOffsetY.maxValue = set.screenHeight

        CurveShadowRadius.doubleValue = rad
        CurveShadowOpacity.doubleValue = opa
        CurveShadowOffsetX.doubleValue = offX
        CurveShadowOffsetY.doubleValue = offY

        CurveShadowRadiusLabel.doubleValue = rad
        CurveShadowOpacityLabel.doubleValue = opa

        CurveGradientStartColor.borderColor = set.guiColor
        CurveGradientStartColor.fillColor = set.gradientColor[0]
        CurveGradientMiddleColor.borderColor = set.guiColor
        CurveGradientMiddleColor.fillColor = set.gradientColor[1]
        CurveGradientFinalColor.borderColor = set.guiColor
        CurveGradientFinalColor.fillColor = set.gradientColor[2]
        CurveGradientStartOpacity.doubleValue = 0
        CurveGradientStartOpacity.maxValue = 1
        CurveGradientStartOpacityLabel.doubleValue =  CurveGradientStartOpacity.doubleValue
        CurveGradientMiddleOpacity.doubleValue = 0
        CurveGradientMiddleOpacity.maxValue = 1
        CurveGradientMiddleOpacityLabel.doubleValue =  CurveGradientMiddleOpacity.doubleValue
        CurveGradientFinalOpacity.doubleValue = 0
        CurveGradientFinalOpacity.maxValue = 1
        CurveGradientFinalOpacityLabel.doubleValue =  CurveGradientFinalOpacity.doubleValue

        CurveGradientStartLabel.stringValue = set.gradientColor[0].hexString
        CurveGradientMiddleLabel.stringValue = set.gradientColor[1].hexString
        CurveGradientFinalLabel.stringValue = set.gradientColor[2].hexString

//      MARK: SketchView ref
        SketchView.parent = self
        SketchView.ToolBox = ToolBox
        SketchView.FrameButtons = FrameButtons

        SketchView.CurveRotate = CurveRotate
        SketchView.CurveOpacityStroke = CurveOpacityStroke
        SketchView.CurveOpacityFill = CurveOpacityFill
        SketchView.CurveWidth = CurveWidth
        SketchView.CurveBlur = CurveBlur

        SketchView.CurveColors = CurveColors

        SketchView.CurveStrokeColor = CurveStrokeColor
        SketchView.CurveFillColor = CurveFillColor
        SketchView.CurveShadowColor = CurveShadowColor
        SketchView.CurveGradientStartColor = CurveGradientStartColor
        SketchView.CurveGradientMiddleColor = CurveGradientMiddleColor
        SketchView.CurveGradientFinalColor = CurveGradientFinalColor

        SketchView.CurveGradientStartOpacity = CurveGradientStartOpacity
        SketchView.CurveGradientMiddleOpacity = CurveGradientMiddleOpacity
        SketchView.CurveGradientFinalOpacity = CurveGradientFinalOpacity

        SketchView.CurveShadowRadius = CurveShadowRadius
        SketchView.CurveShadowOpacity = CurveShadowOpacity

        SketchView.CurveShadowOffsetX = CurveShadowOffsetX
        SketchView.CurveShadowOffsetY = CurveShadowOffsetY

        SketchView.CurveCap = CurveCap
        SketchView.CurveJoin = CurveJoin
        SketchView.CurveDashGap = CurveDashGap

        SketchView.CurveTextTool = CurveTextTool

        // for precision position create and remove panel
        self.createSharedColorPanel()
        self.closeSharedColorPanel()

        // abort text fields
        self.textFields = [
            CurveStrokeLabel,CurveFillLabel,CurveShadowLabel,
            CurveShadowRadiusLabel, CurveShadowOpacityLabel,
            CurveXLabel,CurveYLabel,
            CurveWidLabel,CurveHeiLabel,
            CurveRotateLabel,
            CurveOpacityStrokeLabel,CurveOpacityFillLabel,
            CurveWidthLabel,CurveBlurLabel,
            CurveGradientStartLabel,
            CurveGradientMiddleLabel,
            CurveGradientFinalLabel,
            CurveGradientStartOpacityLabel,
            CurveGradientMiddleOpacityLabel,
            CurveGradientFinalOpacityLabel,
            CurveTextField
        ]

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(abortTextFields), name: Notification.Name("abortTextFields"), object: nil)
        nc.addObserver(self, selector: #selector(updateSliders), name: Notification.Name("updateSliders"), object: nil)

        nc.post(name: Notification.Name("abortTextFields"), object: nil)
    }

//    MARK: Obserevrs actions
    @objc func abortTextFields() {
        for field in self.textFields {
            field.abortEditing()
        }
    }

    @objc func updateSliders() {
        let View = SketchView!
        if let curve = View.selectedCurve {
            let x = Double(curve.path.bounds.midX)
            let y = Double(curve.path.bounds.midY)
            let wid = Double(curve.path.bounds.width)
            let hei = Double(curve.path.bounds.height)
            let angle = Double(curve.angle)
            let opacity = [Double(curve.alpha[0]),Double(curve.alpha[1])]
            let width = Double(curve.lineWidth)
            let blur = Double(curve.blur)

            let strokeColor = curve.strokeColor
            let fillColor = curve.fillColor
            let shadowColor = curve.shadowColor
            let shadow = curve.shadow

            let rad = Double(shadow[0])
            let opa = Double(shadow[1])
            let offx = Double(shadow[2])
            let offy = Double(shadow[3])

            let gradient = curve.gradientColor

            let grad0 = Double(curve.gradientOpacity[0])
            let grad1 = Double(curve.gradientOpacity[1])
            let grad2 = Double(curve.gradientOpacity[2])

            self.CurveX.doubleValue = x
            self.CurveY.doubleValue = y
            self.CurveWid.doubleValue = wid
            self.CurveHei.doubleValue = hei
            self.CurveRotate.doubleValue = angle
            self.CurveOpacityStroke.doubleValue = opacity[0]
            self.CurveOpacityFill.doubleValue = opacity[1]
            self.CurveWidth!.doubleValue = width
            self.CurveBlur!.doubleValue = blur

            self.CurveStrokeColor.fillColor = strokeColor
            self.CurveFillColor.fillColor = fillColor
            self.CurveShadowColor.fillColor = shadowColor

            self.CurveShadowRadius.doubleValue = rad
            self.CurveShadowOpacity.doubleValue = opa
            self.CurveShadowOffsetX.doubleValue = offx
            self.CurveShadowOffsetY.doubleValue = offy

            self.CurveGradientStartColor.fillColor = gradient[0]
            self.CurveGradientMiddleColor.fillColor = gradient[1]
            self.CurveGradientFinalColor.fillColor = gradient[2]

            self.CurveGradientStartOpacity.doubleValue = grad0
            self.CurveGradientMiddleOpacity.doubleValue =  grad1
            self.CurveGradientFinalOpacity.doubleValue =  grad2

            self.CurveXLabel.doubleValue = round(x*10)/10
            self.CurveYLabel.doubleValue =  round(y*10)/10
            self.CurveWidLabel.doubleValue = round(wid*10)/10
            self.CurveHeiLabel.doubleValue =  round(hei*10)/10
            self.CurveRotateLabel.doubleValue =  round(angle*100)/100
            self.CurveOpacityStrokeLabel.doubleValue = round(opacity[0]*100)/100
            self.CurveOpacityFillLabel.doubleValue =  round(opacity[1]*100)/100
            self.CurveWidthLabel.doubleValue = round(width*10)/10
            self.CurveBlurLabel.doubleValue = round(blur*10)/10

            self.CurveStrokeLabel.stringValue = strokeColor.hexString
            self.CurveFillLabel.stringValue = fillColor.hexString
            self.CurveShadowLabel.stringValue = shadowColor.hexString
            self.CurveShadowRadiusLabel.doubleValue = round(rad)
            self.CurveShadowOpacityLabel.doubleValue = round(opa*100)/100

            self.CurveGradientStartLabel.stringValue = gradient[0].hexString
            self.CurveGradientMiddleLabel.stringValue = gradient[1].hexString
            self.CurveGradientFinalLabel.stringValue = gradient[2].hexString

            self.CurveGradientStartOpacityLabel.doubleValue = round(grad0*100)/100
            self.CurveGradientMiddleOpacityLabel.doubleValue = round(grad1*100)/100
            self.CurveGradientFinalOpacityLabel.doubleValue = round(grad2*100)/100

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
            let x = round(Double(View.sketchBorder.bounds.minX)*10)/10
            let y = round(Double(View.sketchBorder.bounds.minY)*10)/10
            let wid = round(Double(View.sketchBorder.bounds.width)*10)/10
            let hei = round(Double(View.sketchBorder.bounds.height)*10)/10
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



//    MARK: Color panel
    func createSharedColorPanel(sender: ColorBox? = nil) {
        let abMin = CGPoint(x: ActionBox.frame.minX,
                            y: ActionBox.frame.minY)
        let deltaX = abMin.x + CurveColorBox.frame.width
        let deltaY = (abMin.y + CurveColorBox.frame.minY)
        let rect = NSRect(x: deltaX + (Window?.frame.minX)!,
                          y: deltaY + (Window?.frame.minY)!,
                          width: CurveColorBox.frame.width,
                          height: CurveColorBox.frame.height)

        NSColorPanel.setPickerMask(NSColorPanel.Options.wheelModeMask)
        SharedColorPanel = NSColorPanel.shared
        SharedColorPanel?.setFrame(rect, display: true)
        SharedColorPanel?.styleMask = .closable
        SharedColorPanel?.backgroundColor = set.guiColor
        SharedColorPanel?.makeKeyAndOrderFront(self)
        SharedColorPanel?.setTarget(self)
        SharedColorPanel?.isContinuous = true
        SharedColorPanel?.mode = NSColorPanel.Mode.wheel

        if sender?.alternateTitle=="stroke" {
            SharedColorPanel?.setAction(
                #selector(self.setStrokeColor))

        } else if sender?.alternateTitle=="fill" {
            SharedColorPanel?.setAction(
                #selector(self.setFillColor))
        } else if sender?.alternateTitle=="shadow" {
            SharedColorPanel?.setAction(
                #selector(self.setShadowColor))
        } else if sender?.alternateTitle=="gradientStart" {
            SharedColorPanel?.setAction(
                #selector(self.setGradientStartColor))
        } else if sender?.alternateTitle=="gradientMiddle" {
            SharedColorPanel?.setAction(
                #selector(self.setGradientMiddleColor))
        } else if sender?.alternateTitle=="gradientFinal" {
            SharedColorPanel?.setAction(
                #selector(self.setGradientFinalColor))
        }
        SketchView!.ColorPanel = SharedColorPanel
    }

    func closeSharedColorPanel() {
        if let panel = self.SharedColorPanel {
            panel.close()
            self.SharedColorPanel = nil
            SketchView!.ColorPanel = nil
        }
    }
//     MARK: Font panel
    func createSharedFontPanel() {
        SharedFontPanel = NSFontPanel.shared
        let height = SharedFontPanel?.frame.height ?? 0
        SharedFontPanel?.setFrameOrigin(NSPoint(
            x: CurveTextTool.frame.minX+(Window?.frame.minX)!,
            y: CurveTextTool.frame.minY+(Window?.frame.minY)!-height))
        SharedFontPanel?.makeKeyAndOrderFront(self)
    }

    func closeSharedFontPanel() {
        if let panel = self.SharedFontPanel {
            panel.close()
            self.SharedFontPanel = nil
        }
    }

//    MARK: Zoom Actions
    @IBAction func zoomOrigin(_ sender: NSPanGestureRecognizer) {
        let View = SketchView!
        let vel = sender.velocity(in: SketchView)
        let deltax = vel.x / set.reduceZoom
        let deltay = vel.y / set.reduceZoom
        View.setZoomOrigin(deltaX: deltax, deltaY: deltay)
    }

    @IBAction func zoomGesture(_ sender: NSMagnificationGestureRecognizer) {
        let View = SketchView!
        let zoomed = Double(View.zoomed)
        var mag = (zoomed + Double(sender.magnification / set.reduceZoom)) * 100

        if mag < set.minZoom || mag > set.maxZoom {
            mag = zoomed * 100
        }
        View.zoomSketch(value: mag)
        ZoomSketch.doubleValue = mag
        ZoomDefaultSketch.title = String(Int(mag))
    }

    @IBAction func zoomSketch(_ sender: NSSlider) {
        let View = SketchView!
        if let event = NSApplication.shared.currentEvent {
            if event.type == NSEvent.EventType.leftMouseDown {
                let wid = View.self.bounds.width
                let hei = View.self.bounds.height
                View.zoomOrigin = CGPoint(x: View.self.bounds.minX+wid/2,
                                          y: View.self.bounds.minY+hei/2)
            }
        }
        View.zoomSketch(value: sender.doubleValue)
        ZoomDefaultSketch.title = String(sender.intValue)
    }

    @IBAction func zoomDefaultSketch(_ sender: NSPopUpButton) {
        let View = SketchView!
        if let value = Double(sender.itemTitle(at: sender.indexOfSelectedItem)) {
            View.zoomOrigin = CGPoint(x: View.bounds.midX,
                                      y: View.bounds.midY)
            sender.title = sender.itemTitle(at: sender.indexOfSelectedItem)
            ZoomSketch.doubleValue = value
            View.zoomSketch(value: value)
        }
    }

//    MARK: Tools Actions
    @IBAction func setTool(_ sender: NSButton) {
        ToolBox.isOn(title: sender.alternateTitle)
        SketchView!.tool.set(sender.alternateTitle)
    }

    func getTagValue(sender: Any) -> (tag: Int, value: Double){
        var tag: Int = 0
        var doubleValue: Double = 0
        if let s = sender as? NSSlider {
            tag = s.tag
            doubleValue = s.doubleValue
        }
        if let  s = sender as? NSTextField {
            tag = s.tag
            doubleValue = s.doubleValue
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

    @IBAction func moveCurve(_ sender: Any) {
        let View = SketchView!
        let v = self.getTagValue(sender: sender)
        View.moveCurve(tag: v.tag, value: v.value)

        let value = round(v.value * 10) / 10
        if v.tag == 0 {
            self.CurveXLabel.doubleValue = value
        } else {
            self.CurveYLabel.doubleValue = value
        }
        self.restoreControlFrame(view: View)
    }

    @IBAction func resizeCurve(_ sender: Any) {
        let View = SketchView!
        let v = self.getTagValue(sender: sender)
        View.resizeCurve(tag: v.tag, value: v.value)

        let value = round(v.value * 10) / 10
        if v.tag == 0 {
            self.CurveWidLabel.doubleValue = value
        } else {
            self.CurveHeiLabel.doubleValue = value
        }
        self.restoreControlFrame(view: View)
    }

    @IBAction func rotateCurve(_ sender: Any) {
        let View = SketchView!
        let v = self.getTagValue(sender: sender)
        View.rotateCurve(angle: v.value)
        let value = round(v.value * 10) / 10

        self.CurveRotateLabel.doubleValue = value
        self.restoreControlFrame(view: View)
    }

    @IBAction func opacityCurve(_ sender: Any) {
        let View = SketchView!
        let v = self.getTagValue(sender: sender)
        View.opacityCurve(tag: v.tag, value: v.value)

        let value = round(v.value * 100) / 100
        if v.tag==0 {
            self.CurveOpacityStrokeLabel.doubleValue = value
        } else if v.tag==1 {
            self.CurveOpacityFillLabel.doubleValue = value
        }
        self.restoreControlFrame(view: View)
    }

    @IBAction func widthCurve(_ sender: Any) {
        let View = SketchView!
        let v = self.getTagValue(sender: sender)
        View.widthCurve(value:  v.value)

        let value = round(v.value * 10) / 10
        self.CurveWidthLabel.doubleValue = value
        self.restoreControlFrame(view: View)
    }

    @IBAction func blurCurve(_ sender: Any) {
        let View = SketchView!
        let v = self.getTagValue(sender: sender)
        View.blurCurve(value: v.value)

        let value = round(v.value * 10) / 10
        self.CurveBlurLabel.doubleValue = value
        self.restoreControlFrame(view: View)
    }

    @IBAction func capCurve(_ sender: NSSegmentedControl) {
        SketchView!.capCurve(value: sender.indexOfSelectedItem)
    }

    @IBAction func joinCurve(_ sender: NSSegmentedControl) {
        SketchView!.joinCurve(value: sender.indexOfSelectedItem)
    }

    @IBAction func dashCurve(_ sender: NSSlider) {
        var dashPattern: [NSNumber] = []
        for slider in CurveDashGap.subviews {
            if let s = slider as? NSSlider {
                dashPattern.append(NSNumber(value: s.doubleValue))
            }
        }
        SketchView!.dashCurve(value: dashPattern)
    }

    @IBAction func alignLeftRightCurve(_ sender: NSSegmentedControl) {
        SketchView!.alignLeftRightCurve(value: sender.indexOfSelectedItem)
    }
    @IBAction func alignUpDownCurve(_ sender: NSSegmentedControl) {
        SketchView!.alignUpDownCurve(value: sender.indexOfSelectedItem)
    }

//    MARK: TextPanel actions
    @IBAction func glyphsCurve(_ sender: NSTextField) {
        SketchView!.glyphsCurve(value: sender.stringValue)
    }

    @IBAction func hideText(_ sender: NSButton) {
        SketchView!.hideText()
    }

    @IBAction func openFontPanel(_ sender: NSButton) {
        if sender.state == .off {
            self.closeSharedFontPanel()
        } else {
            self.createSharedFontPanel()
        }
    }

//    MARK: ColorPanel actions
    @IBAction func openColorPanel(_ sender: ColorBox) {
        if sender.state == .off {
            self.CurveColors.isOn(title: "")
            self.closeSharedColorPanel()
        } else {
            self.CurveColors.isOn(title: sender.alternateTitle)
            self.createSharedColorPanel(sender: sender)
        }
    }

    @IBAction func setStrokeColor(sender: Any) {
        CurveStrokeColorPanel.updateColor(sender: sender,
                                     sharedPanel: &SharedColorPanel)
        SketchView!.colorCurve()
    }

    @IBAction func setFillColor(sender: Any) {
        CurveFillColorPanel.updateColor(sender: sender,
                                     sharedPanel: &SharedColorPanel)
        SketchView!.colorCurve()
    }

    @IBAction func setShadowColor(sender: Any) {
        CurveShadowColorPanel.updateColor(sender: sender,
                                     sharedPanel: &SharedColorPanel)
        SketchView!.shadowColorCurve()
    }

    @IBAction func setShadow(_ sender: Any) {
        let View = SketchView!
        var values = [self.CurveShadowRadius.doubleValue,
                      self.CurveShadowOpacity.doubleValue,
                      self.CurveShadowOffsetX.doubleValue,
                      self.CurveShadowOffsetY.doubleValue]
        if let slider = sender as? NSSlider {
            let value = slider.doubleValue
            switch slider.tag  {
            case 0: values[0] = value
            case 1: values[1] = value
            case 2: values[2] = value
            case 3: values[3] = value
            default: break
            }

        } else if let field = sender as? NSTextField {
            let value = field.doubleValue
            switch field.tag  {
            case 0: values[0] = value
            case 1: values[1] = value
            default: break
            }
        }

        let opa = values[1] > 1 ? 1 : values[1] < 0 ? 0 : values[1]
        CurveShadowRadius.doubleValue = values[0]
        CurveShadowOpacity.doubleValue = opa
        CurveShadowOffsetX.doubleValue = values[2]
        CurveShadowOffsetY.doubleValue = values[3]
        CurveShadowRadiusLabel.doubleValue = round(values[0])
        CurveShadowOpacityLabel.doubleValue = round(opa * 100) / 100

        let floats = values.map({v in CGFloat(v)})

        SketchView!.shadowCurve(value: floats)
        self.restoreControlFrame(view: View)
    }

    @IBAction func setGradientStartColor(sender: Any) {
        CurveGradientStartPanel.updateColor(sender: sender,
                                            sharedPanel: &SharedColorPanel)
        SketchView!.gradientCurve()
    }

    @IBAction func setGradientMiddleColor(_ sender: Any) {
        CurveGradientMiddlePanel.updateColor(sender: sender,
                                            sharedPanel: &SharedColorPanel)
        SketchView!.gradientCurve()
    }

    @IBAction func setGradientFinalColor(_ sender: Any) {
        CurveGradientFinalPanel.updateColor(sender: sender,
                                            sharedPanel: &SharedColorPanel)
        SketchView!.gradientCurve()
    }

    @IBAction func opacityGradientCurve(_ sender: Any) {
        let View = SketchView!
        let v = self.getTagValue(sender: sender)
        View.opacityGradientCurve(tag: v.tag, value: v.value)

        let value = round(v.value * 100) / 100
        if v.tag == 0 {
            self.CurveGradientStartOpacityLabel.doubleValue = value
        } else if v.tag == 1 {
            self.CurveGradientMiddleOpacityLabel.doubleValue = value
        } else if v.tag == 2 {
            self.CurveGradientFinalOpacityLabel.doubleValue = value
        }
        self.restoreControlFrame(view: View)
    }



//    MARK: Buttons actions
    @IBAction func sendCurve(_ sender: NSButton) {
        SketchView!.sendCurve(name: sender.alternateTitle)
    }

    @IBAction func flipCurve(_ sender: NSButton) {
        SketchView!.flipCurve(name: sender.alternateTitle)
    }

    @IBAction func cloneCurve(_ sender: NSButton) {
        SketchView!.cloneCurve()
    }

    @IBAction func editCurve(_ sender: NSButton) {
        if sender.state == NSControl.StateValue.off {
            sender.alternateTitle = "done"
        } else {
            sender.alternateTitle = "edit"
        }
        SketchView!.editCurve(name: sender.alternateTitle)
    }

    @IBAction func lockCurve(_ sender: NSButton) {
        sender.title = sender.state == .off ? "🔓" : "🔒"
        SketchView!.lockCurve()
    }

    @IBAction func groupCurve(_ sender: NSButton) {
        SketchView!.groupCurve()
    }

//    MARK: Menu actions
    @IBAction func delete(_ sender: NSMenuItem) {
        SketchView!.deleteCurve()
    }

    func saveSketch(url: URL, name: String) {
        let View = SketchView!
        if let curve = View.selectedCurve {
            View.clearControls(curve: curve, updatePoints: {})
        }
        View.sketchWidth = 0
        View.sketchColor = NSColor.clear
        let zoomed = View.zoomed
        View.zoomSketch(value: 100)
        let  filePath = url.appendingPathComponent(name)
        if  let image = View.imageData() {
            do {
                try image.write(to: filePath, options: .atomic)

            } catch {
                print("error save image")
            }
        }

        if let curve = View.selectedCurve {
            View.createControls(curve: curve)
        }
        View.sketchWidth = set.lineWidth
        View.sketchColor = set.guiColor
        View.zoomSketch(value: Double(zoomed * 100))
    }
    @IBAction func saveDocument(_ sender: NSMenuItem) {
        let View = SketchView!
        if let name = View.sketchName, let dir = View.sketchDir {
            saveSketch(url: dir, name: name)
        } else {
            self.saveDocumentAs(sender)
        }
    }
    @IBAction func saveDocumentAs(_ sender: NSMenuItem) {
        let View = SketchView!
        let savePanel = NSSavePanel()
        savePanel.setup()

        savePanel.beginSheetModal(for: self.Window!,
                                  completionHandler: {(result) in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                let name = savePanel.nameFieldStringValue

                if name != set.filename {
                    View.sketchName = savePanel.nameFieldStringValue
                }
                if let url = savePanel.directoryURL {
                    View.sketchDir = url
                    self.saveSketch(url: url, name: name)
                }
            } else {
                savePanel.close()
            }
        })

    }
}


