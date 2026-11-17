import 'package:material_ui/material_ui.dart';

import '../design/design.dart';
import '../src/rust/api/types.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
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
    Widget delete = GhButton(
      key: const ValueKey('workspace-delete'),
      onPressed: widget.canDelete ? _confirmDelete : null,
      icon: GhIcons.trash,
      label: tr.delete,
      variant: GhButtonVariant.danger,
    );
    if (!widget.canDelete) {
      delete = GhTooltip(message: tr.cant_delete_only_workspace, child: delete);
    }
    return GhModalShell(
      icon: GhIcon(GhIcons.pencil, size: theme.space(5), color: theme.accentBright),
      title: tr.edit_workspace_title,
      maxWidth: GhModalWidth.lg,
      onClose: widget.onClose,
      showClose: false,
      error: _error,
      footer: ghModalActions(
        leading: [delete],
        trailing: [GhButton(onPressed: widget.onClose, label: tr.cancel)],
        primary: GhButton(
          onPressed: _busy || (_touched && _invalid) ? null : _submit,
          label: tr.save,
          variant: GhButtonVariant.primary,
          paddingX: 5,
          disabledOpacity: 0.5,
        ),
      ),
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
