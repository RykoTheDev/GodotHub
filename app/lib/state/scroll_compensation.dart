import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import '../ui/shell/smooth_scroll.dart';

double compensatedScrollOffset(double saved, double maxScrollExtent) => math.min(saved, math.max(0, maxScrollExtent));

class ScrollCompensation {
  ScrollCompensation([ScrollController? controller]) : controller = controller ?? GhSmoothScrollController(), _owned = controller == null {
    this.controller.addListener(_track);
  }

  final ScrollController controller;
  final bool _owned;
  double _saved = 0;

  double get savedOffset => _saved;

  void _track() {
    if (controller.hasClients) _saved = controller.offset;
  }

  void restoreScroll() {
    void apply() {
      if (!controller.hasClients) return;
      final position = controller.position;
      final target = compensatedScrollOffset(_saved, position.maxScrollExtent);
      if (position.pixels != target) controller.jumpTo(target);
    }

    apply();
    SchedulerBinding.instance.addPostFrameCallback((_) => apply());
  }

  void dispose() {
    controller.removeListener(_track);
    if (_owned) controller.dispose();
  }
}
