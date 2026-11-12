import 'package:flutter/material.dart';

import '../api/projects.dart';
import '../design/design.dart';
import '../src/rust/api/types.dart';
import '../ui/controls/text_input.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/reusables/modal_kit.dart';

String defaultDuplicateDest(String path) {
  final slash = path.lastIndexOf('/');
  final backslash = path.lastIndexOf(r'\');
  final cut = slash > backslash ? slash : backslash;
  return cut > 0 ? path.substring(0, cut) : path;
}

class DuplicateProjectModal extends StatefulWidget {
  const DuplicateProjectModal({super.key, required this.project, required this.onClose, required this.onDuplicated, this.pickFolder});

  final Project project;
  final VoidCallback onClose;
  final VoidCallback onDuplicated;
  final Future<String?> Function()? pickFolder;

  @override
  State<DuplicateProjectModal> createState() => _DuplicateProjectModalState();
}

class _DuplicateProjectModalState extends State<DuplicateProjectModal> {
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

  Future<void> _duplicate() async {
    final trimmed = _name.text.trim();
    if (trimmed.isEmpty || _busy) return;
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
    return GhModalShell(
      icon: GhIcon(GhIcons.copy, size: theme.space(5), color: theme.ink),
      title: tr.duplicate_project_title,
      maxWidth: GhModalWidth.md,
      onClose: widget.onClose,
      footer: [
        const Spacer(),
        GhButton(onPressed: widget.onClose, label: tr.cancel),
        GhButton(onPressed: _name.text.trim().isEmpty || _busy ? null : _duplicate, label: tr.duplicate, variant: GhButtonVariant.primary),
      ],
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
                  focusBorderColor: theme.accentDim,
                  placeholderColor: theme.muted,
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
                    GhPressable(
                      onPressed: _pick,
                      borderRadius: radius,
                      builder: (context, states) => GhAnimatedBox(
                        color: theme.raised,
                        borderRadius: radius,
                        border: Border.all(color: states.active ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
                        padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
                        child: Text(
                          tr.browse,
                          style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: states.active ? theme.ink : theme.muted),
                        ),
                      ),
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
