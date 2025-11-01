/*
Copyright 2021 happn

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

import CoreGraphics /* CGFloat */
import Foundation

import GlobalConfModule


#if os(macOS)
import AppKit
public typealias XibLocFont = NSFont
public extension XibLocFont {
	var sendableFont: some Sendable {
		return SendableFont(self)
	}
}
/* Unless I’m mistaken, this is Sendable because we copy the font for storage and restitution. */
internal struct SendableFont : @unchecked Sendable {
	internal init(_ font: NSFont) {
		self._font = font.copy() as! NSFont
	}
	internal var font: NSFont {
		return _font.copy() as! NSFont
	}
	private let _font: NSFont
}
#else
import UIKit
public typealias XibLocFont = UIFont
public extension XibLocFont {
	var sendableFont: some Sendable {
		return self
	}
}
internal struct SendableFont : Sendable {
	internal let font: UIFont
	internal init(_ font: UIFont) {
		self.font = font
	}
}
#endif


extension XibLocFont {
	
	static var xl_preferredFont: XibLocFont {
#if !os(macOS)
		return XibLocFont.preferredFont(forTextStyle: .body)
#else
		return XibLocFont.systemFont(ofSize: XibLocFont.systemFontSize)
#endif
	}
	
	var isBold: Bool {
#if !os(macOS)
		return fontDescriptor.symbolicTraits.contains(.traitBold)
#else
		return fontDescriptor.symbolicTraits.contains(.bold)
#endif
	}
	
	var isItalic: Bool {
#if !os(macOS)
		return fontDescriptor.symbolicTraits.contains(.traitItalic)
#else
		return fontDescriptor.symbolicTraits.contains(.italic)
#endif
	}
	
	func fontBySetting(size: CGFloat?, isBold: Bool?, isItalic: Bool?) -> XibLocFont {
		var fontDesc = fontDescriptor
		
		if let bold = isBold {
#if !os(macOS)
			if bold {fontDesc = fontDesc.withSymbolicTraits(fontDesc.symbolicTraits.union(.traitBold))       ?? fontDesc}
			else    {fontDesc = fontDesc.withSymbolicTraits(fontDesc.symbolicTraits.subtracting(.traitBold)) ?? fontDesc}
#else
			if bold {fontDesc = fontDesc.withSymbolicTraits(fontDesc.symbolicTraits.union(.bold))}
			else    {fontDesc = fontDesc.withSymbolicTraits(fontDesc.symbolicTraits.subtracting(.bold))}
#endif
		}
		
		if let italic = isItalic {
#if !os(macOS)
			if italic {fontDesc = fontDesc.withSymbolicTraits(fontDesc.symbolicTraits.union(.traitItalic))       ?? fontDesc}
			else      {fontDesc = fontDesc.withSymbolicTraits(fontDesc.symbolicTraits.subtracting(.traitItalic)) ?? fontDesc}
#else
			if italic {fontDesc = fontDesc.withSymbolicTraits(fontDesc.symbolicTraits.union(.italic))}
			else      {fontDesc = fontDesc.withSymbolicTraits(fontDesc.symbolicTraits.subtracting(.italic))}
#endif
		}
		
#if !os(macOS)
		return XibLocFont(descriptor: fontDesc, size: size ?? fontDesc.pointSize)
#else
		guard let f = XibLocFont(descriptor: fontDesc, size: size ?? fontDesc.pointSize) else {
			Conf.logger?.warning("Cannot create new font from original font descriptor; returning original font.")
			return self
		}
		return f
#endif
	}
	
}

#else

public typealias XibLocFont = Never

#endif
