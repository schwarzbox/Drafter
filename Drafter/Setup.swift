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

    let strokeColor = NSColor.white
    let fillColor = NSColor.systemBlue
    let guiColor = NSColor.systemGray
    let shadow: [CGFloat] = [2.0,0.5,8.0,8.0]
    let shadowColor =  NSColor.black
    let maxShadowRadius: Double = 16
    let maxShadowOffsetX: Double = 256
    let maxShadowOffsetY: Double = 256
    let opacityIncrement: Double = 0.1
    let offsetIncrement: Double = 8
    let dotSize: CGFloat =  8
    let dotRadius: CGFloat = 4
    let fontName: String = "Helvetica"
    let fontSize: CGFloat = 16
    let textHeight: CGFloat = 22
    let filename: String = "untitled.png"

    var isActiveTextField: Bool = false
    mutating func activeTextField(find: Bool) {
        self.isActiveTextField = find
    }
}

var set = Set()
