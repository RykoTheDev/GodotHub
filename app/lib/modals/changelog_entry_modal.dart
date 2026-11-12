import 'package:flutter/material.dart';

import '../design/design.dart';
import '../src/rust/api/types.dart';
import '../ui/controls/text_input.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/modal_shell.dart';

typedef ChangelogEntryPrefill = ({String? version, String? date, List<ChangelogNote>? notes});

typedef ChangelogEntrySave = Future<void> Function(String version, String date, List<ChangelogNote> notes, List<String> knownIssues);

String changelogTodayIso([DateTime? now]) {
  final d = (now ?? DateTime.now()).toUtc();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
}

typedef _Category = ({String value, Color Function(GhTheme theme) color, Color Function(GhTheme theme) active});

final List<_Category> _categories = [
  (value: 'add', color: (t) => t.mint, active: (t) => t.mint.withValues(alpha: 0.15)),
  (value: 'fix', color: (t) => t.danger, active: (t) => t.danger.withValues(alpha: 0.15)),
  (value: 'improve', color: (t) => t.accentBright, active: (t) => t.accent.withValues(alpha: 0.15)),
];

class _NoteRow {
  _NoteRow(this.category, String text) : controller = TextEditingController(text: text);

  String category;
  final TextEditingController controller;
  final FocusNode focus = FocusNode();

  void dispose() {
    controller.dispose();
    focus.dispose();
  }
}

class _IssueRow {
  _IssueRow(String text) : controller = TextEditingController(text: text);

  final TextEditingController controller;
  final FocusNode focus = FocusNode();

  void dispose() {
    controller.dispose();
    focus.dispose();
  }
}

class ChangelogEntryModal extends StatefulWidget {
  const ChangelogEntryModal({super.key, this.entry, this.initial, required this.onClose, required this.onSave});

  final ChangelogEntry? entry;
  final ChangelogEntryPrefill? initial;
  final VoidCallback onClose;
  final ChangelogEntrySave onSave;

  @override
  State<ChangelogEntryModal> createState() => _ChangelogEntryModalState();
}

class _ChangelogEntryModalState extends State<ChangelogEntryModal> {
  late final TextEditingController _version = TextEditingController(text: widget.entry?.version ?? widget.initial?.version ?? '');
  late final TextEditingController _date = TextEditingController(text: widget.entry?.date ?? widget.initial?.date ?? changelogTodayIso());
  late final List<_NoteRow> _notes = _initialNotes();
  late final List<_IssueRow> _issues = [for (final issue in widget.entry?.knownIssues ?? const <String>[]) _IssueRow(issue)];
  String? _error;
  bool _busy = false;

  List<_NoteRow> _initialNotes() {
    final entryNotes = widget.entry?.notes ?? const <ChangelogNote>[];
    if (entryNotes.isNotEmpty) return [for (final n in entryNotes) _NoteRow(n.category, n.text)];
    final initialNotes = widget.initial?.notes ?? const <ChangelogNote>[];
    if (initialNotes.isNotEmpty) return [for (final n in initialNotes) _NoteRow(n.category, n.text)];
    return [_NoteRow('add', '')];
  }

  @override
  void dispose() {
    _version.dispose();
    _date.dispose();
    for (final n in _notes) {
      n.dispose();
    }
    for (final i in _issues) {
      i.dispose();
    }
    super.dispose();
  }

  void _addNote() => setState(() => _notes.add(_NoteRow('add', '')));

  void _removeNote(int index) {
    if (_notes.length == 1) return;
    setState(() => _notes.removeAt(index).dispose());
  }

  void _addIssue() => setState(() => _issues.add(_IssueRow('')));

  void _removeIssue(int index) => setState(() => _issues.removeAt(index).dispose());

