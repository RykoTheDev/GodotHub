import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../core/interaction.dart';
import '../core/tooltip.dart';
import '../core/ui_settings.dart';
import '../feedback/modal_events.dart';
import '../overlays/popup_registry.dart';
import '../core/i18n.dart';
import '../../motion/motion.dart';

const double _showTopAfter = 200;
const double _minThumb = 32;
const double _thumbWidth = 5;

class GhOverlayScrollArea extends StatefulWidget {
  const GhOverlayScrollArea({
    super.key,
    required this.child,
    this.hideThumb = false,
    this.hideTopButton = false,
    this.scrollToTopOn,
    this.controller,
    this.topButtonBottom,
    this.scrollToTopLabel,
  });

  final Widget child;
  final bool hideThumb;
  final bool hideTopButton;
  final Object? scrollToTopOn;
  final ScrollController? controller;
  final double? topButtonBottom;
  final String? scrollToTopLabel;

  @override
  State<GhOverlayScrollArea> createState() => _GhOverlayScrollAreaState();
}

class _GhOverlayScrollAreaState extends State<GhOverlayScrollArea> {
  ScrollController? _own;
  double _thumbHeight = 0;
  double _offset = 0;
  bool _visible = false;
  bool _showTop = false;
  bool _dragging = false;
  bool _trackHovered = false;
  double _dragStartY = 0;
  double _dragStartScroll = 0;

