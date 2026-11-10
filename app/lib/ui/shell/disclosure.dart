import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../design/design.dart';
import '../core/ui_settings.dart';

class GhExpoOutCurve extends Curve {
  const GhExpoOutCurve();

  @override
  double transformInternal(double t) => t >= 1 ? 1 : 1 - math.pow(2, -10 * t).toDouble();
}

const ghGsapExpoOut = GhExpoOutCurve();
const ghGsapPower3Out = Curves.easeOutCubic;

class GhDisclosure extends StatefulWidget {
  const GhDisclosure({super.key, required this.open, required this.child});

  final bool open;
  final Widget child;

  static const openDuration = Duration(milliseconds: 400);
  static const closeDuration = Duration(milliseconds: 260);

  @override
  State<GhDisclosure> createState() => _GhDisclosureState();
}

class _GhDisclosureState extends State<GhDisclosure> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, value: widget.open ? 1 : 0);

  @override
  void didUpdateWidget(GhDisclosure oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.open == widget.open) {
      return;
    }
    final speed = GhUiSettings.of(context).motionSpeed;
    if (widget.open) {
      _controller.animateTo(1, duration: GhDurations.scaled(GhDisclosure.openDuration, speed), curve: ghGsapExpoOut);
    } else {
      _controller.animateTo(0, duration: GhDurations.scaled(GhDisclosure.closeDuration, speed), curve: ghGsapPower3Out);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final value = _controller.value;
        final hidden = value <= 0 && !widget.open;
        if (hidden) {
          return Visibility(visible: false, maintainState: true, child: child!);
        }
        if (value >= 1) {
          return child!;
        }
        return ClipRect(
          child: Align(
            alignment: AlignmentDirectional.topStart,
            heightFactor: value.clamp(0.0, 1.0),
            child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
          ),
        );
      },
    );
  }
}

class GhDisclosureChevron extends StatelessWidget {
  const GhDisclosureChevron({super.key, required this.open});

  final bool open;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final speed = GhUiSettings.of(context).motionSpeed;
    return ExcludeSemantics(
      child: AnimatedRotation(
        turns: open ? (rtl ? -0.25 : 0.25) : 0,
        duration: GhDurations.scaled(GhDurations.iconTransform, speed),
        curve: GhCurves.spring,
        child: Transform.rotate(
          angle: rtl ? math.pi : 0,
          child: GhIcon(GhIcons.chevronRight, size: theme.space(3), color: theme.muted),
        ),
      ),
    );
  }
}
