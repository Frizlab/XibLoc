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



public struct AttributesChanger_SetBold : AttributesChanger {}

extension AttributesChanger_SetBold : AttributedStringAttributesChanger {
	@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
	public func apply(on modified: inout AttributedString, _ range: Range<AttributedString.Index>) {
		modified.setBoldOrItalic(bold: true, italic: nil, range: range)
	}
}
extension AttributesChanger_SetBold : NSAttributedStringAttributesChanger {
	public func apply(on modified: NSMutableAttributedString, _ range: NSRange /* An ObjC range */) {
		modified.setBoldOrItalic(bold: true, italic: nil, range: range)
	}
}


public struct AttributesChanger_RemoveBold : AttributesChanger {}

extension AttributesChanger_RemoveBold : AttributedStringAttributesChanger {
	@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
	public func apply(on modified: inout AttributedString, _ range: Range<AttributedString.Index>) {
		modified.setBoldOrItalic(bold: false, italic: nil, range: range)
	}
}
extension AttributesChanger_RemoveBold : NSAttributedStringAttributesChanger {
	public func apply(on modified: NSMutableAttributedString, _ range: NSRange /* An ObjC range */) {
		modified.setBoldOrItalic(bold: false, italic: nil, range: range)
	}
}

#endif
