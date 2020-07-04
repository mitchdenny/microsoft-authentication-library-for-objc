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
            url: "https://github.com/mitchdenny/microsoft-authentication-library-for-objc/releases/download/1.1.6-beta.1/MSAL.xcframework.zip",
            checksum: "57cca1fa07c9bf0ce4e0c7e367a7530cdb08bb8399cd00ff7cf7b8f12f45849d"
            )
    ]
)
