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
    @IBOutlet weak var CurveOpacity: NSSlider!
    @IBOutlet weak var CurveWidth: NSSlider!
    @IBOutlet weak var CurveBlur: NSSlider!
    @IBOutlet weak var CurveXLabel: TextField!
    @IBOutlet weak var CurveYLabel: TextField!
    @IBOutlet weak var CurveWidLabel: TextField!
    @IBOutlet weak var CurveHeiLabel: TextField!
    @IBOutlet weak var CurveRotateLabel: TextField!

    @IBOutlet weak var CurveWidthLabel: TextField!
    @IBOutlet weak var CurveOpacityLabel: TextField!
    @IBOutlet weak var CurveBlurLabel: TextField!

    @IBOutlet weak var CurveColorBox: NSBox!
    @IBOutlet weak var CurveStrokeColor: NSBox!
    @IBOutlet weak var CurveFillColor: NSBox!
    @IBOutlet weak var CurveStrokeColorPanel: ColorBox!
    @IBOutlet weak var CurveFillColorPanel: ColorBox!

    @IBOutlet weak var CurveStrokeLabel: TextField!
    @IBOutlet weak var CurveFillLabel: TextField!

    @IBOutlet weak var CurveShadowColor: NSBox!
    @IBOutlet weak var CurveShadowColorPanel: ColorBox!
    @IBOutlet weak var CurveShadowLabel: TextField!
    @IBOutlet weak var CurveShadowRadius: TextField!
    @IBOutlet weak var CurveShadowOpacity: TextField!
    @IBOutlet weak var CurveShadowOffsetX: TextField!
    @IBOutlet weak var CurveShadowOffsetY: TextField!
    @IBOutlet weak var CurveRadiusStepper: NSStepper!
    @IBOutlet weak var CurveOpacityStepper: NSStepper!
    @IBOutlet weak var CurveOffsetXStepper: NSStepper!
    @IBOutlet weak var CurveOffsetYStepper: NSStepper!

    @IBOutlet weak var CurveCap: NSSegmentedControl!
    @IBOutlet weak var CurveJoin: NSSegmentedControl!
    @IBOutlet weak var CurveDashGap: NSStackView!

    var ColorPanel: NSColorPanel?

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

//        MARK: Set
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
        CurveWid.doubleValue = CurveWid.maxValue
        CurveHei.doubleValue = CurveHei.maxValue
        CurveRotate.minValue = set.minRotate
        CurveRotate.maxValue = set.maxRotate
        CurveWidth.doubleValue = Double(set.lineWidth)
        CurveWidth.maxValue = Double(set.maxLineWidth)
        CurveOpacity.maxValue = 1
        CurveOpacity.doubleValue =  CurveOpacity.maxValue
        CurveBlur.maxValue = set.maxBlur

        CurveWidLabel.doubleValue = set.screenWidth
        CurveHeiLabel.doubleValue = set.screenHeight
        CurveWidthLabel.doubleValue = Double(set.lineWidth)
        CurveOpacityLabel.doubleValue =  CurveOpacity.maxValue


        CurveStrokeColor.borderColor = set.guiColor
        CurveStrokeColor.fillColor = set.strokeColor
        CurveFillColor.borderColor = set.guiColor
        CurveFillColor.fillColor = set.fillColor

        CurveStrokeLabel.stringValue = set.strokeColor.hexString
        CurveFillLabel.stringValue = set.fillColor.hexString


        let rad = Double(set.shadow[0])
        let opa = Double(set.shadow[1])
        let offX = Double(set.shadow[2])
        let offY = Double(set.shadow[3])
        CurveShadowRadius.doubleValue = rad
        CurveShadowOpacity.doubleValue = opa
        CurveShadowOffsetX.doubleValue = offX
        CurveShadowOffsetY.doubleValue = offY

        CurveRadiusStepper.doubleValue = rad
        CurveOpacityStepper.doubleValue = opa
        CurveOffsetXStepper.doubleValue = offX
        CurveOffsetYStepper.doubleValue = offY
        CurveRadiusStepper.maxValue = set.maxShadowRadius
        CurveOpacityStepper.maxValue = 1
        CurveOffsetXStepper.maxValue = set.maxShadowOffsetX
        CurveOffsetYStepper.maxValue = set.maxShadowOffsetY
        CurveOpacityStepper.increment = set.opacityIncrement
        CurveOffsetXStepper.increment = set.offsetIncrement
        CurveOffsetYStepper.increment = set.offsetIncrement

        self.setShadowAlpha(color: set.shadowColor)

        CurveShadowLabel.stringValue = set.shadowColor.hexString

