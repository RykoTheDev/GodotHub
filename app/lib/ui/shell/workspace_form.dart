import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../core/interaction.dart';
import 'strings.dart';
import '../../motion/motion.dart';

@immutable
class GhWorkspaceDraft {
  const GhWorkspaceDraft({required this.name, required this.icon, required this.color});

  final String name;
  final String icon;
  final String color;

  GhWorkspaceDraft copyWith({String? name, String? icon, String? color}) =>
      GhWorkspaceDraft(name: name ?? this.name, icon: icon ?? this.icon, color: color ?? this.color);

  @override
  bool operator ==(Object other) => other is GhWorkspaceDraft && other.name == name && other.icon == icon && other.color == color;

  @override
  int get hashCode => Object.hash(name, icon, color);
}

String? ghWorkspaceNameError(
  String name,
  List<String> takenNames, {
  String requiredError = GhShellStrings.workspaceNameRequiredError,
  String takenError = GhShellStrings.workspaceNameTakenError,
}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return requiredError;
  }
  final lower = trimmed.toLowerCase();
  if (takenNames.any((n) => n.trim().toLowerCase() == lower)) {
    return takenError;
  }
  return null;
}

Color _hexAlpha(String hex, int alpha) => colorFromHex(hex).withAlpha(alpha);

class GhWorkspaceAvatar extends StatelessWidget {
  const GhWorkspaceAvatar({super.key, required this.icon, required this.color, this.size = 14, this.iconSize = 6});

  final String icon;
  final String color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tint = colorFromHex(color);
    return Container(
      width: theme.space(size),
      height: theme.space(size),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _hexAlpha(color, 0x1f),
        border: Border.all(color: tint, width: 2),
      ),
      child: GhIcon(workspaceIcon(icon), size: theme.space(iconSize), color: tint),
    );
  }
}

class GhWorkspaceForm extends StatelessWidget {
  const GhWorkspaceForm({
    super.key,
    required this.value,
    required this.onChanged,
    required this.takenNames,
    required this.showErrors,
    this.autofocus = false,
    this.onSubmit,
    this.onNameBlur,
    this.nameFocusNode,
    this.namePlaceholder = GhShellStrings.workspaceNamePlaceholder,
    this.sectionLabel = GhShellStrings.sectionWorkspaces,
    this.nameLabel = GhShellStrings.workspaceNameLabel,
    this.iconLabel = GhShellStrings.iconLabel,
    this.colorLabel = GhShellStrings.colorLabel,
    this.requiredError = GhShellStrings.workspaceNameRequiredError,
    this.takenError = GhShellStrings.workspaceNameTakenError,
  });

  final GhWorkspaceDraft value;
  final ValueChanged<GhWorkspaceDraft> onChanged;
  final List<String> takenNames;
  final bool showErrors;
  final bool autofocus;
  final VoidCallback? onSubmit;
  final VoidCallback? onNameBlur;
  final FocusNode? nameFocusNode;
  final String namePlaceholder;
  final String sectionLabel;
  final String nameLabel;
  final String iconLabel;
  final String colorLabel;
  final String requiredError;
  final String takenError;

  static const double twoColumnBreakpoint = 640;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final error = showErrors ? ghWorkspaceNameError(value.name, takenNames, requiredError: requiredError, takenError: takenError) : null;
    final trimmed = value.name.trim();
    final preview = Container(
      padding: EdgeInsets.all(theme.space(4)),
      decoration: BoxDecoration(
        color: theme.base.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          GhWorkspaceAvatar(icon: value.icon, color: value.color),
          SizedBox(width: theme.space(4)),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trimmed.isEmpty ? namePlaceholder : trimmed,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text(size: GhTextSize.xl, weight: GhWeight.bold, color: theme.ink, letterSpacingEm: -0.025),
                ),
                SizedBox(height: theme.space(0.5)),
                Text(
                  sectionLabel.toUpperCase(),
                  style: theme.text(
                    size: GhTextSize.x3s,
                    weight: GhWeight.semibold,
                    color: theme.muted.withValues(alpha: 0.6),
                    letterSpacingEm: 0.05,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final nameField = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          nameLabel,
          style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.muted),
        ),
        SizedBox(height: theme.space(2)),
        _NameInput(
          value: value.name,
          onChanged: (name) => onChanged(value.copyWith(name: name)),
          onSubmit: onSubmit,
          onBlur: onNameBlur,
          autofocus: autofocus,
          focusNode: nameFocusNode,
          placeholder: namePlaceholder,
          label: nameLabel,
          error: error,
        ),
        if (error != null) ...[
          SizedBox(height: theme.space(2)),
          Text(
            error,
            style: theme.text(size: GhTextSize.x2s, color: theme.danger),
          ),
        ],
      ],
    );
    final iconPicker = _LabeledGrid(
      label: iconLabel,
      columns: 6,
      children: [
        for (final key in workspaceIconKeys)
          _IconOption(
            iconKey: key,
            active: value.icon == key,
            onPressed: () => onChanged(value.copyWith(icon: key)),
          ),
      ],
    );
    final colorPicker = _LabeledGrid(
      label: colorLabel,
      columns: 7,
      children: [
        for (final color in workspaceColorPresets)
          _ColorOption(
            color: color,
            active: value.color == color,
            onPressed: () => onChanged(value.copyWith(color: color)),
          ),
      ],
    );
    final twoColumns = MediaQuery.sizeOf(context).width >= twoColumnBreakpoint;
    final pickers = twoColumns
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: iconPicker),
              SizedBox(width: theme.space(5)),
              Expanded(child: colorPicker),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              iconPicker,
              SizedBox(height: theme.space(5)),
              colorPicker,
            ],
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        preview,
        SizedBox(height: theme.space(5)),
        nameField,
        SizedBox(height: theme.space(5)),
        pickers,
      ],
    );
  }
}