  ScrollController get _controller => widget.controller ?? (_own ??= ScrollController());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_update);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  @override
  void didUpdateWidget(GhOverlayScrollArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _own)?.removeListener(_update);
      _controller.addListener(_update);
    }
    if (oldWidget.scrollToTopOn != widget.scrollToTopOn && _controller.hasClients) {
      _controller.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_update);
    _own?.dispose();
    super.dispose();
  }

  void _update() {
    if (!mounted || !_controller.hasClients) {
      return;
    }
    final position = _controller.position;
    if (!position.hasContentDimensions || !position.hasViewportDimension) {
      return;
    }
    final clientHeight = position.viewportDimension;
    final maxScroll = position.maxScrollExtent;
    final scrollTop = position.pixels;
    final showTop = scrollTop > _showTopAfter;
    if (maxScroll <= 0) {
      if (_visible || showTop != _showTop) {
        setState(() {
          _showTop = showTop;
          _visible = false;
          _thumbHeight = 0;
          _offset = 0;
        });
      }
      return;
    }
    final scrollHeight = maxScroll + clientHeight;
    final thumbHeight = math.min(clientHeight, math.max(_minThumb, (clientHeight / scrollHeight) * clientHeight));
    final offset = (scrollTop.clamp(0, maxScroll) / maxScroll) * (clientHeight - thumbHeight);
    if (thumbHeight == _thumbHeight && offset == _offset && _visible && showTop == _showTop) {
      return;
    }
    setState(() {
      _showTop = showTop;
      _thumbHeight = thumbHeight;
      _offset = offset;
      _visible = true;
    });
  }

  void _trackDown(PointerDownEvent event) {
    if (!_visible || !_controller.hasClients) {
      return;
    }
    final position = _controller.position;
    final maxScroll = position.maxScrollExtent;
    final travel = position.viewportDimension - _thumbHeight;
    if (maxScroll <= 0 || travel <= 0) {
      return;
    }
    final target = ((event.localPosition.dy - _thumbHeight / 2) / travel) * maxScroll;
    _controller.jumpTo(target.clamp(0, maxScroll).toDouble());
    _dragStartY = event.position.dy;
    _dragStartScroll = _controller.position.pixels;
    setState(() => _dragging = true);
  }

  void _trackMove(PointerMoveEvent event) {
    if (!_dragging || !_controller.hasClients) {
      return;
    }
    if (event.buttons == 0) {
      _endDrag();
      return;
    }
    final position = _controller.position;
    final maxScroll = position.maxScrollExtent;
    final travel = position.viewportDimension - _thumbHeight;
    if (maxScroll <= 0 || travel <= 0) {
      return;
    }
    final dy = event.position.dy - _dragStartY;
    _controller.jumpTo((_dragStartScroll + (dy / travel) * maxScroll).clamp(0, maxScroll).toDouble());
  }

  void _endDrag() {
    if (!_dragging) {
      return;
    }
    setState(() => _dragging = false);
  }

  void _scrollToTop() {
    if (_controller.hasClients) {
      _controller.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final motion = GhMotion.of(context);
    final showThumb = _visible && !widget.hideThumb;
    final thumbColor = _dragging ? theme.accent : (_trackHovered ? theme.accentDim : theme.line);
    final viewport = NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _update());
        return false;
      },
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false, overscroll: false),
        child: SingleChildScrollView(controller: _controller, child: widget.child),
      ),
    );
    final track = PositionedDirectional(
      top: 0,
      bottom: 0,
      end: 0,
      width: theme.space(3.5),
      child: IgnorePointer(
        ignoring: !showThumb,
        child: MouseRegion(
          cursor: showThumb ? (_dragging ? SystemMouseCursors.grabbing : SystemMouseCursors.click) : MouseCursor.defer,
          onEnter: (_) => setState(() => _trackHovered = true),
          onExit: (_) => setState(() => _trackHovered = false),
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _trackDown,
            onPointerMove: _trackMove,
            onPointerUp: (_) => _endDrag(),
            onPointerCancel: (_) => _endDrag(),
            child: Align(
              alignment: Alignment.topCenter,
              child: Transform.translate(
                offset: Offset(0, _offset),
                child: AnimatedOpacity(
                  opacity: showThumb ? 1 : 0,
                  duration: motion.css(GhDurations.interactive),
                  curve: GhCurves.outExpo,
                  child: GhAnimatedBox(
                    duration: motion.css(GhDurations.interactive),
                    width: _thumbWidth,
                    height: _thumbHeight,
                    color: thumbColor,
                    borderRadius: BorderRadius.circular(9999),
                    boxShadow: _dragging ? GhShadows.md(theme.accent.withValues(alpha: 0.4)) : const [],
                    child: null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(child: viewport),
          track,
          if (!widget.hideTopButton && _showTop)
            _TopButtonGate(
              child: Positioned(
                left: 0,
                right: 0,
                bottom: widget.topButtonBottom ?? theme.space(4),
                child: Center(
                  child: Transform.translate(
                    offset: Offset(-theme.space(2), 0),
                    child: GhTooltip(
                      message: widget.scrollToTopLabel ?? context.tr.common.scroll_to_top,
                      side: GhSide.top,
                      child: _ScrollTopButton(label: widget.scrollToTopLabel ?? context.tr.common.scroll_to_top, onPressed: _scrollToTop),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopButtonGate extends StatelessWidget {
  const _TopButtonGate({required this.child});

  final Positioned child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: GhPopupRegistry.openMenuCount,
      builder: (context, menus, _) => ValueListenableBuilder<int>(
        valueListenable: GhModalEvents.openDialogs,
        builder: (context, dialogs, _) => menus + dialogs > 0 ? const SizedBox.shrink() : child,
      ),
    );
  }
}

class _ScrollTopButton extends StatelessWidget {
  const _ScrollTopButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(9999);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      semanticLabel: label,
      builder: (context, states) {
        final hover = states.active;
        final foreground = hover ? theme.ink : theme.muted;
        return GhAnimatedBox(
          height: theme.space(9),
          padding: EdgeInsets.symmetric(horizontal: theme.space(4)),
          color: hover ? theme.overlay : theme.raised,
          borderRadius: radius,
          border: Border.all(color: hover ? theme.accentDim.withValues(alpha: 0.7) : theme.outline.withValues(alpha: 0.5)),
          boxShadow: GhShadows.lg(Colors.black.withValues(alpha: 0.4)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GhIconMotionScale(
                states: states,
                child: GhAnimatedIcon(GhIcons.chevronUp, color: foreground, size: theme.space(3.5)),
              ),
              SizedBox(width: theme.space(1.5)),
              GhAnimatedText(
                label,
                style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: foreground),
              ),
            ],
          ),
        );
      },
    );
  }
}
