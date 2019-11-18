//
//  Setup.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 9/10/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

struct Drf {
    var path = NSBezierPath()
    var fill: Bool = true
    var rounded: CGPoint?
    var angle: Double = setCurve.angle
    var lineWidth: CGFloat = setCurve.lineWidth
    var cap: Int = setCurve.lineCap
    var join: Int = setCurve.lineJoin
    var miter: CGFloat = setCurve.miterLimit
    var dash: [NSNumber] = setCurve.lineDashPattern
    var winding: Int = setCurve.windingRule
    var alpha: [CGFloat] = setCurve.alpha
    var shadow: [CGFloat] = setCurve.shadow
    var gradientDirection: [CGPoint] = setCurve.gradientDirection
    var gradientLocation: [NSNumber] = setCurve.gradientLocation
    var colors: [NSColor] = setCurve.colors
    var blur: Double = setCurve.minBlur
    var points: [ControlPoint] = []
    var name: String = ""
    var oldName: String = ""
    var mask: Bool = false
    var group: Bool = false
    var lock: Bool = false
    var invisible: Bool = false
}

struct SetupGlobal {
    var saved = false
}

struct SetupCurve {
    let minResize: Double = 0.1
    let minRotate = -Double.pi
    let maxRotate = Double.pi
    let angle = 0.0
    let lineWidth: CGFloat = 1.0
    let maxLineWidth: CGFloat = 64
    let lineCap = 0
    let lineJoin = 0
    let miterLimit: CGFloat = 10
    let maxMiter: CGFloat = 16
    let lineDashPattern: [NSNumber] = [0, 0, 0, 0]
    let windingRule = 0
    let minDash: Double = 0
    let maxDash: Double = 32

    let alpha: [CGFloat] = [1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    let colors: [NSColor] = [
        NSColor.white.sRGB(), NSColor.systemBlue.sRGB(),
        NSColor.black.sRGB(), NSColor.systemPink.sRGB(),
        NSColor.systemBlue.sRGB(), NSColor.systemPurple.sRGB()]

    let strokeColor = NSColor.white.sRGB()
    let fillColor = NSColor.systemBlue.sRGB()

    let shadow: [CGFloat] = [2.0, 8.0, 8.0]
    let maxShadowRadius: Double = 32
    let maxShadowOffsetX: Double = 256
    let maxShadowOffsetY: Double = 256

    let gradientDirection = [CGPoint(x: 0.0, y: 0.0),
                             CGPoint(x: 1.0, y: 0.0)]
    let gradientLocation: [NSNumber] = [0.0, 0.50, 1.0]

    let minBlur: Double = 0
    let maxBlur: Double = 64

    let fontFamily: String = "Helvetica"
    let fontType: String = "Regular"
    let fontSize: CGFloat = 18
}

struct SetupEditor {
    let minZoom: Double = 20
    let maxZoom: Double = 640
    let reduceZoom: CGFloat = 20

    let screenWidth: Double = 640
    let screenHeight: Double = 480
    let maxScreenWidth: Double = 1600
    let maxScreenHeight: Double = 1200

    let lineWidth: CGFloat = 1.0
    let strokeColor = NSColor.white.sRGB()
    let fillColor = NSColor.systemBlue.sRGB()
    let guiColor = NSColor.unemphasizedSelectedContentBackgroundColor.sRGB()
    let controlColor = NSColor.systemGreen.sRGB()
    let lineDashPattern: [NSNumber] = [4, 4, 4, 4]

    let dotSize: CGFloat =  8
    let dotRadius: CGFloat = 4

    let rulersDelta: CGFloat = 1.1
    let rulersFontSize: CGFloat = 10
    let rulersShadow: NSSize = NSSize(width: 1, height: -1.5)

    let lockImg = NSImage.init(
        imageLiteralResourceName: NSImage.lockLockedTemplateName)
    let unlockImg = NSImage.init(
        imageLiteralResourceName: NSImage.lockUnlockedTemplateName)

    let stackButtonSize: CGSize = CGSize(width: 16, height: 16)
    let inputFieldSize: CGFloat = 128

    let filename: String = "untitled"
    let fileTypes: [String] = ["drf", "png", "svg"]

    let disabledActions = ["position": NSNull(),
                           "path": NSNull(),
                           "mask": NSNull(),
                           "bounds": NSNull(),
                           "strokeColor": NSNull(),
                           "fillColor": NSNull(),
                           "lineWidth": NSNull(),
                           "lineCap": NSNull(),
                           "lineJoin": NSNull(),
                           "miterLimit": NSNull(),
                           "lineDashPattern": NSNull(),
                           "transform": NSNull(),
                           "filters": NSNull(),
                           "shadowRadius": NSNull(),
                           "shadowOpacity": NSNull(),
                           "shadowOffset": NSNull(),
                           "shadowColor": NSNull()]
}

let curImageNESW = NSImage(byReferencingFile : "/System/Library/Frameworks/WebKit.framework/Versions/A/Frameworks/WebCore.framework/Versions/A/Resources/northEastSouthWestResizeCursor.png")!
let curImageNWSE = NSImage(byReferencingFile :  "/System/Library/Frameworks/WebKit.framework/Versions/A/Frameworks/WebCore.framework/Versions/A/Resources/northWestSouthEastResizeCursor.png")!

struct SetupCursor {
    let cursorNESW: NSCursor = NSCursor.init(image: curImageNESW,
                                             hotSpot: CGPoint(x: 8, y: 8))
    let cursorNWSE: NSCursor = NSCursor.init(image: curImageNWSE,
    hotSpot: CGPoint(x: 8, y: 8))
}

var setGlobal = SetupGlobal()
var setEditor = SetupEditor()
var setCurve = SetupCurve()
var setCursor = SetupCursor()
