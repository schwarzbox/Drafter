//
//  OpenSaveTool.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 12/4/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

struct SetupGlobal {
    var saved = false
}

var setGlobal = SetupGlobal()

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
    var windingRule: Int = setCurve.windingRule
    var maskRule: Int = setCurve.maskRule
    var alpha: [CGFloat] = setCurve.alpha
    var shadow: [CGFloat] = setCurve.shadow
    var gradientDirection: [CGPoint] = setCurve.gradientDirection
    var gradientLocation: [NSNumber] = setCurve.gradientLocation
    var colors: [NSColor] = setCurve.colors
    var filterRadius: Double = setCurve.minFilterRadius

    var points: [ControlPoint] = []

    var name: String = ""
    var mask: Bool = false
    var group: Bool = false
    var lock: Bool = false
    var invisible: Bool = false
    var text: String = ""
    var textDelta: CGPoint?
    var imageScaleX: CGFloat = 1
    var imageScaleY: CGFloat = 1
}

class SaveTool {
    let view: SketchPad

    init (view: SketchPad) {
        self.view = view
    }

    func openPng(fileUrl: URL) {
        if let image = NSImage(contentsOf: fileUrl) {
            let rep = image.representations[0]
            let wid = rep.size.width
            let hei = rep.size.height
            let pixWid = CGFloat(rep.pixelsWide)
            let pixHei = CGFloat(rep.pixelsHigh)
            if let curve = view.selectedCurve {
                view.deselectCurve(curve: curve)
            }

            let topLeft = CGPoint(x: view.sketchPath.bounds.midX - wid/2,
                                  y: view.sketchPath.bounds.midY - hei/2)
            let bottomRight = CGPoint(
                x: view.sketchPath.bounds.midX + wid/2,
                y: view.sketchPath.bounds.midY + hei/2)
            if let rect = tools[3] as? Rectangle {
                rect.useTool(
                    rect.action(topLeft: topLeft,
                                bottomRight: bottomRight))
            }
            view.newCurve()
            if let curve = view.selectedCurve {
                curve.initImageLayer(image: image,
                                     scaleX: CGFloat(wid) / pixWid,
                                     scaleY: CGFloat(hei) / pixHei)

                curve.setName(name: "image", curves: view.curves)
            }
        }
    }

    func openDrf(fileUrl: URL) {
        let filePaths = openDir(fileUrl: fileUrl)
        var drf = Drf()
        for path in filePaths where path.hasSuffix("drf") {
            do {
                let fileUrl = fileUrl.appendingPathComponent(path)
                let file = try String(contentsOf: fileUrl, encoding: .utf8)
                var groups: [Curve] = []
                defer {
                    if groups.count>0 {
                        groups[0].setGroups(curves: Array(groups.dropFirst()))
                    }
                }
                for line in file.split(separator: "\n") {
                    if line == "-" {
                        let curve = self.openCurve(drf: drf,
                                                  fileUrl: fileUrl)
                        if drf.group {
                            groups.append(curve)
                        } else {
                            if groups.count>0 {
                                groups[0].setGroups(
                                    curves: Array(groups.dropFirst()))
                                groups.removeAll()
                            }
                            groups.append(curve)
                            view.addCurve(curve: curve)
                        }
                        drf = Drf()
                    }
                    self.parseLine(drf: &drf, line: String(line))
                }
            } catch {
               print(error.localizedDescription)
            }
        }
    }

    func openDir(fileUrl: URL) -> [String] {
        var filePaths: [String] = []
        do {
            filePaths = try FileManager.default.contentsOfDirectory(
                atPath: fileUrl.relativePath)
        } catch {
            print(error.localizedDescription)
        }
        return filePaths
    }

    func makeCurve(drf: Drf) -> Curve {
        let curve = view.initCurve(
            path: drf.path, fill: drf.fill, rounded: drf.rounded,
            angle: CGFloat(drf.angle),
            lineWidth: drf.lineWidth,
            cap: drf.cap, join: drf.join,
            miter: drf.miter,
            dash: drf.dash,
            windingRule: drf.windingRule,
            maskRule: drf.maskRule,
            alpha: drf.alpha,
            shadow: drf.shadow,
            gradientDirection: drf.gradientDirection,
            gradientLocation: drf.gradientLocation,
            colors: drf.colors,
            filterRadius: drf.filterRadius,
            points: drf.points)

        let name = String(drf.name.split(separator: " ")[0])
        curve.setName(name: name, curves: view.curves)
        curve.mask = drf.mask
        curve.lock = drf.lock
        curve.canvas.isHidden = drf.invisible
        curve.text = drf.text
        curve.textDelta = drf.textDelta

        return curve
    }

