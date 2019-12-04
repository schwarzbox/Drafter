//
//  ViewController.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 8/8/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

class ViewController: NSViewController,
    NSTableViewDataSource, NSTableViewDelegate {
    var window: NSWindow!
    @IBOutlet weak var sketchView: SketchPad!

    @IBOutlet weak var sketchUI: NSTableView!

    @IBOutlet weak var locationX: NSTextField!
    @IBOutlet weak var locationY: NSTextField!

    @IBOutlet weak var toolUI: NSStackView!
    @IBOutlet weak var frameUI: FrameButtons!
    @IBOutlet weak var fontUI: FontTool!

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
    @IBOutlet weak var curveMiter: ActionSlider!

    @IBOutlet weak var curveDashGap: NSStackView!
    @IBOutlet weak var curveDashGapLabel: NSStackView!
    @IBOutlet weak var curveWindingRule: NSSegmentedControl!
    @IBOutlet weak var curveMaskRule: NSSegmentedControl!

    @IBOutlet weak var curveStrokeColor: ColorPanel!
    @IBOutlet weak var curveFillColor: ColorPanel!
    @IBOutlet weak var curveShadowColor: ColorPanel!
    @IBOutlet weak var curveGradStart: ColorPanel!
    @IBOutlet weak var curveGradMiddle: ColorPanel!
    @IBOutlet weak var curveGradFinal: ColorPanel!

    @IBOutlet weak var curveStrokeOpacity: ActionSlider!
    @IBOutlet weak var curveFillOpacity: ActionSlider!
    @IBOutlet weak var curveShadowOpacity: ActionSlider!
    @IBOutlet weak var curveShadowRadius: ActionSlider!
    @IBOutlet weak var curveShadowOffsetX: ActionSlider!
    @IBOutlet weak var curveShadowOffsetY: ActionSlider!
    @IBOutlet weak var curveGradStOpacity: ActionSlider!
    @IBOutlet weak var curveGradMidOpacity: ActionSlider!
    @IBOutlet weak var curveGradFinOpacity: ActionSlider!

    @IBOutlet weak var curveFilterRadius: ActionSlider!

    var alphaSliders: [ActionSlider] = []
    var colorPanels: [ColorPanel] = []
    var textFields: [NSTextField] = []
    var colorPanel: ColorPanel?
    var savePanel: NSSavePanel?
    var openPanel: NSOpenPanel?
    var saveTool: SaveTool?

    var history: [[Curve]] = [[]]
    var indexHistory: Int = 0

    var selectedSketch: Int = -1

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
        sketchUI.delegate = self
        sketchUI.dataSource = self
        sketchUI.refusesFirstResponder = true
        sketchUI.registerForDraggedTypes([.string])
    }

