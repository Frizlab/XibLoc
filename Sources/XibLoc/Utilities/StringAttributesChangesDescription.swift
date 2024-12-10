/*
Copyright 2019 happn

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

#if canImport(Darwin)

import Foundation

#if os(macOS)
import AppKit
public typealias XibLocFont = NSFont
public typealias XibLocColor = NSColor
#else
import UIKit
public typealias XibLocFont = UIFont
public typealias XibLocColor = UIColor
#endif



public struct StringAttributesChangesDescription : Sendable {
	
	@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
	public typealias   ChangeApplicationHandler = @Sendable (_ modified: inout AttributedString, _ range: Range<AttributedString.Index>) -> Void
	public typealias NSChangeApplicationHandler = @Sendable (_ modified: NSMutableAttributedString, _ range: NSRange /* An ObjC range */) -> Void
	
	public enum StringAttributesChangeDescription {
		
		case setBold
		case removeBold
		
		case setItalic
		case removeItalic
		
		case addStraightUnderline
		case removeUnderline
		
		case setFgColor(XibLocColor)
		case setBgColor(XibLocColor)
		
#if !os(macOS)
		case changeFont(newFont: XibLocFont, preserveSizes: Bool, preserveBold: Bool, preserveItalic: Bool)
#endif
		
		case addLink(URL)
		
		@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
		var handlerToApplyChange: ChangeApplicationHandler {
			switch self {
				case .setBold:    return { attrStr, range in attrStr.setBoldOrItalic(bold: true,  italic: nil, range: range) }
				case .removeBold: return { attrStr, range in attrStr.setBoldOrItalic(bold: false, italic: nil, range: range) }
					
				case .setItalic:    return { attrStr, range in attrStr.setBoldOrItalic(bold: nil, italic: true,  range: range) }
				case .removeItalic: return { attrStr, range in attrStr.setBoldOrItalic(bold: nil, italic: false, range: range) }
					
				case .addStraightUnderline: return { attrStr, range in attrStr[range].underlineStyle = .single }
				case .removeUnderline:      return { attrStr, range in attrStr[range].underlineStyle = nil }
					
				case .setFgColor(let color): return { attrStr, range in attrStr[range].foregroundColor = color }
				case .setBgColor(let color): return { attrStr, range in attrStr[range].backgroundColor = color }
					
#if !os(macOS)
				case .changeFont(newFont: let font, preserveSizes: let preserveSizes, preserveBold: let preserveBold, preserveItalic: let preserveItalic):
					return { attrStr, range in attrStr.setFont(font, keepOriginalSize: preserveSizes, keepOriginalIsBold: preserveBold, keepOriginalIsItalic: preserveItalic, range: range) }
#endif
					
				case .addLink(let url): return { attrStr, range in attrStr[range].link = url }
			}
		}
		
		var handlerToApplyNSChange: NSChangeApplicationHandler {
			switch self {
				case .setBold:    return { attrStr, range in attrStr.setBoldOrItalic(bold: true,  italic: nil, range: range) }
				case .removeBold: return { attrStr, range in attrStr.setBoldOrItalic(bold: false, italic: nil, range: range) }
					
				case .setItalic:    return { attrStr, range in attrStr.setBoldOrItalic(bold: nil, italic: true,  range: range) }
				case .removeItalic: return { attrStr, range in attrStr.setBoldOrItalic(bold: nil, italic: false, range: range) }
					
				case .addStraightUnderline: return { attrStr, range in attrStr.addAttribute(   .underlineStyle, value: NSUnderlineStyle.single, range: range) }
				case .removeUnderline:      return { attrStr, range in attrStr.removeAttribute(.underlineStyle,                                 range: range) }
					
				case .setFgColor(let color): return { attrStr, range in attrStr.setTextColor(color, range: range) }
				case .setBgColor(let color): return { attrStr, range in attrStr.setBackgroundColor(color, range: range) }
					
#if !os(macOS)
				case .changeFont(newFont: let font, preserveSizes: let preserveSizes, preserveBold: let preserveBold, preserveItalic: let preserveItalic):
					return { attrStr, range in attrStr.setFont(font, keepOriginalSize: preserveSizes, keepOriginalIsBold: preserveBold, keepOriginalIsItalic: preserveItalic, range: range) }
#endif
					
				case .addLink(let url): return { attrStr, range in attrStr.addAttribute(.link, value: url, range: range) }
			}
		}
		
	}
	
	@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
	public var changes: [ChangeApplicationHandler] {
		get {_changes as! [ChangeApplicationHandler]}
		set {_changes = newValue}
	}
	private var _changes: [Sendable]!
	
	public var nschanges: [NSChangeApplicationHandler]
	
	@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
	public var attributesModifications: (_ modified: inout AttributedString, _ strRange: Range<String.Index>, _ refStr: String) -> Void {
		return { attrStr, range, str in self.apply(to: &attrStr, range: Range(range, in: attrStr)!) }
	}
	
	public var nsattributesModifications: (_ modified: inout NSMutableAttributedString, _ strRange: Range<String.Index>, _ refStr: String) -> Void {
		return { attrStr, range, str in self.nsapply(to: attrStr, range: NSRange(range, in: str)) }
	}
	
	public init(change c: StringAttributesChangeDescription) {
		self.init(changes: [c])
	}
	
	public init(changes c: [StringAttributesChangeDescription]) {
		if #available(macOS 12, iOS 15, tvOS 15, watchOS 8, *) {
			_changes = c.map{ $0.handlerToApplyChange }
		}
		nschanges = c.map{ $0.handlerToApplyNSChange }
	}
	
	@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
	public func apply(to attributedString: inout AttributedString, range: Range<AttributedString.Index>) {
		for h in changes {h(&attributedString, range)}
	}
	
	public func nsapply(to attributedString: NSMutableAttributedString, range: NSRange /* An ObjC range */) {
		for h in nschanges {h(attributedString, range)}
	}
	
}

#endif
