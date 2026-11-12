import 'dart:convert';

import '../src/ui_prefs.dart';
import '../ui/shell/sidebar.dart';

abstract final class SidebarPrefs {
  static const width = 'new_ui_sidebar_width';
  static const collapsed = 'new_ui_sidebar_collapsed';
  static const seenNewTabs = 'new_ui_sidebar_seen_new_tabs';
  static const workspaceTipSeen = 'new_ui_sidebar_workspace_tip_seen';
  static const closedGroups = 'new_ui_sidebar_closed_groups';

  static double readWidth(UiPrefsStore prefs) {
    final value = num.tryParse(prefs.getItem(width) ?? '');
    return GhSidebar.clampWidth(value == null || value == 0 || value.isNaN ? GhSidebar.defaultWidth : value.toDouble());
  }

  static List<String> readList(UiPrefsStore prefs, String key) {
    try {
      final saved = jsonDecode(prefs.getItem(key) ?? '[]');
      return saved is List
          ? [
              for (final id in saved)
                if (id is String) id,
            ]
          : const [];
    } catch (_) {
      return const [];
    }
  }
}
