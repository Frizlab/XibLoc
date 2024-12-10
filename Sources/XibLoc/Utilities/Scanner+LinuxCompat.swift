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



extension Scanner {
	
	func xl_scanString(_ string: String) -> String? {
#if canImport(Darwin)
		if #available(OSX 10.15, tvOS 13.0, iOS 13.0, watchOS 6.0, *) {
			return scanString(string)
		} else {
			var result: NSString?
			guard scanString(string, into: &result) else {return nil}
			return result! as String
		}
#else
		return scanString(string)
#endif
	}
	
	func xl_scanUpToString(_ string: String) -> String? {
#if canImport(Darwin)
		if #available(macOS 10.15, tvOS 13.0, iOS 13.0, watchOS 6.0, *) {
			return scanUpToString(string)
		} else {
			var result: NSString?
			guard scanUpTo(string, into: &result) else {return nil}
			return result! as String
		}
#else
		return scanUpToString(string)
#endif
	}
	
	func xl_scanCharacters(from set: CharacterSet) -> String? {
#if canImport(Darwin)
		if #available(macOS 10.15, tvOS 13.0, iOS 13.0, watchOS 6.0, *) {
			return scanCharacters(from: set)
		} else {
			var result: NSString?
			guard scanCharacters(from: set, into: &result) else {return nil}
			return result! as String
		}
#else
		return scanCharacters(from: set)
#endif
	}
	
}
