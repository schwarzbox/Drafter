//
//  Tool.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 11/11/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

let tools: [Tool] = [
    Drag(), Line(), Triangle(), Rectangle(),
    Pentagon(), Hexagon(), Arc(), Oval(),
    Stylus(), Vector(), Text()
]

let toolsKeys: [String: Tool] = [
    "d": tools[0], "l": tools[1], "t": tools[2],
    "r": tools[3], "p": tools[4], "h": tools[5],
    "a": tools[6], "o": tools[7],
    "s": tools[8], "v": tools[9], "f": tools[10]]

protocol Drawable {
    var tag: Int { get }
    var name: String { get }
    func create(ctrl: Bool, shift: Bool, opt: Bool,
                event: NSEvent?)
    func move(shift: Bool, ctrl: Bool)
    func drag(shift: Bool, ctrl: Bool)
    func down(shift: Bool)
    func up(editDone: Bool)
}

class Tool: Drawable {
    var tag: Int {-1}
    static var view: SketchPad?
    func useTool(_ action: @autoclosure () -> Void) {
         Tool.view!.editedPath = NSBezierPath()
         action()
         if Tool.view!.filledCurve {
             Tool.view!.editedPath.close()
         }
         Tool.view!.editDone = true
    }

    func flipSize(topLeft: CGPoint,
                  bottomRight: CGPoint) -> (wid: CGFloat, hei: CGFloat) {
          return (bottomRight.x - topLeft.x, bottomRight.y - topLeft.y)
    }

    func appendStraightCurves(points: [CGPoint]) {
        Tool.view!.controlPoints = []
        Tool.view!.editedPath.move(to: points[0])
        for i in 0..<points.count {
            let pnt = points[i]
            Tool.view!.controlPoints.append(
                ControlPoint(Tool.view!,
                             cp1: pnt, cp2: pnt, mp: pnt))
            if i == points.count-1 {
                Tool.view!.editedPath.curve(to: points[0],
                                      controlPoint1: points[0],
                                      controlPoint2: points[0])
            } else {
                Tool.view!.editedPath.curve(to: points[i+1],
                                      controlPoint1: points[i+1],
                                      controlPoint2: points[i+1])
            }
        }
    }

    var mpPoints: [CGPoint] {
        return [Tool.view!.startPos]
    }

    // MARK: Protocol
    var name: String {"shape"}

    func create(ctrl: Bool, shift: Bool, opt: Bool,
                event: NSEvent? = nil) { }

    func move(shift: Bool, ctrl: Bool) {
        var mpPoints: [CGPoint] = []
        if let mp = Tool.view!.movePoint {
           mpPoints.append(mp.position)
        }
        for cp in Tool.view!.controlPoints {
           mpPoints.append(cp.mp.position)
        }

        var mPos = Tool.view!.startPos
        if let pos = mpPoints.first, shift {
            Tool.view!.startPos = Tool.view!.shiftAngle(
                topLeft: pos, bottomRight: Tool.view!.startPos)
            mPos = pos
        }

        let snap = Tool.view!.snapToRulers(points: [Tool.view!.startPos],
                                    curves: Tool.view!.curves,
                                    curvePoints: mpPoints,
                                    ctrl: ctrl)
        Tool.view!.startPos.x -= snap.x
        Tool.view!.startPos.y -= snap.y
        Tool.view!.snapMouseToRulers(snap: snap,
                                       pos: Tool.view!.startPos)

        if shift {
            Tool.view!.rulers.appendCustomRule(move: mPos,
                                         line: Tool.view!.startPos)
        }

        if let mp = Tool.view!.movePoint,
            let cp1 = Tool.view!.controlPoint1 {
            Tool.view!.moveCurvedPath(move: mp.position,
                                to: Tool.view!.startPos,
                                cp1: mp.position,
                                cp2: cp1.position)
        }
    }

