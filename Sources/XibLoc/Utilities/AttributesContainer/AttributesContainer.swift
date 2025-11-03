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
#if canImport(os)
import os.log
#endif

import GlobalConfModule



/* Not sure why Foundation’s struct for that does not pluralize attribute.
 * They are probably and I’m probably wrong, but I have used the plural version everywhere, so I’m not changing it. */
public protocol AttributesContainer : Sendable {}


@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public protocol AttributedStringAttributesContainer : AttributesContainer {
	
	var attributedStringAttributes: AttributeContainer {get}
	
}
@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension AttributesContainer {
	
	var attributedStringAttributes: AttributeContainer {
		guard let container = self as? AttributedStringAttributesContainer else {
#if canImport(os)
			if #available(macOS 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {
				Conf.oslog.flatMap{ os_log("Asked attributedStringAttributes on an attributes container which is not an AttributedStringAttributesContainer. Returning an empty container.", log: $0, type: .info) }}
#endif
			Conf.logger?.warning("Asked attributedStringAttributes on an attributes container which is not an AttributedStringAttributesContainer. Returning an empty container.")
			return .init()
		}
		return container.attributedStringAttributes
	}
	
}


public protocol NSAttributedStringAttributesContainer : AttributesContainer {
	
	var nsAttributedStringAttributes: [NSAttributedString.Key: Any] {get}
	
}
public extension AttributesContainer {
	
	var nsAttributedStringAttributes: [NSAttributedString.Key: Any] {
		guard let container = self as? NSAttributedStringAttributesContainer else {
#if canImport(os)
			if #available(macOS 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {
				Conf.oslog.flatMap{ os_log("Asked nsAttributedStringAttributes on an attributes container which is not an NSAttributedStringAttributesContainer. Returning an empty container.", log: $0, type: .info) }}
#endif
			Conf.logger?.warning("Asked nsAttributedStringAttributes on an attributes container which is not an NSAttributedStringAttributesContainer. Returning an empty container.")
			return [:]
		}
		return container.nsAttributedStringAttributes
	}
	
}
