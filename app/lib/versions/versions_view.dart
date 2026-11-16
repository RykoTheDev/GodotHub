import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/opener.dart';
import '../api/versions.dart';
import '../design/design.dart';
import '../logic/export_template_catalog.dart';
import '../logic/format_bytes.dart';
import '../modals/download_error_modal.dart';
import '../modals/version_aliases_modal.dart';
import '../motion/animated_number.dart';
import '../motion/reveal.dart';
import '../src/rust/api/types.dart';
import '../src/ui_prefs.dart';
import '../state/app_signals.dart';
import '../state/export_template_downloads.dart';
import '../state/godot_versions.dart';
import '../state/keyboard_shortcuts.dart' show focusSearchSignal;
import '../state/settings.dart';
import '../state/shell_signals.dart';
import '../state/task_tray.dart';
import '../ui/controls/search_bar.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/core/tooltip.dart';
import '../ui/core/ui_settings.dart' show GhSide;
import '../ui/feedback/confirm_dialog.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/overlays/dropdown.dart';
import '../ui/overlays/menu.dart';
import '../ui/core/button.dart';
import '../ui/reusables/modal_kit.dart';
import '../ui/reusables/state_panel.dart';
import '../ui/reusables/tool_buttons.dart';
import '../ui/reusables/view_header.dart';
import '../ui/shell/overlay_scroll_area.dart';
import '../ui/shell/view_insets.dart';
import 'available_version_card.dart';
import 'installed_version_card.dart';
import 'version_logic.dart';

String _tv(String key, {num? count, Map<String, Object?> args = const {}}) => ghTr('versions:$key', count: count, args: args);

void _toastError(Object error) => ghToasts.pushToast(GhToastType.error, '$error', ttlMs: 6000);

class VersionsView extends ConsumerStatefulWidget {
  const VersionsView({super.key, this.onOpenSettings, this.connected = false, this.prefs});

  final VoidCallback? onOpenSettings;
  final bool connected;
  final UiPrefsStore? prefs;

  @override
  ConsumerState<VersionsView> createState() => _VersionsViewState();
}

