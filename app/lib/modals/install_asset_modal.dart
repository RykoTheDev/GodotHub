import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/asset_library.dart';
import '../api/templates.dart';
import '../assets/asset_common.dart';
import '../design/design.dart';
import '../motion/presence.dart';
import '../src/rust/api/types.dart';
import '../state/app_signals.dart';
import '../state/asset_prefs.dart';
import '../state/projects.dart';
import '../state/keyboard_shortcuts.dart';
import '../state/shell_signals.dart';
import '../ui/controls/checkbox.dart';
import '../ui/controls/dashed_box.dart';
import '../ui/controls/text_input.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/core/tooltip.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/reusables/card_kit.dart';
import '../ui/reusables/modal_kit.dart';
import '../ui/shell/smooth_scroll.dart';

enum AssetInstallTarget { project, template }

typedef AssetInstallOutcome = ({String assetId, AssetInstallTarget targetType, String targetName});

typedef _Row = ({String id, String name, String path, String godotVersion, String? description});

class InstallAssetModal extends ConsumerStatefulWidget {
  const InstallAssetModal({super.key, required this.asset, required this.onClose, required this.onInstalled});

  final AssetLibraryAsset asset;
  final VoidCallback onClose;
  final ValueChanged<AssetInstallOutcome> onInstalled;

  @override
  ConsumerState<InstallAssetModal> createState() => _InstallAssetModalState();
}

class _InstallAssetModalState extends ConsumerState<InstallAssetModal> {
  final TextEditingController _query = TextEditingController();
  final FocusNode _queryNode = FocusNode(debugLabel: 'InstallAssetModal search');
  AssetInstallTarget _tab = AssetInstallTarget.project;
  List<ProjectTemplate> _templates = const [];

  /// Selected targets in the current tab; installs run one after another.
  final Set<String> _selected = {};
  int _done = 0;

  /// Per-target results of the last run, shown when any target failed.
  Map<String, String?> _results = const {};
  bool _installing = false;
  bool _detached = false;
  String? _error;

  AssetLibraryAsset get _asset => widget.asset;

  bool get _canCreateTemplate => _asset.source != 'store' && _asset.assetType == 'project';

  void _close() {
    if (_installing) _detached = true;
    widget.onClose();
  }

  void _failed(Object e) {
    if (_detached || !mounted) {
      ghToasts.pushToast(GhToastType.error, ghTr('asset_install_failed_toast', args: {'title': _asset.title, 'error': '$e'}));
    } else {
      setState(() => _error = '$e');
    }
  }

  void _finish(AssetInstallOutcome outcome) {
    widget.onInstalled(outcome);
    if (!_detached) widget.onClose();
  }

