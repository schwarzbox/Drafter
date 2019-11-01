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
    @IBOutlet weak var sketchUI: SketchStack!

    @IBOutlet weak var locationX: NSTextField!
    @IBOutlet weak var locationY: NSTextField!

    @IBOutlet weak var toolUI: NSStackView!
    @IBOutlet weak var frameUI: FrameButtons!
    @IBOutlet weak var textUI: TextTool!
    @IBOutlet weak var actionUI: NSStackView!

    @IBOutlet weak var colorUI: NSStackView!

    @IBOutlet weak var zoomSketch: NSSlider!
    @IBOutlet weak var zoomDefaultSketch: NSPopUpButton!

    @IBOutlet weak var curveX: ActionSlider!
    @IBOutlet weak var curveY: ActionSlider!
    @IBOutlet weak var curveWid: ActionSlider!
    @IBOutlet weak var curveHei: ActionSlider!
    @IBOutlet weak var curveRotate: ActionSlider!

    @IBOutlet weak var curveWidth: ActionSlider!
    @IBOutlet weak var curveCap: NSSegmentedControl!
    @IBOutlet weak var curveJoin: NSSegmentedControl!
    @IBOutlet weak var curveDashGap: NSStackView!
    @IBOutlet weak var curveDashGapLabel: NSStackView!

    @IBOutlet weak var curveStrokeOpacity: ActionSlider!
    @IBOutlet weak var curveFillOpacity: ActionSlider!

    @IBOutlet weak var curveStrokeColor: ColorPanel!
    @IBOutlet weak var curveFillColor: ColorPanel!

    @IBOutlet weak var curveGradStart: ColorPanel!
    @IBOutlet weak var curveGradMiddle: ColorPanel!
    @IBOutlet weak var curveGradFinal: ColorPanel!

    @IBOutlet weak var curveGradStOpacity: ActionSlider!
    @IBOutlet weak var curveGradMidOpacity: ActionSlider!
    @IBOutlet weak var curveGradFinOpacity: ActionSlider!

    @IBOutlet weak var curveShadowColor: ColorPanel!

    @IBOutlet weak var curveShadowOpacity: ActionSlider!
    @IBOutlet weak var curveShadowRadius: ActionSlider!
    @IBOutlet weak var curveShadowOffsetX: ActionSlider!
    @IBOutlet weak var curveShadowOffsetY: ActionSlider!

    @IBOutlet weak var curveBlur: ActionSlider!
    @IBOutlet weak var curveFilterOpacity: ActionSlider!

    var alphaSliders: [ActionSlider] = []
    var colorPanels: [ColorPanel] = []
    var textFields: [NSTextField] = []
    var colorPanel: ColorPanel?
    var savePanel: NSSavePanel?

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
        NSEvent.addLocalMonitorForEvents(
            matching: NSEvent.EventTypeMask.keyUp) {
            if self.keyUpEvent(event: $0) {
                return nil
            } else {
                return $0
            }
        }
    }

//    MARK: Key
    func eventTest(event: NSEvent) -> Bool {
        guard NSApplication.shared.keyWindow === self.window else {
            return false
        }
        if !event.modifierFlags.contains(.command),
            let resp = self.window.firstResponder,
            resp.isKind(of: NSWindow.self) {
            return true
        }
        return false
    }

    func keyDownEvent(event: NSEvent) -> Bool {
        if self.eventTest(event: event) {
            let view = sketchView!
            if let ch = event.charactersIgnoringModifiers,
               let tool = toolsKeys[ch] {
                view.setTool(tag: tool.rawValue)
                return true

            } else if event.keyCode >= 123 && event.keyCode <= 126 {
                var dt = CGPoint(x: 0, y: 0)
                switch event.keyCode {
                case 123: dt.x = -1
                case 124: dt.x = 1
                case 125: dt.y = 1
                case 126: dt.y = -1
                default: break
                }
                view.dragCurve(deltaX: dt.x, deltaY: dt.y, ctrl: true)
                return true
            }
        }
        return false
    }

    func keyUpEvent(event: NSEvent) -> Bool {
        if self.eventTest(event: event) {
            let view = sketchView!
            if event.keyCode >= 123 && event.keyCode <= 126 {
                self.restoreControlFrame(view: view)
            }
            return true
        }
        return false
    }

