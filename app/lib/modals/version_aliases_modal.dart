import 'package:flutter/material.dart';

import '../design/design.dart';
import '../logic/platform.dart';
import '../src/rust/api/types.dart';
import '../ui/controls/text_input.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/core/tooltip.dart';
import '../ui/feedback/confirm_dialog.dart';
import '../ui/feedback/modal_shell.dart';
import 'current_version_modal.dart';

String _tv(String key, {num? count, Map<String, Object?> args = const {}}) => ghTr('versions:$key', count: count, args: args);

class VersionAliasesModal extends StatefulWidget {
  const VersionAliasesModal({
    super.key,
    required this.versions,
    required this.aliases,
    required this.aliasesDir,
    this.initialTag,
    required this.onClose,
    required this.onCreateMany,
    required this.onDelete,
    this.windows,
  });

  final List<InstalledGodotVersion> versions;
  final List<AliasInfo> aliases;
  final String aliasesDir;
  final String? initialTag;
  final VoidCallback onClose;
  final Future<AliasBatchResult> Function(List<AliasRequest> entries) onCreateMany;
  final Future<void> Function(String name) onDelete;
  final bool? windows;

  @override
  State<VersionAliasesModal> createState() => _VersionAliasesModalState();
}

class _VersionAliasesModalState extends State<VersionAliasesModal> {
  final TextEditingController _name = TextEditingController();
  late String _tag = widget.initialTag ?? widget.versions.firstOrNull?.tag ?? '';
  bool _busy = false;
  String? _error;
  List<AliasRequest> _queue = const [];
  AliasBatchResult? _outcome;

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

  String get _folder => widget.aliasesDir.isNotEmpty ? widget.aliasesDir : (widget.aliases.firstOrNull?.aliasesDir ?? '');

  bool _needsMonoNote(String tag) => (widget.windows ?? isWindows) && widget.versions.any((v) => v.tag == tag && v.isMono);

  bool get _canAdd => _name.text.trim().isNotEmpty && _tag.isNotEmpty && !_busy;

  void _addToQueue() {
    final trimmed = _name.text.trim();
    if (trimmed.isEmpty || _tag.isEmpty) return;
    if (_queue.any((entry) => entry.name.toLowerCase() == trimmed.toLowerCase())) {
      setState(() => _error = _tv('alias_queue_duplicate', args: {'name': trimmed}));
      return;
    }
    setState(() {
      _error = null;
      _outcome = null;
      _queue = [..._queue, AliasRequest(name: trimmed, tag: _tag)];
    });
    _name.clear();
  }

