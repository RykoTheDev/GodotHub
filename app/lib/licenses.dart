import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const visualCppRuntimeNotice =
    'GodotHub for Windows includes the Microsoft Visual C++ runtime (msvcp140.dll, vcruntime140.dll, '
    'vcruntime140_1.dll, concrt140.dll and related files) next to the app. These files are Microsoft '
    'Distributable Code, redistributed under the Microsoft Software License Terms for Microsoft Visual Studio. '
    'They remain the property of Microsoft Corporation. Copyright (c) Microsoft Corporation. All rights reserved.';

const _bundledNotices = <(List<String>, String)>[
  (['Inter'], 'assets/fonts/Inter-LICENSE.txt'),
  (['Google Sans Code'], 'assets/fonts/GoogleSansCode-LICENSE.txt'),
  (['Font Awesome Free'], 'assets/icons/FontAwesome-LICENSE.txt'),
  (['Flag icons'], 'assets/flags/LICENSE'),
];

final _rule = RegExp(r'^={78}$', multiLine: true);
final _divider = RegExp(r'^-{78}$', multiLine: true);

List<LicenseEntry> parseRustNotices(String text) {
  final entries = <LicenseEntry>[];
  for (final block in text.split(_rule).skip(1)) {
    final parts = block.split(_divider);
    if (parts.length < 2) continue;
    final crates = parts.first.trim().split('\n').map((line) => line.split(' ').first).where((name) => name.isNotEmpty).toSet().toList();
    final body = parts.sublist(1).join('-' * 78).trim();
    if (crates.isNotEmpty && body.isNotEmpty) entries.add(LicenseEntryWithLineBreaks(crates, body));
  }
  return entries;
}

Stream<LicenseEntry> _bundledLicenses() async* {
  for (final (packages, asset) in _bundledNotices) {
    yield LicenseEntryWithLineBreaks(packages, await rootBundle.loadString(asset));
  }
  yield* Stream.fromIterable(parseRustNotices(await rootBundle.loadString('assets/licenses/rust-crates.txt')));
  if (Platform.isWindows) yield const LicenseEntryWithLineBreaks(['Microsoft Visual C++ runtime'], visualCppRuntimeNotice);
}

bool _registered = false;

void registerBundledLicenses() {
  if (_registered) return;
  _registered = true;
  LicenseRegistry.addLicense(_bundledLicenses);
}
