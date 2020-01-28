//
//  Support.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 8/26/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        var cPnt = [CGPoint](repeating: .zero, count: 3)

        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &cPnt)
            switch type {
            case .moveTo:
                path.move(to: cPnt[0])
            case .lineTo:
                path.addLine(to: cPnt[0])
            case .curveTo:
                path.addCurve(to: cPnt[2],
                              control1: cPnt[0],
                              control2: cPnt[1])
            case .closePath:
                path.closeSubpath()
            default:
                break
            }
        }
        return path
    }

    func rectPath(_ path: NSBezierPath,
                  pad: CGFloat = 0) -> CGRect {
        let rect = CGRect(
            x: path.bounds.minX-pad, y: path.bounds.minY-pad,
            width: path.bounds.width+pad * 2,
            height: path.bounds.height+pad * 2)
        return rect
    }

    func copyPath(to path: NSBezierPath, start: Int, final: Int) {
        var cPnt = [CGPoint](repeating: .zero, count: 3)
        let st = start < 0 ? 0 : start
        let fn = final > self.elementCount ? self.elementCount : final
        for i in st..<fn {
            let type = self.element(at: i, associatedPoints: &cPnt)
            switch type {
            case .moveTo:
                path.move(to: cPnt[0])
            case .lineTo:
                path.line(to: cPnt[0])
            case .curveTo:
                path.curve(to: cPnt[2],
                           controlPoint1: cPnt[0],
                           controlPoint2: cPnt[1])
            case .closePath:
                path.close()
            default:
                break
            }
        }
    }

    func removePath(at: Int) -> NSBezierPath {
        let path = NSBezierPath()
        self.copyPath(to: path, start: 0, final: at)
        self.copyPath(to: path, start: at+1,
                      final: self.elementCount)
        return path
    }

    func findPath(pos: CGPoint) -> (index: Int, points: [CGPoint])? {
        var cPnt = [CGPoint](repeating: .zero, count: 3)
        var oldPoint: CGPoint?
        let path = NSBezierPath()
        var res: (index: Int, points: [CGPoint])?
        var area: CGFloat = CGFloat(MAXFLOAT)
        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &cPnt)
            switch type {
            case .moveTo:
                oldPoint = cPnt[0]
            case .lineTo:
                path.removeAllPoints()
                if let mp = oldPoint {
                    path.move(to: mp)
                    path.line(to: cPnt[0])
                    path.close()
                }
                cPnt[1] = cPnt[0]
                cPnt[2] = cPnt[0]

                oldPoint = cPnt[0]

                let rect = self.rectPath(
                    path,
                    pad: setEditor.pathPad)
                if rect.contains(pos) {
                    let ar = rect.width * rect.height
                    if ar < area {
                        area = ar
                        res = (index: i, points: cPnt)
                    }
                }
            case .curveTo:
                path.removeAllPoints()
                if let mp = oldPoint {
                    path.move(to: mp)
                    path.curve(to: cPnt[2],
                               controlPoint1: cPnt[0],
                               controlPoint2: cPnt[1])
                    path.close()
                }
                oldPoint = cPnt[2]
                let rect = self.rectPath(
                    path,
                    pad: setEditor.pathPad)
                if rect.contains(pos) {
                    let ar = rect.width * rect.height
                    if ar < area {
                        area = ar
                        res = (index: i, points: cPnt)
                    }
                }
            case .closePath:
                break
            default:
                break
            }
        }
        return res
    }

    func findPoint(_ at: Int) -> [CGPoint] {
        var cPnt = [CGPoint](repeating: .zero, count: 3)
        self.element(at: at, associatedPoints: &cPnt)
        return cPnt
    }

    func findPoints(_ elementType: NSBezierPath.ElementType) -> [[CGPoint]] {
        var points: [[CGPoint]] = []
        for i in 0 ..< self.elementCount {
            var cPnt = [CGPoint](repeating: .zero, count: 3)
            let type = self.element(at: i, associatedPoints: &cPnt)
            if type == elementType {
                points.append(cPnt)
            }
        }
        return points
    }

    func insertCurve(to pos: CGPoint, at: Int,
                     with points: [CGPoint]) -> NSBezierPath {
        let path = NSBezierPath()
        self.copyPath(to: path, start: 0, final: at)
        path.curve(to: pos, controlPoint1: points[0],
                   controlPoint2: pos)
        path.curve(to: points[2], controlPoint1: points[1],
                   controlPoint2: points[2])
        self.copyPath(to: path, start: at + 1,
                      final: self.elementCount)
        return path
    }

    func placeCurve(at: Int, with points: [CGPoint],
                    replace: Bool = true) -> NSBezierPath {
        let path = NSBezierPath()
        self.copyPath(to: path, start: 0, final: at)
        path.curve(to: points[2], controlPoint1: points[0],
                   controlPoint2: points[1])
        let place = replace ? at : at + 1
        self.copyPath(to: path, start: place, final: self.elementCount)
        return path
    }

    func addPin(pos: CGPoint, size: CGFloat) {
        self.move(to: pos)
        let size50 = size/2
        let moveRect = NSRect(x: pos.x - size50, y: pos.y - size50,
                              width: size, height: size)
        self.appendOval(in: moveRect)
        self.move(to: pos)
    }

    func printPath() {
        var cPnt = [CGPoint](repeating: .zero, count: 3)
        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &cPnt)
            switch type {
            case .moveTo:
                print("move")
            case .lineTo:
                print("line")
            case .curveTo:
                print("curve")
            case .closePath:
                print("close")
            default:
                break
            }
        }
    }

    func pathToString() -> String {
        var stringPath: String = ""
        var cPnt = [CGPoint](repeating: .zero, count: 3)
        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &cPnt)
            let toStr: [String] = cPnt.map {
                String(Double($0.x)) + " " + String(Double($0.y)) }
            let finStr = toStr.joined(separator: " ")
            switch type {
            case .moveTo:
                stringPath += "moveTo "
            case .lineTo:
                stringPath += "lineTo "
            case .curveTo:
                stringPath += "curveTo "
            case .closePath:
                stringPath += "closePath "
            default:
                break
            }
            stringPath += (finStr + "|")
        }
        return stringPath
    }

    func stringToPath(str: String) -> NSBezierPath {
        let path = NSBezierPath()
        var cPnt: [CGPoint] = []
        for line in str.split(separator: "|") {
            let space = line.firstIndex(of: " ")
            if let sp = space {
                let str = line.suffix(from: sp).dropFirst().split(
                    separator: " ")
                let floats = str.map {CGFloat(Double($0) ?? 0.0)}
                cPnt = []
                for i in stride(from: 0, to: floats.count, by: 2) {
                    cPnt.append(CGPoint(x: floats[i], y: floats[i+1]))
                }
                switch line.prefix(upTo: sp) {
                case "moveTo":
                    path.move(to: cPnt[0])
                case "lineTo":
                    path.line(to: cPnt[0])
                case "curveTo":
                    path.curve(to: cPnt[2],
                               controlPoint1: cPnt[0],
                               controlPoint2: cPnt[1])
                case "closePath":
                    path.close()
                default:
                   break
                }
            }
        }

        return path
    }

    func applyTransform(oX: CGFloat, oY: CGFloat, transform: () -> Void) {
        let move = AffineTransform(translationByX: -oX, byY: -oY)
        self.transform(using: move)

        transform()

        let moveorigin = AffineTransform(translationByX: oX, byY: oY)
        self.transform(using: moveorigin)
    }
}

