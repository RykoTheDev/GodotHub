import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/design.dart';
import '../../src/rust/api/types.dart';
import '../../state/settings.dart';
import '../../ui/core/interaction.dart';
import '../../ui/core/i18n.dart';

String settingsTr(String key, {num? count, Map<String, Object?> args = const {}}) => ghTr('settings:$key', count: count, args: args);

Future<void> saveSettings(WidgetRef ref, AppSettings Function(AppSettings current) change) async {
  final current = ref.read(settingsProvider).value ?? await ref.read(settingsProvider.future);
  if (current == null) return;
  await ref.read(settingsProvider.notifier).save(change(current));
}

void ignoreAll(Future<void> Function() action) {
  try {
    unawaited(action().catchError((Object _) {}));
  } catch (_) {}
}

class SettingsDropdownTrigger extends StatelessWidget {
  const SettingsDropdownTrigger({super.key, required this.label, required this.open, required this.onPressed});

  final String label;
  final bool open;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhPressable(
      onPressed: onPressed,
      expanded: open,
      borderRadius: radius,
      builder: (context, states) => GhAnimatedBox(
        color: theme.overlay,
        borderRadius: radius,
        border: Border.all(color: states.active ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
        padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(2)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: theme.space(2),
          children: [
            Text(
              label,
              style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink),
            ),
            AnimatedRotation(
              turns: open ? 0.5 : 0,
              duration: GhDurations.iconTransform,
              child: GhIcon(GhIcons.chevronDown, size: theme.space(3), color: theme.muted),
            ),
          ],
        ),
      ),
    );
  }
}

enum SettingsButtonTone { normal, subtleDanger, danger }

class SettingsOutlineButton extends StatelessWidget {
  const SettingsOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = SettingsButtonTone.normal,
    this.paddingX = 5,
  });

  final String label;
  final VoidCallback? onPressed;
  final FaIconData? icon;
  final SettingsButtonTone tone;
  final double paddingX;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      disabledOpacity: 0.5,
      builder: (context, states) {
        final hover = states.active;
        final (Color border, Color? fill, Color text) = switch (tone) {
          SettingsButtonTone.normal => (
            hover ? theme.accentDim : theme.outline.withValues(alpha: 0.5),
            hover ? theme.raised : null,
            theme.ink,
          ),
          SettingsButtonTone.subtleDanger => (
            hover ? theme.danger.withValues(alpha: 0.4) : theme.outline.withValues(alpha: 0.5),
            hover ? theme.danger.withValues(alpha: 0.05) : null,
            hover ? theme.danger : theme.muted,
          ),
          SettingsButtonTone.danger => (
            theme.danger.withValues(alpha: 0.4),
            hover ? theme.danger.withValues(alpha: 0.1) : null,
            theme.danger,
          ),
        };
        final iconData = icon;
        return GhAnimatedBox(
          color: fill ?? theme.raised.withValues(alpha: 0),
          borderRadius: radius,
          border: Border.all(color: border),
          padding: EdgeInsets.symmetric(horizontal: theme.space(paddingX), vertical: theme.space(2.5)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: theme.space(2),
            children: [
              if (iconData != null) GhIcon(iconData, size: theme.space(4), color: text),
              Text(
                label,
                style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: text),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SettingsActionCard extends StatelessWidget {
  const SettingsActionCard({super.key, required this.title, required this.action, this.danger = false});

  final String title;
  final Widget action;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Container(
      padding: EdgeInsets.all(theme.space(4)),
      decoration: BoxDecoration(
        color: danger ? theme.danger.withValues(alpha: 0.04) : theme.overlay,
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: danger ? Border.all(color: theme.danger.withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        spacing: theme.space(6),
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: danger ? theme.danger : theme.ink),
            ),
          ),
          action,
        ],
      ),
    );
  }
}
