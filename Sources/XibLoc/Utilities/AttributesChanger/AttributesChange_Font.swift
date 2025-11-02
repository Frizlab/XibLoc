/*
Copyright 2025 Frizlab

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

#if canImport(AppKit) || canImport(UIKit)

import Foundation



public struct AttributesChanger_Font : AttributesChanger {
	
	/** The new font to apply. */
	public var newFont: XibLocFont
	public var preserveSizes: Bool
	public var preserveBold: Bool
	public var preserveItalic: Bool
	
	init(newFont: XibLocFont, preserveSizes: Bool, preserveBold: Bool, preserveItalic: Bool) {
		self.newFont = newFont
		self.preserveSizes = preserveSizes
		self.preserveBold = preserveBold
		self.preserveItalic = preserveItalic
	}
	
}

extension AttributesChanger_Font : AttributedStringAttributesChanger {
	@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
	public func apply(on modified: inout AttributedString, _ range: Range<AttributedString.Index>) {
		modified.setFont(newFont, keepOriginalSize: preserveSizes, keepOriginalIsBold: preserveBold, keepOriginalIsItalic: preserveItalic, range: range)
	}
}
extension AttributesChanger_Font : NSAttributedStringAttributesChanger {
	public func apply(on modified: NSMutableAttributedString, _ range: NSRange /* An ObjC range */) {
		modified.setFont(newFont, keepOriginalSize: preserveSizes, keepOriginalIsBold: preserveBold, keepOriginalIsItalic: preserveItalic, range: range)
	}
}

#endif
