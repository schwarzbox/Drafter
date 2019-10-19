//
//  Setup.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 9/10/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

enum Tools: Int {
    case drag, line, triangle, rect, pent, hex
    case arc, oval, stylus, curve, text
}

let toolsKeys: [String: Tools] =
    ["d": .drag, "l": .line, "t": .triangle, "r": .rect,
     "p": .pent, "h": .hex,
     "a": .arc, "o": .oval, "s": .stylus, "c": .curve, "f": .text]

struct Setup {
    let minZoom: Double = 20
    let maxZoom: Double = 800
    let reduceZoom: CGFloat = 40

    let sketchIconSize: CGSize = CGSize(width: 16, height: 16)
    let screenWidth: Double = 800
    let screenHeight: Double = 600
    let maxScreenWidth: Double = 1600
    let maxScreenHeight: Double = 1200
    let minResize: Double = 0.1
    let minRotate = -Double.pi
    let maxRotate = Double.pi
    let alpha: [CGFloat] = [1.0, 1.0]
    let lineWidth: CGFloat = 1.0
    let lineCap = 0
    let lineJoin = 0
    let lineDashPattern: [NSNumber] = [0, 0, 0, 0]
    let maxLineWidth: CGFloat = 64
    let minBlur: Double = 0
    let maxBlur: Double = 64
    let minDash: Double = 0
    let maxDash: Double = 32
    let strokeColor = NSColor.white.sRGB()
    let fillColor = NSColor.systemBlue.sRGB()
    let guiColor = NSColor.unemphasizedSelectedContentBackgroundColor.sRGB()
    let controlColor = NSColor.green.sRGB()
    let controlDashPattern: [NSNumber] = [4, 4, 0, 0]

    let shadow: [CGFloat] = [2.0, 0.5, 8.0, 8.0]
    let shadowColor =  NSColor.black
    let maxShadowRadius: Double = 32
    let maxShadowOffsetX: Double = 256
    let maxShadowOffsetY: Double = 256
    let gradientDirection = [CGPoint(x: 0.0, y: 0.0),
                             CGPoint(x: 1.0, y: 0.0)]
    let gradientColor = [NSColor.systemPink,
                         NSColor.systemBlue,
                         NSColor.systemPurple]
    let gradientLocation: [NSNumber] = [0.0, 0.50, 1.0]
    let gradientOpacity: [CGFloat] = [0.0, 0.0, 0.0]

    let dotSize: CGFloat =  8
    let dotRadius: CGFloat = 4

    let rulersDelta: CGFloat = 2
    let rulersPinSize: CGFloat = 2
    let rulersFontSize: CGFloat = 10

    let fontFamily: String = "Helvetica"
    let fontType: String = "Regular"
    let fontSize: CGFloat = 18

    let filename: String = "untitled"
    let fileTypes: [String] = ["png", "svg"]


    let disabledActions = ["position": NSNull(), "bounds": NSNull(),
                           "path": NSNull()]
}

var setup = Setup()
