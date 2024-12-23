/*
Copyright 2019-2022 happn

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
import Logging



public struct ParsedXibLoc<SourceTypeHelper : ParserHelper> {
	
	public typealias SourceType = SourceTypeHelper.ParsedType
	
	public let sourceTypeHelperType: SourceTypeHelper.Type
	
	/**
	 Init a new ParsedXibLoc.
	 Usually you shouldn’t use this, unless you add the support for a type other than `String` or `NSMutableAttributedString`,
	  in which case you should extend your type to apply directly the given resolving info,
	  and the implementation of your extension should call this init (see the implementation of the extension of `String` etc. in file `XibLoc.swift`). */
	public init<DestinationType>(source: SourceType, parserHelper: SourceTypeHelper.Type, forXibLocResolvingInfo xibLocResolvingInfo: XibLocResolvingInfo<SourceType, DestinationType>) {
		self.init(source: source, parserHelper: parserHelper, parsingInfo: xibLocResolvingInfo.parsingInfo)
	}
	
	init(source: SourceType, parserHelper: SourceTypeHelper.Type, parsingInfo: XibLocParsingInfo) {
		var source = SourceTypeHelper.copy(source: source)
		var stringSource = parserHelper.stringRepresentation(of: source)
		var pluralityDefinitionsList = ParsedXibLoc.preprocessForPluralityDefinitionOverrides(source: &source, stringSource: &stringSource, parserHelper: parserHelper)
		while pluralityDefinitionsList.count < parsingInfo.pluralGroups.count {pluralityDefinitionsList.append(nil)}
		
		self.init(source: source, stringSource: stringSource, parserHelper: parserHelper, parsingInfo: parsingInfo, pluralityDefinitionsList: pluralityDefinitionsList)
	}
	
	private init(source: SourceType, stringSource: String, parserHelper: SourceTypeHelper.Type, parsingInfo: XibLocParsingInfo, pluralityDefinitionsList: [PluralityDefinition?]) {
		assert(pluralityDefinitionsList.count >= parsingInfo.pluralGroups.count)
		
		/* Let’s build the replacements.
		 * Overlaps are allowed with the following rules:
		 *    - The attributes modifications can overlap between themselves at will;
		 *    - Replacements can be embedded in other replacements (internal ranges for multiple words tokens);
		 *    - Replacements cannot overlap attributes modifications or replacements if one is not fully embedded in the other. */
		
		func getOneWordRanges(tokens: [OneWordTokens], replacementTypeBuilder: (_ token: OneWordTokens) -> ReplacementValue, currentGroupId: inout Int, in output: inout [Replacement]) {
			for sep in tokens {
				var pos = stringSource.startIndex
				while let r = ParsedXibLoc.rangeFrom(leftSeparator: sep.leftToken, rightSeparator: sep.rightToken, escapeToken: parsingInfo.escapeToken, baseString: stringSource, currentPositionInString: &pos) {
					let replacementType = replacementTypeBuilder(sep)
					let doUntokenization = replacementType.isAttributesModifiation /* See discussion below about token removal */
					let contentRange = ParsedXibLoc.contentRange(from: r, in: stringSource, leftSep: sep.leftToken, rightSep: sep.rightToken)
					let replacement = Replacement(groupId: currentGroupId, range: contentRange, value: replacementType, removedLeftTokenDistance: doUntokenization ? sep.leftToken.count : 0, removedRightTokenDistance: doUntokenization ? sep.rightToken.count : 0, containerRange: r, children: [])
					ParsedXibLoc.insert(replacement: replacement, in: &output)
					currentGroupId += 1
				}
			}
		}
		
		func getMultipleWordsRanges(tokens: [MultipleWordsTokens], replacementTypeBuilder: (_ token: MultipleWordsTokens, _ idx: Int, _ count: ReplacementValue.MutableCount) -> ReplacementValue, currentGroupId: inout Int, in output: inout [Replacement]) {
			for sep in tokens {
				var pos = stringSource.startIndex
				while let r = ParsedXibLoc.rangeFrom(leftSeparator: sep.leftToken, rightSeparator: sep.rightToken, escapeToken: parsingInfo.escapeToken, baseString: stringSource, currentPositionInString: &pos) {
					/* Let’s get the internal ranges. */
					let contentRange = ParsedXibLoc.contentRange(from: r, in: stringSource, leftSep: sep.leftToken, rightSep: sep.rightToken)
					var startIndex = contentRange.lowerBound
					let endIndex = contentRange.upperBound
					let count = ReplacementValue.MutableCount(v: 1)
					
					var idx = 0
					while let sepRange = ParsedXibLoc.range(of: sep.interiorToken, escapeToken: parsingInfo.escapeToken, baseString: stringSource, in: startIndex..<endIndex) {
						let internalRange = startIndex..<sepRange.lowerBound
						/* We set both removed left and right token distances to 0 (see discussion below about token removal) */
						let replacement = Replacement(groupId: currentGroupId, range: internalRange, value: replacementTypeBuilder(sep, idx, count), removedLeftTokenDistance: 0/*idx == 0 ? sep.leftToken.count : 0*/, removedRightTokenDistance: 0/*sep.interiorToken.count*/, containerRange: r, children: [])
						ParsedXibLoc.insert(replacement: replacement, in: &output)
						
						idx += 1
						count.value += 1
						startIndex = sepRange.upperBound
					}
					let internalRange = startIndex..<endIndex
					/* We set both removed left and right token distances to 0 (see discussion below about token removal) */
					let replacement = Replacement(groupId: currentGroupId, range: internalRange, value: replacementTypeBuilder(sep, idx, count), removedLeftTokenDistance: 0/*idx == 0 ? sep.leftToken.count : 0*/, removedRightTokenDistance: 0/*sep.rightToken.count*/, containerRange: r, children: [])
					ParsedXibLoc.insert(replacement: replacement, in: &output)
					currentGroupId += 1
				}
			}
		}
		
		var currentGroupId = 0
		var replacementsBuilding = [Replacement]()
		
		getMultipleWordsRanges(tokens: parsingInfo.orderedReplacements, replacementTypeBuilder: { .orderedReplacement($0, valueIndex: $1, numberOfValues: $2) }, currentGroupId: &currentGroupId, in: &replacementsBuilding)
		getMultipleWordsRanges(tokens: parsingInfo.pluralGroups, replacementTypeBuilder: { .pluralGroup($0, zoneIndex: $1, numberOfZones: $2) }, currentGroupId: &currentGroupId, in: &replacementsBuilding)
		getOneWordRanges(tokens: parsingInfo.simpleSourceTypeReplacements, replacementTypeBuilder: { .simpleSourceTypeReplacement($0) }, currentGroupId: &currentGroupId, in: &replacementsBuilding)
		getOneWordRanges(tokens: parsingInfo.simpleReturnTypeReplacements, replacementTypeBuilder: { .simpleReturnTypeReplacement($0) }, currentGroupId: &currentGroupId, in: &replacementsBuilding)
		getOneWordRanges(tokens: parsingInfo.attributesModifications, replacementTypeBuilder: { .attributesModification($0) }, currentGroupId: &currentGroupId, in: &replacementsBuilding)
		
		/* Let’s remove the tokens we want gone from the source string.
		 * The escape token is always removed.
		 * We only remove the left and right separator tokens from the attributes modification; all other tokens are left.
		 * The idea behind the removal of the tokens is to avoid adjusting all the ranges in the replacements when applying the changes in the source.
		 * The attributes modification change is guaranteed not to modify the range of anything by contract, so we can pre-compute the ranges before applying the modification.
		 * All other changes will modify the ranges 99% of the cases, so there are no pre-computations to be done this way. */
		
		var untokenizedSourceBuilding = source
		var untokenizedStringSourceBuilding = stringSource
		ParsedXibLoc.remove(escapeToken: parsingInfo.escapeToken, in: &replacementsBuilding, source: &untokenizedSourceBuilding, stringSource: &untokenizedStringSourceBuilding, parserHelper: parserHelper)
		ParsedXibLoc.removeTokens(from: &replacementsBuilding, source: &untokenizedSourceBuilding, stringSource: &untokenizedStringSourceBuilding, parserHelper: parserHelper)
//		print("***** RESULTS TIME *****")
//		print("untokenized: \(untokenizedStringSourceBuilding.replacingOccurrences(of: "\n", with: "\\n"))")
//		for r in replacementsBuilding {r.print(from: untokenizedStringSourceBuilding)}
		
		/* Let’s finish the init */
		
		sourceTypeHelperType = parserHelper
		
		replacements = replacementsBuilding
		untokenizedSource = untokenizedSourceBuilding
		untokenizedStringSource = untokenizedStringSourceBuilding
		
		/* Plurality definitions overrides */
		var pluralityDefinitionsBuilding = [MultipleWordsTokens: PluralityDefinition]()
		for (pluralityDefinition, pluralGroup) in zip(pluralityDefinitionsList, parsingInfo.pluralGroups) {
			guard let pluralityDefinition = pluralityDefinition else {continue}
			pluralityDefinitionsBuilding[pluralGroup] = pluralityDefinition
		}
		pluralityDefinitions = pluralityDefinitionsBuilding
	}
	
	public func resolve<ReturnTypeHelper : ParserHelper>(xibLocResolvingInfo: XibLocResolvingInfo<SourceType, ReturnTypeHelper.ParsedType>, returnTypeHelperType: ReturnTypeHelper.Type) -> ReturnTypeHelper.ParsedType {
		let replacementsIterator = ReplacementsIterator(refString: untokenizedStringSource, adjustedReplacements: replacements)
		
		var pluralGroupsDictionary = [MultipleWordsTokens: PluralValue]()
		xibLocResolvingInfo.pluralGroups.forEach{ pluralGroupsDictionary[$0.0] = $0.1 }
		
		/* Applying simple source type replacements */
		var sourceWithSimpleReplacements = SourceTypeHelper.copy(source: untokenizedSource)
		while let replacement = replacementsIterator.next() {
			guard case .simpleSourceTypeReplacement(let token) = replacement.value else {continue}
			guard let newValueCreator = xibLocResolvingInfo.simpleSourceTypeReplacements[token] else {
#if canImport(os)
				if #available(macOS 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {
					Conf.oslog.flatMap{ os_log("Got token %{public}@ in replacement tree for simple source type replacement, but no value given in xibLocResolvingInfo", log: $0, type: .info, String(describing: token)) }}
#endif
				Conf.logger?.warning("Got token \(String(describing: token)) in replacement tree for simple source type replacement, but no value given in xibLocResolvingInfo")
				continue
			}
			
			let currentValue = sourceTypeHelperType.slice(strRange: (replacement.range, replacementsIterator.refString), from: sourceWithSimpleReplacements)
			let stringReplacement = sourceTypeHelperType.replace(strRange: (replacement.containerRange, replacementsIterator.refString), with: newValueCreator(currentValue), in: &sourceWithSimpleReplacements)
			
			replacementsIterator.delete(replacementGroup: replacement.groupId)
			replacementsIterator.replace(rangeInText: replacement.containerRange, with: stringReplacement)
		}
		
		/* Converting the source type string to the destination type */
		var result = xibLocResolvingInfo.identityReplacement(sourceWithSimpleReplacements)
		assert(returnTypeHelperType.stringRepresentation(of: result) == replacementsIterator.refString)
		replacementsIterator.reset()
		
		/* Applying other replacements */
		while let replacement = replacementsIterator.next() {
			switch replacement.value {
				case .simpleSourceTypeReplacement: (/* Treated before conversion to ReturnType */)
				case .attributesModification(let token):
					guard let modifier = xibLocResolvingInfo.attributesModifications[token] else {
#if canImport(os)
						if #available(macOS 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {
							Conf.oslog.flatMap{ os_log("Got token %{public}@ in replacement tree for attributes modification, but no value given in xibLocResolvingInfo", log: $0, type: .info, String(describing: token)) }}
#endif
						Conf.logger?.warning("Got token \(String(describing: token)) in replacement tree for attributes modification, but no value given in xibLocResolvingInfo")
						continue
					}
					modifier(&result, replacement.range, replacementsIterator.refString)
					assert(returnTypeHelperType.stringRepresentation(of: result) == replacementsIterator.refString)
					replacementsIterator.delete(replacementGroup: replacement.groupId)
					
				case .simpleReturnTypeReplacement(let token):
					guard let newValueCreator = xibLocResolvingInfo.simpleReturnTypeReplacements[token] else {
#if canImport(os)
						if #available(macOS 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {
							Conf.oslog.flatMap{ os_log("Got token %{public}@ in replacement tree for simple return type replacement, but no value given in xibLocResolvingInfo", log: $0, type: .info, String(describing: token)) }}
#endif
						Conf.logger?.warning("Got token \(String(describing: token)) in replacement tree for simple return type replacement, but no value given in xibLocResolvingInfo")
						continue
					}
					
					let currentValue = returnTypeHelperType.slice(strRange: (replacement.range, replacementsIterator.refString), from: result)
					let stringReplacement = returnTypeHelperType.replace(strRange: (replacement.containerRange, replacementsIterator.refString), with: newValueCreator(currentValue), in: &result)
					replacementsIterator.delete(replacementGroup: replacement.groupId)
					replacementsIterator.replace(rangeInText: replacement.containerRange, with: stringReplacement)
					assert(returnTypeHelperType.stringRepresentation(of: result) == replacementsIterator.refString)
					
				case .orderedReplacement(let token, valueIndex: let valueIndex, numberOfValues: let numberOfValues):
					guard let wantedValue = xibLocResolvingInfo.orderedReplacements[token] else {
#if canImport(os)
						if #available(macOS 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {
							Conf.oslog.flatMap{ os_log("Got token %{public}@ in replacement tree for ordered replacement, but no value given in xibLocResolvingInfo", log: $0, type: .info, String(describing: token)) }}
