import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/api/updater.dart';
import 'package:godothub/modals/check_for_updates_modal.dart';
import 'package:godothub/src/rust/api/updater.dart' as rust;

import '../support/fake_rust.dart';

void main() {
  test('legacy emoji headings and plain headings both parse into sections', () {
    final legacy = jsonDecode(File('../.github/updater/legacy-latest.json').readAsStringSync()) as Map<String, Object?>;
    final old = parseReleaseNotes(legacy['notes']! as String);
    expect(old.sections, isNotEmpty);
    expect(old.sections.first.title, startsWith('🚀'));
    expect(old.sections.every((s) => s.items.isNotEmpty), isTrue);
    expect(old.sections.any((s) => s.title.startsWith("What's new")), isFalse);

    final current = parseReleaseNotes(
      "## What's new in v1.5.9\n\n### New\n\n- Cover style\n- Faster scans\n\n### Fixed\n\n* Crash on start\n\n### Known Issues\n\n- Tray on Wayland\n\n### Empty\n",
    );
    expect([for (final s in current.sections) s.title], ['New', 'Fixed', 'Known Issues']);
    expect(current.sections.first.items, ['Cover style', 'Faster scans']);
    expect(current.sections[1].items, ['Crash on start']);
    expect(current.sections.last.isKnownIssues, isTrue);
    expect(parseReleaseNotes('#### ⚠️ Known issues\n- one').sections.single.isKnownIssues, isTrue);
  });

  test('a found update reports progress and passes the token to core', () async {
    final rustApi = installFakeRust();
    const info = rust.UpdateInfo(
      version: '1.6.0',
      currentVersion: '1.5.9',
      notes: '### New\n- x',
      target: 'windows-x86_64-nsis',
      url: 'https://example.com/setup.exe',
      signature: 'sig',
      installer: 'nsis',
      portable: false,
      sendToken: false,
    );
    String? token;
    rustApi
      ..on('crateApiUpdaterCheckForUpdate', () async => info)
      ..on('crateApiUpdaterDownloadAndInstallUpdate', ({required rust.UpdateInfo update, String? githubToken}) {
        token = githubToken;
        return Stream.fromIterable([
          rust.UpdateProgress(downloaded: BigInt.zero, total: BigInt.from(100)),
          rust.UpdateProgress(downloaded: BigInt.from(50), total: BigInt.from(100)),
        ]);
      });
    final update = await UpdaterApi.check();
    expect(update!.version, '1.6.0');
    expect(update.body, '### New\n- x');
    final progress = <double>[];
    await update.downloadAndInstall(progress.add, githubToken: 'ghp_x');
    expect(progress, [0, 0.5, 1]);
    expect(token, 'ghp_x');
  });

  test('no update and unversioned builds skip the background check', () async {
    installFakeRust().on('crateApiUpdaterCheckForUpdate', () async => null);
    expect(await UpdaterApi.check(), isNull);
    expect(await UpdaterApi.isUpdateAvailable(), isFalse);
  });
}
