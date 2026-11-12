import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/projects.dart';
import '../api/storage.dart';
import '../design/design.dart';
import '../logic/format_bytes.dart';
import '../src/rust/api/dto.dart';
import '../src/rust/api/types.dart';
import '../src/ui_prefs.dart';
import '../state/godot_versions.dart';
import '../state/settings.dart';
import '../ui/controls/checkbox.dart';
import '../ui/controls/dashed_box.dart';
import '../ui/controls/spin.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/core/tooltip.dart';
import '../ui/core/ui_settings.dart' show GhSide;
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/reusables/view_header.dart';
import '../ui/shell/overlay_scroll_area.dart';
import '../ui/shell/view_insets.dart';

enum ReclaimGroup { versions, partials, exports }

class ReclaimEntry {
  const ReclaimEntry({
    required this.key,
    required this.group,
    required this.label,
    required this.detail,
    required this.path,
    required this.size,
    required this.defaultOn,
    required this.item,
  });

  final String key;
  final ReclaimGroup group;
  final String label;
  final String detail;
  final String path;
  final double size;
  final bool defaultOn;
  final ReclaimItem item;
}

List<ReclaimEntry> reclaimEntries(StorageReport report) => [
  for (final v in report.versions)
    if (v.unused)
      ReclaimEntry(
        key: 'version:${v.tag}',
        group: ReclaimGroup.versions,
        label: v.name,
        detail: v.external_ ? ghTr('cleanup_external_hint') : v.tag,
        path: v.path,
        size: v.sizeBytes.toDouble(),
        defaultOn: !v.external_,
        item: ReclaimItem(kind: ReclaimKind.version, tag: v.tag),
      ),
  for (final p in report.partials)
    ReclaimEntry(
      key: 'partial:${p.path}',
      group: ReclaimGroup.partials,
      label: p.name,
      detail: ghTr('cleanup_kind_${p.kind}'),
      path: p.path,
      size: p.sizeBytes.toDouble(),
      defaultOn: true,
      item: ReclaimItem(kind: ReclaimKind.partial, path: p.path),
    ),
  for (final e in report.exportTemplates)
    if (e.orphan)
      ReclaimEntry(
        key: 'export:${e.root}:${e.folder}',
        group: ReclaimGroup.exports,
        label: e.folder,
        detail: e.root,
        path: e.path,
        size: e.sizeBytes.toDouble(),
        defaultOn: false,
        item: ReclaimItem(kind: ReclaimKind.exportTemplates, folder: e.folder, root: e.root),
      ),
];

double _sum(Iterable<double> values) => values.fold(0, (a, b) => a + b);

typedef StorageTotals = ({double versions, double templates, double exports, double partials, double all});

StorageTotals storageTotals(StorageReport? report) {
  if (report == null) return (versions: 0, templates: 0, exports: 0, partials: 0, all: 0);
  final versions = _sum(report.versions.map((v) => v.sizeBytes.toDouble()));
  final templates = _sum(report.templates.map((t) => t.sizeBytes.toDouble()));
  final exports = _sum(report.exportTemplates.map((e) => e.sizeBytes.toDouble()));
  final partials = _sum(report.partials.map((p) => p.sizeBytes.toDouble()));
  return (versions: versions, templates: templates, exports: exports, partials: partials, all: versions + templates + exports + partials);
}

enum _BadgeTone { accent, mint, amber, muted }

class StorageView extends ConsumerStatefulWidget {
  const StorageView({super.key, this.connected = false, this.prefs, this.active = true});

  final bool connected;
  final UiPrefsStore? prefs;
  final bool active;

  @override
  ConsumerState<StorageView> createState() => _StorageViewState();
}

