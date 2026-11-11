import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../core/interaction.dart';
import '../core/tooltip.dart';
import '../core/ui_settings.dart';
import '../core/i18n.dart';
import '../../motion/motion.dart';

class GhSearchBar extends StatefulWidget {
  const GhSearchBar({
    super.key,
    required this.value,
    required this.onChanged,
    this.placeholder,
    this.focusNode,
    this.onKeyEvent,
    this.onCaretChange,
    this.onBlur,
    this.overlay,
    this.autofocus = false,
    this.searchLabel,
    this.clearLabel,
    this.controller,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String? placeholder;
  final FocusNode? focusNode;
  final FocusOnKeyEventCallback? onKeyEvent;
  final ValueChanged<int>? onCaretChange;
  final VoidCallback? onBlur;
  final Widget? overlay;
  final bool autofocus;
  final String? searchLabel;
  final String? clearLabel;
  final TextEditingController? controller;

  @override
  State<GhSearchBar> createState() => _GhSearchBarState();
}

class _GhSearchBarState extends State<GhSearchBar> {
  TextEditingController? _ownController;

  TextEditingController get _controller => widget.controller ?? (_ownController ??= TextEditingController(text: widget.value));
  FocusNode? _ownNode;
  bool _focusWithin = false;
  int? _lastCaret;

  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode(debugLabel: 'GhSearchBar'));

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _node.addListener(_onInputFocus);
  }

  @override
  void didUpdateWidget(GhSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownNode)?.removeListener(_onInputFocus);
      _node.addListener(_onInputFocus);
    }
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(_onControllerChanged);
      _controller.addListener(_onControllerChanged);
    }
    if (widget.value != _controller.text) {
      final offset = widget.value.length;
      final selection = _controller.selection;
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: selection.isValid && selection.end <= offset ? selection : TextSelection.collapsed(offset: offset),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _node.removeListener(_onInputFocus);
    _ownController?.dispose();
    _ownNode?.dispose();
    super.dispose();
  }

  bool _hadFocus = false;

  void _onInputFocus() {
    final has = _node.hasFocus;
    if (_hadFocus && !has) {
      widget.onBlur?.call();
    }
    _hadFocus = has;
  }

  void _onControllerChanged() {
    final report = widget.onCaretChange;
    if (report == null) {
      return;
    }
    final selection = _controller.selection;
    final caret = selection.isValid ? selection.start : 0;
    if (caret != _lastCaret) {
      _lastCaret = caret;
      report(caret);
    }
  }

  void _clear() {
    widget.onChanged('');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _node.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final forced = GhForcedStates.maybeOf(context);
    final focused = _focusWithin || (forced?.focused ?? false);
    final textStyle = theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.ink);
    final motion = GhMotion.of(context);
    final bar = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (value) => setState(() => _focusWithin = value),
      child: GhAnimatedBox(
        duration: motion.css(GhDurations.interactive),
        height: theme.space(12),
        padding: EdgeInsets.symmetric(horizontal: theme.space(3.5)),
        color: focused ? theme.raised : theme.overlay,
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: focused ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
        child: Row(
          children: [
            GhIcon(GhIcons.search, size: theme.space(4), color: theme.muted),
            SizedBox(width: theme.space(2)),
            Expanded(
              child: Semantics(
                label: widget.searchLabel ?? context.tr.common.search,
                child: Focus(
                  canRequestFocus: false,
                  skipTraversal: true,
                  onKeyEvent: widget.onKeyEvent,
                  child: Material(
                    type: MaterialType.transparency,
                    child: TextField(
                      controller: _controller,
                      focusNode: _node,
                      autofocus: widget.autofocus,
                      onChanged: widget.onChanged,
                      onTap: () => _onControllerChanged(),
                      style: textStyle,
                      maxLines: 1,
                      cursorColor: theme.caret,
                      cursorWidth: 1,
                      decoration: InputDecoration.collapsed(
                        hintText: widget.placeholder ?? context.tr.common.search_projects_placeholder,
                        hintStyle: textStyle.copyWith(color: theme.placeholder),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.value.isNotEmpty) ...[
              SizedBox(width: theme.space(2)),
              GhTooltip(
                message: widget.clearLabel ?? context.tr.common.clear_search,
                side: GhSide.top,
                child: GhPressable(
                  onPressed: _clear,
                  semanticLabel: widget.clearLabel ?? context.tr.common.clear_search,
                  borderRadius: BorderRadius.circular(theme.radiusBtn),
                  builder: (context, states) {
                    final hover = states.hovered && !states.disabled;
                    return GhAnimatedBox(
                      width: theme.space(6),
                      height: theme.space(6),
                      alignment: Alignment.center,
                      color: hover ? theme.raised : theme.raised.withValues(alpha: 0),
                      borderRadius: BorderRadius.circular(theme.radiusBtn),
                      boxShadow: hover ? GhShadows.hoverLift() : const [],
                      child: GhIconMotionScale(
                        states: states,
                        child: GhAnimatedIcon(GhIcons.x, color: hover ? theme.ink : theme.muted, size: theme.space(3.5)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
    final overlay = widget.overlay;
    if (overlay == null) {
      return bar;
    }
    return Stack(clipBehavior: Clip.none, children: [bar, overlay]);
  }
}
