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
import '../motion/motion.dart';
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
import '../ui/reusables/modal_kit.dart';
import '../ui/reusables/tool_buttons.dart';
import '../ui/reusables/view_header.dart';
import '../ui/shell/overlay_scroll_area.dart';
import '../ui/shell/view_insets.dart';
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
      child: Text(
        text.toUpperCase(),
        style: theme.text(size: GhTextSize.x2s, weight: GhWeight.semibold, color: theme.muted, letterSpacingEm: 0.05),
      ),
    ),
  );

  Widget _dashedEmpty(GhTheme theme, {required Widget icon, required Widget text, double py = 20, Color? border}) => Container(
    padding: EdgeInsets.symmetric(vertical: theme.space(py), horizontal: theme.space(6)),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(theme.radiusItem),
      border: Border.all(color: border ?? theme.outline.withValues(alpha: 0.5)),
    ),
    child: Column(spacing: theme.space(3), children: [icon, text]),
  );

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
      return _dashedEmpty(
        theme,
        icon: Container(
          width: theme.space(12),
          height: theme.space(12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.overlay,
            borderRadius: BorderRadius.circular(theme.radiusTile),
            border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
          ),
          child: GhIcon(GhIcons.download, size: theme.space(5), color: theme.muted),
        ),
        text: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: theme.rem(24)),
          child: Text(
            ghTr('version_no_installed'),
            textAlign: TextAlign.center,
            style: theme.text(size: GhTextSize.sm, color: theme.muted, lineHeight: 1.625),
          ),
        ),
      );
    }
    if (installed.isEmpty && searching) {
      return _dashedEmpty(
        theme,
        py: 16,
        icon: GhIcon(GhIcons.search, size: theme.space(5), color: theme.muted),
        text: Text.rich(
          TextSpan(
            text: '${_tv('no_versions_match')} ',
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
            Expanded(child: _sectionTitle(theme, ghTr('installed_versions_section'))),
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
        for (final v in installed)
          InstalledVersionCard(
            key: ValueKey(v.tag),
            version: v,
            isCurrent: state.current?.tag == v.tag,
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
                      _tv('export_templates_orphans_title').toUpperCase(),
                      style: theme.text(size: GhTextSize.x2s, weight: GhWeight.semibold, color: theme.muted, letterSpacingEm: 0.05),
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
      body = Padding(
        padding: EdgeInsets.symmetric(vertical: theme.space(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: theme.space(2),
          children: [
            GhSpinnerIcon(size: 5, color: theme.muted),
            Text(
              ghTr('loading'),
              style: theme.text(size: GhTextSize.sm, color: theme.muted),
            ),
          ],
        ),
      );
    } else if (state.availableError != null) {
      final error = state.availableError!;
      body = _dashedEmpty(
        theme,
        py: 16,
        border: theme.danger.withValues(alpha: 0.3),
        icon: Container(
          width: theme.space(12),
          height: theme.space(12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.danger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(theme.radiusTile),
            border: Border.all(color: theme.danger.withValues(alpha: 0.3)),
          ),
          child: GhIcon(GhIcons.x, size: theme.space(5), color: theme.danger),
        ),
        text: Column(
          spacing: theme.space(3),
          children: [
            Text(
              _tv('fetch_error'),
              style: theme.text(size: GhTextSize.sm, color: theme.danger),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: theme.rem(28)),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: theme.text(size: GhTextSize.xs, mono: true, color: theme.muted),
              ),
            ),
            GhOutlineAction(onPressed: () => _versions.refreshAvailable().ignore(), label: _tv('retry')),
            if (isRateLimited(state.source, error))
              GhBusyButton(
                onPressed: () => _versions.refreshAvailable(VersionSource.archive).ignore(),
                busy: false,
                paddingX: 4,
                label: _tv('switch_to_archive'),
              ),
          ],
        ),
      );
    } else if (groups.isEmpty) {
      body = Padding(
        padding: EdgeInsets.symmetric(horizontal: theme.space(1)),
        child: Text.rich(
          TextSpan(
            text: _tv('no_available_versions_match'),
            children: [
              if (query.isNotEmpty) ...[
                const TextSpan(text: ' '),
                TextSpan(
                  text: '"$query"',
                  style: TextStyle(color: theme.ink, fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: '.'),
              ],
            ],
          ),
          style: theme.text(size: GhTextSize.sm, color: theme.muted),
        ),
      );
    } else {
      body = null;
    }
    final gap = theme.space(2);
    final header = SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: gap,
        children: [_sectionTitle(theme, _tv('available_title')), _availableFilters(theme, state, settings)],
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
              return Padding(
                key: ValueKey(downloadKeyOf(row.tag, row.asset.name)),
                padding: EdgeInsets.only(top: gap),
                child: _AvailableRowTile(
                  row: row,
                  state: state,
                  onInstall: () => _versions.download(row.tag, row.asset.name, row.asset.downloadUrl).ignore(),
                  onOpenSource: () =>
                      OpenerApi.openUrl(sourcePageUrl(state.source, row.tag, state.miseStatus?.sourceUrl)).catchError(_toastError),
                  onPause: _versions.pause,
                  onResume: _versions.resume,
                  onCancel: _versions.cancel,
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
                (group == 'Other' ? _tv('other') : group).toUpperCase(),
                style: theme.text(size: GhTextSize.x2s, weight: GhWeight.semibold, color: color, letterSpacingEm: 0.05),
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
                _tv('installed_count', count: state.installed.length).toUpperCase(),
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

class _AvailableRowTile extends StatefulWidget {
  const _AvailableRowTile({
    required this.row,
    required this.state,
    required this.onInstall,
    required this.onOpenSource,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
  });

  final AvailableRow row;
  final GodotVersionsState state;
  final VoidCallback onInstall;
  final VoidCallback onOpenSource;
  final Future<void> Function(String key) onPause;
  final Future<void> Function(String key) onResume;
  final Future<void> Function(String key) onCancel;

  @override
  State<_AvailableRowTile> createState() => _AvailableRowTileState();
}

class _AvailableRowTileState extends State<_AvailableRowTile> {
  bool _hovered = false;

  Widget _square(
    GhTheme theme, {
    required String tooltip,
    required FaIconData icon,
    required Color hover,
    required VoidCallback onPressed,
  }) => GhTooltip(
    message: tooltip,
    side: GhSide.top,
    child: GhPressable(
      onPressed: onPressed,
      semanticLabel: tooltip,
      borderRadius: BorderRadius.circular(theme.radiusBtn),
      builder: (context, states) => GhAnimatedBox(
        borderRadius: BorderRadius.circular(theme.radiusBtn),
        border: Border.all(color: states.active ? hover.withValues(alpha: 0.4) : theme.outline.withValues(alpha: 0.5)),
        padding: EdgeInsets.all(theme.space(2)),
        child: GhIcon(icon, size: theme.space(4), color: states.active ? hover : theme.muted),
      ),
    ),
  );

  void _guard(Future<void> Function(String key) action, String key) =>
      action(key).catchError((Object e) => ghToasts.pushToast(GhToastType.error, '$e'));

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final row = widget.row;
    final state = widget.state;
    final key = downloadKeyOf(row.tag, row.asset.name);
    final installed = isAvailableInstalled(state.installed, row.tag, row.asset.isMono);
    final dl = state.downloads[key];
    final miseBusy = state.miseInstalls[key] ?? false;
    final dot = installed
        ? theme.mint
        : dl != null || miseBusy
        ? theme.amber
        : theme.muted;
    final Widget trailing;
    if (miseBusy) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        spacing: theme.space(2),
        children: [
          GhSpinnerIcon(size: 4, color: theme.muted),
          Text(
            _tv('mise_installing'),
            style: theme.text(size: GhTextSize.xs, color: theme.muted),
          ),
        ],
      );
    } else if (dl != null) {
      final paused = dl.status == DownloadStatus.paused;
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        spacing: theme.space(2),
        children: [
          if (dl.status == DownloadStatus.queued)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: theme.space(2)),
              child: Text(
                ghTr('queued'),
                style: theme.text(size: GhTextSize.xs, mono: true, color: theme.muted),
              ),
            )
          else
            SizedBox(
              width: theme.space(56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(theme.space(1)),
                    child: Container(
                      height: theme.space(1.5),
                      color: theme.raised,
                      alignment: AlignmentDirectional.centerStart,
                      child: AnimatedFractionallySizedBox(
                        duration: GhMotion.of(context).css(GhDurations.progress),
                        curve: GhCurves.outExpo,
                        widthFactor: dl.total > 0 ? (dl.downloaded / dl.total).clamp(0.0, 1.0) : 0.06,
                        child: GhAnimatedBox(
                          duration: GhDurations.progress,
                          color: paused ? theme.muted : theme.amber,
                          borderRadius: BorderRadius.circular(theme.space(1)),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: theme.space(1)),
                    child: Text(
                      '${paused ? _tv('paused_dot') : ''}${(dl.downloaded / 1024 / 1024).toStringAsFixed(1)} MB${dl.total > 0 ? ' / ${(dl.total / 1024 / 1024).toStringAsFixed(1)} MB' : ''}',
                      style: theme
                          .text(size: GhTextSize.x2s, mono: true, color: theme.muted)
                          .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ),
                ],
              ),
            ),
          if (paused)
            _square(
              theme,
              tooltip: _tv('resume_download'),
              icon: GhIcons.play,
              hover: theme.mint,
              onPressed: () => _guard(widget.onResume, key),
            )
          else if (dl.status == DownloadStatus.downloading)
            _square(
              theme,
              tooltip: _tv('pause_download'),
              icon: GhIcons.pause,
              hover: theme.ink,
              onPressed: () => _guard(widget.onPause, key),
            ),
          _square(
            theme,
            tooltip: _tv('cancel_download'),
            icon: GhIcons.x,
            hover: theme.danger,
            onPressed: () => _guard(widget.onCancel, key),
          ),
        ],
      );
    } else if (installed) {
      trailing = Text(
        _tv('installed_label'),
        style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.mint),
      );
    } else {
      final radius = BorderRadius.circular(theme.radiusItem);
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        spacing: theme.space(2),
        children: [
          GhPressable(
            onPressed: widget.onOpenSource,
            semanticLabel: row.tag,
            borderRadius: radius,
            builder: (context, states) => GhAnimatedBox(
              height: theme.space(9),
              color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
              borderRadius: radius,
              border: Border.all(color: states.active ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
              padding: EdgeInsets.symmetric(horizontal: theme.space(3.5)),
              alignment: Alignment.center,
              child: GhIcon(GhIcons.externalLink, size: theme.space(3.5), color: states.active ? theme.ink : theme.muted),
            ),
          ),
          GhPressable(
            onPressed: widget.onInstall,
            rippleColor: Colors.white,
            borderRadius: radius,
            builder: (context, states) => GhAnimatedBox(
              height: theme.space(9),
              color: states.active ? theme.accentBright : theme.accent,
              borderRadius: radius,
              padding: EdgeInsets.symmetric(horizontal: theme.space(4)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: theme.space(1.5),
                children: [
                  GhIcon(GhIcons.download, size: theme.space(3.5), color: Colors.white),
                  Text(
                    _tv('install'),
                    style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return GhReveal(
      id: 'available:$key',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GhAnimatedBox(
          color: theme.overlay,
          borderRadius: BorderRadius.circular(theme.radiusItem),
          border: Border.all(color: _hovered ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
          padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(3)),
          child: Row(
            spacing: theme.space(3),
            children: [
              Expanded(
                child: Row(
                  spacing: theme.space(2.5),
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(1.5)),
                      decoration: BoxDecoration(
                        color: theme.overlay,
                        borderRadius: BorderRadius.circular(theme.radiusItem),
                        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: theme.space(2),
                        children: [
                          Container(
                            width: theme.space(1.5),
                            height: theme.space(1.5),
                            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                          ),
                          Text(
                            row.tag.isEmpty ? _tv('unbound') : row.tag,
                            style: theme.text(size: GhTextSize.xs, mono: true, color: theme.ink),
                          ),
                        ],
                      ),
                    ),
                    if (row.asset.isMono)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(0.5)),
                        decoration: BoxDecoration(
                          color: theme.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(theme.radiusTag),
                          border: Border.all(color: theme.accentDim.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          '.NET',
                          style: theme.text(size: GhTextSize.x3s, weight: GhWeight.semibold, color: theme.accentBright),
                        ),
                      ),
                    if (state.source != VersionSource.mise)
                      Text(
                        '${(row.asset.size.toDouble() / 1024 / 1024).toStringAsFixed(0)} ${_tv('mb')}',
                        style: theme.text(size: GhTextSize.xs, mono: true, color: theme.muted),
                      ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