//    MARK: Keys
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
                view.setTool(tag: tool.tag)
                return true
            } else if event.keyCode >= 123 && event.keyCode <= 126 {
                var dt = CGPoint(x: 0, y: 0)
                switch event.keyCode {
                case 123: dt.x = -view.zoomed
                case 124: dt.x = view.zoomed
                case 125: dt.y = view.zoomed
                case 126: dt.y = -view.zoomed
                default: break
                }
                view.clearPathLayer(layer: view.curveLayer,
                                    path: view.curvedPath)
                view.dragCurve(deltaX: dt.x, deltaY: dt.y)
                return true
            } else if event.keyCode == 36 {
                if let curve = view.selectedCurve, curve.edit {
                    view.editFinished(curve: curve)
                    return true
                } else if let curve = view.selectedCurve,
                    curve.groups.count==1, !curve.text.isEmpty,
                    !curve.canvas.isHidden {
                    view.groups = []
                    view.tool = tools[tools.count-1]
                    view.toolUI?.isOn(on: tools.count-1)
                    fontUI.inputField.stringValue = curve.text
                    if let tool = view.tool as? Text, let dt = curve.textDelta {
                        let pos = CGPoint(x: curve.canvas.bounds.minX-dt.x,
                                          y: curve.canvas.bounds.minY-dt.y)
                        tool.action(pos: pos)
                        curve.canvas.isHidden = true
                        curve.clearControlFrame()
                        return true
                    }
                }
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
        textShadow.shadowColor = setEditor.guiColor
        textShadow.shadowOffset = setEditor.rulersShadow

        locationX.shadow = textShadow
        locationY.shadow = textShadow

        let ui = [toolUI, frameUI, actionUI]
        for view in ui {
            view?.layer = CALayer()
            view?.layer?.backgroundColor = setEditor.guiColor.cgColor
        }

        self.setupZoom()

        curveX.maxValue = setEditor.screenWidth
        curveY.maxValue = setEditor.screenHeight
        curveX.minValue = -setEditor.screenWidth
        curveY.minValue = -setEditor.screenHeight
        curveWid.minValue = setCurve.minResize
        curveHei.minValue = setCurve.minResize
        curveWid.maxValue = setEditor.maxScreenWidth
        curveHei.maxValue = setEditor.maxScreenHeight
        curveWid.doubleValue = setEditor.screenWidth
        curveHei.doubleValue = setEditor.screenHeight
        curveRotate.doubleValue = setCurve.angle
        curveRotate.minValue = setCurve.minRotate
        curveRotate.maxValue = setCurve.maxRotate

        colorPanels = [curveStrokeColor, curveFillColor,
                       curveShadowColor, curveGradStart,
                       curveGradMiddle, curveGradFinal]

        alphaSliders = [curveStrokeOpacity, curveFillOpacity,
                        curveShadowOpacity, curveGradStOpacity,
                        curveGradMidOpacity, curveGradFinOpacity]

        self.setupStroke()
        self.setupColors()
        self.setupAlpha()
        self.setupShadow()
        self.setupFilters()

        ColorPanel.setupSharedColorPanel()
        fontUI.setupFontTool()
        saveTool = SaveTool.init(view: sketchView!)

        self.setupSketchView()

        self.findAllTextFields(root: self.view)

        self.setupObservers()
        self.showFileName()
        self.updateSliders()
    }

    func setupZoom() {
        zoomSketch.minValue = setEditor.minZoom * 2
        zoomSketch.maxValue = setEditor.maxZoom
        zoomDefaultSketch.removeAllItems()
        for step in stride(from: Int(setEditor.minZoom),
                           to: Int(setEditor.maxZoom) + 1,
                           by: Int(setEditor.minZoom)) {
            zoomDefaultSketch.addItem(withTitle: String(step))
        }
        let index100 = zoomDefaultSketch.indexOfItem(withTitle: "100")
        zoomDefaultSketch.select(zoomDefaultSketch.item(at: index100))
        zoomDefaultSketch.setTitle("100")
    }

    func setupStroke() {
        curveWidth.doubleValue = Double(setCurve.lineWidth)
        curveWidth.maxValue = Double(setCurve.maxLineWidth)

        curveCap.selectedSegment = setCurve.lineCap
        curveJoin.selectedSegment = setCurve.lineJoin
        for view in curveDashGap.subviews {
             if let slider = view as? NSSlider {
                 slider.minValue = setCurve.minDash
                 slider.maxValue = setCurve.maxDash
             }
        }
        curveWindingRule.selectedSegment = setCurve.windingRule
        curveMaskRule.selectedSegment = setCurve.maskRule

        curveMiter.doubleValue = Double(setCurve.miterLimit)
        curveMiter.maxValue = Double(setCurve.maxMiter)
    }

    func setupColors() {
        for (i, panel) in self.colorPanels.enumerated() {
            panel.fillColor = setCurve.colors[i]
        }
    }

    func setupAlpha() {
        for (i, slider) in self.alphaSliders.enumerated() {
            slider.maxValue = 1
            slider.minValue = 0
            slider.doubleValue = Double(setCurve.alpha[i])
        }
    }

    func setupShadow() {
        curveShadowRadius.maxValue = setCurve.maxShadowRadius
        curveShadowOffsetX.minValue = -setCurve.maxShadowOffsetX
        curveShadowOffsetY.minValue = -setCurve.maxShadowOffsetY
        curveShadowOffsetX.maxValue = setCurve.maxShadowOffsetX
        curveShadowOffsetY.maxValue = setCurve.maxShadowOffsetY

        let shadow = setCurve.shadow.map {(fl) in Double(fl)}
        curveShadowRadius.doubleValue = shadow[0]
        curveShadowOffsetX.doubleValue = shadow[1]
        curveShadowOffsetY.doubleValue = shadow[2]
    }

    func setupFilters() {
        curveFilterRadius.minValue = setCurve.minFilterRadius
        curveFilterRadius.maxValue = setCurve.maxFilterRadius
    }

    func setupSketchView() {
        sketchView.parent = self
        sketchView.locationX = locationX
        sketchView.locationY = locationY

        sketchView.toolUI = toolUI
        sketchView.frameUI = frameUI
        sketchView.fontUI = fontUI

        sketchView.curveWidth = curveWidth
        sketchView.curveMiter = curveMiter
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

        nc.addObserver(self, selector: #selector(safeQuit),
                        name: Notification.Name("shouldTerminate"),
                        object: nil)

        nc.addObserver(self, selector: #selector(updateSliders),
                             name: Notification.Name("updateSliders"),
                             object: nil)

        nc.addObserver(self, selector: #selector(restoreFrame),
                        name: Notification.Name("restoreFrame"),
                        object: nil)

        nc.addObserver(self, selector: #selector(updateSketchColor),
                       name: Notification.Name("updateSketchColor"),
                       object: nil)
        nc.addObserver(self, selector: #selector(openFiles),
                       name: Notification.Name("openFiles"),
                       object: nil)
        nc.addObserver(self, selector: #selector(saveHistory),
                       name: Notification.Name("saveHistory"),
                       object: nil)

        nc.post(name: Notification.Name("abortTextFields"), object: nil)
    }

    func findAllTextFields(root: NSView) {
        for child in root.subviews {
            if let textField = child as? NSTextField,
                textField.isEditable {
                self.textFields.append(textField)
            } else {
                self.findAllTextFields(root: child)
            }
        }
    }

    @objc func safeQuit() {
        self.saveDocument(self)
    }

    @objc func abortTextFields() {
        for field in self.textFields {
            field.abortEditing()
        }
    }

    @objc func updateSliders() {
        let view = sketchView!
        if let curve = view.selectedCurve, !curve.lock {
            setGlobal.saved = true
            let bounds = view.groups.count>1
               ? curve.groupRect(curves: view.groups, includeStroke: false)
               : curve.groupRect(curves: curve.groups, includeStroke: false)

            self.curveX.doubleValue = Double(bounds.midX)
            self.curveY.doubleValue = Double(bounds.midY)
            self.curveWid.doubleValue = Double(bounds.width)
            self.curveHei.doubleValue = Double(bounds.height)
            let ang = Double(curve.angle).truncatingRemainder(
                dividingBy: Double.pi+0.01)
            self.curveRotate.doubleValue = ang

            if curve.groups.count==1 && view.groups.count <= 1 {
                self.showUnusedViews(true)
            } else {
                self.showUnusedViews(true)
                self.showUnusedViews(false, from: 3)
                return
            }

            self.curveWidth.doubleValue = Double(curve.lineWidth)
            self.curveCap.selectedSegment = curve.cap
            self.curveJoin.selectedSegment = curve.join
            self.curveMiter.doubleValue = Double(curve.miter)

            for i in 0..<curve.dash.count {
                 let value = Double(truncating: curve.dash[i])
                 if let slider = curveDashGap.subviews[i] as? NSSlider {
                     slider.doubleValue = value
                 }
                 if let label = curveDashGapLabel.subviews[i] as? NSTextField {
                     label.doubleValue = value
                 }
            }
            self.curveWindingRule.selectedSegment = curve.windingRule
            self.curveMaskRule.selectedSegment = curve.maskRule

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

            self.curveFilterRadius.doubleValue = Double(curve.filterRadius)

            self.enableMiter(sender: curveJoin)
        } else {
            self.showUnusedViews(false)
            self.curveWid.doubleValue = Double(view.sketchPath.bounds.width)
            self.curveHei.doubleValue = Double(view.sketchPath.bounds.height)
        }
    }

    func showUnusedViews(_ bool: Bool, from: Int = 2) {
        for index in from..<actionUI.subviews.count-1 {
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

    func enableMiter(sender: NSSegmentedControl) {
        if let stack = actionUI.subviews[4] as? NSStackView {
            if let view = stack.subviews[3] as? ActionSlider {
                if sender.indexOfSelectedItem == 0 {
                    view.isEnabled(all: true)
                } else {
                    view.isEnabled(all: false)
                }
            }
        }
    }

//    MARK: sketchUI func
    func moveToZero(curve: Curve, action: () -> NSImage?) -> NSImage? {
        var image: NSImage?
        let line50 = curve.lineWidth / 2
        var oX = curve.canvas.bounds.minX - line50
        var oY = curve.canvas.bounds.minY - line50
        if curve.canvas.bounds.width > curve.canvas.bounds.height {
            oY -= (curve.canvas.bounds.width-curve.canvas.bounds.height)/2
        } else {
            oX -= (curve.canvas.bounds.height-curve.canvas.bounds.width)/2
        }
        curve.path.applyTransform(oX: oX, oY: oY,
            transform: {
                curve.updateLayer()
                image = action()
        })
        curve.updateLayer()

        return image
    }

    func getImage(index: Int, curve: Curve) -> NSImage? {
        let oldLineWidth = curve.lineWidth
        let side = max(curve.canvas.bounds.width,
                       curve.canvas.bounds.height)
        let size = setEditor.stackButtonSize.width
        let delta = size * (side/(size * 50))
        curve.lineWidth *= delta
        return self.moveToZero(curve: curve, action: {
            if let img = curve.canvas.cgSquareImage(pad: curve.lineWidth) {
                curve.lineWidth = oldLineWidth
                return NSImage(cgImage: img,
                               size: setEditor.stackButtonSize)
            }
            curve.lineWidth = oldLineWidth
            return nil})
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return sketchView!.curves.count
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        selectedSketch = sketchUI.selectedRow
        sketchView!.selectSketch(tag: selectedSketch)
        self.saveHistory()
    }

    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var image: NSImage?
        var text: String = ""
        var cellID = NSUserInterfaceItemIdentifier.init("shapeID")

        let view = sketchView!
        guard row>=0 && row < view.curves.count else {
            return nil
        }
        let curve = sketchView!.curves[row]
        if tableColumn == tableView.tableColumns[0] {
            if curve.canvas.isHidden {
                curve.canvas.isHidden = false
                image = self.getImage(index: row, curve: curve)
                curve.canvas.isHidden = true
            } else if curve.groups.count>1 {
                let img = NSImage.iconViewTemplateName
                image = NSImage.init(imageLiteralResourceName: img)
            } else if curve.mask {
                image = setEditor.maskGrayImg
            } else {
                image = self.getImage(index: row, curve: curve)
            }
            text = curve.name
            cellID = NSUserInterfaceItemIdentifier.init("shapeID")
        }

        if let cell = tableView.makeView(withIdentifier: cellID,
                                         owner: nil) as? NSTableCellView {
            cell.textField?.tag = row
            cell.textField?.stringValue = text
            cell.textField?.backgroundColor = NSColor.clear
            cell.textField?.textColor = NSColor.secondaryLabelColor

            if row == selectedSketch {
                cell.textField?.backgroundColor = setEditor.fillColor
            }

            if let editButton = cell.subviews[0] as? NSButton {
                editButton.tag = row
                editButton.image = image ?? nil
                editButton.isEnabled = curve.edit ? false : true
            }

            if let visButton = cell.subviews[2] as? NSButton {
                visButton.tag = row
                visButton.isEnabled = curve.edit ? false : true
                visButton.state = curve.canvas.isHidden ? .off : .on
            }
            if let lockButton = cell.subviews[3] as? NSButton {
                lockButton.tag = row
                lockButton.isEnabled = curve.edit ? false : true
                if curve.lock {
                    lockButton.image = setEditor.lockImg
                    lockButton.state = .on
                } else {
                    lockButton.image = setEditor.unlockImg
                    lockButton.state = .off
                }
            }
            return cell
        }
        return nil
    }

    func tableView (
        _ tableView: NSTableView,
        pasteboardWriterForRow row: Int)
        -> NSPasteboardWriting? {
        return String(row) as NSString
    }

    func tableView(
        _ tableView: NSTableView,
        validateDrop info: NSDraggingInfo,
        proposedRow row: Int,
        proposedDropOperation dropOperation: NSTableView.DropOperation)
        -> NSDragOperation {
        guard dropOperation == .on else { return [] }
        return .move
    }

    func tableView (
        _ tableView: NSTableView,
        acceptDrop info: NSDraggingInfo,
        row: Int,
        dropOperation: NSTableView.DropOperation) -> Bool {
        let view = sketchView!
        guard let items = info.draggingPasteboard.pasteboardItems
            else { return false }
        let index = Int(items[0].string(forType: .string) ?? "0") ?? 0

        let curve = view.curves[index]
        let tag = index>row ? 0 : 1
        let dist = abs(row-index)
        for _ in 0..<dist {
            view.sendCurve(curve: curve, tag: tag)
        }
        self.saveHistory()
        return true
    }

//    MARK: SketchUI Actions
    @IBAction func editSketch(_ sender: NSButton) {
        if sender.tag<sketchUI.subviews.count {
            if let row = sketchUI.subviews[sender.tag] as? NSTableRowView,
                let cell = row.subviews.last as? NSTableCellView {
                if let textField = cell.subviews[1] as? NSTextField {
                    textField.selectText(textField)
                }
            }
        }
    }

    @IBAction func visibleSketch(_ sender: NSButton) {
        sketchView!.visibleSketch(sender: sender)
        self.saveHistory()
    }

    @IBAction func renameSketch(_ sender: NSTextField) {
        sketchView!.curves[sender.tag].name = sender.stringValue
        self.saveHistory()
    }

//    MARK: Zoom Actions
    @IBAction func zoomGesture(_ sender: NSMagnificationGestureRecognizer) {
        let view = sketchView!
        let zoomed = Double(view.zoomed)
        let mag = Double(sender.magnification / setEditor.reduceZoom)
        var zoom = (zoomed + mag) * 100

        if zoom < setEditor.minZoom * 2 || zoom > setEditor.maxZoom {
            zoom = zoomed * 100
        }
        view.zoomSketch(value: zoom)
        zoomSketch.doubleValue = zoom
        zoomDefaultSketch.title = String(Int(zoom))
        fontUI.setupFont()
    }

    @IBAction func zoomSketch(_ sender: NSSlider) {
        let view = sketchView!
        view.zoomOrigin = CGPoint(x: view.sketchPath.bounds.midX,
                                  y: view.sketchPath.bounds.midY)
        view.zoomSketch(value: sender.doubleValue)
        zoomDefaultSketch.title = String(sender.intValue)
        fontUI.setupFont()
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
            fontUI.setupFont()
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

    @objc func restoreFrame() {
        let view = sketchView!
        if let curve = view.selectedCurve,
            curve.controlFrame==nil,
            !curve.canvas.isHidden,
            !curve.lock {
            curve.reset()
            view.createControls(curve: curve)
        }
        for cur in view.groups {
            view.curvedPath.append(cur.path)
        }
    }

    func restoreControlFrame(view: SketchPad) {
        if NSEvent.pressedMouseButtons == 0 {
            self.restoreFrame()
            self.saveHistory()
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
            sender: sender, limit: {x in x <= 0 ? setCurve.minResize : x})
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
        let minR = setCurve.minRotate
        let maxR = setCurve.maxRotate
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

        self.saveHistory()
    }

    @IBAction func joinCurve(_ sender: NSSegmentedControl) {
        sketchView!.joinCurve(value: sender.indexOfSelectedItem)
        self.enableMiter(sender: sender)
        self.saveHistory()
    }

    @IBAction func miterCurve(_ sender: Any) {
        let view = sketchView!
        let val = self.getTagValue(
            sender: sender, limit: {x in x < 0 ? 0 : x})

        self.curveMiter.doubleValue = val.value
        view.miterCurve(value: val.value)
        self.restoreControlFrame(view: view)
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

    @IBAction func windingCurve(_ sender: NSSegmentedControl) {
        sketchView!.windingCurve(value: sender.indexOfSelectedItem)
        self.saveHistory()
    }

    @IBAction func maskRuleCurve(_ sender: NSSegmentedControl) {
        sketchView!.maskRuleCurve(value: sender.indexOfSelectedItem)
        self.saveHistory()
    }

//    MARK: TextTool action
    @IBAction func glyphsCurve(_ sender: NSTextField) {
        sketchView!.glyphsCurve(value: sender.stringValue,
                                sharedFont: fontUI.sharedFont)
        sender.stringValue = "Text"
        self.saveHistory()
    }

//    MARK: ColorPanel actions
    @objc func updateSketchColor() {
        let view = sketchView!
        if let panel = self.colorPanel,
            let cp = panel.sharedColorPanel {
            cp.acceptsMouseMovedEvents = true
            if let curve = view.selectedCurve {
                view.clearControls(curve: curve)
            }
        }
        view.colorCurve()
    }
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

    @IBAction func filterRadius(_ sender: Any) {
        let view = sketchView!
        let val = self.getTagValue(
            sender: sender, limit: {x in x < 0 ? 0 : x})
        curveFilterRadius.doubleValue = val.value
        view.filterRadius(value: val.value)
        self.restoreControlFrame(view: view)
    }

//    MARK: Buttons actions
    @IBAction func sendCurve(_ sender: NSButton) {
        if let curve = sketchView!.selectedCurve {
            sketchView!.sendCurve(curve: curve, tag: sender.tag)
            self.saveHistory()
        }
    }

    @IBAction func flipCurve(_ sender: NSButton) {
        sketchView!.flipCurve(tag: sender.tag)
        self.saveHistory()
    }

    @IBAction func maskCurve(_ sender: NSButton) {
        sketchView!.maskCurve(sender: sender)
        self.saveHistory()
    }

    @IBAction func groupCurve(_ sender: Any) {
        sketchView!.groupCurve(sender: sender)
        self.saveHistory()
    }

    @IBAction func ungroup(_ sender: NSMenuItem) {
        sketchView!.groupCurve(sender: sender)
        self.saveHistory()
    }

    @IBAction func editCurve(_ sender: NSButton) {
        sketchView!.editCurve(sender: sender)
        self.saveHistory()
    }

    @IBAction func lockCurve(_ sender: NSButton) {
        sketchView!.lockCurve(sender: sender)
        self.saveHistory()
    }

//    MARK: History
    func clearHistory() {
        self.history = [[]]
        self.indexHistory = self.history.count-1
    }

    @objc func saveHistory() {
        let view = sketchView!
        self.history[self.indexHistory+1..<self.history.count] = []
        self.history.append(view.copyAll())
        self.indexHistory = self.history.count-1
        self.updateStack()
    }

//    MARK: Menu actions
    func updateStack() {
        sketchUI.reloadData()
        if let curve = sketchView!.selectedCurve,
            let index = sketchView!.curves.firstIndex(of: curve) {
            selectedSketch = index
        } else {
            selectedSketch = -1
        }
    }
    func restoreStack(history: () -> Void) {
        let view = sketchView!
        if let curve = view.selectedCurve {
            view.clearControls(curve: curve)
            if curve.edit {
                curve.clearPoints()
            }
            view.selectedCurve = nil
        }

        view.groups = []
        view.removeAllCurves()

        history()

        view.clearCurvedPath()
        view.curves = self.history[self.indexHistory]
        view.curves = view.copyAll()
        view.addAllLayers()
        for cur in view.curves {
            if cur.controlFrame != nil {
                view.createControls(curve: cur)
                view.selectedCurve = cur
                break
            }
            if cur.edit {
                view.editStarted(curve: cur)
                view.selectedCurve = cur
                break
            }
        }

        view.updateMasks()
        view.needsDisplay = true
        self.updateStack()
        self.updateSliders()
    }
    @IBAction func undoStack(_ sender: Any) {
        if let resp = self.window.firstResponder,
            resp.isKind(of: NSWindow.self) {
            self.restoreStack {
                if self.indexHistory-1 >= 0 {
                    self.indexHistory-=1
                }
            }
//            print("undo", self.indexHistory, self.history)
        }
    }

    @IBAction func redoStack(_ sender: Any) {
        if let resp = self.window.firstResponder,
            resp.isKind(of: NSWindow.self) {
            self.restoreStack {
                if self.indexHistory+1 < self.history.count {
                    self.indexHistory+=1
                }
            }
//            print("redo", self.indexHistory, self.history)
        }
    }

    @IBAction func cut(_ sender: NSMenuItem) {
        let view = sketchView!
        view.copyCurve(from: sketchView!.selectedCurve)
        view.deleteCurve()
        self.saveHistory()
    }

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
        self.saveHistory()
    }

    @IBAction override func selectAll(_ sender: Any?) {
        let view = sketchView!
        if let resp = self.window.firstResponder,
            resp.isKind(of: NSWindow.self) {
            view.groups = []
            for curve in view.curves {
                view.groups.append(contentsOf: curve.groups)
            }
            if let curve = view.selectedCurve {
                view.clearControls(curve: curve)
            }
            if view.groups.count>0 {
                view.selectedCurve = view.groups[0]
                view.createControls(curve: view.groups[0])
            }
            view.showGroup()
        } else {
            super.selectAll(sender)
        }
    }

    @IBAction func delete(_ sender: NSMenuItem) {
        sketchView!.deleteCurve()
        self.saveHistory()
    }

    func showFileName() {
        let fileName = sketchView!.sketchName ?? setEditor.filename
        self.window!.title = fileName
    }

    func clearSketch(view: SketchPad) {
        view.zoomOrigin = CGPoint(x: setEditor.screenWidth/2,
                                  y: setEditor.screenHeight/2)
        view.zoomSketch(value: 100)
        if let curve = view.selectedCurve {
            curve.clearControlFrame()
            curve.clearPoints()
        }
        view.clearCurvedPath()
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

        view.removeAllCurves()

        fontUI.inputField.hide()

        self.clearHistory()
        self.updateStack()
        self.updateSliders()
        setGlobal.saved = false
    }

    @objc func openFiles(notification: NSNotification) {
        let view = sketchView!
        if let curve = view.selectedCurve, curve.edit {
            return
        }
        if let fileUrl = notification.userInfo!["fileUrl"] as? URL {
            let ext = fileUrl.pathExtension
            switch ext {
            case "bundle":
                self.saveTool?.openDrf(fileUrl: fileUrl)
            case "svg":
                self.saveTool?.openSvg(fileUrl: fileUrl)
            default:
                self.saveTool?.openPng(fileUrl: fileUrl)
            }
            view.updateMasks()
            self.saveHistory()
            setGlobal.saved = false
        }
    }

    @IBAction func openDocument(_ sender: NSMenuItem) {
        let view = sketchView!
        if let curve = view.selectedCurve, curve.edit {
            return
        }
        self.colorPanel?.closeSharedColorPanel()
        openPanel = NSOpenPanel()
        if let openPanel = openPanel {
            openPanel.setupPanel()
            openPanel.beginSheetModal(
                for: self.window!,
                completionHandler: {(result) -> Void in
                    if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                        if openPanel.urls.count>0 {
                            let nc = NotificationCenter.default
                            nc.post(name: Notification.Name("openFiles"),
                                    object: nil,
                                    userInfo: ["fileUrl": openPanel.urls[0]])
                        }
                    } else {
                        openPanel.close()
                    }
                }
            )
        }
    }

    func saveSketch(url: URL, name: String, ext: String) {
        let view = sketchView!
        view.sketchLayer.isHidden = true
        let zoomed = view.zoomed
        let zoomOrigin = view.zoomOrigin

        self.clearSketch(view: view)

        switch ext {
        case "bundle":
            let dirUrl = url.appendingPathComponent(
                name + ".bundle", isDirectory: true)
            do {
                try FileManager.default.createDirectory(
                    atPath: dirUrl.relativePath,
                    withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
            }
            let fileUrl = dirUrl.appendingPathComponent(name + ".drf")
            for curve in view.curves {
                for cur in curve.groups
                    where cur.imageLayer.contents != nil {
                    if let img = cur.imageLayer.contents as? NSImage {
                        do {
                            let fileUrl = dirUrl.appendingPathComponent(
                                cur.name + ".tiff")
                            try img.tiffRepresentation?.write(to: fileUrl)
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
            }
            saveTool?.saveDrf(fileUrl: fileUrl)
        case "svg":
            let fileUrl = url.appendingPathComponent(name + "." + ext)
            saveTool?.saveSvg(fileUrl: fileUrl)
        default:
            let fileUrl = url.appendingPathComponent(name + "." + ext)
            saveTool?.savePng(fileUrl: fileUrl)
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
        setGlobal.saved = false
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

    @IBAction func saveDocument(_ sender: Any) {
        let view = sketchView!
        if let name = view.sketchName,
            let dir = view.sketchDir,
            let ext = view.sketchExt {
            self.saveSketch(url: dir, name: name, ext: ext)
            if let sen = sender as? NSMenuItem, sen.title == "New" {
                self.newSketch()
                self.showFileName()
            }
            NSApplication.shared.reply(
            toApplicationShouldTerminate: true)
        } else {
            self.saveDocumentAs(sender)
        }
    }

    @IBAction func saveDocumentAs(_ sender: Any) {
        let view = sketchView!
        self.colorPanel?.closeSharedColorPanel()
        savePanel = NSSavePanel()
        if let savePanel = savePanel {
            let popup = savePanel.setupPanel(fileName: setEditor.filename)
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
                        if trimName != setEditor.filename {
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
                    if let sen = sender as? NSMenuItem, sen.title == "New" {
                        self.newSketch()
                    }
                    self.showFileName()
                    NSApplication.shared.reply(
                    toApplicationShouldTerminate: true)
            })
        }
    }
}
