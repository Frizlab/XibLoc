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

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)

import Foundation
import XCTest

@testable import XibLoc




@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
class XibLocTestsSwiftAttrStr : XCTestCase {
	
	/* All tests are repeated a few times in a loop as we actually got random
	 * crashes (first found was testFromHappn4/testFromHappn3ObjC; Swift should
	 * be good but who knows…). */
	let nRepeats = 150
	
	override func setUp() {
		super.setUp()
		
		XibLocConfig.cache = nil
		XibLocConfig.defaultEscapeToken = #"\"#
		XibLocConfig.defaultPluralityDefinition = PluralityDefinition()
		
		XibLocConfig.defaultStr2AttrStrAttributes = AttributeContainer()
		XibLocConfig.defaultStr2AttrStrAttributes.font = .systemFont(ofSize: 14)
		XibLocConfig.defaultStr2AttrStrAttributes.foregroundColor = .black
		
		XibLocConfig.defaultBoldAttrsChangesDescription = StringAttributesChangesDescription(changes: [.setBold])
		XibLocConfig.defaultItalicAttrsChangesDescription = nil
		
		#if canImport(os)
			XibLocConfig.oslog = nil
		#endif
		XibLocConfig.logger = nil
	}
	
	override func tearDown() {
		super.tearDown()
	}
	
	func testCommonTokensGroupDocCaseAttrStr() {
		let nRepeats = 1
		for _ in 0..<nRepeats {
			/* Set needed defaults like in the doc. */
			XibLocConfig.defaultEscapeToken = "~"
			XibLocConfig.defaultItalicAttrsChangesDescription = StringAttributesChangesDescription(changes: [.setItalic])
			let info = CommonTokensGroup().str2AttrStrXibLocInfo
			
			print(info)
			var result = AttributedString("helloworldhowareyou", attributes: XibLocConfig.defaultStr2AttrStrAttributes)
			XibLocConfig.defaultItalicAttrsChangesDescription?.apply(to: &result, range: result.range(of: "world")!)
			XibLocConfig.defaultItalicAttrsChangesDescription?.apply(to: &result, range: result.range(of: "are")!)
			
			XCTAssertEqual(
				"hello_world_how_are_you".applying(xibLocInfo: info),
				result
			)
		}
	}
	
	/* Actually, the same as testFromHappn3ObjC */
	func testFromHappn4() throws {
		for _ in 0..<nRepeats {
			let info = CommonTokensGroup(genderMeIsMale: true, genderOtherIsMale: false).str2StrXibLocInfo
			XCTAssertEqual(
				localized("crossed path for the first time").applying(xibLocInfo: info),
				"Vous vous êtes croisés"
			)
		}
	}
	
	private func localized(_ key: String) -> String {
		let testBundle = Bundle(for: Self.self)
		return NSLocalizedString(key, bundle: testBundle, comment: "Crash test")
	}
	
	/* The tests below are only macOS compatible. Other oses either do not have
	 * NSAttributedString (Linux), or do not have the necessary attributes to
	 * test attributed strings (we could find one, be there is no need, really). */
	
	func testOneOrderedReplacementAndIdentityAttributeModification1() throws {
		for _ in 0..<nRepeats {
			let info = try XibLocResolvingInfo<String, AttributedString>(
				defaultPluralityDefinition: PluralityDefinition(), escapeToken: nil,
				simpleSourceTypeReplacements: [:],
				orderedReplacements: [MultipleWordsTokens(leftToken: "<", interiorToken: ":", rightToken: ">"): 0],
				pluralGroups: [],
				attributesModifications: [OneWordTokens(token: "$"): helperAddTestAlternateDescription],
				simpleReturnTypeReplacements: [:], identityReplacement: { AttributedString($0) }
			).get()
			var result = AttributedString("the ")
			result.append(AttributedString("first").mergingAttributes(attributeContainerAlternateDescription))
			XCTAssertEqual(
				"the <$first$:second>".applying(xibLocInfo: info),
				result
			)
		}
	}
	
