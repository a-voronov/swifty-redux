// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "SwiftyRedux",
    platforms: [
        .iOS(.v10),
        .macOS(.v10_12)
    ],
    products: [
        .library(name: "SwiftyRedux", targets: ["SwiftyRedux"]),
        .library(name: "SwiftyReduxEpics", targets: ["SwiftyReduxEpics"]),
        .library(name: "SwiftyReduxReactiveExtensions", targets: ["SwiftyReduxReactiveExtensions"])
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveCocoa/ReactiveSwift.git", .upToNextMajor(from: "6.0.0"))
    ],
    targets: [
        .target(
            name: "SwiftyRedux",
            path: "SwiftyRedux/Sources",
            exclude: [
                "Epics",
                "ReactiveExtensions"
            ],
            linkerSettings: [
                .linkedFramework("Foundation")
            ]
        ),
        .target(
            name: "SwiftyReduxEpics",
            dependencies: [
                "SwiftyRedux",
                .product(name: "ReactiveSwift", package: "ReactiveSwift")
            ],
            path: "SwiftyRedux/Sources/Epics"
        ),
        .target(
            name: "SwiftyReduxReactiveExtensions",
            dependencies: [
                "SwiftyRedux",
                .product(name: "ReactiveSwift", package: "ReactiveSwift")
            ],
            path: "SwiftyRedux/Sources/ReactiveExtensions"
        ),
        .testTarget(
            name: "SwiftyReduxTests",
            dependencies: [
                "SwiftyRedux",
                "SwiftyReduxEpics",
                "SwiftyReduxReactiveExtensions",
                .product(name: "ReactiveSwift", package: "ReactiveSwift")
            ],
            path: "SwiftyRedux/Tests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