  Future<void> _createQueued() async {
    if (_queue.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _outcome = null;
    });
    try {
      final result = await widget.onCreateMany(_queue);
      if (mounted) {
        setState(() {
          _outcome = result;
          _queue = const [];
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete(AliasInfo alias) async {
    final ok = await showGhConfirmDialog(
      context,
      title: _tv('alias_remove_title'),
      description: _tv('alias_remove_desc', args: {'name': alias.name}),
      confirmLabel: _tv('alias_remove'),
      variant: GhConfirmVariant.danger,
    );
    if (!ok || !mounted) return;
    setState(() => _error = null);
    try {
      await widget.onDelete(alias.name);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Widget _accentButton(
    GhTheme theme, {
    required String label,
    required FaIconData icon,
    required VoidCallback? onPressed,
    bool expand = false,
  }) {
    final radius = BorderRadius.circular(theme.radiusBtn);
    final enabled = onPressed != null;
    return GhPressable(
      onPressed: onPressed,
      disabledOpacity: null,
      disabledCursor: SystemMouseCursors.forbidden,
      rippleColor: Colors.white,
      borderRadius: radius,
      builder: (context, states) => GhAnimatedBox(
        color: enabled ? (states.active ? theme.accentBright : theme.accent) : theme.raised,
        borderRadius: radius,
        border: Border.all(color: enabled ? theme.accent : theme.line),
        padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(2)),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: theme.space(1.5),
          children: [
            GhIcon(icon, size: theme.space(3.5), color: enabled ? Colors.white : theme.muted.withValues(alpha: 0.4)),
            Text(
              label,
              style: theme.text(
                size: GhTextSize.sm,
                weight: GhWeight.medium,
                color: enabled ? Colors.white : theme.muted.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tagChip(GhTheme theme, String text) => Container(
    padding: EdgeInsets.symmetric(horizontal: theme.space(1.5), vertical: theme.space(0.5)),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(theme.radiusTag),
      border: Border.all(color: theme.outline.withValues(alpha: 0.4)),
    ),
    child: Text(
      text,
      style: theme.text(size: GhTextSize.x3s, weight: GhWeight.semibold, color: theme.muted),
    ),
  );

  Widget _trash(GhTheme theme, {required VoidCallback onPressed, double size = 3}) => GhPressable(
    onPressed: onPressed,
    semanticLabel: _tv('alias_remove'),
    borderRadius: BorderRadius.circular(theme.radiusBtn),
    builder: (context, states) => GhAnimatedBox(
      color: theme.danger.withValues(alpha: states.active ? 0.1 : 0),
      borderRadius: BorderRadius.circular(theme.radiusBtn),
      padding: EdgeInsets.all(theme.space(size == 3 ? 1.5 : 2)),
      child: GhIcon(GhIcons.trash, size: theme.space(size), color: states.active ? theme.danger : theme.muted.withValues(alpha: 0.7)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final outcome = _outcome;
    final folder = _folder;
    final muted = theme.text(size: GhTextSize.xs, color: theme.muted, lineHeight: 1.625);
    return GhModalShell(
      icon: GhIcon(GhIcons.terminal, size: theme.space(5), color: theme.accentBright),
      title: _tv('aliases_title'),
      maxWidth: GhModalWidth.xl,
      onClose: widget.onClose,
      footer: [
        if (folder.isNotEmpty)
          OutlineIconButton(label: _tv('current_open_folder'), icon: GhIcons.externalLink, onPressed: () => openFolderOrToast(folder)),
        const Spacer(),
        GhButton(onPressed: widget.onClose, label: ghTr('close'), variant: GhButtonVariant.primary, weight: GhWeight.medium),
      ],
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), 0, theme.space(6), theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(4),
          children: [
            Container(
              padding: EdgeInsets.all(theme.space(3.5)),
              decoration: BoxDecoration(
                color: theme.overlay,
                borderRadius: BorderRadius.circular(theme.radiusItem),
                border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: theme.space(2.5),
                children: [
                  Row(
                    spacing: theme.space(2),
                    children: [
                      Expanded(
                        child: GhTextInput(
                          controller: _name,
                          mono: true,
                          placeholder: _tv('alias_name_placeholder'),
                          semanticLabel: _tv('alias_name_label'),
                          onSubmitted: (_) => _addToQueue(),
                          background: theme.raised,
                          borderColor: theme.line,
                          focusBorderColor: theme.accentDim,
                          placeholderColor: theme.muted.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(theme.radiusBtn),
                          padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
                        ),
                      ),
                      _accentButton(theme, label: _tv('alias_add'), icon: GhIcons.plus, onPressed: _canAdd ? _addToQueue : null),
                    ],
                  ),
                  if (widget.versions.isNotEmpty)
                    Wrap(
                      spacing: theme.space(1.5),
                      runSpacing: theme.space(1.5),
                      children: [
                        for (final v in widget.versions)
                          GhPressable(
                            key: ValueKey(v.tag),
                            onPressed: () => setState(() => _tag = v.tag),
                            checked: _tag == v.tag,
                            borderRadius: BorderRadius.circular(theme.radiusTag),
                            builder: (context, states) {
                              final active = _tag == v.tag;
                              final color = active ? theme.accentBright : (states.active ? theme.ink : theme.muted);
                              return GhAnimatedBox(
                                color: active ? theme.accent.withValues(alpha: 0.15) : (states.active ? theme.raised : theme.overlay),
                                borderRadius: BorderRadius.circular(theme.radiusTag),
                                border: Border.all(
                                  color: active ? theme.accentDim.withValues(alpha: 0.5) : theme.outline.withValues(alpha: 0.5),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(1)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: theme.space(1.5),
                                  children: [
                                    if (active) GhIcon(GhIcons.check, size: theme.space(2.5), color: color),
                                    if (v.isMono)
                                      Text(
                                        _tv('mono_short').toUpperCase(),
                                        style: theme.text(size: GhTextSize.x4s, weight: GhWeight.bold, color: color, letterSpacingEm: 0.05),
                                      ),
                                    Text(
                                      (v.customName?.isNotEmpty ?? false) ? v.customName! : v.tag,
                                      style: theme.text(size: GhTextSize.x2s, weight: GhWeight.medium, color: color),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    )
                  else
                    Text(
                      _tv('aliases_no_versions'),
                      style: theme.text(size: GhTextSize.xs, color: theme.amber),
                    ),
                  if (_needsMonoNote(_tag))
                    Text(
                      _tv('alias_mono_script_note'),
                      style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625),
                    ),
                  if (_queue.isNotEmpty)
                    Container(
                      padding: EdgeInsets.only(top: theme.space(2.5)),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: theme.outline.withValues(alpha: 0.4))),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: theme.space(1.5),
                        children: [
                          for (final entry in _queue)
                            Row(
                              key: ValueKey(entry.name),
                              spacing: theme.space(2),
                              children: [
                                Flexible(
                                  child: Text(
                                    entry.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.text(size: GhTextSize.xs, mono: true, color: theme.ink),
                                  ),
                                ),
                                _tagChip(theme, entry.tag),
                                const Spacer(),
                                _trash(
                                  theme,
                                  onPressed: () => setState(
                                    () => _queue = [
                                      for (final e in _queue)
                                        if (!identical(e, entry)) e,
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  _accentButton(
                    theme,
                    label: _tv('alias_create_all', count: _queue.length),
                    icon: GhIcons.check,
                    expand: true,
                    onPressed: _queue.isEmpty || _busy ? null : _createQueued,
                  ),
                ],
              ),
            ),
            if (outcome != null)
              Container(
                padding: EdgeInsets.all(theme.space(3)),
                decoration: BoxDecoration(
                  color: theme.overlay,
                  borderRadius: BorderRadius.circular(theme.radiusItem),
                  border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: theme.space(1),
                  children: [
                    if (outcome.created.isNotEmpty)
                      Text(
                        _tv('aliases_batch_created', count: outcome.created.length),
                        style: theme.text(size: GhTextSize.xs, color: theme.mint),
                      ),
                    if (outcome.skipped.isNotEmpty) ...[
                      Text(
                        _tv('aliases_batch_skipped', count: outcome.skipped.length),
                        style: theme.text(size: GhTextSize.xs, color: theme.amber),
                      ),
                      for (final skip in outcome.skipped)
                        GhTooltip(
                          message: '${skip.name} - ${skip.reason}',
                          child: Text(
                            '${skip.name} - ${skip.reason}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            if (_error != null)
              Text(
                _error!,
                style: theme.text(size: GhTextSize.xs, color: theme.danger, lineHeight: 1.625),
              ),
            if (widget.aliases.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: theme.space(1)),
                child: Text(_tv('aliases_empty'), style: muted),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: theme.space(2),
                children: [
                  for (final alias in widget.aliases)
                    Container(
                      key: ValueKey(alias.name),
                      padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2.5)),
                      decoration: BoxDecoration(
                        color: theme.overlay,
                        borderRadius: BorderRadius.circular(theme.radiusItem),
                        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        spacing: theme.space(3),
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  spacing: theme.space(2),
                                  children: [
                                    Flexible(
                                      child: Text(
                                        alias.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.text(size: GhTextSize.sm, mono: true, color: theme.ink),
                                      ),
                                    ),
                                    _tagChip(theme, alias.tag),
                                    if (alias.method == 'shim')
                                      GhTooltip(
                                        message: _needsMonoNote(alias.tag) ? _tv('alias_mono_script_note') : '',
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: theme.space(1.5), vertical: theme.space(0.5)),
                                          decoration: BoxDecoration(
                                            color: theme.amber.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(theme.radiusTag),
                                            border: Border.all(color: theme.amber.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            _tv('alias_shim_badge'),
                                            style: theme.text(size: GhTextSize.x3s, weight: GhWeight.semibold, color: theme.amber),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsets.only(top: theme.space(0.5)),
                                  child: GhTooltip(
                                    message: alias.aliasPath,
                                    child: Text(
                                      alias.aliasPath,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CopyButton(value: alias.aliasPath, semanticLabel: _tv('alias_copy_path'), compact: true),
                          _trash(theme, size: 3.5, onPressed: () => _confirmDelete(alias)),
                        ],
                      ),
                    ),
                ],
              ),
            if (folder.isNotEmpty) Text(_tv('aliases_path_hint'), style: muted),
          ],
        ),
      ),
    );
  }
}