	func testOneOrderedReplacementAndIdentityAttributeModification2() throws {
		for _ in 0..<nRepeats {
			let info = try XibLocResolvingInfo<String, AttributedString>(
				defaultPluralityDefinition: PluralityDefinition(), escapeToken: nil,
				simpleSourceTypeReplacements: [:],
				orderedReplacements: [MultipleWordsTokens(leftToken: "<", interiorToken: ":", rightToken: ">"): 1],
				pluralGroups: [],
				attributesModifications: [OneWordTokens(token: "$"): helperAddTestAlternateDescription],
				simpleReturnTypeReplacements: [:], identityReplacement: { AttributedString($0) }
			).get()
			XCTAssertEqual(
				"the <$first$:second>".applying(xibLocInfo: info),
				AttributedString("the second")
			)
		}
	}
	
	func testOneOrderedReplacementAndIdentityAttributeModification3() throws {
		for _ in 0..<nRepeats {
			let info = try XibLocResolvingInfo<String, AttributedString>(
				defaultPluralityDefinition: PluralityDefinition(), escapeToken: nil,
				simpleSourceTypeReplacements: [:],
				orderedReplacements: [MultipleWordsTokens(leftToken: "<", interiorToken: ":", rightToken: ">"): 0],
				pluralGroups: [],
				attributesModifications: [OneWordTokens(token: "$"): helperAddTestAlternateDescription],
				simpleReturnTypeReplacements: [:], identityReplacement: { AttributedString($0) }
			).get()
			var result = AttributedString("the ")
			result.append(AttributedString("first").mergingAttributes(attributeContainerAlternateDescription))
			XCTAssertEqual(
				"the $<first:second>$".applying(xibLocInfo: info),
				result
			)
		}
	}
	
	func testOneOrderedReplacementAndIdentityAttributeModification4() throws {
		for _ in 0..<nRepeats {
			let info = try XibLocResolvingInfo<String, AttributedString>(
				defaultPluralityDefinition: PluralityDefinition(), escapeToken: nil,
				simpleSourceTypeReplacements: [:],
				orderedReplacements: [MultipleWordsTokens(leftToken: "<", interiorToken: ":", rightToken: ">"): 1],
				pluralGroups: [],
				attributesModifications: [OneWordTokens(token: "$"): helperAddTestAlternateDescription],
				simpleReturnTypeReplacements: [:], identityReplacement: { AttributedString($0) }
			).get()
			var result = AttributedString("the ")
			result.append(AttributedString("second").mergingAttributes(attributeContainerAlternateDescription))
			XCTAssertEqual(
				"the $<first:second>$".applying(xibLocInfo: info),
				result
			)
		}
	}
	
	func testOneAttributesChange() throws {
		for _ in 0..<nRepeats {
			let info = try XibLocResolvingInfo<String, AttributedString>(
				defaultPluralityDefinition: PluralityDefinition(), escapeToken: nil,
				simpleSourceTypeReplacements: [:], orderedReplacements: [:], pluralGroups: [],
				attributesModifications: [OneWordTokens(token: "*"): helperAddTestAlternateDescription],
				simpleReturnTypeReplacements: [:],
				identityReplacement: { AttributedString($0) }
			).get()
			var result = AttributedString("the ")
			result.append(AttributedString("test").mergingAttributes(attributeContainerAlternateDescription))
			XCTAssertEqual(
				"the *test*".applying(xibLocInfo: info),
				result
			)
		}
	}
	
	func testOneAttributesChangeTwice() throws {
		for _ in 0..<nRepeats {
			let info = try XibLocResolvingInfo<String, AttributedString>(
				defaultPluralityDefinition: PluralityDefinition(), escapeToken: nil,
				simpleSourceTypeReplacements: [:], orderedReplacements: [:], pluralGroups: [],
				attributesModifications: [OneWordTokens(token: "*"): helperAddTestAlternateDescription],
				simpleReturnTypeReplacements: [:],
				identityReplacement: { AttributedString($0) }
			).get()
			var result = AttributedString("the ")
			result.append(AttributedString("testtwice").mergingAttributes(attributeContainerAlternateDescription))
			XCTAssertEqual(
				"the *test**twice*".applying(xibLocInfo: info),
				result
			)
		}
	}
	
