import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/projects.dart';
import '../design/design.dart';
import '../src/rust/api/types.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/core/tooltip.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/reusables/modal_kit.dart';

String _tv(String key, {num? count, Map<String, Object?> args = const {}}) => ghTr('versions:$key', count: count, args: args);

class CopyButton extends StatefulWidget {
  const CopyButton({super.key, required this.value, required this.semanticLabel, this.compact = false});

  final String value;
  final String semanticLabel;
  final bool compact;

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool _copied = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.value));
      if (!mounted) return;
      setState(() => _copied = true);
      _reset?.cancel();
      _reset = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _copied = false);
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhPressable(
      onPressed: _copy,
      semanticLabel: widget.semanticLabel,
      borderRadius: radius,
      builder: (context, states) => GhAnimatedBox(
        color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
        borderRadius: radius,
        border: Border.all(color: states.active ? theme.accentDim : theme.line),
        padding: EdgeInsets.symmetric(horizontal: theme.space(widget.compact ? 2.5 : 3), vertical: theme.space(1.5)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: theme.space(1.5),
          children: [
            GhIcon(
              _copied ? GhIcons.check : GhIcons.copy,
              size: theme.space(3.5),
              color: _copied ? theme.mint : (states.active ? theme.ink : theme.muted),
            ),
            Text(
              _copied ? _tv('current_copied') : _tv('current_copy'),
              style: theme.text(size: GhTextSize.xs, color: states.active ? theme.ink : theme.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class OutlineIconButton extends StatelessWidget {
  const OutlineIconButton({super.key, required this.label, required this.icon, required this.onPressed});

  final String label;
  final FaIconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      builder: (context, states) => GhAnimatedBox(
        color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
        borderRadius: radius,
        border: Border.all(color: states.active ? theme.accentDim : theme.line),
        padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(2.5)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: theme.space(2),
          children: [
            GhIcon(icon, size: theme.space(4), color: states.active ? theme.ink : theme.muted),
            Text(
              label,
              style: theme.text(size: GhTextSize.sm, color: states.active ? theme.ink : theme.muted),
            ),
          ],
        ),
      ),
    );
  }
}

void openFolderOrToast(String path) => ProjectsApi.openFolder(path).catchError((Object e) => ghToasts.pushToast(GhToastType.error, '$e'));

class CurrentVersionModal extends StatelessWidget {
  const CurrentVersionModal({super.key, required this.info, required this.onClose});

  final CurrentVersionInfo info;
  final VoidCallback onClose;

  Widget _row(GhTheme theme, String target, String label, String value) => Container(
    padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2.5)),
    decoration: BoxDecoration(
      color: theme.overlay,
      borderRadius: BorderRadius.circular(theme.radiusItem),
      border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
    ),
    child: Row(
      spacing: theme.space(3),
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: theme.text(size: GhTextSize.x2s, weight: GhWeight.semibold, color: theme.muted, letterSpacingEm: 0.05),
              ),
              Padding(
                padding: EdgeInsets.only(top: theme.space(0.5)),
                child: GhTooltip(
                  message: value,
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.text(size: GhTextSize.xs, mono: true, color: theme.ink),
                  ),
                ),
              ),
            ],
          ),
        ),
        CopyButton(value: value, semanticLabel: _tv('current_copy_$target')),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final note = theme.text(size: GhTextSize.xs, color: theme.muted, lineHeight: 1.625);
    return GhModalShell(
      icon: GhIcon(GhIcons.pin, size: theme.space(5), color: theme.accentBright),
      title: _tv('current_set_title'),
      maxWidth: GhModalWidth.xl,
      onClose: onClose,
      footer: [
        OutlineIconButton(
          label: _tv('current_open_folder'),
          icon: GhIcons.externalLink,
          onPressed: () => openFolderOrToast(info.aliasesDir),
        ),
        const Spacer(),
        GhButton(onPressed: onClose, label: ghTr('close'), variant: GhButtonVariant.primary, weight: GhWeight.medium),
      ],
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), 0, theme.space(6), theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(3),
          children: [
            _row(theme, 'alias', _tv('cleanup_alias_badge'), info.aliasPath),
            _row(theme, 'dir', _tv('current_dir_label'), info.aliasesDir),
            Text(_tv('current_path_hint'), style: note),
            if (info.method == 'shim') Text(_tv('current_shim_note'), style: note.copyWith(color: theme.amber)),
          ],
        ),
      ),
    );
  }
}

class ModalSpinnerLabel extends StatelessWidget {
  const ModalSpinnerLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: theme.space(3),
      children: [
        GhSpinnerIcon(size: 4, color: theme.muted),
        Text(
          label,
          style: theme.text(size: GhTextSize.sm, color: theme.muted),
        ),
      ],
    );
  }
}
