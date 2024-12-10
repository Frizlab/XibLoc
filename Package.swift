// swift-tools-version:6.0
import PackageDescription


let swiftSettings: [SwiftSetting] = []

let package = Package(
	name: "XibLoc",
	defaultLocalization: "en",
	platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)],
	products: [
		.library(name: "XibLoc", targets: ["XibLoc"])
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-log.git",          from: "1.2.0"),
		.package(url: "https://github.com/Frizlab/GlobalConfModule.git", from: "0.4.0"),
	],
	targets: [
		.target(name: "XibLoc", dependencies: [
			.product(name: "Logging",          package: "swift-log"),
			.product(name: "GlobalConfModule", package: "GlobalConfModule")
		], swiftSettings: swiftSettings),
		.testTarget(
			name: "XibLocTests", dependencies: ["XibLoc"], exclude: ["XibLocTestsObjC.m"],
			resources: [Resource.process("Helpers/en.lproj/Localizable.strings")],
			swiftSettings: swiftSettings
		)
	]
)
