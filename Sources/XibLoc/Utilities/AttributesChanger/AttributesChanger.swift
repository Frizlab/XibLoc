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

import Foundation
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif



public protocol AttributesChanger : Sendable {}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public protocol AttributedStringAttributesChanger : AttributesChanger {
	
	func apply(on modified: inout AttributedString, _ range: Range<AttributedString.Index>)
	
}

public protocol NSAttributedStringAttributesChanger : AttributesChanger {
	
	func apply(on modified: NSMutableAttributedString, _ range: NSRange /* An ObjC range */)
	
}


@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension AttributedStringAttributesChanger {
	
	func apply(on modified: inout AttributedString, in strRange: Range<String.Index>, of refStr: String) {
		assert(String(modified.characters) == refStr)
		apply(on: &modified, Range(strRange, in: modified)!)
	}
	
}

public extension NSAttributedStringAttributesChanger {
	
	func apply(on modified: inout NSMutableAttributedString, in strRange: Range<String.Index>, of refStr: String) {
		assert(modified.string == refStr)
		apply(on: modified, NSRange(strRange, in: refStr))
	}
	
}
