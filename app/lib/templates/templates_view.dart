import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/templates.dart';
import '../assets/asset_library_browser.dart';
import '../design/design.dart';
import '../logic/locale.dart';
import '../logic/pending_action.dart';
import '../modals/create_project_modal.dart';
import '../modals/current_version_modal.dart' show openFolderOrToast;
import '../modals/template_preview_modal.dart';
import '../motion/animated_number.dart';
import '../src/rust/api/types.dart';
import '../src/ui_prefs.dart';
import '../state/app_signals.dart';
import '../state/categories.dart';
import '../state/godot_versions.dart';
import '../state/keyboard_shortcuts.dart' show focusSearchSignal;
import '../state/projects.dart';
import '../state/settings.dart';
import '../state/shell_signals.dart';
import '../state/task_tray.dart';
import '../state/workspaces.dart';
import '../ui/controls/dashed_box.dart';
import '../ui/controls/search_bar.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/core/tooltip.dart';
import '../ui/feedback/confirm_dialog.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/overlays/dropdown.dart';
import '../ui/overlays/menu.dart';
import '../ui/reusables/tool_buttons.dart';
import '../ui/reusables/view_header.dart';
import '../ui/shell/overlay_scroll_area.dart';
import '../ui/shell/view_insets.dart';

const templateSortKey = 'godothub_template_sort';

enum TemplateSort {
  nameAsc('name_asc', 'sort_name_asc'),
  nameDesc('name_desc', 'sort_name_desc'),
  newest('newest', 'sort_created_desc'),
  oldest('oldest', 'sort_created_asc');

  const TemplateSort(this.id, this.labelKey);

  final String id;
  final String labelKey;

  static TemplateSort parse(String? id) => values.firstWhere((s) => s.id == id, orElse: () => nameAsc);
}

int _createdMs(ProjectTemplate t) => DateTime.tryParse(t.createdAt)?.millisecondsSinceEpoch ?? 0;

List<ProjectTemplate> filterAndSortTemplates(List<ProjectTemplate> templates, String query, TemplateSort sort) {
  final q = query.toLowerCase();
  final list = query.trim().isEmpty
      ? [...templates]
      : [
          for (final t in templates)
            if (t.name.toLowerCase().contains(q) || (t.description.isNotEmpty && t.description.toLowerCase().contains(q))) t,
        ];
  list.sort(
    (a, b) => switch (sort) {
      TemplateSort.nameDesc => ghLocaleCompare(b.name, a.name),
      TemplateSort.newest => _createdMs(b).compareTo(_createdMs(a)),
      TemplateSort.oldest => _createdMs(a).compareTo(_createdMs(b)),
      TemplateSort.nameAsc => ghLocaleCompare(a.name, b.name),
    },
  );
  return list;
}

