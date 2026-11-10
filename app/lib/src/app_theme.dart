import 'dart:ui';

import '../design/design.dart';
import '../motion/motion.dart';
import '../ui/core/ui_settings.dart';
import 'rust/api/types.dart';

GhTheme ghThemeFromSettings(AppSettings settings, Brightness platformBrightness) {
  return GhTheme.fromSettings(
    accentColor: settings.accentColor,
    backgroundColor: settings.backgroundColor,
    themeMode: settings.themeMode,
    themePreset: settings.themePreset,
    raisedContrast: settings.raisedContrast,
    cornerRadius: settings.cornerRadius,
    uiDensity: settings.uiDensity,
    fontScale: settings.fontScale,
    projectIconOpacity: settings.projectIconOpacity.toDouble(),
    showScrollbars: settings.showScrollbars,
    platformBrightness: platformBrightness,
    languageCode: settings.language.split(RegExp('[-_]')).first,
  );
}

GhUiSettingsData ghUiSettingsFrom(AppSettings settings) {
  return GhUiSettingsData(tooltipDelay: Duration(milliseconds: settings.tooltipDelay));
}

GhMotionPrefs ghMotionPrefsFrom(AppSettings settings) {
  return GhMotionPrefs(
    intensity: GhMotionIntensity.parse(settings.animationIntensity),
    speed: settings.animationSpeed,
    entrance: GhViewEntrance.parse(settings.viewEntrance),
    threshold: settings.animationThreshold,
    scrollReveal: settings.motionScrollReveal,
    tilt: settings.motionCardTilt,
    ripple: settings.motionClickRipple,
    press: settings.motionPressBounce,
    animatedNumbers: settings.animatedNumbers,
  );
}