extension NSStackView {
    func isOn(on: Int) {
        func restore(tag: Int,
                     state: inout NSControl.StateValue) {
            if tag == on {
                state = NSControl.StateValue.on
            } else {
                state = NSControl.StateValue.off
            }
        }

        for view in self.subviews {
            if let button = view as? NSButton {
                restore(tag: button.tag,
                        state: &button.state)
            } else if let panel = view as? ColorPanel {
                if let box = panel.subviews.last as? NSBox,
                    let colorbox = box.subviews.last as? ColorBox {
                    restore(tag: colorbox.tag,
                            state: &colorbox.state)
                    colorbox.restore()
                }
            } else if let stack = view as? NSStackView {
                if let button = stack.arrangedSubviews.first as? NSButton {
                restore(tag: button.tag, state: &button.state)
                }
            }
        }
    }

    func setEnabled(tag: Int = -1, bool: Bool) {
        if tag >= 0, self.subviews.count > tag,
            let control = self.subviews[tag] as? NSControl {
            control.isEnabled = bool
        }
    }

    func isEnabled(tag: Int = -1, all: Bool = false) {
        for view in self.subviews {
            if let control = view as? NSControl {
                if control.tag == tag || all {
                    control.isEnabled = true
                } else {
                    control.isEnabled = false
                }

            } else if let box = view as? NSBox {
                if box.subviews.count>1,
                    let clrBox = box.subviews[1] as? ColorBox {
                    if clrBox.tag == tag || all {
                        clrBox.isEnabled = true
                    } else {
                        clrBox.isEnabled = false
                    }
                }
            }
        }
    }
}

