import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/design.dart';
import '../logic/locale.dart';
import '../modals/changelog_entry_modal.dart';
import '../modals/release_notes_draft_modal.dart';
import '../src/rust/api/types.dart';
import '../src/ui_prefs.dart';
import '../state/changelog.dart';
import '../state/settings.dart';
import '../ui/controls/dashed_box.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/core/tooltip.dart';
import '../ui/feedback/confirm_dialog.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/reusables/view_header.dart';
import '../ui/shell/overlay_scroll_area.dart';
import '../ui/shell/view_insets.dart';

String _tc(String key, {Map<String, Object?> args = const {}}) => ghTr('changelog:$key', args: args);

String formatChangelogDate(String raw) {
  if (raw.isEmpty) return '';
  final date = DateTime.tryParse(raw);
  if (date == null) return raw;
  return formatLocaleDate(date, const GhDateFormatOptions(day: GhDatePart.numeric, month: GhDatePart.short, year: GhDatePart.numeric));
}

typedef ChangelogGroup = ({String key, String labelKey, Color Function(GhTheme theme) color, Color Function(GhTheme theme) chip});

final List<ChangelogGroup> changelogGroups = [
  (key: 'add', labelKey: 'added', color: (t) => t.mint, chip: (t) => t.mint.withValues(alpha: 0.1)),
  (key: 'fix', labelKey: 'fixed', color: (t) => t.danger, chip: (t) => t.danger.withValues(alpha: 0.1)),
  (key: 'improve', labelKey: 'improved', color: (t) => t.accentBright, chip: (t) => t.accent.withValues(alpha: 0.15)),
];

class ChangelogView extends ConsumerStatefulWidget {
  const ChangelogView({super.key, this.connected = false, this.prefs, this.devTools = kDebugMode});

  final bool connected;
  final UiPrefsStore? prefs;
  final bool devTools;

  @override
  ConsumerState<ChangelogView> createState() => _ChangelogViewState();
}

