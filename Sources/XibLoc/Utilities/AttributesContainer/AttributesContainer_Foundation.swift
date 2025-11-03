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



/* Sendability is unchecked because we have to store the AttributedString attributes as Any, to be compatible with macOS < 12, etc. */
public struct AttributesContainer_Foundation : AttributesContainer, @unchecked Sendable {
	
	@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
	public var attributedStringAttributes: AttributeContainer {
		get {_attributedStringAttributes as! AttributeContainer}
		set {_attributedStringAttributes = newValue}
	}
	public var nsAttributedStringAttributes: [NSAttributedString.Key: Any] {
		nsAttributedStringAttributesFactory()
	}
	
	/**
	 The factory that generates ``nsAttributedStringAttributes``.
	 
	 `AttributesContainer_Foundation` must be `Sendable`, because `AttributesContainer` is a protocol that conforms to `Sendable`
	  (and that must be because the protocol is used in the GlobalConf of the module).
	 
	 The attributes of an `NSAttributedString` are inherently non-`Sendable` (value of the dictionary is `Any`, with a trivial example of a stored `NSFont` on macOS).
	 
	 So we have to store an `@Sendable` factory that will generate the attributes every time to return them… */
	public var nsAttributedStringAttributesFactory: @Sendable () -> [NSAttributedString.Key: Any]
	
	@_disfavoredOverload
	public init(nsAttributedStringAttributesFactory: @escaping @Sendable () -> [NSAttributedString.Key: Any] = { [:] }) {
		if #available(macOS 12, iOS 15, tvOS 15, watchOS 8, *) {
			self._attributedStringAttributes = AttributeContainer()
		} else {
			self._attributedStringAttributes = nil
		}
		self.nsAttributedStringAttributesFactory = nsAttributedStringAttributesFactory
	}
	
	@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
	public init(
		attributedStringAttributes: AttributeContainer = .init(),
		nsAttributedStringAttributesFactory: @escaping @Sendable () -> [NSAttributedString.Key : Any] = { [:] }
	) {
		self._attributedStringAttributes = attributedStringAttributes
		self.nsAttributedStringAttributesFactory = nsAttributedStringAttributesFactory
	}
	
	private var _attributedStringAttributes: Any!
	
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributesContainer_Foundation :   AttributedStringAttributesContainer {}
extension AttributesContainer_Foundation : NSAttributedStringAttributesContainer {}