    func drag(shift: Bool, ctrl: Bool) {
        let snap = Tool.view!.snapToRulers(
            points: [Tool.view!.finPos],
            curves: Tool.view!.curves,
            curvePoints: mpPoints, ctrl: ctrl)
        Tool.view!.finPos.x -= snap.x
        Tool.view!.finPos.y -= snap.y
        Tool.view!.snapMouseToRulers(snap: snap,
                                       pos: Tool.view!.finPos)
    }

    func down(shift: Bool) {
        Tool.view!.controlPoints = []
        Tool.view!.editedPath.removeAllPoints()
    }

    func up(editDone: Bool) {
        if let curve = Tool.view!.selectedCurve {
            Tool.view!.clearControls(curve: curve)
        } else {
            if Tool.view!.groups.count>0 {
                Tool.view!.selectedCurve = Tool.view!.groups[0]
            }
        }
        if editDone {
            Tool.view!.newCurve()
        }
        if let curve = Tool.view!.selectedCurve,
            !curve.canvas.isHidden {
            curve.reset()
            Tool.view!.createControls(curve: curve)
        }
    }
}

class Drag: Tool {
    override var tag: Int {0}
    override var name: String {"drag"}
    func action(topLeft: CGPoint, bottomRight: CGPoint) {
        let size = self.flipSize(topLeft: topLeft,
                                bottomRight: bottomRight)
        Tool.view!.curvedPath.appendRect(NSRect(
            x: topLeft.x, y: topLeft.y,
            width: size.wid, height: size.hei))
        Tool.view!.groups.removeAll()
        for cur in Tool.view!.curves {
           let curves = cur.groupRect(curves: cur.groups)
           if Tool.view!.curvedPath.bounds.contains(curves) &&
               !Tool.view!.groups.contains(cur) {
                Tool.view!.groups.append(contentsOf: cur.groups)
           }
        }
        for cur in Tool.view!.groups {
            Tool.view!.curvedPath.append(cur.path)
        }
    }

    override func create(ctrl: Bool, shift: Bool, opt: Bool,
                         event: NSEvent? = nil) {
        Tool.view!.clearPathLayer(layer: Tool.view!.curveLayer,
                            path: Tool.view!.curvedPath)
        if let curve = Tool.view!.selectedCurve, !curve.lock {
            Tool.view!.dragCurve(deltaX: event?.deltaX ?? 0,
                                   deltaY: event?.deltaY ?? 0,
                                   ctrl: ctrl)
        } else {
            self.action(topLeft: Tool.view!.startPos,
                        bottomRight: Tool.view!.finPos)
        }
    }

    override func drag(shift: Bool, ctrl: Bool) {
        Tool.view!.clearRulers()
    }

    override func move(shift: Bool, ctrl: Bool) {
        Tool.view!.clearRulers()
    }

    override func down(shift: Bool) {
        Tool.view!.clearPathLayer(layer: Tool.view!.curveLayer,
                            path: Tool.view!.curvedPath)
        Tool.view!.selectCurve(pos: Tool.view!.startPos,
                                 shift: shift)
    }
}

class Line: Tool {
    override var tag: Int {1}
    override var name: String {"line"}
    func action(topLeft: CGPoint, bottomRight: CGPoint) {
        Tool.view!.editedPath.move(to: topLeft)
        Tool.view!.editedPath.curve(to: bottomRight,
                              controlPoint1: bottomRight,
                              controlPoint2: bottomRight)
        Tool.view!.editedPath.move(to: bottomRight)

        Tool.view!.controlPoints = [
            ControlPoint(Tool.view!, cp1: topLeft, cp2: topLeft,
                         mp: topLeft),
            ControlPoint(Tool.view!, cp1: bottomRight, cp2: bottomRight,
                                 mp: bottomRight)]
    }
    override func create(ctrl: Bool, shift: Bool, opt: Bool,
                         event: NSEvent? = nil) {
        self.useTool(self.action(
            topLeft: Tool.view!.startPos, bottomRight: Tool.view!.finPos))
        Tool.view!.filledCurve = false
    }

