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
/* Note: We do not check whether it is possible to import AppKit; instead we check whether we’re on macOS.
 * This avoids an issue where when building for Catalyst where importing AppKit is possible but not the one we care about. */
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif



public struct AttributesChanger_ForegroundColor : AttributesChanger {
	/** The new color to apply. If `nil`, removes the attribute. */
	public var newColor: XibLocColor?
	public init(newColor: XibLocColor? = nil) {self.newColor = newColor}
}

extension AttributesChanger_ForegroundColor : AttributedStringAttributesChanger {
	@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
	public func apply(on modified: inout AttributedString, _ range: Range<AttributedString.Index>) {
		modified[range].foregroundColor = newColor
	}
}
extension AttributesChanger_ForegroundColor : NSAttributedStringAttributesChanger {
	public func apply(on modified: NSMutableAttributedString, _ range: NSRange /* An ObjC range */) {
		modified.setTextColor(newColor, range: range)
	}
}


public struct AttributesChanger_BackgroundColor : AttributesChanger {
	/** The new color to apply. If `nil`, removes the attribute. */
	public var newColor: XibLocColor?
	public init(newColor: XibLocColor? = nil) {self.newColor = newColor}
}

extension AttributesChanger_BackgroundColor : AttributedStringAttributesChanger {
	@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
	public func apply(on modified: inout AttributedString, _ range: Range<AttributedString.Index>) {
		modified[range].backgroundColor = newColor
	}
}
extension AttributesChanger_BackgroundColor : NSAttributedStringAttributesChanger {
	public func apply(on modified: NSMutableAttributedString, _ range: NSRange /* An ObjC range */) {
		modified.setBackgroundColor(newColor, range: range)
	}
}

#endif
