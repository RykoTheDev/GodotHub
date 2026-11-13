import 'dart:io';

import '../src/rust/api/updater.dart' as rust;
import '../window/app_window.dart';

const appBuildVersion = String.fromEnvironment('APP_VERSION');
const updaterTestEndpoint = String.fromEnvironment('UPDATER_TEST_ENDPOINT');
const updaterTestPublicKey = String.fromEnvironment('UPDATER_TEST_PUBKEY');

class UpdateDownloadProgress {
  const UpdateDownloadProgress({required this.downloaded, this.total});

  final int downloaded;
  final int? total;
}

class AppUpdate {
  const AppUpdate({
    required this.version,
    this.body,
    this.date,
    this.downloadUrl,
    this.package,
    required this.download,
    required this.restart,
  });

  final String version;
  final String? body;
  final String? date;
  final String? downloadUrl;
  final String? package;
  final Future<void> Function(
    void Function(UpdateDownloadProgress progress) onProgress, {
    String? githubToken,
    void Function(String line)? onLog,
  })
  download;
  final Future<void> Function() restart;
}

class UpdateSource {
  const UpdateSource({this.host, this.file, this.releaseUrl});

  final String? host;
  final String? file;
  final String? releaseUrl;
}

final _releaseDownload = RegExp(r'^(/[^/]+/[^/]+)/releases/download/([^/]+)/');

UpdateSource updateSourceFrom(String? url) {
  final uri = url == null ? null : Uri.tryParse(url);
  if (uri == null || uri.host.isEmpty) return const UpdateSource();
  final file = uri.pathSegments.isEmpty ? null : Uri.decodeComponent(uri.pathSegments.last);
  final release = _releaseDownload.firstMatch(uri.path);
  return UpdateSource(
    host: uri.host,
    file: file == null || file.isEmpty ? null : file,
    releaseUrl: release != null && uri.host == 'github.com' ? 'https://github.com${release[1]}/releases/tag/${release[2]}' : null,
  );
}

class DownloadSpeedMeter {
  final _samples = <(Duration, int)>[];

  ({double? speed, Duration? eta}) sample(int downloaded, int? total, Duration now) {
    _samples.add((now, downloaded));
    while (_samples.length > 2 && now - _samples.first.$1 > const Duration(seconds: 3)) {
      _samples.removeAt(0);
    }
    final (start, startBytes) = _samples.first;
    final seconds = (now - start).inMicroseconds / 1e6;
    final speed = seconds >= 0.25 ? (downloaded - startBytes) / seconds : null;
    final eta = speed != null && speed > 0 && total != null
        ? Duration(milliseconds: (((total - downloaded) / speed) * 1000).clamp(0, double.maxFinite).round())
        : null;
    return (speed: speed, eta: eta);
  }
}

abstract final class UpdaterApi {
  static void applyBuildVersion() {
    if (appBuildVersion.isNotEmpty) rust.setAppVersion(version: appBuildVersion);
    if (updaterTestEndpoint.isEmpty && updaterTestPublicKey.isEmpty) return;
    try {
      rust.setUpdaterTestOverrides(endpoint: updaterTestEndpoint, publicKey: updaterTestPublicKey);
      stderr.writeln('Updater test mode: $updaterTestEndpoint');
    } catch (error) {
      stderr.writeln('Updater test overrides rejected: $error');
    }
  }

  static Future<void> confirmLaunch() async {
    try {
      await rust.confirmLaunch();
    } catch (_) {}
  }

  static Future<AppUpdate?> check() async {
    final info = await rust.checkForUpdate();
    if (info == null) return null;
    return AppUpdate(
      version: info.version,
      body: info.notes,
      date: info.pubDate,
      downloadUrl: info.url,
      package: info.target,
      download: (onProgress, {githubToken, onLog}) => _download(info, onProgress, githubToken, onLog),
      restart: _restart,
    );
  }

  static Future<bool> isUpdateAvailable() async {
    if (appBuildVersion.isEmpty) return false;
    return await rust.checkForUpdate() != null;
  }

  static Future<void> _download(
    rust.UpdateInfo info,
    void Function(UpdateDownloadProgress progress) onProgress,
    String? githubToken,
    void Function(String line)? onLog,
  ) async {
    var last = const UpdateDownloadProgress(downloaded: 0);
    await for (final progress in rust.downloadUpdate(update: info, githubToken: githubToken)) {
      final line = progress.log;
      if (line != null) {
        onLog?.call(line);
        continue;
      }
      last = UpdateDownloadProgress(downloaded: progress.downloaded.toInt(), total: progress.total?.toInt());
      onProgress(last);
    }
    onProgress(UpdateDownloadProgress(downloaded: last.downloaded, total: last.total ?? last.downloaded));
  }

  static Future<void> _restart() async {
    final installerRelaunches = await rust.restartToUpdate();
    final window = AppWindow.maybeInstance;
    if (window == null) return;
    if (installerRelaunches) {
      await window.quit();
    } else {
      await window.relaunch();
    }
  }
}