    override func drag(shift: Bool, ctrl: Bool) {
        let par = Tool.view!
        if shift {
            par.finPos = par.shiftAngle(topLeft: par.startPos,
                                        bottomRight: par.finPos)
        }

        super.drag(shift: shift, ctrl: ctrl)

        if shift {
            par.rulers.appendCustomRule(move: par.startPos,
                                        line: par.finPos)
        }
    }
}

class Triangle: Tool {
    override var tag: Int {2}
    func action(topLeft: CGPoint, bottomRight: CGPoint, sides: Int,
                angle: CGFloat) {
        let size = self.flipSize(topLeft: topLeft,
                                 bottomRight: bottomRight)

        let radius = abs(size.wid) < abs(size.hei)
            ? abs(size.wid/2)
            : abs(size.hei/2)
        let cx: CGFloat = size.wid > 0 ? topLeft.x + radius : topLeft.x - radius
        var cy: CGFloat = topLeft.y - radius
        var turn90 = -CGFloat.pi / 2
        if size.hei > 0 {
            cy = topLeft.y + radius
            turn90 *= -1
        }

        var points: [CGPoint] = []
        if radius>0 {
            let radian = CGFloat(angle * CGFloat.pi / 180)

            for i in 0..<sides {
                let cosX = cos(turn90 + CGFloat(i) * radian)
                let sinY = -sin(turn90 + CGFloat(i) * radian)
                points.append(CGPoint(x: cx + cosX * radius,
                                     y: cy + sinY * radius))
           }
        }
        if points.count>0 {
            self.appendStraightCurves(points: points)
        }
    }

    override func create(ctrl: Bool, shift: Bool, opt: Bool,
                         event: NSEvent? = nil) {
        self.useTool(self.action(topLeft: Tool.view!.startPos,
                                 bottomRight: Tool.view!.finPos,
                                 sides: 3, angle: 120))
    }

    override func drag(shift: Bool, ctrl: Bool) {
        Tool.view!.clearRulers()
    }
}

class Rectangle: Tool {
    override var tag: Int {3}
    func action(topLeft: CGPoint, bottomRight: CGPoint,
                shift: Bool = false) {
        var botLeft: CGPoint
        var topRight: CGPoint

        if topLeft.x < bottomRight.x && topLeft.y > bottomRight.y {
            botLeft = CGPoint(x: topLeft.x, y: bottomRight.y)
            topRight = CGPoint(x: bottomRight.x, y: topLeft.y)
        } else if topLeft.x < bottomRight.x  && topLeft.y < bottomRight.y {
            botLeft = CGPoint(x: topLeft.x, y: topLeft.y)
            topRight = CGPoint(x: bottomRight.x, y: bottomRight.y)
        } else if topLeft.x > bottomRight.x && topLeft.y > bottomRight.y {
            botLeft = CGPoint(x: bottomRight.x, y: bottomRight.y)
            topRight = CGPoint(x: topLeft.x, y: topLeft.y)
        } else {
            botLeft = CGPoint(x: bottomRight.x, y: topLeft.y)
            topRight = CGPoint(x: topLeft.x, y: bottomRight.y)
        }

        let size = self.flipSize(topLeft: botLeft,
                                 bottomRight: topRight)
        var wid = size.wid
        var hei = size.hei

        if shift {
            let maxSize = abs(size.wid) > abs(size.hei)
                ? abs(size.wid)
                : abs(size.hei)
            wid = maxSize
            hei = maxSize
        }

        if shift && (topLeft.x < bottomRight.x) &&
                   (topLeft.y > bottomRight.y) {
            botLeft.y = topRight.y - hei
        } else if shift && (topLeft.x > bottomRight.x) &&
            (topLeft.y < bottomRight.y) {
            botLeft.x = topRight.x - wid
        } else if shift && (topLeft.x > bottomRight.x) &&
            (topLeft.y > bottomRight.y) {
            botLeft.x = topRight.x - wid
            botLeft.y = topRight.y - hei
        }

        let points: [CGPoint] = [
            CGPoint(x: botLeft.x, y: botLeft.y + hei),
            CGPoint(x: botLeft.x, y: botLeft.y),
            CGPoint(x: botLeft.x + wid, y: botLeft.y),
            CGPoint(x: botLeft.x + wid, y: botLeft.y + hei)]

        Tool.view!.controlPoints = []
        Tool.view!.editedPath.move(to: points[0])
        for i in 0..<points.count {
            let pnt = points[i]
            Tool.view!.controlPoints.append(
                ControlPoint(Tool.view!, cp1: pnt, cp2: pnt, mp: pnt))
            Tool.view!.controlPoints.append(
                ControlPoint(Tool.view!, cp1: pnt, cp2: pnt, mp: pnt))

            Tool.view!.editedPath.curve(to: pnt,
                                  controlPoint1: pnt, controlPoint2: pnt)
            if i == points.count-1 {
                Tool.view!.editedPath.curve(to: points[0],
                                      controlPoint1: points[0],
                                      controlPoint2: points[0])
            } else {
                Tool.view!.editedPath.curve(to: points[i+1],
                                      controlPoint1: points[i+1],
                                      controlPoint2: points[i+1])
            }
        }
        Tool.view!.roundedCurve = CGPoint(x: 0, y: 0)
    }
    override func create(ctrl: Bool, shift: Bool, opt: Bool,
                         event: NSEvent? = nil) {
        self.useTool(self.action(topLeft: Tool.view!.startPos,
                                 bottomRight: Tool.view!.finPos,
                                 shift: shift))
    }
}