String? templateSyncSummary(TemplateSyncResult result) {
  final parts = [
    if (result.imported.isNotEmpty) ghTr('template_imported_count', count: result.imported.length),
    if (result.updated.isNotEmpty) ghTr('template_updated_count', count: result.updated.length),
    if (result.removed.isNotEmpty) ghTr('template_removed_count', count: result.removed.length),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

enum _TemplatesTab { local, asset }

class TemplatesView extends ConsumerStatefulWidget {
  const TemplatesView({super.key, this.connected = false, this.prefs, this.onOpenSettings});

  final bool connected;
  final UiPrefsStore? prefs;
  final VoidCallback? onOpenSettings;

  @override
  ConsumerState<TemplatesView> createState() => _TemplatesViewState();
}

class _TemplatesViewState extends ConsumerState<TemplatesView> {
  static const _syncTaskId = 'sync-templates';

  final TextEditingController _search = TextEditingController();
  final FocusNode _searchNode = FocusNode(debugLabel: 'TemplatesView search');
  final List<StreamSubscription<Object?>> _subscriptions = [];
  _TemplatesTab _tab = _TemplatesTab.local;
  List<ProjectTemplate> _templates = const [];
  bool _loaded = false;
  ({bool loading, int total}) _assetStats = (loading: true, total: 0);
  late TemplateSort _sort = TemplateSort.parse(_prefs.getItem(templateSortKey));

  UiPrefsStore get _prefs => widget.prefs ?? UiPrefsStore.instance;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    void on(String name, void Function() handler) => _subscriptions.add(AppSignals.on(name).listen((_) => handler()));
    on(focusSearchSignal, _searchNode.requestFocus);
    on(syncTemplatesSignal, () => _sync().catchError((Object _) {}));
    on(refreshTemplatesSignal, () => _load().ignore());
    _load().ignore();
    if (consumePendingAction() == 'sync-templates') _sync().catchError((Object _) {});
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _search.dispose();
    _searchNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await TemplatesApi.list();
      if (mounted) setState(() => _templates = list);
    } catch (_) {}
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _sync() async {
    final tray = ref.read(taskTrayProvider.notifier);
    tray.registerTask(
      TrayTask(
        id: _syncTaskId,
        type: TaskType.syncTemplates,
        label: ghTr('syncing'),
        description: ghTr('loading'),
        status: TaskStatus.running,
      ),
    );
    try {
      final result = await TemplatesApi.syncWithScanDir();
      tray.updateTask(_syncTaskId, status: TaskStatus.completed, description: templateSyncSummary(result) ?? ghTr('up_to_date'));
      tray.scheduleRemoval(_syncTaskId, const Duration(seconds: 3));
      await _load();
    } catch (e) {
      tray.updateTask(_syncTaskId, status: TaskStatus.error, errorMessage: '$e');
      tray.scheduleRemoval(_syncTaskId, const Duration(seconds: 6));
      rethrow;
    }
  }

  void _setSort(TemplateSort sort) {
    setState(() => _sort = sort);
    _prefs.setItem(templateSortKey, sort.id);
  }

  void _preview(ProjectTemplate template) => showGhModal<void>(
    context,
    (modal) => TemplatePreviewModal(template: template, onClose: () => Navigator.of(modal).pop()),
  ).ignore();

  void _create(ProjectTemplate template) => showGhModal<void>(
    context,
    (modal) => Consumer(
      builder: (context, ref, _) {
        final settings = ref.watch(settingsProvider).value;
        return CreateProjectModal(
          installedVersions: ref.watch(godotVersionsProvider).installed,
          defaultLocation: settings?.defaultProjectLocation,
          initialTemplateId: template.id,
          categories: ref.watch(categoriesProvider).data,
          categoriesEnabled: settings?.categoriesEnabled ?? false,
          onClose: () => Navigator.of(modal).pop(),
          onCreated: () {
            Navigator.of(modal).pop();
            ref.read(projectsProvider.notifier).refresh().ignore();
          },
        );
      },
    ),
  ).ignore();

  Future<void> _confirmDelete(ProjectTemplate template) async {
    final ok = await showGhConfirmDialog(
      context,
      title: ghTr('template_delete_title'),
      description: template.name.isNotEmpty ? ghTr('template_delete_desc', args: {'name': template.name}) : ghTr('cannot_undo'),
      confirmLabel: ghTr('delete'),
      variant: GhConfirmVariant.danger,
    );
    if (!ok) return;
    try {
      await TemplatesApi.delete(template.id);
      if (mounted) setState(() => _templates = [for (final t in _templates) if (t.id != template.id) t]);
    } catch (e) {
      ghToasts.pushToast(GhToastType.error, '$e');
    }
  }

  Widget _headerButton(GhTheme theme, {required String label, required VoidCallback onPressed}) {
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      builder: (context, states) => GhAnimatedBox(
        height: theme.space(10),
        color: states.active ? theme.raised : theme.overlay,
        borderRadius: radius,
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
        boxShadow: GhShadows.md(Colors.black.withValues(alpha: 0.1)),
        padding: EdgeInsets.symmetric(horizontal: theme.space(6)),
        alignment: Alignment.center,
        child: Text(
          label,
          style: theme.text(weight: GhWeight.semibold, color: states.active ? theme.ink : theme.muted).copyWith(fontSize: theme.rem(1.0625)),
        ),
      ),
    );
  }

  Widget _tabSwitcher(GhTheme theme) {
    final radius = BorderRadius.circular(theme.radiusBtn);
    Widget option(_TemplatesTab value, String label, FaIconData icon) {
      final active = _tab == value;
      return GhPressable(
        onPressed: () => setState(() => _tab = value),
        borderRadius: radius,
        selected: active,
        builder: (context, states) {
          final color = active ? Colors.white : (states.active ? theme.ink : theme.muted);
          return GhAnimatedBox(
            color: active ? theme.accent : (states.active ? theme.raised : theme.raised.withValues(alpha: 0)),
            borderRadius: radius,
            padding: EdgeInsets.symmetric(horizontal: theme.space(3.5)),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: theme.space(1.5),
              children: [
                GhIcon(icon, size: theme.space(3.5), color: color),
                Text(label, style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: color)),
              ],
            ),
          );
        },
      );
    }

    return Container(
      height: theme.space(12),
      padding: EdgeInsets.all(theme.space(1)),
      decoration: BoxDecoration(
        color: theme.overlay,
        borderRadius: radius,
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: theme.space(1),
        children: [
          option(_TemplatesTab.local, ghTr('templates_tab_local'), GhIcons.copy),
          option(_TemplatesTab.asset, ghTr('templates_tab_asset'), GhIcons.store),
        ],
      ),
    );
  }

  Widget _dashed(GhTheme theme, {required double py, double px = 0, required List<Widget> children}) => GhDashedBox(
    color: theme.outline.withValues(alpha: 0.5),
    radius: BorderRadius.circular(theme.radiusItem),
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: theme.space(py), horizontal: theme.space(px)),
      child: SizedBox(
        width: double.infinity,
        child: Column(spacing: theme.space(3), children: children),
      ),
    ),
  );

  Widget _grid(BuildContext context, List<Widget> children) {
    final theme = GhTheme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1024 ? 3 : (width >= 640 ? 2 : 1);
    final rows = <Widget>[];
    for (var start = 0; start < children.length; start += columns) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(3),
            children: [
              for (var i = start; i < start + columns; i++) Expanded(child: i < children.length ? children[i] : const SizedBox.shrink()),
            ],
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: theme.space(3), children: rows);
  }

  Widget _local(BuildContext context, GhTheme theme) {
    final query = _search.text;
    if (!_loaded) {
      return _grid(context, [
        for (var i = 0; i < 3; i++)
          Container(
            key: ValueKey('template-skeleton-$i'),
            height: theme.space(52),
            decoration: BoxDecoration(
              color: theme.overlay,
              borderRadius: BorderRadius.circular(theme.radiusItem),
              border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
            ),
          ),
      ]);
    }
    if (_templates.isEmpty) {
      return _dashed(
        theme,
        py: 20,
        px: 6,
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
            child: GhIcon(GhIcons.copy, size: theme.space(5), color: theme.muted),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: theme.rem(24)),
            child: Text.rich(
              TextSpan(
                children: ghTrans(
                  ghTr('no_templates_yet'),
                  tags: {'1': (text, children) => TextSpan(children: children, style: const TextStyle(fontWeight: FontWeight.w700))},
                ),
              ),
              textAlign: TextAlign.center,
              style: theme.text(size: GhTextSize.sm, color: theme.muted, lineHeight: 1.625),
            ),
          ),
        ],
      );
    }
    final list = filterAndSortTemplates(_templates, query, _sort);
    if (list.isEmpty) {
      return _dashed(
        theme,
        py: 16,
        children: [
          GhIcon(GhIcons.search, size: theme.space(5), color: theme.muted),
          Text.rich(
            TextSpan(
              text: '${ghTr('no_templates_match')} ',
              children: [
                TextSpan(
                  text: '"$query"',
                  style: TextStyle(color: theme.ink, fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: '.'),
              ],
            ),
            textAlign: TextAlign.center,
            style: theme.text(size: GhTextSize.sm, color: theme.muted),
          ),
        ],
      );
    }
    final radius = BorderRadius.circular(theme.radiusItem);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(2),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: GhDropdown(
            align: GhSide.left,
            items: [
              for (final option in TemplateSort.values)
                GhMenuItem(id: option.id, label: ghTr(option.labelKey), active: option == _sort, onSelected: () => _setSort(option)),
            ],
            trigger: (context, open, toggle) => GhPressable(
              onPressed: toggle,
              expanded: open,
              borderRadius: radius,
              builder: (context, states) => GhAnimatedBox(
                height: theme.space(7),
                color: states.active ? theme.raised : theme.overlay,
                borderRadius: radius,
                padding: EdgeInsets.symmetric(horizontal: theme.space(3)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: theme.space(1.5),
                  children: [
                    Text('${ghTr('sort')}:', style: theme.text(size: GhTextSize.xs, color: theme.muted)),
                    Text(
                      ghTr(_sort.labelKey),
                      style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.ink),
                    ),
                    GhIcon(GhIcons.chevronDown, size: theme.space(3), color: theme.muted),
                  ],
                ),
              ),
            ),
          ),
        ),
        _grid(context, [
          for (final t in list)
            TemplateCard(
              key: ValueKey(t.id),
              template: t,
              onPreview: () => _preview(t),
              onDelete: () => _confirmDelete(t).ignore(),
              onCreate: () => _create(t),
            ),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr;
    ref.listen(activeWorkspaceIdProvider, (prev, next) {
      if (prev != next) _load().ignore();
    });
    final settings = ref.watch(settingsProvider).value ?? defaultSettings;
    final scanDir = settings.templateScanDir;
    final insets = GhViewInsets.of(context);
    final scrollInsets = EdgeInsetsDirectional.only(
      start: insets.start >= theme.space(2) ? insets.start - theme.space(2) : insets.start,
      end: insets.end >= theme.space(4) ? insets.end - theme.space(4) : insets.end,
      bottom: insets.bottom >= theme.space(4) ? insets.bottom - theme.space(4) : insets.bottom,
    );
    final local = _tab == _TemplatesTab.local;
    final count = local ? _templates.length : _assetStats.total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: insets.start, end: insets.end),
          child: GhViewHeader(
            connected: widget.connected,
            title: tr.nav.templates,
            metric: [
              DefaultTextStyle.merge(
                style: theme.text(size: GhTextSize.x4l, weight: GhWeight.bold, color: theme.muted),
                child: GhAnimatedNumber(count),
              ),
              Text(
                ghTr(local ? 'template_your_templates' : 'asset_store_count', count: count).toUpperCase(),
                style: theme.text(size: GhTextSize.lg, weight: GhWeight.medium, color: theme.muted),
              ),
            ],
            actions: [
              if (scanDir != null && scanDir.isNotEmpty) _headerButton(theme, label: ghTr('open_folder'), onPressed: () => openFolderOrToast(scanDir)),
              GhScanButton(
                onOpenSettings: widget.onOpenSettings,
                scanDirs: [if (scanDir != null && scanDir.isNotEmpty) scanDir],
                scan: () async {
                  await _sync();
                  return const <String>[];
                },
              ),
            ],
            child: Row(
              spacing: theme.space(2),
              children: [
                Expanded(
                  child: GhSearchBar(
                    value: _search.text,
                    controller: _search,
                    focusNode: _searchNode,
                    placeholder: ghTr(local ? 'template_search_placeholder' : 'asset_search_placeholder'),
                    onChanged: (_) {},
                  ),
                ),
                _tabSwitcher(theme),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: scrollInsets,
            child: GhOverlayScrollArea(
              hideThumb: !settings.showScrollbars,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(theme.space(widget.connected ? 5 : 2), theme.space(2), theme.space(5), theme.space(8)),
                child: local
                    ? _local(context, theme)
                    : AssetLibraryBrowser(
                        query: _search.text,
                        onStatsChange: (stats) {
                          if (mounted && stats != _assetStats) setState(() => _assetStats = stats);
                        },
                        installedTemplateNames: [for (final t in _templates) t.name],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TemplateCard extends StatefulWidget {
  const TemplateCard({super.key, required this.template, required this.onPreview, required this.onDelete, required this.onCreate});

  final ProjectTemplate template;
  final VoidCallback onPreview;
  final VoidCallback onDelete;
  final VoidCallback onCreate;

  @override
  State<TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<TemplateCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final t = widget.template;
    final radius = BorderRadius.circular(theme.radiusItem);
    final created = DateTime.tryParse(t.createdAt);
    final meta = theme.text(size: GhTextSize.x3s, mono: true, color: theme.muted.withValues(alpha: 0.5));
    final deleteLabel = ghTr('delete_template', args: {'name': t.name});
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onPreview,
        behavior: HitTestBehavior.opaque,
        child: GhAnimatedBox(
          color: theme.overlay,
          borderRadius: radius,
          border: Border.all(color: _hover ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
          padding: EdgeInsets.all(theme.space(4)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(3),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: theme.space(10),
                    height: theme.space(10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.raised,
                      borderRadius: BorderRadius.circular(theme.radiusTile),
                      border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                    ),
                    child: GhIcon(GhIcons.copy, size: theme.space(4), color: theme.muted),
                  ),
                  GhTooltip(
                    message: deleteLabel,
                    side: GhSide.left,
                    child: GhPressable(
                      onPressed: widget.onDelete,
                      semanticLabel: deleteLabel,
                      borderRadius: BorderRadius.circular(theme.radiusBtn),
                      builder: (context, del) {
                        final visible = _hover || del.focused;
                        return GhAnimatedBox(
                          color: del.active ? theme.danger.withValues(alpha: 0.1) : theme.danger.withValues(alpha: 0),
                          borderRadius: BorderRadius.circular(theme.radiusBtn),
                          padding: EdgeInsets.all(theme.space(1.5)),
                          child: AnimatedOpacity(
                            opacity: visible ? 1 : 0,
                            duration: const Duration(milliseconds: 150),
                            child: GhIcon(
                              GhIcons.trash,
                              size: theme.space(3.5),
                              color: del.active ? theme.danger : theme.muted.withValues(alpha: 0.4),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.text(size: GhTextSize.sm, weight: GhWeight.semibold, color: theme.ink),
                    ),
                    if (t.description.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: theme.space(1)),
                        child: Text(
                          t.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.text(size: GhTextSize.xs, color: theme.muted, lineHeight: 1.625),
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                spacing: theme.space(1.5),
                children: [
                  if (t.godotVersion.isNotEmpty) Text('${ghTr('godot')} ${t.godotVersion}', style: meta),
                  if (t.createdAt.isNotEmpty) ...[
                    Text('·', style: meta),
                    Text(created == null ? '' : formatLocaleDate(created), style: meta),
                  ],
                ],
              ),
              GhPressable(
                onPressed: widget.onCreate,
                borderRadius: radius,
                builder: (context, create) => GhAnimatedBox(
                  color: theme.accent.withValues(alpha: create.active ? 0.2 : 0.1),
                  borderRadius: radius,
                  border: Border.all(color: theme.accentDim.withValues(alpha: 0.3)),
                  padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: theme.space(1.5),
                    children: [
                      GhIcon(GhIcons.folderPlus, size: theme.space(3.5), color: theme.accentBright),
                      Text(ghTr('create_project_btn'), style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: theme.accentBright)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