	func testTwoOverlappingAttributesChange() throws {
		for _ in 0..<nRepeats {
			let info = try XibLocResolvingInfo<String, AttributedString>(
				defaultPluralityDefinition: PluralityDefinition(), escapeToken: nil,
				simpleSourceTypeReplacements: [:], orderedReplacements: [:], pluralGroups: [],
				attributesModifications: [
					OneWordTokens(token: "*"): helperAddTestAlternateDescription,
					OneWordTokens(token: "_"): helperAddTestLanguageIdentifier
				], simpleReturnTypeReplacements: [:],
				identityReplacement: { AttributedString($0) }
			).get()
			var result = AttributedString("the test ")
			result.append(AttributedString("one ").mergingAttributes(attributeContainerAlternateDescription))
			result.append(AttributedString("and").mergingAttributes(attributeContainerAlternateDescription).mergingAttributes(attributeContainerLanguageIdentifier))
			result.append(AttributedString(" two").mergingAttributes(attributeContainerLanguageIdentifier))
			XCTAssertEqual(
				"the test *one _and* two_".applying(xibLocInfo: info),
				result
			)
		}
	}
	
	func testApplyingOnStringTwice() throws {
		for _ in 0..<nRepeats {
			let info = try XibLocResolvingInfo<String, String>(
				defaultPluralityDefinition: PluralityDefinition(), escapeToken: nil,
				simpleSourceTypeReplacements: [OneWordTokens(token: "|"): { _ in "replaced" }], orderedReplacements: [:], pluralGroups: [],
				attributesModifications: [:], simpleReturnTypeReplacements: [:],
				identityReplacement: { $0 }
			).get()
			let tested = "the test |replacement|"
			let parsedXibLoc = ParsedXibLoc(source: tested, parserHelper: StringParserHelper.self, forXibLocResolvingInfo: info)
			XCTAssertEqual(
				parsedXibLoc.resolve(xibLocResolvingInfo: info, returnTypeHelperType: StringParserHelper.self),
				"the test replaced"
			)
			XCTAssertEqual(
				parsedXibLoc.resolve(xibLocResolvingInfo: info, returnTypeHelperType: StringParserHelper.self),
				"the test replaced"
			)
		}
	}
	
	func testApplyingOnMutableAttributedStringTwice() throws {
		for _ in 0..<nRepeats {
			let info = try XibLocResolvingInfo<AttributedString, AttributedString>(
				defaultPluralityDefinition: PluralityDefinition(), escapeToken: nil,
				simpleSourceTypeReplacements: [OneWordTokens(token: "|"): { _ in AttributedString("replaced") }], orderedReplacements: [:], pluralGroups: [],
				attributesModifications: [:], simpleReturnTypeReplacements: [:],
				identityReplacement: { $0 }
			).get()
			let tested = AttributedString("the test |replacement|")
			let parsedXibLoc = ParsedXibLoc(source: tested, parserHelper: AttributedStringParserHelper.self, forXibLocResolvingInfo: info)
			XCTAssertEqual(
				parsedXibLoc.resolve(xibLocResolvingInfo: info, returnTypeHelperType: AttributedStringParserHelper.self),
				AttributedString("the test replaced")
			)
			XCTAssertEqual(
				parsedXibLoc.resolve(xibLocResolvingInfo: info, returnTypeHelperType: AttributedStringParserHelper.self),
				AttributedString("the test replaced")
			)
		}
	}
	
	func testVariableChangeAfterAttrChangeInOrderedReplacementGroup1() throws {
		for _ in 0..<nRepeats {
			/* Bold, italic, font and text color already setup in the tests setup. */
			let info = CommonTokensGroup(simpleReplacement1: "sᴉoɔuɐɹℲ", genderOtherIsMale: true).str2AttrStrXibLocInfo
			var result = AttributedString("Yo sᴉoɔuɐɹℲ").mergingAttributes(XibLocConfig.defaultStr2AttrStrAttributes)
			result.setBoldOrItalic(bold: true, italic: nil, range: result.range(of: "Yo")!)
			XCTAssertEqual(
				"`*Yo* |username|¦Nope. We don’t greet women.´".applying(xibLocInfo: info),
				result
			)
			XCTAssertEqual(
				"`*Yo* |username|¦*Hey* |username|!´".applying(xibLocInfo: info),
				result
			)
		}
	}
	