//    MARK : Appear
    override func viewDidAppear() {
        super.viewDidAppear()
        window = self.view.window!

        let textShadow = NSShadow()
        textShadow.shadowColor = setup.guiColor
        textShadow.shadowOffset = NSSize(width: 1, height: -1.5)

        locationX.shadow = textShadow
        locationY.shadow = textShadow

        let ui = [toolUI, frameUI, actionUI]
        for view in ui {
            view?.layer = CALayer()
            view?.layer?.backgroundColor = setup.guiColor.cgColor
        }

        self.setupZoom()

        curveX.maxValue = setup.screenWidth
        curveY.maxValue = setup.screenHeight
        curveX.minValue = -setup.screenWidth
        curveY.minValue = -setup.screenHeight
        curveWid.minValue = setup.minResize
        curveHei.minValue = setup.minResize
        curveWid.maxValue = setup.maxScreenWidth
        curveHei.maxValue = setup.maxScreenHeight
        curveWid.doubleValue = setup.screenWidth
        curveHei.doubleValue = setup.screenHeight
        curveRotate.minValue = setup.minRotate
        curveRotate.maxValue = setup.maxRotate

        colorPanels = [curveStrokeColor, curveFillColor,
                       curveShadowColor, curveGradStart,
                       curveGradMiddle, curveGradFinal]

        alphaSliders = [curveStrokeOpacity, curveFillOpacity,
                        curveShadowOpacity, curveGradStOpacity,
                        curveGradMidOpacity, curveGradFinOpacity,
                        curveFilterOpacity]

        self.setupStroke()
        self.setupColors()
        self.setupAlpha()
        self.setupShadow()

        curveBlur.minValue = setup.minBlur
        curveBlur.maxValue = setup.maxBlur

        ColorPanel.setupSharedColorPanel()

        self.setupSketchView()
        textUI!.setupTextTool()

        self.findAllTextFields(root: self.view)

        self.setupObservers()
        self.showFileName()
        self.updateSliders()
    }

    func setupZoom() {
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
    }

    func setupStroke() {
        curveWidth.doubleValue = Double(setup.lineWidth)
        curveWidth.maxValue = Double(setup.maxLineWidth)

         for view in curveDashGap.subviews {
             if let slider = view as? NSSlider {
                 slider.minValue = setup.minDash
                 slider.maxValue = setup.maxDash
             }
         }
    }

    func setupColors() {
        for (i, panel) in self.colorPanels.enumerated() {
            panel.fillColor = setup.colors[i]
        }
    }

    func setupAlpha() {
        for (i, slider) in self.alphaSliders.enumerated() {
            slider.maxValue = 1
            slider.minValue = 0
            slider.doubleValue = Double(setup.alpha[i])
        }
    }

    func setupShadow() {
        curveShadowRadius.maxValue = setup.maxShadowRadius
        curveShadowOffsetX.minValue = -setup.maxShadowOffsetX
        curveShadowOffsetY.minValue = -setup.maxShadowOffsetY
        curveShadowOffsetX.maxValue = setup.maxShadowOffsetX
        curveShadowOffsetY.maxValue = setup.maxShadowOffsetY

        let shadow = setup.shadow.map {(fl) in Double(fl)}
        curveShadowRadius.doubleValue = shadow[0]
        curveShadowOffsetX.doubleValue = shadow[1]
        curveShadowOffsetY.doubleValue = shadow[2]
    }

    func setupSketchView() {
        sketchView.parent = self
        sketchView.locationX = locationX
        sketchView.locationY = locationY

        sketchView.sketchUI = sketchUI
        sketchView.toolUI = toolUI
        sketchView.frameUI = frameUI
        sketchView.textUI = textUI

        sketchView.curveWidth = curveWidth

        sketchView.curveShadowRadius = curveShadowRadius
        sketchView.curveShadowOffsetX = curveShadowOffsetX
        sketchView.curveShadowOffsetY = curveShadowOffsetY

        sketchView.alphaSliders = alphaSliders
        sketchView.colorPanels = colorPanels
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
        if let curve = sketchView!.selectedCurve {
            self.updateSketchUIButtons(curve: curve)
        }
    }

    func showUnusedViews(_ bool: Bool, from: Int = 2) {
        for index in from..<actionUI.subviews.count {
            let subs = actionUI.subviews[index].subviews
            if index==2 {
                for i in 0..<subs.count {
                    if let stack = subs[i] as? NSStackView {
                        if i != 3 && i != 4 {
                            stack.isEnabled(all: bool)
                        }
                    }
                }
            } else {
                for view in subs {
                    if let stack = view as? NSStackView {
                        stack.isEnabled(all: bool)
                    }
                }
            }
        }
        if let sharedPanel = self.colorPanel, !bool {
            sharedPanel.closeSharedColorPanel()
        }
    }

    @objc func updateSliders() {
        let view = sketchView!
        if let curve = view.selectedCurve, !curve.lock {

            let bounds = view.groups.count>1
                ? curve.groupRect(curves: view.groups, includeStroke: false)
                : curve.groupRect(curves: curve.groups, includeStroke: false)
            self.curveX.doubleValue = Double(bounds.midX)
            self.curveY.doubleValue = Double(bounds.midY)
            self.curveWid.doubleValue = Double(bounds.width)
            self.curveHei.doubleValue = Double(bounds.height)
            self.curveRotate.doubleValue = Double(curve.angle)

            defer {self.updateSketchUIButtons(curve: curve)}

            if curve.groups.count==1 && view.groups.count <= 1 {
                self.showUnusedViews(true)
            } else {
                self.showUnusedViews(false, from: 3)
                return
            }

            self.curveWidth.doubleValue = Double(curve.lineWidth)
            self.curveCap.selectedSegment = curve.cap
            self.curveJoin.selectedSegment = curve.join

            for i in 0..<curve.dash.count {
                 let value = Double(truncating: curve.dash[i])
                 if let slider = curveDashGap.subviews[i] as? NSSlider {
                     slider.doubleValue = value
                 }
                 if let label = curveDashGapLabel.subviews[i] as? NSTextField {
                     label.doubleValue = value
                 }
            }

            for (i, color) in curve.colors.enumerated() {
                self.colorPanels[i].fillColor = color
            }

            for (i, alpha) in curve.alpha.enumerated() {
                self.alphaSliders[i].doubleValue = Double(alpha)
            }

            if let clrPan = self.colorPanel,
                let sharedClrPan = clrPan.sharedColorPanel {
                let view = self.colorPanels[clrPan.colorTag]
                sharedClrPan.color = view.fillColor
            }

            let shadow = curve.shadow.map {(fl) in Double(fl)}
            self.curveShadowRadius.doubleValue = shadow[0]
            self.curveShadowOffsetX.doubleValue = shadow[1]
            self.curveShadowOffsetY.doubleValue = shadow[2]

            self.curveBlur.doubleValue = Double(curve.blur)
        } else {
            self.showUnusedViews(false)
            self.curveWid.doubleValue = Double(view.sketchPath.bounds.width)
            self.curveHei.doubleValue = Double(view.sketchPath.bounds.height)
        }
    }

    func updateSketchUIButtons(curve: Curve) {
        if let index = sketchView!.curves.firstIndex(of: curve) {
            sketchUI.updateImageButton(index: index, curve: curve)
        }
    }

