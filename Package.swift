import PackageDescription

let package = Package(
    name: "myHomeServer_vapor",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 1, minor: 0)
    ]
)
