/*
 * PluralityDefinitionZoneValueIntervalOfFloats.swift
 * XibLoc
 *
 * Created by François Lamboley on 8/26/17.
 * Copyright © 2017 happn. All rights reserved.
 */

import Foundation



struct PluralityDefinitionZoneValueIntervalOfFloats : PluralityDefinitionZoneValue {
	
	init?(string: String) {
		let scanner = Scanner(string: string)
		scanner.charactersToBeSkipped = CharacterSet()
		scanner.locale = nil
		
		let bracketsCharset = CharacterSet(charactersIn: "[]")
		
		var f: Float = 0
		
		guard let bracket1 = scanner.scanCharactersFromSet(bracketsCharset), bracket1.count == 1 else {return nil}
		assert(bracket1 == "[" || bracket1 == "]")
		
		start = scanner.scanFloat(&f) ? (value: f, included: bracket1 == "[") : nil
		
		guard scanner.scanString("→", into: nil) else {return nil}
		
		let hasEnd = scanner.scanFloat(&f)
		
		guard let bracket2 = scanner.scanCharactersFromSet(bracketsCharset), bracket2.count == 1 else {return nil}
		assert(bracket2 == "[" || bracket2 == "]")
		
		guard scanner.isAtEnd else {return nil}
		
		end = hasEnd ? (value: f, included: bracket2 == "]") : nil
		
		guard start != nil || end != nil else {return nil}
		if let start = start, let end = end, start.value > end.value {return nil}
	}
	
	func matches(int: Int) -> Bool {
		return matches(float: Float(int), precision: 0)
	}
	
	func matches(float: Float, precision: Float) -> Bool {
		assert(precision >= 0)
		assert(start != nil || end != nil)
		
		if let start = start {
			guard (start.included && float - start.value >= -precision) || (!start.included && float - start.value > -precision) else {
				return false
			}
		}
		
		if let end = end {
			guard (end.included && float - end.value <= precision) || (!end.included && float - end.value < precision) else {
				return false
			}
		}
		
		return true
	}
	
	var debugDescription: String {
		var ret = "PluralityDefinitionZoneValueIntervalOfFloats: "
		if let start = start          {ret.append("start = \(start.value) (\(start.included ? "incl." : "excl.")")}
		if start != nil && end != nil {ret.append(", ")}
		if let end = end              {ret.append("end = \(end.value) (\(end.included ? "incl." : "excl.")")}
		return ret
	}
	
	private let start, end: (value: Float, included: Bool)?
	
}
