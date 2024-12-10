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
#if canImport(OSLog)
import OSLog
#endif

import GlobalConfModule
import Logging



public extension ConfKeys {
	/* XibLoc conf namespace declaration. */
	struct XibLoc {}
	var xibLoc: XibLoc {XibLoc()}
}


extension ConfKeys.XibLoc {
	
#if canImport(OSLog)
	#declareConfKey("oslog",  OSLog?         .self, defaultValue: OSLog(subsystem: "me.frizlab.XibLoc", category: "Main"))
	#declareConfKey("logger", Logging.Logger?.self, defaultValue: nil)
#else
	#declareConfKey("logger", Logging.Logger?.self, defaultValue: .init(label: "me.frizlab.XibLoc"))
#endif
	
	#declareConfKey("defaultNumberFormatterForInts", NumberFormatter.self, defaultValue: {
		let f = NumberFormatter()
		f.numberStyle = .none
		return f
	}())
	#declareConfKey("defaultNumberFormatterForFloats", NumberFormatter.self, defaultValue: {
		let f = NumberFormatter()
		f.numberStyle = .decimal
		return f
	}())
	
	#declareConfKey("defaultEscapeToken",                      String.self, defaultValue: "~")
	#declareConfKey("defaultPluralityDefinition", PluralityDefinition.self, defaultValue: PluralityDefinition(matchingNothing: ()))
	
#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
	@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
	#declareConfKey("defaultStr2AttrStrAttributes", AttributeContainer.self, defaultValue: .init())
	#declareConfKey("defaultStr2NSAttrStrAttributes", [NSAttributedString.Key: Any]?.self, defaultValue: nil)
	#declareConfKey("defaultBoldAttrsChangesDescription", StringAttributesChangesDescription?.self, defaultValue: .init(change: .setBold))
	#declareConfKey("defaultItalicAttrsChangesDescription", StringAttributesChangesDescription?.self, defaultValue: .init(change: .setItalic))
#endif
	
	/**
	 We give public access to the cache so you can customize it however you like.
	 However, you should not access objects in it or modify them.
	 
	 To disable the cache, set this property to `nil`.
	 
	 - Important: Do **not** modify the objects in this cache. The property should
	  only be modified if needed when your app starts, to customize the cache. */
	#declareConfKey("cache", NSCache<ErasedParsedXibLocInitInfoWrapper, ParsedXibLocWrapper>?.self, unsafeNonIsolated: true, defaultValue: {
		let c = NSCache<ErasedParsedXibLocInitInfoWrapper, ParsedXibLocWrapper>()
		c.countLimit = 1500
		return c
	}())
	
}


extension Conf {
	
#if canImport(os)
	#declareConfAccessor(\.xibLoc.oslog,  OSLog?         .self)
#endif
	#declareConfAccessor(\.xibLoc.logger, Logging.Logger?.self)
	
	#declareConfAccessor(\.xibLoc.defaultNumberFormatterForInts,   NumberFormatter.self)
	#declareConfAccessor(\.xibLoc.defaultNumberFormatterForFloats, NumberFormatter.self)
	
	#declareConfAccessor(\.xibLoc.defaultEscapeToken,                      String.self)
	#declareConfAccessor(\.xibLoc.defaultPluralityDefinition, PluralityDefinition.self)
	
#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
	@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
	#declareConfAccessor(\.xibLoc.defaultStr2AttrStrAttributes,                          AttributeContainer.self)
	#declareConfAccessor(\.xibLoc.defaultStr2NSAttrStrAttributes,            [NSAttributedString.Key: Any]?.self)
	#declareConfAccessor(\.xibLoc.defaultBoldAttrsChangesDescription,   StringAttributesChangesDescription?.self)
	#declareConfAccessor(\.xibLoc.defaultItalicAttrsChangesDescription, StringAttributesChangesDescription?.self)
#endif
	
//	#declareConfAccessor(\.xibLoc.cache, NSCache<ErasedParsedXibLocInitInfoWrapper, ParsedXibLocWrapper>?.self)
	internal static var cache: NSCache<ErasedParsedXibLocInitInfoWrapper, ParsedXibLocWrapper>? {
		Conf[\.xibLoc.cache].value
	}
	
}