class _ChangelogViewState extends ConsumerState<ChangelogView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(changelogBadgeProvider.notifier).markSeen();
    });
  }

  void _openEditor({ChangelogEntry? entry, ChangelogEntryPrefill? initial}) {
    final notifier = ref.read(changelogProvider.notifier);
    showGhModal<void>(
      context,
      (modal) => ChangelogEntryModal(
        entry: entry,
        initial: initial,
        onClose: () => Navigator.of(modal).pop(),
        onSave: (version, date, notes, knownIssues) => entry != null
            ? notifier.updateEntry(entry.id, version, date, notes, knownIssues)
            : notifier.addEntry(version, date, notes, knownIssues),
      ),
    ).ignore();
  }

  void _openDraft() {
    showGhModal<void>(
      context,
      (modal) => ReleaseNotesDraftModal(
        onClose: () => Navigator.of(modal).pop(),
        onUseDraft: (notes, version, date) {
          Navigator.of(modal).pop();
          _openEditor(initial: (version: version, date: date, notes: notes));
        },
      ),
    ).ignore();
  }

  Future<void> _confirmDelete(ChangelogEntry entry) async {
    final ok = await showGhConfirmDialog(
      context,
      title: _tc('delete_entry_title'),
      description: _tc('delete_entry_desc'),
      confirmLabel: _tc('delete'),
      variant: GhConfirmVariant.danger,
    );
    if (!ok) return;
    try {
      await ref.read(changelogProvider.notifier).removeEntry(entry.id);
    } catch (e) {
      ghToasts.pushToast(GhToastType.error, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(changelogBadgeEntriesProvider, (_, _) => ref.read(changelogBadgeProvider.notifier).markSeen());
    final theme = GhTheme.of(context);
    final settings = ref.watch(settingsProvider).value ?? defaultSettings;
    final changelog = ref.watch(changelogProvider);
    final entries = changelog.data;
    final connected = widget.connected;
    final insets = GhViewInsets.of(context);
    final scrollInsets = EdgeInsetsDirectional.only(
      start: connected ? insets.start : (insets.start >= theme.space(2) ? insets.start - theme.space(2) : insets.start),
      end: connected ? insets.end : (insets.end >= theme.space(4) ? insets.end - theme.space(4) : insets.end),
      bottom: connected ? insets.bottom : (insets.bottom >= theme.space(4) ? insets.bottom - theme.space(4) : insets.bottom),
    );
    final Widget body;
    if (changelog.loading && entries.isEmpty) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(4),
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              height: theme.space(28),
              decoration: BoxDecoration(
                color: theme.overlay,
                borderRadius: BorderRadius.circular(theme.radiusItem),
                border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
              ),
            ),
        ],
      );
    } else if (entries.isEmpty) {
      body = GhDashedBox(
        color: theme.outline.withValues(alpha: 0.5),
        radius: BorderRadius.circular(theme.radiusItem),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: theme.space(24)),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              spacing: theme.space(4),
              children: [
                Container(
                  width: theme.space(12),
                  height: theme.space(12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.overlay,
                    borderRadius: BorderRadius.circular(theme.radiusTile),
                    border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                  ),
                  child: GhIcon(GhIcons.bookOpen, size: theme.space(5), color: theme.muted),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: theme.rem(20)),
                  child: Text(
                    _tc('no_entries'),
                    textAlign: TextAlign.center,
                    style: theme.text(size: GhTextSize.sm, color: theme.muted, lineHeight: 1.625),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, entry) in entries.indexed)
            ChangelogEntryCard(
              key: ValueKey(entry.id),
              entry: entry,
              isLast: i == entries.length - 1,
              devTools: widget.devTools,
              onEdit: () => _openEditor(entry: entry),
              onDelete: () => _confirmDelete(entry).ignore(),
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: insets.start, end: insets.end, bottom: theme.space(4)),
          child: GhViewHeader(
            connected: connected,
            title: _tc('changelog_title'),
            actions: [
              if (widget.devTools) ...[
                _HeaderButton(icon: GhIcons.rocket, label: ghTr('changelog_generate_from_git'), onPressed: _openDraft),
                _HeaderButton(icon: GhIcons.plus, label: ghTr('add_entry'), primary: true, onPressed: _openEditor),
              ],
            ],
            child: Text(
              _tc('changelog_subtitle'),
              style: theme.text(size: GhTextSize.xs, color: theme.muted),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: scrollInsets,
            child: GhOverlayScrollArea(
              hideThumb: !settings.showScrollbars,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(theme.space(connected ? 3 : 2), theme.space(2), theme.space(5), theme.space(4)),
                child: body,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.label, required this.onPressed, this.primary = false});

  final FaIconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      rippleColor: primary ? Colors.white : null,
      builder: (context, states) {
        final color = primary ? Colors.white : (states.active ? theme.ink : theme.muted);
        return GhAnimatedBox(
          height: theme.space(8),
          padding: EdgeInsets.symmetric(horizontal: theme.space(4)),
          color: primary ? (states.active ? theme.accentBright : theme.accent) : theme.overlay,
          borderRadius: radius,
          border: primary ? null : Border.all(color: states.active ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: theme.space(1.5),
            children: [
              GhIcon(icon, size: theme.space(3.5), color: color),
              Text(
                label,
                style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: color),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ChangelogEntryCard extends StatefulWidget {
  const ChangelogEntryCard({
    super.key,
    required this.entry,
    required this.isLast,
    required this.onEdit,
    required this.onDelete,
    this.devTools = false,
  });

  final ChangelogEntry entry;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool devTools;

  @override
  State<ChangelogEntryCard> createState() => _ChangelogEntryCardState();
}

class _ChangelogEntryCardState extends State<ChangelogEntryCard> {
  bool _hovered = false;
  bool _cardHovered = false;
  bool _focusInside = false;

  Widget _dot(GhTheme theme, Color color) => Container(
    width: theme.space(1.5),
    height: theme.space(1.5),
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  Widget _bullets(GhTheme theme, List<String> lines, Color dot) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: theme.space(1.5),
    children: [
      for (final line in lines)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: theme.space(2),
          children: [
            Padding(padding: const EdgeInsets.only(top: 3), child: _dot(theme, dot)),
            Expanded(
              child: Text(
                line,
                style: theme.text(size: GhTextSize.xs, color: theme.muted, lineHeight: 1.625),
              ),
            ),
          ],
        ),
    ],
  );

  Widget _iconButton(
    GhTheme theme, {
    required FaIconData icon,
    required String label,
    required VoidCallback onPressed,
    bool danger = false,
  }) {
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhTooltip(
      message: label,
      side: GhSide.top,
      child: GhPressable(
        onPressed: onPressed,
        borderRadius: radius,
        semanticLabel: label,
        builder: (context, states) => GhAnimatedBox(
          padding: EdgeInsets.all(theme.space(2)),
          color: states.active ? (danger ? theme.danger.withValues(alpha: 0.1) : theme.raised) : theme.raised.withValues(alpha: 0),
          borderRadius: radius,
          child: GhIcon(icon, size: theme.space(3.5), color: states.active ? (danger ? theme.danger : theme.ink) : theme.muted),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final entry = widget.entry;
    final issues = entry.knownIssues;
    final radius = BorderRadius.circular(theme.radiusItem);
    final showTools = _hovered || _focusInside;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(5),
          children: [
            Padding(
              padding: EdgeInsetsDirectional.only(top: theme.space(2), start: theme.space(2)),
              child: Column(
                children: [
                  Container(
                    width: theme.space(2),
                    height: theme.space(2),
                    decoration: BoxDecoration(
                      color: theme.accent,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: theme.accent.withValues(alpha: 0.15), spreadRadius: 4)],
                    ),
                  ),
                  if (!widget.isLast)
                    Expanded(
                      child: Container(
                        width: 1,
                        margin: EdgeInsets.only(top: theme.space(2)),
                        color: theme.line,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: theme.space(9)),
                child: MouseRegion(
                  onEnter: (_) => setState(() => _cardHovered = true),
                  onExit: (_) => setState(() => _cardHovered = false),
                  child: GhAnimatedBox(
                    padding: EdgeInsets.all(theme.space(5)),
                    color: _cardHovered ? theme.raised : theme.overlay,
                    borderRadius: radius,
                    border: Border.all(color: _cardHovered ? theme.accentDim.withValues(alpha: 0.7) : theme.outline.withValues(alpha: 0.5)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: theme.space(4),
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: theme.space(1),
                                children: [
                                  Text(
                                    entry.version,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.text(size: GhTextSize.lg, weight: GhWeight.semibold, color: theme.ink),
                                  ),
                                  if (entry.date.isNotEmpty)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      spacing: theme.space(1),
                                      children: [
                                        GhIcon(GhIcons.clock, size: theme.space(3), color: theme.muted),
                                        Text(
                                          formatChangelogDate(entry.date),
                                          style: theme.text(size: GhTextSize.x2s, color: theme.muted),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            if (widget.devTools)
                              Focus(
                                canRequestFocus: false,
                                skipTraversal: true,
                                onFocusChange: (inside) => setState(() => _focusInside = inside),
                                child: AnimatedOpacity(
                                  opacity: showTools ? 1 : 0,
                                  alwaysIncludeSemantics: true,
                                  duration: GhDurations.color,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    spacing: theme.space(1),
                                    children: [
                                      _iconButton(
                                        theme,
                                        icon: GhIcons.pencil,
                                        label: _tc('edit_entry_aria', args: {'version': entry.version}),
                                        onPressed: widget.onEdit,
                                      ),
                                      _iconButton(
                                        theme,
                                        icon: GhIcons.trash,
                                        label: _tc('delete_entry_aria', args: {'version': entry.version}),
                                        onPressed: widget.onDelete,
                                        danger: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (entry.notes.isNotEmpty || issues.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: theme.space(3)),
                            child: Wrap(
                              spacing: theme.space(1.5),
                              runSpacing: theme.space(1.5),
                              children: [
                                for (final group in changelogGroups)
                                  if (entry.notes.any((n) => n.category == group.key))
                                    _chip(
                                      theme,
                                      background: group.chip(theme),
                                      color: group.color(theme),
                                      leading: _dot(theme, group.color(theme)),
                                      label: '${entry.notes.where((n) => n.category == group.key).length} ${_tc(group.labelKey)}',
                                    ),
                                if (issues.isNotEmpty)
                                  _chip(
                                    theme,
                                    background: theme.amber.withValues(alpha: 0.1),
                                    color: theme.amber,
                                    leading: GhIcon(GhIcons.alertTriangle, size: theme.space(2.5), color: theme.amber),
                                    label: '${issues.length} ${_tc('changelog_known_issues')}',
                                  ),
                              ],
                            ),
                          ),
                        if (entry.notes.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: theme.space(4)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              spacing: theme.space(3),
                              children: [
                                for (final group in changelogGroups)
                                  if (entry.notes.any((n) => n.category == group.key))
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      spacing: theme.space(1.5),
                                      children: [
                                        Text(
                                          _tc(group.labelKey).toUpperCase(),
                                          style: theme.text(
                                            size: GhTextSize.x3s,
                                            weight: GhWeight.semibold,
                                            color: group.color(theme),
                                            letterSpacingEm: 0.05,
                                          ),
                                        ),
                                        _bullets(theme, [
                                          for (final n in entry.notes)
                                            if (n.category == group.key) n.text,
                                        ], group.color(theme)),
                                      ],
                                    ),
                              ],
                            ),
                          ),
                        if (issues.isNotEmpty)
                          Container(
                            margin: EdgeInsets.only(top: theme.space(4)),
                            padding: EdgeInsets.only(top: theme.space(4)),
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: theme.outline.withValues(alpha: 0.4))),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              spacing: theme.space(1.5),
                              children: [
                                Row(
                                  spacing: theme.space(1),
                                  children: [
                                    GhIcon(GhIcons.alertTriangle, size: theme.space(3), color: theme.amber),
                                    Text(
                                      _tc('changelog_known_issues').toUpperCase(),
                                      style: theme.text(
                                        size: GhTextSize.x3s,
                                        weight: GhWeight.semibold,
                                        color: theme.amber,
                                        letterSpacingEm: 0.05,
                                      ),
                                    ),
                                  ],
                                ),
                                _bullets(theme, issues, theme.amber),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(GhTheme theme, {required Color background, required Color color, required Widget leading, required String label}) =>
      Container(
        padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(0.5)),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(theme.radiusTag)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: theme.space(1.5),
          children: [
            leading,
            Text(
              label,
              style: theme.text(size: GhTextSize.x3s, weight: GhWeight.semibold, color: color),
            ),
          ],
        ),
      );
}