#endif
						Conf.logger?.warning("Got token \(String(describing: token)) in replacement tree for ordered replacement, but no value given in xibLocResolvingInfo")
						continue
					}
					guard (
						valueIndex == wantedValue ||
						(wantedValue < 0 && valueIndex == 0) ||
						(wantedValue >= numberOfValues.value && valueIndex == numberOfValues.value-1)
					) else {continue}
					
					let content = returnTypeHelperType.slice(strRange: (replacement.range, replacementsIterator.refString), from: result)
					let stringContent = returnTypeHelperType.replace(strRange: (replacement.containerRange, replacementsIterator.refString), with: content, in: &result)
					replacementsIterator.delete(replacementGroup: replacement.groupId)
					replacementsIterator.replace(rangeInText: replacement.containerRange, with: stringContent)
					assert(returnTypeHelperType.stringRepresentation(of: result) == replacementsIterator.refString)
					
				case .pluralGroup(let token, zoneIndex: let zoneIndex, numberOfZones: let numberOfZones):
					guard let wantedValue = pluralGroupsDictionary[token] else {
#if canImport(os)
						if #available(macOS 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {
							Conf.oslog.flatMap{ os_log("Got token %{public}@ in replacement tree for plural replacement, but no value given in xibLocResolvingInfo", log: $0, type: .info, String(describing: token)) }}
