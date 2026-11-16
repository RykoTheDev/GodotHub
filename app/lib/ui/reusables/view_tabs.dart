import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../core/interaction.dart';

typedef GhViewTab = ({String value, String label, FaIconData icon});

/// The section switch that sits beside a view's search box (Asset Store:
/// Addons and Templates). Icon and label per section, the active one filled.
class GhViewTabs extends StatelessWidget {
  const GhViewTabs({super.key, required this.tabs, required this.value, required this.onChanged});

  final List<GhViewTab> tabs;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    Widget option(GhViewTab tab) {
      final active = tab.value == value;
      return GhPressable(
        key: ValueKey('view-tab-${tab.value}'),
        onPressed: () => onChanged(tab.value),
        borderRadius: radius,
        selected: active,
        semanticLabel: tab.label,
        builder: (context, states) {
          final color = active ? Colors.white : (states.active ? theme.ink : theme.muted);
          return GhAnimatedBox(
            color: active ? theme.accent : (states.active ? theme.raised : theme.raised.withValues(alpha: 0)),
            borderRadius: radius,
            padding: EdgeInsets.symmetric(horizontal: theme.space(3.5)),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: theme.space(1.5),
              children: [
                GhIcon(tab.icon, size: theme.space(3.5), color: color),
                Flexible(
                  child: Text(
                    tab.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: color),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Container(
      height: theme.space(12),
      padding: EdgeInsets.all(theme.space(1)),
      decoration: BoxDecoration(
        color: theme.overlay,
        borderRadius: radius,
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: theme.space(1),
        children: [for (final tab in tabs) Flexible(child: option(tab))],
      ),
    );
  }
}