extension NSTextField {
    override open var doubleValue: Double {
        didSet {
            if doubleValue > 10 {
                self.stringValue = String(round(doubleValue * 10) / 10)
            } else {
                self.stringValue = String(round(doubleValue * 100) / 100)
            }
        }
    }
}

extension CGPoint {
    func atan2Rad(other: CGPoint) -> CGFloat {
        let wid = self.x - other.x
        let hei = self.y - other.y
        return atan2(hei, wid)
    }

    func normalVector(origin: CGPoint = CGPoint(x: 0, y: 0)) -> CGPoint {
        return CGPoint(x: self.y, y: -self.x).unitVector(origin: origin)
    }

    func unitVector(origin: CGPoint = CGPoint(x: 0, y: 0)) -> CGPoint {
        let mag = magnitude(origin: origin)
        if mag == 0 {
            return origin
        }
        return CGPoint(x: (self.x - origin.x)/mag, y: (self.y-origin.y)/mag)
    }

    func magnitude(origin: CGPoint = CGPoint(x: 0, y: 0)) -> CGFloat {
        let wid = abs(self.x - origin.x)
        let hei = abs(self.y - origin.y)
        return hypot(wid, hei)
    }

    func sameLine(cp1: CGPoint, cp2: CGPoint,
                  limit: CGFloat = 0.05) -> Bool {
        let ang1 = abs(cp1.atan2Rad(other: self))
        let ang2 = abs(cp2.atan2Rad(other: self)) - CGFloat.pi
        if abs(ang1 - abs(ang2)) <= limit {
            return true
        }
        return false
    }
}

extension String {
    func sizeOfString(usingFont font: NSFont) -> CGSize {
        let fontAttributes = [NSAttributedString.Key.font: font]
        return self.size(withAttributes: fontAttributes)
    }

    func emojiToImage(width: CGFloat = 32, height: CGFloat = 32) -> NSImage {
        return NSImage(
            size: NSSize(width: width, height: height),
            flipped: false,
            drawingHandler: { (dstRect: NSRect) -> Bool in
                let font = NSFont.systemFont(ofSize: 24)
                let textAttr = [
                    NSAttributedString.Key.font: font,
                    NSAttributedString.Key.foregroundColor: NSColor.white]
                self.draw(in: dstRect, withAttributes: textAttr)
                return true
        })
    }
}

