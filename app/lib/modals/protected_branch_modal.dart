import 'package:flutter/material.dart';

import '../design/design.dart';
import '../ui/controls/text_input.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/reusables/modal_kit.dart';

class ProtectedBranchModal extends StatefulWidget {
  const ProtectedBranchModal({
    super.key,
    required this.branch,
    required this.suggestedBranch,
    required this.onCommitAnyway,
    required this.onCreatePullRequest,
    required this.onClose,
  });

  final String branch;
  final String suggestedBranch;
  final VoidCallback onCommitAnyway;
  final Future<void> Function(String branch) onCreatePullRequest;
  final VoidCallback onClose;

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

  Future<void> _submit() async {
    final name = _branch.text.trim();
    if (name.isEmpty || _busy) return;
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

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return GhModalShell(
      icon: GhIcon(GhIcons.lock, size: theme.space(5), color: theme.amber),
      title: ghTr('git:protected_branch_title'),
      maxWidth: GhModalWidth.lg,
      onClose: _busy ? null : widget.onClose,
      footer: [
        const Spacer(),
        GhButton(onPressed: _busy ? null : widget.onClose, label: ghTr('cancel')),
        GhButton(
          onPressed: _busy ? null : widget.onCommitAnyway,
          label: ghTr('git:protected_branch_commit_anyway'),
          variant: GhButtonVariant.outline,
        ),
        GhBusyButton(
          onPressed: _branch.text.trim().isEmpty || _busy ? null : _submit,
          busy: _busy,
          autofocus: true,
          paddingX: 4,
          label: _busy ? ghTr('git:protected_branch_creating_pr') : ghTr('git:protected_branch_create_pr'),
        ),
      ],
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(2),
              children: [
                GhFieldLabel(ghTr('git:protected_branch_new_label')),
                GhTextInput(
                  controller: _branch,
                  enabled: !_busy,
                  mono: true,
                  textDirection: TextDirection.ltr,
                  onSubmitted: (_) => _submit(),
                  background: theme.raised,
                  borderColor: theme.line,
                  focusBorderColor: theme.accentDim,
                  borderRadius: BorderRadius.circular(theme.radiusItem),
                  padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(2.5)),
                ),
              ],
            ),
            if (_error != null) GhAlertBox(tone: GhAlertTone.danger, text: _error, strong: true),
          ],
        ),
      ),
    );
  }
}
