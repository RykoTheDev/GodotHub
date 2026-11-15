import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/design/design.dart';

double _channel(double c) => c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) => 0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

double contrast(String a, String b) {
  final la = _luminance(colorFromHex(a));
  final lb = _luminance(colorFromHex(b));
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final palette in [highContrastDark, highContrastLight]) {
    test('${palette.name} meets WCAG contrast', () {
      expect(contrast(palette.ink, palette.base), greaterThanOrEqualTo(7));
      expect(contrast(palette.muted, palette.base), greaterThanOrEqualTo(7));
      expect(contrast(palette.ink, palette.raised), greaterThanOrEqualTo(7));
      expect(contrast('#ffffff', palette.accent), greaterThanOrEqualTo(4.5), reason: 'white text on primary buttons');
      expect(contrast('#ffffff', palette.danger), greaterThanOrEqualTo(4.5), reason: 'white text on danger buttons');
      expect(contrast(palette.accentBright, palette.base), greaterThanOrEqualTo(4.5));
      expect(contrast(palette.accentDim, palette.base), greaterThanOrEqualTo(3), reason: 'focus outlines');
      for (final border in [palette.outline, palette.line]) {
        expect(contrast(border, palette.base), greaterThanOrEqualTo(3));
      }
      for (final status in [palette.mint, palette.amber, palette.danger]) {
        expect(contrast(status, palette.base), greaterThanOrEqualTo(3));
      }
    });
  }

  test('high contrast replaces the chosen theme and follows light or dark', () {
    GhTheme build({required bool highContrast, String mode = 'dark'}) => GhTheme.fromSettings(
      accentColor: '#ff00aa',
      backgroundColor: '#336699',
      themeMode: mode,
      themePreset: 'custom',
      raisedContrast: 8,
      cornerRadius: 10,
      uiDensity: 1,
      fontScale: 1,
      projectIconOpacity: 1,
      showScrollbars: true,
      platformBrightness: Brightness.dark,
      highContrast: highContrast,
    );
    expect(build(highContrast: false).base, colorFromHex('#336699'));
    expect(build(highContrast: true).presetId, highContrastDark.id);
    expect(build(highContrast: true).base, colorFromHex('#000000'));
    expect(build(highContrast: true, mode: 'light').presetId, highContrastLight.id);
  });

  const windowsThemes = {
    'Aquatic': (window: '#202020', text: '#ffffff', highlight: '#8ee3f0', button: '#202020', gray: '#a6a6a6', link: '#75e9fc', dark: true),
    'Desert': (window: '#fffaef', text: '#3d3d3d', highlight: '#903909', button: '#fffaef', gray: '#676767', link: '#1c5e75', dark: false),
    'Dusk': (window: '#2d3236', text: '#b6f6f0', highlight: '#a1bfde', button: '#2d3236', gray: '#a6a6a6', link: '#70ebde', dark: true),
    'Night sky': (
      window: '#000000',
      text: '#ffffff',
      highlight: '#d6b4fd',
      button: '#000000',
      gray: '#a6a6a6',
      link: '#8080ff',
      dark: true,
    ),
  };

  for (final MapEntry(key: name, value: t) in windowsThemes.entries) {
    test('the $name contrast theme gives a readable palette in its own colors', () {
      final p = highContrastFromSystem(
        window: t.window,
        windowText: t.text,
        highlight: t.highlight,
        buttonFace: t.button,
        grayText: t.gray,
        hotlight: t.link,
      );
      expect(p.mode, t.dark ? GhThemeMode.dark : GhThemeMode.light);
      expect(p.base, t.window);
      expect(p.ink, t.text);
      expect(contrastRatio(p.ink, p.base), greaterThanOrEqualTo(7));
      expect(contrastRatio('#ffffff', p.accent), greaterThanOrEqualTo(4.5), reason: 'white text on primary buttons');
      expect(contrastRatio('#ffffff', p.danger), greaterThanOrEqualTo(4.5));
      for (final color in [p.accentBright, p.accentDim, p.line, p.outline, p.mint, p.amber]) {
        expect(contrastRatio(color, p.base), greaterThanOrEqualTo(3), reason: color);
      }
      expect(
        contrastRatio(p.danger, p.base),
        greaterThanOrEqualTo(2.85),
        reason: 'the lightest red that still carries white text; 2.87 is the most Dusk allows',
      );
    });
  }

  test('a highlight that already suits white text is kept as the accent', () {
    expect(darkenForWhiteText('#903909'), '#903909');
    expect(contrastRatio('#ffffff', darkenForWhiteText('#8ee3f0')), greaterThanOrEqualTo(4.5));
  });

  test('Windows system colors can be read', () {
    final colors = readSystemContrastColors();
    if (!Platform.isWindows) {
      expect(colors, isNull);
      return;
    }
    final hex = RegExp(r'^#[0-9a-f]{6}$');
    for (final value in [
      colors!.window,
      colors.windowText,
      colors.highlight,
      colors.highlightText,
      colors.buttonFace,
      colors.grayText,
      colors.hotlight,
    ]) {
      expect(value, matches(hex));
    }
    expect(colors.window, isNot(colors.windowText));
  });
}
