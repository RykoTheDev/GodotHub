import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/design/design.dart';

Map<String, dynamic> _load() {
  final file = File('test/fixtures/theme_tokens.json');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

Map<String, String> _presetJson(ThemePreset p) => {
      'id': p.id,
      'name': p.name,
      'mode': p.mode.name,
      'base': p.base,
      'surface': p.surface,
      'raised': p.raised,
      'overlay': p.overlay,
      'line': p.line,
      'outline': p.outline,
      'ink': p.ink,
      'muted': p.muted,
      'accent': p.accent,
      'accentDim': p.accentDim,
      'accentBright': p.accentBright,
      'mint': p.mint,
      'amber': p.amber,
      'danger': p.danger,
    };

double _px(String value) => double.parse(value.replaceAll('px', ''));

void main() {
  final fixtures = _load();

  test('defaults match colors.ts and theme-defaults.json', () {
    final d = fixtures['defaults'] as Map<String, dynamic>;
    expect(defaultAccent, d['accent']);
    expect(defaultBackground, d['background']);
    expect(defaultBackgroundLight, d['backgroundLight']);
    expect(defaultRaisedContrast, d['raisedContrast']);
    expect(radiusMdDefault, d['radiusMd']);
    final dark = customThemeDefaults(GhThemeMode.dark);
    final light = customThemeDefaults(GhThemeMode.light);
    expect({'accent_color': dark.accentColor, 'background_color': dark.backgroundColor}, d['customDark']);
    expect({'accent_color': light.accentColor, 'background_color': light.backgroundColor}, d['customLight']);
    final json = jsonDecode(File('../src-tauri/theme-defaults.json').readAsStringSync()) as Map<String, dynamic>;
    expect(defaultAccent, json['accent']);
    expect(defaultBackground, json['background']);
  });

  test('buildCustomPalette matches the TypeScript output for every case', () {
    final cases = fixtures['palettes'] as List<dynamic>;
    expect(cases, hasLength(greaterThan(600)));
    for (final raw in cases) {
      final c = raw as Map<String, dynamic>;
      final palette = buildCustomPalette(
        c['accent'] as String,
        c['background'] as String,
        mode: GhThemeMode.parse(c['mode'] as String),
        raisedContrast: c['raisedContrast'] as num?,
      );
      expect(_presetJson(palette), c['palette'], reason: '${c['accent']} ${c['background']} ${c['mode']} ${c['raisedContrast']}');
    }
  });

  test('GhTheme colors equal the derived palette after an accent or background change', () {
    final cases = (fixtures['palettes'] as List<dynamic>).cast<Map<String, dynamic>>();
    var theme = GhTheme.defaults();
    for (final c in cases.take(120)) {
      theme = GhTheme.fromSettings(
        accentColor: c['accent'] as String,
        backgroundColor: c['background'] as String,
        themeMode: c['mode'] as String,
        themePreset: 'custom',
        raisedContrast: (c['raisedContrast'] as num?) ?? 8,
        cornerRadius: theme.cornerRadius,
        uiDensity: theme.uiDensity,
        fontScale: theme.fontScale,
        projectIconOpacity: theme.projectIconOpacity,
        showScrollbars: true,
        platformBrightness: Brightness.dark,
      );
      final expected = Map<String, String>.from(c['palette'] as Map)..removeWhere((k, _) => const {'id', 'name', 'mode'}.contains(k));
      final vars = theme.toVars();
      expect(vars['--color-base'], colorToHex(colorFromHex(expected['base']!)));
      expect(vars['--color-accent'], colorToHex(colorFromHex(expected['accent']!)));
      expect(vars['--color-surface'], expected['surface']);
      expect(vars['--color-raised'], expected['raised']);
      expect(vars['--color-overlay'], expected['overlay']);
      expect(vars['--color-line'], expected['line']);
      expect(vars['--color-accent-dim'], expected['accentDim']);
      expect(vars['--color-accent-bright'], expected['accentBright']);
      expect(vars['--color-ink'], expected['ink']);
      expect(vars['--color-muted'], expected['muted']);
    }
  });

  test('theme presets are identical', () {
    final presets = (fixtures['presets'] as List<dynamic>).cast<Map<String, dynamic>>();
    expect(themePresets.map(_presetJson).toList(), presets);
    expect(lightThemePresets.length, 10);
    expect(darkThemePresets.length, 7);
    for (final p in themePresets) {
      final theme = GhTheme.fromSettings(
        accentColor: '#000000',
        backgroundColor: '#ffffff',
        themeMode: 'light',
        themePreset: p.id,
        raisedContrast: 40,
        cornerRadius: 7,
        uiDensity: 1,
        fontScale: 1,
        projectIconOpacity: 14,
        showScrollbars: true,
        platformBrightness: Brightness.light,
      );
      expect(theme.toVars(), p.toVars());
      expect(theme.mode, p.mode);
    }
  });

  test('radius vars match radiusVars() exactly', () {
    for (final raw in fixtures['radii'] as List<dynamic>) {
      final c = raw as Map<String, dynamic>;
      final md = (c['md'] as num?)?.toDouble();
      final vars = md == null ? radiusVars() : radiusVars(md);
      final expected = (c['vars'] as Map<String, dynamic>).map((k, v) => MapEntry(k, _px(v as String)));
      expect(vars, expected, reason: 'md=$md');
      if (md != null) {
        final t = GhTheme.defaults().copyWith(cornerRadius: md);
        expect(
          [t.radiusSm, t.radiusMd, t.radiusLg, t.radiusXl, t.radiusTag, t.radiusBtn, t.radiusDropdownBtn, t.radiusDropdown, t.radiusItem, t.radiusTile, t.radiusMenu, t.radiusCard, t.radiusModal],
          [for (final key in radiusScale.keys) expected[key]],
        );
      }
    }
  });

  test('tagColor reproduces the JS int32 and double hashing', () {
    for (final raw in fixtures['tags'] as List<dynamic>) {
      final c = raw as Map<String, dynamic>;
      expect(tagColor(c['tag'] as String), c['color'], reason: c['tag'] as String);
    }
  });

  test('isDarkColor matches', () {
    for (final raw in fixtures['isDark'] as List<dynamic>) {
      final c = raw as Map<String, dynamic>;
      expect(isDarkColor(c['hex'] as String), c['dark'], reason: c['hex'] as String);
    }
  });

  test('swatch, category and workspace lists match', () {
    final s = fixtures['swatches'] as Map<String, dynamic>;
    expect(accentPresetsDark, s['accentDark']);
    expect(accentPresetsLight, s['accentLight']);
    expect(bgPresetsDark, s['bgDark']);
    expect(bgPresetsLight, s['bgLight']);
    expect(categoryColors, s['category']);
    expect(workspaceColorPresets, s['workspace']);
    expect(workspaceIconKeys, s['workspaceIcons']);
    expect(workspaceIcon('missing'), GhIcons.briefcase);
  });

  test('density and font scale produce the CSS values', () {
    for (final raw in fixtures['density'] as List<dynamic>) {
      final c = raw as Map<String, dynamic>;
      final t = GhTheme.defaults().copyWith(uiDensity: (c['scale'] as num).toDouble());
      expect(t.spacingUnit, _px(c['spacing'] as String));
    }
    for (final raw in fixtures['fontScale'] as List<dynamic>) {
      final c = raw as Map<String, dynamic>;
      final t = GhTheme.defaults().copyWith(fontScale: (c['scale'] as num).toDouble());
      final percent = double.parse((c['fontSize'] as String).replaceAll('%', ''));
      expect(t.remPx, closeTo(16 * percent / 100, 1e-9));
    }
  });

  test('system mode follows the platform brightness', () {
    expect(resolveThemeMode('system', Brightness.light), GhThemeMode.light);
    expect(resolveThemeMode('system', Brightness.dark), GhThemeMode.dark);
    expect(resolveThemeMode('light', Brightness.dark), GhThemeMode.light);
    expect(resolveThemeMode('dark', Brightness.light), GhThemeMode.dark);
  });

  test('lerp keeps endpoints exact', () {
    final a = GhTheme.defaults();
    final b = GhTheme.fromPalette(themePreset('nord')!);
    expect(a.lerp(b, 0).toVars(), a.toVars());
    expect(a.lerp(b, 1).toVars(), b.toVars());
  });
}
