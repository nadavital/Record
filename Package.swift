// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "record",
    platforms: [.iOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0"),
    ],
    targets: [
        .target(
            name: "record",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk")
            ],
            path: "record"
        )
    ]
)