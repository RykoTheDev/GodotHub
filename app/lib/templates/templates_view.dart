import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/asset_library.dart';
import '../api/templates.dart';
import '../assets/asset_library_browser.dart';
import '../design/design.dart';
import '../logic/locale.dart';
import '../logic/pending_action.dart';
import '../modals/create_project_modal.dart';
import '../modals/current_version_modal.dart' show openFolderOrToast;
import '../modals/template_preview_modal.dart';
import '../motion/animated_number.dart';
import '../motion/reveal.dart';
import '../src/rust/api/types.dart';
import '../src/ui_prefs.dart';
import '../state/app_signals.dart';
import '../state/asset_prefs.dart';
import '../state/categories.dart';
import '../state/godot_versions.dart';
import '../state/keyboard_shortcuts.dart' show focusSearchSignal;
import '../state/projects.dart';
import '../state/settings.dart';
import '../state/shell_signals.dart';
import '../state/task_tray.dart';
import '../state/workspaces.dart';
import '../ui/controls/search_bar.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/confirm_dialog.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/overlays/dropdown.dart';
import '../ui/overlays/menu.dart';
import '../ui/reusables/card_grid.dart';
import '../ui/reusables/card_kit.dart';
import '../ui/reusables/state_panel.dart';
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
  String? _loadError;
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

  final Set<String> _updating = {};

  Future<void> _updateTemplate(ProjectTemplate t, TemplateUpdate update) async {
    final confirmed = await showGhConfirmDialog(
      context,
      title: ghTr('template_update_confirm_title', args: {'name': t.name, 'version': update.latestVersion}),
      description: ghTr('template_update_confirm_desc', args: {'name': t.name}),
      confirmLabel: ghTr('template_update_btn'),
      cancelLabel: ghTr('cancel'),
    );
    if (!confirmed || !mounted) return;
    setState(() => _updating.add(t.id));
    try {
      await AssetLibraryApi.updateTemplate(t.id);
      ghToasts.pushToast(GhToastType.success, ghTr('template_updated_toast', args: {'name': t.name, 'version': update.latestVersion}));
      await _load();
    } catch (e) {
      ghToasts.pushToast(GhToastType.error, ghTr('template_update_failed', args: {'name': t.name, 'error': '$e'}));
    } finally {
      if (mounted) setState(() => _updating.remove(t.id));
    }
  }

  Future<void> _load() async {
    try {
      final list = await TemplatesApi.list();
      if (mounted) {
        setState(() {
          _templates = list;
          _loadError = null;
        });
        if (list.any((t) => t.sourceAssetId != null)) ref.read(templateUpdatesProvider.notifier).refresh().ignore();
      }
    } catch (e) {
      if (mounted) setState(() => _loadError = '$e');
    }
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

  void _preview(ProjectTemplate template) =>
      showGhModal<void>(context, (modal) => TemplatePreviewModal(template: template, onClose: () => Navigator.of(modal).pop())).ignore();

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
      if (mounted) {
        setState(
          () => _templates = [
            for (final t in _templates)
              if (t.id != template.id) t,
          ],
        );
      }
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
          style: theme
              .text(weight: GhWeight.semibold, color: states.active ? theme.ink : theme.muted)
              .copyWith(fontSize: theme.rem(1.0625)),
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
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: color),
                  ),
                ),
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
          Flexible(child: option(_TemplatesTab.local, ghTr('templates_tab_local'), GhIcons.copy)),
          Flexible(child: option(_TemplatesTab.asset, ghTr('templates_tab_asset'), GhIcons.store)),
        ],
      ),
    );
  }

  Widget _local(BuildContext context, GhTheme theme) {
    final updates = {for (final u in ref.watch(templateUpdatesProvider).data) u.templateId: u};
    final query = _search.text;
    if (!_loaded) {
      return GhCardGrid.fill(rows: 1, builder: (context, i) => GhCardSkeleton(key: ValueKey('template-skeleton-$i'), mediaHeight: null));
    }
    final error = _loadError;
    if (_templates.isEmpty && error != null) {
      return GhStatePanel.error(title: ghTr('templates_load_error'), message: error, onRetry: () => _load().ignore());
    }
    if (_templates.isEmpty) {
      return GhStatePanel.empty(
        icon: GhIcons.copy,
        title: ghTr('templates_empty_title'),
        message: ghTr('no_templates_yet').replaceAll(RegExp(r'</?\d+>'), ''),
        actions: [
          GhButton(
            onPressed: () => setState(() => _tab = _TemplatesTab.asset),
            label: ghTr('templates_browse_library'),
            icon: GhIcons.store,
            variant: GhButtonVariant.primary,
          ),
        ],
      );
    }
    final list = filterAndSortTemplates(_templates, query, _sort);
    if (list.isEmpty) {
      return GhStatePanel.empty(
        icon: GhIcons.search,
        title: '${ghTr('no_templates_match')} "$query"',
        actions: [GhButton(onPressed: _search.clear, label: ghTr('clear_search'), icon: GhIcons.x, variant: GhButtonVariant.outline)],
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
                    Text(
                      '${ghTr('sort')}:',
                      style: theme.text(size: GhTextSize.xs, color: theme.muted),
                    ),
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
        if (error != null)
          GhCardNotice(
            tone: GhTone.danger,
            message: ghTr('templates_load_error'),
            action: GhButton(onPressed: () => _load().ignore(), label: ghTr('retry'), size: GhTextSize.xs, paddingY: 1.5),
          ),
        GhCardGrid(
          children: [
            for (final t in list)
              TemplateCard(
                key: ValueKey(t.id),
                template: t,
                onPreview: () => _preview(t),
                onDelete: () => _confirmDelete(t).ignore(),
                onCreate: () => _create(t),
                update: updates[t.id],
                updating: _updating.contains(t.id),
                onUpdate: updates[t.id] == null ? null : () => _updateTemplate(t, updates[t.id]!).ignore(),
              ),
          ],
        ),
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
                ghTr(local ? 'template_your_templates' : 'asset_store_count', count: count),
                style: theme.text(size: GhTextSize.lg, weight: GhWeight.medium, color: theme.muted),
              ),
            ],
            actions: [
              if (scanDir != null && scanDir.isNotEmpty)
                _headerButton(theme, label: ghTr('open_folder'), onPressed: () => openFolderOrToast(scanDir)),
              GhScanButton(
                onOpenSettings: widget.onOpenSettings,
                scanDirs: [if (scanDir != null && scanDir.isNotEmpty) scanDir],
                scan: () async {
                  await _sync();
                  return const <String>[];
                },
              ),
            ],
            child: LayoutBuilder(
              builder: (context, constraints) {
                final search = GhSearchBar(
                  value: _search.text,
                  controller: _search,
                  focusNode: _searchNode,
                  placeholder: ghTr(local ? 'template_search_placeholder' : 'asset_search_placeholder'),
                  onChanged: (_) {},
                );
                // Narrow windows stack the tab switcher under the search box.
                if (constraints.maxWidth < theme.space(110)) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: theme.space(2),
                    children: [search, _tabSwitcher(theme)],
                  );
                }
                return Row(
                  spacing: theme.space(2),
                  children: [
                    Expanded(child: search),
                    _tabSwitcher(theme),
                  ],
                );
              },
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: scrollInsets,
            child: GhOverlayScrollArea(
              hideThumb: !settings.showScrollbars,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  theme.space(widget.connected ? 5 : 2),
                  theme.space(2),
                  theme.space(5),
                  theme.space(8),
                ),
                child: local
                    ? _local(context, theme)
                    : AssetLibraryBrowser(
                        query: _search.text,
                        onClearQuery: _search.clear,
                        onStatsChange: (stats) {
                          if (mounted && stats != _assetStats) setState(() => _assetStats = stats);
                        },
                        installedTemplateNames: [for (final t in _templates) t.name],
                        installedTemplateIds: {
                          for (final t in _templates)
                            if (t.sourceAssetId != null) t.sourceAssetId!,
                        },
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TemplateCard extends StatelessWidget {
  const TemplateCard({
    super.key,
    required this.template,
    required this.onPreview,
    required this.onDelete,
    required this.onCreate,
    this.update,
    this.updating = false,
    this.onUpdate,
  });

  final ProjectTemplate template;

  /// A newer upload of the Asset Library asset this template came from.
  final TemplateUpdate? update;
  final bool updating;
  final VoidCallback? onUpdate;
  final VoidCallback onPreview;
  final VoidCallback onDelete;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final t = template;
    final created = DateTime.tryParse(t.createdAt);
    final deleteLabel = ghTr('delete_template', args: {'name': t.name});
    return GhReveal(
      id: 'template:${t.id}',
      child: GhCard(
        onPressed: onPreview,
        builder: (context, highlighted) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: GhCardBody(
                leading: Container(
                  width: theme.space(9),
                  height: theme.space(9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.raised,
                    borderRadius: BorderRadius.circular(theme.radiusTile),
                    border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                  ),
                  child: GhIcon(GhIcons.copy, size: theme.space(4), color: theme.muted),
                ),
                title: t.name,
                meta: [if (t.godotVersion.isNotEmpty) '${ghTr('godot')} ${t.godotVersion}', if (created != null) formatLocaleDate(created)],
                description: t.description,
                badges: [
                  if (update != null)
                    GhBadge(
                      label: ghTr('template_update_available', args: {'version': update!.latestVersion}),
                      icon: GhIcons.arrowUp,
                      tone: GhTone.amber,
                      tooltip: ghTr('template_update_tip', args: {'installed': update!.installedVersion, 'latest': update!.latestVersion}),
                    ),
                ],
                trailing: AnimatedOpacity(
                  opacity: highlighted ? 1 : 0,
                  duration: GhDurations.color,
                  alwaysIncludeSemantics: true,
                  child: GhIconButton(
                    icon: GhIcons.trash,
                    onPressed: onDelete,
                    tooltip: deleteLabel,
                    semanticLabel: deleteLabel,
                    iconSpace: 3.5,
                  ),
                ),
              ),
            ),
            GhCardFooter(
              trailing: [
                if (onUpdate != null)
                  GhButton(
                    key: ValueKey('template-update-${t.id}'),
                    onPressed: updating ? null : onUpdate,
                    label: ghTr('template_update_btn'),
                    icon: GhIcons.arrowUp,
                    variant: GhButtonVariant.outline,
                  ),
                GhButton(
                  onPressed: onCreate,
                  label: ghTr('create_project_btn'),
                  icon: GhIcons.folderPlus,
                  variant: GhButtonVariant.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