    func openCurve(drf: Drf, fileUrl: URL) -> Curve {
        let curve = self.makeCurve(drf: drf)

        let dirUrl = fileUrl.deletingLastPathComponent()
        let imgUrl = dirUrl.appendingPathComponent(drf.name + ".tiff")
        if let image = NSImage(contentsOf: imgUrl) {
            curve.initImageLayer(image: image,
                                 scaleX: drf.imageScaleX,
                                 scaleY: drf.imageScaleY)
        }
        view.layer?.addSublayer(curve.canvas)
        return curve
    }
    

    func parseLine(drf: inout Drf, line: String) {
        if let sp = line.firstIndex(of: " ") {
            let str = String(line.suffix(from: sp).dropFirst())
            switch line.prefix(upTo: sp) {
            case "-name": drf.name = str
            case "-path": drf.path = drf.path.stringToPath(str: str)
            case "-points":
                var points: [ControlPoint] = []
                for line in str.split(separator: "|") {
                    let floats = line.split(separator: " ").map {
                        CGFloat(Double($0) ?? 0.0)}
                    var pnt: [CGPoint] = []
                    for i in stride(from: 0, to: floats.count, by: 2) {
                        pnt.append(CGPoint(x: floats[i],
                                           y: floats[i+1]))
                    }
                    points.append(ControlPoint(view,
                                               cp1: pnt[0],
                                               cp2: pnt[1],
                                               mp: pnt[2]))
                }
                drf.points = points
            case "-fill": drf.fill = Bool(str) ?? true
            case "-rounded":
                if !str.isEmpty {
                    let float = str.split(separator: " ")
                    drf.rounded = CGPoint(
                        x: CGFloat(Double(float[0]) ?? 0.0),
                        y: CGFloat(Double(float[1]) ?? 0.0))
                }
            case "-angle": drf.angle = Double(str) ?? 0.0
            case "-lineWidth":
                drf.lineWidth = CGFloat(Double(str) ?? 0.0)
            case "-cap": drf.cap = Int(str) ?? 0
            case "-join": drf.join = Int(str) ?? 0
            case "-miter":
                drf.miter = CGFloat(Double(str) ?? 0.0)
            case "-dash":
                let dash = str.split(separator: " ").map {
                    NSNumber(value: Int($0) ?? 0)}
                drf.dash = dash
            case "-windingRule": drf.windingRule = Int(str) ?? 0
            case "-maskRule": drf.maskRule = Int(str) ?? 0
            case "-alpha":
                drf.alpha = str.split(separator: " ").map {
                    CGFloat(Double($0) ?? 0.0)}
            case "-shadow":
                drf.shadow = str.split(separator: " ").map {
                    CGFloat(Double($0) ?? 0.0)}
            case "-gradientDirection":
                let dir = str.split(separator: " ").map {
                    CGFloat(Double($0) ?? 0.0)}
                drf.gradientDirection = [CGPoint(x: dir[0], y: dir[1]),
                                         CGPoint(x: dir[2], y: dir[3])]
            case "-gradientLocation":
                drf.gradientLocation = str.split(separator: " ").map {
                    NSNumber(value: Double(String($0)) ?? 0) }
            case "-colors":
                let cmp = str.split(separator: " ").map {
                    CGFloat(Double($0) ?? 0.0)}
                var colors: [NSColor] = []
                for i in stride(from: 0, to: cmp.count, by: 3) {
                    let clr = NSColor(
                        red: cmp[i], green: cmp[i+1], blue: cmp[i+2],
                        alpha: 1)
                    colors.append(clr.sRGB())
                }
                drf.colors = colors
            case "-filterRadius": drf.filterRadius = Double(str) ?? 0.0
            case "-mask": drf.mask = true
            case "-group": drf.group = true
            case "-lock": drf.lock = true
            case "-invisible": drf.invisible = true
            case "-text": drf.text = str
            case "-textDelta":
                if !str.isEmpty {
                    let float = str.split(separator: " ")
                    drf.textDelta = CGPoint(
                        x: CGFloat(Double(float[0]) ?? 0.0),
                        y: CGFloat(Double(float[1]) ?? 0.0))
                }
            case "-imageScaleX":
                drf.imageScaleX = CGFloat(Double(str) ?? 0.0)
            case "-imageScaleY":
                drf.imageScaleY = CGFloat(Double(str) ?? 0.0)
            default: break
            }
        }
    }