extension NSImage {
    func rotated(by angle: CGFloat) -> NSImage {
        let img = NSImage(size: self.size, flipped: false,
                          drawingHandler: { (rect) -> Bool in
            let (width, height) = (rect.size.width, rect.size.height)
            let transform = NSAffineTransform()
            transform.translateX(by: width / 2, yBy: height / 2)
            transform.rotate(byRadians: angle)
            transform.translateX(by: -width / 2, yBy: -height / 2)
            transform.concat()
            self.draw(in: rect)
            return true
        })
        img.isTemplate = self.isTemplate
        return img
    }
    func resized(scaleX: CGFloat, scaleY: CGFloat) -> NSImage {
        let img = NSImage(size: self.size, flipped: false,
                          drawingHandler: { (rect) -> Bool in
            let (width, height) = (rect.size.width, rect.size.height)
            let transform = NSAffineTransform()
            transform.translateX(by: width / 2, yBy: height / 2)
            transform.scaleX(by: scaleX, yBy: scaleY)
            transform.translateX(by: -width / 2, yBy: -height / 2)
            transform.concat()
            self.draw(in: rect)
            return true
        })
        img.isTemplate = self.isTemplate
        return img
    }
}

extension CALayer {
    // width not radius
    func collide(pos: CGPoint, radius: CGFloat,
                 circular: Bool = true) -> Bool {
        if circular {
            let dx = pos.x - self.position.x
            let dy = pos.y - self.position.y
            let dist: CGFloat = dx*dx + dy*dy
            if dist < (radius * radius) + 1 {
                 return true
            }
        } else {
            if pos.x >= self.frame.minX-1 && pos.x <= self.frame.maxX+1  &&
                pos.y >= self.frame.minY-1 && pos.y <= self.frame.maxY+1 {
                return true
            }
        }
        return false
    }

    func ciImage(width: Int, height: Int) -> CIImage? {
        let imageRepresentation = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width, pixelsHigh: height,
            bitsPerSample: 8, samplesPerPixel: 4,
            hasAlpha: true, isPlanar: false,
            colorSpaceName: NSColorSpaceName.deviceRGB,
            bytesPerRow: 0, bitsPerPixel: 0)!

        let context = NSGraphicsContext(bitmapImageRep: imageRepresentation)!

        self.render(in: context.cgContext)

        if let image =  CIImage(bitmapImageRep: imageRepresentation) {
            return image
        }
        return nil
    }

    func cgSquareImage(pad: CGFloat) -> CGImage? {
        let maxSide = max(self.bounds.width, self.bounds.height)
        let width = Int(maxSide+pad+1)
        let height = Int(maxSide+pad+1)
        let context = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

        self.render(in: context)
        if let image = context.makeImage() {
            return image
        }
        return nil
    }

    func makeShape(path: NSBezierPath,
                   strokeColor: NSColor?,
                   fillColor: NSColor? = nil,
                   lineWidth: CGFloat = 1.0,
                   dashPattern: [NSNumber]? = nil,
                   lineCap: CAShapeLayerLineCap = .square,
                   lineJoin: CAShapeLayerLineJoin = .miter,
                   actions: [String: CAAction]? = nil) {
        let shape = CAShapeLayer()
        shape.path = path.cgPath

        shape.strokeColor = strokeColor?.cgColor
        shape.fillColor = fillColor?.cgColor
        shape.lineWidth = lineWidth
        shape.lineDashPattern = dashPattern
        shape.lineCap = lineCap
        shape.lineJoin = lineJoin
        shape.actions = actions
        self.addSublayer(shape)
    }

    func makeText(text: String, pos: CGPoint, pad: CGFloat, tag: Int,
                  backgroundColor: NSColor? = nil,
                  foregroundColor: NSColor? = nil) {
        let txt = CATextLayer()
        txt.alignmentMode = .center
        txt.backgroundColor = backgroundColor?.cgColor
        txt.foregroundColor = foregroundColor?.cgColor
        txt.actions = setEditor.disabledActions
        let font = CTFontCreateWithName(
            NSFont.systemFont(
                ofSize: 0, weight: .light).fontName as CFString, 0, nil)
        txt.fontSize = setEditor.rulersFontSize
        txt.font = font
        txt.string = text

        var txtSize = text.sizeOfString(usingFont: font)
        txtSize.height -= pad / 2
        txtSize.width += pad / 2
        var finPos = pos
        if tag==0 {
            finPos.x += pad
            finPos.y += pad
        } else if tag==1 {
            finPos.x -= (txtSize.width + pad)
            finPos.y -= (txtSize.height + pad)
        }

        txt.frame = CGRect(x: finPos.x, y: finPos.y,
                           width: txtSize.width ,
                           height: txtSize.height )

        self.addSublayer(txt)
    }
}

