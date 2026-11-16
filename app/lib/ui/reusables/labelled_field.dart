import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../controls/text_input.dart';
import '../core/i18n.dart';
import 'modal_kit.dart';

/// What a [GhLabelledField] tells the input inside it, so the input picks up
/// its accessible label, the error or hint it is described by, and its
/// invalid styling without each form wiring that by hand.
class GhFieldScope extends InheritedWidget {
  const GhFieldScope({super.key, required this.label, this.describedBy, this.invalid = false, required super.child});

  final String label;
  final String? describedBy;
  final bool invalid;

  static GhFieldScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<GhFieldScope>();

  @override
  bool updateShouldNotify(GhFieldScope oldWidget) =>
      label != oldWidget.label || describedBy != oldWidget.describedBy || invalid != oldWidget.invalid;
}

/// One form field: label, input, then either the error or the hint below it.
///
/// The error replaces the hint while present and is announced as a live
/// region. A [GhFieldInput] or [GhPathField] placed in [child] is labelled by
/// [label], described by the error or hint, and shows the invalid border
/// automatically. Mark a field [optional] (the usual case for non-essential
/// fields) or [required]; never both.
class GhLabelledField extends StatelessWidget {
  const GhLabelledField({
    super.key,
    required this.label,
    required this.child,
    this.hint,
    this.error,
    this.optional = false,
    this.required = false,
    this.trailing,
    this.inset = true,
  }) : assert(!(optional && required), 'A field is either optional or required');

  final String label;
  final Widget child;
  final String? hint;
  final String? error;
  final bool optional;
  final bool required;

  /// Shown at the end of the label row, for a counter or a small link.
  final Widget? trailing;

  /// Indents the label and messages to line up with the input's text.
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final error = this.error?.trim().isEmpty ?? true ? null : this.error;
    final hint = this.hint?.trim().isEmpty ?? true ? null : this.hint;
    final labelWidget = required
        ? Text.rich(
            TextSpan(
              text: label,
              children: [
                TextSpan(
                  text: ' *',
                  semanticsLabel: ', ${ghTr('field_required')}',
                  style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: theme.danger.withValues(alpha: 0.8)),
                ),
              ],
            ),
            style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.muted),
          )
        : GhFieldLabel(label, optional: optional ? ghTr('optional') : null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(1.5),
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: inset ? theme.space(1) : 0),
          child: Row(
            children: [
              Expanded(child: ExcludeSemantics(child: labelWidget)),
              ?trailing,
            ],
          ),
        ),
        GhFieldScope(
          label: required ? '$label, ${ghTr('field_required')}' : label,
          describedBy: error ?? hint,
          invalid: error != null,
          child: child,
        ),
        if (error != null) GhFieldMessage(error, error: true, inset: inset) else if (hint != null) GhFieldMessage(hint, inset: inset),
      ],
    );
  }
}

/// The hint or error line under a field.
class GhFieldMessage extends StatelessWidget {
  const GhFieldMessage(this.text, {super.key, this.error = false, this.inset = true});

  final String text;
  final bool error;
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final color = error ? theme.danger : theme.muted;
    final message = Padding(
      padding: EdgeInsetsDirectional.only(start: inset ? theme.space(1) : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: theme.space(1.5),
        children: [
          if (error)
            Padding(
              padding: EdgeInsets.only(top: theme.space(0.25)),
              child: GhIcon(GhIcons.alertTriangle, size: theme.space(3), color: color),
            ),
          Expanded(
            child: Text(
              text,
              style: theme.text(size: GhTextSize.x2s, color: color, lineHeight: 1.5),
            ),
          ),
        ],
      ),
    );
    // The input already reads the message as its hint; keep the visible copy
    // out of the tree except for the live announcement of a new error.
    return error ? Semantics(liveRegion: true, child: message) : ExcludeSemantics(child: message);
  }
}

/// The standard form text input: base background, outline border that turns
/// danger when invalid and accent-dim on focus. Inside a [GhLabelledField] it
/// takes its label, description and invalid state from the field.
class GhFieldInput extends StatelessWidget {
  const GhFieldInput({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.onChanged,
    this.onSubmitted,
    this.onKeyEvent,
    this.onBlur,
    this.invalid,
    this.mono = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.semanticLabel,
    this.maxLines = 1,
    this.minLines,
    this.textDirection,
    this.obscureText = false,
    this.textColor,
    this.onTap,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusOnKeyEventCallback? onKeyEvent;
  final VoidCallback? onBlur;

  /// Overrides the invalid state from the surrounding [GhLabelledField].
  final bool? invalid;
  final bool mono;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final String? semanticLabel;
  final int? maxLines;
  final int? minLines;
  final TextDirection? textDirection;
  final bool obscureText;
  final Color? textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final scope = GhFieldScope.maybeOf(context);
    final bad = invalid ?? scope?.invalid ?? false;
    return GhTextInput(
      controller: controller,
      focusNode: focusNode,
      placeholder: placeholder,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onKeyEvent: onKeyEvent,
      onBlur: onBlur,
      autofocus: autofocus,
      enabled: enabled,
      readOnly: readOnly,
      onTap: onTap,
      mono: mono,
      maxLines: maxLines,
      minLines: minLines,
      textDirection: textDirection,
      obscureText: obscureText,
      textColor: textColor,
      semanticLabel: semanticLabel ?? scope?.label,
      semanticHint: scope?.describedBy,
      background: theme.base,
      borderColor: bad ? theme.danger.withValues(alpha: 0.7) : theme.outline.withValues(alpha: 0.5),
      focusBorderColor: bad ? theme.danger : theme.accentDim,
      borderRadius: BorderRadius.circular(theme.radiusItem),
      padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(2.5)),
    );
  }
}
