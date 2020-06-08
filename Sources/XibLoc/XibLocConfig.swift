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

import Logging



/**
The global configuration for XibLoc.

You can modify all of the variables in this struct to change the default
behavior of XibLoc.
Be careful, none of these properties are thread-safe. It is a good practice to
change the behaviors you want when you start your app, and then leave the config
alone.

- Note: We allow the configuration for a generic `Logger` (from Apple’s
swift-log repository), **and** an `OSLog` logger.
We do this because Apple recommends using `OSLog` directly whenever possible for
performance and privacy reason (see [swift-log’s Readme](https://github.com/apple/swift-log/blob/4f876718737f2c2b2ecd6d4cb4b99e0367b257a4/README.md)
for more informations).

The recommended configuration for Logging is to use `OSLog` when you can (you
are on an Apple platform that supports `OSLog`) and `Logger` otherwise.
You can also configure both if you want, though I’m not sure why that would be
needed.

In the future, OSLog’s API should be modified to match the swift-log’s one, and
we’ll then probably drop the support for OSLog (because you’ll be able to use
OSLog through Logging without any performance or privacy hit). */
public struct XibLocConfig {
	
	#if canImport(os)
		@available(macOS 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *)
		public static var oslog: OSLog? = .default
	#endif
	public static var logger: Logger? = {
		#if canImport(os)
		if #available(macOS 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {
			return nil
		}
		#endif
		return Logger(label: "com.happn.XibLoc")
	}()
	
	public static var defaultNumberFormatterForInts: NumberFormatter = {
		let f = NumberFormatter()
		f.numberStyle = .none
		return f
	}()
	
	public static var defaultNumberFormatterForFloats: NumberFormatter = {
		let f = NumberFormatter()
		f.numberStyle = .decimal
		return f
	}()
	
	public static var defaultEscapeToken: String? = "~"
	public static var defaultPluralityDefinition = PluralityDefinition()
	
	#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
		public static var defaultStr2AttrStrAttributes: [NSAttributedString.Key: Any]? = nil
		public static var defaultBoldAttrsChangesDescription: StringAttributesChangesDescription? = StringAttributesChangesDescription(change: .setBold)
		public static var defaultItalicAttrsChangesDescription: StringAttributesChangesDescription? = StringAttributesChangesDescription(change: .setItalic)
	#endif
	
	/**
	We give public access to the cache so you can customize it however you like.
	However, you should not access objects in it or modify them.
	
	To disable the cache, set this property to `nil`.
	
	- Important: Do **not** modify the objects in this cache. The property should
	only be modified if needed when your app starts, to customize the cache. */
	public static var cache: NSCache<ErasedParsedXibLocInitInfoWrapper, ParsedXibLocWrapper>? = {
		let c = NSCache<ErasedParsedXibLocInitInfoWrapper, ParsedXibLocWrapper>()
		c.countLimit = 1500
		return c
	}()
	
	/** This struct is simply a container for static configuration properties. */
	private init() {}
	
}
