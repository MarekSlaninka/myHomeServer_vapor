import PackageDescription

let package = Package(
    name: "myHomeServer_vapor",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 1, minor: 1),
        .Package(url: "https://github.com/uraimo/SwiftyGPIO.git", majorVersion: 0),
        .Package(url: "https://github.com/matthijs2704/vapor-apns.git", majorVersion: 1, minor: 1)
    ]
)
