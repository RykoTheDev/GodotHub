import 'package:flutter/material.dart';

import '../design/design.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/feedback/confirm_dialog.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/reusables/labelled_field.dart';
import '../ui/reusables/modal_kit.dart';

final _invalidRefChars = RegExp(r'[\s~^:?*\[\\\x00-\x1f\x7f]');

bool isValidBranchName(String name) {
  if (name.isEmpty || name == '@') return false;
  if (_invalidRefChars.hasMatch(name)) return false;
  if (name.contains('..') || name.contains('@{') || name.contains('//')) return false;
  if (name.startsWith('/') || name.endsWith('/') || name.endsWith('.') || name.endsWith('.lock')) return false;
  return name.split('/').every((part) => part.isNotEmpty && !part.startsWith('.') && !part.endsWith('.lock'));
}

String? branchNameError(String name, {Iterable<String> existing = const []}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return ghTr('git:branch_name_required');
  if (!isValidBranchName(trimmed)) return ghTr('git:branch_name_invalid');
  if (existing.any((b) => b == trimmed)) return ghTr('git:branch_name_exists');
  return null;
}

class ProtectedBranchModal extends StatefulWidget {
  const ProtectedBranchModal({
    super.key,
    required this.branch,
    required this.suggestedBranch,
    required this.onCommitAnyway,
    required this.onCreatePullRequest,
    required this.onClose,
    this.existingBranches = const [],
  });

  final String branch;
  final String suggestedBranch;
  final VoidCallback onCommitAnyway;
  final Future<void> Function(String branch) onCreatePullRequest;
  final VoidCallback onClose;
  final List<String> existingBranches;

  @override
  State<ProtectedBranchModal> createState() => _ProtectedBranchModalState();
}

class _ProtectedBranchModalState extends State<ProtectedBranchModal> {
  late final TextEditingController _branch = TextEditingController(text: widget.suggestedBranch);
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _branch.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _branch.dispose();
    super.dispose();
  }

  String? get _nameError => branchNameError(_branch.text, existing: widget.existingBranches);

  Future<void> _submit() async {
    final name = _branch.text.trim();
    if (_nameError != null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onCreatePullRequest(name);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _busy = false;
        });
      }
    }
  }

  Future<void> _commitAnyway() async {
    final confirmed = await showGhConfirmDialog(
      context,
      title: ghTr('git:protected_branch_confirm_title', args: {'branch': widget.branch}),
      description: ghTr('git:protected_branch_confirm_desc', args: {'branch': widget.branch}),
      confirmLabel: ghTr('git:protected_branch_commit_anyway'),
      cancelLabel: ghTr('cancel'),
      variant: GhConfirmVariant.danger,
    );
    if (confirmed && mounted) widget.onCommitAnyway();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final nameError = _nameError;
    return GhModalShell(
      icon: GhIcon(GhIcons.lock, size: theme.space(5), color: theme.amber),
      title: ghTr('git:protected_branch_title'),
      maxWidth: GhModalWidth.lg,
      onClose: _busy ? null : widget.onClose,
      error: _error,
      footer: ghModalActions(
        leading: [
          GhButton(
            key: const ValueKey('protected-branch-commit-anyway'),
            onPressed: _busy ? null : _commitAnyway,
            icon: GhIcons.alertTriangle,
            label: ghTr('git:protected_branch_commit_anyway'),
            variant: GhButtonVariant.danger,
          ),
        ],
        trailing: [GhButton(onPressed: _busy ? null : widget.onClose, label: ghTr('cancel'))],
        primary: GhBusyButton(
          key: const ValueKey('protected-branch-create-pr'),
          onPressed: nameError != null || _busy ? null : _submit,
          busy: _busy,
          autofocus: true,
          paddingX: 4,
          label: _busy ? ghTr('git:protected_branch_creating_pr') : ghTr('git:protected_branch_create_pr'),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), 0, theme.space(6), theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(4),
          children: [
            Text(
              ghTr('git:protected_branch_desc', args: {'branch': widget.branch}),
              style: theme.text(size: GhTextSize.sm, color: theme.muted, lineHeight: 1.625),
            ),
            GhLabelledField(
              label: ghTr('git:protected_branch_new_label'),
              error: nameError,
              child: GhFieldInput(
                controller: _branch,
                enabled: !_busy,
                mono: true,
                textDirection: TextDirection.ltr,
                onSubmitted: (_) => _submit(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
