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
        var points = [CGPoint](repeating: .zero, count: 3)

        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2],
                              control1: points[0],
                              control2: points[1])
            case .closePath:
                path.closeSubpath()
            default:
                break
            }
        }
        return path
    }

    func findPath(pos: NSPoint) -> (index: Int, points: [NSPoint])? {
        var points = [NSPoint](repeating: .zero, count: 3)
        var oldPoint: NSPoint?
        let path = NSBezierPath()
        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:
                oldPoint = points[0]
            case .lineTo:
                path.removeAllPoints()
                if let mp = oldPoint {
                    path.move(to: mp)
                    path.line(to: points[0])
                    path.close()
                }
                oldPoint = points[0]
                if path.contains(pos) {
                    return (index: i, points: points)
                }

            case .curveTo:
                path.removeAllPoints()
                if let mp = oldPoint {
                    path.move(to: mp)
                    path.curve(to: points[2],
                               controlPoint1: points[0],
                               controlPoint2: points[1])
                    path.line(to: mp)
                    path.close()
                }
                oldPoint = points[2]
                if path.contains(pos) {
                    return (index: i, points: points)
                }
            case .closePath:
                break
            default:
                break
            }
        }
        return nil
    }

    func copyPath(to path: NSBezierPath, start: Int, final: Int) {
        var points = [CGPoint](repeating: .zero, count: 3)
        let st = start < 0 ? 0 : start
        let fn = final > self.elementCount ? self.elementCount : final
        for i in st..<fn {
            let type = self.element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.line(to: points[0])
            case .curveTo:
                path.curve(to: points[2],
                           controlPoint1: points[0],
                           controlPoint2: points[1])
            case .closePath:
                path.close()
            default:
                break
            }
        }
    }

    func printPath() {
        var points = [NSPoint](repeating: .zero, count: 3)
        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)
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

}

extension NSStackView {
    func isOn(title: String) {
        func restore(alttitle: String,
                     state: inout NSControl.StateValue) {
            if alttitle == title {
                state = NSControl.StateValue.on
            } else {
                state = NSControl.StateValue.off
            }
        }

        for view in self.subviews {
            if let button = view as? NSButton {
                restore(alttitle: button.alternateTitle,
                        state: &button.state)
            } else if let panel = view as? ColorPanel {
                if let box = panel.subviews.last as? NSBox,
                    let colorbox = box.subviews.last as? ColorBox {

                    restore(alttitle: colorbox.alternateTitle,
                            state: &colorbox.state)
                    colorbox.restore()
                }
            }
        }
    }

    func isEnable(title: String = "", all: Bool = false) {
        for view in self.subviews {
            if let button = view as? NSButton {
                if  button.alternateTitle == title || all {
                    button.isEnabled = true
                } else {
                    button.isEnabled = false
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

extension CALayer {
    // use width not radius
    func collide(origin: CGPoint, width: CGFloat) -> Bool {
        let dx = origin.x - self.position.x
        let dy = origin.y - self.position.y
        let dist: CGFloat = dx*dx + dy*dy
        if dist < width * width {
            return true
        }
        return false
    }

    func ciImage() -> CIImage? {
        let width = Int(self.bounds.width)
        let height = Int(self.bounds.height)
        let imageRepresentation = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
            bitsPerSample: 8, samplesPerPixel: 4,
            hasAlpha: true, isPlanar: false,
            colorSpaceName: NSColorSpaceName.deviceRGB,
            bytesPerRow: 0, bitsPerPixel: 0)!
        imageRepresentation.size = bounds.size

        let context = NSGraphicsContext(bitmapImageRep: imageRepresentation)!
        self.render(in: context.cgContext)

        if let image =  CIImage(bitmapImageRep: imageRepresentation) {
            return image
        }
        return nil
    }

    func cgImage() -> CGImage? {
        let width = Int(self.bounds.width)
        let height = Int(self.bounds.height)
        let canvas = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

        let nsCanvas = NSGraphicsContext(cgContext: canvas,
                                         flipped: true)
        NSGraphicsContext.current = nsCanvas
        self.render(in: canvas)
        NSGraphicsContext.current = nil

        if let image = canvas.makeImage() {
            return image
        }
        return nil
    }

    func makeShape(path: NSBezierPath, color: NSColor, width: CGFloat) {
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.strokeColor = color.cgColor
        shape.lineWidth = width
        self.addSublayer(shape)
    }
}

extension CGColor {
    func sRGB(alpha: CGFloat = 1.0) -> CGColor {
        let color  = self.components

        if let rgba = color, rgba.count == 4 {
            return CGColor.init(red: rgba[0],
                                green: rgba[1],
                                blue: rgba[2],
                                alpha: alpha)
        }
        return self
    }
}

extension NSColor {
    func sRGB(alpha: CGFloat = 1.0) -> NSColor {
        guard let color = self.usingColorSpace(NSColorSpace.extendedSRGB) else {
            return NSColor.init(
                srgbRed: 255.0, green: 255.0,
                blue: 255.0, alpha: alpha)
        }
        return NSColor.init(srgbRed: color.redComponent,
                            green: color.greenComponent,
                            blue: color.blueComponent,
                            alpha: alpha)
    }

    var hexString: String {
        guard let color = usingColorSpace(NSColorSpace.extendedSRGB) else {
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

        self.allowedFileTypes = setup.fileTypes
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

        for item in setup.fileTypes {
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
        self.allowedFileTypes = setup.fileTypes
        self.allowsMultipleSelection = false
        self.canChooseDirectories = false
        self.canCreateDirectories = false
        self.canChooseFiles = true
    }
}
