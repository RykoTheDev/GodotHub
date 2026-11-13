import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/design.dart';
import '../core/interaction.dart';
import 'pulse_dot.dart';
import '../core/i18n.dart';

const _confirmDuration = Duration(milliseconds: 1500);

class GhKeyRecorder extends StatefulWidget {
  const GhKeyRecorder({super.key, required this.value, required this.onChanged, this.onReset, this.isMac, this.defaultKey = 'p'});

  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback? onReset;
  final bool? isMac;
  final String defaultKey;

  @override
  State<GhKeyRecorder> createState() => _GhKeyRecorderState();
}

class _GhKeyRecorderState extends State<GhKeyRecorder> {
  bool _listening = false;
  bool _handlerAttached = false;
  String? _confirm;
  Timer? _confirmTimer;

  String get _mod => (widget.isMac ?? defaultTargetPlatform == TargetPlatform.macOS) ? '⌘' : 'Ctrl+';

  @override
  void dispose() {
    _confirmTimer?.cancel();
    _detach();
    super.dispose();
  }

  void _attach() {
    if (!_handlerAttached) {
      FocusManager.instance.addEarlyKeyEventHandler(_handleKey);
      _handlerAttached = true;
    }
  }

  void _detach() {
    if (_handlerAttached) {
      FocusManager.instance.removeEarlyKeyEventHandler(_handleKey);
      _handlerAttached = false;
    }
  }

  void _setListening(bool value) {
    if (!mounted || value == _listening) {
      return;
    }
    setState(() => _listening = value);
    if (value) {
      _attach();
    } else {
      _detach();
    }
  }

  void _showConfirm(String message) {
    setState(() => _confirm = message);
    _confirmTimer?.cancel();
    _confirmTimer = Timer(_confirmDuration, () {
      if (mounted) {
        setState(() => _confirm = null);
      }
    });
  }

  String? _capture(KeyEvent event) {
    final character = event.character;
    if (character != null && character.length == 1) {
      final code = character.codeUnitAt(0);
      if (code >= 0x20 && code != 0x7f) {
        return character == ' ' ? ' ' : character.toLowerCase();
      }
    }
    final label = event.logicalKey.keyLabel;
    if (label.length == 1) {
      return label == ' ' ? ' ' : label.toLowerCase();
    }
    return null;
  }

  KeyEventResult _handleKey(KeyEvent event) {
    if (!_listening || !mounted) {
      return KeyEventResult.ignored;
    }
    if (event is KeyUpEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _setListening(false);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      _setListening(false);
      return KeyEventResult.ignored;
    }
    final captured = _capture(event);
    if (captured == null) {
      return KeyEventResult.handled;
    }
    widget.onChanged(captured);
    _setListening(false);
    final label = captured == ' ' ? t.settings.key_space : captured.toUpperCase();
    _showConfirm('✓ $_mod$label');
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final mod = _mod;
    final value = widget.value;
    final tr = context.tr;
    final displayKey = value == ' ' ? tr.settings.key_space : (value.isNotEmpty ? value.toUpperCase() : tr.common.none);
    final onReset = widget.onReset;
    final kbdRadius = BorderRadius.circular(theme.rem(0.25));
    final paragraph = theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625);

    final header = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            tr.settings.palette_shortcut,
            style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.muted),
          ),
        ),
        if (value != widget.defaultKey && onReset != null)
          GhPressable(
            onPressed: () {
              onReset();
              _showConfirm('✓ $mod${widget.defaultKey.toUpperCase()}');
            },
            builder: (context, states) => GhAnimatedText(
              tr.settings.reset_to_default,
              style: theme.text(
                size: GhTextSize.x3s,
                weight: GhWeight.medium,
                color: states.hovered ? theme.accent : theme.muted.withValues(alpha: 0.6),
              ),
            ),
          ),
      ],
    );

    final hint = Padding(
      padding: EdgeInsets.only(top: theme.space(0.5)),
      child: Text.rich(
        TextSpan(
          style: paragraph,
          children: [
            TextSpan(text: '${tr.settings.keybind_instruction} ${tr.settings.press} '),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: theme.space(1), vertical: theme.space(0.5)),
                decoration: BoxDecoration(
                  color: theme.base,
                  borderRadius: kbdRadius,
                  border: Border.all(color: theme.line),
                ),
                child: Text(
                  'Esc',
                  style: theme.text(size: GhTextSize.x3s, mono: true, color: theme.muted, lineHeight: 1.625),
                ),
              ),
            ),
            TextSpan(text: ' ${tr.settings.to_cancel}.'),
          ],
        ),
      ),
    );

    final pressable = GhPressable(
      onPressed: () => _setListening(!_listening),
      borderRadius: BorderRadius.circular(theme.radiusItem),
      builder: (context, states) {
        final hover = states.hovered && !_listening;
        final List<Widget> children;
        if (_listening) {
          children = [
            GhPulseDot(color: theme.accent),
            SizedBox(width: theme.space(2)),
            GhAnimatedText(
              tr.settings.press_key,
              style: theme.text(size: GhTextSize.sm, weight: GhWeight.semibold, mono: true, color: theme.accentBright),
            ),
          ];
        } else {
          children = [
            Container(
              padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(0.5)),
              decoration: BoxDecoration(
                color: theme.base,
                borderRadius: kbdRadius,
                border: Border.all(color: theme.line.withValues(alpha: 0.6)),
              ),
              child: Text(
                '$mod$displayKey',
                style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, mono: true, color: theme.ink),
              ),
            ),
            SizedBox(width: theme.space(2)),
            Text(
              tr.settings.click_to_rebind,
              style: theme.text(size: GhTextSize.xs, mono: true, color: theme.muted),
            ),
          ];
        }
        return GhAnimatedBox(
          padding: EdgeInsets.symmetric(horizontal: theme.space(5), vertical: theme.space(3)),
          borderRadius: BorderRadius.circular(theme.radiusItem),
          color: _listening ? theme.accent.withValues(alpha: 0.1) : (hover ? theme.raised : theme.overlay),
          border: Border.all(color: _listening ? theme.accent : (hover ? theme.accentDim : theme.outline.withValues(alpha: 0.5))),
          boxShadow: hover ? GhShadows.hoverLift() : const [],
          child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: children),
        );
      },
    );
    final button = TapRegion(
      onTapOutside: (_) => _setListening(false),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (focused) {
          if (!focused) _setListening(false);
        },
        child: pressable,
      ),
    );

    final confirm = _confirm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        header,
        SizedBox(height: theme.space(2.5)),
        hint,
        SizedBox(height: theme.space(2.5)),
        Row(
          children: [
            button,
            if (confirm != null) ...[
              SizedBox(width: theme.space(3)),
              Row(
                key: ValueKey(confirm),
                mainAxisSize: MainAxisSize.min,
                children: [
                  GhIcon(GhIcons.check, size: theme.space(3), color: theme.accent),
                  SizedBox(width: theme.space(1)),
                  Text(
                    confirm,
                    style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.accent),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }
}