extension CGColor {
    func sRGB(alpha: CGFloat = 1.0) -> CGColor {
        if let color = self.copy(alpha: alpha) {
            return color
        }
        return self
    }
}

extension NSColor {
    func sRGB(alpha: CGFloat = 1.0) -> NSColor {
        guard let color = self.usingColorSpace(NSColorSpace.sRGB) else {

            return NSColor.init(
                srgbRed: 255.0, green: 255.0,
                blue: 255.0, alpha: alpha)
        }
        return NSColor.init(srgbRed: color.redComponent,
                            green: color.greenComponent,
                            blue: color.blueComponent,
                            alpha: alpha)
    }

    var hexStr: String {
        guard let color = usingColorSpace(NSColorSpace.sRGB) else {
            return "FFFFFF"
        }
        let red = Int(round(color.redComponent * 0xFF))
        let green = Int(round(color.greenComponent * 0xFF))
        let blue = Int(round(color.blueComponent * 0xFF))
        let hexString = NSString(format: "%02X%02X%02X", red, green, blue)
        return hexString as String
    }

    convenience init(hex: Int) {
        let components = (
            R: CGFloat((hex >> 16) & 0xff) / 255,
            G: CGFloat((hex >> 08) & 0xff) / 255,
            B: CGFloat((hex >> 00) & 0xff) / 255
        )
        self.init(
            srgbRed: components.R, green: components.G,
            blue: components.B, alpha: 1)
    }
}

extension NSSavePanel {
    func setupPanel(fileName: String) -> NSPopUpButton {
        self.directoryURL = FileManager.default.urls(
            for: .desktopDirectory, in: .userDomainMask).first!

        self.allowedFileTypes = setEditor.fileTypes
        self.allowsOtherFileTypes = false
        self.isExtensionHidden = false
        self.canSelectHiddenExtension = true
        self.canCreateDirectories = true
        self.showsTagField = false

        self.nameFieldStringValue = fileName

        let view = NSStackView()
        view.orientation = .vertical

        let stack = NSStackView()
        stack.orientation = .horizontal

        let popup = NSPopUpButton()
        popup.autoenablesItems = false

        for item in setEditor.fileTypes {
            popup.addItem(withTitle: "\(item.uppercased())")
        }

        popup.selectItem(at: 0)

        let label = NSTextField()
        label.backgroundColor = NSColor.clear
        label.isBordered = false
        label.isEditable = false
        label.isSelectable = false
        label.stringValue = "Format"

        stack.addArrangedSubview(label)
        stack.addArrangedSubview(popup)

        view.addArrangedSubview(stack)

        if let sview = view.superview {
            NSLayoutConstraint.activate([
                view.widthAnchor.constraint(equalTo: sview.widthAnchor),
                stack.centerXAnchor.constraint(equalTo: view.centerXAnchor)
                ])
        }
        self.accessoryView = view
        return popup
    }
}

extension NSOpenPanel {
    func setupPanel() {
        self.allowedFileTypes = setEditor.fileTypes
        self.allowsMultipleSelection = false
        self.canChooseDirectories = false
        self.canCreateDirectories = false
        self.canChooseFiles = true
    }
}

extension NSColorPanel {
    override open func mouseMoved(with event: NSEvent) {
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("saveHistory"), object: nil)
        self.acceptsMouseMovedEvents = false
    }
}
