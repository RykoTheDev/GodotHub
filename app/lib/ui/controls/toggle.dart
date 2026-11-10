import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../core/interaction.dart';

class GhToggle extends StatelessWidget {
  const GhToggle({
    super.key,
    required this.checked,
    required this.onChanged,
    this.label,
    this.disabled = false,
    this.focusNode,
    this.autofocus = false,
  });

  final bool checked;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final bool disabled;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final enabled = !disabled && onChanged != null;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final width = theme.space(12);
    final height = theme.space(7);
    final thumb = theme.space(5);
    final radius = BorderRadius.circular(9999);
    return GhPressable(
      onPressed: enabled ? () => onChanged!(!checked) : null,
      focusNode: focusNode,
      autofocus: autofocus,
      borderRadius: radius,
      disabledCursor: SystemMouseCursors.forbidden,
      semanticLabel: label,
      button: false,
      toggled: checked,
      builder: (context, states) {
        return TweenAnimationBuilder<double>(
          tween: Tween(end: states.hovered && !states.disabled ? 1.1 : 1.0),
          duration: GhDurations.interactive,
          curve: GhCurves.outExpo,
          builder: (context, brightness, child) => GhBrightness(amount: brightness, child: child!),
          child: Transform.flip(
            flipX: rtl,
            child: GhAnimatedBox(
              width: width,
              height: height,
              color: checked ? theme.accent : theme.raised,
              borderRadius: radius,
              border: Border.all(color: checked ? theme.accentDim : theme.line),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedPositioned(
                    duration: GhDurations.iconTransform,
                    curve: GhCurves.spring,
                    left: checked ? width - 2 - thumb - 3 : 3,
                    top: (height - 2 - thumb) / 2,
                    width: thumb,
                    height: thumb,
                    child: AnimatedContainer(
                      duration: GhDurations.iconTransform,
                      curve: GhCurves.spring,
                      transform: states.pressed ? Matrix4.diagonal3Values(1.25, 0.9, 1) : Matrix4.identity(),
                      transformAlignment: Alignment.center,
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: GhShadows.md()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