class Pentagon: Triangle {
    override var tag: Int {4}
    override func create(ctrl: Bool, shift: Bool, opt: Bool,
                         event: NSEvent? = nil) {
        self.useTool(self.action(topLeft: Tool.view!.startPos,
                                 bottomRight: Tool.view!.finPos,
                                 sides: 5, angle: 72))
    }
    override func drag(shift: Bool, ctrl: Bool) {
        Tool.view!.clearRulers()
    }
}

class Hexagon: Triangle {
    override var tag: Int {5}
    override func create(ctrl: Bool, shift: Bool, opt: Bool,
                         event: NSEvent? = nil) {
        self.useTool(self.action(topLeft: Tool.view!.startPos,
                                 bottomRight: Tool.view!.finPos,
                                 sides: 6, angle: 60))
    }

    override func drag(shift: Bool, ctrl: Bool) {
        Tool.view!.clearRulers()
    }
}

class Arc: Tool {
    override var tag: Int {6}
    func action(topLeft: CGPoint, bottomRight: CGPoint) {
        let size = self.flipSize(topLeft: topLeft,
                                 bottomRight: bottomRight)

        let delta = remainder(abs(size.hei/2), 360)

        let startAngle = -delta
        let endAngle = delta

        Tool.view!.editedPath.move(to: topLeft)
        Tool.view!.editedPath.appendArc(withCenter: topLeft, radius: size.wid,
                                  startAngle: startAngle, endAngle: endAngle,
                                  clockwise: false)

        let mPnt = Tool.view!.editedPath.findPoint(0)
        let lPnt = Tool.view!.editedPath.findPoint(1)

        Tool.view!.editedPath = Tool.view!.editedPath.placeCurve(
            at: 1, with: [lPnt[0], lPnt[0], lPnt[0]], replace: false)

        let fPnt = Tool.view!.editedPath.findPoint(
            Tool.view!.editedPath.elementCount-1)

        Tool.view!.editedPath = Tool.view!.editedPath.placeCurve(
            at: Tool.view!.editedPath.elementCount,
            with: [fPnt[2], fPnt[2], mPnt[0]])

        let points = Tool.view!.editedPath.findPoints(.curveTo)

        let lst = points.count-1
        if lst > 0 {
            Tool.view!.controlPoints = [
                ControlPoint(Tool.view!, cp1: points[lst][2],
                             cp2: points[lst][2], mp: points[lst][2]),
                ControlPoint(Tool.view!, cp1: points[1][0],
                             cp2: points[0][2], mp: points[0][2])]
        }
        if lst > 1 {
            for i in 1..<lst-1 {
                Tool.view!.controlPoints.append(
                    ControlPoint(Tool.view!, cp1: points[i+1][0],
                                 cp2: points[i][1], mp: points[i][2]))
            }
            Tool.view!.controlPoints.append(
                ControlPoint(Tool.view!, cp1: points[lst-1][2],
                             cp2: points[lst-1][1], mp: points[lst-1][2]))
        }
    }

