//
//  Setup.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 9/10/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

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
    let windingRule = 0
    let maskRule = 0
    let lineDashPattern: [NSNumber] = [0, 0, 0, 0]
    let minDash: Double = 0
    let maxDash: Double = 32

    let alpha: [CGFloat] = [1.0, 1.0, 0.0, 0.0, 0.0, 0.0]
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

    let minFilterRadius: Double = 0
    let maxFilterRadius: Double = 32
}

struct SetupEditor {
    let maxHistory: Int = 2
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

    let pathPad: CGFloat = 32
    let dotSize: CGFloat =  8
    let dotRadius: CGFloat = 4

    let rulersDelta: CGFloat = 2
    let rulersFontSize: CGFloat = 10
    let rulersShadow: NSSize = NSSize(width: 1, height: -1.5)

    let lockImg = NSImage.init(
        imageLiteralResourceName: NSImage.lockLockedTemplateName)
    let unlockImg = NSImage.init(
        imageLiteralResourceName: NSImage.lockUnlockedTemplateName)
    let maskGrayImg = #imageLiteral(resourceName: "maskGray")

    let stackButtonSize: CGSize = CGSize(width: 16, height: 16)
    let filename: String = "untitled"
    let fileTypes: [String] = ["bundle", "png", "svg"]

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

    let fontFamily: String = "Helvetica"
    let fontType: String = "Regular"
    let fontSize: Double = 16
    let minFont: Double = 8
    let maxFont: Double = 128
    let fonts: [String] = [
        "American Typewriter", "Andale Mono",
        "Arcade", "Arial", "Arial Black",
        "Arial Narrow", "Avenir", "Avenir Next",
        "Bradley Hand", "Brush Script MT",
        "Chalkboard", "Chalkduster", "Comic Sans MS",
        "Copperplate", "Courier",
        "Courier New", "Didot", "DIN Alternate",
        "DIN Condensed", "Futura", "Geneva", "Georgia",
        "Gill Sans", "Helvetica", "Helvetica Neue",
        "Herculanum", "Hoefler Text", "Impact",
        "InaiMathi", "Kefa", "Kohinoor Bangla",
        "Kohinoor Devanagari", "Kohinoor Gujarati",
        "Kohinoor Telugu", "Krungthep",
        "Monaco", "Mukta Mahee", "Lucida Grande",
        "Luminari", "Marker Felt", "Menlo",
        "Microsoft Sans Serif", "Monaco", "Mukta Mahee",
        "Noteworthy", "Optima", "Papyrus",
        "PCBius", "Phosphate", "PT Mono", "PT Sans",
        "PT Sans Caption", "PT Sans Narrow",
        "PT Serif", "PT Serif Caption",
        "Rockwell", "Savoye LET", "SignPainter",
        "Silkscreen", "Silom", "Skia", "Snell Roundhand",
        "Space Invaders", "Stencil Std", "Tahoma", "Times",
        "Times New Roman", "Trattatello",
        "Trebuchet MS", "Verdana", "Zapfino"]
}

struct SetupCursor {
    let resizeNS: NSCursor = NSCursor.init(
        image: #imageLiteral(resourceName: "nsResizeCursor"),
        hotSpot: CGPoint(x: 8, y: 8))
    let resizeWE: NSCursor = NSCursor.init(
        image: #imageLiteral(resourceName: "weResizeCursor"),
        hotSpot: CGPoint(x: 8, y: 8))
    let resizeNESW: NSCursor = NSCursor.init(
        image: #imageLiteral(resourceName: "neswResizeCursor"),
        hotSpot: CGPoint(x: 8, y: 8))
    let resizeNWSE: NSCursor = NSCursor.init(
        image: #imageLiteral(resourceName: "nwseResizeCursor"),
        hotSpot: CGPoint(x: 8, y: 8))
    let rotateW: NSCursor = NSCursor.init(
        image: #imageLiteral(resourceName: "nwseResizeCursor"),
        hotSpot: CGPoint(x: 8, y: 8))
    let rotateE: NSCursor = NSCursor.init(
        image: #imageLiteral(resourceName: "neswResizeCursor"),
        hotSpot: CGPoint(x: 8, y: 8))

    let stylus: NSCursor = NSCursor.init(
        image: "✎".emojiToImage(),
        hotSpot: CGPoint(x: 16, y: 24))
    let vector: NSCursor = NSCursor.init(
        image: "✑".emojiToImage(),
        hotSpot: CGPoint(x: 24, y: 12))
}

var setEditor = SetupEditor()
var setCurve = SetupCurve()
var setCursor = SetupCursor()
