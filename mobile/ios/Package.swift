// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "INSTALL",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "INSTALL",
            targets: ["INSTALL"]
        )
    ],
    dependencies: [
        // Firebase
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.20.0")
    ],
    targets: [
        .target(
            name: "INSTALL",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk")
            ]
        ),
        .testTarget(
            name: "INSTALLTests",
            dependencies: ["INSTALL"]
        )
    ]
)
