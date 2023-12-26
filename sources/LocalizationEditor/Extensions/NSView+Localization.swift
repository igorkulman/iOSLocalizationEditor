//
//  NSVIew+Localization.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 24/10/2019.
//  Copyright © 2019 Igor Kulman. All rights reserved.
//
// Inspired by https://github.com/PiXeL16/IBLocalizable for iOS
//

import AppKit
import Foundation

/**
 *  Localizable Protocol
 */
protocol Localizable: AnyObject {
    /// The property that can be localized for each view, for example in a UILabel its the text, in a UIButton its the title, etc
    var localizableProperty: String? { get set }

    /// The localizable string value in the your localizable strings
    var localizableString: String { get set }

    /**
     Applies the localizable string to the supported view attribute
     */
    func applyLocalizableString(_ localizableString: String?)
}

extension Localizable {
    /**
     Applies the localizable string to the supported view attribute

     - parameter localizableString: localizable String Value
     */
    public func applyLocalizableString(_ localizableString: String?) {
        localizableProperty = localizableString?.localized
    }
}

extension NSCell: Localizable {
    /// Not implemented in base class
    @objc var localizableProperty: String? {
        get {
            return ""
        }
        // swiftlint:disable unused_setter_value
        set {}
        // swiftlint:enable unused_setter_value
    }

    /// Applies the localizable string to the localizable field of the supported view
    @IBInspectable var localizableString: String {
        get {
            guard let text = self.localizableProperty else {
                return ""
            }
            return text
        }
        set {
            /**
             *  Applys the localization to the property
             */
            applyLocalizableString(newValue)
        }
    }
}

extension NSMenuItem: Localizable {
    /// Not implemented in base class
    @objc var localizableProperty: String? {
        get {
            return title
        }
        set {
            title = newValue ?? ""
        }
    }

    /// Applies the localizable string to the localizable field of the supported view
    @IBInspectable var localizableString: String {
        get {
            guard let text = self.localizableProperty else {
                return ""
            }
            return text
        }
        set {
            /**
             *  Applys the localization to the property
             */
            applyLocalizableString(newValue)
        }
    }

    func applyLocalizableString(_ localizableString: String?) {
        title = localizableString?.localized ?? ""
    }
}

extension NSMenu {
    /// Not implemented in base class
    @objc var localizableProperty: String? {
        get {
            return title
        }
        set {
            title = newValue ?? ""
        }
    }

    /// Applies the localizable string to the localizable field of the supported view
    @IBInspectable var localizableString: String {
        get {
            guard let text = self.localizableProperty else {
                return ""
            }
            return text
        }
        set {
            /**
             *  Applys the localization to the property
             */
            applyLocalizableString(newValue)
        }
    }

    func applyLocalizableString(_ localizableString: String?) {
        title = localizableString?.localized ?? ""
    }
}

extension NSSearchField {
    /// Not implemented in base class
    @objc var localizableProperty: String? {
        get {
            return placeholderString
        }
        set {
            placeholderString = newValue ?? ""
        }
    }

    /// Applies the localizable string to the localizable field of the supported view
    @IBInspectable var localizableString: String {
        get {
            guard let text = self.localizableProperty else {
                return ""
            }
            return text
        }
        set {
            /**
             *  Applys the localization to the property
             */
            applyLocalizableString(newValue)
        }
    }

    func applyLocalizableString(_ localizableString: String?) {
        placeholderString = localizableString?.localized ?? ""
    }
}

extension NSTextFieldCell {
    public override var localizableProperty: String? {
        get {
            return title
        }
        set {
            title = newValue ?? ""
        }
    }
}

extension NSButtonCell {
    public override var localizableProperty: String? {
        get {
            return title
        }
        set {
            title = newValue ?? ""
        }
    }
}

extension NSPopUpButtonCell {
    public override var localizableProperty: String? {
        get {
            return title
        }
        set {
            title = newValue ?? ""
        }
    }
}
