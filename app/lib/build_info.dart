import 'package:flutter/foundation.dart' show kReleaseMode;

// The toolchain versions this build was made with. Neither one can be read from a running app,
// so the release workflow passes them in, from the same values it installs the toolchains with:
//   --dart-define=FLUTTER_BUILD_VERSION=3.50.1 --dart-define=RUST_BUILD_VERSION=1.99.1
// A build without them, like a plain `flutter run`, has no versions to show.
const flutterBuildVersion = String.fromEnvironment('FLUTTER_BUILD_VERSION');
const rustBuildVersion = String.fromEnvironment('RUST_BUILD_VERSION');

/// What the "Built with" tooltip says: one line per known version. A development build that was
/// not given them says why there are none (plain English, like the other development-only text);
/// a release build never shows that.
String builtWithVersions({
  String flutter = flutterBuildVersion,
  String rust = rustBuildVersion,
  bool release = kReleaseMode,
}) {
  final versions = [if (flutter.isNotEmpty) 'Flutter $flutter', if (rust.isNotEmpty) 'Rust $rust'];
  if (versions.isNotEmpty) return versions.join('\n');
  if (release) return '';
  return 'This is a development build. Run it with --dart-define=FLUTTER_BUILD_VERSION=x.y.z and '
      '--dart-define=RUST_BUILD_VERSION=x.y.z to show the versions here. Release builds have them.';
}
