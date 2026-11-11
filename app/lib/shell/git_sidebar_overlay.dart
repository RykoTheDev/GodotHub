import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../design/design.dart';
import '../motion/presence.dart';
import '../src/rust/api/types.dart';
import '../ui/shell/resize_knob.dart';

@immutable
class GitSidebarTarget {
  const GitSidebarTarget({required this.project, this.gitStatus});

  final Project project;
  final GitStatus? gitStatus;
}

abstract final class GitSidebarWidth {
  static const prefKey = 'new_ui_git_sidebar_width';
  static const double min = 280;
  static const double max = 560;
  static const double fallback = 320;

  static double clamp(double value) => value.clamp(min, max).toDouble();

  static double parse(String? stored) {
    final value = num.tryParse(stored ?? '');
    return clamp(value == null || value == 0 || value.isNaN ? fallback : value.toDouble());
  }
}

class GitSidebarOverlay extends StatefulWidget {
  const GitSidebarOverlay({
    super.key,
    required this.target,
    required this.initialWidth,
    required this.fixedKnob,
    required this.onClose,
    required this.onWidthCommitted,
    required this.builder,
  });

  final GitSidebarTarget? target;
  final double initialWidth;
  final bool fixedKnob;
  final VoidCallback onClose;
  final ValueChanged<double> onWidthCommitted;
  final Widget Function(BuildContext context, GitSidebarTarget target) builder;

  @override
  State<GitSidebarOverlay> createState() => _GitSidebarOverlayState();
}

class _GitSidebarOverlayState extends State<GitSidebarOverlay> {
  late double _width = GitSidebarWidth.clamp(widget.initialWidth);
  GitSidebarTarget? _shown;
  bool _dragging = false;
  bool _revealed = false;
  bool _edgeHovered = false;
  double? _knobY;
  Duration? _lastDown;
  double _startX = 0;
  double _startWidth = 0;

  @override
  void initState() {
    super.initState();
    _shown = widget.target;
  }

  @override
  void didUpdateWidget(GitSidebarOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.target != null) _shown = widget.target;
  }

  void _reset() {
    setState(() {
      _width = GitSidebarWidth.fallback;
      _knobY = null;
    });
    widget.onWidthCommitted(_width);
  }

  void _onDown(PointerDownEvent event) {
    final last = _lastDown;
    _lastDown = event.timeStamp;
    if (last != null && event.timeStamp - last < GhResizeKnob.doubleClickWindow) {
      _reset();
      return;
    }
    _startX = event.position.dx;
    _startWidth = _width;
    setState(() => _dragging = true);
  }

  void _finish() {
    setState(() => _dragging = false);
    widget.onWidthCommitted(_width);
  }

  void _onStripMove(PointerMoveEvent event, double height, bool rtl) {
    if (_dragging) {
      if (event.buttons == 0) {
        _finish();
        return;
      }
      final delta = _startX - event.position.dx;
      final next = _startWidth + (rtl ? -delta : delta);
      setState(() => _width = GitSidebarWidth.clamp(next.roundToDouble()));
    }
  }

  void _onStripHover(PointerHoverEvent event, double height) {
    if (_dragging || widget.fixedKnob) return;
    setState(() => _knobY = GhResizeKnob.offsetFor(event.localPosition.dy, height));
  }

  void _onEnd() {
    if (_dragging) _finish();
  }

  void _onWrapperHover(PointerHoverEvent event, double width, double height, bool rtl) {
    if (_dragging || widget.fixedKnob) return;
    final x = event.localPosition.dx;
    final dist = rtl ? width - x : x;
    if (dist > GhResizeKnob.resetDistance) {
      if (_knobY != null) setState(() => _knobY = null);
      return;
    }
    if (dist <= GhResizeKnob.trackDistance) {
      setState(() => _knobY = GhResizeKnob.offsetFor(event.localPosition.dy, height));
    }
  }

  void _leave() => setState(() {
    _revealed = false;
    _knobY = null;
  });

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final open = widget.target != null;
    final shown = _shown;
    final inset = theme.space(2);
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !open,
            child: GhPresence(
              visible: open,
              kind: GhPresenceKind.backdrop,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onClose,
                child: const ColoredBox(color: Color(0x4D000000)),
              ),
            ),
          ),
        ),
        if (shown != null)
          PositionedDirectional(
            top: inset,
            end: inset,
            bottom: inset,
            child: IgnorePointer(
              ignoring: !open,
              child: GhPresence(
                visible: open,
                kind: GhPresenceKind.panel,
                onExited: () {
                  if (mounted && widget.target == null) setState(() => _shown = null);
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final height = constraints.maxHeight;
                    final overhang = theme.space(3.5);
                    return SizedBox(
                      width: _width + overhang,
                      height: height,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          PositionedDirectional(
                            top: 0,
                            bottom: 0,
                            end: 0,
                            width: _width,
                            child: MouseRegion(
                              opaque: false,
                              hitTestBehavior: HitTestBehavior.deferToChild,
                              onEnter: (_) => setState(() => _revealed = true),
                              onHover: (event) => _onWrapperHover(event, _width, height, rtl),
                              onExit: (_) => _leave(),
                              child: Container(
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(theme.radiusXl),
                                  boxShadow: GhShadows.xl2(Colors.black.withValues(alpha: 0.4)),
                                ),
                                child: widget.builder(context, shown),
                              ),
                            ),
                          ),
                          PositionedDirectional(
                            top: 0,
                            bottom: 0,
                            start: 0,
                            width: overhang * 2,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.resizeColumn,
                              onEnter: (_) => setState(() {
                                _revealed = true;
                                _edgeHovered = true;
                              }),
                              onHover: (event) => _onStripHover(event, height),
                              onExit: (_) => setState(() {
                                _edgeHovered = false;
                                _revealed = false;
                                _knobY = null;
                              }),
                              child: Listener(
                                behavior: HitTestBehavior.opaque,
                                onPointerDown: _onDown,
                                onPointerMove: (event) => _onStripMove(event, height, rtl),
                                onPointerUp: (_) => _onEnd(),
                                onPointerCancel: (_) => _onEnd(),
                                child: Semantics(
                                  container: true,
                                  child: GhResizeKnob(
                                    visible: _dragging || _revealed,
                                    dragging: _dragging,
                                    hovered: _edgeHovered,
                                    offsetY: _knobY != null && !widget.fixedKnob ? _knobY! : 0,
                                    width: _width,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