#endif
						Conf.logger?.warning("Got token \(String(describing: token)) in replacement tree for plural replacement, but no value given in xibLocResolvingInfo")
						continue
					}
					let pluralityDefinition = pluralityDefinitions[token] ?? xibLocResolvingInfo.defaultPluralityDefinition
					let indexToUse = pluralityDefinition.indexOfVersionToUse(forValue: wantedValue, numberOfVersions: numberOfZones.value) /* Let’s use the default defaultFloatPrecision! */
					assert(indexToUse <= numberOfZones.value)
					
					guard zoneIndex == indexToUse else {continue}
					
					let content = returnTypeHelperType.slice(strRange: (replacement.range, replacementsIterator.refString), from: result)
					let stringContent = returnTypeHelperType.replace(strRange: (replacement.containerRange, replacementsIterator.refString), with: content, in: &result)
					replacementsIterator.delete(replacementGroup: replacement.groupId)
					replacementsIterator.replace(rangeInText: replacement.containerRange, with: stringContent)
					assert(returnTypeHelperType.stringRepresentation(of: result) == replacementsIterator.refString)
			}
		}
		
		return result
	}
	
	/* ***************
	   MARK: - Private
	   *************** */
	
	/* Would prefer embedded in Replacement, but makes Swift crash :( (Xcode 9.1/9B55) */
	private enum ReplacementValue {
		
		class MutableCount {
			var value: Int
			init(v: Int) {value = v}
		}
		
		case simpleSourceTypeReplacement(OneWordTokens)
		case orderedReplacement(MultipleWordsTokens, valueIndex: Int, numberOfValues: MutableCount)
		case pluralGroup(MultipleWordsTokens, zoneIndex: Int, numberOfZones: MutableCount)
		
		case attributesModification(OneWordTokens)
		case simpleReturnTypeReplacement(OneWordTokens)
		
		var isAttributesModifiation: Bool {
			switch self {
				case .attributesModification: return true
				default:                      return false
			}
		}
		
	}
	
	/* Note: I’m not so sure having a struct here is such a good idea…
	 *       We have to workaround a lot the fact that we pass replacements by value instead of pointers to replacements… */
	private struct Replacement {
		
		let groupId: Int
		
		var range: Range<String.Index>
		let value: ReplacementValue
		
		var removedLeftTokenDistance: Int
		var removedRightTokenDistance: Int
		var containerRange: Range<String.Index> /* Always contains “range”. Equals “range” for OneWordTokens. */
		
		var children: [Replacement]
		
		func print(from string: String, prefix: String = "") {
			Swift.print("\(prefix)REPLACEMENT START")
			Swift.print("\(prefix)container: \(string[containerRange].replacingOccurrences(of: "\n", with: "\\n"))")
			Swift.print("\(prefix)range: \(string[range].replacingOccurrences(of: "\n", with: "\\n"))")
			Swift.print("\(prefix)groupId: \(groupId)")
			Swift.print("\(prefix)removed left  token distance: \(removedLeftTokenDistance)")
			Swift.print("\(prefix)removed right token distance: \(removedRightTokenDistance)")
			Swift.print("\(prefix)children (\(children.count))")
			for c in children {c.print(from: string, prefix: prefix + "   ")}
			Swift.print("\(prefix)REPLACEMENT END")
		}
		
	}
	
	/**
	 Contains the parsed replacements to apply when transforming the input string.
	 
	 The data structure is basically a graph whose root is hidden (the variable contains all the children of the root directly).
	 The children of a replacement are the replacements whose ranges are embedded in them.
	 Attributes changes replacements are special: they are sterile (cannot have children).
	 As they have a different behavior than other replacements (they can overlap for instance), they have to be treated a bit differently. */
	private let replacements: [Replacement]
	private let untokenizedSource: SourceType
	private let untokenizedStringSource: String
	private let pluralityDefinitions: [MultipleWordsTokens: PluralityDefinition]
	
	/* *************************
	   MARK: → General Utilities
	   ************************* */
	
	private class ReplacementsIterator : IteratorProtocol {
		
		typealias Element = Replacement
		
		var refString: String
		var adjustedReplacements: [Replacement]
		
		init(refString rs: String, adjustedReplacements r: [Replacement]) {
//			print("RESET I")
			refString = rs
			adjustedReplacements = r
		}
		
		func next() -> Replacement? {
//			print("ASKED NEXT REPLACEMENT. CURRENT INDEX PATH IS \(currentIndexPath); refString is \(refString)")
//			defer {print(" --> NEW CURRENT INDEX PATH: \(currentIndexPath)")}
			/* Moving currentIndexPath to next index path. Depth-first graph traversal style. */
			if wentIn {
				func isLastIndexInParent(_ indexPath: IndexPath) -> Bool {
					guard let lastIndex = indexPath.last else {return false}
					let parentIndexPath = indexPath.dropLast()
					if parentIndexPath.isEmpty {return lastIndex == adjustedReplacements.endIndex-1}
					else                       {return lastIndex == replacement(at: parentIndexPath).children.endIndex-1}
				}
				
				if isLastIndexInParent(currentIndexPath) {currentIndexPath.removeLast(); wentIn = true}
				else {
					guard let lastIndex = currentIndexPath.last else {/*print(" --> RETURNING NIL"); */return nil}
					currentIndexPath.removeLast(); currentIndexPath.append(lastIndex + 1)
					wentIn = false
				}
			}
			if !wentIn {
				while (currentIndexPath.count == 0 && adjustedReplacements.count > 0) || (currentIndexPath.count > 0 && replacement(at: currentIndexPath).children.count > 0) {currentIndexPath.append(0)}
				wentIn = true
			}
			
			/* Returning Replacement at currentIndexPath */
			guard currentIndexPath.count > 0 else {/*print(" --> RETURNING NIL"); */return nil}
//			print(" --> RETURNING AT INDEX PATH \(currentIndexPath)")
			return replacement(at: currentIndexPath)
		}
		
		func reset() {
//			print("RESET")
			currentIndexPath = IndexPath()
			wentIn = false
		}
		
		func delete(replacementGroup: Int) {
			delete(replacementGroup: replacementGroup, in: &adjustedReplacements)
		}
		
		func replace(rangeInText replacedRange: Range<String.Index>, with string: String) {
			let originalString = refString
			refString.replaceSubrange(replacedRange, with: string)
			ReplacementsIterator.adjustReplacementRanges(replacedRange: replacedRange, with: string, in: &adjustedReplacements, originalString: originalString, newString: refString)
		}
		
		func delete(rangeInText replacedRange: Range<String.Index>) {
			replace(rangeInText: replacedRange, with: "")
		}
		
		private var currentIndexPath = IndexPath()
		private var wentIn = false
		
		private static func convert(range: Range<String.Index>, from originalString: String, to newString: String, searchAnchorInNewString: String.Index) -> Range<String.Index> {
			let fragment = originalString[range]
			guard !fragment.isEmpty else {return searchAnchorInNewString..<searchAnchorInNewString}
			return newString.range(of: fragment, options: [.anchored, .literal], range: searchAnchorInNewString..<newString.endIndex)! /* Not sure about the literal… */
		}
		
		/* adjustedRange and removedRange are relative to originalString.
		 * addedDistance is relative to newString.
		 *
		 * The original range that will be adjusted MUST start and end with indexes that are at the start of an extended grapheme cluster. */
		private static func adjustedRange(from adjustedRange: Range<String.Index>, byReplacing removedRange: Range<String.Index>, in originalString: String, with addedString: String, newString: String) -> Range<String.Index> {
			/* Let’s verify we’re indeed at the start of a cluster for the lower and upper bounds of the adjusted range. */
			assert(String.Index(adjustedRange.lowerBound, within: originalString) != nil)
			assert(String.Index(adjustedRange.upperBound, within: originalString) != nil)
			
			/* We make sure that the removed range does not overlap with the adjusted range or the adjusted range contains the removed range fully. */
			assert(!adjustedRange.overlapsWithEmpty(removedRange) || adjustedRange.clamped(to: removedRange) == removedRange)
			
			let adjustLowerBound = (originalString.distance(from: adjustedRange.lowerBound, to: removedRange.upperBound) <= 0)
			let adjustUpperBound = (originalString.distance(from: adjustedRange.upperBound, to: removedRange.upperBound) <= 0)
			
#if !USE_UTF16_OFFSETS
#warning("I’m pretty sure the adjustment can be done using another algo (basically the same as the one in remove(escapeToken...)). Note there might be other places where we could update the algo too.")
			/* With this version of the algorithm we play it safe and re-compute the ranges by searching for partial strings from the original string in the new string.
			 * This has a small performance impact on some ObjC strings, but in most of the cases it’s completely negligible. */
			let newLowerBound: String.Index
			let newUpperBound: String.Index
			
			if adjustLowerBound {
				/* We must adjust the lower bound of the adjusted range. */
				let prefixRangeInNewString = convert(range: originalString.startIndex..<removedRange.lowerBound, from: originalString, to: newString, searchAnchorInNewString: newString.startIndex)
				let suffixRangeInNewString = convert(range: removedRange.upperBound..<adjustedRange.lowerBound,  from: originalString, to: newString, searchAnchorInNewString: newString.index(prefixRangeInNewString.upperBound, offsetBy: addedString.count))
				newLowerBound = suffixRangeInNewString.upperBound
			} else {
				/* Technically we shouldn’t have to adjust the lower bound of the range.
				 * However, it seems the bound can become invalid, so we’ll recalculate it anyway. */
				let prefixRangeInNewString = convert(range: originalString.startIndex..<adjustedRange.lowerBound, from: originalString, to: newString, searchAnchorInNewString: newString.startIndex)
				newLowerBound = prefixRangeInNewString.upperBound
			}
			
			if adjustUpperBound {
				/* We must adjust the upper bound of the adjusted range. */
				let prefixRangeInNewString = convert(range: originalString.startIndex..<removedRange.lowerBound, from: originalString, to: newString, searchAnchorInNewString: newString.startIndex)
				let suffixRangeInNewString = convert(range: removedRange.upperBound..<adjustedRange.upperBound,  from: originalString, to: newString, searchAnchorInNewString: newString.index(prefixRangeInNewString.upperBound, offsetBy: addedString.count))
				newUpperBound = suffixRangeInNewString.upperBound
			} else {
				/* Technically we shouldn’t have to adjust the upper bound of the range.
				 * However, it seems the bound can become invalid, so we’ll recalculate it anyway. */
				let prefixRangeInNewString = convert(range: originalString.startIndex..<adjustedRange.upperBound, from: originalString, to: newString, searchAnchorInNewString: newString.startIndex)
				newUpperBound = prefixRangeInNewString.upperBound
			}
			
#else
			/* This version of the algorithm, though slightly faster in some circumstances, crashes _randomly_ for some ObjC strings.
			 * It is kept for posterity mainly, and for performance test comparison with the other version of the algorithm. */
			guard adjustLowerBound || adjustUpperBound else {return adjustedRange}
			
			let removedUTF16Distance = removedRange.upperBound.utf16Offset(in: originalString) - removedRange.lowerBound.utf16Offset(in: originalString) - addedString.utf16.count
			let newLowerBound = String.Index(utf16Offset: adjustedRange.lowerBound.utf16Offset(in: originalString) - (adjustLowerBound ? removedUTF16Distance : 0), in: newString)
			let newUpperBound = String.Index(utf16Offset: adjustedRange.upperBound.utf16Offset(in: originalString) - (adjustUpperBound ? removedUTF16Distance : 0), in: newString)
			
#endif
			
			/* Let’s verify we’re still at the start of a cluster for the lower and upper bounds of the new range. */
			assert(String.Index(newLowerBound, within: newString) != nil)
			assert(String.Index(newUpperBound, within: newString) != nil)
			return Range<String.Index>(uncheckedBounds: (lower: newLowerBound, upper: newUpperBound))
		}
		
		private static func adjustReplacementRanges(replacedRange: Range<String.Index>, with string: String, in replacements: inout [Replacement], originalString: String, newString: String) {
			for (idx, var replacement) in replacements.enumerated() {
				/* We make sure range is contained by the container range of the replacement, or that both do not overlap. */
				assert(!replacement.containerRange.overlapsWithEmpty(replacedRange) || replacement.containerRange.clamped(to: replacedRange) == replacedRange)
				
				replacement.range          = ReplacementsIterator.adjustedRange(from: replacement.range,          byReplacing: replacedRange, in: originalString, with: string, newString: newString)
				replacement.containerRange = ReplacementsIterator.adjustedRange(from: replacement.containerRange, byReplacing: replacedRange, in: originalString, with: string, newString: newString)
				
				adjustReplacementRanges(replacedRange: replacedRange, with: string, in: &replacement.children, originalString: originalString, newString: newString)
				replacements[idx] = replacement
			}
		}
		
		private func delete(replacementGroup deletedGroupId: Int, in replacements: inout [Replacement], currentLevel: Int = 0) {
			var idx = 0
			while idx < replacements.count {
				var replacement = replacements[idx]
				
				guard replacement.groupId != deletedGroupId else {
					if currentLevel < currentIndexPath.endIndex {
						switch currentIndexPath[currentLevel] {
							case idx:
								/* The replacement we are removing is currently being visited.
								 * Let’s relocate the current index to the previous replacement. */
								currentIndexPath.removeLast(currentIndexPath.count-currentLevel-1)
								while let last = currentIndexPath.last, last == 0 {currentIndexPath.removeLast()}
								if let last = currentIndexPath.last {currentIndexPath.removeLast(); currentIndexPath.append(last - 1)}
								else                                {wentIn = false}
								
							case idx...:
								currentIndexPath[currentLevel] -= 1
								
							default: (/*nop*/)
						}
					}
					replacements.remove(at: idx)
					continue
				}
				
				delete(replacementGroup: deletedGroupId, in: &replacement.children, currentLevel: currentLevel+1)
				replacements[idx] = replacement
				
				idx += 1
			}
		}
		
		private func replacement(at indexPath: IndexPath) -> Replacement {
			var result: Replacement!
			var replacements = adjustedReplacements
			for idx in indexPath {
				result = replacements[idx]
				replacements = result.children
			}
			return result
		}
		
	}
	
	/* **************************
	   MARK: → Parsing the XibLoc
	   ************************** */
	
	private static func remove(escapeToken: String?, in replacements: inout [Replacement], source: inout SourceType, stringSource: inout String, parserHelper: SourceTypeHelper.Type) {
		guard let escapeToken = escapeToken else {return}
		
		let iterator = ReplacementsIterator(refString: stringSource, adjustedReplacements: replacements)
		
		var pos = iterator.refString.startIndex
		while let r = iterator.refString.range(of: escapeToken, options: [.literal], range: pos..<iterator.refString.endIndex) {
			/* We’ll use this later to re-create the range after modifying the string. */
			let d1 = iterator.refString.distance(from: iterator.refString.startIndex, to: r.lowerBound)
			let d2 = iterator.refString.distance(from: iterator.refString.startIndex, to: r.upperBound)
			
			parserHelper.remove(strRange: (r, iterator.refString), from: &source)
			iterator.delete(rangeInText: r)
			
			/* We must recreate the range because the previous range is no longer valid in the modified string. */
			if d2 > iterator.refString.count {break}
			let r = iterator.refString.index(iterator.refString.startIndex, offsetBy: d1)..<iterator.refString.index(iterator.refString.startIndex, offsetBy: d2)
			
			pos = r.lowerBound
			if iterator.refString[r] == escapeToken {pos = iterator.refString.index(pos, offsetBy: escapeToken.count)}
		}
		
		replacements = iterator.adjustedReplacements
		stringSource = iterator.refString
	}
	
	private static func removeTokens(from replacements: inout [Replacement], source: inout SourceType, stringSource: inout String, parserHelper: SourceTypeHelper.Type) {
		let iterator = ReplacementsIterator(refString: stringSource, adjustedReplacements: replacements)
		
		while let replacement = iterator.next() {
			guard replacement.removedLeftTokenDistance > 0 else {continue}
			let leftTokenRange = iterator.refString.index(replacement.range.lowerBound, offsetBy: -replacement.removedLeftTokenDistance)..<replacement.range.lowerBound
			parserHelper.remove(strRange: (leftTokenRange, iterator.refString), from: &source)
			iterator.delete(rangeInText: leftTokenRange)
		}
		iterator.reset()
		while let replacement = iterator.next() {
			guard replacement.removedRightTokenDistance > 0 else {continue}
			let rightTokenRange = replacement.range.upperBound..<iterator.refString.index(replacement.range.upperBound, offsetBy: replacement.removedRightTokenDistance)
			parserHelper.remove(strRange: (rightTokenRange, iterator.refString), from: &source)
			iterator.delete(rangeInText: rightTokenRange)
		}
		
		replacements = iterator.adjustedReplacements
		stringSource = iterator.refString
	}
	
	/**
	 Inserts the given replacement in the given array of replacements, if possible.
	 If a valid insertion cannot be done, returns `false` (otherwise, returns `true`).
	 
	 Assumes the given replacement and current replacements are valid. */
	@discardableResult
	private static func insert(replacement insertedReplacement: Replacement, in currentReplacements: inout [Replacement], level: Int = 0) -> Bool {
//		print(String(repeating: " ", count: level) + "inserting: " + "|title|^\n_#n# result<:s>_^"[insertedReplacement.containerRange].replacingOccurrences(of: "\n", with: "\\n") + " (\(insertedReplacement.children.count) children)")
		/* We might have to modify the inserted replacement (to add children inside it). */
		var insertedReplacement = insertedReplacement
		
		var idx = 0
		while idx < currentReplacements.endIndex {
			defer {idx += 1}
			let checkedReplacement = currentReplacements[idx]
//			print(String(repeating: " ", count: level) + "checking: " + "|title|^\n_#n# result<:s>_^"[checkedReplacement.containerRange].replacingOccurrences(of: "\n", with: "\\n") + " (\(checkedReplacement.children.count) children)")
			
			/* If both checked and inserted replacements have the same container range,
			 *  we are inserting a new replacement value for the checked replacement
			 *  (eg. inserting the “b” when “a” has been inserted in the following replacement: “<a:b>”).
			 * Let’s just check the two ranges do not overlap (asserted, this is an internal logic error if ranges overlap). */
			if insertedReplacement.containerRange == checkedReplacement.containerRange {
				assert(!insertedReplacement.range.overlapsWithEmpty(checkedReplacement.range))
				continue
			}
			
			/* If there are no overlaps of the container ranges, or if we have two attributes modifications, we have an easy case: nothing to do (all ranges are valid). */
			if insertedReplacement.value.isAttributesModifiation && checkedReplacement.value.isAttributesModifiation {continue}
			if !insertedReplacement.range.overlapsWithEmpty(checkedReplacement.range) {continue}
			
			if !checkedReplacement.value.isAttributesModifiation && checkedReplacement.range.clamped(to: insertedReplacement.containerRange) == insertedReplacement.containerRange {
				/* insertedReplacement’s container range is included in checkedReplacement’s range and checkedReplacement is not an attributes modification:
				 *    we must add insertedReplacement as a child of checkedReplacement */
				var checkedReplacement = checkedReplacement
				guard insert(replacement: insertedReplacement, in: &checkedReplacement.children, level: level + 1) else {return false}
				currentReplacements[idx] = checkedReplacement
//				print(String(repeating: " ", count: level) + "inserted (below): " + "|title|^\n_#n# result<:s>_^"[insertedReplacement.containerRange].replacingOccurrences(of: "\n", with: "\\n") + " (\(insertedReplacement.children.count) children)")
				return true
			} else if insertedReplacement.range.clamped(to: checkedReplacement.containerRange) == checkedReplacement.containerRange {
				if !insertedReplacement.value.isAttributesModifiation {
					/* checkedReplacement’s container range is included in insertedReplacement’s range and insertedReplacement is not an attributes modification:
					 *    we must add all replacements whose group id is equal to checkedReplacement’s group id as a child of insertedReplacement */
					guard insert(replacement: checkedReplacement, in: &insertedReplacement.children, level: level + 1) else {return false}
					currentReplacements.remove(at: idx)
					idx -= 1
					continue
				} else {
					/* inserted replacement is an attributes modification: it cannot have children.
					 * However the checked replacement is fully embedded in the inserted replacement:
					 *    nothing is stopping us from adding the replacement on this check. */
					continue
				}
			} else {
				return false
			}
		}
		
		currentReplacements.append(insertedReplacement)
//		print(String(repeating: " ", count: level) + "inserted: " + "|title|^\n_#n# result<:s>_^"[insertedReplacement.containerRange].replacingOccurrences(of: "\n", with: "\\n") + " (\(insertedReplacement.children.count) children)")
		return true
	}
	
	private static func preprocessForPluralityDefinitionOverrides(source: inout SourceType, stringSource: inout String, parserHelper: SourceTypeHelper.Type) -> [PluralityDefinition?] {
		let pluralityOverrideSeparator = "||"
		guard stringSource.hasPrefix(pluralityOverrideSeparator) else {return []}
		
		let startIdx = stringSource.startIndex
		
		/* We might have plurality overrides. Let’s check. */
		guard !stringSource.hasPrefix(pluralityOverrideSeparator + "|") else {
			/* We don’t. But we must remove one leading "|". */
			parserHelper.remove(strRange: (..<stringSource.index(after: startIdx), stringSource), from: &source)
			stringSource.removeFirst()
			return []
		}
		
		let pluralityStringStartIdx = stringSource.index(startIdx, offsetBy: pluralityOverrideSeparator.count)
		
		/* We do have plurality override(s)! Is it valid? */
		guard let pluralityEndIdx = stringSource.range(of: pluralityOverrideSeparator, options: [.literal], range: pluralityStringStartIdx..<stringSource.endIndex)?.lowerBound else {
			/* Nope. It is not. */
#if canImport(os)
			if #available(macOS 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {
				Conf.oslog.flatMap{ os_log("Got invalid plurality override in string source \"%@\"", log: $0, type: .info, stringSource) }}
#endif
			Conf.logger?.warning("Got invalid plurality override in string source \"\(stringSource)\"")
			return []
		}
		
		/* A valid plurality overrides part was found. Let’s parse them! */
		let pluralityOverrideStr = stringSource[pluralityStringStartIdx..<pluralityEndIdx]
		/* Dev note: `components(separatedBy:)` does return empty components, contrary to `split(separator:)`.
		 * In our case though it is not possible to get empty components (because an empty component would have signaled the end of the plurality override). */
		let pluralityDefinitions = pluralityOverrideStr.components(separatedBy: "|").map{ $0 == "_" ? nil : PluralityDefinition(string: $0) }
		
		/* Let’s remove the plurality definition from the string. */
		let nonPluralityStringStartIdx = stringSource.index(pluralityEndIdx, offsetBy: pluralityOverrideSeparator.count)
		parserHelper.remove(strRange: (..<nonPluralityStringStartIdx, stringSource), from: &source)
		stringSource.removeSubrange(startIdx..<nonPluralityStringStartIdx)
		
		return pluralityDefinitions
	}
	
	private static func contentRange(from range: Range<String.Index>, in source: String, leftSep: String, rightSep: String) -> Range<String.Index> {
		assert(source.distance(from: range.lowerBound, to: range.upperBound) >= leftSep.count + rightSep.count)
		return source.index(range.lowerBound, offsetBy: leftSep.count)..<source.index(range.upperBound, offsetBy: -rightSep.count)
		/* The line below is the same, but unchecked. We could use it though as we assert it’s good just before. */
//		return Range<String.Index>(uncheckedBounds: (lower: source.index(range.lowerBound, offsetBy: leftSep.count), upper: source.index(range.upperBound, offsetBy: -rightSep.count)))
	}
	
	private static func rangeFrom(leftSeparator: String, rightSeparator: String, escapeToken: String?, baseString: String, currentPositionInString: inout String.Index) -> Range<String.Index>? {
		guard let leftSeparatorRange = range(of: leftSeparator, escapeToken: escapeToken, baseString: baseString, in: currentPositionInString..<baseString.endIndex) else {
			currentPositionInString = baseString.endIndex
			return nil
		}
		currentPositionInString = leftSeparatorRange.upperBound
		
		guard let rightSeparatorRange = range(of: rightSeparator, escapeToken: escapeToken, baseString: baseString, in: currentPositionInString..<baseString.endIndex) else {
			/* Invalid string: The left token was found, but the right was not. */
#if canImport(os)
			if #available(macOS 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {
				Conf.oslog.flatMap{ os_log("Invalid baseString “%@”: left token “%@” was found, but right one “%@” was not. Ignoring.", log: $0, type: .info, baseString, leftSeparator, rightSeparator) }}
#endif
			Conf.logger?.warning("Invalid baseString “\(baseString)”: left token “\(leftSeparator)” was found, but right one “\(rightSeparator)” was not. Ignoring.")
			currentPositionInString = baseString.endIndex
			return nil
		}
		currentPositionInString = rightSeparatorRange.upperBound
		
		return leftSeparatorRange.lowerBound..<rightSeparatorRange.upperBound
	}
	
	private static func range(of separator: String, escapeToken: String?, baseString: String, in range: Range<String.Index>) -> Range<String.Index>? {
		var escaped: Bool
		var ret: Range<String.Index>
		
		var startIndex = range.lowerBound
		let endIndex = range.upperBound
		
		repeat {
			guard let rl = baseString.range(of: separator, options: [.literal], range: startIndex..<endIndex) else {
				return nil
			}
			startIndex = rl.upperBound
			escaped = isTokenEscaped(tokenRange: rl, in: baseString, escapeToken: escapeToken)
			
			ret = rl
		} while escaped
		
		return ret
	}
	
	private static func isTokenEscaped(tokenRange range: Range<String.Index>, in baseString: String, escapeToken token: String?) -> Bool {
		guard let escapeToken = token, !escapeToken.isEmpty else {return false}
		
		var nMatches = 0
		var wasMatch = true
		var curPos = range.lowerBound
		/* We iterate while we have found a match and there is enough string space left to have a new match. */
		while wasMatch && baseString.distance(from: baseString.startIndex, to: curPos) >= escapeToken.count {
			curPos = baseString.index(curPos, offsetBy: -escapeToken.count)
			wasMatch = (baseString[curPos..<baseString.index(curPos, offsetBy: escapeToken.count)] == escapeToken)
			if wasMatch {nMatches += 1}
		}
		return !nMatches.isMultiple(of: 2)
	}
	
}
