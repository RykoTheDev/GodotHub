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
    expect(update.downloadUrl, 'https://example.com/setup.exe');
    expect(update.package, 'windows-x86_64-nsis');
    final progress = <(int, int?)>[];
    await update.downloadAndInstall((p) => progress.add((p.downloaded, p.total)), githubToken: 'ghp_x');
    expect(progress, [(0, 100), (50, 100), (50, 100)]);
    expect(token, 'ghp_x');
  });

  test('no update and unversioned builds skip the background check', () async {
    installFakeRust().on('crateApiUpdaterCheckForUpdate', () async => null);
    expect(await UpdaterApi.check(), isNull);
    expect(await UpdaterApi.isUpdateAvailable(), isFalse);
  });

  test('the download source comes from the release URL', () {
    final source = updateSourceFrom('https://github.com/RykoTheDev/godothub/releases/download/flutter-v0.2.0/GodotHub-Beta-0.2.0-windows-x64-setup.exe');
    expect(source.host, 'github.com');
    expect(source.file, 'GodotHub-Beta-0.2.0-windows-x64-setup.exe');
    expect(source.releaseUrl, 'https://github.com/RykoTheDev/godothub/releases/tag/flutter-v0.2.0');
    final other = updateSourceFrom('https://cdn.example.com/files/GodotHub%20Setup.exe');
    expect(other.host, 'cdn.example.com');
    expect(other.file, 'GodotHub Setup.exe');
    expect(other.releaseUrl, isNull);
    expect(updateSourceFrom(null).host, isNull);
    expect(updateSourceFrom('not a url').host, isNull);
  });

  test('speed is averaged over recent samples and gives the time left', () {
    final meter = DownloadSpeedMeter();
    expect(meter.sample(0, 1000, Duration.zero).speed, isNull);
    final half = meter.sample(500, 1000, const Duration(seconds: 1));
    expect(half.speed, 500);
    expect(half.eta, const Duration(seconds: 1));
    meter.sample(600, 1000, const Duration(seconds: 2));
    meter.sample(700, 1000, const Duration(seconds: 3));
    final later = meter.sample(800, 1000, const Duration(seconds: 5));
    expect(later.speed, closeTo(66.67, 0.01));
    expect(later.eta, const Duration(seconds: 3));
    expect(DownloadSpeedMeter().sample(10, null, Duration.zero).eta, isNull);
  });
}
