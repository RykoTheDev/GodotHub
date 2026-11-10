import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/design/design.dart';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(Future.value(ByteData.sublistView(File(file).readAsBytesSync())));
  }
  await loader.load();
}

Size _measure(TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: 'The quick brown fox jumps over the lazy dog 0123', style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.size;
}

const _browser = <String, List<double>>{
  '4xs': [214.08, 13.5],
  '3xs': [237.86, 15],
  '2xs': [261.64, 16.5],
  'xs': [285.42, 16],
  'sm': [333, 20],
  'base': [380.56, 24],
  'lg': [428.14, 28],
  'xl': [475.7, 28],
  '2xl': [570.84, 32],
  '3xl': [713.56, 36],
  '4xl': [856.27, 40],
  'w500': [383.81, 24],
  'w600': [387.06, 24],
  'w700': [390.27, 24],
  'mono400': [403.2, 20],
  'mono500': [403.2, 20],
};

void main() {
  setUpAll(() async {
    await _loadFont('Inter', ['assets/fonts/inter-latin.ttf']);
    await _loadFont('GoogleSansCode', ['assets/fonts/gsc-latin-400.ttf', 'assets/fonts/gsc-latin-500.ttf']);
  });

  test('text metrics stay close to Chromium for the same fonts', () {
    final theme = GhTheme.defaults();
    final sizes = {
      '4xs': GhTextSize.x4s,
      '3xs': GhTextSize.x3s,
      '2xs': GhTextSize.x2s,
      'xs': GhTextSize.xs,
      'sm': GhTextSize.sm,
      'base': GhTextSize.base,
      'lg': GhTextSize.lg,
      'xl': GhTextSize.xl,
      '2xl': GhTextSize.x2l,
      '3xl': GhTextSize.x3l,
      '4xl': GhTextSize.x4l,
    };
    final measured = <String, Size>{
      for (final e in sizes.entries) e.key: _measure(theme.text(size: e.value)),
      'w500': _measure(theme.text(size: GhTextSize.base, weight: GhWeight.medium)),
      'w600': _measure(theme.text(size: GhTextSize.base, weight: GhWeight.semibold)),
      'w700': _measure(theme.text(size: GhTextSize.base, weight: GhWeight.bold)),
      'mono400': _measure(theme.text(size: GhTextSize.sm, mono: true)),
      'mono500': _measure(theme.text(size: GhTextSize.sm, mono: true, weight: GhWeight.medium)),
    };
    for (final entry in _browser.entries) {
      final size = measured[entry.key]!;
      final width = entry.value[0];
      expect(size.width, closeTo(width, 0.05), reason: '${entry.key} width ${size.width} vs $width');
      expect(size.height, closeTo(entry.value[1], 0.51), reason: '${entry.key} height ${size.height} vs ${entry.value[1]}');
    }
  });
}
