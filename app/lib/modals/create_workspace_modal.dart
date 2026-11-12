import 'package:flutter/material.dart';

import '../design/design.dart';
import '../src/rust/api/types.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/shell/workspace_form.dart';

enum WorkspaceStart { copy, fresh }

class CreateWorkspaceModal extends StatefulWidget {
  const CreateWorkspaceModal({super.key, required this.takenNames, required this.onClose, required this.onCreate, this.copySource});

  final List<String> takenNames;
  final Workspace? copySource;
  final VoidCallback onClose;
  final Future<void> Function(GhWorkspaceDraft draft, WorkspaceStart start) onCreate;

  @override
  State<CreateWorkspaceModal> createState() => _CreateWorkspaceModalState();
}

class _CreateWorkspaceModalState extends State<CreateWorkspaceModal> {
  GhWorkspaceDraft _draft = GhWorkspaceDraft(name: '', icon: workspaceIconKeys.first, color: workspaceColorPresets.first);
  late WorkspaceStart _start = widget.copySource != null ? WorkspaceStart.copy : WorkspaceStart.fresh;
  bool _touched = false;
  String? _error;
  bool _busy = false;

  bool get _invalid => ghWorkspaceNameError(_draft.name, widget.takenNames) != null;

  Future<void> _submit() async {
    setState(() => _touched = true);
    if (_invalid || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onCreate(_draft.copyWith(name: _draft.name.trim()), _start);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr.common;
    final source = widget.copySource;
    final options = source == null
        ? const <_StartOption>[]
        : [
            _StartOption(
              WorkspaceStart.copy,
              GhIcons.copy,
              tr.workspace_start_copy.args({'name': source.name}),
              tr.workspace_start_copy_desc,
            ),
            _StartOption(WorkspaceStart.fresh, GhIcons.rocket, tr.workspace_start_fresh, tr.workspace_start_fresh_desc),
          ];
    return GhModalShell(
      icon: GhIcon(GhIcons.plus, size: theme.space(5), color: theme.accentBright),
      title: tr.create_workspace_title,
      maxWidth: GhModalWidth.lg,
      onClose: widget.onClose,
      showClose: false,
      footer: [
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: theme.space(2.5),
          children: [
            if (_error != null)
              Padding(
                padding: EdgeInsetsDirectional.only(end: theme.space(2)),
                child: Text(
                  _error!,
                  style: theme.text(size: GhTextSize.xs, color: theme.danger),
                ),
              ),
            GhButton(onPressed: widget.onClose, label: tr.cancel),
            GhButton(
              onPressed: _busy || (_touched && _invalid) ? null : _submit,
              label: _busy ? tr.creating : tr.create_workspace,
              variant: GhButtonVariant.primary,
              paddingX: 5,
              disabledOpacity: 0.5,
            ),
          ],
        ),
      ],
      child: Padding(
        padding: EdgeInsets.all(theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(6),
          children: [
            GhWorkspaceForm(
              value: _draft,
              onChanged: (next) => setState(() => _draft = next),
              takenNames: widget.takenNames,
              showErrors: _touched,
              autofocus: true,
              onSubmit: _submit,
              onNameBlur: () {
                if (_draft.name.isNotEmpty) setState(() => _touched = true);
              },
            ),
            if (options.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: theme.space(2),
                children: [
                  Text(
                    tr.workspace_start_label,
                    style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.muted),
                  ),
                  Semantics(
                    label: tr.workspace_start_label,
                    container: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: theme.space(1.5),
                      children: [
                        for (final option in options)
                          _StartOptionButton(
                            option: option,
                            active: _start == option.id,
                            onPressed: () => setState(() => _start = option.id),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StartOption {
  const _StartOption(this.id, this.icon, this.title, this.description);

  final WorkspaceStart id;
  final FaIconData icon;
  final String title;
  final String description;
}

class _StartOptionButton extends StatelessWidget {
  const _StartOptionButton({required this.option, required this.active, required this.onPressed});

  final _StartOption option;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      child: GhPressable(
        onPressed: onPressed,
        borderRadius: radius,
        checked: active,
        semanticLabel: option.title,
        builder: (context, states) {
          final hover = states.active && !active;
          return GhAnimatedBox(
            borderRadius: radius,
            color: active
                ? theme.accent.withValues(alpha: 0.1)
                : hover
                ? theme.overlay.withValues(alpha: 0.6)
                : theme.base.withValues(alpha: 0.4),
            border: Border.all(
              color: active
                  ? theme.accent
                  : hover
                  ? theme.accentDim
                  : theme.outline.withValues(alpha: 0.5),
            ),
            padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(3)),
            child: Row(
              spacing: theme.space(3),
              children: [
                GhAnimatedBox(
                  width: theme.space(8),
                  height: theme.space(8),
                  alignment: Alignment.center,
                  borderRadius: BorderRadius.circular(theme.radiusTile),
                  color: active ? theme.accent.withValues(alpha: 0.15) : theme.overlay,
                  child: GhIcon(option.icon, size: theme.space(3.5), color: active ? theme.accentBright : theme.muted),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.ink),
                      ),
                      Text(
                        option.description,
                        style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625),
                      ),
                    ],
                  ),
                ),
                GhAnimatedBox(
                  width: theme.space(4.5),
                  height: theme.space(4.5),
                  alignment: Alignment.center,
                  borderRadius: BorderRadius.circular(9999),
                  color: active ? theme.accent : Colors.transparent,
                  border: Border.all(color: active ? theme.accent : theme.outline.withValues(alpha: 0.6)),
                  child: active ? GhIcon(GhIcons.check, size: theme.space(2.5), color: Colors.white) : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
