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



public struct AttributesChanger_Aggregate : AttributesChanger {
	
	public var changes: [any AttributesChanger]
	public init(_ changes: [any AttributesChanger]) {
		self.changes = changes
	}
	
}

extension AttributesChanger_Aggregate : AttributedStringAttributesChanger {
	@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
	public func apply(on modified: inout AttributedString, _ range: Range<AttributedString.Index>) {
		for change in (changes.compactMap{ $0 as? AttributedStringAttributesChanger }) {
			change.apply(on: &modified, range)
		}
	}
}
extension AttributesChanger_Aggregate : NSAttributedStringAttributesChanger {
	public func apply(on modified: NSMutableAttributedString, _ range: NSRange /* An ObjC range */) {
		for change in (changes.compactMap{ $0 as? NSAttributedStringAttributesChanger }) {
			change.apply(on: modified, range)
		}
	}
}
