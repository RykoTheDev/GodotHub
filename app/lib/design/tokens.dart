import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'palette.dart';
import 'typography.dart';

const double defaultCornerRadius = 7;
const double defaultUiDensity = 1.05;
const double defaultFontScale = 1.0;
const double defaultProjectIconOpacity = 14;

@immutable
class GhTheme extends ThemeExtension<GhTheme> {
  const GhTheme({
    required this.mode,
    required this.presetId,
    required this.base,
    required this.surface,
    required this.raised,
    required this.overlay,
    required this.line,
    required this.outline,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.accentDim,
    required this.accentBright,
    required this.mint,
    required this.amber,
    required this.danger,
    this.cornerRadius = defaultCornerRadius,
    this.uiDensity = defaultUiDensity,
    this.fontScale = defaultFontScale,
    this.projectIconOpacity = defaultProjectIconOpacity,
    this.showScrollbars = true,
    this.languageCode,
  });

  factory GhTheme.fromPalette(
    ThemePreset palette, {
    double cornerRadius = defaultCornerRadius,
    double uiDensity = defaultUiDensity,
    double fontScale = defaultFontScale,
    double projectIconOpacity = defaultProjectIconOpacity,
    bool showScrollbars = true,
    String? languageCode,
  }) {
    return GhTheme(
      mode: palette.mode,
      presetId: palette.id,
      base: colorFromHex(palette.base),
      surface: colorFromHex(palette.surface),
      raised: colorFromHex(palette.raised),
      overlay: colorFromHex(palette.overlay),
      line: colorFromHex(palette.line),
      outline: colorFromHex(palette.outline),
      ink: colorFromHex(palette.ink),
      muted: colorFromHex(palette.muted),
      accent: colorFromHex(palette.accent),
      accentDim: colorFromHex(palette.accentDim),
      accentBright: colorFromHex(palette.accentBright),
      mint: colorFromHex(palette.mint),
      amber: colorFromHex(palette.amber),
      danger: colorFromHex(palette.danger),
      cornerRadius: cornerRadius,
      uiDensity: uiDensity,
      fontScale: fontScale,
      projectIconOpacity: projectIconOpacity,
      showScrollbars: showScrollbars,
      languageCode: languageCode,
    );
  }

  factory GhTheme.fromSettings({
    required String accentColor,
    required String backgroundColor,
    required String themeMode,
    required String themePreset,
    required num raisedContrast,
    required double cornerRadius,
    required double uiDensity,
    required double fontScale,
    required double projectIconOpacity,
    required bool showScrollbars,
    required Brightness platformBrightness,
    String? languageCode,
  }) {
    final palette = resolvePalette(
      accent: accentColor,
      background: backgroundColor,
      mode: resolveThemeMode(themeMode, platformBrightness),
      presetId: themePreset,
      raisedContrast: raisedContrast,
    );
    return GhTheme.fromPalette(
      palette,
      cornerRadius: cornerRadius,
      uiDensity: uiDensity,
      fontScale: fontScale,
      projectIconOpacity: projectIconOpacity,
      showScrollbars: showScrollbars,
      languageCode: languageCode,
    );
  }

  factory GhTheme.defaults() => GhTheme.fromPalette(buildCustomPalette(defaultAccent, defaultBackground));

  final GhThemeMode mode;
  final String presetId;
  final Color base;
  final Color surface;
  final Color raised;
  final Color overlay;
  final Color line;
  final Color outline;
  final Color ink;
  final Color muted;
  final Color accent;
  final Color accentDim;
  final Color accentBright;
  final Color mint;
  final Color amber;
  final Color danger;
  final double cornerRadius;
  final double uiDensity;
  final double fontScale;
  final double projectIconOpacity;
  final bool showScrollbars;
  final String? languageCode;

  static GhTheme of(BuildContext context) => Theme.of(context).extension<GhTheme>() ?? GhTheme.defaults();

  bool get isLight => mode == GhThemeMode.light;

