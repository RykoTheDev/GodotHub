import 'package:flutter/material.dart';

import '../api/changelog.dart';
import '../design/design.dart';
import '../logic/open_todos.dart' show localDateValue;
import '../src/rust/api/types.dart';
import '../ui/controls/checkbox.dart';
import '../ui/controls/text_input.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/core/tooltip.dart';
import '../ui/core/ui_settings.dart' show GhSide;
import '../ui/feedback/modal_shell.dart';
import '../ui/overlays/dropdown.dart';
import '../ui/overlays/menu.dart';
import '../ui/reusables/modal_kit.dart';
import '../ui/shell/smooth_scroll.dart';

const changelogHead = 'HEAD';
const changelogCategories = ['add', 'fix', 'improve'];

class DraftRow {
  DraftRow({required this.key, required this.category, required String text, this.hash}) : controller = TextEditingController(text: text);

  final String key;
  String category;
  final TextEditingController controller;
  final String? hash;
}

class ReleaseNotesDraftModal extends StatefulWidget {
  const ReleaseNotesDraftModal({super.key, required this.onClose, required this.onUseDraft});

  final VoidCallback onClose;
  final void Function(List<ChangelogNote> notes, String version, String date) onUseDraft;

  @override
  State<ReleaseNotesDraftModal> createState() => _ReleaseNotesDraftModalState();
}

