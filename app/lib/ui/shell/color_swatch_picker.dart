import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../controls/hsv_color_picker.dart';
import '../core/interaction.dart';
import '../core/tooltip.dart';
import '../core/ui_settings.dart';
import '../overlays/dropdown.dart';
import '../core/i18n.dart';
import '../../motion/motion.dart';

final _hexPattern = RegExp(r'^#([0-9a-fA-F]{6})$');

bool ghIsValidHex(String hex) => _hexPattern.hasMatch(hex);

const _darkCheckPresets = {'#ffffff', '#f8f9fa', '#fafafa', '#fdf6e3', '#fbf1c7'};

class GhColorSwatchPicker extends StatefulWidget {
  const GhColorSwatchPicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.presets,
    this.label,
    this.trigger,
    this.presetsLabel,
    this.onOpenChange,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final List<String> presets;
  final String? label;
  final GhDropdownTriggerBuilder? trigger;
  final String? presetsLabel;
  final ValueChanged<bool>? onOpenChange;

  static const double panelMinWidth = 440;
  static const double wheelSize = 180;

  @override
  State<GhColorSwatchPicker> createState() => _GhColorSwatchPickerState();
}

class _GhColorSwatchPickerState extends State<GhColorSwatchPicker> {
  @override
  Widget build(BuildContext context) {
    return GhDropdown(
      align: GhSide.left,
      side: GhSide.bottom,
      onOpenChange: widget.onOpenChange,
      trigger: widget.trigger ?? _defaultTrigger,
      content: (context, close) => _SwatchPanel(
        value: widget.value,
        onChanged: widget.onChanged,
        presets: widget.presets,
        presetsLabel: widget.presetsLabel ?? context.tr.common.color_presets,
      ),
    );
  }

  Widget _defaultTrigger(BuildContext context, bool open, VoidCallback toggle) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    final button = GhPressable(
      onPressed: toggle,
      borderRadius: radius,
      expanded: open,
      semanticLabel: widget.label,
      semanticValue: widget.value.toLowerCase(),
      excludeChildSemantics: widget.label != null,
      builder: (context, states) => GhAnimatedBox(
        padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2.5)),
        color: theme.overlay,
        borderRadius: radius,
        border: Border.all(color: states.active ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
        child: Row(
          children: [
            _Swatch(color: widget.value, size: theme.space(8), radius: theme.radiusTile),
            SizedBox(width: theme.space(3)),
            Expanded(
              child: Text(
                textAlign: TextAlign.end,
                widget.value.toLowerCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.text(size: GhTextSize.xs, mono: true, color: theme.ink),
              ),
            ),
          ],
        ),
      ),
    );
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.label != null) ...[
            ExcludeSemantics(
              child: Text(
                widget.label!,
                style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.muted),
              ),
            ),
            SizedBox(height: theme.space(2)),
          ],
          button,
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.size, required this.radius});

  final String color;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final borderRadius = BorderRadius.circular(radius);
    return CustomPaint(
      foregroundPainter: InsetShadowPainter(borderRadius: borderRadius),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: ghIsValidHex(color) ? colorFromHex(color) : Colors.transparent,
          borderRadius: borderRadius,
          border: Border.all(color: theme.line),
        ),
      ),
    );
  }
}

class _SwatchPanel extends StatefulWidget {
  const _SwatchPanel({required this.value, required this.onChanged, required this.presets, required this.presetsLabel});

  final String value;
  final ValueChanged<String> onChanged;
  final List<String> presets;
  final String presetsLabel;

  @override
  State<_SwatchPanel> createState() => _SwatchPanelState();
}

class _SwatchPanelState extends State<_SwatchPanel> {
  late final TextEditingController _hex = TextEditingController(text: widget.value);
  final FocusNode _hexNode = FocusNode(debugLabel: 'GhColorSwatchPicker hex');
  bool _hexFocused = false;

  @override
  void initState() {
    super.initState();
    _hexNode.addListener(_onHexFocus);
  }

