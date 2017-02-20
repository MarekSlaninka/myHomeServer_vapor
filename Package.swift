import PackageDescription

let package = Package(
    name: "myHomeServer_vapor",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 1),
        .Package(url: "https://github.com/uraimo/SwiftyGPIO.git", majorVersion: 0),
        .Package(url: "https://github.com/BrettRToomey/Jobs.git", majorVersion: 0),
        .Package(url: "https://github.com/vapor/sqlite-provider.git", majorVersion: 1, minor: 1)
    ]
)