//        MARK: SketchView ref
        SketchView.parent = self
        SketchView.ToolBox = ToolBox
        SketchView.FrameButtons = FrameButtons
        SketchView.CurveX = CurveX
        SketchView.CurveY = CurveY
        SketchView.CurveWid = CurveWid
        SketchView.CurveHei = CurveHei
        SketchView.CurveRotate = CurveRotate
        SketchView.CurveOpacity = CurveOpacity
        SketchView.CurveWidth = CurveWidth
        SketchView.CurveBlur = CurveBlur

        SketchView.CurveXLabel = CurveXLabel
        SketchView.CurveYLabel = CurveYLabel
        SketchView.CurveWidLabel = CurveWidLabel
        SketchView.CurveHeiLabel = CurveHeiLabel
        SketchView.CurveRotateLabel = CurveRotateLabel
        SketchView.CurveOpacityLabel = CurveOpacityLabel
        SketchView.CurveWidthLabel = CurveWidthLabel
        SketchView.CurveBlurLabel = CurveBlurLabel

        SketchView.CurveStrokeColorPanel = CurveStrokeColorPanel
        SketchView.CurveFillColorPanel = CurveFillColorPanel
        SketchView.CurveShadowColorPanel = CurveShadowColorPanel

        SketchView.CurveStrokeColor = CurveStrokeColor
        SketchView.CurveFillColor = CurveFillColor
        SketchView.CurveShadowColor = CurveShadowColor
        SketchView.CurveStrokeLabel = CurveStrokeLabel
        SketchView.CurveFillLabel = CurveFillLabel
        SketchView.CurveShadowLabel = CurveShadowLabel
        SketchView.CurveShadowRadius = CurveShadowRadius
        SketchView.CurveShadowOpacity = CurveShadowOpacity
        SketchView.CurveShadowOffsetX = CurveShadowOffsetX
        SketchView.CurveShadowOffsetY = CurveShadowOffsetY
        SketchView.CurveRadiusStepper = CurveRadiusStepper
        SketchView.CurveOpacityStepper = CurveOpacityStepper
        SketchView.CurveOffsetXStepper = CurveOffsetXStepper
        SketchView.CurveOffsetYStepper = CurveOffsetYStepper

        SketchView.CurveCap = CurveCap
        SketchView.CurveJoin = CurveJoin
        SketchView.CurveDashGap = CurveDashGap

        // for precision position create and remove panel
        self.createColorPanel(type: "fill")
        self.closeColorPanel()

        // abort text fields
        let textFields = [CurveStrokeLabel,CurveFillLabel,
                          CurveShadowLabel,
                          CurveShadowRadius, CurveShadowOpacity,
                          CurveShadowOffsetX, CurveShadowOffsetY,
                          CurveXLabel,CurveYLabel,
                          CurveWidLabel,CurveHeiLabel,
                          CurveRotateLabel,CurveOpacityLabel,
                          CurveWidthLabel,CurveBlurLabel]

        for view in textFields {
            if let field = view {
                SketchView.setTextField(field: field)
            }
        }
        SketchView.abortTextFields()

        // keys event
        NSEvent.addLocalMonitorForEvents(
            matching: NSEvent.EventTypeMask.keyDown,
            handler: keyDownEvent)
    }

//    MARK: Event func
    func keyDownEvent(with event: NSEvent) -> NSEvent? {
        if event.keyCode == 51 && !set.isActiveTextField {
            let View = SketchView!
            View.deleteCurve()
        }
        return event
    }

