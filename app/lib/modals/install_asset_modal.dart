import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/asset_library.dart';
import '../api/templates.dart';
import '../assets/asset_common.dart';
import '../design/design.dart';
import '../motion/presence.dart';
import '../src/rust/api/types.dart';
import '../state/app_signals.dart';
import '../state/projects.dart';
import '../state/shell_signals.dart';
import '../ui/controls/dashed_box.dart';
import '../ui/controls/text_input.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/modal_shell.dart';
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
  String? _selectedId;
  bool _installing = false;
  String? _error;

  AssetLibraryAsset get _asset => widget.asset;

  bool get _canCreateTemplate => _asset.source != 'store' && _asset.assetType == 'project';

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

  List<_Row> _rows(List<Project> projects) {
    final q = _query.text.trim().toLowerCase();
    final List<_Row> all = _tab == AssetInstallTarget.project
        ? [for (final p in projects) (id: p.id, name: p.name, path: p.path, godotVersion: p.godotVersion, description: null)]
        : [for (final t in _templates) (id: t.id, name: t.name, path: t.path, godotVersion: t.godotVersion, description: t.description)];
    return [
      for (final row in all)
        if (row.name.toLowerCase().contains(q) || row.path.toLowerCase().contains(q)) row,
    ];
  }

  Future<void> _install(String targetId, String targetName) async {
    setState(() {
      _installing = true;
      _error = null;
    });
    final tab = _tab;
    try {
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
      widget.onInstalled((assetId: _asset.assetId, targetType: tab, targetName: targetName));
      widget.onClose();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _installing = false);
    }
  }

  Future<void> _saveAsNewTemplate() async {
    setState(() {
      _installing = true;
      _error = null;
    });
    try {
      final template = await AssetLibraryApi.installAsTemplate(_asset.assetId);
      AppSignals.emit(refreshTemplatesSignal);
      widget.onInstalled((assetId: _asset.assetId, targetType: AssetInstallTarget.template, targetName: template.name));
      widget.onClose();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _installing = false);
    }
  }

  Widget _tabButton(GhTheme theme, AssetInstallTarget value, FaIconData icon, String label) {
    final active = _tab == value;
    final radius = BorderRadius.circular(theme.radiusBtn);
    return Expanded(
      child: GhPressable(
        onPressed: () => setState(() {
          _tab = value;
          _selectedId = null;
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
              if (_installing && _selectedId == null) GhSpinnerIcon(size: 4, color: theme.mint),
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

  Widget _row(GhTheme theme, _Row item) {
    final selected = _selectedId == item.id;
    final radius = BorderRadius.circular(theme.radiusItem);
    final project = _tab == AssetInstallTarget.project;
    final subtitle = project
        ? '${item.godotVersion.isNotEmpty ? 'Godot ${item.godotVersion} · ' : ''}${item.path}'
        : (item.description ?? '');
    return GhPressable(
      onPressed: () => setState(() => _selectedId = item.id),
      selected: selected,
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
            if (selected)
              Container(
                width: theme.space(1.5),
                height: theme.space(1.5),
                decoration: BoxDecoration(color: theme.accent, shape: BoxShape.circle),
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
    final selectedId = _selectedId;
    final selectedName = selectedId == null
        ? null
        : (_tab == AssetInstallTarget.project
              ? projects.where((p) => p.id == selectedId).firstOrNull?.name
              : _templates.where((t) => t.id == selectedId).firstOrNull?.name);
    final radius = BorderRadius.circular(theme.radiusItem);
    final iconUrl = _asset.iconUrl;
    final canInstall = selectedId != null && !_installing;
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
      showClose: false,
      onClose: () {
        if (!_installing) widget.onClose();
      },
      footer: [
        GhPressable(
          onPressed: _installing ? null : widget.onClose,
          borderRadius: radius,
          builder: (context, states) => GhAnimatedBox(
            color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
            borderRadius: radius,
            padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(2)),
            child: Text(ghTr('cancel'), style: theme.text(color: states.active ? theme.ink : theme.muted)),
          ),
        ),
        GhPressable(
          onPressed: canInstall ? () => _install(selectedId, selectedName ?? '') : null,
          disabledCursor: SystemMouseCursors.forbidden,
          borderRadius: radius,
          rippleColor: Colors.white,
          builder: (context, states) => GhAnimatedBox(
            color: states.active && canInstall ? theme.accentBright : theme.accent,
            borderRadius: radius,
            padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(2)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: theme.space(2),
              children: [
                if (_installing) ...[
                  GhSpinnerIcon(color: Colors.white),
                  Text(
                    ghTr('asset_installing'),
                    style: theme.text(weight: GhWeight.medium, color: Colors.white),
                  ),
                ] else if (selectedName != null) ...[
                  GhIcon(GhIcons.download, size: theme.space(3.5), color: Colors.white),
                  Text(
                    ghTr('asset_install_into', args: {'name': selectedName}),
                    style: theme.text(weight: GhWeight.medium, color: Colors.white),
                  ),
                ] else
                  Text(
                    ghTr('asset_install'),
                    style: theme.text(weight: GhWeight.medium, color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
      ],
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(theme.space(5), 0, theme.space(5), theme.space(4)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(3),
          children: [
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
            if (_canCreateTemplate && _tab == AssetInstallTarget.template) _newTemplateButton(theme),
            _search(theme),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: theme.space(72)),
              child: rows.isEmpty
                  ? Padding(
                      padding: EdgeInsets.only(bottom: theme.space(1)),
                      child: GhDashedBox(
                        color: theme.outline.withValues(alpha: 0.5),
                        radius: radius,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: theme.space(10)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            spacing: theme.space(2),
                            children: [
                              GhIcon(GhIcons.store, size: theme.space(5), color: theme.muted.withValues(alpha: 0.5)),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 220),
                                child: Text(
                                  _tab == AssetInstallTarget.project
                                      ? ghTr('asset_install_no_projects')
                                      : ghTr('asset_install_no_templates'),
                                  textAlign: TextAlign.center,
                                  style: theme.text(size: GhTextSize.xs, color: theme.muted, lineHeight: 1.625),
                                ),
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
                        children: [for (final item in rows) _row(theme, item)],
                      ),
                    ),
            ),
            if (_error != null)
              Semantics(
                liveRegion: true,
                child: Container(
                  padding: EdgeInsets.all(theme.space(2.5)),
                  decoration: BoxDecoration(
                    color: theme.danger.withValues(alpha: 0.1),
                    borderRadius: radius,
                    border: Border.all(color: theme.danger.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: theme.space(2),
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: theme.space(0.5)),
                        child: GhIcon(GhIcons.alertTriangle, size: theme.space(3.5), color: theme.danger),
                      ),
                      Expanded(
                        child: Text(
                          _error!,
                          style: theme.text(size: GhTextSize.xs, color: theme.danger, lineHeight: 1.375),
                        ),
                      ),
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
