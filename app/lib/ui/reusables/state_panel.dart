import 'package:material_ui/material_ui.dart';

import '../../design/design.dart';
import '../controls/dashed_box.dart';
import '../controls/spin.dart';
import '../core/button.dart';
import '../core/i18n.dart';

enum GhStateKind { empty, loading, error }

/// The one empty / loading / error panel for main screens. Every state has an
/// icon, a short title, an optional explanation and the actions that get the
/// user unstuck (retry, change filters, open settings). Errors use the danger
/// tone and always offer [onRetry] when one is provided.
class GhStatePanel extends StatelessWidget {
  const GhStatePanel({
    super.key,
    required this.kind,
    required this.title,
    this.message,
    this.icon,
    this.actions = const [],
    this.onRetry,
    this.compact = false,
  });

  const GhStatePanel.empty({super.key, required this.title, this.message, this.icon, this.actions = const [], this.compact = false})
    : kind = GhStateKind.empty,
      onRetry = null;

  const GhStatePanel.loading({super.key, required this.title, this.message, this.compact = false})
    : kind = GhStateKind.loading,
      icon = null,
      actions = const [],
      onRetry = null;

  const GhStatePanel.error({super.key, required this.title, this.message, this.onRetry, this.actions = const [], this.compact = false})
    : kind = GhStateKind.error,
      icon = GhIcons.alertTriangle;

  final GhStateKind kind;
  final String title;
  final String? message;
  final FaIconData? icon;
  final List<Widget> actions;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final danger = kind == GhStateKind.error;
    final accent = danger ? theme.danger : theme.muted;
    final radius = BorderRadius.circular(theme.radiusItem);
    final iconBox = theme.space(compact ? 9 : 11);
    final Widget glyph = kind == GhStateKind.loading
        ? GhSpinning(
            child: GhIcon(GhIcons.spinner, size: theme.space(compact ? 4 : 5), color: theme.accentBright),
          )
        : GhIcon(
            icon ?? GhIcons.info,
            size: theme.space(compact ? 4 : 5),
            color: accent.withValues(alpha: danger ? 1 : 0.7),
          );
    final buttons = [
      if (onRetry != null) GhButton(onPressed: onRetry, label: ghTr('retry'), icon: GhIcons.refresh, variant: GhButtonVariant.outline),
      ...actions,
    ];
    return Semantics(
      container: true,
      liveRegion: kind != GhStateKind.empty,
      child: GhDashedBox(
        color: danger ? theme.danger.withValues(alpha: 0.35) : theme.outline.withValues(alpha: 0.5),
        radius: radius,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.space(6), vertical: theme.space(compact ? 8 : 16)),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: theme.space(100)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: theme.space(3),
                children: [
                  Container(
                    width: iconBox,
                    height: iconBox,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: danger ? theme.danger.withValues(alpha: 0.1) : theme.raised,
                      borderRadius: BorderRadius.circular(theme.radiusTile),
                      border: Border.all(color: danger ? theme.danger.withValues(alpha: 0.25) : theme.outline.withValues(alpha: 0.5)),
                    ),
                    child: glyph,
                  ),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.text(size: compact ? GhTextSize.sm : GhTextSize.base, weight: GhWeight.semibold),
                  ),
                  if (message != null && message!.isNotEmpty)
                    Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: theme.text(size: GhTextSize.xs, color: theme.muted, lineHeight: 1.625),
                    ),
                  if (buttons.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: theme.space(1)),
                      child: Wrap(alignment: WrapAlignment.center, spacing: theme.space(2), runSpacing: theme.space(2), children: buttons),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A placeholder bar for skeleton loaders. Give either [width] or
/// [widthFactor]; height and radius default to a single text line.
class GhSkeleton extends StatelessWidget {
  const GhSkeleton({super.key, this.width, this.widthFactor, required this.height, this.radius});

  final double? width;
  final double? widthFactor;
  final double height;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final box = ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(color: theme.raised, borderRadius: BorderRadius.circular(radius ?? theme.radiusSm)),
        child: SizedBox(width: width, height: height),
      ),
    );
    return widthFactor == null
        ? box
        : FractionallySizedBox(alignment: AlignmentDirectional.centerStart, widthFactor: widthFactor, child: box);
  }
}
