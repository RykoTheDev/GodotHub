import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../../motion/reveal.dart';
import '../core/bidi.dart';

class GhViewHeader extends StatelessWidget {
  const GhViewHeader({
    super.key,
    required this.title,
    this.badge,
    this.leadingAction,
    this.metric,
    this.actions = const [],
    this.child,
    this.connected = false,
  });

  final String title;
  final Widget? badge;
  final Widget? leadingAction;
  final List<Widget>? metric;
  final List<Widget> actions;
  final Widget? child;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final metric = this.metric;
    return GhReveal(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: theme.space(6), vertical: theme.space(4)),
        decoration: BoxDecoration(
          color: theme.raised,
          borderRadius: connected ? BorderRadius.zero : BorderRadius.circular(theme.radiusCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: theme.space(2),
          children: [
            Row(
              spacing: theme.space(3),
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: theme.space(2),
                  children: [
                    GhReveal(
                      kind: GhRevealKind.heading,
                      child: ghPlaintext(
                        title,
                        Text(
                          title.toUpperCase(),
                          style: theme.text(size: GhTextSize.x4l, weight: GhWeight.bold, color: theme.ink, letterSpacingEm: 0.025),
                        ),
                      ),
                    ),
                    ?badge,
                    ?leadingAction,
                  ],
                ),
                const Spacer(),
                if (metric != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    spacing: theme.space(1),
                    children: metric,
                  ),
                if (actions.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, spacing: theme.space(2), children: actions),
              ],
            ),
            ?child,
          ],
        ),
      ),
    );
  }
}
