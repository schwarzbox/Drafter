//
//  Rulers.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 10/16/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

struct RulerPoint {
    let move: CGPoint
    let line: CGPoint
    let maxMove: CGPoint
    let maxLine: CGPoint
    var dist: [CGFloat] = [0]
}

class Ruler: CAShapeLayer {
    var parent: SketchPad?
    var dotSize: CGFloat = setup.dotRadius

    override init(layer: Any) {
        super.init(layer: layer)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    init(parent: SketchPad) {

        self.parent = parent
        super.init()
        self.strokeColor = setup.controlColor.cgColor
        self.fillColor = nil

        self.dotSize = parent.dotRadius
        self.lineWidth = parent.lineWidth
        self.actions = setup.disabledActions
        
        self.makeShape(
            path: NSBezierPath(),
            strokeColor: setup.controlColor.sRGB(alpha: 0.5),
            actions: setup.disabledActions)
    }

    func createRulers(points: [CGPoint], curves: [Curve],
                      curvePoints: [CGPoint] = [],
                      exclude: Curve?, ctrl: Bool = false)
        -> (delta: CGPoint, pnt: [String: (pos: CGPoint?,
                                            dist: CGFloat)]) {

        self.dotSize = self.parent!.dotRadius
        self.lineWidth = self.parent!.lineWidth
        self.clearRulers()

        var minDistX: CGFloat = CGFloat(MAXFLOAT)
        var minDistY: CGFloat = CGFloat(MAXFLOAT)
        var rulerPoints = self.findRulersToCurve(points: points,
                                                 curves: curves,
                                                 exclude: exclude,
                                                 minDistX: &minDistX,
                                                 minDistY: &minDistY)

        let curvePoints = self.findRulersToPoints(point: points[0],
                                                  curvePoints: curvePoints,
                                                  minDistX: minDistX,
                                                  minDistY: minDistY)

        if curvePoints["x"] != nil {
            rulerPoints["x"] = curvePoints["x"]
        }
        if curvePoints["y"] != nil {
            rulerPoints["y"] = curvePoints["y"]
        }

        self.showRulers(rulerPoints: rulerPoints, ctrl: ctrl)
        var snap = self.deltaRulers(rulerPoints: rulerPoints)
        if ctrl {
            snap.delta = CGPoint(x: 0, y: 0)
        }
        return snap
    }

    func updateRulers() {
        self.removeFromSuperlayer()
        self.parent?.layer?.addSublayer(self)
    }

    func clearRulers() {
        self.removeFromSuperlayer()
        self.path = nil
        if let subs = self.sublayers,
            let alphaLayer = subs[0] as? CAShapeLayer {
            alphaLayer.path = nil
        }
    }

    func deltaRulers(rulerPoints: [String: RulerPoint?])
        -> (delta: CGPoint, pnt: [String: (pos: CGPoint?,
        dist: CGFloat)]) {
        var deltaX: CGFloat = 0
        var deltaY: CGFloat = 0
        var signX: CGFloat = 1
        var signY: CGFloat = 1
        var result: [String: (pos: CGPoint?, dist: CGFloat)] = [:]
        result["x"] = (pos: nil, dist: 0)
        result["y"] = (pos: nil, dist: 0)
        for (key, point) in rulerPoints {
            guard let pnt = point else { continue }

            let dX = pnt.move.x - pnt.line.x
            let dY = pnt.move.y - pnt.line.y

            result[key] = (pos: pnt.move, dist: 0)
            if abs(dX) < setup.rulersDelta && abs(dX) >= deltaX {
                if dY != 0 {
                    result["y"]?.dist = (abs(dY) * 10).rounded()/10
                }
                deltaX = abs(dX)
                signX = dX>0 ? 1 : -1
            }
            if abs(dY) < setup.rulersDelta && abs(dY) >= deltaY {
                if dX != 0 {
                    result["x"]?.dist = (abs(dX) * 10).rounded()/10
                }
                deltaY = abs(dY)
                signY = dY>0 ? 1 : -1
            }
        }
        return (CGPoint(x: deltaX * signX,
                        y: deltaY * signY), result)
    }

    func findRulersToCurve(
        points: [CGPoint], curves: [Curve], exclude: Curve? = nil,
        minDistX: inout CGFloat,
        minDistY: inout CGFloat) -> [String: RulerPoint?] {
        var rulerPoints: [String: RulerPoint?] = [:]
        var rulerPointX: RulerPoint?
        var rulerPointY: RulerPoint?
        for cur in curves {
            if let ex = exclude, ex == cur {
                continue
            }

            for pnt in points {
                for curPnt in cur.boundsPoints {
                    if pnt.x <= curPnt.x+setup.rulersDelta &&
                        pnt.x >= curPnt.x-setup.rulersDelta {

                        let (minTarY, maxTarY) = self.findMinMax(
                            sel: pnt.y, tar: curPnt.y,
                            min: cur.boundsPoints[1].y,
                            max: cur.boundsPoints[2].y)

                        var minSelY = pnt.y
                        var maxSelY = pnt.y

                        if points.count == 3 {
                            (minSelY, maxSelY) = self.findMinMax(
                                sel: minTarY, tar: pnt.y,
                                min: points[1].y, max: points[2].y)
                        }
                        let dist = abs(minTarY - minSelY)
                        if dist < minDistY {
                            minDistY = dist
                            rulerPointY = RulerPoint(
                                move: CGPoint(x: pnt.x, y: minSelY),
                                line: CGPoint(x: curPnt.x, y: minTarY),
                                maxMove: CGPoint(x: pnt.x, y: maxSelY),
                                maxLine: CGPoint(x: curPnt.x, y: maxTarY))
                        }
                    }

                    if pnt.y <= curPnt.y+setup.rulersDelta &&
                        pnt.y >= curPnt.y-setup.rulersDelta {
                        let (minTarX, maxTarX) = self.findMinMax(
                            sel: pnt.x, tar: curPnt.x,
                            min: cur.boundsPoints[1].x,
                            max: cur.boundsPoints[2].x)

                        var minSelX = pnt.x
                        var maxSelX = pnt.x

                        if points.count == 3 {
                            (minSelX, maxSelX) = self.findMinMax(
                                sel: minTarX, tar: pnt.x,
                                min: points[1].x, max: points[2].x)
                        }
                        let dist = abs(minTarX - minSelX)
                        if dist < minDistX {
                            minDistX = dist
                            rulerPointX = RulerPoint(
                                move: CGPoint(x: minSelX, y: pnt.y),
                                line: CGPoint(x: minTarX, y: curPnt.y),
                                maxMove: CGPoint(x: maxSelX, y: pnt.y),
                                maxLine: CGPoint(x: maxTarX, y: curPnt.y))
                        }
                    }
                }
            }
        }
        if rulerPointX != nil {
            rulerPoints["x"] = rulerPointX
        }
        if rulerPointY != nil {
            rulerPoints["y"] = rulerPointY
        }

        return rulerPoints
    }

    func findRulersToPoints(point: CGPoint,
                            curvePoints: [CGPoint],
                            minDistX: CGFloat,
                            minDistY: CGFloat) -> [String: RulerPoint?] {
        var rulerPoints: [String: RulerPoint?] = [:]
        var minDistX: CGFloat = minDistX
        var minDistY: CGFloat = minDistY
        var rulerPointX: RulerPoint?
        var rulerPointY: RulerPoint?
        for pnt in curvePoints {
            if point.x <= pnt.x+setup.rulersDelta &&
                point.x >= pnt.x-setup.rulersDelta {
                let distY = abs(pnt.y - point.y)
                if distY < minDistY {
                    minDistY = distY
                    rulerPointY = RulerPoint(
                    move: CGPoint(x: point.x, y: point.y),
                    line: CGPoint(x: pnt.x, y: pnt.y),
                    maxMove: CGPoint(x: point.x, y: point.y),
                    maxLine: CGPoint(x: pnt.x, y: pnt.y))
                }
            }
            if point.y <= pnt.y+setup.rulersDelta &&
                point.y >= pnt.y-setup.rulersDelta {
                let distX = abs(pnt.x - point.x)
                if distX < minDistX {
                    minDistX = distX
                    rulerPointX = RulerPoint(
                    move: CGPoint(x: point.x, y: point.y),
                    line: CGPoint(x: pnt.x, y: pnt.y),
                    maxMove: CGPoint(x: point.x, y: point.y),
                    maxLine: CGPoint(x: pnt.x, y: pnt.y))
                }
            }
        }
        if rulerPointX != nil {
            rulerPoints["x"] = rulerPointX
        }
        if rulerPointY != nil {
            rulerPoints["y"] = rulerPointY
        }
        return rulerPoints
    }

    func findMinMax(sel: CGFloat, tar: CGFloat,
                    min: CGFloat,
                    max: CGFloat) -> (min: CGFloat, max: CGFloat) {
        var minValue = tar
        var maxValue = tar

        let t1 = abs(min - sel)
        let t2 = abs(max - sel)
        if t1<t2 {
            minValue = min
            maxValue = max
        } else {
            minValue = max
            maxValue = min
        }
        return (minValue, maxValue)
    }

    func showRulers(rulerPoints: [String: RulerPoint?],
                    ctrl: Bool = false) {
        let solidPath = NSBezierPath()
        let alphaPath = NSBezierPath()

        for (_, point) in rulerPoints {
            guard let pnt = point else { continue }
            let distX = abs(pnt.move.x - pnt.line.x)
            let distY = abs(pnt.move.y - pnt.line.y)

            var move = CGPoint(x: pnt.move.x, y: pnt.move.y)
            var maxMove = CGPoint(x: pnt.maxMove.x, y: pnt.maxMove.y)
            let maxLine =  CGPoint(x: pnt.maxLine.x, y: pnt.maxLine.y)
            if distX <= setup.rulersDelta {
                move.x = pnt.line.x
                maxMove.x = pnt.line.x
            }
            if distY <= setup.rulersDelta {
                move.y = pnt.line.y
                maxMove.y = pnt.line.y
            }

            alphaPath.move(to: maxMove)
            alphaPath.line(to: move)
            alphaPath.move(to: pnt.line)
            alphaPath.line(to: maxLine)
            alphaPath.close()

            solidPath.move(to: move)
            solidPath.addPin(pos: move, size: self.dotSize / 2)
            solidPath.line(to: pnt.line)
            solidPath.addPin(pos: pnt.line, size: self.dotSize)
            solidPath.close()
        }

        self.path = solidPath.cgPath
        if let alphaLayer = self.sublayers?[0] as? CAShapeLayer {
            alphaLayer.path = alphaPath.cgPath
            alphaLayer.lineWidth = self.lineWidth
        }
    }
}
