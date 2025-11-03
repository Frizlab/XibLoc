/*
Copyright 2020 happn

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
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

import GlobalConfModule



/**
 A default Tokens Group.
 
 This tokens group should be enough to process most, if not all of your translations.
 If you need more tokens, you can create your own groups, the same way this one has been done
  (or any other way you want, the idea is simply to get a `XibLocResolvingInfo` at the end;
  you can even extend `XibLocResolvingInfo` to create a custom init if you prefer,
  though you must remember to call `initParsingInfo` at the end of your init).
 
 The default init of this group will set `defaultBoldAttrsChanger` and `defaultItalicAttrsChanger` resp. to the `*` and `_` tokens.
 If you don’t want bold or italic, you must explicitly disable it, whether when initing the group, or by setting the defaults in the `Conf`.
 
 List of tokens:
 - Escape: `~`
 - Simple replacement 1: `|`
 - Simple replacement 2: `^`
 - Plural: `<` `:` `>`
 - Plural value: `#`
 - Gender me: `{` `₋` `}`
 - Gender other: ``` ` ``` `¦` `´`
 - Bold: `*`
 - Italic: `_`
 
 - Note: Only the transformations set to a non-nil value will see their tokens parsed.
 Which means, the following string `hello_world_how_are_you`, if processed with a `CommonTokensGroup()` (using all default arguments),
  will yield the same string when processed with the str2str resolving info,
  but will yield the attributed string `helloworldhowareyou` with the words “`world`” and “`are`” in italic if processed with the str2attrstr resolving info.
 
 This is because an str2str resolving info will not do anything with the bold and italic tokens and thus, they are not put in the str2str resolving info.
 
 If you’re processing translations automatically through some kind of script or app, because of the behaviour described above, it is recommended you escape as many tokens as possible.
 XibLoc will remove all the escape tokens.
 For instance, using the previous example, one should use the string `hello~_world~_how~_are~_you` whether they expect the translation to be used in an attributed or a non-attributed string.
 Finally, don’t forget to escape the escape token if it is in the original string.
 
 The list of all the tokens (except the escape one!) is given in a static variable for convenience, as well as a static method to escape all of the tokens in a string. */
public struct CommonTokensGroup : TokensGroup {
	
	public static let escapeToken = "~"
	public static let tokensExceptEscape = Set(arrayLiteral: "|", "^", "#", "<", ":", ">", "{", "₋", "}", "`", "¦", "´", "*", "_")
	
	/** Token is `|` */
	public var simpleReplacement1: String?
	/** Token is `^` */
	public var simpleReplacement2: String?
	/**
	 Intentionally blank line (for doc formatting purposes).
	 
	 Tokens:
	 - For the number replacement: `#`
	 - For the plural value: `<` `:` `>` */
	public var number: XibLocNumber?
	
	/**
	 Tokens: `{` `₋` `}`
	 
	 - Important: The dash is not a standard dash… */
	public var genderMeIsMale: Bool?
	/** Tokens: ``` ` ``` `¦` `´` */
	public var genderOtherIsMale: Bool?
	
	public var defaultPluralityDefinition: PluralityDefinition
	
	public var baseFont: XibLocFont?
	public var baseColor: XibLocColor?
	public var baseAttributes: AttributesContainer
	
	/** Token is `*` */
	public var boldAttrsChanger: AttributesChanger?
	/** Token is `_` */
	public var italicAttrsChanger: AttributesChanger?
	
	public init(
		defaultPluralityDefinition: PluralityDefinition = Conf[\.xibLoc.defaultPluralityDefinition],
		simpleReplacement1: String? = nil,
		simpleReplacement2: String? = nil,
		number: XibLocNumber? = nil,
		genderMeIsMale: Bool? = nil,
		genderOtherIsMale: Bool? = nil,
		baseFont: XibLocFont? = nil,
		baseColor: XibLocColor? = nil,
		baseAttributes: AttributesContainer = Conf[\.xibLoc.defaultAttributes],
		boldAttrsChanger: AttributesChanger? = Conf[\.xibLoc.defaultBoldAttrsChanger],
		italicAttrsChanger: AttributesChanger? = Conf[\.xibLoc.defaultItalicAttrsChanger]
	) {
		self.defaultPluralityDefinition = defaultPluralityDefinition
		
		self.simpleReplacement1 = simpleReplacement1
		self.simpleReplacement2 = simpleReplacement2
		self.number = number
		self.genderMeIsMale = genderMeIsMale
		self.genderOtherIsMale = genderOtherIsMale
		
		self.baseFont = baseFont
		self.baseColor = baseColor
		self.baseAttributes = baseAttributes
		
		self.boldAttrsChanger = boldAttrsChanger
		self.italicAttrsChanger = italicAttrsChanger
	}
	