class _VersionsViewState extends ConsumerState<VersionsView> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchNode = FocusNode(debugLabel: 'VersionsView search');
  final GlobalKey<GhImportButtonState> _import = GlobalKey();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  late VersionFilters _filters = VersionFilters.decode(_prefs.getItem(versionFiltersKey));
  late VersionSort _sort = VersionSort.parse(_prefs.getItem(versionSortKey), installed: false);
  late VersionSort _installedSort = VersionSort.parse(_prefs.getItem(versionInstalledSortKey), installed: true);
  final Set<String> _collapsed = {};
  int _visibleGroups = 5;
  Object? _groupInputs;
  List<(String, List<AvailableRow>)> _groups = const [];
  bool _scanning = false;
  DownloadErrorInfo? _shownError;

  UiPrefsStore get _prefs => widget.prefs ?? UiPrefsStore.instance;

  GodotVersionsNotifier get _versions => ref.read(godotVersionsProvider.notifier);

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    void on(String name, void Function() handler) => _subscriptions.add(AppSignals.on(name).listen((_) => handler()));
    on(focusSearchSignal, _searchNode.requestFocus);
    on(scanVersionsSignal, () => _scanNow().ignore());
    on(importVersionSignal, () => _import.currentState?.trigger().ignore());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _versions.refreshMiseStatus().ignore();
    });
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

  void _setFilters(VersionFilters next) {
    setState(() => _filters = next);
    _prefs.setItem(versionFiltersKey, next.encode());
  }

  void _setSort(VersionSort next) {
    setState(() => _sort = next);
    _prefs.setItem(versionSortKey, next.id);
  }

  void _setInstalledSort(VersionSort next) {
    setState(() => _installedSort = next);
    _prefs.setItem(versionInstalledSortKey, next.id);
  }

  Future<void> _runTask(String label, String description, Future<void> Function() work) async {
    final tray = ref.read(taskTrayProvider.notifier);
    final id = '${label.hashCode}-${DateTime.now().microsecondsSinceEpoch}';
    tray.registerTask(TrayTask(id: id, type: TaskType.importVersions, label: label, description: description, status: TaskStatus.running));
    try {
      await work();
      await _versions.refreshInstalled();
      tray.updateTask(id, status: TaskStatus.completed);
      tray.scheduleRemoval(id, taskCompletedRemovalDelay);
    } catch (e) {
      tray.updateTask(id, status: TaskStatus.error, errorMessage: '$e');
      tray.scheduleRemoval(id, taskErrorRemovalDelay);
    }
  }

  Future<void> _importVersion(String folder) => _runTask(_tv('importing_version'), folder, () => VersionsApi.import(folder));

  Future<void> _addCustomBuild() async {
    String? file;
    try {
      file = await VersionsApi.pickExecutable();
    } catch (e) {
      _toastError(e);
      return;
    }
    if (file == null) return;
    await _runTask(_tv('adding_custom_build'), file, () => VersionsApi.addCustomBuild(file!, null));
  }

  Future<void> _scanNow() async {
    if (_scanning) return;
    final settings = ref.read(settingsProvider).value;
    if (settings == null) return;
    if (settings.versionScanDirs.isEmpty) {
      final open = widget.onOpenSettings;
      if (open != null) {
        open();
      } else {
        AppSignals.emit(openSettingSignal, 'version_scan_dirs');
      }
      return;
    }
    setState(() => _scanning = true);
    try {
      await VersionsApi.scan(settings.versionScanDirs, settings.scanDepth);
    } catch (e) {
      _toastError(e);
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _removeTemplates(ExportTemplatesVersionInfo info) async {
    try {
      await VersionsApi.deleteExportTemplates(info.folder, info.root);
      setTemplateFilesInstalled(info.tag, null, false);
      await _versions.refreshExportTemplates();
      ghToasts.pushToast(GhToastType.success, _tv('export_templates_removed_toast'));
    } catch (e) {
      _toastError(e);
    }
  }

  Future<void> _deleteOrphan(ExportTemplatesOrphan orphan) async {
    final ok = await showGhConfirmDialog(
      context,
      title: _tv('export_templates_orphan_delete_title'),
      description: _tv('export_templates_orphan_delete_desc', args: {'folder': orphan.folder}),
      confirmLabel: _tv('export_templates_orphan_delete'),
      variant: GhConfirmVariant.danger,
    );
    if (!ok) return;
    try {
      await VersionsApi.deleteExportTemplates(orphan.folder, orphan.root);
      await _versions.refreshExportTemplates();
      ghToasts.pushToast(GhToastType.success, _tv('export_templates_orphan_deleted'));
    } catch (e) {
      _toastError(e);
    }
  }

  void _openTemplatesFolder([String? tag]) => VersionsApi.openExportTemplatesFolder(tag).catchError(_toastError);

  Future<void> _openAliases({String? tag}) => showGhModal<void>(
    context,
    (modal) => Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(godotVersionsProvider);
        final notifier = ref.read(godotVersionsProvider.notifier);
        return VersionAliasesModal(
          versions: state.installed,
          aliases: state.aliases,
          aliasesDir: state.aliasesDir,
          initialTag: tag,
          onClose: () => Navigator.of(modal).pop(),
          onCreateMany: notifier.createAliases,
          onDelete: notifier.deleteAlias,
        );
      },
    ),
  );

  void _maybeShowError(DownloadErrorInfo? error) {
    if (error == null || identical(error, _shownError)) return;
    _shownError = error;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showGhModal<void>(
        context,
        (modal) => DownloadErrorModal(
          error: error,
          onRetry: () {
            Navigator.of(modal).pop();
            _versions.retryDownload().ignore();
          },
          onClose: () => Navigator.of(modal).pop(),
        ),
      ).whenComplete(() {
        if (ref.read(godotVersionsProvider).downloadError == error) _versions.dismissDownloadError();
        _shownError = null;
      });
    });
  }

  Widget _pill(
    GhTheme theme, {
    required String label,
    required String value,
    required bool open,
    required VoidCallback onPressed,
    bool small = false,
  }) {
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      onPressed: onPressed,
      expanded: open,
      borderRadius: radius,
      builder: (context, states) => GhAnimatedBox(
        height: theme.space(small ? 7 : 8),
        color: states.active ? theme.raised : theme.overlay,
        borderRadius: radius,
        padding: EdgeInsets.symmetric(horizontal: theme.space(small ? 3 : 4)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: theme.space(1.5),
          children: [
            Text(
              '$label:',
              style: theme.text(size: small ? GhTextSize.xs : GhTextSize.sm, color: theme.muted),
            ),
            Text(
              value,
              style: theme.text(size: small ? GhTextSize.sm : GhTextSize.base, weight: GhWeight.medium, color: theme.ink),
            ),
            GhIcon(GhIcons.chevronDown, size: theme.space(3), color: theme.muted),
          ],
        ),
      ),
    );
  }

  Widget _smallButton(GhTheme theme, {required Widget child, required VoidCallback onPressed}) {
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      builder: (context, states) => GhAnimatedBox(
        height: theme.space(7),
        color: states.active ? theme.raised : theme.overlay,
        borderRadius: radius,
        padding: EdgeInsets.symmetric(horizontal: theme.space(3)),
        alignment: Alignment.center,
        child: DefaultTextStyle.merge(
          style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: states.active ? theme.ink : theme.muted),
          child: child,
        ),
      ),
    );
  }

  Widget _sectionTitle(GhTheme theme, String text) => GhReveal(
    kind: GhRevealKind.heading,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: theme.space(1)),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: theme.text(size: GhTextSize.sm, weight: GhWeight.semibold, color: theme.muted),
        ),
      ),
    ),
  );

  void _clearSearch() {
    _search.clear();
    _searchNode.requestFocus();
  }

  void _resetFilters() {
    _setFilters(const VersionFilters());
    if (_search.text.isNotEmpty) _search.clear();
  }

  void _openTokenSettings() => AppSignals.emit(openSettingsCategorySignal, 'integrations');

  Widget _installedSection(
    GhTheme theme,
    GodotVersionsState state,
    AppSettings settings,
    Map<String, ExportTemplateDownload> templateDownloads,
  ) {
    final query = _search.text.trim();
    final searching = query.isNotEmpty;
    final installed = filterAndSortInstalled(state.installed, query, _installedSort);
    if (state.installed.isEmpty && !searching) {
      return GhStatePanel.empty(
        key: const ValueKey('versions-empty-installed'),
        icon: GhIcons.download,
        title: _tv('no_installed_title'),
        message: ghTr('version_no_installed'),
        actions: [
          GhButton(
            onPressed: () => _import.currentState?.trigger().ignore(),
            label: ghTr('import_version'),
            icon: GhIcons.folderPlus,
            variant: GhButtonVariant.outline,
          ),
        ],
      );
    }
    final templates = state.exportTemplates;
    final mise = state.miseStatus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(2),
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle(theme, _tv('installed_heading'))),
            Wrap(
              spacing: theme.space(2),
              children: [
                _smallButton(theme, child: Text(_tv('templates_folder')), onPressed: () => _openTemplatesFolder()),
                _smallButton(theme, child: Text(_tv('versions_folder')), onPressed: () => VersionsApi.openFolder().catchError(_toastError)),
                if (settings.useMise)
                  GhTooltip(
                    message: _tv('mise_sync_title'),
                    side: GhSide.top,
                    child: _smallButton(
                      theme,
                      onPressed: () => _versions.syncMise().catchError((Object e) => ghToasts.pushToast(GhToastType.error, '$e')),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: theme.space(1.5),
                        children: [
                          Text(
                            'mise',
                            style: theme.text(size: GhTextSize.xs, mono: true, color: theme.muted),
                          ),
                          Text(
                            (mise?.available ?? false) ? _tv('mise_sync') : _tv('mise_missing'),
                            style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, mono: true, color: theme.ink),
                          ),
                        ],
                      ),
                    ),
                  ),
                GhDropdown(
                  items: [
                    for (final option in VersionSort.values)
                      GhMenuItem(
                        id: option.id,
                        label: _tv(option.labelKey),
                        active: option == _installedSort,
                        onSelected: () => _setInstalledSort(option),
                      ),
                  ],
                  trigger: (context, open, toggle) =>
                      _pill(theme, label: ghTr('sort'), value: _tv(_installedSort.labelKey), open: open, onPressed: toggle, small: true),
                ),
              ],
            ),
          ],
        ),
        if (installed.isEmpty)
          GhStatePanel.empty(
            key: const ValueKey('versions-empty-installed-search'),
            compact: true,
            icon: GhIcons.search,
            title: '${_tv('no_versions_match')} "$query"',
            actions: [GhButton(onPressed: _clearSearch, label: ghTr('clear_search'), variant: GhButtonVariant.outline)],
          ),
        for (final v in installed)
          InstalledVersionCard(
            key: ValueKey(v.tag),
            version: v,
            isCurrent: state.current?.tag == v.tag,
            updateTag: newerStableRelease(v, state.available, state.installed),
            onOpen: (console) => VersionsApi.open(v.tag, console).catchError((Object e) => ghToasts.pushToast(GhToastType.error, '$e')),
            onRename: (name) => _versions.rename(v.tag, name).catchError((Object e) {
              ghToasts.pushToast(GhToastType.error, '$e');
              return v;
            }),
            onSetCurrent: () => _versions.setCurrent(v.tag),
            onClearCurrent: _versions.clearCurrent,
            onManageAliases: () => _openAliases(tag: v.tag),
            onUninstall: () => _versions.remove(v.tag).catchError((Object e) => ghToasts.pushToast(GhToastType.error, '$e')),
            templates: templates?.versions.where((info) => info.tag == v.tag).firstOrNull,
            templateDownload: templateDownloads[v.tag],
            onInstallTemplates: (files) => ref
                .read(exportTemplateDownloadsProvider.notifier)
                .install(v.tag, files, onInstalled: _versions.refreshExportTemplates)
                .ignore(),
            onCancelTemplates: () => ref.read(exportTemplateDownloadsProvider.notifier).cancel(v.tag).ignore(),
            onRemoveTemplates: () {
              final info = templates?.versions.where((i) => i.tag == v.tag).firstOrNull;
              if (info != null) _removeTemplates(info).ignore();
            },
            onOpenTemplates: () => _openTemplatesFolder(v.tag),
            onTemplatesChanged: _versions.refreshExportTemplates,
          ),
        if (templates != null && templates.orphans.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(3)),
            decoration: BoxDecoration(
              color: theme.overlay,
              borderRadius: BorderRadius.circular(theme.radiusItem),
              border: Border.all(color: theme.outline.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(2),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tv('export_templates_orphans_title'),
                      style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: theme.muted),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: theme.space(0.5)),
                      child: Text(
                        _tv('export_templates_orphans_desc'),
                        style: theme.text(size: GhTextSize.xs, color: theme.muted.withValues(alpha: 0.8)),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: theme.space(1),
                  children: [
                    for (final orphan in templates.orphans)
                      Container(
                        key: ValueKey(orphan.path),
                        padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(1.5)),
                        decoration: BoxDecoration(
                          color: theme.raised.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(theme.radiusBtn),
                        ),
                        child: Row(
                          spacing: theme.space(2),
                          children: [
                            GhIcon(GhIcons.folder, size: theme.space(3.5), color: theme.muted),
                            Expanded(
                              child: Text(
                                orphan.folder,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.text(size: GhTextSize.xs, mono: true, color: theme.ink),
                              ),
                            ),
                            Text(
                              formatBytes(orphan.sizeBytes.toInt()),
                              style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted),
                            ),
                            GhTooltip(
                              message: _tv('export_templates_orphan_delete'),
                              child: GhPressable(
                                onPressed: () => _deleteOrphan(orphan),
                                semanticLabel: _tv('export_templates_orphan_delete'),
                                borderRadius: BorderRadius.circular(theme.radiusBtn),
                                builder: (context, states) => GhAnimatedBox(
                                  color: theme.danger.withValues(alpha: states.active ? 0.1 : 0),
                                  borderRadius: BorderRadius.circular(theme.radiusBtn),
                                  padding: EdgeInsets.all(theme.space(1)),
                                  child: GhIcon(GhIcons.trash, size: theme.space(3.5), color: states.active ? theme.danger : theme.muted),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _sourceLabel(VersionSource source) => switch (source) {
    VersionSource.archive => _tv('source_archive'),
    VersionSource.mise => _tv('source_mise'),
    VersionSource.github => _tv('source_github'),
  };

  Widget _availableFilters(GhTheme theme, GodotVersionsState state, AppSettings settings) {
    final source = state.source;
    String buildLabel(BuildTypeFilter value) => switch (value) {
      BuildTypeFilter.both => _tv('both'),
      BuildTypeFilter.mono => _tv('mono'),
      BuildTypeFilter.standard => _tv('standard'),
    };
    String channelLabel(ChannelFilter value) => switch (value) {
      ChannelFilter.both => _tv('both'),
      ChannelFilter.stable => _tv('stable'),
      ChannelFilter.unstable => _tv('unstable'),
    };
    return Wrap(
      spacing: theme.space(2),
      runSpacing: theme.space(2),
      children: [
        GhDropdown(
          align: GhSide.left,
          items: [
            GhMenuItem(
              id: 'github',
              label: _tv('source_github'),
              active: source == VersionSource.github,
              onSelected: () => _versions.refreshAvailable(VersionSource.github).ignore(),
            ),
            GhMenuItem(
              id: 'archive',
              label: _tv('source_archive'),
              active: source == VersionSource.archive,
              onSelected: () {
                _versions.refreshAvailable(VersionSource.archive).ignore();
                _setFilters(_filters.copyWith(channel: ChannelFilter.stable));
              },
            ),
            if (settings.useMise && (state.miseStatus?.available ?? false))
              GhMenuItem(
                id: 'mise',
                label: _tv('source_mise'),
                active: source == VersionSource.mise,
                onSelected: () {
                  _versions.refreshAvailable(VersionSource.mise).ignore();
                  _setFilters(_filters.copyWith(channel: ChannelFilter.stable));
                },
              ),
          ],
          trigger: (context, open, toggle) =>
              _pill(theme, label: _tv('source'), value: _sourceLabel(source), open: open, onPressed: toggle),
        ),
        GhDropdown(
          align: GhSide.left,
          items: [
            for (final value in [BuildTypeFilter.standard, BuildTypeFilter.mono, BuildTypeFilter.both])
              GhMenuItem(
                id: value.name,
                label: buildLabel(value),
                active: _filters.buildType == value,
                onSelected: () => _setFilters(_filters.copyWith(buildType: value)),
              ),
          ],
          trigger: (context, open, toggle) =>
              _pill(theme, label: _tv('type'), value: buildLabel(_filters.buildType), open: open, onPressed: toggle),
        ),
        if (source == VersionSource.github)
          GhDropdown(
            align: GhSide.left,
            items: [
              for (final value in [ChannelFilter.stable, ChannelFilter.unstable, ChannelFilter.both])
                GhMenuItem(
                  id: value.name,
                  label: channelLabel(value),
                  active: _filters.channel == value,
                  onSelected: () => _setFilters(_filters.copyWith(channel: value)),
                ),
            ],
            trigger: (context, open, toggle) =>
                _pill(theme, label: _tv('channel'), value: channelLabel(_filters.channel), open: open, onPressed: toggle),
          ),
        GhDropdown(
          align: GhSide.left,
          items: [
            for (final option in availableSortOptions)
              GhMenuItem(id: option.id, label: _tv(option.labelKey), active: option == _sort, onSelected: () => _setSort(option)),
          ],
          trigger: (context, open, toggle) => _pill(theme, label: ghTr('sort'), value: _tv(_sort.labelKey), open: open, onPressed: toggle),
        ),
      ],
    );
  }

  List<Widget> _availableSection(GhTheme theme, GodotVersionsState state, AppSettings settings) {
    final query = _search.text.trim();
    final inputs = (state.available, query, _filters, _sort);
    if (inputs != _groupInputs) {
      _groupInputs = inputs;
      _groups = groupAvailable(state.available, query, _filters, _sort);
    }
    final groups = _groups;
    final Widget? body;
    if (state.loadingAvailable) {
      body = GhStatePanel.loading(key: const ValueKey('versions-available-loading'), title: _tv('loading_available'), compact: true);
    } else if (state.availableError != null) {
      final error = state.availableError!;
      final rateLimited = isRateLimited(state.source, error);
      body = GhStatePanel.error(
        key: const ValueKey('versions-available-error'),
        title: _tv('fetch_error'),
        message: rateLimited ? _tv('fetch_error_rate_limited') : '${_tv('fetch_error_hint')}\n$error',
        onRetry: () => _versions.refreshAvailable().ignore(),
        actions: [
          if (rateLimited) ...[
            GhButton(
              onPressed: () => _versions.refreshAvailable(VersionSource.archive).ignore(),
              label: _tv('switch_to_archive'),
              variant: GhButtonVariant.primary,
            ),
            GhButton(onPressed: _openTokenSettings, label: _tv('add_github_token'), icon: GhIcons.github, variant: GhButtonVariant.ghost),
          ],
        ],
      );
    } else if (groups.isEmpty) {
      final filtered = _filters != const VersionFilters();
      body = GhStatePanel.empty(
        key: const ValueKey('versions-available-empty'),
        compact: true,
        icon: query.isNotEmpty ? GhIcons.search : GhIcons.filter,
        title: query.isNotEmpty ? '${_tv('no_available_versions_match')} "$query"' : _tv('no_available_versions_match'),
        message: filtered || query.isNotEmpty ? _tv('no_available_hint') : null,
        actions: [
          if (filtered) GhButton(onPressed: _resetFilters, label: _tv('reset_filters'), variant: GhButtonVariant.outline),
          if (!filtered && query.isNotEmpty)
            GhButton(onPressed: _clearSearch, label: ghTr('clear_search'), variant: GhButtonVariant.outline),
        ],
      );
    } else {
      body = null;
    }
    final gap = theme.space(2);
    final header = SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: gap,
        children: [_sectionTitle(theme, _tv('available_heading')), _availableFilters(theme, state, settings)],
      ),
    );
    if (body != null) {
      return [
        header,
        SliverPadding(
          padding: EdgeInsets.only(top: gap),
          sliver: SliverToBoxAdapter(child: body),
        ),
      ];
    }
    return [
      header,
      for (final (index, (group, rows)) in groups.take(_visibleGroups).indexed) ...[
        SliverPadding(
          key: ValueKey('header:$group'),
          padding: EdgeInsets.only(top: index == 0 ? gap : theme.space(4)),
          sliver: SliverToBoxAdapter(child: _groupHeader(theme, group, rows.length)),
        ),
        if (!_collapsed.contains(group))
          SliverList.builder(
            key: ValueKey('rows:$group'),
            itemCount: rows.length,
            findChildIndexCallback: (key) {
              final index = rows.indexWhere((row) => ValueKey(downloadKeyOf(row.tag, row.asset.name)) == key);
              return index < 0 ? null : index;
            },
            itemBuilder: (context, index) {
              final row = rows[index];
              final key = downloadKeyOf(row.tag, row.asset.name);
              return Padding(
                key: ValueKey(key),
                padding: EdgeInsets.only(top: gap),
                child: AvailableVersionCard(
                  tag: row.tag,
                  asset: row.asset,
                  source: state.source,
                  installed: isAvailableInstalled(state.installed, row.tag, row.asset.isMono),
                  download: state.downloads[key],
                  miseBusy: state.miseInstalls[key] ?? false,
                  onInstall: () => _versions.download(row.tag, row.asset.name, row.asset.downloadUrl).ignore(),
                  onOpenSource: () =>
                      OpenerApi.openUrl(sourcePageUrl(state.source, row.tag, state.miseStatus?.sourceUrl)).catchError(_toastError),
                  onPause: () => _versions.pause(key),
                  onResume: () => _versions.resume(key),
                  onCancel: () => _versions.cancel(key),
                ),
              );
            },
          ),
      ],
      if (_visibleGroups < groups.length)
        SliverPadding(
          padding: EdgeInsets.only(top: theme.space(4)),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: GhOutlineAction(onPressed: () => setState(() => _visibleGroups += 5), label: ghTr('show_more')),
            ),
          ),
        ),
    ];
  }

  Widget _groupHeader(GhTheme theme, String group, int count) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: GhPressable(
        onPressed: () => setState(() => _collapsed.contains(group) ? _collapsed.remove(group) : _collapsed.add(group)),
        expanded: !_collapsed.contains(group),
        borderRadius: BorderRadius.circular(theme.radiusBtn),
        builder: (context, states) {
          final color = states.active ? theme.ink : theme.muted;
          return Row(
            mainAxisSize: MainAxisSize.min,
            spacing: theme.space(1.5),
            children: [
              AnimatedRotation(
                turns: _collapsed.contains(group) ? (Directionality.of(context) == TextDirection.rtl ? 0.25 : -0.25) : 0,
                duration: GhDurations.iconTransform,
                child: GhIcon(GhIcons.chevronDown, size: theme.space(3), color: color),
              ),
              Text(
                group == 'Other' ? _tv('other') : group,
                style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: color),
              ),
              Text(
                '$count',
                style: theme.text(size: GhTextSize.x3s, weight: GhWeight.medium, color: theme.muted.withValues(alpha: 0.6)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr;
    final state = ref.watch(godotVersionsProvider);
    final settings = ref.watch(settingsProvider).value ?? defaultSettings;
    final templateDownloads = ref.watch(exportTemplateDownloadsProvider);
    _maybeShowError(state.downloadError);
    final insets = GhViewInsets.of(context);
    final scrollInsets = EdgeInsetsDirectional.only(
      start: insets.start >= theme.space(2) ? insets.start - theme.space(2) : insets.start,
      end: insets.end >= theme.space(4) ? insets.end - theme.space(4) : insets.end,
      bottom: insets.bottom >= theme.space(4) ? insets.bottom - theme.space(4) : insets.bottom,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: insets.start, end: insets.end),
          child: GhViewHeader(
            connected: widget.connected,
            title: tr.nav.versions,
            metric: [
              DefaultTextStyle.merge(
                style: theme.text(size: GhTextSize.x4l, weight: GhWeight.bold, color: theme.muted),
                child: GhAnimatedNumber(state.installed.length),
              ),
              Text(
                _tv('installed_count', count: state.installed.length),
                style: theme.text(size: GhTextSize.lg, weight: GhWeight.medium, color: theme.muted),
              ),
            ],
            actions: [
              GhPressable(
                onPressed: _openAliases,
                borderRadius: BorderRadius.circular(theme.radiusItem),
                builder: (context, states) => GhAnimatedBox(
                  height: theme.space(10),
                  color: states.active ? theme.raised : theme.overlay,
                  borderRadius: BorderRadius.circular(theme.radiusItem),
                  border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                  boxShadow: GhShadows.md(Colors.black.withValues(alpha: 0.1)),
                  padding: EdgeInsets.symmetric(horizontal: theme.space(6)),
                  alignment: Alignment.center,
                  child: Text(
                    _tv('aliases_manage'),
                    style: theme
                        .text(weight: GhWeight.semibold, color: states.active ? theme.ink : theme.muted)
                        .copyWith(fontSize: theme.rem(1.0625)),
                  ),
                ),
              ),
              GhImportButton(
                key: _import,
                disabled: _scanning,
                onImport: _importVersion,
                options: [
                  GhMenuItem(
                    id: 'add-custom-build',
                    label: _tv('add_custom_build'),
                    icon: GhIcons.plus,
                    onSelected: () => _addCustomBuild().ignore(),
                  ),
                ],
              ),
              GhScanButton(
                onOpenSettings: widget.onOpenSettings,
                disabled: _scanning,
                scanDirs: settings.versionScanDirs,
                scan: () async {
                  await VersionsApi.scan(settings.versionScanDirs, settings.scanDepth);
                  return const <String>[];
                },
                onComplete: () => _versions.refreshInstalled().ignore(),
                onScanStart: () => setState(() => _scanning = true),
                onScanEnd: () => setState(() => _scanning = false),
              ),
            ],
            child: GhSearchBar(
              value: _search.text,
              controller: _search,
              focusNode: _searchNode,
              placeholder: ghTr('version_search_placeholder'),
              onChanged: (_) {},
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: scrollInsets,
            child: GhOverlayScrollArea(
              hideThumb: !settings.showScrollbars,
              slivers: [
                SliverPadding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    theme.space(widget.connected ? 5 : 2),
                    theme.space(2),
                    theme.space(5),
                    theme.space(8),
                  ),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(child: _installedSection(theme, state, settings, templateDownloads)),
                      SliverPadding(
                        padding: EdgeInsets.only(top: theme.space(2)),
                        sliver: SliverMainAxisGroup(slivers: _availableSection(theme, state, settings)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
