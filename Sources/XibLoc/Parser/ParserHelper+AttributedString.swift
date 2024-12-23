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

/* To check later, but for now AttributedString is _not_ available on Linux. */
#if canImport(Darwin)

import Foundation



@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
struct AttributedStringParserHelper : ParserHelper {
	
	typealias ParsedType = AttributedString
	
	static func copy(source: AttributedString) -> AttributedString {
		return source
	}
	
	static func stringRepresentation(of source: AttributedString) -> String {
		return String(source.characters)
	}
	
	static func slice<R>(strRange: (r: R, s: String), from source: AttributedString) -> AttributedString where R : RangeExpression, R.Bound == String.Index {
		assert(strRange.s == String(source.characters))
		
		let range = Range(strRange.r, in: source)!
		return AttributedString(source[range])
	}
	
	static func remove<R>(strRange: (r: R, s: String), from source: inout AttributedString) where R : RangeExpression, R.Bound == String.Index {
		assert(strRange.s == String(source.characters))
		
		let range = Range(strRange.r, in: source)!
		source.removeSubrange(range)
	}
	
	static func replace<R>(strRange: (r: R, s: String), with replacement: AttributedString, in source: inout AttributedString) -> String where R : RangeExpression, R.Bound == String.Index {
		assert(strRange.s == String(source.characters))
		
		let range = Range(strRange.r, in: source)!
		source.replaceSubrange(range, with: replacement)
		
		return String(replacement.characters)
	}
	
}

#endif