  Future<void> _submit() async {
    if (_version.text.trim().isEmpty) {
      setState(() => _error = ghTr('changelog_error_no_version'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSave(
        _version.text,
        _date.text,
        [for (final n in _notes) ChangelogNote(category: n.category, text: n.controller.text)],
        [for (final i in _issues) i.controller.text],
      );
      widget.onClose();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  GhTextInput _input(
    GhTheme theme,
    TextEditingController controller, {
    String? placeholder,
    FocusNode? focusNode,
    bool autofocus = false,
    double py = 2.5,
    Color? focusBorder,
    VoidCallback? onEnter,
    String? semanticLabel,
  }) => GhTextInput(
    controller: controller,
    focusNode: focusNode,
    autofocus: autofocus,
    placeholder: placeholder,
    semanticLabel: semanticLabel,
    placeholderColor: theme.placeholder,
    background: theme.base,
    borderColor: theme.outline.withValues(alpha: 0.5),
    focusBorderColor: focusBorder ?? theme.accentDim,
    borderRadius: BorderRadius.circular(theme.radiusBtn),
    padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(py)),
    onSubmitted: onEnter == null ? null : (_) => onEnter(),
  );

  Widget _label(GhTheme theme, String text) => Text(
    text,
    style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.muted),
  );

  Widget _removeButton(GhTheme theme, {required String label, required VoidCallback onPressed}) {
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      semanticLabel: label,
      builder: (context, states) => GhAnimatedBox(
        padding: EdgeInsets.all(theme.space(1.5)),
        color: states.active ? theme.danger.withValues(alpha: 0.1) : theme.danger.withValues(alpha: 0),
        borderRadius: radius,
        child: GhIcon(GhIcons.x, size: theme.space(3), color: states.active ? theme.danger : theme.muted),
      ),
    );
  }

  Widget _ghostButton(GhTheme theme, {required String label, required VoidCallback onPressed}) {
    final radius = BorderRadius.circular(theme.radiusBtn);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: GhPressable(
        onPressed: onPressed,
        borderRadius: radius,
        builder: (context, states) {
          final color = states.active ? theme.ink : theme.muted;
          return GhAnimatedBox(
            padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(1.5)),
            color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
            borderRadius: radius,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: theme.space(1.5),
              children: [
                GhIcon(GhIcons.plus, size: theme.space(3), color: color),
                Text(
                  label,
                  style: theme.text(size: GhTextSize.xs, color: color),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _categoryPicker(GhTheme theme, _NoteRow note) {
    final radius = BorderRadius.circular(theme.radiusBtn);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(theme.radiusBtn - 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final c in _categories)
              GhPressable(
                tooltip: ghTr(c.value),
                onPressed: () => setState(() => note.category = c.value),
                selected: note.category == c.value,
                builder: (context, states) {
                  final active = note.category == c.value;
                  return GhAnimatedBox(
                    padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(1.5)),
                    color: active
                        ? c.active(theme)
                        : (states.active ? theme.raised.withValues(alpha: 0.5) : theme.raised.withValues(alpha: 0)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: theme.space(1),
                      children: [
                        Container(
                          width: theme.space(1.5),
                          height: theme.space(1.5),
                          decoration: BoxDecoration(color: c.color(theme), shape: BoxShape.circle),
                        ),
                        Text(
                          ghTr(c.value),
                          style: theme.text(size: GhTextSize.x3s, weight: GhWeight.medium, color: active ? c.color(theme) : theme.muted),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final btnRadius = BorderRadius.circular(theme.radiusBtn);
    final error = _error;
    return GhModalShell(
      icon: GhIcon(GhIcons.pencil, size: theme.space(5), color: theme.accentBright),
      title: widget.entry != null ? ghTr('edit_entry') : ghTr('new_entry'),
      maxWidth: GhModalWidth.lg,
      onClose: widget.onClose,
      showClose: false,
      footer: [
        if (error != null)
          Flexible(
            child: Text(
              error,
              style: theme.text(size: GhTextSize.xs, color: theme.danger),
            ),
          ),
        const Spacer(),
        GhPressable(
          onPressed: widget.onClose,
          borderRadius: btnRadius,
          builder: (context, states) => GhAnimatedBox(
            padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(2.5)),
            color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
            borderRadius: btnRadius,
            child: Text(
              ghTr('cancel'),
              style: theme.text(size: GhTextSize.sm, color: states.active ? theme.ink : theme.muted),
            ),
          ),
        ),
        GhPressable(
          onPressed: _busy ? null : _submit,
          disabledOpacity: 0.5,
          borderRadius: btnRadius,
          rippleColor: Colors.white,
          builder: (context, states) => GhAnimatedBox(
            padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(2.5)),
            color: states.active ? theme.accentBright : theme.accent,
            borderRadius: btnRadius,
            child: Text(
              _busy ? ghTr('saving') : (widget.entry != null ? ghTr('save_changes') : ghTr('add_entry')),
              style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: Colors.white),
            ),
          ),
        ),
      ],
      child: Padding(
        padding: EdgeInsets.all(theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(2.5),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: theme.space(4),
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: theme.space(2),
                    children: [
                      _label(theme, ghTr('changelog_version_label')),
                      _input(
                        theme,
                        _version,
                        autofocus: true,
                        placeholder: ghTr('changelog_version_placeholder'),
                        semanticLabel: ghTr('changelog_version_label'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: theme.space(2),
                    children: [
                      _label(theme, ghTr('changelog_date_label')),
                      _input(theme, _date, placeholder: ghTr('changelog_date_placeholder'), semanticLabel: ghTr('changelog_date_label')),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(top: theme.space(3)),
              child: _label(theme, ghTr('changelog_what_changed')),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(2),
              children: [
                for (final (i, note) in _notes.indexed)
                  Row(
                    key: ObjectKey(note),
                    spacing: theme.space(2),
                    children: [
                      _categoryPicker(theme, note),
                      Expanded(
                        child: _input(
                          theme,
                          note.controller,
                          focusNode: note.focus,
                          py: 2,
                          placeholder: ghTr('changelog_placeholder_note'),
                          onEnter: () {
                            _addNote();
                            note.focus.requestFocus();
                          },
                        ),
                      ),
                      if (_notes.length > 1)
                        _removeButton(theme, label: ghTr('changelog_remove_line_aria'), onPressed: () => _removeNote(i)),
                    ],
                  ),
              ],
            ),
            _ghostButton(theme, label: ghTr('changelog_add_line'), onPressed: _addNote),
            Padding(
              padding: EdgeInsets.only(top: theme.space(4)),
              child: Row(
                spacing: theme.space(1.5),
                children: [
                  GhIcon(GhIcons.alertTriangle, size: theme.space(3.5), color: theme.amber),
                  _label(theme, ghTr('changelog_known_issues')),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(2),
              children: [
                if (_issues.isEmpty)
                  Text(
                    ghTr('changelog_known_issues_none'),
                    style: theme
                        .text(size: GhTextSize.x2s, color: theme.muted.withValues(alpha: 0.6))
                        .copyWith(fontStyle: FontStyle.italic),
                  )
                else
                  for (final (i, issue) in _issues.indexed)
                    Row(
                      key: ObjectKey(issue),
                      spacing: theme.space(2),
                      children: [
                        GhIcon(GhIcons.alertTriangle, size: theme.space(3.5), color: theme.amber),
                        Expanded(
                          child: _input(
                            theme,
                            issue.controller,
                            focusNode: issue.focus,
                            py: 2,
                            focusBorder: theme.amber.withValues(alpha: 0.6),
                            placeholder: ghTr('changelog_known_issue_placeholder'),
                            onEnter: () {
                              _addIssue();
                              issue.focus.requestFocus();
                            },
                          ),
                        ),
                        _removeButton(theme, label: ghTr('changelog_remove_known_issue_aria'), onPressed: () => _removeIssue(i)),
                      ],
                    ),
              ],
            ),
            _ghostButton(theme, label: ghTr('changelog_add_known_issue'), onPressed: _addIssue),
          ],
        ),
      ),
    );
  }
}
