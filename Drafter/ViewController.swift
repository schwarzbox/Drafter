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

    var history: [[Curve]] = [[]]
    var indexHistory: Int = 0
//    var maxHistory: Int = 60

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
                view.tool = tool
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
            } else if event.keyCode == 36 {
                if let curve = view.selectedCurve, curve.edit {
                    view.editFinished(curve: curve)
                    return true
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
                        curveGradMidOpacity, curveGradFinOpacity,
                        curveFilterOpacity]

        self.setupStroke()
        self.setupColors()
        self.setupAlpha()
        self.setupShadow()

        curveBlur.minValue = setCurve.minBlur
        curveBlur.maxValue = setCurve.maxBlur

        ColorPanel.setupSharedColorPanel()

        self.setupSketchView()
        textUI!.setupTextTool()

        self.findAllTextFields(root: self.view)

        self.setupObservers()
        self.showFileName()
        self.updateSliders()
    }

    func setupZoom() {
        zoomSketch.minValue = setEditor.minZoom * 2
        zoomSketch.maxValue = setEditor.maxZoom
        zoomDefaultSketch.removeAllItems()
        var zoom: [String] = []
        for step in stride(from: Int(setEditor.minZoom),
                           to: Int(setEditor.maxZoom) + 1,
                           by: Int(setEditor.minZoom)) {
            zoom.append(String(step))
        }
        zoomDefaultSketch.addItems(withTitles: zoom)
        let index100 = zoomDefaultSketch.indexOfItem(withTitle: "100")
        zoomDefaultSketch.select(zoomDefaultSketch.item(at: index100))
        zoomDefaultSketch.setTitle("100")
    }

    func setupStroke() {
        curveWidth.doubleValue = Double(setCurve.lineWidth)
        curveWidth.maxValue = Double(setCurve.maxLineWidth)

         for view in curveDashGap.subviews {
             if let slider = view as? NSSlider {
                 slider.minValue = setCurve.minDash
                 slider.maxValue = setCurve.maxDash
             }
         }
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

    func setupSketchView() {
        sketchView.parent = self
        sketchView.locationX = locationX
        sketchView.locationY = locationY

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
        nc.addObserver(self, selector: #selector(updateStack),
                       name: Notification.Name("updateStack"),
                       object: nil)
        nc.addObserver(self, selector: #selector(safeQuit),
                       name: Notification.Name("shouldTerminate"),
                       object: nil)
        nc.addObserver(self, selector: #selector(saveHistory),
                       name: Notification.Name("saveHistory"),
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
        self.updateStack()
    }

    @objc func updateSliders() {
        let view = sketchView!
        defer {self.updateStack()}
        if let curve = view.selectedCurve, !curve.lock {
            setGlobal.saved = true
            let bounds = view.groups.count>1
               ? curve.groupRect(curves: view.groups, includeStroke: false)
               : curve.groupRect(curves: curve.groups, includeStroke: false)

            self.curveX.doubleValue = Double(bounds.midX)
            self.curveY.doubleValue = Double(bounds.midY)
            self.curveWid.doubleValue = Double(bounds.width)
            self.curveHei.doubleValue = Double(bounds.height)
            self.curveRotate.doubleValue = Double(curve.angle)

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

    @objc func updateStack() {
        sketchUI.reloadData()
        if let curve = sketchView!.selectedCurve,
            let index = sketchView!.curves.firstIndex(of: curve) {
            selectedSketch = index
        } else {
            selectedSketch = -1
        }
    }

    @objc func safeQuit() {
        self.saveDocument(self)
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
        curve.applyTransform(oX: oX, oY: oY,
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
            if let img = curve.canvas.cgImage(pad: curve.lineWidth) {
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
        sketchUI.reloadData()

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
    }

    @IBAction func renameSketch(_ sender: NSTextField) {
        sketchView!.curves[sender.tag].name = sender.stringValue
        sketchUI.reloadData()
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
            for cur in view.groups {
                view.curvedPath.append(cur.path)
            }
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
        if let curve = sketchView!.selectedCurve {
            sketchView!.sendCurve(curve: curve, tag: sender.tag)
        }
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

//    MARK: History
    @objc func saveHistory() {
        let view = sketchView!
        self.history.replaceSubrange(
        self.indexHistory+1..<self.history.count, with: [])

        self.history.append(view.copyAll())
        self.indexHistory = self.history.count-1
        print(self.history)
        print(self.indexHistory, self.history.count)
        self.undoManager?.registerUndo(
            withTarget: self,
            selector: #selector(self.undo),
            object: view.curves)
    }

//    MARK: Menu actions
    @IBAction func undo(_ sender: NSMenuItem) {
        let view = sketchView!

        if let curve = view.selectedCurve {
            curve.clearControlFrame()
            curve.clearPoints()
            view.selectedCurve = nil
        }
        view.groups = []
        view.removeAllCurves()

        if self.indexHistory-1 >= 0 {
            self.indexHistory-=1
        }
        view.curves = self.history[self.indexHistory]
        view.addAll()

        print("undo", self.indexHistory, self.history.count)

        self.updateStack()

        self.undoManager?.registerUndo(
            withTarget: self,
            selector: #selector(self.redo),
            object: view.curves)
    }

    @IBAction func redo(_ sender: NSMenuItem) {
        let view = sketchView!

        if let curve = view.selectedCurve {
            curve.clearControlFrame()
            curve.clearPoints()
            view.selectedCurve = nil
        }
        view.groups = []
        view.removeAllCurves()

        if self.indexHistory+1 < self.history.count {
            self.indexHistory+=1
        }
        view.curves = self.history[self.indexHistory]
        view.addAll()
        print("redo", self.indexHistory, self.history.count)
        self.updateStack()

        self.undoManager?.registerUndo(
            withTarget: self,
            selector: #selector(self.undo),
            object: view.curves)
    }

    @IBAction func cut(_ sender: NSMenuItem) {
        sketchView!.copyCurve(from: sketchView!.selectedCurve)
        sketchView!.deleteCurve()
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
    }

    @IBAction func group(_ sender: NSMenuItem) {
        sketchView!.groupCurve(sender: sender)
    }

    @IBAction func ungroup(_ sender: NSMenuItem) {
        sketchView!.groupCurve(sender: sender)
    }

    @IBAction override func selectAll(_ sender: Any?) {
        let view = sketchView!
        if let resp = self.window.firstResponder,
            resp.isKind(of: NSWindow.self) {
            view.groups = view.curves
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

        view.removeAllCurves()

        textUI.hide()
        self.updateSliders()
        setGlobal.saved = false
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
                        switch ext {
                        case "drf": self.openDrf(filePath: filePath)
                        case "svg": self.openSvg(filePath: filePath)
                        default:
                            self.openPng(filePath: filePath)
                        }
                    }
                } else {
                    openPanel.close()
                }
            }
        )
        setGlobal.saved = false
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
                if let rect = tools[3] as? Rectangle {
                    rect.useTool(
                        rect.action(topLeft: topLeft,
                                    bottomRight: bottomRight))
                }
                view.newCurve()
                if let curve = view.selectedCurve {
                    view.createControls(curve: curve)
                }
            }

            if let curve = view.selectedCurve {
                curve.alpha = [CGFloat](repeating: 0, count: 7)
                curve.imageLayer.contents = image
//                curve.filterLayer.contents = image
                curve.imageLayer.bounds = curve.canvas.bounds
                curve.imageLayer.position = curve.canvas.position

                curve.setName(name: "image", curves: view.curves)
                self.updateSliders()
            }
        }
    }

    func openDrf(filePath: URL) {
        let view = sketchView!
        var drf = Drf()
        do {
            let file = try String(contentsOf: filePath, encoding: .utf8)
            var groups: [Curve] = []
            defer {
                groups[0].setGroups(curves: Array(groups.dropFirst()))
            }
            for line in file.split(separator: "\n") {
                if line == "-" {
                    let curve = self.openCurve(drf: drf)
                    if drf.group {
                        groups.append(curve)
                    } else {
                        if groups.count>0 {
                            groups[0].setGroups(
                                curves: Array(groups.dropFirst()))
                            groups.removeAll()
                        }
                        groups.append(curve)
                        view.addCurve(curve: curve)
                    }
                    drf = Drf()
                }
                self.parseLine(drf: &drf, line: String(line))
            }
        } catch {
           print("error open \(filePath)")
        }
        self.updateStack()
    }

    func openCurve(drf: Drf) -> Curve {
        let view = sketchView!
        let curve = view.initCurve(
            path: drf.path, fill: drf.fill, rounded: drf.rounded,
            angle: CGFloat(drf.angle),
            lineWidth: drf.lineWidth,
            cap: drf.cap, join: drf.join,
            dash: drf.dash,
            alpha: drf.alpha,
            shadow: drf.shadow,
            gradientDirection: drf.gradientDirection,
            gradientLocation: drf.gradientLocation,
            colors: drf.colors,
            blur: drf.blur,
            points: drf.points)
        let name = String(drf.name.split(separator: " ")[0])
        curve.setName(name: name, curves: view.curves)
        view.layer?.addSublayer(curve.canvas)
        return curve
    }

    func parseLine(drf: inout Drf, line: String) {
        let view = sketchView!
        if let sp = line.firstIndex(of: " ") {
            let str = String(line.suffix(from: sp).dropFirst())
            switch line.prefix(upTo: sp) {
            case "-name": drf.name = str
            case "-oldName": drf.oldName = str
            case "-path": drf.path = drf.path.stringToPath(str: str)
            case "-points":
                var points: [ControlPoint] = []
                for line in str.split(separator: "|") {
                    let floats = line.split(separator: " ").map {
                        CGFloat(Double($0) ?? 0.0)}
                    var pnt: [CGPoint] = []
                    for i in stride(from: 0, to: floats.count, by: 2) {
                        pnt.append(CGPoint(x: floats[i],
                                           y: floats[i+1]))
                    }
                    points.append(ControlPoint(view,
                                               cp1: pnt[0],
                                               cp2: pnt[1],
                                               mp: pnt[2]))
                }
                drf.points = points
            case "-fill": drf.fill = Bool(str) ?? true
            case "-rounded":
                if !str.isEmpty {
                    let float = str.split(separator: " ")
                    drf.rounded = CGPoint(
                        x: CGFloat(Double(float[0]) ?? 0.0),
                        y: CGFloat(Double(float[1]) ?? 0.0))
                }
            case "-angle": drf.angle = Double(str) ?? 0.0
            case "-lineWidth":
                drf.lineWidth = CGFloat(Double(str) ?? 0.0)
            case "-cap": drf.cap = Int(str) ?? 0
            case "-join": drf.join = Int(str) ?? 0
            case "-dash":
                let dash = str.split(separator: " ").map {
                    NSNumber(value: Int($0) ?? 0)}
                drf.dash = dash
            case "-alpha":
                drf.alpha = str.split(separator: " ").map {
                    CGFloat(Double($0) ?? 0.0)}
            case "-shadow":
                drf.shadow = str.split(separator: " ").map {
                    CGFloat(Double($0) ?? 0.0)}
            case "-gradientDirection":
                let dir = str.split(separator: " ").map {
                    CGFloat(Double($0) ?? 0.0)}
                drf.gradientDirection = [CGPoint(x: dir[0], y: dir[1]),
                                         CGPoint(x: dir[2], y: dir[3])]
            case "-gradientLocation":
                drf.gradientLocation = str.split(separator: " ").map {
                    NSNumber(value: Double(String($0)) ?? 0) }
            case "-colors":
                let cmp = str.split(separator: " ").map {
                    CGFloat(Double($0) ?? 0.0)}
                var colors: [NSColor] = []
                for i in stride(from: 0, to: cmp.count, by: 3) {
                    let clr = NSColor(
                        red: cmp[i], green: cmp[i+1], blue: cmp[i+2],
                        alpha: 1)
                    colors.append(clr.sRGB())
                }
                drf.colors = colors
            case "-blur": drf.blur = Double(str) ?? 0.0
            case "-group": drf.group = true
            default: break
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

        switch ext {
        case "drf": self.saveDrf(filePath: filePath)
        case "svg": self.saveSvg(filePath: filePath)
        default:
            self.savePng(filePath: filePath)
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

    func savePng(filePath: URL) {
        let view = sketchView!
        if let image = view.imageData() {
            do {
                try image.write(to: filePath, options: .atomic)

            } catch {
                print("error save \(filePath)")
            }
        }
    }

    func saveDrf(filePath: URL) {
        let view = sketchView!
        var code: String = ""
        for curve in view.curves {
            for (ind, cur) in curve.groups.enumerated() {
                code += ("-name " + cur.name + "\n")
                code += ("-oldName " + cur.oldName + "\n")
                if let path = cur.path.copy() as? NSBezierPath {
                    code += "-path " + path.pathToString() + "\n"
                    code += "-points "
                    for point in cur.points {
                        code += point.stringPoint() + "|"
                    }
                }
                code += "\n"
                code += "-fill " + String(cur.fill) + "\n"
                code += "-rounded "
                let rounded = cur.rounded != nil
                    ? (String(Double(cur.rounded?.x ?? 0)) + " " +
                        String(Double(cur.rounded?.y ?? 0))) + "\n"
                    : "\n"
                code += rounded
                code += "-angle " + String(Double(cur.angle)) + "\n"
                code += "-lineWidth " + String(Double(cur.lineWidth)) + "\n"
                code += "-cap " + String(cur.cap) + "\n"
                code += "-join " + String(cur.join) + "\n"
                code += "-dash "
                let dash = cur.dash.map {String(
                    Int(truncating: $0))}.joined(separator: " ")
                code += dash + "\n"
                code += "-alpha "
                let alpha = cur.alpha.map {String(
                    Double($0))}.joined(separator: " ")
                code += alpha + "\n"
                code += "-shadow "
                let shadow = cur.shadow.map {String(
                    Double($0))}.joined(separator: " ")
                code += shadow + "\n"
                code += "-gradientDirection "
                let gradDir = cur.gradientDirection.map {(String(
                    Double($0.x)) + " " + String(
                        Double($0.y)) )}.joined(separator: " ")
                code += gradDir + "\n"
                code += "-gradientLocation "
                let gradLoc = cur.gradientLocation.map {String(
                    Double(truncating: $0))}.joined(separator: " ")
                code += gradLoc + "\n"
                code += "-colors "
                let clr = cur.colors.map {
                    String(Double($0.redComponent)) + " " +
                    String(Double($0.greenComponent)) + " " +
                    String(Double($0.blueComponent))
                }.joined(separator: " ")
                code += clr + "\n"
                code += "-blur " + String(Double(cur.blur)) + "\n"
                if ind > 0 {
                    code += "-group \n"
                }
                code += "-\n"
            }
        }
        do {
            try code.write(to: filePath, atomically: false, encoding: .utf8)
        } catch {
            print("error save \(filePath)")
        }
    }

    func saveSvg(filePath: URL) {
        let view = sketchView!
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