	public var str2StrXibLocInfo: Str2StrXibLocInfo {
		return Str2StrXibLocInfo(
			defaultPluralityDefinition: defaultPluralityDefinition,
			escapeToken: Self.escapeToken,
			simpleSourceTypeReplacements: [:],
			orderedReplacements: [
				MultipleWordsTokens(leftToken: "{", interiorToken: "₋", rightToken: "}"): genderMeIsMale.flatMap{ $0 ? 0 : 1 },
				MultipleWordsTokens(leftToken: "`", interiorToken: "¦", rightToken: "´"): genderOtherIsMale.flatMap{ $0 ? 0 : 1 }
			].compactMapValues{ $0 },
			pluralGroups: [number.flatMap{ (MultipleWordsTokens(leftToken: "<", interiorToken: ":", rightToken: ">"), $0.pluralValue) }].compactMap{ $0 },
			attributesModifications: [:],
			simpleReturnTypeReplacements: [
				OneWordTokens(token: "|"): simpleReplacement1.flatMap{ r in { _ in r } },
				OneWordTokens(token: "^"): simpleReplacement2.flatMap{ r in { _ in r } },
				OneWordTokens(token: "#"): number.flatMap{ n in { _ in n.localizedString } }
			].compactMapValues{ $0 },
			identityReplacement: { $0 }
		)! /* We force unwrap because we _know_ these tokens are valid. */
	}
	
	@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
	public var str2AttrStrXibLocInfo: Str2AttrStrXibLocInfo {
		var defaultAttributes = baseAttributes.attributedStringAttributes
#if canImport(AppKit) || canImport(UIKit)
		if let f = baseFont  {defaultAttributes[keyPath: \.font] = f} /* Note: The keypath syntax “hides” the “NSFont is not Sendable” warning. Is it correct? idk… */
		if let c = baseColor {defaultAttributes.foregroundColor = c}
#endif
		
		let   boldAttrsChanger =   boldAttrsChanger as? AttributedStringAttributesChanger
		let italicAttrsChanger = italicAttrsChanger as? AttributedStringAttributesChanger
		if boldAttrsChanger == nil && self.boldAttrsChanger != nil {
#if canImport(os)
			Conf.oslog.flatMap{ os_log("Ignoring a bold attributes changer which is not an AttributedStringAttributesChanger when asked for a Str2AttrStrXibLocInfo.", log: $0, type: .info) }
#endif
			Conf.logger?.warning("Ignoring a bold attributes changer which is not an AttributedStringAttributesChanger when asked for a Str2AttrStrXibLocInfo.")
		}
		if italicAttrsChanger == nil && self.italicAttrsChanger != nil {
#if canImport(os)
			Conf.oslog.flatMap{ os_log("Ignoring an italic attributes changer which is not an AttributedStringAttributesChanger when asked for a Str2AttrStrXibLocInfo.", log: $0, type: .info) }
#endif
			Conf.logger?.warning("Ignoring an italic attributes changer which is not an AttributedStringAttributesChanger when asked for a Str2AttrStrXibLocInfo.")
		}
		
		return Str2AttrStrXibLocInfo(
			defaultPluralityDefinition: defaultPluralityDefinition,
			escapeToken: Self.escapeToken,
			simpleSourceTypeReplacements: [
				OneWordTokens(token: "|"): simpleReplacement1.flatMap{ r in { _ in r } },
				OneWordTokens(token: "^"): simpleReplacement2.flatMap{ r in { _ in r } },
				OneWordTokens(token: "#"): number.flatMap{ n in { _ in n.localizedString } }
			].compactMapValues{ $0 },
			orderedReplacements: [
				MultipleWordsTokens(leftToken: "{", interiorToken: "₋", rightToken: "}"): genderMeIsMale.flatMap{ $0 ? 0 : 1 },
				MultipleWordsTokens(leftToken: "`", interiorToken: "¦", rightToken: "´"): genderOtherIsMale.flatMap{ $0 ? 0 : 1 }
			].compactMapValues{ $0 },
			pluralGroups: [number.flatMap{ (MultipleWordsTokens(leftToken: "<", interiorToken: ":", rightToken: ">"), $0.pluralValue) }].compactMap{ $0 },
			attributesModifications: [
				OneWordTokens(token: "*"):   boldAttrsChanger?.apply(on:in:of:),
				OneWordTokens(token: "_"): italicAttrsChanger?.apply(on:in:of:),
			].compactMapValues{ $0 },
			simpleReturnTypeReplacements: [:],
			identityReplacement: { AttributedString($0, attributes: defaultAttributes) }
		)! /* We force unwrap because we _know_ these tokens are valid. */
	}
	