  void _newProject() {
    widget.onClose();
    AppSignals.emit(newProjectRequestSignal);
  }

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
    _queryNode.addListener(() => setState(() {}));
    TemplatesApi.list().then(
      (list) {
        if (mounted) setState(() => _templates = list);
      },
      onError: (Object _) {
        if (mounted) setState(() => _templates = const []);
      },
    );
  }

  @override
  void dispose() {
    _query.dispose();
    _queryNode.dispose();
    super.dispose();
  }

  List<_Row> _rows(List<Project> projects, {bool filtered = true}) {
    final q = filtered ? _query.text.trim().toLowerCase() : '';
    final List<_Row> all = _tab == AssetInstallTarget.project
        ? [
            for (final p in projects)
              if (!p.missing) (id: p.id, name: p.name, path: p.path, godotVersion: p.godotVersion, description: null),
          ]
        : [for (final t in _templates) (id: t.id, name: t.name, path: t.path, godotVersion: t.godotVersion, description: t.description)];
    return [
      for (final row in all)
        if (row.name.toLowerCase().contains(q) || row.path.toLowerCase().contains(q)) row,
    ];
  }

  Future<void> _installOne(AssetInstallTarget tab, String targetId) async {
    if (_asset.source == 'store') {
      final (publisher, slug) = parseStoreId(_asset.assetId);
      if (tab == AssetInstallTarget.project) {
        await AssetLibraryApi.installStoreAsset(publisher, slug, _asset.title, targetId, null);
      } else {
        await AssetLibraryApi.installStoreAsset(publisher, slug, _asset.title, null, targetId);
      }
    } else if (tab == AssetInstallTarget.project) {
      await AssetLibraryApi.install(_asset.assetId, targetId, null);
    } else {
      await AssetLibraryApi.install(_asset.assetId, null, targetId);
    }
  }

  /// Installs into every selected target in turn. Each success is reported
  /// as it lands; when any target fails the dialog stays open with a result
  /// per target and only the failed ones still selected, ready to retry.
  Future<void> _install(List<_Row> targets) async {
    setState(() {
      _installing = true;
      _error = null;
      _done = 0;
      _results = const {};
    });
    final tab = _tab;
    // Read before awaiting: the dialog may be closed while installs continue.
    final installations = ref.read(assetInstallationsProvider.notifier);
    final results = <String, String?>{};
    for (final target in targets) {
      try {
        await _installOne(tab, target.id);
        results[target.id] = null;
        widget.onInstalled((assetId: _asset.assetId, targetType: tab, targetName: target.name));
      } catch (e) {
        results[target.id] = '$e';
      }
      if (mounted && !_detached) setState(() => _done++);
    }
    installations.refresh().ignore();
    final failed = {
      for (final e in results.entries)
        if (e.value != null) e.key: e.value!,
    };
    if (failed.isEmpty) {
      if (!_detached) widget.onClose();
    } else if (_detached || !mounted) {
      for (final target in targets.where((t) => failed.containsKey(t.id))) {
        ghToasts.pushToast(
          GhToastType.error,
          ghTr(
            'asset_install_failed_toast',
            args: {'title': targets.length == 1 ? _asset.title : '${_asset.title} (${target.name})', 'error': failed[target.id]},
          ),
        );
      }
    } else {
      setState(() {
        _results = results;
        _selected.removeWhere((id) => results[id] == null);
        _error = targets.length == 1 ? failed.values.first : ghTr('asset_install_some_failed', args: {'count': failed.length});
      });
    }
    if (mounted) setState(() => _installing = false);
  }

  Future<void> _saveAsNewTemplate() async {
    setState(() {
      _installing = true;
      _error = null;
    });
    try {
      final template = await AssetLibraryApi.installAsTemplate(_asset.assetId);
      AppSignals.emit(refreshTemplatesSignal);
      _finish((assetId: _asset.assetId, targetType: AssetInstallTarget.template, targetName: template.name));
    } catch (e) {
      _failed(e);
    } finally {
      if (mounted) setState(() => _installing = false);
    }
  }

  Widget _tabButton(GhTheme theme, AssetInstallTarget value, FaIconData icon, String label) {
    final active = _tab == value;
    final radius = BorderRadius.circular(theme.radiusBtn);
    return Expanded(
      child: GhPressable(
        onPressed: _installing
            ? null
            : () => setState(() {
                _tab = value;
                _selected.clear();
                _results = const {};
              }),
        selected: active,
        borderRadius: radius,
        builder: (context, states) {
          final color = active ? Colors.white : (states.active ? theme.ink : theme.muted);
          return GhAnimatedBox(
            height: theme.space(8),
            padding: EdgeInsets.symmetric(horizontal: theme.space(3)),
            color: active ? theme.accent : (states.active ? theme.raised : theme.raised.withValues(alpha: 0)),
            borderRadius: radius,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: theme.space(2),
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
      ),
    );
  }

  Widget _newTemplateButton(GhTheme theme) {
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      onPressed: _installing ? null : _saveAsNewTemplate,
      disabledOpacity: 0.5,
      disabledCursor: SystemMouseCursors.forbidden,
      borderRadius: radius,
      builder: (context, states) => GhDashedBox(
        color: theme.mint.withValues(alpha: 0.3),
        radius: radius,
        child: GhAnimatedBox(
          color: theme.mint.withValues(alpha: states.active ? 0.1 : 0.05),
          borderRadius: radius,
          padding: EdgeInsets.all(theme.space(3)),
          child: Row(
            spacing: theme.space(3),
            children: [
              Container(
                width: theme.space(8),
                height: theme.space(8),
                decoration: BoxDecoration(color: theme.mint.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(theme.radiusTile)),
                alignment: Alignment.center,
                child: GhIcon(GhIcons.download, size: theme.space(4), color: theme.mint),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ghTr('asset_new_template_btn'),
                      style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: theme.space(0.5)),
                      child: Text(
                        ghTr('asset_new_template_hint'),
                        style: theme.text(size: GhTextSize.x2s, color: theme.muted.withValues(alpha: 0.7), lineHeight: 1.375),
                      ),
                    ),
                  ],
                ),
              ),
              if (_installing && _selected.isEmpty) GhSpinnerIcon(size: 4, color: theme.mint),
            ],
          ),
        ),
      ),
    );
  }

  Widget _search(GhTheme theme) {
    final focused = _queryNode.hasFocus;
    return GhAnimatedBox(
      height: theme.space(10),
      padding: EdgeInsets.symmetric(horizontal: theme.space(3)),
      color: focused ? theme.raised : theme.overlay,
      borderRadius: BorderRadius.circular(theme.radiusItem),
      border: Border.all(color: focused ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
      child: Row(
        spacing: theme.space(2),
        children: [
          GhIcon(GhIcons.search, size: theme.space(3.5), color: theme.muted),
          Expanded(
            child: GhTextInput(
              controller: _query,
              focusNode: _queryNode,
              bordered: false,
              background: Colors.transparent,
              weight: GhWeight.medium,
              placeholderColor: theme.muted.withValues(alpha: 0.7),
              padding: EdgeInsets.zero,
              placeholder: _tab == AssetInstallTarget.project ? ghTr('asset_install_search_projects') : ghTr('template_search_placeholder'),
            ),
          ),
        ],
      ),
    );
  }

  void _toggle(String id) => setState(() => _selected.contains(id) ? _selected.remove(id) : _selected.add(id));

  Widget _row(GhTheme theme, _Row item, {List<AssetInstallation> installs = const []}) {
    final selected = _selected.contains(item.id);
    final result = _results[item.id];
    final hasResult = _results.containsKey(item.id);
    final radius = BorderRadius.circular(theme.radiusItem);
    final project = _tab == AssetInstallTarget.project;
    final subtitle = project
        ? '${item.godotVersion.isNotEmpty ? 'Godot ${item.godotVersion} · ' : ''}${item.path}'
        : (item.description ?? '');
    return GhPressable(
      onPressed: _installing ? null : () => _toggle(item.id),
      checked: selected,
      borderRadius: radius,
      builder: (context, states) => GhAnimatedBox(
        padding: EdgeInsets.all(theme.space(2.5)),
        color: selected ? theme.accent.withValues(alpha: 0.1) : (states.active ? theme.raised : theme.raised.withValues(alpha: 0)),
        borderRadius: radius,
        border: Border.all(
          color: selected
              ? theme.accentDim.withValues(alpha: 0.6)
              : (states.active ? theme.outline.withValues(alpha: 0.5) : Colors.transparent),
        ),
        child: Row(
          spacing: theme.space(3),
          children: [
            Container(
              width: theme.space(8),
              height: theme.space(8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? theme.accent.withValues(alpha: 0.2) : theme.raised,
                borderRadius: BorderRadius.circular(theme.radiusTile),
                border: Border.all(color: selected ? theme.accentDim.withValues(alpha: 0.4) : theme.outline.withValues(alpha: 0.5)),
              ),
              child: GhIcon(
                project ? GhIcons.folderPlus : GhIcons.copy,
                size: theme.space(3.5),
                color: selected ? theme.accentBright : theme.muted,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: theme.space(0.5)),
                    child: Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.text(size: GhTextSize.x3s, mono: true, color: theme.muted.withValues(alpha: 0.6)),
                    ),
                  ),
                ],
              ),
            ),
            if (installs.isNotEmpty && !hasResult)
              GhBadge(
                label: ghTr('asset_installed'),
                tone: GhTone.mint,
                tooltip: installs.map((i) => i.version).where((v) => v.isNotEmpty).join(', '),
              ),
            if (hasResult)
              GhTooltip(
                message: result ?? ghTr('asset_install_target_done'),
                child: GhIcon(
                  result == null ? GhIcons.circleCheck : GhIcons.circleX,
                  size: theme.space(4),
                  color: result == null ? theme.mint : theme.danger,
                ),
              ),
            ExcludeSemantics(
              child: GhCheckbox(checked: selected, disabled: _installing, onChanged: (_) => _toggle(item.id)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final projects = ref.watch(projectsProvider).data;
    final rows = _rows(projects);
    final installsByProject = <String, List<AssetInstallation>>{};
    for (final i in ref.watch(assetInstallationsProvider).data.where((i) => i.assetId == _asset.assetId)) {
      installsByProject.putIfAbsent(i.projectId, () => []).add(i);
    }
    final allRows = _rows(projects, filtered: false);
    final targets = [
      for (final r in allRows)
        if (_selected.contains(r.id)) r,
    ];
    final selectedName = targets.length == 1 ? targets.single.name : null;
    final allVisibleSelected = rows.isNotEmpty && rows.every((r) => _selected.contains(r.id));
    final radius = BorderRadius.circular(theme.radiusItem);
    final iconUrl = _asset.iconUrl;
    final canInstall = targets.isNotEmpty && !_installing;
    final project = _tab == AssetInstallTarget.project;
    return GhModalShell(
      icon: iconUrl != null && iconUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(theme.radiusTile),
              child: Image.network(
                iconUrl,
                frameBuilder: ghFadeInFrameBuilder,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stack) => const SizedBox.shrink(),
              ),
            )
          : GhIcon(GhIcons.store, size: theme.space(5), color: theme.muted),
      title: ghTr('asset_install_modal_title', args: {'title': _asset.title}),
      maxWidth: GhModalWidth.md,
      onClose: _close,
      error: _error,
      footer: ghModalActions(
        trailing: [
          GhButton(key: const ValueKey('asset-install-close'), onPressed: _close, label: _installing ? ghTr('close') : ghTr('cancel')),
        ],
        primary: GhBusyButton(
          key: const ValueKey('asset-install-submit'),
          onPressed: canInstall ? () => _install(targets).ignore() : null,
          busy: _installing,
          icon: GhIcons.download,
          label: _installing
              ? (targets.length > 1
                    ? ghTr('asset_installing_progress', args: {'done': _done + 1, 'total': targets.length})
                    : ghTr('asset_installing'))
              : selectedName != null
              ? ghTr('asset_install_into', args: {'name': selectedName})
              : targets.length > 1
              ? ghTr('asset_install_into_many', args: {'count': targets.length})
              : ghTr('asset_install'),
        ),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(theme.space(5), 0, theme.space(5), theme.space(4)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(3),
          children: [
            Text(
              ghTr(project ? 'asset_install_intro_project' : 'asset_install_intro_template', args: {'title': _asset.title}),
              style: theme.text(size: GhTextSize.sm, color: theme.muted, lineHeight: 1.6),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(1.5),
              children: [
                Text(
                  ghTr('asset_install_where_label'),
                  style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: theme.ink),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.overlay,
                    borderRadius: radius,
                    border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(theme.space(1)),
                    child: Row(
                      spacing: theme.space(1),
                      children: [
                        _tabButton(theme, AssetInstallTarget.project, GhIcons.folderPlus, ghTr('asset_install_tab_project')),
                        _tabButton(theme, AssetInstallTarget.template, GhIcons.copy, ghTr('asset_install_tab_template')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_installing)
              Semantics(
                liveRegion: true,
                child: Container(
                  padding: EdgeInsets.all(theme.space(2.5)),
                  decoration: BoxDecoration(
                    color: theme.accent.withValues(alpha: 0.08),
                    borderRadius: radius,
                    border: Border.all(color: theme.accentDim.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: theme.space(2),
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: theme.space(0.5)),
                        child: GhIcon(GhIcons.info, size: theme.space(3.5), color: theme.accentBright),
                      ),
                      Expanded(
                        child: Text(
                          ghTr('asset_install_continues'),
                          style: theme.text(size: GhTextSize.xs, color: theme.ink, lineHeight: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_canCreateTemplate && !project) _newTemplateButton(theme),
            Row(
              children: [
                Expanded(child: _search(theme)),
                if (rows.length > 1)
                  Padding(
                    padding: EdgeInsetsDirectional.only(start: theme.space(2)),
                    child: GhButton(
                      key: const ValueKey('asset-install-select-all'),
                      onPressed: _installing
                          ? null
                          : () => setState(() {
                              if (allVisibleSelected) {
                                _selected.removeAll(rows.map((r) => r.id));
                              } else {
                                _selected.addAll(rows.map((r) => r.id));
                              }
                            }),
                      label: allVisibleSelected ? ghTr('asset_install_select_none') : ghTr('asset_install_select_all'),
                      variant: GhButtonVariant.ghost,
                      size: GhTextSize.xs,
                    ),
                  ),
              ],
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: theme.space(72)),
              child: rows.isEmpty
                  ? Padding(
                      padding: EdgeInsets.only(bottom: theme.space(1)),
                      child: GhDashedBox(
                        color: theme.outline.withValues(alpha: 0.5),
                        radius: radius,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: theme.space(8), horizontal: theme.space(4)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            spacing: theme.space(3),
                            children: [
                              GhIcon(GhIcons.store, size: theme.space(5), color: theme.muted.withValues(alpha: 0.5)),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 260),
                                child: Text(
                                  project ? ghTr('asset_install_no_projects') : ghTr('asset_install_no_templates'),
                                  textAlign: TextAlign.center,
                                  style: theme.text(size: GhTextSize.xs, color: theme.muted, lineHeight: 1.625),
                                ),
                              ),
                              if (project && _query.text.trim().isEmpty)
                                GhButton(
                                  key: const ValueKey('asset-install-new-project'),
                                  onPressed: _installing ? null : _newProject,
                                  icon: GhIcons.folderPlus,
                                  label: ghTr('new_project'),
                                  variant: GhButtonVariant.outline,
                                ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : GhScrollView(
                      padding: EdgeInsets.only(bottom: theme.space(1)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: theme.space(1.5),
                        children: [
                          for (final item in rows)
                            _row(theme, item, installs: project ? (installsByProject[item.id] ?? const []) : const []),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