    override func create(ctrl: Bool, shift: Bool, opt: Bool,
                         event: NSEvent? = nil) {
        self.useTool(self.action(topLeft: Tool.view!.startPos,
                                 bottomRight: Tool.view!.finPos))
    }
}

class Oval: Tool {
    override var tag: Int {7}
    func action(topLeft: CGPoint, bottomRight: CGPoint,
                shift: Bool = false) {
        let size = self.flipSize(topLeft: topLeft, bottomRight: bottomRight)
        var wid = size.wid
        var hei = size.hei

        if shift {
            let maxSize = abs(size.wid) > abs(size.hei)
                ? abs(size.wid)
                : abs(size.hei)
            let signWid: CGFloat = wid>0 ? 1 : -1
            let signHei: CGFloat = hei>0 ? 1 : -1
            wid = maxSize * signWid
            hei = maxSize * signHei
        }

        Tool.view!.editedPath.appendOval(
            in: NSRect(x: topLeft.x, y: topLeft.y,
                       width: wid, height: hei))

        let points = Tool.view!.editedPath.findPoints(.curveTo)
        if points.count == 4 {
            Tool.view!.controlPoints = [
                ControlPoint(Tool.view!, cp1: points[0][0],
                             cp2: points[3][1], mp: points[3][2]),
                ControlPoint(Tool.view!, cp1: points[1][0],
                             cp2: points[0][1], mp: points[0][2]),
                ControlPoint(Tool.view!, cp1: points[2][0],
                             cp2: points[1][1], mp: points[1][2]),
                ControlPoint(Tool.view!, cp1: points[3][0],
                             cp2: points[2][1], mp: points[2][2])]
        }
    }
    override func create(ctrl: Bool, shift: Bool, opt: Bool,
                         event: NSEvent? = nil) {
        self.useTool(self.action(topLeft: Tool.view!.startPos,
                                 bottomRight: Tool.view!.finPos,
                                 shift: shift))
    }
}

class Stylus: Line {
    override var tag: Int {8}
    override var name: String {"line"}
    override func action(topLeft: CGPoint, bottomRight: CGPoint) {
        Tool.view!.editedPath.curve(to: bottomRight,
                              controlPoint1: bottomRight,
                              controlPoint2: bottomRight)

        Tool.view!.controlPoints.append(
            ControlPoint(Tool.view!, cp1: bottomRight,
                         cp2: bottomRight, mp: bottomRight))
    }

    override func create(ctrl: Bool, shift: Bool, opt: Bool,
                         event: NSEvent? = nil) {
        let par = Tool.view!
        if abs(par.startPos.x - par.finPos.x) > setEditor.dotSize ||
            abs(par.startPos.y - par.finPos.y) > setEditor.dotSize {
            self.action(topLeft: par.startPos,
                        bottomRight: par.finPos)
            par.startPos = par.finPos
            par.editDone = true
        }
        par.filledCurve = false
    }

    override func down(shift: Bool) {
        Tool.view!.controlPoints = []
        Tool.view!.editedPath.removeAllPoints()
        Tool.view!.editedPath.move(to: Tool.view!.startPos)
        Tool.view!.controlPoints.append(
            ControlPoint(Tool.view!, cp1: Tool.view!.startPos,
                        cp2: Tool.view!.startPos, mp: Tool.view!.startPos))
    }

