import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../../motion/presence.dart';
import 'bidi.dart';
import 'ui_settings.dart';

const double _viewportPad = 12;
const double _gap = 8;

class GhTooltip extends StatefulWidget {
  const GhTooltip({super.key, required this.child, this.message, this.content, this.side, this.maxWidth = 280, this.delay});

  final Widget child;
  final String? message;
  final Widget? content;
  final GhSide? side;
  final double maxWidth;
  final Duration? delay;

  @override
  State<GhTooltip> createState() => _GhTooltipState();
}

class _GhTooltipState extends State<GhTooltip> {
  final _portal = OverlayPortalController();
  final _bubbleKey = GlobalKey();
  Timer? _timer;
  Rect? _trigger;
  Offset? _position;
  GhSide _side = GhSide.bottom;
  bool _shown = false;

  bool get _hasContent => widget.content != null || (widget.message?.isNotEmpty ?? false);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _show() {
    if (!_hasContent) {
      return;
    }
    _timer?.cancel();
    _timer = Timer(widget.delay ?? GhUiSettings.of(context).tooltipDelay, () {
      if (!mounted) {
        return;
      }
      final box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) {
        return;
      }
      setState(() {
        _trigger = box.localToGlobal(Offset.zero) & box.size;
        _position = null;
        _shown = true;
      });
      _portal.show();
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    });
  }

  void _hide() {
    _timer?.cancel();
    if (!_shown) {
      return;
    }
    if (_position == null) {
      _shown = false;
      _removeOverlay();
      return;
    }
    setState(() => _shown = false);
  }

  void _removeOverlay() {
    if (_shown) {
      return;
    }
    if (_portal.isShowing) {
      _portal.hide();
    }
    _position = null;
  }

  void _measure() {
    final bubble = _bubbleKey.currentContext?.findRenderObject() as RenderBox?;
    final trigger = _trigger;
    if (!mounted || bubble == null || trigger == null || !bubble.hasSize) {
      return;
    }
    final viewport = MediaQuery.sizeOf(context);
    final size = bubble.size;
    final direction = Directionality.of(context);
    final space = {
      GhSide.top: trigger.top - _viewportPad - _gap,
      GhSide.bottom: viewport.height - trigger.bottom - _viewportPad - _gap,
      GhSide.left: trigger.left - _viewportPad - _gap,
      GhSide.right: viewport.width - trigger.right - _viewportPad - _gap,
    };
    GhSide side;
    if (widget.side != null) {
      side = mirrorSide(widget.side!, direction);
    } else {
      final ranked =
          [
              GhSide.bottom,
              GhSide.top,
              GhSide.right,
              GhSide.left,
            ].where((s) => space[s]! >= (s == GhSide.top || s == GhSide.bottom ? size.height : size.width) + _gap).toList()
            ..sort((a, b) => space[b]!.compareTo(space[a]!));
      if (ranked.isNotEmpty) {
        side = ranked.first;
      } else {
        final all = space.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        side = all.first.key;
      }
    }
    var x = switch (side) {
      GhSide.bottom || GhSide.top => trigger.left + trigger.width / 2 - size.width / 2,
      GhSide.right => trigger.right + _gap,
      GhSide.left => trigger.left - size.width - _gap,
    };
    var y = switch (side) {
      GhSide.bottom => trigger.bottom + _gap,
      GhSide.top => trigger.top - size.height - _gap,
      GhSide.left || GhSide.right => trigger.top + trigger.height / 2 - size.height / 2,
    };
    x = math.max(_viewportPad, math.min(x, viewport.width - size.width - _viewportPad));
    y = math.max(_viewportPad, math.min(y, viewport.height - size.height - _viewportPad));
    setState(() {
      _side = side;
      _position = Offset(x, y);
    });
  }

  Widget _overlay(BuildContext context) {
    final theme = GhTheme.of(context);
    final viewport = MediaQuery.sizeOf(context);
    final maxWidth = math.min(widget.maxWidth, viewport.width - _viewportPad * 2);
    final bubble = Container(
      key: _bubbleKey,
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(1.5)),
      decoration: BoxDecoration(
        color: theme.raised,
        borderRadius: BorderRadius.circular(theme.radiusTag),
        border: Border.all(color: theme.line),
        boxShadow: GhShadows.md(theme.base),
      ),
      child: DefaultTextStyle(
        style: theme.text(size: GhTextSize.x2s, weight: GhWeight.medium, color: theme.muted, lineHeight: 1.375),
        child: widget.content ?? ghPlaintext(widget.message ?? '', Text(widget.message ?? '')),
      ),
    );
    final position = _position;
    final content = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: _Arrow(side: _side, color: theme.raised),
        ),
        bubble,
      ],
    );
    return Positioned(
      left: position?.dx ?? -9999,
      top: position?.dy ?? -9999,
      child: IgnorePointer(
        child: position == null
            ? Opacity(opacity: 0, child: content)
            : GhPresence(
                visible: _shown,
                kind: GhPresenceKind.tooltip,
                origin: ghTooltipOrigin(_side),
                onExited: _removeOverlay,
                child: content,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) => Stack(children: [_overlay(context)]),
      child: MouseRegion(
        onEnter: (event) {
          if (event.kind == PointerDeviceKind.mouse) {
            _show();
          }
        },
        onExit: (_) => _hide(),
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onFocusChange: (focused) => focused ? _show() : _hide(),
          child: Listener(onPointerDown: (_) => _hide(), child: widget.child),
        ),
      ),
    );
  }
}

Alignment ghTooltipOrigin(GhSide side) => switch (side) {
  GhSide.top => Alignment.bottomCenter,
  GhSide.bottom => Alignment.topCenter,
  GhSide.left => Alignment.centerRight,
  GhSide.right => Alignment.centerLeft,
};

class _Arrow extends StatelessWidget {
  const _Arrow({required this.side, required this.color});

  final GhSide side;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final alignment = switch (side) {
      GhSide.top => Alignment.bottomCenter,
      GhSide.bottom => Alignment.topCenter,
      GhSide.left => Alignment.centerRight,
      GhSide.right => Alignment.centerLeft,
    };
    final offset = switch (side) {
      GhSide.top => const Offset(0, 4),
      GhSide.bottom => const Offset(0, -4),
      GhSide.left => const Offset(4, 0),
      GhSide.right => const Offset(-4, 0),
    };
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Transform.translate(
          offset: offset,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: SizedBox(width: 8, height: 8, child: ColoredBox(color: color)),
          ),
        ),
      ),
    );
  }
}
