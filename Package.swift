// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Microsoft Authentication Library for Objective-C",
    products: [
        .library(
            name: "microsoft-authentication-library-for-objc",
            targets: ["MSAL"]),
    ],
    targets: [
        .binaryTarget(
            name: "MSAL",
            parth: "artifacts/MSAL.xcframework.zip")
    ]
)
