import 'dart:io';

import 'package:flutter/foundation.dart';

const _appImageMarkers = ['APPIMAGE', 'APPDIR', 'ARGV0', 'OWD'];
const _appImagePathLists = [
  'LD_LIBRARY_PATH',
  'LD_PRELOAD',
  'PATH',
  'XDG_DATA_DIRS',
  'XDG_CONFIG_DIRS',
  'GIO_EXTRA_MODULES',
  'GIO_MODULE_DIR',
  'GDK_PIXBUF_MODULEDIR',
  'GDK_PIXBUF_MODULE_FILE',
  'GTK_PATH',
  'GTK_EXE_PREFIX',
  'GTK_DATA_PREFIX',
  'GTK_IM_MODULE_FILE',
  'GSETTINGS_SCHEMA_DIR',
  'GST_PLUGIN_PATH',
  'GST_PLUGIN_SYSTEM_PATH',
  'GST_PLUGIN_SYSTEM_PATH_1_0',
  'GST_PLUGIN_SCANNER',
  'QT_PLUGIN_PATH',
  'PYTHONHOME',
  'PYTHONPATH',
  'PERLLIB',
];

Map<String, String> hostEnvironment(Map<String, String> environment) {
  final bundle = environment['APPDIR'];
  if (bundle == null || bundle.isEmpty) return Map.of(environment);
  final out = <String, String>{};
  for (final MapEntry(:key, :value) in environment.entries) {
    if (_appImageMarkers.contains(key)) continue;
    if (_appImagePathLists.contains(key)) {
      final kept = value.split(':').where((part) => part.isNotEmpty && !part.startsWith(bundle)).join(':');
      if (kept.isNotEmpty) {
        out[key] = kept;
      } else if (key == 'PATH') {
        out[key] = value;
      }
      continue;
    }
    out[key] = value;
  }
  return out;
}

abstract final class OpenerApi {
  @visibleForTesting
  static Future<void> Function(String url)? debugOpenUrl;

  static Future<void> openUrl(String url) async {
    final override = debugOpenUrl;
    if (override != null) return override(url);
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http') || uri.host.isEmpty) {
      throw ArgumentError.value(url, 'url', 'Only http and https links can be opened');
    }
    final target = uri.toString();
    final ProcessResult result;
    if (Platform.isWindows) {
      result = await Process.run('rundll32', ['url.dll,FileProtocolHandler', target]);
    } else if (Platform.isMacOS) {
      result = await Process.run('open', [target]);
    } else {
      result = await Process.run('xdg-open', [target], environment: hostEnvironment(Platform.environment), includeParentEnvironment: false);
    }
    if (result.exitCode != 0) {
      throw ProcessException('open', [target], '${result.stderr}', result.exitCode);
    }
  }
}
