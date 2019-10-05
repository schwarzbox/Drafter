//
//  ViewController.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 8/8/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    var window: NSWindow?
    @IBOutlet weak var sketchView: SketchPad!
    @IBOutlet weak var toolBox: NSStackView!

    @IBOutlet weak var frameButtons: NSStackView!

    @IBOutlet weak var textTool: NSStackView!
    @IBOutlet weak var textToolField: NSTextField!
    @IBOutlet weak var textToolFontFamily: NSPopUpButton!
    @IBOutlet weak var textToolFontType: NSPopUpButton!

    @IBOutlet weak var actionBox: NSStackView!

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

    @IBOutlet weak var curveColorBox: NSBox!
    @IBOutlet weak var curveColors: NSStackView!
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
    @IBOutlet weak var curveGradStartLabel: NSTextField!
    @IBOutlet weak var curveGradMiddleLabel: NSTextField!
    @IBOutlet weak var curveGradFinalLabel: NSTextField!

    @IBOutlet weak var curveGradStartOpacity: NSSlider!
    @IBOutlet weak var curveGradStartOpacityLab: NSTextField!
    @IBOutlet weak var curveGradMiddleOpacity: NSSlider!
    @IBOutlet weak var curveGradMiddleOpacityLab: NSTextField!
    @IBOutlet weak var curveGradFinalOpacity: NSSlider!
    @IBOutlet weak var curveGradFinalOpacityLab: NSTextField!

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
    var sharedColorPanel: NSColorPanel?
    var savePanel: NSSavePanel?

    var fontFamily: String = setup.fontFamily
    var fontType: String = setup.fontType
    var fontSize: CGFloat = setup.fontSize
    var fontMembers = [[Any]]()
    var sharedFont: NSFont?

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // mouse
        self.view.window?.acceptsMouseMovedEvents = true
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
        guard let window = self.view.window,
            NSApplication.shared.keyWindow === window else {
                return false
        }
        if !event.modifierFlags.contains(.command),
            let resp = window.firstResponder, resp.isKind(of: NSWindow.self) {
            let keys: [String] = ["d", "p", "l", "o",
                                  "t", "r", "s", "c", "f"]
            if let ch = event.charactersIgnoringModifiers {
                if let tag = keys.firstIndex(of: ch) {
                    sketchView!.setTool(tag: tag)
                    return true
                }
            }
        }
        return false
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        window = self.view.window!

