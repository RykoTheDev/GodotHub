import 'package:flutter/material.dart';

import '../api/vault.dart';
import '../design/design.dart';
import '../src/rust/api/types.dart';
import '../ui/core/i18n.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import 'tag_editor.dart';
import 'vault_modal_parts.dart';

class EditVaultItemModal extends StatefulWidget {
  const EditVaultItemModal({super.key, required this.item, required this.onClose, required this.onSaved});

  final VaultItem item;
  final VoidCallback onClose;
  final ValueChanged<VaultItem> onSaved;

  @override
  State<EditVaultItemModal> createState() => _EditVaultItemModalState();
}

class _EditVaultItemModalState extends State<EditVaultItemModal> {
  late final TextEditingController _name = TextEditingController(text: widget.item.name);
  late final TextEditingController _desc = TextEditingController(text: widget.item.description);
  late List<String> _tags = widget.item.tags;
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

  Future<void> _save() async {
    final trimmed = _name.text.trim();
    if (trimmed.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final updated = await VaultApi.update(widget.item.id, trimmed, _desc.text.trim(), _tags);
      ghToasts.pushToast(GhToastType.success, ghTr('vault_item_updated_toast'));
      widget.onSaved(updated);
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
    final enabled = !_busy && _name.text.trim().isNotEmpty;
    return GhModalShell(
      icon: GhIcon(GhIcons.pencil, size: theme.space(4), color: theme.ink),
      title: ghTr('vault_edit_title'),
      maxWidth: GhModalWidth.sm,
      onClose: widget.onClose,
      footer: [
        VaultCancelButton(onPressed: widget.onClose),
        Expanded(
          child: VaultPrimaryButton(label: _busy ? ghTr('saving') : ghTr('save'), onPressed: enabled ? _save : null),
        ),
      ],
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), theme.space(4), theme.space(6), theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(4),
          children: [
            VaultField(
              label: ghTr('vault_item_name_label'),
              child: vaultTextInput(
                theme,
                _name,
                autofocus: true,
                onSubmitted: (_) {
                  if (_name.text.trim().isNotEmpty) _save();
                },
              ),
            ),
            VaultField(
              label: ghTr('vault_item_desc_label'),
              optional: true,
              child: vaultTextInput(theme, _desc, placeholder: ghTr('vault_item_desc_placeholder'), lines: 3),
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
