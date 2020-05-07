// swift-tools-version:5.0
import PackageDescription


let package = Package(
	name: "XibLoc",
	products: [
		.library(name: "XibLoc", targets: ["XibLoc"])
	],
	dependencies: [
		.package(url: "https://github.com/happn-tech/DummyLinuxOSLog.git", from: "1.0.0")
	],
	targets: [
		.target(name: "XibLoc", dependencies: ["DummyLinuxOSLog"]),
		.testTarget(name: "XibLocTests", dependencies: ["XibLoc"], exclude: ["XibLocTestsObjC.m"])
	]
)