//    MARK: Color panel
    func setShadowAlpha(color: NSColor) {
        let alpha = CurveShadowOpacity.doubleValue
        CurveShadowColor.fillColor = color.sRGB(alpha: CGFloat(alpha))
    }

    func createColorPanel(type: String) {
        let abMin = CGPoint(x: ActionBox.frame.minX,
                            y: ActionBox.frame.minY)
        let deltaX = abMin.x + CurveColorBox.frame.width
        let deltaY = (abMin.y + CurveColorBox.frame.minY)
        let rect = NSRect(x: deltaX + (Window?.frame.minX)!,
                          y: deltaY + (Window?.frame.minY)!,
                          width: CurveColorBox.frame.width,
                          height: CurveColorBox.frame.height)

        NSColorPanel.setPickerMask(NSColorPanel.Options.wheelModeMask)
        ColorPanel = NSColorPanel.shared
        ColorPanel?.setFrame(rect, display: true)
        ColorPanel?.styleMask = .closable
        ColorPanel?.backgroundColor = set.guiColor
        ColorPanel?.makeKeyAndOrderFront(self)
        ColorPanel?.setTarget(self)

        ColorPanel?.isContinuous = true
        ColorPanel?.mode = NSColorPanel.Mode.wheel
        if type=="stroke" {
            ColorPanel?.setAction(
                #selector(self.setStrokeColor))
        } else if type=="fill" {
            ColorPanel?.setAction(
                #selector(self.setFillColor))
        } else {
            ColorPanel?.setAction(
                #selector(self.setShadowColor))
        }
        let View = SketchView!
        View.ColorPanel = ColorPanel
    }

    @IBAction func setStrokeColor(sender: NSColorPanel) {
        CurveStrokeColor.fillColor = sender.color
        CurveStrokeLabel.stringValue = sender.color.hexString
        let View = SketchView!
        View.colorCurve()
    }

//    MARK: Manual Actions
    @IBAction func setFillColor(sender: NSColorPanel) {
        CurveFillColor.fillColor = sender.color
        CurveFillLabel.stringValue = sender.color.hexString
        let View = SketchView!
        View.colorCurve()
    }

    @IBAction func setShadowColor(sender: NSColorPanel) {
        CurveShadowLabel.stringValue = sender.color.hexString
        self.setShadowAlpha(color: sender.color)
        let View = SketchView!
        View.shadowColorCurve()
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

//    MARK: Actions
    @IBAction func setTool(_ sender: NSButton) {
        let View = SketchView!
        ToolBox.isOn(title: sender.alternateTitle)
        View.tool.set(sender.alternateTitle)
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

        if NSEvent.pressedMouseButtons == 0 {
            if let curve = View.selectedCurve {
                View.createControls(curve: curve)
            }
        }
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
        if NSEvent.pressedMouseButtons == 0 {
            if let curve = View.selectedCurve {
                View.createControls(curve: curve)
            }
        }
    }

    @IBAction func rotateCurve(_ sender: Any) {
        let View = SketchView!
        let v = self.getTagValue(sender: sender)
        View.rotateCurve(angle: v.value)
        let value = round(v.value * 10) / 10

        View.CurveRotateLabel.doubleValue = value
        if NSEvent.pressedMouseButtons == 0 {
            if let curve = View.selectedCurve {
                View.createControls(curve: curve)
            }
        }
    }

    @IBAction func opacityCurve(_ sender: Any) {
        let View = SketchView!
        let v = self.getTagValue(sender: sender)
        View.opacityCurve(value: v.value)

        let value = round(v.value * 10) / 10
        self.CurveOpacityLabel.doubleValue = value
        if NSEvent.pressedMouseButtons == 0 {
            if let curve = View.selectedCurve {
                View.createControls(curve: curve)
            }
        }
    }

    @IBAction func widthCurve(_ sender: Any) {
        let View = SketchView!
        let v = self.getTagValue(sender: sender)
        View.widthCurve(value:  v.value)

        let value = round(v.value * 10) / 10
        self.CurveWidthLabel.doubleValue = value
        if NSEvent.pressedMouseButtons == 0 {
            if let curve = View.selectedCurve {
                View.createControls(curve: curve)
            }
        }
    }

    @IBAction func blurCurve(_ sender: Any) {
        let View = SketchView!
        let v = self.getTagValue(sender: sender)
        View.blurCurve(value: v.value)

        let value = round(v.value * 10) / 10
        self.CurveBlurLabel.doubleValue = value
        if NSEvent.pressedMouseButtons == 0 {
            if let curve = View.selectedCurve {
                View.createControls(curve: curve)
            }
        }
    }

    @IBAction func setHexStrokeColor(_ sender: NSTextField) {
        let color = NSColor.init(
            hex: Int(sender.stringValue, radix: 16) ?? 0xFFFFFF)
        CurveStrokeLabel.stringValue = color.hexString
        ColorPanel?.color = color
        CurveStrokeColor.fillColor = color
        let View = SketchView!
        View.colorCurve()
    }

    @IBAction func setHexFillColor(_ sender: NSTextField) {
        let color = NSColor.init(
            hex: Int(sender.stringValue, radix: 16) ?? 0xFFFFFF)
        CurveFillLabel.stringValue = color.hexString
        ColorPanel?.color = color
        CurveFillColor.fillColor = color
        let View = SketchView!
        View.colorCurve()
    }

    @IBAction func setHexShadowColor(_ sender: NSTextField) {
        let color = NSColor.init(
            hex: Int(sender.stringValue, radix: 16) ?? 0xFFFFFF)
        CurveShadowLabel.stringValue = color.hexString
        ColorPanel?.color = color
        self.setShadowAlpha(color: color)
        let View = SketchView!
        View.colorCurve()
    }

    @IBAction func setShadow(_ sender: Any) {
        if let stepper = sender as? NSStepper {

            let value = stepper.doubleValue
            switch stepper.tag  {
            case 0: CurveShadowRadius.doubleValue = value
            case 1: CurveShadowOpacity.doubleValue = round(value * 10) / 10
            case 2: CurveShadowOffsetX.doubleValue = value
            case 3: CurveShadowOffsetY.doubleValue = value
            default: break
            }
        }
        var opa = CurveShadowOpacity.doubleValue
        opa = opa>1 ? 1 : opa < 0 ? 0 : opa
        let values = [CurveShadowRadius.doubleValue,
                      opa,
                      CurveShadowOffsetX.doubleValue,
                      CurveShadowOffsetY.doubleValue]
        CurveRadiusStepper.doubleValue = values[0]
        CurveOpacityStepper.doubleValue = values[1]
        CurveOffsetXStepper.doubleValue = values[2]
        CurveOffsetYStepper.doubleValue = values[3]
        CurveShadowRadius.doubleValue = values[0]
        CurveShadowOpacity.doubleValue = values[1]
        CurveShadowOffsetX.doubleValue = values[2]
        CurveShadowOffsetY.doubleValue = values[3]

        let floats = values.map({v in CGFloat(v)})

        self.setShadowAlpha(color: CurveShadowColor.fillColor)

        let View = SketchView!
        View.shadowCurve(value: floats)
    }

    func closeColorPanel() {
        if let panel = self.ColorPanel {
            panel.close()
            self.ColorPanel = nil
            let View = SketchView!
            View.ColorPanel = nil
        }
    }

    @IBAction func strokeColorPanel(_ sender: ColorBox) {
        if sender.state == NSControl.StateValue.off {
            self.closeColorPanel()
        } else {
            self.createColorPanel(type: "stroke")
            self.ColorPanel?.color = self.CurveStrokeColor.fillColor
            self.CurveFillColorPanel.state = .off
            self.CurveFillColorPanel.restore()
            self.CurveShadowColorPanel.state = .off
            self.CurveShadowColorPanel.restore()
        }
    }

    @IBAction func fillColorPanel(_ sender: ColorBox) {
        if sender.state == NSControl.StateValue.off {
            self.closeColorPanel()
        } else {
            self.createColorPanel(type: "fill")
            self.ColorPanel?.color = self.CurveFillColor.fillColor
            self.CurveStrokeColorPanel.state = .off
            self.CurveStrokeColorPanel.restore()
            self.CurveShadowColorPanel.state = .off
            self.CurveShadowColorPanel.restore()
        }
    }

    @IBAction func shadowColorPanel(_ sender: ColorBox) {
        if sender.state == NSControl.StateValue.off {
            self.closeColorPanel()
        } else {
            self.createColorPanel(type: "shadow")
            self.ColorPanel?.color = self.CurveShadowColor.fillColor
            self.CurveFillColorPanel.state = .off
            self.CurveFillColorPanel.restore()
            self.CurveStrokeColorPanel.state = .off
            self.CurveStrokeColorPanel.restore()
        }
    }

    @IBAction func capCurve(_ sender: NSSegmentedControl) {
        let View = SketchView!
        View.capCurve(value: sender.indexOfSelectedItem)
    }

    @IBAction func joinCurve(_ sender: NSSegmentedControl) {
        let View = SketchView!
        View.joinCurve(value: sender.indexOfSelectedItem)
    }

    @IBAction func dashCurve(_ sender: NSSlider) {
        let View = SketchView!
        var dashPattern: [NSNumber] = []
        for slider in CurveDashGap.subviews {
            if let s = slider as? NSSlider {
                dashPattern.append(NSNumber(value: s.doubleValue))
            }
        }
        View.dashCurve(value: dashPattern)
    }
    @IBAction func alignLeftRightCurve(_ sender: NSSegmentedControl) {
        let View = SketchView!
        View.alignLeftRightCurve(value: sender.indexOfSelectedItem)
    }
    @IBAction func alignUpDownCurve(_ sender: NSSegmentedControl) {
        let View = SketchView!
        View.alignUpDownCurve(value: sender.indexOfSelectedItem)
    }

    @IBAction func sendCurve(_ sender: NSButton) {
        let View = SketchView!
        View.sendCurve(name: sender.alternateTitle)
    }

    @IBAction func flipCurve(_ sender: NSButton) {
        let View = SketchView!
        View.flipCurve(name: sender.alternateTitle)
    }

    @IBAction func cloneCurve(_ sender: NSButton) {
        let View = SketchView!
        View.cloneCurve()
    }

    @IBAction func editCurve(_ sender: NSButton) {
        let View = SketchView!
        if sender.state == NSControl.StateValue.off {
            sender.alternateTitle = "done"
        } else {
            sender.alternateTitle = "edit"
        }
        View.editCurve(name: sender.alternateTitle)
    }

    @IBAction func lockCurve(_ sender: NSButton) {
        let View = SketchView!
        sender.title = sender.state == .off ? "🔓" : "🔒"
        View.lockCurve()
    }

//    MARK: Menu func
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


