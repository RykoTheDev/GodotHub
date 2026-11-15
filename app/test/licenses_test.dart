import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the Rust notices name every crate and keep each license text', () {
    final text = File('assets/licenses/rust-crates.txt').readAsStringSync();
    final entries = parseRustNotices(text);
    final crates = {for (final entry in entries) ...entry.packages};
    expect(crates, containsAll(['serde', 'tokio', 'reqwest', 'minisign-verify', 'zip', 'flutter_rust_bridge']));
    final listed = RegExp(r'^([A-Za-z0-9_-]+) \d[^ ]* \(', multiLine: true).allMatches(text).map((m) => m.group(1)!).toSet();
    expect(crates, listed);
    for (final entry in entries) {
      expect(entry.paragraphs.map((p) => p.text).join().trim(), isNotEmpty);
    }
  });

  test('fonts, icons, flags and Rust crates are registered with the license page', () async {
    registerBundledLicenses();
    final packages = <String>{};
    await for (final entry in LicenseRegistry.licenses) {
      packages.addAll(entry.packages);
    }
    expect(packages, containsAll(['Inter', 'Google Sans Code', 'Font Awesome Free', 'Flag icons', 'serde', 'tokio']));
    expect(packages.contains('Microsoft Visual C++ runtime'), Platform.isWindows);
  });
}
