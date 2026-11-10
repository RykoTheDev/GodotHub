import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../design/design.dart';
import '../../motion/motion.dart';
import '../../motion/ease.dart';
import '../../motion/presence.dart';

class GhDisclosure extends StatefulWidget {
  const GhDisclosure({super.key, required this.open, required this.child});

  final bool open;
  final Widget child;

  static const openSeconds = 0.4;
  static const closeSeconds = 0.26;

  @override
  State<GhDisclosure> createState() => _GhDisclosureState();
}

class _GhDisclosureState extends State<GhDisclosure> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, value: widget.open ? 1 : 0);
  int _stagger = 0;

  @override
  void didUpdateWidget(GhDisclosure oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.open == widget.open) {
      return;
    }
    final motion = GhMotion.of(context);
    if (widget.open) {
      if (_controller.value <= 0) {
        _stagger += 1;
      }
      _controller.animateTo(1, duration: motion.gsap(GhDisclosure.openSeconds), curve: GhEase.out);
    } else {
      _controller.animateTo(0, duration: motion.gsap(GhDisclosure.closeSeconds), curve: GhEase.soft);
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
      child: GhCascadeHost(
        cascade: GhPresenceSpecs.disclosureItems,
        replay: _stagger,
        resetOnReplay: false,
        child: widget.child,
      ),
      builder: (context, child) {
        final value = _controller.value.clamp(0.0, 1.0);
        final hidden = value <= 0 && !widget.open;
        final settled = value >= 1;
        return Visibility(
          visible: !hidden,
          maintainState: true,
          child: ClipRect(
            clipBehavior: settled ? Clip.none : Clip.hardEdge,
            child: Align(
              alignment: AlignmentDirectional.topStart,
              widthFactor: 1,
              heightFactor: value,
              child: Opacity(opacity: value, child: child),
            ),
          ),
        );
      },
    );
  }
}

class GhDisclosureItem extends StatelessWidget {
  const GhDisclosureItem({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => GhCascadeItem(role: GhCascadeRole.disclosure, child: child);
}

class GhDisclosureChevron extends StatelessWidget {
  const GhDisclosureChevron({super.key, required this.open});

  final bool open;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final motion = GhMotion.of(context);
    return ExcludeSemantics(
      child: AnimatedRotation(
        turns: open ? (rtl ? -0.25 : 0.25) : 0,
        duration: motion.css(GhDurations.iconTransform),
        curve: GhCurves.spring,
        child: Transform.rotate(
          angle: rtl ? math.pi : 0,
          child: GhIcon(GhIcons.chevronRight, size: theme.space(3), color: theme.muted),
        ),
      ),
    );
  }
}
