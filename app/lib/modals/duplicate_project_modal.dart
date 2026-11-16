import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/projects.dart';
import '../design/design.dart';
import '../logic/naming_convention.dart';
import '../src/rust/api/types.dart';
import '../state/settings.dart';
import '../ui/controls/text_input.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/reusables/modal_kit.dart';

String defaultDuplicateDest(String path) {
  final slash = path.lastIndexOf('/');
  final backslash = path.lastIndexOf(r'\');
  final cut = slash > backslash ? slash : backslash;
  return cut > 0 ? path.substring(0, cut) : path;
}

class DuplicateProjectModal extends ConsumerStatefulWidget {
  const DuplicateProjectModal({super.key, required this.project, required this.onClose, required this.onDuplicated, this.pickFolder});

  final Project project;
  final VoidCallback onClose;
  final VoidCallback onDuplicated;
  final Future<String?> Function()? pickFolder;

  @override
  ConsumerState<DuplicateProjectModal> createState() => _DuplicateProjectModalState();
}

class _DuplicateProjectModalState extends ConsumerState<DuplicateProjectModal> {
  late final TextEditingController _name = TextEditingController(text: '${widget.project.name} ${ghTr('copy_suffix')}');
  late String _dest = defaultDuplicateDest(widget.project.path);
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final picked = await (widget.pickFolder ?? ProjectsApi.pickFolder)();
      if (picked != null && mounted) setState(() => _dest = picked);
    } catch (e) {
      ghToasts.pushToast(GhToastType.error, '$e');
    }
  }

  String get _folderName =>
      applyNamingConvention(_name.text.trim(), NamingConvention.parse(ref.read(settingsProvider).value?.directoryNamingConvention ?? ''));

  String? get _nameError {
    final trimmed = _name.text.trim();
    if (trimmed.isEmpty) return null;
    final folder = _folderName;
    if (!isValidFolderName(folder)) return ghTr('folder_name_invalid_chars');
    if (Directory('$_dest${Platform.pathSeparator}$folder').existsSync()) return ghTr('duplicate_folder_exists');
    return null;
  }

  Future<void> _duplicate() async {
    final trimmed = _name.text.trim();
    if (trimmed.isEmpty || _busy || _nameError != null) return;
    setState(() => _busy = true);
    try {
      await ProjectsApi.duplicate(widget.project.id, trimmed, _dest);
      ghToasts.pushToast(GhToastType.success, ghTr('project_duplicated'));
      widget.onDuplicated();
      widget.onClose();
    } catch (e) {
      ghToasts.pushToast(GhToastType.error, '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr.common;
    final radius = BorderRadius.circular(theme.radiusItem);
    ref.watch(settingsProvider);
    final nameError = _nameError;
    final canDuplicate = _name.text.trim().isNotEmpty && nameError == null && !_busy;
    return GhModalShell(
      icon: GhIcon(GhIcons.copy, size: theme.space(5), color: theme.ink),
      title: tr.duplicate_project_title,
      maxWidth: GhModalWidth.md,
      onClose: widget.onClose,
      footer: ghModalActions(
        trailing: [GhButton(onPressed: widget.onClose, label: tr.cancel)],
        primary: GhBusyButton(onPressed: canDuplicate ? _duplicate : null, busy: _busy, label: tr.duplicate),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), 0, theme.space(6), theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(4),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(2),
              children: [
                GhFieldLabel(tr.new_project_name),
                GhTextInput(
                  controller: _name,
                  placeholder: tr.new_project_name,
                  background: theme.base,
                  borderColor: nameError != null ? theme.danger : null,
                  focusBorderColor: nameError != null ? theme.danger : theme.accentDim,
                  placeholderColor: theme.muted,
                ),
                if (nameError != null)
                  Text(
                    nameError,
                    style: theme.text(size: GhTextSize.x2s, color: theme.danger, lineHeight: 1.5),
                  )
                else if (_name.text.trim().isNotEmpty)
                  Text(
                    tr.folder_name_preview.args({'name': _folderName}),
                    style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.5),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(2),
              children: [
                GhFieldLabel(tr.destination_folder),
                Row(
                  spacing: theme.space(2),
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
                        decoration: BoxDecoration(
                          color: theme.base,
                          borderRadius: radius,
                          border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          spacing: theme.space(2),
                          children: [
                            GhIcon(GhIcons.folder, size: theme.space(3.5), color: theme.muted),
                            Expanded(
                              child: Text(
                                _dest,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.text(size: GhTextSize.xs, mono: true, color: theme.ink),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GhButton(
                      onPressed: _pick,
                      label: tr.browse,
                      variant: GhButtonVariant.outline,
                      size: GhTextSize.xs,
                      paddingX: 3,
                      paddingY: 2,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
