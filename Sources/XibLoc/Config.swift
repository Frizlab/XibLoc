/*
 * DependencyInjection.swift
 * XibLoc
 *
 * Created by François Lamboley on 1/22/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation

import os.log



public struct DependencyInjection {
	
	init() {
		if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {log = .default}
		else                                                          {log = nil}
	}
	
	public var log: OSLog?
	
	public var defaultEscapeToken: String?
	public var defaultPluralityDefinition = PluralityDefinition()
	
}

public var di = DependencyInjection()