    override func up(editDone: Bool) {
        if Tool.view!.editDone {
            Tool.view!.editedPath.move(to: Tool.view!.startPos)
        } else {
            Tool.view!.controlPoints = []
            Tool.view!.editedPath.removeAllPoints()
        }
        super.up(editDone: editDone)
    }
}

class Vector: Line {
    override var tag: Int {9}
    override var name: String {"shape"}
    func action(topLeft: CGPoint) {
        let par = Tool.view!
        if let mp = par.movePoint,
            let cp1 = par.controlPoint1,
            let cp2 = par.controlPoint2 {
            par.moveCurvedPath(move: mp.position, to: topLeft,
                               cp1: cp1.position, cp2: topLeft)
            par.addSegment(mp: mp, cp1: cp1, cp2: cp2)
        }

        par.movePoint = Dot(par, pos: topLeft)
        par.layer?.addSublayer(par.movePoint!)
        par.controlPoint1 = Dot(par, pos: topLeft,
                                strokeColor: setEditor.fillColor,
                                fillColor: setEditor.strokeColor)
            par.layer?.addSublayer(par.controlPoint1!)
        par.controlPoint2 = Dot(par, pos: topLeft,
                                strokeColor: setEditor.fillColor,
                                fillColor: setEditor.strokeColor)
        par.layer?.addSublayer(Tool.view!.controlPoint2!)

        par.clearPathLayer(layer: par.controlLayer,
                           path: par.controlPath)

        if let mp = par.movePoint {
            let options: NSTrackingArea.Options = [
                .mouseEnteredAndExited, .activeInActiveApp]
            let area = NSTrackingArea(rect: NSRect(x: mp.frame.minX,
                                                   y: mp.frame.minY,
                                                   width: mp.frame.width,
                                                   height: mp.frame.height),
                                      options: options, owner: par)
            par.addTrackingArea(area)
        }

        if par.editedPath.elementCount==0 {
            par.editedPath.move(to: topLeft)
        }
    }
    override func create(ctrl: Bool, shift: Bool, opt: Bool,
                         event: NSEvent? = nil) {
        if Tool.view!.editDone { return }
        Tool.view!.dragCurvedPath(topLeft: Tool.view!.startPos,
                                    bottomRight: Tool.view!.finPos,
                                    opt: opt)
    }

    override var mpPoints: [CGPoint] {
        let par = Tool.view!
        var points: [CGPoint] = [par.startPos]

        if let mp = par.movePoint {
           points.append(mp.position)
        }
        for cp in par.controlPoints {
            points.append(cp.mp.position)
        }
        return points
    }

    override func down(shift: Bool) {
        self.action(topLeft: Tool.view!.startPos)
    }

    override func up(editDone: Bool) {
        if let curve = Tool.view!.selectedCurve, curve.edit || editDone {
            Tool.view!.clearControls(curve: curve)
        }

        if editDone {
            Tool.view!.newCurve()
        }
        if let curve = Tool.view!.selectedCurve, curve.edit || editDone {
            curve.reset()
            Tool.view!.createControls(curve: curve)
        }
    }
}

class Text: Tool {
    override var tag: Int {10}
    override var name: String {"text"}
    func action(pos: CGPoint? = nil) {
        let topLeft = pos ?? Tool.view!.startPos

        let deltaX = topLeft.x-Tool.view!.bounds.minX
        let deltaY = topLeft.y-Tool.view!.bounds.minY

        Tool.view!.fontUI.inputField.setFrameOrigin(CGPoint(
            x: deltaX * Tool.view!.zoomed,
            y: deltaY * Tool.view!.zoomed))
        Tool.view!.fontUI.inputField.show()
    }

    override func create(ctrl: Bool, shift: Bool, opt: Bool,
                         event: NSEvent? = nil) {
        self.action(pos: Tool.view!.finPos)

    }

    override func drag(shift: Bool, ctrl: Bool) {
        Tool.view!.clearRulers()
    }

    override func down(shift: Bool) {
        self.action(pos: Tool.view!.startPos)
    }
}