	func testVariableChangeAfterAttrChangeInOrderedReplacementGroup2() throws {
		for _ in 0..<nRepeats {
			/* Bold, italic, font and text color already setup in the tests setup. */
			let info = CommonTokensGroup(simpleReplacement1: "sᴉoɔuɐɹℲ", genderOtherIsMale: false).str2AttrStrXibLocInfo
			var result = AttributedString("Yo sᴉoɔuɐɹℲ").mergingAttributes(XibLocConfig.defaultStr2AttrStrAttributes)
			result.setBoldOrItalic(bold: true, italic: nil, range: result.range(of: "Yo")!)
			XCTAssertEqual(
				"`Nope. We don’t greet women.¦*Yo* |username|´".applying(xibLocInfo: info),
				result
			)
			XCTAssertEqual(
				"`*Hey* |username|!¦*Yo* |username|´".applying(xibLocInfo: info),
				result
			)
		}
	}
	
	func testOverlappingAttributesChangesWithPluralInTheMiddle() throws {
		for _ in 0..<nRepeats {
			let (info, baseAttributes) = docCasesInfo
			var result = AttributedString("abcdefghijklmnqrstuvwxyzABCDEFGHIJKLMNOP").mergingAttributes(baseAttributes)
			result[result.range(of: "efghijklmnqrs")!].mergeAttributes(attributeContainerLanguageIdentifier)
			result[result.range(of: "jklmnqrstuvwx")!].mergeAttributes(attributeContainerAlternateDescription)
			XCTAssertEqual(
				"abcd*efghi_jkl<mn:op>qrs*tuvwx_yzABCDEFGHIJKLMNOP".applying(xibLocInfo: info),
				result
			)
		}
	}
	
	/* Also exists in ObjC */
	func testFromHappn1() throws {
		for _ in 0..<nRepeats {
			let str = "{*CrushTime खेलें* और देखें कि क्या आप अनुमान लगा सकते हैं कि आपको किसने पसंद किया!₋*CrushTime खेलें* और देखें कि क्या आप अनुमान लगा सकती हैं कि आपको किसने पसंद किया!}"
			/* Bold, italic, font and text color already setup in the tests setup. */
			let info = CommonTokensGroup(number: XibLocNumber(0), genderMeIsMale: true, genderOtherIsMale: true).str2AttrStrXibLocInfo
			var result = AttributedString("CrushTime खेलें और देखें कि क्या आप अनुमान लगा सकते हैं कि आपको किसने पसंद किया!", attributes: XibLocConfig.defaultStr2AttrStrAttributes)
			result.setBoldOrItalic(bold: true, italic: nil, range: result.range(of: "CrushTime खेलें")!)
			XCTAssertEqual(
				str.applying(xibLocInfo: info),
				result
			)
		}
	}
	
	func testFromHappn1Bis() throws {
		for _ in 0..<nRepeats {
			let str = "{CrushTime खेलें और देखें कि क्या आप अनुमान लगा सकते हैं कि आपको किसने पसंद किया!₋CrushTime खेलें और देखें कि क्या आप अनुमान लगा सकती हैं कि आपको किसने पसंद किया!}"
			/* Bold, italic, font and text color already setup in the tests setup. */
			let info = CommonTokensGroup(number: XibLocNumber(0), genderMeIsMale: true, genderOtherIsMale: true).str2AttrStrXibLocInfo
			let result = AttributedString("CrushTime खेलें और देखें कि क्या आप अनुमान लगा सकते हैं कि आपको किसने पसंद किया!", attributes: XibLocConfig.defaultStr2AttrStrAttributes)
			XCTAssertEqual(
				str.applying(xibLocInfo: info),
				result
			)
		}
	}
	
