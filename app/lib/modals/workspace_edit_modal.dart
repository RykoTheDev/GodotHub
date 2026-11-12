import 'package:flutter/material.dart';

import '../design/design.dart';
import '../src/rust/api/types.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/core/tooltip.dart';
import '../ui/feedback/confirm_dialog.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/shell/workspace_form.dart';

class WorkspaceEditModal extends StatefulWidget {
  const WorkspaceEditModal({
    super.key,
    required this.workspace,
    required this.takenNames,
    required this.canDelete,
    required this.onClose,
    required this.onSave,
    required this.onDelete,
  });

  final Workspace workspace;
  final List<String> takenNames;
  final bool canDelete;
  final VoidCallback onClose;
  final Future<void> Function(String name, String icon, String color) onSave;
  final Future<void> Function() onDelete;

  @override
  State<WorkspaceEditModal> createState() => _WorkspaceEditModalState();
}

class _WorkspaceEditModalState extends State<WorkspaceEditModal> {
  late GhWorkspaceDraft _draft = GhWorkspaceDraft(name: widget.workspace.name, icon: widget.workspace.icon, color: widget.workspace.color);
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
      await widget.onSave(_draft.name.trim(), _draft.icon, _draft.color);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete() async {
    final tr = context.tr.common;
    final confirmed = await showGhConfirmDialog(
      context,
      title: tr.delete_workspace_title,
      description: tr.delete_workspace_desc.args({'name': widget.workspace.name}),
      confirmLabel: tr.delete,
      variant: GhConfirmVariant.danger,
    );
    if (confirmed) widget.onDelete().ignore();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr.common;
    Widget delete = _DeleteButton(label: tr.delete, onPressed: widget.canDelete ? _confirmDelete : null);
    if (!widget.canDelete) {
      delete = GhTooltip(message: tr.cant_delete_only_workspace, child: delete);
    }
    return GhModalShell(
      icon: GhIcon(GhIcons.pencil, size: theme.space(5), color: theme.accentBright),
      title: tr.edit_workspace_title,
      maxWidth: GhModalWidth.lg,
      onClose: widget.onClose,
      showClose: false,
      footer: [
        delete,
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
              label: tr.save,
              variant: GhButtonVariant.primary,
              paddingX: 5,
              disabledOpacity: 0.5,
            ),
          ],
        ),
      ],
      child: Padding(
        padding: EdgeInsets.all(theme.space(6)),
        child: GhWorkspaceForm(
          value: _draft,
          onChanged: (next) => setState(() => _draft = next),
          takenNames: widget.takenNames,
          showErrors: _touched,
          autofocus: true,
          onSubmit: _submit,
          onNameBlur: () => setState(() => _touched = true),
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      rippleColor: theme.danger,
      builder: (context, states) {
        final hover = states.active;
        return GhAnimatedBox(
          borderRadius: radius,
          color: hover ? theme.danger.withValues(alpha: 0.05) : theme.danger.withValues(alpha: 0),
          padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(2.5)),
          child: Text(
            label,
            style: theme.text(size: GhTextSize.sm, color: hover ? theme.danger : theme.muted),
          ),
        );
      },
    );
  }
}