	public var str2NSAttrStrXibLocInfo: Str2NSAttrStrXibLocInfo {
		var defaultAttributes = baseAttributes.nsAttributedStringAttributes
#if canImport(AppKit) || canImport(UIKit)
		if let f = baseFont  {defaultAttributes[.font] = f}
		if let c = baseColor {defaultAttributes[.foregroundColor] = c}
#endif
		
		let   boldAttrsChanger =   boldAttrsChanger as? NSAttributedStringAttributesChanger
		let italicAttrsChanger = italicAttrsChanger as? NSAttributedStringAttributesChanger
		if boldAttrsChanger == nil && self.boldAttrsChanger != nil {
#if canImport(os)
			if #available(macOS 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {
				Conf.oslog.flatMap{ os_log("Ignoring a bold attributes changer which is not an NSAttributedStringAttributesChanger when asked for a Str2NSAttrStrXibLocInfo.", log: $0, type: .info) }}
#endif
			Conf.logger?.warning("Ignoring a bold attributes changer which is not an NSAttributedStringAttributesChanger when asked for a Str2NSAttrStrXibLocInfo.")
		}
		if italicAttrsChanger == nil && self.italicAttrsChanger != nil {
#if canImport(os)
			if #available(macOS 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {
				Conf.oslog.flatMap{ os_log("Ignoring an italic attributes changer which is not an NSAttributedStringAttributesChanger when asked for a Str2NSAttrStrXibLocInfo.", log: $0, type: .info) }}
#endif
			Conf.logger?.warning("Ignoring an italic attributes changer which is not an NSAttributedStringAttributesChanger when asked for a Str2NSAttrStrXibLocInfo.")
		}
		
		return Str2NSAttrStrXibLocInfo(
			defaultPluralityDefinition: defaultPluralityDefinition,
			escapeToken: Self.escapeToken,
			simpleSourceTypeReplacements: [
				OneWordTokens(token: "|"): simpleReplacement1.flatMap{ r in { _ in r } },
				OneWordTokens(token: "^"): simpleReplacement2.flatMap{ r in { _ in r } },
				OneWordTokens(token: "#"): number.flatMap{ n in { _ in n.localizedString } }
			].compactMapValues{ $0 },
			orderedReplacements: [
				MultipleWordsTokens(leftToken: "{", interiorToken: "₋", rightToken: "}"): genderMeIsMale.flatMap{ $0 ? 0 : 1 },
				MultipleWordsTokens(leftToken: "`", interiorToken: "¦", rightToken: "´"): genderOtherIsMale.flatMap{ $0 ? 0 : 1 }
			].compactMapValues{ $0 },
			pluralGroups: [number.flatMap{ (MultipleWordsTokens(leftToken: "<", interiorToken: ":", rightToken: ">"), $0.pluralValue) }].compactMap{ $0 },
			attributesModifications: [
				OneWordTokens(token: "*"):   boldAttrsChanger?.apply(on:in:of:),
				OneWordTokens(token: "_"): italicAttrsChanger?.apply(on:in:of:),
			].compactMapValues{ $0 },
			simpleReturnTypeReplacements: [:],
			identityReplacement: { NSMutableAttributedString(string: $0, attributes: defaultAttributes) }
		)! /* We force unwrap because we _know_ these tokens are valid. */
	}
	
}

extension String {
	
	/**
	 Apply a `CommonTokensGroup` on your string.
	 
	 - parameter simpleReplacement1: Token is `|`
	 - parameter simpleReplacement2: Token is `^`
	 - parameter number: Tokens are `#` (number value), `<` `:` `>` (plural)
	 - parameter genderMeIsMale: Tokens are `{` `₋` `}`
	 - parameter genderOtherIsMale: Tokens are ``` ` ``` `¦` `´` */
	public func applyingCommonTokens(
		defaultPluralityDefinition: PluralityDefinition = Conf[\.xibLoc.defaultPluralityDefinition],
		simpleReplacement1: String? = nil,
		simpleReplacement2: String? = nil,
		number: XibLocNumber? = nil,
		genderMeIsMale: Bool? = nil,
		genderOtherIsMale: Bool? = nil
	) -> String {
		return applying(xibLocInfo: CommonTokensGroup(
			defaultPluralityDefinition: defaultPluralityDefinition,
			simpleReplacement1: simpleReplacement1,
			simpleReplacement2: simpleReplacement2,
			number: number,
			genderMeIsMale: genderMeIsMale,
			genderOtherIsMale: genderOtherIsMale
		).str2StrXibLocInfo)
	}
	