	/* Also exists in ObjC */
//	func testFromHappn1Ter() throws {
//		for _ in 0..<nRepeats {
//			let str = "*लें*"
//			/* Bold, italic, font and text color already setup in the tests setup. */
//			let info = CommonTokensGroup(number: XibLocNumber(0), genderMeIsMale: true, genderOtherIsMale: true).str2AttrStrXibLocInfo
//			let resultStr = "लें"
//			let result = AttributedString(resultStr, attributes: XibLocConfig.defaultStr2AttrStrAttributes)
//			result.setBoldOrItalic(bold: true, italic: nil, range: NSRange(location: 0, length: (resultStr as NSString).length))
//			XCTAssertEqual(
//				str.applying(xibLocInfo: info),
//				result
//			)
//		}
//	}
//
//	/* Same as Ter TBH… */
//	func testFromHappn1Quater() throws {
//		for _ in 0..<nRepeats {
//			let str = "*🧒🏻*"
//			/* Bold, italic, font and text color already setup in the tests setup. */
//			let info = CommonTokensGroup(number: XibLocNumber(0), genderMeIsMale: true, genderOtherIsMale: true).str2AttrStrXibLocInfo
//			let resultStr = "🧒🏻"
//			let result = AttributedString(resultStr, attributes: XibLocConfig.defaultStr2AttrStrAttributes)
//			result.setBoldOrItalic(bold: true, italic: nil, range: NSRange(location: 0, length: (resultStr as NSString).length))
//			XCTAssertEqual(
//				str.applying(xibLocInfo: info),
//				result
//			)
//		}
//	}
//
//	func testFromHappn1Quinquies() throws {
//		for _ in 0..<nRepeats {
//			let str = "🧒🏻*🧒🏻"
//			let info = try Str2AttrStrXibLocInfo(
//				attributesModifications: [OneWordTokens(token: "🧒🏻"): { attrStr, strRange, refStr in StringAttributesChangesDescription(changes: [.setBold]).nsapply(to: attrStr, range: NSRange(strRange, in: refStr)) }],
//				identityReplacement: { AttributedString($0, attributes: XibLocConfig.defaultStr2AttrStrAttributes) }
//			).get()
//			let resultStr = "*"
//			let result = AttributedString(resultStr, attributes: XibLocConfig.defaultStr2AttrStrAttributes)
//			result.setBoldOrItalic(bold: true, italic: nil, range: NSRange(location: 0, length: (resultStr as NSString).length))
//			XCTAssertEqual(
//				str.applying(xibLocInfo: info),
//				result
//			)
//		}
//	}
//
//	/* Also exists in ObjC */
//	func testFromHappn1Sexies() throws {
//		for _ in 0..<nRepeats {
//			let str = "🧒🏻👳🏿‍♀️🧒🏻"
//			let info = try Str2AttrStrXibLocInfo(
//				attributesModifications: [OneWordTokens(token: "🧒🏻"): { attrStr, strRange, refStr in StringAttributesChangesDescription(changes: [.setBold]).nsapply(to: attrStr, range: NSRange(strRange, in: refStr)) }],
//				identityReplacement: { AttributedString($0, attributes: XibLocConfig.defaultStr2AttrStrAttributes) }
//			).get()
//			let resultStr = "👳🏿‍♀️"
//			let result = AttributedString(resultStr, attributes: XibLocConfig.defaultStr2AttrStrAttributes)
//			result.setBoldOrItalic(bold: true, italic: nil, range: NSRange(location: 0, length: (resultStr as NSString).length))
//			XCTAssertEqual(
//				str.applying(xibLocInfo: info),
//				result
//			)
//		}
//	}
//
//	/* Copied from ObjC tests. */
//	func testFromHappn1Septies() throws {
//		for _ in 0..<nRepeats {
//			let str = "🧔🏻*🧒🏻*"
//			/* Bold, italic, font and text color already setup in the tests setup. */
//			let info = CommonTokensGroup(number: XibLocNumber(0), genderMeIsMale: true, genderOtherIsMale: true).str2AttrStrXibLocInfo
//			let resultStr = "🧔🏻🧒🏻"
//			let objcStart = ("🧔🏻" as NSString).length
//			let result = AttributedString(resultStr, attributes: XibLocConfig.defaultStr2AttrStrAttributes)
//			result.setBoldOrItalic(bold: true, italic: nil, range: NSRange(location: objcStart, length: (resultStr as NSString).length - objcStart))
//			XCTAssertEqual(
//				str.applying(xibLocInfo: info),
//				result
//			)
//		}
//	}
//
//	/* Copied from ObjC tests. */
//	func testFromHappn1Octies() throws {
//		for _ in 0..<nRepeats {
//			let str = "🧔🏻*a*"
//			/* Bold, italic, font and text color already setup in the tests setup. */
//			let info = CommonTokensGroup(number: XibLocNumber(0), genderMeIsMale: true, genderOtherIsMale: true).str2AttrStrXibLocInfo
//			let resultStr = "🧔🏻a"
//			let objcStart = ("🧔🏻" as NSString).length
//			let result = AttributedString(resultStr, attributes: XibLocConfig.defaultStr2AttrStrAttributes)
//			result.setBoldOrItalic(bold: true, italic: nil, range: NSRange(location: objcStart, length: (resultStr as NSString).length - objcStart))
//			XCTAssertEqual(
//				str.applying(xibLocInfo: info),
//				result
//			)
//		}
//	}
//
//	/* ***** Doc Cases Tests ***** */
//	/* Config:
//	 *    "*" is a left and right token for an attributes modification
//	 *    "_" is a left and right token for an attributes modification
//	 *    "|" is a left and right token for a simple replacement
//	 *    "<" ":" ">" are resp. a left, interior and right tokens for an ordered replacement. */
//
//	func testDocCase1() throws {
//		for _ in 0..<nRepeats {
//			let (info, baseAttributes) = docCasesInfo
//			let result = AttributedString("This text will be bold and italic too!").mergingAttributes(baseAttributes)
//			result.addAttributes([.accessibilityListItemIndex: NSNumber(value: 0)], range: NSRange(location: 18, length: 19))
//			result.addAttributes([.accessibilityListItemLevel: NSNumber(value: 0)], range: NSRange(location: 23, length: 10))
//			XCTAssertEqual(
//				"This text will be *bold _and italic_ too*!".applying(xibLocInfo: info),
//				result
//			)
//		}
//	}
//
//	func testDocCase2() throws {
//		for _ in 0..<nRepeats {
//			let (info, baseAttributes) = docCasesInfo
//			let result = AttributedString("This text will be bold and italic too!").mergingAttributes(baseAttributes)
//			result.addAttributes([.accessibilityListItemIndex: NSNumber(value: 0)], range: NSRange(location: 18, length: 19))
//			result.addAttributes([.accessibilityListItemLevel: NSNumber(value: 0)], range: NSRange(location: 23, length: 14))
//			XCTAssertEqual(
//				"This text will be *bold _and italic too*_!".applying(xibLocInfo: info),
//				result
//			)
//		}
//	}
//
//	func testDocCase3() throws {
//		for _ in 0..<nRepeats {
//			let (info, baseAttributes) = docCasesInfo
//			let result = AttributedString("This text will be bold and italic too!").mergingAttributes(baseAttributes)
//			result.addAttributes([.accessibilityListItemIndex: NSNumber(value: 0)], range: NSRange(location: 18, length: 19))
//			result.addAttributes([.accessibilityListItemLevel: NSNumber(value: 0)], range: NSRange(location: 23, length: 14))
//			XCTAssertEqual(
//				"This text will be *bold _and italic too_*!".applying(xibLocInfo: info),
//				result
//			)
//		}
//	}
//
//	func testDocCase4() throws {
//		for _ in 0..<nRepeats {
//			let (info, baseAttributes) = docCasesInfo
//			let result = AttributedString("This text will be bold and italic too!").mergingAttributes(baseAttributes)
//			result.addAttributes([.accessibilityListItemIndex: NSNumber(value: 0)], range: NSRange(location: 18, length: 8))
//			result.addAttributes([.accessibilityListItemLevel: NSNumber(value: 0)], range: NSRange(location: 23, length: 14))
//			XCTAssertEqual(
//				"This text will be *bold _and* italic too_!".applying(xibLocInfo: info),
//				result
//			)
//		}
//	}
//
//	func testDocCase5() throws {
//		for _ in 0..<nRepeats {
//			let (info, baseAttributes) = docCasesInfo
//			let result = AttributedString("replacement_value to be replaced").mergingAttributes(baseAttributes)
//			XCTAssertEqual(
//				"|*some text*| to be replaced".applying(xibLocInfo: info),
//				result
//			)
//		}
//	}
//
//	func testDocCase6() throws {
//		for _ in 0..<nRepeats {
//			let (info, baseAttributes) = docCasesInfo
//			let result = AttributedString("Let's replace replacement_value").mergingAttributes(baseAttributes)
//			result.addAttributes([.accessibilityListItemIndex: NSNumber(value: 0)], range: NSRange(location: 14, length: 17))
//			XCTAssertEqual(
//				"Let's replace *|some text|*".applying(xibLocInfo: info),
//				result
//			)
//		}
//	}
//
//	func testDocCase6Variant() throws {
//		for _ in 0..<nRepeats {
//			let (info, baseAttributes) = docCasesInfo
//			let result = AttributedString("Let's replace replacement_value").mergingAttributes(baseAttributes)
//			result.addAttributes([.accessibilityListItemIndex: NSNumber(value: 0)], range: NSRange(location: 14, length: 17))
//			result.addAttributes([.accessibilityListItemLevel: NSNumber(value: 0)], range: NSRange(location: 14, length: 17))
//			XCTAssertEqual(
//				"Let's replace _<*|some text|*:val2>_".applying(xibLocInfo: info),
//				result
//			)
//		}
//	}
//
//	func testDocCase7() throws {
//		for _ in 0..<nRepeats {
//			let (info, baseAttributes) = docCasesInfo
//			let result = AttributedString("Let's replace with either this is chosen or nope").mergingAttributes(baseAttributes)
//			result.addAttributes([.accessibilityListItemIndex: NSNumber(value: 0)], range: NSRange(location: 26, length: 4))
//			XCTAssertEqual(
//				"Let's replace with either <*this* is chosen:nope> or <nope:_that_>".applying(xibLocInfo: info),
//				result
//			)
//		}
//	}
//
//	func testDocCase8() throws {
//		for _ in 0..<nRepeats {
//			let (info, baseAttributes) = docCasesInfo
//			let result = AttributedString("Let's replace with either this is chosen or nope").mergingAttributes(baseAttributes)
//			result.addAttributes([.accessibilityListItemIndex: NSNumber(value: 0)], range: NSRange(location: 26, length: 22))
//			result.addAttributes([.accessibilityListItemLevel: NSNumber(value: 0)], range: NSRange(location: 44, length: 4))
//			XCTAssertEqual(
//				"Let's replace with either *<this is chosen:_nope_> or <_nope_:that>*".applying(xibLocInfo: info),
//				result
//			)
//		}
//	}
//
//	func testDocCase9() throws {
//		for _ in 0..<nRepeats {
//			let (info, baseAttributes) = docCasesInfo
//			let result1 = AttributedString("Let's replace *replacement_value").mergingAttributes(baseAttributes)
//			let result2 = AttributedString("Let's replace |some text|").mergingAttributes(baseAttributes)
//			result2.addAttributes([.accessibilityListItemIndex: NSNumber(value: 0)], range: NSRange(location: 14, length: 5))
//			let processed = "Let's replace *|some* text|".applying(xibLocInfo: info)
//			XCTAssert(processed == result1 || processed == result2)
//		}
//	}
//
//	func testDocCase10() throws {
//		for _ in 0..<nRepeats {
//			let (info, baseAttributes) = docCasesInfo
//			let result = AttributedString("Let's replace multiple").mergingAttributes(baseAttributes)
//			result.addAttributes([.accessibilityListItemIndex: NSNumber(value: 0)], range: NSRange(location: 14, length: 8))
//			XCTAssertEqual(
//				"Let's replace <*multiple*:*choices*:stuff>".applying(xibLocInfo: info),
//				result
//			)
//		}
//	}
//
//	func testDocCase11() throws {
//		for _ in 0..<nRepeats {
//			let (info, baseAttributes) = docCasesInfo
//			let result1 = AttributedString("Let's replace *multiple").mergingAttributes(baseAttributes)
//			let result2 = AttributedString("Let's replace <multiple:choices:stuff>").mergingAttributes(baseAttributes)
//			result2.addAttributes([.accessibilityListItemIndex: NSNumber(value: 0)], range: NSRange(location: 14, length: 17))
//			let processed = "Let's replace *<multiple:choices*:stuff>".applying(xibLocInfo: info)
//			XCTAssert(processed == result1 || processed == result2)
//		}
//	}
//
//	func testDocCase12() throws {
//		for _ in 0..<nRepeats {
//			let (info, baseAttributes) = docCasesInfo
//			let result1 = AttributedString("Let's replace *multiple").mergingAttributes(baseAttributes)
//			let result2 = AttributedString("Let's replace <multiple:choices:stuff>").mergingAttributes(baseAttributes)
//			result2.addAttributes([.accessibilityListItemIndex: NSNumber(value: 0)], range: NSRange(location: 15, length: 16))
//			let processed = "Let's replace <*multiple:choices*:stuff>".applying(xibLocInfo: info)
//			XCTAssert(processed == result1 || processed == result2)
//		}
//	}
	
