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

    init(parent: SketchPad, curves: [Curve]) {
        super.init(parent: parent)
        
        if let rect = self.initGroupFrame(curves: curves) {
            self.frame = rect
        }
        self.borderWidth = setup.lineWidth
        self.borderColor = setup.controlColor.cgColor

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
                                   y: self.bounds.maxY),
                      pad: 4, tag: -1, backgroundColor: setup.controlColor)
    }
}
