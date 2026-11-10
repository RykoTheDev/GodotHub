import 'package:flutter/foundation.dart';

import '../overlays/popup_registry.dart';

abstract final class GhModalEvents {
  static final ValueNotifier<int> openDialogs = ValueNotifier<int>(0);

  static ValueListenable<int> get openMenus => GhPopupRegistry.openMenuCount;

  static bool get isMenuOpen => GhPopupRegistry.isMenuOpen;
}