	/* Baseline is set with XibLoc compiled with USE_UTF16_OFFSETS.
	 * USE_UTF16_OFFSETS is not used and is dangerous as it makes XibLoc crash
	 * for some Objective-C strings crash. See ParsedXibLoc.swift for more info. */
	func testPerf2() throws {
		measure{
			for _ in 0..<nRepeats {
				let str = "{*CrushTime खेलें* और देखें कि क्या आप अनुमान लगा सकते हैं कि आपको किसने पसंद किया!₋*CrushTime खेलें* और देखें कि क्या आप अनुमान लगा सकती हैं कि आपको किसने पसंद किया!}"
				/* Bold, italic, font and text color already setup in the tests setup. */
				let info = CommonTokensGroup(number: XibLocNumber(0), genderMeIsMale: true, genderOtherIsMale: true).str2AttrStrXibLocInfo
				var result = AttributedString("CrushTime खेलें और देखें कि क्या आप अनुमान लगा सकते हैं कि आपको किसने पसंद किया!").mergingAttributes(XibLocConfig.defaultStr2AttrStrAttributes)
				result.setBoldOrItalic(bold: true, italic: nil, range: result.range(of: "CrushTime खेलें")!)
				XCTAssertEqual(
					str.applying(xibLocInfo: info),
					result
				)
			}
		}
	}
	
	
	private var attributeContainerAlternateDescription: AttributeContainer = {
		var ret = AttributeContainer()
		ret.alternateDescription = "set"
		return ret
	}()
	
