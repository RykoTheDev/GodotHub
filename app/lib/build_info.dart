// The toolchain versions this build was made with. Neither one can be read from a running app,
// so the release workflow passes them in, from the same values it installs the toolchains with:
//   --dart-define=FLUTTER_BUILD_VERSION=3.50.1 --dart-define=RUST_BUILD_VERSION=1.99.1
// A build without them (a plain `flutter run`) simply has no versions to show.
const flutterBuildVersion = String.fromEnvironment('FLUTTER_BUILD_VERSION');
const rustBuildVersion = String.fromEnvironment('RUST_BUILD_VERSION');

/// One line per known version, for the "Built with" tooltip. Empty when none are known.
String builtWithVersions({String flutter = flutterBuildVersion, String rust = rustBuildVersion}) =>
    [if (flutter.isNotEmpty) 'Flutter $flutter', if (rust.isNotEmpty) 'Rust $rust'].join('\n');