  double get radiusSm => cornerRadius * 0.8;
  double get radiusMd => cornerRadius * 1.0;
  double get radiusLg => cornerRadius * 1.4;
  double get radiusXl => cornerRadius * 2.0;
  double get radiusTag => cornerRadius * 1.0;
  double get radiusBtn => cornerRadius * 1.6;
  double get radiusDropdownBtn => cornerRadius * 1.3;
  double get radiusDropdown => cornerRadius * 1.3;
  double get radiusItem => cornerRadius * 2.2;
  double get radiusTile => cornerRadius * 1.6;
  double get radiusMenu => cornerRadius * 2.4;
  double get radiusCard => cornerRadius * 2.4;
  double get radiusModal => cornerRadius * 3.0;

  double get spacingUnit => 4 * uiDensity;
  double space(num n) => n * spacingUnit;

  double get remPx => 16 * fontScale;
  double rem(num n) => n * remPx;

  double get projectIconAlpha => projectIconOpacity.clamp(0, 100) / 100;

  Color get placeholder => muted.withValues(alpha: 0.85);
  Color get caret => accentBright;

  TextStyle text({
    GhTextSize size = GhTextSize.sm,
    FontWeight weight = GhWeight.normal,
    bool mono = false,
    Color? color,
    double? lineHeight,
    double? letterSpacingEm,
  }) {
    return ghTextStyle(
      remPx: remPx,
      size: size,
      weight: weight,
      mono: mono,
      color: color ?? ink,
      lineHeight: lineHeight,
      letterSpacingEm: letterSpacingEm,
      languageCode: languageCode,
    );
  }

  Map<String, String> toVars() {
    return {
      '--color-base': colorToHex(base),
      '--color-surface': colorToHex(surface),
      '--color-raised': colorToHex(raised),
      '--color-overlay': colorToHex(overlay),
      '--color-line': colorToHex(line),
      '--color-outline': colorToHex(outline),
      '--color-ink': colorToHex(ink),
      '--color-muted': colorToHex(muted),
      '--color-accent': colorToHex(accent),
      '--color-accent-dim': colorToHex(accentDim),
      '--color-accent-bright': colorToHex(accentBright),
      '--color-mint': colorToHex(mint),
      '--color-amber': colorToHex(amber),
      '--color-danger': colorToHex(danger),
    };
  }

