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

#if !canImport(os) && canImport(DummyLinuxOSLog)
	import DummyLinuxOSLog
#endif



public struct DependencyInjection {
	
	init() {
		#if canImport(os)
			if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {log = .default}
			else                                                          {log = nil}
		#else
			log = nil
		#endif
	}
	
	public var log: OSLog?
	
	public var defaultEscapeToken: String? = nil
	public var defaultPluralityDefinition = PluralityDefinition()
	
	#if !os(Linux)
	public var defaultStr2AttrStrAttributes: [NSAttributedString.Key: Any]? = nil
	public var defaultBoldAttrsChangesDescription: StringAttributesChangesDescription? = StringAttributesChangesDescription(changes: [.setBold])
	public var defaultItalicAttrsChangesDescription: StringAttributesChangesDescription? = StringAttributesChangesDescription(changes: [.setItalic])
	#endif
	
	/** We give public access to the cache so you can customize it however you
	like. However, you should not access objects in it or modify them.
	
	To disable the cache, set this property to `nil`.
	
	- Important: Do **not** modify the objects in this cache. The property should
	only be modified if needed when your app starts, to customize the cache. */
	public var cache: NSCache<ErasedParsedXibLocInitInfoWrapper, ParsedXibLocWrapper>? = {
		let c = NSCache<ErasedParsedXibLocInitInfoWrapper, ParsedXibLocWrapper>()
		c.countLimit = 1500
		return c
	}()
	
}

public var di = DependencyInjection()
