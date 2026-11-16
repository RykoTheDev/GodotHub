import 'dart:convert';
import 'dart:io';

const sourceLocale = 'en-US';

String get repoRoot => File.fromUri(Platform.script).parent.parent.parent.parent.path;

String get localesPath => '$repoRoot/src/i18n/locales';

bool get useColor => stdout.hasTerminal && stdout.supportsAnsiEscapes;

String paint(String text, String codes) => useColor ? '$codes$text\x1b[0m' : text;

const bold = '\x1b[1m';
const dim = '\x1b[2m';
const red = '\x1b[31m';
const green = '\x1b[32m';
const yellow = '\x1b[33m';
const cyan = '\x1b[36m';
const gray = '\x1b[90m';

List<String> localeNames() => Directory(localesPath)
    .listSync()
    .whereType<Directory>()
    .map((d) => d.uri.pathSegments.where((s) => s.isNotEmpty).last)
    .toList()
  ..sort();

List<String> namespaceNames([String locale = sourceLocale]) => Directory('$localesPath/$locale')
    .listSync()
    .whereType<File>()
    .where((f) => f.path.endsWith('.json'))
    .map((f) => f.uri.pathSegments.last.replaceAll('.json', ''))
    .toList()
  ..sort();

Map<String, Object?>? readLocaleFile(String locale, String namespace) {
  final file = File('$localesPath/$locale/$namespace.json');
  if (!file.existsSync() || file.lengthSync() == 0) return null;
  try {
    return (jsonDecode(file.readAsStringSync()) as Map).cast<String, Object?>();
  } catch (_) {
    return null;
  }
}

Map<String, Object?> flatten(Map<String, Object?> data, [String prefix = '']) {
  final out = <String, Object?>{};
  for (final entry in data.entries) {
    final path = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    final value = entry.value;
    if (value is Map) {
      out.addAll(flatten(value.cast<String, Object?>(), path));
    } else if (value is List) {
      out.addAll(flatten({for (var i = 0; i < value.length; i++) '$i': value[i]}, path));
    } else {
      out[path] = value;
    }
  }
  return out;
}