//    MARK: Zoom Actions
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
        let view = sketchView!
        view.zoomOrigin = CGPoint(x: view.sketchPath.bounds.midX,
                                  y: view.sketchPath.bounds.midY)
        view.zoomSketch(value: sender.doubleValue)
        zoomDefaultSketch.title = String(sender.intValue)
    }

    @IBAction func zoomDefaultSketch(_ sender: NSPopUpButton) {
        let view = sketchView!
        if let value = Double(sender.itemTitle(
            at: sender.indexOfSelectedItem)) {
            view.zoomOrigin = CGPoint(x: view.sketchPath.bounds.midX,
                                      y: view.sketchPath.bounds.midY)

            sender.title = sender.itemTitle(at: sender.indexOfSelectedItem)
            zoomSketch.doubleValue = value
            view.zoomSketch(value: value)
        }
    }

//    MARK: Tools Actions
    @IBAction func setTool(_ sender: NSButton) {
        sketchView!.setTool(tag: sender.tag)
        self.showUnusedViews(true)
    }

    func getTagValue(sender: Any,
                     limit: (_ :Double) -> Double = {x in x})
        -> (tag: Int, value: Double) {
        var tag: Int = 0
        var doubleValue: Double = 0
        if let sl = sender as? NSSlider {
            tag = sl.tag
            doubleValue = sl.doubleValue
        } else if let tf = sender as? NSTextField {
            tag = tf.tag
            doubleValue = tf.doubleValue
        } else if let tuple = sender as? (tag: Int, doubleValue: Double) {
            tag = tuple.tag
            doubleValue = tuple.doubleValue
        }
        doubleValue = limit(doubleValue)
        return (tag: tag, value: doubleValue)
    }

    func restoreControlFrame(view: SketchPad) {
        if NSEvent.pressedMouseButtons == 0 {
            if let curve = view.selectedCurve, curve.controlFrame==nil,
                !curve.lock {
                view.createControls(curve: curve)
            }
        }
    }

    @IBAction func alignLeftRightCurve(_ sender: NSSegmentedControl) {
        let view = sketchView!
        view.alignLeftRightCurve(value: sender.indexOfSelectedItem)
        self.restoreControlFrame(view: view)
    }
    @IBAction func alignUpDownCurve(_ sender: NSSegmentedControl) {
        let view = sketchView!
        sketchView!.alignUpDownCurve(value: sender.indexOfSelectedItem)
        self.restoreControlFrame(view: view)
    }

    @IBAction func moveCurve(_ sender: Any) {
        let view = sketchView!
        let val = self.getTagValue(sender: sender)
        if val.tag == 0 {
            self.curveX.doubleValue = val.value
        } else {
            self.curveY.doubleValue = val.value
        }
        view.moveCurve(tag: val.tag, value: val.value)
        self.restoreControlFrame(view: view)
    }

    @IBAction func resizeCurve(_ sender: Any) {
        let view = sketchView!
        let val = self.getTagValue(
            sender: sender, limit: {x in x <= 0 ? setup.minResize : x})
        if val.tag == 0 {
            self.curveWid.doubleValue = val.value
        } else {
            self.curveHei.doubleValue = val.value
        }
        view.resizeCurve(tag: val.tag, value: val.value)
        self.restoreControlFrame(view: view)
    }

    @IBAction func rotateCurve(_ sender: Any) {
        let view = sketchView!
        let minR = setup.minRotate
        let maxR = setup.maxRotate
        let val = self.getTagValue(
            sender: sender, limit: {x in x > maxR ? maxR : x < minR ? minR : x})

        self.curveRotate.doubleValue = val.value
        view.rotateCurve(angle: val.value)
        self.restoreControlFrame(view: view)
    }

    @IBAction func widthCurve(_ sender: Any) {
        let view = sketchView!
        let val = self.getTagValue(
            sender: sender, limit: {x in x < 0 ? 0 : x})

        self.curveWidth.doubleValue = val.value
        view.lineWidthCurve(value: val.value)
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

        if let label = curveDashGapLabel.subviews[val.tag] as? NSTextField {
            label.doubleValue = lim
        }
        view.dashCurve(tag: val.tag, value: lim)
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
        if tag < self.colorPanels.count {
             self.colorPanel = self.colorPanels[tag]
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
    @IBAction func alphaCurve(_ sender: Any) {
        let view = sketchView!
        let val = self.getTagValue(
            sender: sender, limit: {x in x > 1 ? 1 : x < 0 ? 0 : x})
        if val.tag < self.alphaSliders.count {
            self.alphaSliders[val.tag].doubleValue = val.value
        }
        view.alphaCurve(tag: val.tag, value: val.value)
        self.restoreControlFrame(view: view)
    }

    @IBAction func setShadow(_ sender: Any) {
        let view = sketchView!
        let val = self.getTagValue(sender: sender)
        var lim = val.value
        switch val.tag {
        case 0:
            lim = lim < 0 ? 0 : lim
            curveShadowRadius.doubleValue = lim
        case 1:
            curveShadowOffsetX.doubleValue = lim
        case 2:
            curveShadowOffsetY.doubleValue = lim
        default: break
        }
        view.shadowCurve(tag: val.tag, value: lim)
        self.restoreControlFrame(view: view)
    }

    @IBAction func blurCurve(_ sender: Any) {
        let view = sketchView!
        let val = self.getTagValue(
            sender: sender, limit: {x in x < 0 ? 0 : x})
        curveBlur.doubleValue = val.value
        view.blurCurve(value: val.value)
        self.restoreControlFrame(view: view)
    }

//    MARK: Buttons actions
    @IBAction func sendCurve(_ sender: NSButton) {
        sketchView!.sendCurve(tag: sender.tag)
    }

    @IBAction func flipCurve(_ sender: NSButton) {
        sketchView!.flipCurve(tag: sender.tag)
    }

    @IBAction func editCurve(_ sender: NSButton) {
        sketchView!.editCurve(sender: sender)
    }

    @IBAction func groupCurve(_ sender: NSButton) {
        sketchView!.groupCurve(sender: sender)
    }

    @IBAction func lockCurve(_ sender: NSButton) {
        sketchView!.lockCurve(sender: sender)
    }

//    MARK: Menu actions
    @IBAction func copy(_ sender: NSMenuItem) {
        sketchView!.copyCurve(from: sketchView!.selectedCurve)
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
        sketchView!.copyCurve(from: sketchView!.selectedCurve)
        sketchView!.deleteCurve()
    }

    @IBAction func undo(_ sender: NSMenuItem) {
        print("undo")
//        SketchView!.undoCurve()
    }

    @IBAction func redo(_ sender: NSMenuItem) {
        print("redo")
        //        SketchView!.redoCurve()
    }

    @IBAction func delete(_ sender: NSMenuItem) {
        sketchView!.deleteCurve()
    }

    func showFileName() {
        let fileName = sketchView!.sketchName ?? setup.filename
        self.window!.title = fileName
    }

    func clearSketch(view: SketchPad) {
        view.zoomOrigin = CGPoint(x: view.frame.midX,
                                  y: view.frame.midY)
        view.zoomSketch(value: 100)
        if let curve = view.selectedCurve {
            curve.clearControlFrame()
            curve.clearPoints()
        }
        view.clearPathLayer(layer: view.editLayer, path: view.editedPath)
        frameUI.hide()
    }

    @IBAction func newDocument(_ sender: NSMenuItem) {
        self.saveDocument(sender)
    }

    func newSketch() {
        let view = sketchView!
        self.clearSketch(view: view)
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
        if let curve = sketchView!.selectedCurve, curve.edit {
            return
        }
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
            }
        )
    }

    func openPng(filePath: URL) {
        let view = sketchView!
        let image = NSImage(contentsOf: filePath)
        if let wid = image?.size.width, let hei = image?.size.height {

            if view.selectedCurve == nil {
                let topLeft = CGPoint(x: view.sketchPath.bounds.midX - wid/2,
                                      y: view.sketchPath.bounds.midY - hei/2)
                let bottomRight = CGPoint(
                    x: view.sketchPath.bounds.midX + wid/2,
                    y: view.sketchPath.bounds.midY + hei/2)
                view.useTool(view.createRectangle(topLeft: topLeft,
                                                  bottomRight: bottomRight))
                view.newCurve()
                if let curve = view.selectedCurve {
                    view.createControls(curve: curve)
                }
            }

            if let curve = view.selectedCurve {
                curve.alpha = [CGFloat](repeating: 0, count: 7)
                curve.shadow = [CGFloat](repeating: 0, count: 3)
                curve.imageLayer.contents = image
                curve.imageLayer.bounds = curve.canvas.bounds
                curve.imageLayer.position = curve.canvas.position
                self.updateSliders()
            }
        }
    }

    func openSvg(filePath: URL) {
        print("open svg")
    }

    func saveSketch(url: URL, name: String, ext: String) {
        let view = sketchView!
        view.sketchLayer.isHidden = true
        let zoomed = view.zoomed
        let zoomOrigin = view.zoomOrigin

        self.clearSketch(view: view)

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
        view.sketchLayer.isHidden = false
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
