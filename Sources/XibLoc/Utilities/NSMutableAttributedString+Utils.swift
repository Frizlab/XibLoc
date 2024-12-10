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

import CoreGraphics /* CGFloat */
import Foundation



extension NSMutableAttributedString {
	
	func getFont(at index: Int, effectiveRange: inout NSRange) -> XibLocFont? {
		let attr = attribute(.font, at: index, effectiveRange: &effectiveRange)
		return attr as? XibLocFont
	}
	
	func setFont(_ font: XibLocFont, range: NSRange? = nil) {
		let range = range ?? NSRange(location: 0, length: length)
		removeAttribute(.font, range: range) /* Work around an Apple leak (according to OHAttributedLabel) */
		addAttribute(.font, value: font, range: range)
	}
	
	func setTextColor(_ color: XibLocColor, range: NSRange? = nil) {
		let range = range ?? NSRange(location: 0, length: length)
		removeAttribute(.foregroundColor, range: range) /* Work around an Apple leak (according to OHAttributedLabel) */
		addAttribute(.foregroundColor, value: color, range: range)
	}
	
	func setBackgroundColor(_ color: XibLocColor, range: NSRange? = nil) {
		let range = range ?? NSRange(location: 0, length: length)
		removeAttribute(.backgroundColor, range: range) /* Work around an Apple leak (according to OHAttributedLabel) */
		addAttribute(.backgroundColor, value: color, range: range)
	}
	
	/**
	 - Warning: If no font is defined in the given range, the method will use the preferred font for the “body” style (on iOS, watchOS and tvOS) or the system font of “system” size. */
	func setBoldOrItalic(bold: Bool?, italic: Bool?, range: NSRange? = nil) {
		let range = range ?? NSRange(location: 0, length: length)
		guard bold != nil || italic != nil else {return}
		guard range.length > 0 else {return}
		
		var curPos = range.location
		var outRange = NSRange(location: 0, length: 0)
		
		repeat {
#if !os(macOS)
			let f = getFont(at: curPos, effectiveRange: &outRange) ?? XibLocFont.preferredFont(forTextStyle: .body)
#else
			let f = getFont(at: curPos, effectiveRange: &outRange) ?? XibLocFont.systemFont(ofSize: XibLocFont.systemFontSize)
#endif
			outRange = NSIntersectionRange(outRange, range)
			
			setFont(f.fontBySetting(size: nil, isBold: bold, isItalic: italic), range: outRange)
			
			curPos = outRange.upperBound
		} while curPos < range.upperBound
	}
	
	func setFont(_ font: XibLocFont, keepOriginalSize: Bool = false, keepOriginalIsBold: Bool = false, keepOriginalIsItalic: Bool = false, range: NSRange? = nil) {
		let range = range ?? NSRange(location: 0, length: length)
		guard range.length > 0 else {return}
		
		var curPos = range.location
		var outRange = NSRange(location: 0, length: 0)
		
		repeat {
			let f = getFont(at: curPos, effectiveRange: &outRange)
			outRange = NSIntersectionRange(outRange, range)
			
			let (b, i, s) = (f?.isBold, f?.isItalic, f?.pointSize)
			setFont(font.fontBySetting(size: keepOriginalSize ? s : nil, isBold: keepOriginalIsBold ? b : nil, isItalic: keepOriginalIsItalic ? i : nil), range: outRange)
			
			curPos = outRange.upperBound
		} while curPos < range.upperBound
	}
	
}

#endif
