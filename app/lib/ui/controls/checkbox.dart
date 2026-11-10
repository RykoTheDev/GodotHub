import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../core/interaction.dart';
import 'keyframe.dart';
import 'negative_margin.dart';

class GhCheckbox extends StatelessWidget {
  const GhCheckbox({
    super.key,
    required this.checked,
    required this.onChanged,
    this.indeterminate = false,
    this.label,
    this.disabled = false,
    this.child,
    this.focusNode,
    this.autofocus = false,
  });

  final bool checked;
  final bool indeterminate;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final bool disabled;
  final Widget? child;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final enabled = !disabled && onChanged != null;
    final active = checked || indeterminate;
    final margin = theme.space(1);
    final radius = BorderRadius.circular(theme.radiusMd);
    return GhNegativeMargin(
      margin: EdgeInsets.all(margin),
      child: GhPressable(
        onPressed: enabled ? () => onChanged!(!checked) : null,
        focusNode: focusNode,
        autofocus: autofocus,
        borderRadius: radius,
        disabledCursor: SystemMouseCursors.forbidden,
        semanticLabel: label,
        button: false,
        checked: indeterminate ? null : checked,
        mixed: indeterminate ? true : null,
        builder: (context, states) {
          return Padding(
            padding: EdgeInsets.all(margin),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CheckBoxSquare(active: active, indeterminate: indeterminate),
                if (child != null) ...[
                  SizedBox(width: theme.space(2.5)),
                  Flexible(
                    child: DefaultTextStyle.merge(
                      style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink),
                      textAlign: TextAlign.start,
                      child: child!,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CheckBoxSquare extends StatefulWidget {
  const _CheckBoxSquare({required this.active, required this.indeterminate});

  final bool active;
  final bool indeterminate;

  @override
  State<_CheckBoxSquare> createState() => _CheckBoxSquareState();
}

class _CheckBoxSquareState extends State<_CheckBoxSquare> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final forcedHover = GhForcedStates.maybeOf(context)?.hovered ?? false;
    final hovered = _hovered || forcedHover;
    final active = widget.active;
    final size = theme.space(4);
    final border = active ? theme.accentDim : (hovered ? theme.accentDim : theme.line);
    final icon = widget.indeterminate ? GhIcons.minus : GhIcons.check;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GhKeyframe(
        active: active,
        duration: GhDurations.focusPop,
        builder: (context, t, child) => Transform.scale(scale: 0.7 + 0.3 * GhCurves.spring.transform(t), child: child),
        child: GhAnimatedBox(
          width: size,
          height: size,
          duration: GhDurations.color,
          color: active ? theme.accent : theme.raised,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(theme.radiusSm),
          alignment: Alignment.center,
          child: Opacity(
            opacity: active ? 1 : 0,
            child: GhKeyframe(
              key: ValueKey(icon),
              active: active,
              duration: GhDurations.iconTransform,
              builder: (context, t, child) {
                final v = GhCurves.spring.transform(t);
                return Transform.rotate(
                  angle: -math.pi / 4 * (1 - v),
                  child: Transform.scale(scale: v, child: child),
                );
              },
              child: GhAnimatedIcon(icon, color: active ? Colors.white : Colors.white.withValues(alpha: 0), size: theme.space(3)),
            ),
          ),
        ),
      ),
    );
  }
}