class _StorageViewState extends ConsumerState<StorageView> {
  StorageReport? _report;
  bool _loading = false;
  String? _error;
  Set<String> _selected = {};
  bool _reclaiming = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) _load();
  }

  @override
  void didUpdateWidget(StorageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final next = await StorageApi.report();
      if (!mounted) return;
      setState(() {
        _report = next;
        _selected = {
          for (final e in reclaimEntries(next))
            if (e.defaultOn) e.key,
        };
      });
    } catch (e) {
      debugPrint('$e');
      if (!mounted) return;
      final message = _message(e);
      setState(() => _error = message);
      if (_report != null) ghToasts.pushToast(GhToastType.error, ghTr('cleanup_load_error', args: {'error': message}));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _message(Object e) {
    final text = '$e';
    const prefix = 'Exception: ';
    return text.startsWith(prefix) ? text.substring(prefix.length) : text;
  }

  void _toggle(String key, bool on) => setState(() {
    final next = {..._selected};
    if (on) {
      next.add(key);
    } else {
      next.remove(key);
    }
    _selected = next;
  });

  Future<void> _reclaim(List<ReclaimEntry> chosen) async {
    setState(() => _reclaiming = true);
    try {
      final result = await StorageApi.reclaim([for (final e in chosen) e.item]);
      if (result.removed > BigInt.zero) {
        ghToasts.pushToast(GhToastType.success, ghTr('cleanup_done', args: {'size': formatBigBytes(result.freedBytes)}));
      }
      for (final f in result.failed) {
        ghToasts.pushToast(GhToastType.error, ghTr('cleanup_failed', args: {'label': f.label, 'error': f.error}), ttlMs: 8000);
      }
      if (chosen.any((e) => e.group == ReclaimGroup.versions)) {
        await ref.read(godotVersionsProvider.notifier).refreshInstalled();
      }
    } catch (e) {
      reportError(e);
    } finally {
      if (mounted) setState(() => _reclaiming = false);
      if (mounted) await _load();
    }
  }

  void _confirm(List<ReclaimEntry> chosen, double chosenSize) {
    showGhModal<void>(
      context,
      (context) => _ReclaimConfirmModal(
        chosen: chosen,
        size: chosenSize,
        onCancel: () => Navigator.of(context).pop(),
        onConfirm: () {
          Navigator.of(context).pop();
          _reclaim(chosen);
        },
      ),
    ).ignore();
  }

  Widget _badge(GhTheme theme, _BadgeTone tone, String text) {
    final (bg, fg, border) = switch (tone) {
      _BadgeTone.accent => (theme.accent.withValues(alpha: 0.1), theme.accentBright, theme.accentDim.withValues(alpha: 0.3)),
      _BadgeTone.mint => (theme.mint.withValues(alpha: 0.1), theme.mint, theme.mint.withValues(alpha: 0.3)),
      _BadgeTone.amber => (theme.amber.withValues(alpha: 0.1), theme.amber, theme.amber.withValues(alpha: 0.3)),
      _BadgeTone.muted => (theme.raised, theme.muted, theme.outline.withValues(alpha: 0.5)),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: theme.space(1.5), vertical: theme.space(0.5)),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(theme.radiusTag),
        border: Border.all(color: border),
      ),
      child: Text(text, style: theme.text(size: GhTextSize.x3s, weight: GhWeight.semibold, color: fg)),
    );
  }

  Widget _section(GhTheme theme, {required FaIconData icon, required String title, double? total, String? description, required Widget child}) {
    return Container(
      padding: EdgeInsets.all(theme.space(4)),
      decoration: BoxDecoration(
        color: theme.overlay,
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(3),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: theme.space(4),
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Row(
                        spacing: theme.space(2),
                        children: [
                          GhIcon(icon, size: theme.space(3.5), color: theme.muted),
                          Flexible(
                            child: Text(title, style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.ink)),
                          ),
                        ],
                      ),
                    ),
                    if (description != null)
                      Padding(
                        padding: EdgeInsets.only(top: theme.space(1)),
                        child: Text(description, style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625)),
                      ),
                  ],
                ),
              ),
              if (total != null) Text(formatBytes(total), style: theme.text(size: GhTextSize.xs, mono: true, color: theme.muted)),
            ],
          ),
          child,
        ],
      ),
    );
  }

  Widget _row(GhTheme theme, {required List<Widget> children, double vertical = 2}) => Container(
    padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(vertical)),
    decoration: BoxDecoration(
      color: theme.base.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(theme.radiusBtn),
      border: Border.all(color: theme.outline.withValues(alpha: 0.4)),
    ),
    child: Row(spacing: theme.space(3), children: children),
  );

  Widget _titleDetail(GhTheme theme, String title, String detail) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink)),
        Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.text(size: GhTextSize.x2s, color: theme.muted)),
      ],
    ),
  );

  Widget _size(GhTheme theme, String text) => Text(text, style: theme.text(size: GhTextSize.xs, mono: true, color: theme.ink));

  Widget _emptyNote(GhTheme theme, String text) => Padding(
    padding: EdgeInsets.symmetric(vertical: theme.space(2)),
    child: Text(text, style: theme.text(size: GhTextSize.xs, color: theme.muted.withValues(alpha: 0.7))),
  );

  Widget _reclaimSection(GhTheme theme, List<ReclaimEntry> entries, List<ReclaimEntry> chosen, double chosenSize) {
    final groups = [
      (id: ReclaimGroup.versions, title: ghTr('cleanup_group_unused_versions'), hint: null),
      (id: ReclaimGroup.partials, title: ghTr('cleanup_group_partials'), hint: null),
      (id: ReclaimGroup.exports, title: ghTr('cleanup_group_orphan_exports'), hint: ghTr('cleanup_orphan_exports_hint')),
    ];
    final disabled = chosen.isEmpty || _reclaiming || _loading;
    return _section(
      theme,
      icon: GhIcons.trash,
      title: ghTr('cleanup_reclaimable_title'),
      description: ghTr('cleanup_reclaimable_desc'),
      child: entries.isEmpty
          ? _emptyNote(theme, ghTr('cleanup_nothing_to_reclaim'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(3),
              children: [
                for (final group in groups)
                  if (entries.any((e) => e.group == group.id))
                    Builder(
                      builder: (context) {
                        final rows = [for (final e in entries) if (e.group == group.id) e];
                        final allOn = rows.every((r) => _selected.contains(r.key));
                        final someOn = rows.any((r) => _selected.contains(r.key));
                        return Column(
                          key: ValueKey('group:${group.id.name}'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: theme.space(1.5),
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: theme.space(1)),
                              child: Row(
                                spacing: theme.space(3),
                                children: [
                                  Expanded(
                                    child: Align(
                                      alignment: AlignmentDirectional.centerStart,
                                      child: GhCheckbox(
                                        checked: allOn,
                                        indeterminate: !allOn && someOn,
                                        label: group.title,
                                        onChanged: (on) => setState(() {
                                          final next = {..._selected};
                                          for (final r in rows) {
                                            on ? next.add(r.key) : next.remove(r.key);
                                          }
                                          _selected = next;
                                        }),
                                        child: Text(group.title, style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink)),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    formatBytes(_sum(rows.map((r) => r.size))),
                                    style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted),
                                  ),
                                ],
                              ),
                            ),
                            if (group.hint != null)
                              Text(group.hint!, style: theme.text(size: GhTextSize.x2s, color: theme.amber.withValues(alpha: 0.9), lineHeight: 1.625)),
                            for (final row in rows)
                              KeyedSubtree(
                                key: ValueKey(row.key),
                                child: _row(
                                  theme,
                                  children: [
                                    GhCheckbox(checked: _selected.contains(row.key), label: row.label, onChanged: (on) => _toggle(row.key, on)),
                                    _titleDetail(theme, row.label, row.detail),
                                    _size(theme, formatBytes(row.size)),
                                    _OpenFolderButton(path: row.path),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                Container(
                  padding: EdgeInsets.only(top: theme.space(2)),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.line))),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: GhPressable(
                      onPressed: disabled ? null : () => _confirm(chosen, chosenSize),
                      borderRadius: BorderRadius.circular(theme.radiusItem),
                      builder: (context, states) => Opacity(
                        opacity: disabled ? 0.4 : 1,
                        child: GhAnimatedBox(
                          height: theme.space(9),
                          padding: EdgeInsets.symmetric(horizontal: theme.space(5)),
                          color: states.active ? Color.lerp(theme.danger, Colors.white, 0.1)! : theme.danger,
                          borderRadius: BorderRadius.circular(theme.radiusItem),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: theme.space(2),
                            children: [
                              _reclaiming
                                  ? GhSpinning(child: GhIcon(GhIcons.spinner, size: theme.space(4), color: Colors.white))
                                  : GhIcon(GhIcons.trash, size: theme.space(4), color: Colors.white),
                              Text(
                                ghTr('cleanup_reclaim_btn', args: {'size': formatBytes(chosenSize)}),
                                style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _versionsSection(GhTheme theme, StorageReport report, double total) {
    final maxVersion = report.versions.fold<double>(0, (m, v) => v.sizeBytes.toDouble() > m ? v.sizeBytes.toDouble() : m);
    return _section(
      theme,
      icon: GhIcons.cloudArrowDown,
      title: ghTr('installed_versions_section'),
      total: total,
      description: ghTr('cleanup_versions_desc'),
      child: report.versions.isEmpty
          ? _emptyNote(theme, ghTr('cleanup_empty'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(1.5),
              children: [
                for (final v in report.versions)
                  Container(
                    key: ValueKey(v.tag),
                    padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
                    decoration: BoxDecoration(
                      color: theme.base.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(theme.radiusBtn),
                      border: Border.all(color: theme.outline.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: theme.space(1.5),
                      children: [
                        Row(
                          spacing: theme.space(2),
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: theme.space(1.5),
                                runSpacing: theme.space(1),
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(v.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink)),
                                  if (v.name != v.tag) Text(v.tag, style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted)),
                                  if (v.isCurrent) _badge(theme, _BadgeTone.accent, ghTr('cleanup_current_badge')),
                                  if (v.aliases.isNotEmpty) _badge(theme, _BadgeTone.accent, ghTr('cleanup_alias_badge')),
                                  if (v.projects.isNotEmpty)
                                    GhTooltip(
                                      message: v.projects.join(', '),
                                      child: _badge(theme, _BadgeTone.mint, ghTr('n_projects', count: v.projects.length)),
                                    ),
                                  if (v.templates.isNotEmpty)
                                    GhTooltip(
                                      message: v.templates.join(', '),
                                      child: _badge(theme, _BadgeTone.mint, ghTr('cleanup_used_by_templates', count: v.templates.length)),
                                    ),
                                  if (v.unused) _badge(theme, _BadgeTone.amber, ghTr('cleanup_unused_badge')),
                                  if (v.managedBy != null) _badge(theme, _BadgeTone.muted, ghTr('cleanup_mise_badge')),
                                  if (v.external_ && v.managedBy == null) _badge(theme, _BadgeTone.muted, ghTr('cleanup_external_badge')),
                                ],
                              ),
                            ),
                            _size(theme, v.managedBy != null ? '-' : formatBigBytes(v.sizeBytes)),
                            _OpenFolderButton(path: v.path),
                          ],
                        ),
                        if (v.managedBy == null) _SizeBar(size: v.sizeBytes.toDouble(), max: maxVersion),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _templatesSection(GhTheme theme, StorageReport report, double total) => _section(
    theme,
    icon: GhIcons.rocket,
    title: ghTr('cleanup_templates_title'),
    total: total,
    child: report.templates.isEmpty
        ? _emptyNote(theme, ghTr('cleanup_empty'))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(1.5),
            children: [
              for (final t in report.templates)
                KeyedSubtree(
                  key: ValueKey(t.path),
                  child: _row(
                    theme,
                    children: [
                      _titleDetail(theme, t.name, t.workspace),
                      _size(theme, formatBigBytes(t.sizeBytes)),
                      _OpenFolderButton(path: t.path),
                    ],
                  ),
                ),
            ],
          ),
  );

  Widget _exportsSection(GhTheme theme, StorageReport report, double total) {
    final error = report.exportTemplatesError;
    return _section(
      theme,
      icon: GhIcons.hardDrive,
      title: ghTr('cleanup_export_templates_title'),
      total: total,
      child: error != null && error.isNotEmpty
          ? _emptyNote(theme, error)
          : report.exportTemplates.isEmpty
          ? _emptyNote(theme, ghTr('cleanup_empty'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(1.5),
              children: [
                for (final e in report.exportTemplates)
                  KeyedSubtree(
                    key: ValueKey('${e.root}:${e.folder}'),
                    child: _row(
                      theme,
                      children: [
                        Expanded(
                          child: Row(
                            spacing: theme.space(1.5),
                            children: [
                              Flexible(
                                child: Text(
                                  e.tag ?? e.folder,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink),
                                ),
                              ),
                              if (e.orphan) _badge(theme, _BadgeTone.amber, ghTr('cleanup_orphan_badge')),
                            ],
                          ),
                        ),
                        _size(theme, formatBigBytes(e.sizeBytes)),
                        _OpenFolderButton(path: e.path),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _cards(GhTheme theme, StorageTotals totals, double reclaimable) {
    final cards = [
      (label: ghTr('installed_versions_section'), value: totals.versions),
      (label: ghTr('cleanup_templates_title'), value: totals.templates),
      (label: ghTr('cleanup_export_templates_title'), value: totals.exports),
      (label: ghTr('cleanup_reclaimable_title'), value: reclaimable),
    ];
    final columns = MediaQuery.sizeOf(context).width >= 1024 ? 4 : 2;
    Widget card(({String label, double value}) c) => Container(
      key: ValueKey(c.label),
      padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(3)),
      decoration: BoxDecoration(
        color: theme.overlay,
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: theme.space(1),
        children: [
          Text(
            c.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.text(size: GhTextSize.x3s, weight: GhWeight.semibold, color: theme.muted.withValues(alpha: 0.6), letterSpacingEm: 0.05),
          ),
          Text(formatBytes(c.value), style: theme.text(size: GhTextSize.lg, weight: GhWeight.semibold, color: theme.ink)),
        ],
      ),
    );
    return Column(
      spacing: theme.space(3),
      children: [
        for (var i = 0; i < cards.length; i += columns)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(3),
              children: [for (final c in cards.skip(i).take(columns)) Expanded(child: card(c))],
            ),
          ),
      ],
    );
  }

  Widget _body(GhTheme theme, StorageReport? report) {
    if (_error != null && report == null) {
      return GhDashedBox(
        color: theme.danger.withValues(alpha: 0.3),
        radius: BorderRadius.circular(theme.radiusItem),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: theme.space(16)),
          child: Column(
            spacing: theme.space(4),
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: theme.rem(24)),
                child: Text(
                  ghTr('cleanup_load_error', args: {'error': _error}),
                  textAlign: TextAlign.center,
                  style: theme.text(size: GhTextSize.sm, color: theme.muted, lineHeight: 1.625),
                ),
              ),
              GhPressable(
                onPressed: _load,
                borderRadius: BorderRadius.circular(theme.radiusItem),
                builder: (context, states) => GhAnimatedBox(
                  padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(2)),
                  color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
                  borderRadius: BorderRadius.circular(theme.radiusItem),
                  border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: theme.space(2),
                    children: [
                      GhIcon(GhIcons.refresh, size: theme.space(3.5), color: theme.ink),
                      Text(ghTr('try_again'), style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (report == null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: theme.space(16)),
        child: Column(
          spacing: theme.space(3),
          children: [
            GhSpinning(child: GhIcon(GhIcons.spinner, size: theme.space(5), color: theme.muted)),
            Text(ghTr('cleanup_scanning'), style: theme.text(size: GhTextSize.xs, color: theme.muted)),
          ],
        ),
      );
    }
    final entries = reclaimEntries(report);
    final chosen = [
      for (final e in entries)
        if (_selected.contains(e.key)) e,
    ];
    final chosenSize = _sum(chosen.map((e) => e.size));
    final totals = storageTotals(report);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(2),
      children: [
        _cards(theme, totals, _sum(entries.map((e) => e.size))),
        _reclaimSection(theme, entries, chosen, chosenSize),
        _versionsSection(theme, report, totals.versions),
        _templatesSection(theme, report, totals.templates),
        _exportsSection(theme, report, totals.exports),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final settings = ref.watch(settingsProvider).value ?? defaultSettings;
    final report = _report;
    final totals = storageTotals(report);
    final insets = GhViewInsets.of(context);
    final scrollInsets = EdgeInsetsDirectional.only(
      start: insets.start >= theme.space(2) ? insets.start - theme.space(2) : insets.start,
      end: insets.end >= theme.space(4) ? insets.end - theme.space(4) : insets.end,
      bottom: insets.bottom >= theme.space(4) ? insets.bottom - theme.space(4) : insets.bottom,
    );
    final busy = _loading || _reclaiming;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: insets.start, end: insets.end),
          child: GhViewHeader(
            connected: widget.connected,
            title: ghTr('cleanup_title'),
            metric: [
              Text(
                report != null ? formatBytes(totals.all) : '…',
                style: theme.text(size: GhTextSize.x4l, weight: GhWeight.bold, color: theme.muted),
              ),
              Text(
                ghTr('cleanup_total_label').toUpperCase(),
                style: theme.text(size: GhTextSize.lg, weight: GhWeight.medium, color: theme.muted),
              ),
            ],
            actions: [
              GhPressable(
                onPressed: busy ? null : _load,
                borderRadius: BorderRadius.circular(theme.radiusItem),
                builder: (context, states) => Opacity(
                  opacity: busy ? 0.4 : 1,
                  child: GhAnimatedBox(
                    height: theme.space(8),
                    padding: EdgeInsets.symmetric(horizontal: theme.space(4)),
                    color: states.active ? theme.raised : theme.overlay,
                    borderRadius: BorderRadius.circular(theme.radiusItem),
                    border: Border.all(color: states.active ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: theme.space(1.5),
                      children: [
                        if (_loading)
                          GhSpinning(child: GhIcon(GhIcons.refresh, size: theme.space(3.5), color: states.active ? theme.ink : theme.muted))
                        else
                          GhIcon(GhIcons.refresh, size: theme.space(3.5), color: states.active ? theme.ink : theme.muted),
                        Text(
                          ghTr('refresh'),
                          style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: states.active ? theme.ink : theme.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            child: Text(ghTr('cleanup_subtitle'), style: theme.text(size: GhTextSize.xs, color: theme.muted)),
          ),
        ),
        Expanded(
          child: Padding(
            padding: scrollInsets,
            child: GhOverlayScrollArea(
              hideThumb: !settings.showScrollbars,
              topButtonBottom: theme.space(17),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(theme.space(widget.connected ? 5 : 2), theme.space(2), theme.space(5), theme.space(8)),
                child: _body(theme, report),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OpenFolderButton extends StatelessWidget {
  const _OpenFolderButton({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final label = ghTr('open_folder');
    return GhTooltip(
      message: label,
      side: GhSide.left,
      child: GhPressable(
        onPressed: () => ProjectsApi.openFolder(path).catchError(reportError),
        semanticLabel: label,
        borderRadius: BorderRadius.circular(theme.radiusBtn),
        builder: (context, states) => GhAnimatedBox(
          padding: EdgeInsets.all(theme.space(1.5)),
          color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(theme.radiusBtn),
          child: GhIcon(GhIcons.folder, size: theme.space(3.5), color: states.active ? theme.ink : theme.muted.withValues(alpha: 0.6)),
        ),
      ),
    );
  }
}

class _SizeBar extends StatelessWidget {
  const _SizeBar({required this.size, required this.max});

  final double size;
  final double max;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final pct = max > 0 ? ((size / max) * 100).round().clamp(2, 100) : 0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: theme.space(1),
        color: theme.raised,
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: pct / 100,
          heightFactor: 1,
          child: ColoredBox(color: theme.accent.withValues(alpha: 0.6)),
        ),
      ),
    );
  }
}

class _ReclaimConfirmModal extends StatelessWidget {
  const _ReclaimConfirmModal({required this.chosen, required this.size, required this.onCancel, required this.onConfirm});

  final List<ReclaimEntry> chosen;
  final double size;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return GhModalShell(
      icon: GhIcon(GhIcons.trash, size: theme.space(5), color: theme.danger),
      title: ghTr('cleanup_confirm_title', args: {'size': formatBytes(size)}),
      maxWidth: GhModalWidth.md,
      onClose: onCancel,
      showClose: false,
      footer: [
        const Spacer(),
        GhButton(onPressed: onCancel, label: ghTr('cancel')),
        GhButton(
          onPressed: onConfirm,
          label: ghTr('cleanup_confirm_btn', count: chosen.length),
          variant: GhButtonVariant.danger,
          weight: GhWeight.medium,
        ),
      ],
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), 0, theme.space(6), theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(3),
          children: [
            Text(ghTr('cleanup_confirm_desc'), style: theme.text(size: GhTextSize.xs, color: theme.muted)),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: theme.space(64)),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: theme.space(1),
                  children: [
                    for (final e in chosen)
                      Container(
                        key: ValueKey(e.key),
                        padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
                        decoration: BoxDecoration(
                          color: theme.base.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(theme.radiusBtn),
                          border: Border.all(color: theme.outline.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          spacing: theme.space(3),
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink)),
                                  GhTooltip(
                                    message: e.path,
                                    child: Text(e.path, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.text(size: GhTextSize.x2s, color: theme.muted)),
                                  ),
                                ],
                              ),
                            ),
                            Text(formatBytes(e.size), style: theme.text(size: GhTextSize.xs, mono: true, color: theme.ink)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Text(ghTr('cleanup_confirm_trash_note'), style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625)),
          ],
        ),
      ),
    );
  }
}
