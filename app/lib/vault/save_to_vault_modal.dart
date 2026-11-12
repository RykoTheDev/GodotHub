import 'package:flutter/material.dart';

import '../api/vault.dart';
import '../design/design.dart';
import '../src/rust/api/types.dart';
import '../ui/controls/dashed_box.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import 'tag_editor.dart';
import 'vault_modal_parts.dart';
import 'vault_source_section.dart';

class _SourceDraft {
  _SourceDraft(this.key, this.projectId, [Set<String>? selected]) : selected = selected ?? {};

  final int key;
  final String? projectId;
  final Set<String> selected;
}

class SaveToVaultModal extends StatefulWidget {
  const SaveToVaultModal({super.key, required this.projects, this.initialProjectId, required this.onClose, required this.onSaved});

  final List<Project> projects;
  final String? initialProjectId;
  final VoidCallback onClose;
  final VoidCallback onSaved;

  @override
  State<SaveToVaultModal> createState() => _SaveToVaultModalState();
}

class _SaveToVaultModalState extends State<SaveToVaultModal> {
  late List<_SourceDraft> _sources = [_SourceDraft(0, widget.initialProjectId)];
  int _nextKey = 1;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _desc = TextEditingController();
  List<String> _tags = const [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _projectChange(int key, String id) => setState(() {
    _sources = [for (final s in _sources) s.key == key ? _SourceDraft(s.key, id) : s];
  });

  void _toggle(int key, String rel) => setState(() {
    _sources = [
      for (final s in _sources)
        if (s.key != key)
          s
        else
          _SourceDraft(s.key, s.projectId, () {
            final next = {...s.selected};
            if (!next.remove(rel)) {
              next.removeWhere((existing) => existing == rel || existing.startsWith('$rel/'));
              next.add(rel);
            }
            return next;
          }()),
    ];
  });

  void _addSource() => setState(() {
    _sources = [..._sources, _SourceDraft(_nextKey, null)];
    _nextKey++;
  });

  void _removeSource(int key) => setState(() => _sources = _sources.where((s) => s.key != key).toList());

  List<VaultSaveSource> get _payload => [
    for (final s in _sources)
      if (s.projectId != null && s.selected.isNotEmpty) VaultSaveSource(projectId: s.projectId!, paths: s.selected.toList()),
  ];

  bool get _canSave => _name.text.trim().isNotEmpty && _payload.isNotEmpty && !_busy;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _busy = true);
    try {
      await VaultApi.saveToVault(_name.text.trim(), _desc.text.trim(), _tags, _payload);
      ghToasts.pushToast(GhToastType.success, ghTr('vault_saved_toast'));
      widget.onSaved();
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
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhModalShell(
      icon: GhIcon(GhIcons.briefcase, size: theme.space(4), color: theme.ink),
      title: ghTr('vault_save_title'),
      maxWidth: GhModalWidth.lg,
      onClose: widget.onClose,
      footer: [
        VaultCancelButton(onPressed: widget.onClose),
        Expanded(
          child: VaultPrimaryButton(label: _busy ? ghTr('saving') : ghTr('vault_save_btn'), onPressed: _canSave ? _save : null),
        ),
      ],
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), theme.space(4), theme.space(6), theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(4),
          children: [
            VaultField(
              label: ghTr('vault_source_project_label'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: theme.space(2),
                children: [
                  for (final (index, source) in _sources.indexed)
                    VaultSourceSection(
                      key: ValueKey(source.key),
                      projects: widget.projects,
                      projectId: source.projectId,
                      selected: source.selected,
                      index: index,
                      canRemove: _sources.length > 1,
                      onProjectChange: (id) => _projectChange(source.key, id),
                      onToggle: (rel) => _toggle(source.key, rel),
                      onRemove: () => _removeSource(source.key),
                    ),
                  GhPressable(
                    onPressed: _addSource,
                    borderRadius: radius,
                    builder: (context, states) => GhDashedBox(
                      color: states.active ? theme.accentDim : theme.outline.withValues(alpha: 0.6),
                      radius: radius,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: theme.space(1.5),
                          children: [
                            GhIcon(GhIcons.plus, size: theme.space(3.5), color: states.active ? theme.ink : theme.muted),
                            Text(
                              ghTr('vault_add_source'),
                              style: theme.text(
                                size: GhTextSize.xs,
                                weight: GhWeight.medium,
                                color: states.active ? theme.ink : theme.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            VaultField(
              label: ghTr('vault_item_name_label'),
              child: vaultTextInput(theme, _name, placeholder: ghTr('vault_item_name_placeholder')),
            ),
            VaultField(
              label: ghTr('vault_item_desc_label'),
              optional: true,
              child: vaultTextInput(theme, _desc, placeholder: ghTr('vault_item_desc_placeholder'), lines: 2),
            ),
            VaultField(
              label: ghTr('vault_item_tags_label'),
              optional: true,
              child: VaultTagEditor(tags: _tags, onChanged: (tags) => setState(() => _tags = tags)),
            ),
          ],
        ),
      ),
    );
  }
}