	/**
	 Apply a `CommonTokensGroup` on your string with attributed string result.
	 
	 - parameter simpleReplacement1: Token is `|`
	 - parameter simpleReplacement2: Token is `^`
	 - parameter number: Tokens are `#` (number value), `<` `:` `>` (plural)
	 - parameter genderMeIsMale: Tokens are `{` `₋` `}`
	 - parameter genderOtherIsMale: Tokens are ``` ` ``` `¦` `´`
	 - parameter boldAttrsChangesDescription: Token is `*`
	 - parameter italicAttrsChangesDescription: Token is `_` */
	@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
	public func applyingCommonTokensAttributed(
		defaultPluralityDefinition: PluralityDefinition = Conf[\.xibLoc.defaultPluralityDefinition],
		simpleReplacement1: String? = nil,
		simpleReplacement2: String? = nil,
		number: XibLocNumber? = nil,
		genderMeIsMale: Bool? = nil,
		genderOtherIsMale: Bool? = nil,
		baseFont: XibLocFont? = nil,
		baseColor: XibLocColor? = nil,
		baseAttributes: AttributesContainer = Conf[\.xibLoc.defaultAttributes],
		boldAttrsChanger: AttributesChanger? = Conf[\.xibLoc.defaultBoldAttrsChanger],
		italicAttrsChanger: AttributesChanger? = Conf[\.xibLoc.defaultItalicAttrsChanger]
	) -> AttributedString {
		return applying(xibLocInfo: CommonTokensGroup(
			defaultPluralityDefinition: defaultPluralityDefinition,
			simpleReplacement1: simpleReplacement1,
			simpleReplacement2: simpleReplacement2,
			number: number,
			genderMeIsMale: genderMeIsMale,
			genderOtherIsMale: genderOtherIsMale,
			baseFont: baseFont,
			baseColor: baseColor,
			baseAttributes: baseAttributes,
			boldAttrsChanger: boldAttrsChanger,
			italicAttrsChanger: italicAttrsChanger
		).str2AttrStrXibLocInfo)
	}
	
	/**
	 Apply a `CommonTokensGroup` on your string with attributed string result.
	 
	 - parameter simpleReplacement1: Token is `|`
	 - parameter simpleReplacement2: Token is `^`
	 - parameter number: Tokens are `#` (number value), `<` `:` `>` (plural)
	 - parameter genderMeIsMale: Tokens are `{` `₋` `}`
	 - parameter genderOtherIsMale: Tokens are ``` ` ``` `¦` `´`
	 - parameter boldAttrsChanger: Token is `*`
	 - parameter italicAttrsChanger: Token is `_` */
	@available(macOS,   deprecated: 12, message: "Use AttributedString")
	@available(iOS,     deprecated: 15, message: "Use AttributedString")
	@available(tvOS,    deprecated: 15, message: "Use AttributedString")
	@available(watchOS, deprecated: 8,  message: "Use AttributedString")
	public func applyingCommonTokensNSAttributed(
		defaultPluralityDefinition: PluralityDefinition = Conf[\.xibLoc.defaultPluralityDefinition],
		simpleReplacement1: String? = nil,
		simpleReplacement2: String? = nil,
		number: XibLocNumber? = nil,
		genderMeIsMale: Bool? = nil,
		genderOtherIsMale: Bool? = nil,
		baseFont: XibLocFont? = nil,
		baseColor: XibLocColor? = nil,
		baseAttributes: AttributesContainer = Conf[\.xibLoc.defaultAttributes],
		boldAttrsChanger: AttributesChanger? = Conf[\.xibLoc.defaultBoldAttrsChanger],
		italicAttrsChanger: AttributesChanger? = Conf[\.xibLoc.defaultItalicAttrsChanger]
	) -> NSMutableAttributedString {
		return applying(xibLocInfo: CommonTokensGroup(
			defaultPluralityDefinition: defaultPluralityDefinition,
			simpleReplacement1: simpleReplacement1,
			simpleReplacement2: simpleReplacement2,
			number: number,
			genderMeIsMale: genderMeIsMale,
			genderOtherIsMale: genderOtherIsMale,
			baseFont: baseFont,
			baseColor: baseColor,
			baseAttributes: baseAttributes,
			boldAttrsChanger: boldAttrsChanger,
			italicAttrsChanger: italicAttrsChanger
		).str2NSAttrStrXibLocInfo)
	}
	
}