    func openSvg(fileUrl: URL) {
        print("open svg")
    }

    func savePng(fileUrl: URL) {
        if let image = view.imageData() {
            do {
                try image.write(to: fileUrl, options: .atomic)

            } catch {
                print(error.localizedDescription)
            }
        }
    }

    func makeDrf() -> String {
        var code: String = ""
        for curve in view.curves {
            for (ind, cur) in curve.groups.enumerated() {
                code += ("-name " + cur.name + "\n")
                if let path = cur.path.copy() as? NSBezierPath {
                    code += "-path " + path.pathToString() + "\n"
                    code += "-points "
                    for point in cur.points {
                        code += point.stringPoint() + "|"
                    }
                }
                code += "\n"
                code += "-fill " + String(cur.fill) + "\n"
                code += "-rounded "
                let rounded = cur.rounded != nil
                    ? (String(Double(cur.rounded?.x ?? 0)) + " " +
                        String(Double(cur.rounded?.y ?? 0))) + "\n"
                    : "\n"
                code += rounded
                code += "-angle " + String(Double(cur.angle)) + "\n"
                code += "-lineWidth " + String(Double(cur.lineWidth)) + "\n"
                code += "-cap " + String(cur.cap) + "\n"
                code += "-join " + String(cur.join) + "\n"
                code += "-miter " + String(Double(cur.miter)) + "\n"
                code += "-dash "
                let dash = cur.dash.map {String(
                    Int(truncating: $0))}.joined(separator: " ")
                code += dash + "\n"
                code += "-windingRule " + String(cur.windingRule) + "\n"
                code += "-maskRule " + String(cur.maskRule) + "\n"
                code += "-alpha "
                let alpha = cur.alpha.map {String(
                    Double($0))}.joined(separator: " ")
                code += alpha + "\n"
                code += "-shadow "
                let shadow = cur.shadow.map {String(
                    Double($0))}.joined(separator: " ")
                code += shadow + "\n"
                code += "-gradientDirection "
                let gradDir = cur.gradientDirection.map {(String(
                    Double($0.x)) + " " + String(
                        Double($0.y)) )}.joined(separator: " ")
                code += gradDir + "\n"
                code += "-gradientLocation "
                let gradLoc = cur.gradientLocation.map {String(
                    Double(truncating: $0))}.joined(separator: " ")
                code += gradLoc + "\n"
                code += "-colors "
                let clr = cur.colors.map {
                    String(Double($0.redComponent)) + " " +
                    String(Double($0.greenComponent)) + " " +
                    String(Double($0.blueComponent))
                }.joined(separator: " ")
                code += clr + "\n"
                code += "-filterRadius " + String(
                    Double(cur.filterRadius)) + "\n"
                if cur.mask { code += "-mask \n" }
                if ind > 0 { code += "-group \n" }
                if cur.lock { code += "-lock \n" }
                if cur.canvas.isHidden { code += "-invisible \n" }
                if !cur.text.isEmpty {code += "-text " + cur.text + "\n"}
                code += "-textDelta "
                let textDelta = cur.textDelta != nil
                    ? (String(Double(cur.textDelta?.x ?? 0)) + " " +
                        String(Double(cur.textDelta?.y ?? 0))) + "\n"
                    : "\n"
                code += textDelta
                code += "-imageScaleX " +
                    String(Double(cur.imageScaleX)) + "\n"
                code += "-imageScaleY " +
                    String(Double(cur.imageScaleY)) + "\n"
                code += "-\n"
            }
        }
        return code
    }

    func saveDrf(fileUrl: URL) {
        let code = self.makeDrf()
        do {
            try code.write(to: fileUrl, atomically: false, encoding: .utf8)
        } catch {
            print(error.localizedDescription)
        }
    }

    func saveSvg(fileUrl: URL) {
        
    }
}
