//
//  GroupFrame.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 10/18/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

class GroupFrame: ControlFrame {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    init(parent: SketchPad, curves: [Curve], numberDots: Int) {
        super.init(parent: parent)

        if let rect = self.initGroupFrame(curves: curves) {
            self.frame = rect
        }
        self.borderWidth = setup.lineWidth
        self.borderColor = setup.controlColor.cgColor
        self.dotSize = dotSize
        self.dot50Size = dot50Size

        let dots: [CGPoint] = [
            CGPoint(x: self.bounds.maxX + self.ctrlPad, y: self.bounds.minY),
            CGPoint(x: self.bounds.maxX, y: self.bounds.minY)]

        var rounded = self.dot50Size
        var offset: CGFloat = 0
        for i in 0..<dots.count {
            self.makeDot(parent: parent, tag: numberDots + i,
                         x: dots[i].x + offset,
                         y: dots[i].y - offset, radius: rounded,
                         strokeColor: setup.strokeColor,
                         fillColor: setup.controlColor)
            rounded = 0
            offset = self.dot50Size
        }

        let path = NSBezierPath()
        path.move(to: CGPoint(x: self.bounds.maxX, y: self.bounds.minY))
        path.line(to: CGPoint(x: self.bounds.maxX + self.ctrlPad,
                              y: self.bounds.minY))
        self.makeShape(path: path, strokeColor: setup.controlColor,
                       lineWidth: setup.lineWidth)

        if curves[0].group > 0 {
            self.initGroupNumber(groupIndex: curves[0].group)
        }
    }

    func initGroupFrame(curves: [Curve]) -> CGRect? {
        var allMinX: [CGFloat] = []
        var allMinY: [CGFloat] = []
        var allMaxX: [CGFloat] = []
        var allMaxY: [CGFloat] = []
        for curve in curves {
            let line50 = curve.lineWidth/2
            allMinX.append(curve.path.bounds.minX - line50)
            allMinY.append(curve.path.bounds.minY - line50)
            allMaxX.append(curve.path.bounds.maxX + line50)
            allMaxY.append(curve.path.bounds.maxY + line50)
        }
        if let minX = allMinX.min(), let minY = allMinY.min(),
            let maxX = allMaxX.max(), let maxY = allMaxY.max() {
            let pad = setup.lineWidth * 2
            let rect = CGRect(x: minX - setup.lineWidth,
                              y: minY - setup.lineWidth,
                              width: pad + maxX - minX,
                              height: pad + maxY - minY)
            return rect
        }
        return nil
    }

    func initGroupNumber(groupIndex: Int) {
        self.makeText(text: String(groupIndex),
                      pos: CGPoint(x: self.bounds.minX,
                                   y: self.bounds.maxY), tag: -1)
    }
}
