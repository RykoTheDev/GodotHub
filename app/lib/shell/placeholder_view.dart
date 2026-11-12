import 'package:flutter/material.dart';

import '../design/design.dart';
import '../ui/core/button.dart';
import '../ui/feedback/modal_shell.dart';

class PlaceholderView extends StatelessWidget {
  const PlaceholderView({super.key, required this.icon, required this.title, this.actions = const []});

  final FaIconData icon;
  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: theme.space(3),
        children: [
          GhIcon(icon, size: theme.space(8), color: theme.muted.withValues(alpha: 0.5)),
          Text(
            title,
            style: theme.text(size: GhTextSize.lg, weight: GhWeight.semibold, color: theme.ink),
          ),
          Text(
            'This view has not been ported to the Flutter app yet.',
            style: theme.text(size: GhTextSize.xs, color: theme.muted),
          ),
          if (actions.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, spacing: theme.space(2), children: actions),
        ],
      ),
    );
  }
}

class PlaceholderModal extends StatelessWidget {
  const PlaceholderModal({super.key, required this.title, required this.icon});

  final String title;
  final FaIconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    void close() => Navigator.of(context).pop();
    return GhModalShell(
      icon: GhIcon(icon, size: theme.space(5), color: theme.accentBright),
      title: title,
      maxWidth: GhModalWidth.md,
      onClose: close,
      footer: [
        const Spacer(),
        GhButton(onPressed: close, label: 'Close', variant: GhButtonVariant.primary),
      ],
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), 0, theme.space(6), theme.space(4)),
        child: Text(
          'This dialog has not been ported to the Flutter app yet.',
          style: theme.text(size: GhTextSize.sm, color: theme.muted),
        ),
      ),
    );
  }
}

Future<void> showPlaceholderModal(BuildContext context, {required String title, required FaIconData icon}) =>
    showGhModal<void>(context, (context) => PlaceholderModal(title: title, icon: icon));
