//
//  Setup.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 9/10/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

struct Set {
    let minZoom: Double = 20
    let maxZoom: Double = 400
    let reduceZoom: CGFloat = 40

    let screenWidth: Double = 800
    let screenHeight: Double = 600
    let maxScreenWidth: Double = 1600
    let maxScreenHeight: Double = 1200
    let minRotate = -Double.pi
    let maxRotate = Double.pi
    let lineWidth: CGFloat = 1.0
    let maxLineWidth: CGFloat = 256
    let maxBlur: Double = 128

    let strokeColor = NSColor.white.sRGB()
    let fillColor = NSColor.systemBlue.sRGB()
    let guiColor = NSColor.systemGray.sRGB()
    let shadow: [CGFloat] = [2.0,0.5,8.0,8.0]
    let shadowColor =  NSColor.black
    let maxShadowRadius: Double = 32
    let gradientDirection = [CGPoint(x: 0.0, y: 0.0),
                             CGPoint(x: 1.0, y: 0.0)]
    let gradientColor = [NSColor.systemPink,
                         NSColor.systemBlue,
                         NSColor.systemPurple]
    let gradientLocation: [NSNumber] = [0.0, 0.50, 1.0]

    let framePad: CGFloat = 8
    let dotSize: CGFloat =  8
    let dotRadius: CGFloat = 4
    let fontName: String = "Helvetica"
    let fontSize: CGFloat = 16
    let textHeight: CGFloat = 22
    let fontButtonSize = CGSize(width: 16, height: 16)
    let filename: String = "untitled.png"
}

var set = Set()

