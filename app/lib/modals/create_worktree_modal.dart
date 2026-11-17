import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../api/git.dart';
import '../api/projects.dart';
import '../design/design.dart';
import '../logic/worktree_paths.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/reusables/labelled_field.dart';
import '../ui/reusables/modal_kit.dart';
import '../ui/reusables/path_field.dart';

String worktreePathWithParent(String current, String parent) {
  final folder = current.replaceAll('\\', '/').replaceFirst(RegExp(r'/+$'), '').split('/').last;
  return '${parent.replaceFirst(RegExp(r'[\\/]+$'), '')}/${folder.isEmpty ? 'worktree' : folder}';
}

class CreateWorktreeModal extends StatefulWidget {
  const CreateWorktreeModal({super.key, required this.repositoryPath, required this.onClose, required this.onCreated, this.pickFolder});

  final String repositoryPath;
  final VoidCallback onClose;
  final VoidCallback onCreated;
  final Future<String?> Function()? pickFolder;

  @override
  State<CreateWorktreeModal> createState() => _CreateWorktreeModalState();
}

/// A worktree target may be new or an empty folder; git creates missing
/// parents, so only an empty value or an existing file is rejected here.
String? worktreePathError(String raw) {
  final path = ghNormalizePath(raw);
  if (path.isEmpty) return ghTr('path_error_required');
  if (FileSystemEntity.typeSync(path) == FileSystemEntityType.file) return ghTr('path_error_not_a_folder');
  return null;
}

class _CreateWorktreeModalState extends State<CreateWorktreeModal> {
  late final TextEditingController _path = TextEditingController(text: defaultWorktreePath(widget.repositoryPath));
  final TextEditingController _branch = TextEditingController();
  final FocusNode _pathNode = FocusNode(debugLabel: 'CreateWorktreeModal path');
  bool _busy = false;
  String? _error;
  String? _pathError;

  @override
  void initState() {
    super.initState();
    _path.addListener(() => setState(() => _pathError = null));
  }

  @override
  void dispose() {
    _path.dispose();
    _branch.dispose();
    _pathNode.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final path = ghNormalizePath(_path.text);
    if (path.isEmpty || _busy) return;
    final pathError = worktreePathError(path);
    if (pathError != null) {
      setState(() => _pathError = pathError);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final branch = _branch.text.trim();
      await GitApi.worktreeAdd(widget.repositoryPath, path, branch.isEmpty ? null : branch);
      widget.onCreated();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _busy = false;
        });
      }
    }
  }

  /// Browse picks the parent folder; the worktree folder name is kept.
  Future<String?> _pickParent() async {
    if (mounted) setState(() => _error = null);
    final parent = await (widget.pickFolder ?? ProjectsApi.pickFolder)();
    return parent == null ? null : worktreePathWithParent(_path.text, parent);
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return GhModalShell(
      icon: GhIcon(GhIcons.clone, size: theme.space(5), color: theme.ink),
      title: ghTr('git:add_worktree'),
      maxWidth: GhModalWidth.lg,
      onClose: _busy ? null : widget.onClose,
      initialFocus: _pathNode,
      footer: [
        const Spacer(),
        GhButton(onPressed: _busy ? null : widget.onClose, label: ghTr('cancel')),
        GhBusyButton(
          onPressed: _path.text.trim().isEmpty || _busy ? null : _create,
          busy: _busy,
          paddingX: 4,
          label: _busy ? ghTr('creating') : ghTr('git:add_worktree_btn'),
        ),
      ],
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), 0, theme.space(6), theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(5),
          children: [
            GhPathField(
              key: const ValueKey('worktree-path'),
              controller: _path,
              focusNode: _pathNode,
              autofocus: true,
              kind: GhPathKind.folder,
              validator: worktreePathError,
              pick: _pickParent,
              onPickError: (e) => setState(() => _error = '$e'),
              label: ghTr('git:worktree_location_label'),
              hint: ghTr('git:worktree_location_hint'),
              error: _pathError,
              placeholder: ghTr('git:worktree_path_placeholder'),
              browseLabel: ghTr('git:worktree_browse_parent'),
              compactBrowse: true,
              enabled: !_busy,
              onSubmitted: (_) => _create(),
            ),
            GhLabelledField(
              label: ghTr('git:worktree_branch_label'),
              hint: ghTr('git:worktree_branch_hint'),
              child: GhFieldInput(
                controller: _branch,
                enabled: !_busy,
                textDirection: TextDirection.ltr,
                placeholder: ghTr('git:worktree_branch_placeholder'),
                onSubmitted: (_) => _create(),
              ),
            ),
            if (_error != null) GhAlertBox(tone: GhAlertTone.danger, text: _error, strong: true),
          ],
        ),
      ),
    );
  }
}
