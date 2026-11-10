import 'package:flutter/foundation.dart';

abstract final class GhUiTransition {
  static bool _splashConsumed = false;
  static bool _switchToSettings = false;
  static bool _shellIntroHandedOff = false;

  static bool shouldOpenSettingsAfterSwitch() => _switchToSettings;

  static void clearUiSwitchToSettings() => _switchToSettings = false;

  static bool shouldShowSplash() => !_splashConsumed;

  static void markSplashConsumed() => _splashConsumed = true;

  static void handOffShellIntro() => _shellIntroHandedOff = true;

  static bool consumeShellIntroHandOff() {
    final handedOff = _shellIntroHandedOff;
    _shellIntroHandedOff = false;
    return handedOff;
  }

  @visibleForTesting
  static void reset() {
    _splashConsumed = false;
    _switchToSettings = false;
    _shellIntroHandedOff = false;
  }
}
