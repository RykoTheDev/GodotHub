import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/design.dart';
import '../core/interaction.dart';
import '../core/tooltip.dart';
import '../core/ui_settings.dart';
import 'negative_margin.dart';
import '../core/i18n.dart';
import '../../motion/motion.dart';

const double _thumbOffset = 16;

class _StepIntent extends Intent {
  const _StepIntent(this.direction, {this.big = false});

  final int direction;
  final bool big;
}

class _EdgeIntent extends Intent {
  const _EdgeIntent(this.end);

  final bool end;
}

const _sliderShortcuts = <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.arrowRight): _StepIntent(1),
  SingleActivator(LogicalKeyboardKey.arrowUp): _StepIntent(1),
  SingleActivator(LogicalKeyboardKey.arrowLeft): _StepIntent(-1),
  SingleActivator(LogicalKeyboardKey.arrowDown): _StepIntent(-1),
  SingleActivator(LogicalKeyboardKey.pageUp): _StepIntent(1, big: true),
  SingleActivator(LogicalKeyboardKey.pageDown): _StepIntent(-1, big: true),
  SingleActivator(LogicalKeyboardKey.home): _EdgeIntent(false),
  SingleActivator(LogicalKeyboardKey.end): _EdgeIntent(true),
};

class GhSlider extends StatefulWidget {
  const GhSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.disabled = false,
    this.label,
    this.display,
    this.defaultValue,
    this.resetLabel,
    this.focusNode,
    this.autofocus = false,
  });

  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double>? onChanged;
  final bool disabled;
  final String? label;
  final Widget? display;
  final double? defaultValue;
  final String? resetLabel;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<GhSlider> createState() => _GhSliderState();
}

