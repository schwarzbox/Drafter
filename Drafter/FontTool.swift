//
//  FontTool.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 10/6/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

class FontTool: NSStackView {
    @IBOutlet weak var sketchView: SketchPad!
    @IBOutlet weak var inputField: InputTool!
    @IBOutlet weak var popFontFamily: NSPopUpButton!
    @IBOutlet weak var popFontType: NSPopUpButton!
    @IBOutlet weak var sliderFontSize: ActionSlider!

    var zoomed: CGFloat = 1

    var fontFamily: String = setEditor.fontFamily
    var fontType: String = setEditor.fontType
    var fontSize: CGFloat = CGFloat(setEditor.fontSize)
    var fontMembers = [[Any]]()
    var sharedFont: NSFont?
    var inputFont: NSFont?

    func setupFontTool() {
        self.setupFontFamily()
        self.popFontFamily.selectItem(withTitle: setEditor.fontFamily)
        let fFam = self.popFontFamily.titleOfSelectedItem ??
            setEditor.fontFamily
        self.popFontFamily.setTitle(fFam)
        self.setupFontMembers()
        self.setupFontType()
        self.popFontType.selectItem(withTitle: setEditor.fontType)
        let titType = self.popFontType.titleOfSelectedItem ??
            setEditor.fontType
        self.popFontType.setTitle(titType)

        self.setupFontSize()
        self.setupFont()
    }

    func setupFontFamily() {
        self.popFontFamily.removeAllItems()
        for fam in NSFontManager.shared.availableFontFamilies {
            if setEditor.fonts.contains(fam) {
                self.popFontFamily.addItem(withTitle: fam)
            }
        }
    }

    func setupFontMembers() {
        if let members = NSFontManager.shared.availableMembers(
            ofFontFamily: self.fontFamily) {
            self.fontMembers.removeAll()
            self.fontMembers = members
        }
    }

    func setupFontType() {
        self.popFontType.removeAllItems()
        for member in self.fontMembers {
            if let type = member[1] as? String {
                self.popFontType.addItem(withTitle: type)
            }
        }
    }

    func setupFontSize() {
        self.sliderFontSize.doubleValue = setEditor.fontSize
        self.sliderFontSize.minValue = setEditor.minFont
        self.sliderFontSize.maxValue = setEditor.maxFont
    }

    func setupFont() {
        let member = self.fontMembers[popFontType.indexOfSelectedItem]
        if let weight = member[2] as? Int, let traits = member[3] as? UInt {
            self.sharedFont = NSFontManager.shared.font(
                withFamily: self.fontFamily,
                traits: NSFontTraitMask(rawValue: traits),
                weight: weight, size: self.fontSize)


            self.inputFont = NSFontManager.shared.font(
                withFamily: self.fontFamily,
                traits: NSFontTraitMask(rawValue: traits),
                weight: weight, size: self.fontSize * sketchView.zoomed)
        }
        if let font = self.inputFont {
            self.inputField.font = font
            self.inputField.resize()
        }
    }

    @IBAction func selectFont(_ sender: NSPopUpButton) {
        if let family = sender.titleOfSelectedItem {
            self.fontFamily = family
            sender.title = family

            self.setupFontMembers()

            self.setupFontType()
            let fType = self.popFontType.selectedItem?.title ??
                setEditor.fontType
            self.fontType = fType

            self.setupFont()
        }
    }

    @IBAction func selectType(_ sender: NSPopUpButton) {
        if let type = sender.titleOfSelectedItem {
            self.fontType = type
            sender.title = type
            self.setupFont()
        }
    }

    @IBAction func selectSize(_ sender: Any) {
        var val: Double = 1
        if let sl = sender as? NSSlider {
            val = sl.doubleValue
        } else if let tf = sender as? NSTextField {
            val = tf.doubleValue
        }
        let lim = val<1 ? 1 : val
        self.sliderFontSize.doubleValue = lim
        self.fontSize = CGFloat(val)

        self.setupFont()
    }

}
