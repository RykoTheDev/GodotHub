import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';

import 'plural_rules.dart';
import 'strings.g.dart';

export 'strings.g.dart';

final _interpolation = RegExp(r'\{\{\s*([^}]+?)\s*\}\}');

extension GhInterpolation on String {
  String args(Map<String, Object?> values) {
    if (values.isEmpty || !contains('{{')) {
      return this;
    }
    return replaceAllMapped(_interpolation, (m) {
      final name = m[1]!;
      if (!values.containsKey(name) || values[name] == null) {
        return m[0]!;
      }
      return _format(values[name]);
    });
  }
}

String _format(Object? value) {
  if (value is double && value == value.truncateToDouble() && value.isFinite) {
    return value.toInt().toString();
  }
  return '$value';
}

const _reserved = {
  'abstract', 'as', 'assert', 'async', 'await', 'base', 'break', 'case', 'catch', 'class', 'const', 'continue',
  'covariant', 'default', 'deferred', 'do', 'dynamic', 'else', 'enum', 'export', 'extends', 'extension', 'external',
  'factory', 'false', 'final', 'finally', 'for', 'get', 'hide', 'if', 'implements', 'in', 'interface', 'is', 'late',
  'library', 'mixin', 'new', 'null', 'of', 'on', 'operator', 'part', 'required', 'rethrow', 'return', 'sealed', 'set',
  'show', 'static', 'super', 'switch', 'sync', 'this', 'throw', 'true', 'try', 'type', 'typedef', 'var', 'void', 'when',
  'while', 'with', 'yield',
};

String _sanitized(String segment) {
  if (RegExp(r'^\d').hasMatch(segment) || _reserved.contains(segment)) {
    return 'k${segment[0].toUpperCase()}${segment.substring(1)}';
  }
  return segment;
}

Object? _flat(Translations translations, String ns, String path) {
  final direct = translations['$ns.$path'];
  if (direct != null) {
    return direct;
  }
  final sanitized = path.split('.').map(_sanitized).join('.');
  return sanitized == path ? null : translations['$ns.$sanitized'];
}

String ghTr(
  String key, {
  num? count,
  Map<String, Object?> args = const {},
  Translations? translations,
  String defaultNamespace = 'common',
}) {
  final source = translations ?? t;
  final colon = key.indexOf(':');
  final ns = colon < 0 ? defaultNamespace : key.substring(0, colon);
  final path = colon < 0 ? key : key.substring(colon + 1);
  final values = count == null ? args : {...args, 'count': count};
  for (final namespace in {ns, 'common'}) {
    if (count != null) {
      final plural = _flat(source, namespace, '${path}_plural') ?? _flat(source, namespace, path);
      if (plural is String Function({required num count})) {
        return plural(count: count).args(values);
      }
    }
    final value = _flat(source, namespace, path);
    if (value is String) {
      return value.args(values);
    }
  }
  return path;
}

void registerI18nextPluralRules() {
  for (final locale in AppLocale.values) {
    LocaleSettings.instance.setPluralResolverSync(
      locale: locale,
      cardinalResolver: i18nextCardinal(locale.languageCode),
      ordinalResolver: i18nextCardinal(locale.languageCode),
    );
  }
}

typedef GhTransTag = InlineSpan Function(String text, List<InlineSpan> children);

final _tag = RegExp(r'<(\w+)>(.*?)</\1>', dotAll: true);

List<InlineSpan> ghTrans(String text, {Map<String, GhTransTag> tags = const {}}) {
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final match in _tag.allMatches(text)) {
    if (match.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, match.start)));
    }
    final inner = match[2]!;
    final children = ghTrans(inner, tags: tags);
    final builder = tags[match[1]!];
    spans.add(builder == null ? TextSpan(children: children) : builder(inner.replaceAll(RegExp(r'<[^>]+>'), ''), children));
    cursor = match.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor)));
  }
  return spans;
}

const _rtlLanguages = {'ar', 'he', 'iw', 'fa', 'ur', 'ps', 'ug', 'yi', 'ji', 'dv', 'ckb', 'sd'};

TextDirection ghTextDirectionOf(String language) =>
    _rtlLanguages.contains(language.split(RegExp('[-_]')).first.toLowerCase()) ? TextDirection.rtl : TextDirection.ltr;

TextDirection ghLayoutDirection(String language, {required bool rtlLayout}) =>
    ghTextDirectionOf(language) == TextDirection.rtl && rtlLayout ? TextDirection.rtl : TextDirection.ltr;

AppLocale? ghAppLocaleFor(String language) {
  final normalized = language.replaceAll('_', '-').toLowerCase();
  for (final locale in AppLocale.values) {
    if (locale.languageTag.toLowerCase() == normalized) {
      return locale;
    }
  }
  return null;
}