	private var attributeContainerLanguageIdentifier: AttributeContainer = {
		var ret = AttributeContainer()
		ret.languageIdentifier = "en"
		return ret
	}()
	
	private func helperAddTestAlternateDescription(to attributedString: inout AttributedString, strRange: Range<String.Index>, refStr: String) {
		attributedString[Range(strRange, in: attributedString)!].mergeAttributes(attributeContainerAlternateDescription)
	}
	
	private func helperAddTestLanguageIdentifier(to attributedString: inout AttributedString, strRange: Range<String.Index>, refStr: String) {
		attributedString[Range(strRange, in: attributedString)!].mergeAttributes(attributeContainerLanguageIdentifier)
	}
	
	private lazy var docCasesInfo: (Str2AttrStrXibLocInfo, AttributeContainer) = {
		var baseAttributes = AttributeContainer()
		baseAttributes.font = XibLocFont.systemFont(ofSize: 14)
		baseAttributes.foregroundColor = XibLocColor.black
		let info = Str2AttrStrXibLocInfo(
			escapeToken: nil,
			simpleSourceTypeReplacements: [OneWordTokens(token: "|"): { _ in "replacement_value" }],
			orderedReplacements: [MultipleWordsTokens(leftToken: "<", interiorToken: ":", rightToken: ">"): 0],
			attributesModifications: [
				OneWordTokens(token: "*"): helperAddTestLanguageIdentifier,
				OneWordTokens(token: "_"): helperAddTestAlternateDescription
			],
			identityReplacement: { AttributedString($0).mergingAttributes(baseAttributes) }
		)!
		return (info, baseAttributes)
	}()
	
}

#endif
