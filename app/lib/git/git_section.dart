import 'package:flutter/material.dart';

import '../design/design.dart';
import '../src/ui_prefs.dart';
import '../ui/core/interaction.dart';
import '../ui/shell/disclosure.dart';

class GitSection extends StatefulWidget {
  const GitSection({
    super.key,
    required this.title,
    required this.children,
    this.count,
    this.storageKey,
    this.defaultOpen,
    this.onContextMenu,
    this.onOpenChange,
    this.prefs,
  });

  final String title;
  final List<Widget> children;
  final int? count;
  final String? storageKey;
  final bool? defaultOpen;
  final ValueChanged<Offset>? onContextMenu;
  final ValueChanged<bool>? onOpenChange;
  final UiPrefsStore? prefs;

  @override
  State<GitSection> createState() => _GitSectionState();
}

class _GitSectionState extends State<GitSection> {
  late bool _open = _initial();

  UiPrefsStore get _prefs => widget.prefs ?? UiPrefsStore.instance;

  bool _initial() {
    final fallback = widget.defaultOpen ?? true;
    final key = widget.storageKey;
    if (key == null) return fallback;
    try {
      final saved = _prefs.getItem(key);
      return saved == null ? fallback : saved != '0';
    } catch (_) {
      return fallback;
    }
  }

  void _toggle() {
    final next = !_open;
    final key = widget.storageKey;
    if (key != null) {
      try {
        _prefs.setItem(key, next ? '1' : '0');
      } catch (_) {}
    }
    setState(() => _open = next);
    widget.onOpenChange?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final count = widget.count;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GhPressable(
          onPressed: _toggle,
          onSecondaryTapUp: widget.onContextMenu == null ? null : (details) => widget.onContextMenu!(details.globalPosition),
          expanded: _open,
          borderRadius: BorderRadius.circular(theme.radiusItem),
          builder: (context, states) => GhAnimatedBox(
            color: states.active ? theme.raised.withValues(alpha: 0.6) : theme.raised.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(theme.radiusItem),
            padding: EdgeInsets.all(theme.space(1)),
            child: Row(
              spacing: theme.space(1.5),
              children: [
                AnimatedRotation(
                  turns: _open ? 0 : (rtl ? 0.25 : -0.25),
                  duration: GhDurations.iconTransform,
                  child: GhIcon(GhIcons.chevronDown, size: theme.space(3), color: theme.muted.withValues(alpha: 0.5)),
                ),
                Expanded(
                  child: Text(
                    widget.title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.text(
                      size: GhTextSize.x3s,
                      weight: GhWeight.semibold,
                      color: states.active ? theme.muted : theme.muted.withValues(alpha: 0.5),
                      letterSpacingEm: 0.05,
                    ),
                  ),
                ),
                if (count != null && count > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: theme.space(1.5), vertical: theme.space(0.5)),
                    decoration: BoxDecoration(
                      color: theme.overlay,
                      borderRadius: BorderRadius.circular(theme.radiusTag),
                      border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      '$count',
                      style: theme
                          .text(size: GhTextSize.x3s, weight: GhWeight.medium, mono: true, color: theme.muted.withValues(alpha: 0.6))
                          .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ),
              ],
            ),
          ),
        ),
        GhDisclosure(
          open: _open,
          child: Padding(
            padding: EdgeInsets.only(top: theme.space(1.5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: theme.space(1.5),
              children: widget.children,
            ),
          ),
        ),
      ],
    );
  }
}
