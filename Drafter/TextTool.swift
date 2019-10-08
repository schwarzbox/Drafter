//
//  TextTool.swift
//  Drafter
//
//  Created by Alex Veledzimovich on 10/6/19.
//  Copyright © 2019 Alex Veledzimovich. All rights reserved.
//

import Cocoa

class TextTool: NSStackView {
    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var popFontFamily: NSPopUpButton!
    @IBOutlet weak var popFontType: NSPopUpButton!

    var fontFamily: String = setup.fontFamily
    var fontType: String = setup.fontType
    var fontSize: CGFloat = setup.fontSize
    var fontMembers = [[Any]]()
    var sharedFont: NSFont?

    func setupTextTool() {
        self.setupFontFamily()
        self.popFontFamily.selectItem(withTitle: setup.fontFamily)
        let titFam = self.popFontFamily.titleOfSelectedItem ?? setup.fontFamily
        self.popFontFamily.setTitle(titFam)
        self.setupFontMembers()
        self.setupFontType()
        self.popFontType.selectItem(withTitle: setup.fontType)
        let titType = self.popFontType.titleOfSelectedItem ?? setup.fontType
        self.popFontType.setTitle(titType)
        self.setupFont()

    }

    func setupFontFamily() {
        self.popFontFamily.removeAllItems()
        self.popFontFamily.addItems(
            withTitles: NSFontManager.shared.availableFontFamilies)
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
        self.popFontType.selectItem(at: 0)
    }

    func setupFont() {
        let member = self.fontMembers[popFontType.indexOfSelectedItem]
        if let weight = member[2] as? Int, let traits = member[3] as? UInt {
            self.sharedFont = NSFontManager.shared.font(
                withFamily: self.fontFamily,
                traits: NSFontTraitMask(rawValue: traits),
                weight: weight, size: self.fontSize)
        }
    }

    func hide() {
        self.isHidden = true
        if let txt = self.arrangedSubviews.first as? NSTextField {
            txt.isEnabled = false
        }
    }

    func show() {
        self.isHidden = false
        if let txt = self.arrangedSubviews.first as? NSTextField {
            txt.isEnabled = true
        }
    }

    @IBAction func selectFont(_ sender: NSPopUpButton) {
        if let family = sender.titleOfSelectedItem {
            self.fontFamily = family
            sender.title = family

            self.setupFontMembers()

            self.setupFontType()
            let titType = self.popFontType.selectedItem?.title ?? setup.fontType
            self.fontType = titType

            self.setupFont()
            if let font = self.sharedFont {
                self.textField.font = font
            }
        }
    }

    @IBAction func selectType(_ sender: NSPopUpButton) {
        if let type = sender.titleOfSelectedItem {
            self.fontType = type
            sender.title = type
            self.setupFont()
            if let font = self.sharedFont {
                self.textField.font = font
            }
        }
    }

}
