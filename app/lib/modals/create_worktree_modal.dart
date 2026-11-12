import 'package:flutter/material.dart';

import '../api/git.dart';
import '../api/projects.dart';
import '../design/design.dart';
import '../logic/worktree_paths.dart';
import '../ui/controls/text_input.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/reusables/modal_kit.dart';

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

class _CreateWorktreeModalState extends State<CreateWorktreeModal> {
  late final TextEditingController _path = TextEditingController(text: defaultWorktreePath(widget.repositoryPath));
  final TextEditingController _branch = TextEditingController();
  final FocusNode _pathNode = FocusNode(debugLabel: 'CreateWorktreeModal path');
  bool _busy = false;
  bool _picking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _path.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _path.dispose();
    _branch.dispose();
    _pathNode.dispose();
    super.dispose();
  }

  bool get _locked => _busy || _picking;

  Future<void> _create() async {
    final path = _path.text.trim();
    if (path.isEmpty || _locked) return;
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

  Future<void> _browse() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final parent = await (widget.pickFolder ?? ProjectsApi.pickFolder)();
      if (parent != null && mounted) _path.text = worktreePathWithParent(_path.text, parent);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  GhTextInput _input(GhTheme theme, TextEditingController controller, {String? placeholder, bool mono = false, FocusNode? focusNode}) =>
      GhTextInput(
        controller: controller,
        focusNode: focusNode,
        autofocus: focusNode != null,
        enabled: !(mono ? _locked : _busy),
        mono: mono,
        textDirection: TextDirection.ltr,
        placeholder: placeholder,
        onSubmitted: (_) => _create(),
        background: theme.raised,
        borderColor: theme.line,
        focusBorderColor: theme.accentDim,
        placeholderColor: theme.muted.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(theme.radiusItem),
        padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(2.5)),
      );

  Widget _hint(GhTheme theme, String text) => Text(
    text,
    style: theme.text(size: GhTextSize.x2s, color: theme.muted.withValues(alpha: 0.7), lineHeight: 1.625),
  );

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return GhModalShell(
      icon: GhIcon(GhIcons.clone, size: theme.space(5), color: theme.ink),
      title: ghTr('git:add_worktree'),
      maxWidth: GhModalWidth.lg,
      onClose: _locked ? null : widget.onClose,
      initialFocus: _pathNode,
      footer: [
        const Spacer(),
        GhButton(onPressed: _locked ? null : widget.onClose, label: ghTr('cancel')),
        GhBusyButton(
          onPressed: _path.text.trim().isEmpty || _locked ? null : _create,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(2),
              children: [
                GhFieldLabel(ghTr('git:worktree_location_label')),
                Row(
                  spacing: theme.space(2),
                  children: [
                    Expanded(
                      child: _input(theme, _path, placeholder: ghTr('git:worktree_path_placeholder'), mono: true, focusNode: _pathNode),
                    ),
                    SizedBox(
                      width: theme.space(11),
                      child: GhOutlineAction(
                        onPressed: _locked ? null : _browse,
                        icon: _picking ? null : GhIcons.folder,
                        iconSize: 4,
                        busy: _picking,
                        tooltip: ghTr('git:worktree_browse_parent'),
                        semanticLabel: ghTr('git:worktree_browse_parent'),
                      ),
                    ),
                  ],
                ),
                _hint(theme, ghTr('git:worktree_location_hint')),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(2),
              children: [
                GhFieldLabel(ghTr('git:worktree_branch_label')),
                _input(theme, _branch, placeholder: ghTr('git:worktree_branch_placeholder')),
                _hint(theme, ghTr('git:worktree_branch_hint')),
              ],
            ),
            if (_error != null) GhAlertBox(tone: GhAlertTone.danger, text: _error, strong: true),
          ],
        ),
      ),
    );
  }
}