  @override
  GhTheme copyWith({
    GhThemeMode? mode,
    String? presetId,
    Color? base,
    Color? surface,
    Color? raised,
    Color? overlay,
    Color? line,
    Color? outline,
    Color? ink,
    Color? muted,
    Color? accent,
    Color? accentDim,
    Color? accentBright,
    Color? mint,
    Color? amber,
    Color? danger,
    double? cornerRadius,
    double? uiDensity,
    double? fontScale,
    double? projectIconOpacity,
    bool? showScrollbars,
    String? languageCode,
  }) {
    return GhTheme(
      mode: mode ?? this.mode,
      presetId: presetId ?? this.presetId,
      base: base ?? this.base,
      surface: surface ?? this.surface,
      raised: raised ?? this.raised,
      overlay: overlay ?? this.overlay,
      line: line ?? this.line,
      outline: outline ?? this.outline,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      accent: accent ?? this.accent,
      accentDim: accentDim ?? this.accentDim,
      accentBright: accentBright ?? this.accentBright,
      mint: mint ?? this.mint,
      amber: amber ?? this.amber,
      danger: danger ?? this.danger,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      uiDensity: uiDensity ?? this.uiDensity,
      fontScale: fontScale ?? this.fontScale,
      projectIconOpacity: projectIconOpacity ?? this.projectIconOpacity,
      showScrollbars: showScrollbars ?? this.showScrollbars,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  @override
  GhTheme lerp(covariant GhTheme? other, double t) {
    if (other == null) {
      return this;
    }
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    final pick = t < 0.5 ? this : other;
    return GhTheme(
      mode: pick.mode,
      presetId: pick.presetId,
      base: c(base, other.base),
      surface: c(surface, other.surface),
      raised: c(raised, other.raised),
      overlay: c(overlay, other.overlay),
      line: c(line, other.line),
      outline: c(outline, other.outline),
      ink: c(ink, other.ink),
      muted: c(muted, other.muted),
      accent: c(accent, other.accent),
      accentDim: c(accentDim, other.accentDim),
      accentBright: c(accentBright, other.accentBright),
      mint: c(mint, other.mint),
      amber: c(amber, other.amber),
      danger: c(danger, other.danger),
      cornerRadius: other.cornerRadius,
      uiDensity: other.uiDensity,
      fontScale: other.fontScale,
      projectIconOpacity: lerpDouble(projectIconOpacity, other.projectIconOpacity, t)!,
      showScrollbars: other.showScrollbars,
      languageCode: other.languageCode,
    );
  }

  ThemeData toThemeData() {
    final brightness = isLight ? Brightness.light : Brightness.dark;
    final body = text(size: GhTextSize.base);
    final scheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: Colors.white,
      secondary: accentBright,
      onSecondary: Colors.white,
      error: danger,
      onError: Colors.white,
      surface: base,
      onSurface: ink,
      onSurfaceVariant: muted,
      surfaceContainerLowest: base,
      surfaceContainerLow: surface,
      surfaceContainer: overlay,
      surfaceContainerHigh: raised,
      surfaceContainerHighest: raised,
      outline: outline,
      outlineVariant: line,
      shadow: Colors.black,
      surfaceTint: Colors.transparent,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: base,
      canvasColor: base,
      fontFamily: GhFonts.body,
      fontFamilyFallback: GhFonts.bodyFallback,
      textTheme: Typography.material2021().englishLike.apply(
        fontFamily: GhFonts.body,
        fontFamilyFallback: GhFonts.bodyFallback,
        bodyColor: ink,
        displayColor: ink,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: accent.withValues(alpha: 0.7),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accentBright,
        selectionColor: accent.withValues(alpha: 0.35),
        selectionHandleColor: accent,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStatePropertyAll(showScrollbars ? 4 : 0),
        radius: const Radius.circular(999),
        crossAxisMargin: 2,
        mainAxisMargin: 2,
        thumbVisibility: const WidgetStatePropertyAll(false),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (!showScrollbars) {
            return Colors.transparent;
          }
          if (states.contains(WidgetState.dragged)) {
            return accent;
          }
          if (states.contains(WidgetState.hovered)) {
            return accentDim;
          }
          return line;
        }),
        trackColor: const WidgetStatePropertyAll(Colors.transparent),
        trackBorderColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      tooltipTheme: TooltipThemeData(
        textStyle: text(size: GhTextSize.xs, color: ink),
        decoration: BoxDecoration(
          color: overlay,
          borderRadius: BorderRadius.circular(radiusMd),
          border: Border.all(color: line),
        ),
        waitDuration: const Duration(milliseconds: 500),
      ),
      iconTheme: IconThemeData(color: ink, size: body.fontSize),
      dividerColor: line,
      extensions: [this],
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GhTheme &&
        other.mode == mode &&
        other.presetId == presetId &&
        other.base == base &&
        other.surface == surface &&
        other.raised == raised &&
        other.overlay == overlay &&
        other.line == line &&
        other.outline == outline &&
        other.ink == ink &&
        other.muted == muted &&
        other.accent == accent &&
        other.accentDim == accentDim &&
        other.accentBright == accentBright &&
        other.mint == mint &&
        other.amber == amber &&
        other.danger == danger &&
        other.cornerRadius == cornerRadius &&
        other.uiDensity == uiDensity &&
        other.fontScale == fontScale &&
        other.projectIconOpacity == projectIconOpacity &&
        other.showScrollbars == showScrollbars &&
        other.languageCode == languageCode;
  }

  @override
  int get hashCode => Object.hashAll([
    mode,
    presetId,
    base,
    surface,
    raised,
    overlay,
    line,
    outline,
    ink,
    muted,
    accent,
    accentDim,
    accentBright,
    mint,
    amber,
    danger,
    cornerRadius,
    uiDensity,
    fontScale,
    projectIconOpacity,
    showScrollbars,
    languageCode,
  ]);
}