class _NameInput extends StatefulWidget {
  const _NameInput({
    required this.value,
    required this.onChanged,
    required this.onSubmit,
    required this.onBlur,
    required this.autofocus,
    required this.focusNode,
    required this.placeholder,
    required this.label,
    required this.error,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmit;
  final VoidCallback? onBlur;
  final bool autofocus;
  final FocusNode? focusNode;
  final String placeholder;
  final String label;
  final String? error;

  @override
  State<_NameInput> createState() => _NameInputState();
}

class _NameInputState extends State<_NameInput> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);
  FocusNode? _own;
  bool _focused = false;

  FocusNode get _node => widget.focusNode ?? (_own ??= FocusNode(debugLabel: 'GhWorkspaceForm name'));

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(_NameInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _own)?.removeListener(_onFocus);
      _node.addListener(_onFocus);
    }
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _controller.dispose();
    _own?.dispose();
    super.dispose();
  }

  void _onFocus() {
    final has = _node.hasFocus;
    if (has == _focused) {
      return;
    }
    setState(() => _focused = has);
    if (!has) {
      widget.onBlur?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final motion = GhMotion.of(context);
    final focused = _focused || (GhForcedStates.maybeOf(context)?.focused ?? false);
    final hasError = widget.error != null;
    final border = hasError
        ? theme.danger.withValues(alpha: 0.6)
        : focused
        ? theme.accentDim
        : theme.outline.withValues(alpha: 0.5);
    final style = theme.text(size: GhTextSize.sm, color: theme.ink);
    return GhAnimatedBox(
      duration: motion.css(GhDurations.interactive),
      color: theme.base,
      borderRadius: BorderRadius.circular(theme.radiusBtn),
      border: Border.all(color: border),
      boxShadow: focused ? GhShadows.focusRing(theme) : const [],
      padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(2.5)),
      child: Semantics(
        label: widget.label,
        textField: true,
        hint: widget.error,
        child: Material(
          type: MaterialType.transparency,
          child: TextField(
            onSubmitted: (_) => widget.onSubmit?.call(),
            onEditingComplete: () {},
            controller: _controller,
            focusNode: _node,
            autofocus: widget.autofocus,
            onChanged: widget.onChanged,
            style: style,
            maxLines: 1,
            cursorColor: theme.caret,
            cursorWidth: 1,
            decoration: InputDecoration.collapsed(
              hintText: widget.placeholder,
              hintStyle: style.copyWith(color: theme.placeholder),
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledGrid extends StatelessWidget {
  const _LabeledGrid({required this.label, required this.columns, required this.children});

  final String label;
  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final gap = theme.space(1.5);
    final rows = <Widget>[];
    for (var start = 0; start < children.length; start += columns) {
      final cells = <Widget>[];
      for (var i = 0; i < columns; i++) {
        if (i > 0) {
          cells.add(SizedBox(width: gap));
        }
        final index = start + i;
        cells.add(Expanded(child: AspectRatio(aspectRatio: 1, child: index < children.length ? children[index] : null)));
      }
      if (rows.isNotEmpty) {
        rows.add(SizedBox(height: gap));
      }
      rows.add(Row(children: cells));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.muted),
        ),
        SizedBox(height: theme.space(2)),
        Semantics(
          label: label,
          container: true,
          child: Column(mainAxisSize: MainAxisSize.min, children: rows),
        ),
      ],
    );
  }
}

class _IconOption extends StatelessWidget {
  const _IconOption({required this.iconKey, required this.active, required this.onPressed});

  final String iconKey;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusTile);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      semanticLabel: iconKey.replaceAll('_', ' '),
      checked: active,
      builder: (context, states) {
        final hover = states.active && !active;
        final Color foreground;
        final Color background;
        final Color border;
        if (active) {
          foreground = theme.accentBright;
          background = theme.accent.withValues(alpha: 0.1);
          border = theme.accent;
        } else {
          foreground = hover ? theme.ink : theme.muted;
          background = hover ? theme.overlay : theme.overlay.withValues(alpha: 0);
          border = theme.outline.withValues(alpha: 0.5);
        }
        return GhAnimatedBox(
          alignment: Alignment.center,
          color: background,
          borderRadius: radius,
          border: Border.all(color: border),
          boxShadow: hover ? GhShadows.hoverLift() : const [],
          child: GhIconMotionScale(
            states: states,
            child: GhAnimatedIcon(workspaceIcon(iconKey), color: foreground, size: theme.space(3.5)),
          ),
        );
      },
    );
  }
}

class _ColorOption extends StatelessWidget {
  const _ColorOption({required this.color, required this.active, required this.onPressed});

  final String color;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final motion = GhMotion.of(context);
    final radius = BorderRadius.circular(9999);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      semanticLabel: color,
      checked: active,
      builder: (context, states) {
        final hover = states.active && !active;
        return AnimatedScale(
          scale: hover ? 1.1 : 1,
          duration: motion.css(GhDurations.interactive),
          curve: GhCurves.outExpo,
          child: GhAnimatedBox(
            duration: motion.css(GhDurations.interactive),
            alignment: Alignment.center,
            color: colorFromHex(color),
            borderRadius: radius,
            boxShadow: active ? GhShadows.ring(theme.ink.withValues(alpha: 0.8), width: 2, offset: 2, offsetColor: theme.raised) : const [],
            child: active ? GhIcon(GhIcons.check, size: theme.space(2.5), color: Colors.white) : null,
          ),
        );
      },
    );
  }
}