class _GhSliderState extends State<GhSlider> {
  bool _dragging = false;
  bool _resetAtDragStart = false;
  bool _hovered = false;
  bool _focusHighlight = false;
  bool _pointerFocus = false;
  FocusNode? _ownNode;

  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode(debugLabel: 'GhSlider'));

  bool get _enabled => !widget.disabled && widget.onChanged != null;

  bool get _canReset {
    final d = widget.defaultValue;
    return d != null && (widget.value - d).abs() >= widget.step / 2;
  }

  @override
  void dispose() {
    _ownNode?.dispose();
    super.dispose();
  }

  int get _decimals {
    int places(double v) {
      final text = v.toString();
      if (text.contains('e')) {
        return 10;
      }
      final dot = text.indexOf('.');
      if (dot < 0) {
        return 0;
      }
      final frac = text.substring(dot + 1);
      return frac == '0' ? 0 : frac.length;
    }

    return math.max(places(widget.step), places(widget.min));
  }

  double _snap(double raw) {
    final min = widget.min;
    final max = widget.max;
    final step = widget.step;
    if (max <= min) {
      return min;
    }
    final clamped = raw.clamp(min, max);
    var steps = ((clamped - min) / step).round();
    var value = min + steps * step;
    if (value > max + 1e-9) {
      steps = ((max - min) / step).floor();
      value = min + steps * step;
    }
    return double.parse(value.toStringAsFixed(_decimals));
  }

  void _emit(double next) {
    if (!_enabled) {
      return;
    }
    final snapped = _snap(next);
    if (snapped != widget.value) {
      widget.onChanged!(snapped);
    }
  }

  void _updateFromPointer(double x, double width) {
    final thumb = GhTheme.of(context).space(4);
    final usable = width - thumb;
    final fraction = usable <= 0 ? 0.0 : ((x - thumb / 2) / usable).clamp(0.0, 1.0);
    _emit(widget.min + fraction * (widget.max - widget.min));
  }

  void _onStep(_StepIntent intent) {
    setState(() => _pointerFocus = false);
    final range = widget.max - widget.min;
    final amount = intent.big ? math.max(range / 10, widget.step) : widget.step;
    _emit(widget.value + amount * intent.direction);
  }

  void _onEdge(_EdgeIntent intent) {
    setState(() => _pointerFocus = false);
    _emit(intent.end ? widget.max : widget.min);
  }

  void _pointerDown(PointerDownEvent event, double width) {
    if (!_enabled) {
      return;
    }
    if (event.kind == PointerDeviceKind.mouse && event.buttons & kPrimaryMouseButton == 0) {
      return;
    }
    setState(() {
      _resetAtDragStart = _canReset;
      _dragging = true;
      _pointerFocus = true;
    });
    _node.requestFocus();
    _updateFromPointer(event.localPosition.dx, width);
  }

  void _pointerMove(PointerMoveEvent event, double width) {
    if (_dragging) {
      _updateFromPointer(event.localPosition.dx, width);
    }
  }

  void _pointerEnd() {
    if (_dragging) {
      setState(() => _dragging = false);
    }
  }

  String _format(double v) => v.toStringAsFixed(_decimals);

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final forced = GhForcedStates.maybeOf(context);
    final enabled = _enabled;
    final hovered = _hovered || (forced?.hovered ?? false);
    final focusVisible = enabled && ((_focusHighlight && !_pointerFocus) || (forced?.focused ?? false));
    final canReset = _canReset;
    final showReset = _dragging ? _resetAtDragStart : canReset;
    final span = widget.max - widget.min;
    final percent = span == 0 ? 0.0 : ((widget.value - widget.min) / span) * 100;
    final fraction = (percent / 100).clamp(0.0, 1.0);
    final trackRadius = theme.radiusMd;
    final bandTop = theme.space(1);
    final bandHeight = theme.space(6);
    final wrapperHeight = theme.space(8);

    final track = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final thumbLeft = (percent / 100) * width - (percent / 100) * _thumbOffset;
        return SizedBox(
          height: wrapperHeight,
          width: width,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: bandTop,
                height: bandHeight,
                child: IgnorePointer(
                  child: GhAnimatedBox(
                    color: theme.raised,
                    borderRadius: BorderRadius.circular(trackRadius),
                    border: Border.all(
                      color: widget.disabled ? theme.line : (hovered ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(math.max(0, trackRadius - 1)),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: fraction,
                          heightFactor: 1,
                          child: ColoredBox(color: theme.accent),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: thumbLeft,
                top: 0,
                width: theme.space(4),
                height: wrapperHeight,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(theme.radiusLg),
                      border: Border.all(color: theme.line),
                      boxShadow: GhShadows.md(),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: bandTop,
                height: bandHeight,
                child: FocusableActionDetector(
                  enabled: enabled,
                  focusNode: _node,
                  autofocus: widget.autofocus,
                  shortcuts: _sliderShortcuts,
                  actions: {
                    _StepIntent: CallbackAction<_StepIntent>(
                      onInvoke: (intent) {
                        _onStep(intent);
                        return null;
                      },
                    ),
                    _EdgeIntent: CallbackAction<_EdgeIntent>(
                      onInvoke: (intent) {
                        _onEdge(intent);
                        return null;
                      },
                    ),
                  },
                  mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
                  onShowHoverHighlight: (value) => setState(() => _hovered = value),
                  onShowFocusHighlight: (value) => setState(() {
                    _focusHighlight = value;
                    if (!value) {
                      _pointerFocus = false;
                    }
                  }),
                  child: GhFocusRing(
                    visible: focusVisible,
                    borderRadius: BorderRadius.circular(trackRadius),
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (event) => _pointerDown(event, width),
                      onPointerMove: (event) => _pointerMove(event, width),
                      onPointerUp: (_) => _pointerEnd(),
                      onPointerCancel: (_) => _pointerEnd(),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    final step = widget.step;
    final slider = Semantics(
      slider: true,
      enabled: enabled,
      label: widget.label,
      value: _format(widget.value),
      increasedValue: _format(_snap(widget.value + step)),
      decreasedValue: _format(_snap(widget.value - step)),
      onIncrease: enabled ? () => _emit(widget.value + step) : null,
      onDecrease: enabled ? () => _emit(widget.value - step) : null,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Opacity(
          opacity: widget.disabled ? 0.4 : 1,
          child: GhNegativeMargin(
            margin: EdgeInsets.symmetric(vertical: (wrapperHeight - theme.space(5)) / 2),
            child: track,
          ),
        ),
      ),
    );

    final resetDuration = GhMotion.of(context).css(const Duration(milliseconds: 300));
    final resetSize = theme.space(6);
    final resetEnabled = !widget.disabled && canReset && widget.onChanged != null;
    final reset = ExcludeSemantics(
      excluding: !showReset,
      child: AnimatedContainer(
        duration: resetDuration,
        curve: GhCurves.outExpo,
        width: showReset ? resetSize : 0,
        height: resetSize,
        margin: EdgeInsetsDirectional.only(end: showReset ? theme.space(1) : 0),
        child: AnimatedOpacity(
          duration: resetDuration,
          curve: GhCurves.outExpo,
          opacity: showReset ? 1 : 0,
          child: ClipRect(
            child: OverflowBox(
              alignment: AlignmentDirectional.centerStart,
              minWidth: resetSize,
              maxWidth: resetSize,
              child: GhTooltip(
                message: widget.resetLabel ?? context.tr.settings.reset_to_default,
                side: GhSide.left,
                child: GhPressable(
                  onPressed: resetEnabled ? () => widget.onChanged!(widget.defaultValue!) : null,
                  semanticLabel: widget.resetLabel ?? context.tr.settings.reset_to_default,
                  borderRadius: BorderRadius.circular(9999),
                  disabledOpacity: null,
                  disabledCursor: SystemMouseCursors.click,
                  builder: (context, states) {
                    final hover = states.hovered && !states.disabled && canReset;
                    final transparent = theme.raised.withValues(alpha: 0);
                    return GhAnimatedBox(
                      width: resetSize,
                      height: resetSize,
                      alignment: Alignment.center,
                      color: canReset ? (hover ? theme.overlay : theme.raised) : transparent,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: canReset
                            ? (hover ? theme.accentDim.withValues(alpha: 0.7) : theme.outline.withValues(alpha: 0.5))
                            : theme.outline.withValues(alpha: 0),
                      ),
                      boxShadow: hover ? GhShadows.hoverLift() : const [],
                      child: GhIconMotionScale(
                        states: states,
                        child: GhAnimatedIcon(
                          GhIcons.refresh,
                          color: canReset ? (hover ? theme.accentBright : theme.muted) : theme.muted.withValues(alpha: 0),
                          size: theme.space(3),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final display = widget.display;
    final trailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        reset,
        if (display != null)
          Container(
            constraints: BoxConstraints(minWidth: theme.space(14)),
            height: theme.space(6),
            padding: EdgeInsets.symmetric(horizontal: theme.space(2)),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.raised,
              border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(theme.radiusTag),
            ),
            child: DefaultTextStyle.merge(
              style: theme
                  .text(size: GhTextSize.xs, mono: true, color: theme.ink)
                  .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              child: display,
            ),
          ),
      ],
    );

    final label = widget.label;
    return Row(
      children: [
        if (label != null && label.isNotEmpty) ...[
          Text(
            label,
            style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.muted),
          ),
          SizedBox(width: theme.space(3)),
        ],
        Expanded(child: slider),
        SizedBox(width: theme.space(3)),
        trailing,
      ],
    );
  }
}
