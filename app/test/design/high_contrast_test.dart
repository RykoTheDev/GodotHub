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
}
