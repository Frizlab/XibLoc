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

import Foundation



public struct AttributesChanger_Link : AttributesChanger {
	/** The new URL to apply. If `nil`, removes the attribute. */
	public var newURL: URL?
	public init(newURL: URL? = nil) {self.newURL = newURL}
}

extension AttributesChanger_Link : AttributedStringAttributesChanger {
	@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
	public func apply(on modified: inout AttributedString, _ range: Range<AttributedString.Index>) {
		modified[range].link = newURL
	}
}

/* The link attribute exists on the OpenSource Foundation, but only for AttributedString, not for NSAttributedString. */
#if os(Darwin)
extension AttributesChanger_Link : NSAttributedStringAttributesChanger {
	public func apply(on modified: NSMutableAttributedString, _ range: NSRange /* An ObjC range */) {
		if let newStyle {attrStr.addAttribute(   .link, value: newURL, range: range)}
		else            {attrStr.removeAttribute(.link,                range: range)}
	}
}
#endif