class _ReleaseNotesDraftModalState extends State<ReleaseNotesDraftModal> {
  final TextEditingController _version = TextEditingController();
  late final TextEditingController _date = TextEditingController(text: localDateValue());
  List<String> _tags = const [];
  String _from = '';
  String _to = changelogHead;
  ChangelogDraft? _draft;
  List<DraftRow> _rows = [];
  final Set<int> _skipped = {};
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    ChangelogApi.listGitTags().then(
      (list) {
        if (!mounted) return;
        setState(() {
          _tags = list;
          _from = list.firstOrNull ?? '';
        });
      },
      onError: (Object e) {
        if (mounted) setState(() => _error = '$e');
      },
    );
  }

  @override
  void dispose() {
    _version.dispose();
    _date.dispose();
    for (final row in _rows) {
      row.controller.dispose();
    }
    super.dispose();
  }

  void _replaceRows(List<DraftRow> rows) {
    final old = _rows;
    _rows = rows;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final row in old) {
        if (!rows.contains(row)) row.controller.dispose();
      }
    });
  }

  Future<void> _generate() async {
    if (_from.isEmpty || _to.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _draft = null;
    });
    try {
      final draft = await ChangelogApi.generateDraft(_from, _to);
      if (!mounted) return;
      setState(() {
        _draft = draft;
        _replaceRows([for (final n in draft.notes) DraftRow(key: 'n-${n.hash}', category: n.category, text: n.text, hash: n.hash)]);
        _skipped.clear();
        if (_version.text.isEmpty) _version.text = draft.nextVersion;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleSkipped(int i) {
    final draft = _draft;
    if (draft == null) return;
    final key = 's-$i';
    setState(() {
      if (!_skipped.remove(i)) _skipped.add(i);
      final existing = _rows.where((r) => r.key == key).firstOrNull;
      if (existing != null) {
        _replaceRows([
          for (final r in _rows)
            if (r.key != key) r,
        ]);
      } else {
        final item = draft.skipped[i];
        _replaceRows([..._rows, DraftRow(key: key, category: 'improve', text: item.subject, hash: item.hash)]);
      }
    });
  }

  void _useDraft() {
    final notes = [
      for (final r in _rows)
        if (r.controller.text.trim().isNotEmpty) ChangelogNote(category: r.category, text: r.controller.text.trim()),
    ];
    widget.onUseDraft(notes, _version.text, _date.text);
  }

  Widget _rangePicker(
    GhTheme theme, {
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(1.5),
      children: [
        Text(
          label,
          style: theme.text(size: GhTextSize.x2s, weight: GhWeight.medium, color: theme.muted),
        ),
        GhDropdown(
          align: GhSide.left,
          expand: true,
          items: [
            for (final option in options)
              GhMenuItem(id: option, label: option, active: option == value, onSelected: () => onSelected(option)),
          ],
          trigger: (context, open, toggle) => GhPressable(
            onPressed: toggle,
            expanded: open,
            borderRadius: BorderRadius.circular(theme.radiusItem),
            builder: (context, states) => GhAnimatedBox(
              height: theme.space(9),
              color: theme.overlay,
              borderRadius: BorderRadius.circular(theme.radiusItem),
              border: Border.all(color: states.active ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
              padding: EdgeInsets.symmetric(horizontal: theme.space(3)),
              child: Row(
                spacing: theme.space(2),
                children: [
                  Expanded(
                    child: Text(
                      value.isEmpty ? '…' : value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.text(size: GhTextSize.x2s, mono: true, color: states.active ? theme.ink : theme.muted),
                    ),
                  ),
                  Opacity(
                    opacity: 0.6,
                    child: GhIcon(GhIcons.gitBranch, size: theme.space(3), color: states.active ? theme.ink : theme.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _categoryToggle(GhTheme theme, DraftRow row) {
    Color tone(String c) => switch (c) {
      'add' => theme.mint,
      'fix' => theme.danger,
      _ => theme.accentBright,
    };
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(theme.radiusBtn),
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final c in changelogCategories)
            GhPressable(
              onPressed: () => setState(() => row.category = c),
              checked: row.category == c,
              builder: (context, states) {
                final active = row.category == c;
                return GhAnimatedBox(
                  color: active
                      ? tone(c).withValues(alpha: 0.15)
                      : (states.active ? theme.raised.withValues(alpha: 0.5) : theme.raised.withValues(alpha: 0)),
                  padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(1.5)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: theme.space(1),
                    children: [
                      Container(
                        width: theme.space(1.5),
                        height: theme.space(1.5),
                        decoration: BoxDecoration(color: tone(c), shape: BoxShape.circle),
                      ),
                      Text(
                        ghTr(c),
                        style: theme.text(size: GhTextSize.xs, color: active ? tone(c) : theme.muted),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  GhTextInput _field(
    GhTheme theme,
    TextEditingController controller, {
    String? placeholder,
    GhTextSize size = GhTextSize.sm,
    double py = 2,
    double px = 3.5,
  }) => GhTextInput(
    controller: controller,
    size: size,
    placeholder: placeholder,
    background: theme.base,
    borderColor: theme.outline.withValues(alpha: 0.5),
    focusBorderColor: theme.accentDim,
    borderRadius: BorderRadius.circular(theme.radiusBtn),
    padding: EdgeInsets.symmetric(horizontal: theme.space(px), vertical: theme.space(py)),
  );

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final draft = _draft;
    return GhModalShell(
      icon: GhIcon(GhIcons.rocket, size: theme.space(5), color: theme.accentBright),
      title: ghTr('changelog_draft_title'),
      maxWidth: GhModalWidth.lg,
      showClose: false,
      onClose: widget.onClose,
      footer: [
        if (_error != null)
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: theme.space(64)),
              child: Text(
                _error!,
                style: theme.text(size: GhTextSize.xs, color: theme.danger),
              ),
            ),
          ),
        const Spacer(),
        GhButton(onPressed: widget.onClose, label: ghTr('cancel')),
        GhButton(
          onPressed: _rows.isEmpty ? null : _useDraft,
          label: ghTr('changelog_draft_use'),
          variant: GhButtonVariant.primary,
          weight: GhWeight.medium,
        ),
      ],
      child: Padding(
        padding: EdgeInsets.all(theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(2.5),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: theme.space(3),
              children: [
                _rangePicker(
                  theme,
                  label: ghTr('changelog_draft_from'),
                  value: _from,
                  options: _tags,
                  onSelected: (v) => setState(() => _from = v),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: theme.space(2.5)),
                  child: Text(
                    '→',
                    style: theme.text(size: GhTextSize.xs, color: theme.muted),
                  ),
                ),
                _rangePicker(
                  theme,
                  label: ghTr('changelog_draft_to'),
                  value: _to,
                  options: [changelogHead, ..._tags],
                  onSelected: (v) => setState(() => _to = v),
                ),
                GhTooltip(
                  message: ghTr('changelog_draft_generate'),
                  child: GhPressable(
                    onPressed: _loading || _from.isEmpty || _to.isEmpty ? null : _generate,
                    semanticLabel: ghTr('changelog_draft_generate'),
                    disabledOpacity: 0.4,
                    rippleColor: Colors.white,
                    borderRadius: BorderRadius.circular(theme.radiusItem),
                    builder: (context, states) {
                      Widget glyph = GhIcon(GhIcons.refresh, size: theme.space(3.5), color: Colors.white);
                      if (_loading) glyph = GhSpinnerIcon(color: Colors.white);
                      return GhAnimatedBox(
                        width: theme.space(9),
                        height: theme.space(9),
                        color: states.active ? theme.accentBright : theme.accent,
                        borderRadius: BorderRadius.circular(theme.radiusItem),
                        alignment: Alignment.center,
                        child: glyph,
                      );
                    },
                  ),
                ),
              ],
            ),
            if (draft != null) ...[
              Padding(
                padding: EdgeInsets.only(top: theme.space(2)),
                child: Row(
                  spacing: theme.space(1.5),
                  children: [
                    GhIcon(GhIcons.rocket, size: theme.space(3.5), color: theme.accentBright),
                    Text(
                      ghTr('changelog_draft_commits', count: draft.count.toInt()),
                      style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink),
                    ),
                    Flexible(
                      child: Text(
                        '${draft.from} → ${draft.to}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted.withValues(alpha: 0.6)),
                      ),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: theme.space(64)),
                child: GhScrollView(
                  padding: EdgeInsetsDirectional.only(end: theme.space(1)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: theme.space(1.5),
                    children: [
                      if (_rows.isEmpty && draft.skipped.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: theme.space(3)),
                          child: Text(
                            ghTr('changelog_draft_none'),
                            textAlign: TextAlign.center,
                            style: theme
                                .text(size: GhTextSize.xs, color: theme.muted.withValues(alpha: 0.7))
                                .copyWith(fontStyle: FontStyle.italic),
                          ),
                        ),
                      for (final row in _rows)
                        Row(
                          key: ValueKey(row.key),
                          spacing: theme.space(2),
                          children: [
                            _categoryToggle(theme, row),
                            Expanded(child: _field(theme, row.controller, size: GhTextSize.xs, py: 1.5, px: 3)),
                            if (row.hash != null)
                              Text(
                                row.hash!,
                                style: theme.text(size: GhTextSize.x3s, mono: true, color: theme.muted.withValues(alpha: 0.5)),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              if (draft.skipped.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(top: theme.space(2)),
                  padding: EdgeInsets.only(top: theme.space(3)),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: theme.outline.withValues(alpha: 0.4))),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: theme.space(1),
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: theme.space(0.5)),
                        child: Text(
                          ghTr('skipped').toUpperCase(),
                          style: theme.text(
                            size: GhTextSize.x2s,
                            weight: GhWeight.semibold,
                            color: theme.muted.withValues(alpha: 0.6),
                            letterSpacingEm: 0.05,
                          ),
                        ),
                      ),
                      for (var i = 0; i < draft.skipped.length; i++)
                        Row(
                          key: ValueKey(draft.skipped[i].hash),
                          spacing: theme.space(2),
                          children: [
                            GhCheckbox(
                              checked: _skipped.contains(i),
                              label: ghTr('changelog_draft_include'),
                              onChanged: (_) => _toggleSkipped(i),
                            ),
                            Text(
                              draft.skipped[i].hash,
                              style: theme.text(size: GhTextSize.x3s, mono: true, color: theme.muted.withValues(alpha: 0.7)),
                            ),
                            Expanded(
                              child: Text(
                                draft.skipped[i].subject,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.text(size: GhTextSize.x2s, color: theme.muted.withValues(alpha: 0.7)),
                              ),
                            ),
                            Text(
                              draft.skipped[i].reason.toUpperCase(),
                              style: theme.text(size: GhTextSize.x3s, color: theme.muted.withValues(alpha: 0.4), letterSpacingEm: 0.025),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
            Padding(
              padding: EdgeInsets.only(top: theme.space(3)),
              child: Row(
                spacing: theme.space(4),
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: theme.space(2),
                      children: [
                        GhFieldLabel(ghTr('changelog_version_label')),
                        _field(
                          theme,
                          _version,
                          placeholder: (draft?.nextVersion.isNotEmpty ?? false)
                              ? draft!.nextVersion
                              : ghTr('changelog_version_placeholder'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: theme.space(2),
                      children: [GhFieldLabel(ghTr('changelog_date_label')), _field(theme, _date)],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