//      MARK: Set
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
        
        for item in curveDashGap.subviews {
            if let slider = item as? NSSlider {
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

        curveStrokeLabel.stringValue = setup.strokeColor.hexString
        curveFillLabel.stringValue = setup.fillColor.hexString

        curveShadowColor.borderColor =  setup.guiColor
        curveShadowColor.fillColor = setup.shadowColor
        curveShadowLabel.stringValue = setup.shadowColor.hexString

        var shadow = setup.shadow.map {(fl) in Double(fl)}
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
        curveGradStartOpacity.doubleValue = Double(setup.gradientOpacity[0])
        curveGradStartOpacity.maxValue = 1
        curveGradStartOpacityLab.doubleValue = curveGradStartOpacity.doubleValue
        curveGradMiddleOpacity.doubleValue = Double(setup.gradientOpacity[1])
        curveGradMiddleOpacity.maxValue = 1
        curveGradMiddleOpacityLab.doubleValue = curveGradMiddleOpacity.doubleValue
        curveGradFinalOpacity.doubleValue = Double(setup.gradientOpacity[2])
        curveGradFinalOpacity.maxValue = 1
        curveGradFinalOpacityLab.doubleValue = curveGradFinalOpacity.doubleValue

        curveGradStartLabel.stringValue = setup.gradientColor[0].hexString
        curveGradMiddleLabel.stringValue = setup.gradientColor[1].hexString
        curveGradFinalLabel.stringValue = setup.gradientColor[2].hexString

        curveBlur.maxValue = setup.maxBlur

//      MARK: SketchView ref
        sketchView.parent = self
        sketchView.toolBox = toolBox
        sketchView.frameButtons = frameButtons

        sketchView.curveOpacityStroke = curveOpacityStroke
        sketchView.curveOpacityFill = curveOpacityFill
        sketchView.curveWidth = curveWidth

        sketchView.curveCap = curveCap
        sketchView.curveJoin = curveJoin
        sketchView.curveDashGap = curveDashGap

        sketchView.curveColors = curveColors
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

        sketchView.curveGradStartOpacity = curveGradStartOpacity
        sketchView.curveGradMiddleOpacity = curveGradMiddleOpacity
        sketchView.curveGradFinalOpacity = curveGradFinalOpacity

        sketchView.curveBlur = curveBlur

        sketchView.textTool = textTool

        // for precision position create and remove panel
        self.createSharedColorPanel()
        self.closeSharedColorPanel()

        self.findAllTextFields(root: self.view)

        self.setupObservers()
        self.setupTextTool()

        self.showFileName()
    }

//    MARK Obserevers func
    func setupObservers() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(abortTextFields),
                       name: Notification.Name("abortTextFields"),
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

    @objc func updateSliders() {
        let view = sketchView!
        if let curve = view.selectedCurve {
            let x = Double(curve.path.bounds.midX)
            let y = Double(curve.path.bounds.midY)
            let wid = Double(curve.path.bounds.width)
            let hei = Double(curve.path.bounds.height)
            let angle = Double(curve.angle)
            var opacity = curve.alpha.map {(fl) in Double(fl)}
            let width = Double(curve.lineWidth)
            let blur = Double(curve.blur)

            let strokeColor = curve.strokeColor
            let fillColor = curve.fillColor
            let shadowColor = curve.shadowColor
            var shadow = curve.shadow.map {(fl) in Double(fl)}

            let gradient = curve.gradientColor
            let grad0 = Double(curve.gradientOpacity[0])
            let grad1 = Double(curve.gradientOpacity[1])
            let grad2 = Double(curve.gradientOpacity[2])

            self.curveX.doubleValue = x
            self.curveY.doubleValue = y
            self.curveWid.doubleValue = wid
            self.curveHei.doubleValue = hei
            self.curveRotate.doubleValue = angle
            self.curveOpacityStroke.doubleValue = opacity[0]
            self.curveOpacityFill.doubleValue = opacity[1]
            self.curveWidth!.doubleValue = width
            self.curveBlur!.doubleValue = blur

            self.curveStrokeColor.fillColor = strokeColor
            self.curveFillColor.fillColor = fillColor
            self.curveShadowColor.fillColor = shadowColor

            self.curveShadowRadius.doubleValue = shadow[0]
            self.curveShadowOpacity.doubleValue = shadow[1]
            self.curveShadowOffsetX.doubleValue = shadow[2]
            self.curveShadowOffsetY.doubleValue = shadow[3]

            self.curveGradStartColor.fillColor = gradient[0]
            self.curveGradMiddleColor.fillColor = gradient[1]
            self.curveGradFinalColor.fillColor = gradient[2]

            self.curveGradStartOpacity.doubleValue = grad0
            self.curveGradMiddleOpacity.doubleValue =  grad1
            self.curveGradFinalOpacity.doubleValue =  grad2

            self.curveXLabel.doubleValue = x
            self.curveYLabel.doubleValue = y
            self.curveWidLabel.doubleValue = wid
            self.curveHeiLabel.doubleValue =  hei
            self.curveRotateLabel.doubleValue =  angle
            self.curveOpacityStrokeLabel.doubleValue = opacity[0]
            self.curveOpacityFillLabel.doubleValue =  opacity[1]
            self.curveWidthLabel.doubleValue = width
            self.curveBlurLabel.doubleValue = blur

            self.curveStrokeLabel.stringValue = strokeColor.hexString
            self.curveFillLabel.stringValue = fillColor.hexString
            self.curveShadowLabel.stringValue = shadowColor.hexString
            self.curveShadowRadiusLabel.doubleValue = round(shadow[0])
            self.curveShadowOpacityLabel.doubleValue = shadow[1]
            self.curveShadowOffsetXLabel.doubleValue = shadow[2]
            self.curveShadowOffsetYLabel.doubleValue = shadow[3]

            self.curveGradStartLabel.stringValue = gradient[0].hexString
            self.curveGradMiddleLabel.stringValue = gradient[1].hexString
            self.curveGradFinalLabel.stringValue = gradient[2].hexString

            self.curveGradStartOpacityLab.doubleValue = grad0
            self.curveGradMiddleOpacityLab.doubleValue = grad1
            self.curveGradFinalOpacityLab.doubleValue = grad2

            self.curveCap.selectedSegment = curve.cap
            self.curveJoin.selectedSegment = curve.join
            var index = 0
            for item in curveDashGap.subviews {
                if let slider = item as? NSSlider {
                    slider.doubleValue = Double(truncating: curve.dash[index])
                    index += 1
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

//    MARK: Color panel
    func createSharedColorPanel(sender: ColorBox? = nil) {
        let abMin = CGPoint(x: actionBox.frame.minX,
                            y: actionBox.frame.minY)
        let deltaX = abMin.x + curveColorBox.frame.width
        let deltaY = (abMin.y + curveColorBox.frame.minY)
        let rect = NSRect(x: deltaX + (window?.frame.minX)!,
                          y: deltaY + (window?.frame.minY)!,
                          width: curveColorBox.frame.width,
                          height: curveColorBox.frame.height)

        NSColorPanel.setPickerMask(NSColorPanel.Options.wheelModeMask)
        sharedColorPanel = NSColorPanel.shared
        sharedColorPanel?.setFrame(rect, display: true)
        sharedColorPanel?.styleMask = .init(arrayLiteral: [.titled])

        sharedColorPanel?.backgroundColor = setup.guiColor
        sharedColorPanel?.makeKeyAndOrderFront(self)
        sharedColorPanel?.setTarget(self)
        sharedColorPanel?.isContinuous = true
        sharedColorPanel?.mode = NSColorPanel.Mode.wheel

        let tag = sender?.tag ?? -1
        switch tag {
        case 0:
        sharedColorPanel?.setAction(#selector(self.setStrokeColor))
        case 1:
            sharedColorPanel?.setAction(
                #selector(self.setFillColor))
        case 2:
            sharedColorPanel?.setAction(
                #selector(self.setShadowColor))
        case 3:
            sharedColorPanel?.setAction(
                #selector(self.setGradientStartColor))
        case 4:
            sharedColorPanel?.setAction(
                #selector(self.setGradientMiddleColor))
        case 5:
            sharedColorPanel?.setAction(
                #selector(self.setGradientFinalColor))
        default:
            break
        }

        let title = sender?.alternateTitle ?? ""
        sharedColorPanel?.title = title.capitalized
        sketchView!.colorPanel = sharedColorPanel

        self.window?.makeKey()
    }

    func closeSharedColorPanel() {
        if let panel = self.sharedColorPanel {
            panel.close()
            sharedColorPanel = nil
            self.curveColors.isOn(on: -1)
        }
    }

//     MARK: TextTool
    func setupTextTool() {
        self.setupFontFamily()
        textToolFontFamily.selectItem(withTitle: setup.fontFamily)
        let titFam = textToolFontFamily.titleOfSelectedItem ?? setup.fontFamily
        textToolFontFamily.setTitle(titFam)
        self.setupFontMembers()
        self.setupFontType()
        textToolFontType.selectItem(withTitle: setup.fontType)
        let titType = textToolFontType.titleOfSelectedItem ?? setup.fontType
        textToolFontType.setTitle(titType)
        self.setupFont()
    }

    func setupFontFamily() {
        textToolFontFamily.removeAllItems()
        textToolFontFamily.addItems(
            withTitles: NSFontManager.shared.availableFontFamilies)
    }

    func setupFontMembers() {
        if let members = NSFontManager.shared.availableMembers(
            ofFontFamily: self.fontFamily) {
            self.fontMembers.removeAll()
            self.fontMembers = members
        }
    }

    func setupFontType() {
        textToolFontType.removeAllItems()
        for member in self.fontMembers {
            if let type = member[1] as? String {
                textToolFontType.addItem(withTitle: type)
            }
        }
        textToolFontType.selectItem(at: 0)
    }

    func setupFont() {
        let member = self.fontMembers[textToolFontType.indexOfSelectedItem]
        if let weight = member[2] as? Int, let traits = member[3] as? UInt {
            self.sharedFont = NSFontManager.shared.font(
                withFamily: self.fontFamily,
                traits: NSFontTraitMask(rawValue: traits),
                weight: weight, size: self.fontSize)
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
        self.curveRotateLabel.doubleValue = val.value
        view.rotateCurve(angle: val.value)
        self.restoreControlFrame(view: view)
    }

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

//    MARK: TextPanel actions
    @IBAction func selectFont(_ sender: NSPopUpButton) {
        if let family = sender.titleOfSelectedItem {
            self.fontFamily = family
            sender.title = family

            self.setupFontMembers()

            self.setupFontType()
            let titType = textToolFontType.selectedItem?.title ?? setup.fontType
            self.fontType = titType

            self.setupFont()
            if let font = self.sharedFont {
                textToolField.font = font
            }
        }
    }

    @IBAction func selectType(_ sender: NSPopUpButton) {
        if let type = sender.titleOfSelectedItem {
            self.fontType = type
            sender.title = type
            self.setupFont()
            if let font = self.sharedFont {
                textToolField.font = font
            }
        }
    }

    @IBAction func glyphsCurve(_ sender: NSTextField) {
        sketchView!.glyphsCurve(value: sender.stringValue,
                                sharedFont: self.sharedFont)
        sender.stringValue = ""
    }

//    MARK: ColorPanel actions
    @IBAction func openColorPanel(_ sender: ColorBox) {
        if sender.state == .off {
            self.closeSharedColorPanel()
        } else {
            self.curveColors.isOn(on: sender.tag)
            self.createSharedColorPanel(sender: sender)
        }
    }

    @IBAction func setStrokeColor(sender: Any) {
        var color = NSColor.black
        curveStrokeColorPanel.updateColor(sender: sender,
                                          color: &color)
        sharedColorPanel?.color = color
        sketchView!.colorCurve()
    }

    @IBAction func setFillColor(sender: Any) {
        var color = NSColor.black
        curveFillColorPanel.updateColor(sender: sender,
                                        color: &color)
        sharedColorPanel?.color = color
        sketchView!.colorCurve()
    }

    @IBAction func setShadowColor(sender: Any) {
        var color = NSColor.black
        curveShadowColorPanel.updateColor(sender: sender,
                                          color: &color)
        sharedColorPanel?.color = color
        sketchView!.shadowColorCurve()
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

    @IBAction func setGradientStartColor(sender: Any) {
        var color = NSColor.black
        curveGradientStartPanel.updateColor(sender: sender,
                                            color: &color)
        sharedColorPanel?.color = color
        sketchView!.gradientCurve()
    }

    @IBAction func setGradientMiddleColor(_ sender: Any) {
        var color = NSColor.black
        curveGradientMiddlePanel.updateColor(sender: sender,
                                             color: &color)
        sharedColorPanel?.color = color
        sketchView!.gradientCurve()
    }

    @IBAction func setGradientFinalColor(_ sender: Any) {
        var color = NSColor.black
        curveGradientFinalPanel.updateColor(sender: sender,
                                            color: &color)
        sharedColorPanel?.color = color
        sketchView!.gradientCurve()
    }

    @IBAction func opacityGradientCurve(_ sender: Any) {
        let view = sketchView!
        let val = self.getTagValue(sender: sender)

        let lim = val.value > 1 ? 1 : val.value < 0 ? 0 : val.value
        if val.tag == 0 {
            curveGradStartOpacityLab.doubleValue = lim
        } else if val.tag == 1 {
            curveGradMiddleOpacityLab.doubleValue = lim
        } else if val.tag == 2 {
            curveGradFinalOpacityLab.doubleValue = lim
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

            let topLeft = NSPoint(x: view.frame.midX - wid/2,
                                  y: view.frame.midY - hei/2)
            let bottomRight = NSPoint(x: view.frame.midX + wid/2,
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

    func newSketch() {
        let view = sketchView!
        view.zoomOrigin = NSPoint(x: view.frame.midX,
                                  y: view.frame.midY)
        view.zoomSketch(value: 100)

        if let curve = view.selectedCurve {
            view.clearControls(curve: curve, updatePoints: {})
        }
        view.selectedCurve = nil

        self.closeSharedColorPanel()
        view.hideTextTool()

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

        self.updateSliders()
    }

    @IBAction func openDocument(_ sender: NSMenuItem) {
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
        if let curve = view.selectedCurve {
            view.clearControls(curve: curve, updatePoints: {})
        }
        view.sketchWidth = 0
        view.sketchColor = NSColor.clear
        let zoomed = view.zoomed
        let zoomOrigin = view.zoomOrigin
        view.zoomOrigin = NSPoint(x: view.frame.midX,
                                  y: view.frame.midY)
        view.zoomSketch(value: 100)

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
        } else {
            self.saveDocumentAs(sender)
        }
    }

    @IBAction func saveDocumentAs(_ sender: NSMenuItem) {
        let view = sketchView!
        self.closeSharedColorPanel()
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