  @override
  void didUpdateWidget(_SwatchPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _setDraft(widget.value);
    }
  }

  @override
  void dispose() {
    _hexNode.removeListener(_onHexFocus);
    _hexNode.dispose();
    _hex.dispose();
    super.dispose();
  }

  void _setDraft(String text) {
    if (_hex.text == text) {
      return;
    }
    _hex.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _onHexFocus() {
    final has = _hexNode.hasFocus;
    if (has != _hexFocused) {
      setState(() => _hexFocused = has);
    }
    if (!has && !ghIsValidHex(_hex.text)) {
      _setDraft(widget.value);
    }
  }

  void _onHexChanged(String raw) {
    final next = raw.startsWith('#') ? raw : '#$raw';
    if (next != raw) {
      _setDraft(next);
    }
    if (ghIsValidHex(next)) {
      widget.onChanged(next);
    }
  }

  void _pick(String hex) {
    widget.onChanged(hex);
    _setDraft(hex);
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final motion = GhMotion.of(context);
    final hexStyle = theme.text(size: GhTextSize.xs, mono: true, color: theme.ink);
    final left = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GhHsvColorPicker(value: widget.value, onChanged: _pick, size: GhColorSwatchPicker.wheelSize),
        SizedBox(height: theme.space(3)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Swatch(color: widget.value, size: theme.space(7), radius: theme.radiusItem),
            SizedBox(width: theme.space(2)),
            GhAnimatedBox(
              duration: motion.css(GhDurations.interactive),
              width: theme.space(20),
              padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(2)),
              color: theme.overlay,
              borderRadius: BorderRadius.circular(theme.radiusItem),
              border: Border.all(color: _hexFocused ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
              boxShadow: const [],
              child: Material(
                type: MaterialType.transparency,
                child: TextField(
                  controller: _hex,
                  focusNode: _hexNode,
                  onChanged: _onHexChanged,
                  onEditingComplete: () {},
                  style: hexStyle,
                  maxLines: 1,
                  autocorrect: false,
                  enableSuggestions: false,
                  cursorColor: theme.caret,
                  cursorWidth: 1,
                  decoration: InputDecoration.collapsed(
                    hintText: '#000000',
                    hintStyle: hexStyle.copyWith(color: theme.placeholder),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
    final presetCells = <Widget>[];
    for (final preset in widget.presets) {
      presetCells.add(
        _PresetSwatch(preset: preset, selected: preset.toLowerCase() == widget.value.toLowerCase(), onPressed: () => _pick(preset)),
      );
    }
    final gap = theme.space(1.5);
    final rows = <Widget>[];
    for (var start = 0; start < presetCells.length; start += 6) {
      final cells = <Widget>[];
      for (var i = start; i < start + 6 && i < presetCells.length; i++) {
        if (i > start) {
          cells.add(SizedBox(width: gap));
        }
        cells.add(presetCells[i]);
      }
      if (rows.isNotEmpty) {
        rows.add(SizedBox(height: gap));
      }
      rows.add(Row(mainAxisSize: MainAxisSize.min, children: cells));
    }
    final right = Container(
      padding: EdgeInsetsDirectional.only(start: theme.space(3)),
      decoration: BoxDecoration(
        border: BorderDirectional(start: BorderSide(color: theme.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.presetsLabel.toUpperCase(),
            style: theme.text(
              size: GhTextSize.x3s,
              weight: GhWeight.medium,
              color: theme.muted.withValues(alpha: 0.6),
              letterSpacingEm: 0.05,
            ),
          ),
          SizedBox(height: theme.space(2)),
          ...rows,
        ],
      ),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: GhColorSwatchPicker.panelMinWidth),
      child: Padding(
        padding: EdgeInsets.all(theme.space(3)),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(alignment: AlignmentDirectional.topStart, child: left),
              SizedBox(width: theme.space(3)),
              right,
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetSwatch extends StatelessWidget {
  const _PresetSwatch({required this.preset, required this.selected, required this.onPressed});

  final String preset;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final motion = GhMotion.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhTooltip(
      message: preset,
      child: GhPressable(
        onPressed: onPressed,
        borderRadius: radius,
        focusStyle: GhFocusStyle.outline,
        semanticLabel: preset,
        selected: selected,
        builder: (context, states) {
          final hover = states.active;
          return AnimatedScale(
            scale: selected ? 1.1 : 1,
            duration: motion.css(GhDurations.interactive),
            curve: GhCurves.outExpo,
            child: GhAnimatedBox(
              duration: motion.css(GhDurations.interactive),
              width: theme.space(7),
              height: theme.space(7),
              alignment: Alignment.center,
              color: colorFromHex(preset),
              borderRadius: radius,
              border: Border.all(
                color: selected
                    ? colorFromHex(preset)
                    : hover
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.2),
              ),
              boxShadow: selected ? GhShadows.ring(theme.ink, width: 2, offset: 1, offsetColor: theme.surface) : const [],
              child: selected
                  ? GhIcon(GhIcons.check, size: theme.space(2.5), color: _darkCheckPresets.contains(preset) ? Colors.black : Colors.white)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
