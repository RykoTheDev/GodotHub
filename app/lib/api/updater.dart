import 'dart:io';

import '../src/rust/api/updater.dart' as rust;
import '../window/app_window.dart';

const appBuildVersion = String.fromEnvironment('APP_VERSION');

class AppUpdate {
  const AppUpdate({required this.version, this.body, required this.downloadAndInstall});

  final String version;
  final String? body;
  final Future<void> Function(void Function(double progress) onProgress, {String? githubToken}) downloadAndInstall;
}

abstract final class UpdaterApi {
  static void applyBuildVersion() {
    if (appBuildVersion.isNotEmpty) rust.setAppVersion(version: appBuildVersion);
  }

  static Future<AppUpdate?> check() async {
    final info = await rust.checkForUpdate();
    if (info == null) return null;
    return AppUpdate(
      version: info.version,
      body: info.notes,
      downloadAndInstall: (onProgress, {githubToken}) => _install(info, onProgress, githubToken),
    );
  }

  static Future<bool> isUpdateAvailable() async {
    if (appBuildVersion.isEmpty) return false;
    return await rust.checkForUpdate() != null;
  }

  static Future<void> _install(rust.UpdateInfo info, void Function(double progress) onProgress, String? githubToken) async {
    await for (final progress in rust.downloadAndInstallUpdate(update: info, githubToken: githubToken)) {
      final total = progress.total;
      if (total != null && total > BigInt.zero) onProgress(progress.downloaded.toDouble() / total.toDouble());
    }
    onProgress(1);
    final window = AppWindow.maybeInstance;
    if (window == null) return;
    if (Platform.isWindows) {
      await window.quit();
    } else {
      await window.relaunch();
    }
  }
}
