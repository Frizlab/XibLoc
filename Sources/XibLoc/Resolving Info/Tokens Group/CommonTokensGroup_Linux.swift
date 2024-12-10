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

#if !canImport(Darwin)
import Foundation

import GlobalConfModule



/**
 A default Tokens Group.
 
 See doc of the non Linux variant for more info.
 
 List of tokens:
 - Escape: `~`
 - Simple replacement 1: `|`
 - Simple replacement 2: `^`
 - Plural: `<` `:` `>`
 - Plural value: `#`
 - Gender me: `{` `₋` `}`
 - Gender other: \` `¦` `´` */
public struct CommonTokensGroup : TokensGroup {
	
	public static let escapeToken = "~"
	public static let tokensExceptEscape = Set(arrayLiteral: "|", "^", "#", "<", ":", ">", "{", "₋", "}", "`", "¦", "´")
	
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
	/**
	 Tokens: \` `¦` `´`
	 
	 (Doc formatting note: I did not find a way to specify the first token is code
	  (because it’s the same token as the token used to specify we have code in doc comments).
	 Doesn’t matter, it’s not really visible though.) */
	public var genderOtherIsMale: Bool?
	
	public init(
		simpleReplacement1 r1: String? = nil,
		simpleReplacement2 r2: String? = nil,
		number n: XibLocNumber? = nil,
		genderMeIsMale gm: Bool? = nil,
		genderOtherIsMale go: Bool? = nil
	) {
		simpleReplacement1 = r1
		simpleReplacement2 = r2
		number = n
		genderMeIsMale = gm
		genderOtherIsMale = go
	}
	
	public var str2StrXibLocInfo: Str2StrXibLocInfo {
		/* Building this accessor the same way it is build for macOS crashes the compiler on Linux.
		 * So we do it that way. */
		var orderedReplacements = [MultipleWordsTokens: Int]()
		var pluralGroups = [(MultipleWordsTokens, PluralValue)]()
		var simpleReturnTypeReplacements = Dictionary<OneWordTokens, (String) -> String>()
		
		if let isMeMale = genderMeIsMale       {orderedReplacements[MultipleWordsTokens(leftToken: "{", interiorToken: "₋", rightToken: "}")] = isMeMale ? 0 : 1}
		if let isOtherMale = genderOtherIsMale {orderedReplacements[MultipleWordsTokens(leftToken: "`", interiorToken: "¦", rightToken: "´")] = isOtherMale ? 0 : 1}
		
		if let number = number {
			pluralGroups.append((MultipleWordsTokens(leftToken: "<", interiorToken: ":", rightToken: ">"), number.pluralValue))
			simpleReturnTypeReplacements[OneWordTokens(token: "#")] = { _ in number.localizedString }
		}
		
		if let s1 = simpleReplacement1 {simpleReturnTypeReplacements[OneWordTokens(token: "|")] = { _ in s1 }}
		if let s2 = simpleReplacement2 {simpleReturnTypeReplacements[OneWordTokens(token: "^")] = { _ in s2 }}
		
		return Str2StrXibLocInfo(
			defaultPluralityDefinition: Conf.defaultPluralityDefinition,
			escapeToken: Self.escapeToken,
			simpleSourceTypeReplacements: [:],
			orderedReplacements: orderedReplacements,
			pluralGroups: pluralGroups,
			attributesModifications: [:],
			simpleReturnTypeReplacements: simpleReturnTypeReplacements,
			identityReplacement: { $0 }
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
	 - parameter genderOtherIsMale: Tokens are \` `¦` `´` */
	public func applyingCommonTokens(
		simpleReplacement1: String? = nil,
		simpleReplacement2: String? = nil,
		number: XibLocNumber? = nil,
		genderMeIsMale: Bool? = nil,
		genderOtherIsMale: Bool? = nil
	) -> String {
		return applying(xibLocInfo: CommonTokensGroup(
			simpleReplacement1: simpleReplacement1,
			simpleReplacement2: simpleReplacement2,
			number: number,
			genderMeIsMale: genderMeIsMale,
			genderOtherIsMale: genderOtherIsMale
		).str2StrXibLocInfo)
	}
	
}

#endif
