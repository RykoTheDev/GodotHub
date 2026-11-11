import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../../motion/motion.dart';
import '../core/interaction.dart';

class GhTextInput extends StatefulWidget {
  const GhTextInput({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.onChanged,
    this.onSubmitted,
    this.onKeyEvent,
    this.onBlur,
    this.autofocus = false,
    this.size = GhTextSize.sm,
    this.weight = GhWeight.normal,
    this.mono = false,
    this.textColor,
    this.placeholderColor,
    this.background,
    this.borderColor,
    this.focusBorderColor,
    this.borderRadius,
    this.padding,
    this.bordered = true,
    this.focusRing = true,
    this.width,
    this.semanticLabel,
    this.tooltip,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusOnKeyEventCallback? onKeyEvent;
  final VoidCallback? onBlur;
  final bool autofocus;
  final GhTextSize size;
  final FontWeight weight;
  final bool mono;
  final Color? textColor;
  final Color? placeholderColor;
  final Color? background;
  final Color? borderColor;
  final Color? focusBorderColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool bordered;
  final bool focusRing;
  final double? width;
  final String? semanticLabel;
  final String? tooltip;

  @override
  State<GhTextInput> createState() => _GhTextInputState();
}

class _GhTextInputState extends State<GhTextInput> {
  TextEditingController? _ownController;
  FocusNode? _ownNode;
  bool _focused = false;

  TextEditingController get _controller => widget.controller ?? (_ownController ??= TextEditingController());

  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode(debugLabel: 'GhTextInput'));

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(GhTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownNode)?.removeListener(_onFocus);
      _node.addListener(_onFocus);
    }
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _ownController?.dispose();
    _ownNode?.dispose();
    super.dispose();
  }

  void _onFocus() {
    final has = _node.hasFocus;
    if (has == _focused) return;
    setState(() => _focused = has);
    if (!has) widget.onBlur?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final motion = GhMotion.of(context);
    final focused = _focused || (GhForcedStates.maybeOf(context)?.focused ?? false);
    final style = theme.text(size: widget.size, weight: widget.weight, mono: widget.mono, color: widget.textColor ?? theme.ink);
    Widget field = Material(
      type: MaterialType.transparency,
      child: TextField(
        controller: _controller,
        focusNode: _node,
        autofocus: widget.autofocus,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        onEditingComplete: widget.onSubmitted == null ? null : () {},
        style: style,
        maxLines: 1,
        cursorColor: theme.caret,
        cursorWidth: 1,
        decoration: InputDecoration.collapsed(
          hintText: widget.placeholder,
          hintStyle: style.copyWith(color: widget.placeholderColor ?? theme.placeholder),
        ),
      ),
    );
    if (widget.onKeyEvent != null) {
      field = Focus(canRequestFocus: false, skipTraversal: true, onKeyEvent: widget.onKeyEvent, child: field);
    }
    if (widget.semanticLabel != null) {
      field = Semantics(label: widget.semanticLabel, textField: true, child: field);
    }
    final border = widget.borderColor ?? theme.outline.withValues(alpha: 0.5);
    final focusBorder = widget.focusBorderColor ?? theme.accent.withValues(alpha: 0.6);
    Widget box = GhAnimatedBox(
      duration: motion.css(GhDurations.interactive),
      width: widget.width,
      color: widget.background,
      borderRadius: widget.borderRadius ?? BorderRadius.circular(theme.radiusItem),
      border: widget.bordered ? Border.all(color: focused ? focusBorder : border) : null,
      boxShadow: focused && widget.focusRing && widget.bordered ? GhShadows.inputFocus(theme) : const [],
      padding: widget.padding ?? EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
      child: field,
    );
    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      box = Tooltip(message: widget.tooltip, child: box);
    }
    return box;
  }
}
