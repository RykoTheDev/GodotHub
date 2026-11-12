import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

enum GhTextSize {
  x4s(0.5625, null),
  x3s(0.625, null),
  x2s(0.6875, null),
  xs(0.75, 1 / 0.75),
  sm(0.875, 1.25 / 0.875),
  base(1, 1.5),
  lg(1.125, 1.75 / 1.125),
  xl(1.25, 1.75 / 1.25),
  x2l(1.5, 2 / 1.5),
  x3l(1.875, 2.25 / 1.875),
  x4l(2.25, 2.5 / 2.25),
  x5l(3, 1);

  const GhTextSize(this.rem, this.lineHeight);

  final double rem;
  final double? lineHeight;
}

abstract final class GhFonts {
  static const body = 'Inter';
  static const mono = 'GoogleSansCode';

  static const bodyFallback = ['InterLatinExt', 'InterCyrillic', 'InterCyrillicExt', 'InterGreek', 'InterGreekExt', 'InterVietnamese'];

  static const monoFallback = [
    'GoogleSansCodeLatinExt',
    'GoogleSansCodeVietnamese',
    'GoogleSansCodeSymbols',
    'GoogleSansCodeSymbols2',
    'GoogleSansCodeMath',
  ];

  static const _cjkJa = ['Yu Gothic UI', 'Hiragino Sans', 'Noto Sans CJK JP', 'Noto Sans JP', 'Meiryo'];
  static const _cjkJaMono = ['Noto Sans Mono CJK JP', 'MS Gothic', 'Osaka-Mono'];
  static const _cjkZh = ['Microsoft YaHei', 'PingFang SC', 'Noto Sans CJK SC', 'Noto Sans SC'];
  static const _cjkZhMono = ['Noto Sans Mono CJK SC', 'NSimSun'];

  static List<String> cjk(String? languageCode, {bool mono = false}) {
    return switch (languageCode) {
      'ja' => mono ? _cjkJaMono : _cjkJa,
      'zh' => mono ? _cjkZhMono : _cjkZh,
      _ => const [],
    };
  }
}

abstract final class GhWeight {
  static const normal = FontWeight.w400;
  static const medium = FontWeight.w500;
  static const semibold = FontWeight.w600;
  static const bold = FontWeight.w700;
}

const double defaultLineHeight = 1.5;

TextStyle ghTextStyle({
  required double remPx,
  GhTextSize size = GhTextSize.base,
  FontWeight weight = GhWeight.normal,
  bool mono = false,
  Color? color,
  double? lineHeight,
  double? letterSpacingEm,
  String? languageCode,
}) {
  final fontSize = size.rem * remPx;
  final monoWeight = weight.value >= 500 ? FontWeight.w500 : FontWeight.w400;
  return TextStyle(
    inherit: true,
    fontFamily: mono ? GhFonts.mono : GhFonts.body,
    fontFamilyFallback: [
      ...(mono ? GhFonts.monoFallback : GhFonts.bodyFallback),
      ...GhFonts.cjk(languageCode, mono: mono),
    ],
    fontSize: fontSize,
    fontWeight: mono ? monoWeight : weight,
    fontVariations: mono ? null : [FontVariation.weight(weight.value.toDouble())],
    height: lineHeight ?? size.lineHeight ?? defaultLineHeight,
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: letterSpacingEm == null ? null : letterSpacingEm * fontSize,
    color: color,
  );
}

void warmUpFonts({String? languageCode}) {
  const sample = 'Aa09 ĀăĞőŸ ЖжЯѣ ΩωΆἀ ạễỹ';
  for (final mono in [false, true]) {
    final weights = mono ? const [GhWeight.normal, GhWeight.medium] : const [GhWeight.normal, GhWeight.medium, GhWeight.semibold, GhWeight.bold];
    for (final weight in weights) {
      final style = ghTextStyle(remPx: 16, weight: weight, mono: mono, languageCode: languageCode);
      final builder = ui.ParagraphBuilder(style.getParagraphStyle())
        ..pushStyle(style.getTextStyle())
        ..addText(sample);
      builder.build()
        ..layout(const ui.ParagraphConstraints(width: 2000))
        ..dispose();
    }
  }
}
