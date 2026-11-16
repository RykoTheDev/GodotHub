import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/projects.dart';
import '../design/design.dart';
import '../logic/naming_convention.dart';
import '../src/rust/api/types.dart';
import '../state/settings.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/reusables/labelled_field.dart';
import '../ui/reusables/modal_kit.dart';
import '../ui/reusables/path_field.dart';

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
  late final TextEditingController _destination = TextEditingController(text: defaultDuplicateDest(widget.project.path));

  /// The last destination the user committed; the name check only touches
  /// the disk under this folder, never under half-typed text.
  late String _checkedDest = ghNormalizePath(_destination.text);
  bool _busy = false;
  String? _destError;

  String get _dest => ghNormalizePath(_destination.text);

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    _destination.addListener(() => setState(() => _destError = null));
  }

  @override
  void dispose() {
    _name.dispose();
    _destination.dispose();
    super.dispose();
  }

  String get _folderName =>
      applyNamingConvention(_name.text.trim(), NamingConvention.parse(ref.read(settingsProvider).value?.directoryNamingConvention ?? ''));

  String? get _nameError {
    final trimmed = _name.text.trim();
    if (trimmed.isEmpty) return null;
    final folder = _folderName;
    if (!isValidFolderName(folder)) return ghTr('folder_name_invalid_chars');
    if (_dest.isNotEmpty && _dest == _checkedDest && Directory('$_dest${Platform.pathSeparator}$folder').existsSync()) {
      return ghTr('duplicate_folder_exists');
    }
    return null;
  }

  Future<void> _duplicate() async {
    final trimmed = _name.text.trim();
    if (trimmed.isEmpty || _busy || _nameError != null) return;
    final destError = ghPathError(_dest, GhPathKind.folder);
    if (destError != null) {
      setState(() => _destError = destError);
      return;
    }
    setState(() => _checkedDest = _dest);
    if (_nameError != null) return;
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
    ref.watch(settingsProvider);
    final nameError = _nameError;
    final canDuplicate = _name.text.trim().isNotEmpty && _dest.isNotEmpty && nameError == null && !_busy;
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
            GhLabelledField(
              label: tr.new_project_name,
              error: nameError,
              hint: _name.text.trim().isNotEmpty ? tr.folder_name_preview.args({'name': _folderName}) : null,
              child: GhFieldInput(controller: _name, placeholder: tr.new_project_name),
            ),
            GhPathField(
              key: const ValueKey('duplicate-destination'),
              controller: _destination,
              kind: GhPathKind.folder,
              label: tr.destination_folder,
              error: _destError,
              enabled: !_busy,
              pick: widget.pickFolder,
              onCommitted: (path) => setState(() => _checkedDest = path),
            ),
          ],
        ),
      ),
    );
  }
}
