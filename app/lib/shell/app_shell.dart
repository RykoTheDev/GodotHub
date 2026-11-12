import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import '../api/events.dart';
import '../api/projects.dart';
import '../design/design.dart';
import '../logic/launch_errors.dart';
import '../logic/settings_copy.dart';
import '../logic/screen_reader.dart';
import '../logic/settings_category_nav.dart';
import '../modals/command_palette.dart';
import '../motion/intro.dart';
import '../motion/presence.dart';
import '../motion/reveal.dart';
import '../src/hello_screen.dart';
import '../src/rust/api/types.dart';
import '../src/ui_prefs.dart';
import '../src/ui_transition.dart';
import '../state/app_lifecycle.dart';
import '../state/app_signals.dart';
import '../state/discord_rpc.dart';
import '../state/keyboard_shortcuts.dart';
import '../state/news.dart';
import '../state/open_todos_sync.dart';
import '../state/projects.dart';
import '../state/settings.dart';
import '../state/shell_signals.dart';
import '../state/update_available.dart';
import '../state/workspaces.dart';
import '../titlebar/title_bar.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/feedback/announcement_banner.dart';
import '../ui/feedback/confirm_dialog.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/feedback/toast_host.dart';
import '../ui/feedback/workspace_switch_notice.dart';
import '../ui/shell/account_menu.dart' show ghSupportUrl;
import '../ui/shell/sidebar.dart';
import '../ui/shell/view_insets.dart';
import '../projects/projects_view.dart';
import '../ui/splash/splash_screen.dart';
import 'account_menu_host.dart';
import 'git_sidebar_overlay.dart';
import '../api/git.dart';
import '../console/project_console_window.dart';
import '../git/git_sidebar.dart';
import '../versions/versions_view.dart';
import '../modals/create_project_modal.dart';
import '../state/categories.dart';
import '../state/godot_versions.dart';
import 'placeholder_view.dart';
import 'tabs.dart';
import 'workspace_modals.dart';

const _repoUrl = 'https://github.com/RykoTheDev/GodotHub';

abstract final class SidebarPrefs {
  static const width = 'new_ui_sidebar_width';
  static const collapsed = 'new_ui_sidebar_collapsed';
  static const seenNewTabs = 'new_ui_sidebar_seen_new_tabs';
  static const workspaceTipSeen = 'new_ui_sidebar_workspace_tip_seen';
  static const closedGroups = 'new_ui_sidebar_closed_groups';

  static double readWidth(UiPrefsStore prefs) {
    final value = num.tryParse(prefs.getItem(width) ?? '');
    return GhSidebar.clampWidth(value == null || value == 0 || value.isNaN ? GhSidebar.defaultWidth : value.toDouble());
  }

  static List<String> readList(UiPrefsStore prefs, String key) {
    try {
      final saved = jsonDecode(prefs.getItem(key) ?? '[]');
      return saved is List
          ? [
              for (final id in saved)
                if (id is String) id,
            ]
          : const [];
    } catch (_) {
      return const [];
    }
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, this.title = 'GodotHub', this.prefs, this.isMac, this.onOpenGallery});

  final String title;
  final UiPrefsStore? prefs;
  final bool? isMac;
  final VoidCallback? onOpenGallery;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final List<StreamSubscription<Object?>> _subscriptions = [];
  bool _createProjectOpen = false;
  final bool _uiSwitchIntent = GhUiTransition.shouldOpenSettingsAfterSwitch();
  final bool _introHandedOff = GhUiTransition.consumeShellIntroHandOff();
  late bool _splashDone = !GhUiTransition.shouldShowSplash();
  late String _requestedTab = _uiSwitchIntent ? 'settings' : 'projects';
  late final GhAnnouncementController _announcement = GhAnnouncementController(
    getItem: _prefs.getItem,
    setItem: _prefs.setItem,
    isHidden: ghAppHidden,
  );
  final List<String> _mountedTabs = [];
  final Map<String, ({Object inputs, Widget view})> _views = {};
  bool _landingApplied = false;
  String? _emittedTab;
  String _tab = 'projects';
  GitSidebarTarget? _git;
  Route<Object?>? _paletteRoute;
  Route<Object?>? _bugReportRoute;
  bool _paletteOpen = false;
  bool _bugReportOpen = false;
  bool _confirmingRestart = false;

  UiPrefsStore get _prefs => widget.prefs ?? UiPrefsStore.instance;

  bool get _isMac => widget.isMac ?? Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    GhUiTransition.markSplashConsumed();
    if (_uiSwitchIntent) GhUiTransition.clearUiSwitchToSettings();
    void on(String name, void Function(Object? detail) handler) =>
        _subscriptions.add(AppSignals.on(name).listen((signal) => handler(signal.detail)));
    on(setTabSignal, (detail) {
      if (detail is String && detail.isNotEmpty) _setTab(detail);
    });
    on(openSettingSignal, (_) => _setTab('settings'));
    on(openSettingsCategorySignal, (detail) {
      if (detail is! String) return;
      setPendingSettingsCategory(detail);
      _setTab('settings');
    });
    on(showProjectTodosSignal, (_) => _setTab('projects', closeGit: true));
    on(newProjectRequestSignal, (_) => _openCreateProject());
    on(importProjectRequestSignal, (_) => _importProject());
    on(scanProjectsSignal, (_) => _scanProjects());
    on(reportBugSignal, (_) => _openBugReport());
    on(previewUpdateModalSignal, (_) => _openUpdates());
    on(showGitSidebarSignal, (detail) {
      if (detail is! GitSidebarTarget) return;
      setState(() => _git = _git != null && _git!.project.id == detail.project.id ? null : detail);
    });
    on(toggleCommandPaletteSignal, (_) => _togglePalette());
    on(confirmRestartSignal, (_) => _confirmRestart());
    on(escapeSignal, (_) {
      if (_git != null) setState(() => _git = null);
      _dismiss(_paletteRoute);
      _dismiss(_bugReportRoute);
    });
    on(openProjectSignal, _handleOpenProject);
    on(showAnnouncementSignal, (_) => _announcement.show());
    _subscriptions.add(AppEvents.of(AppEventKind.projectExited).listen((_) => ref.read(projectsProvider.notifier).refresh().ignore()));
    _announcement.start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkProjectsHealth());
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _announcement.dispose();
    super.dispose();
  }

  void _setTab(String id, {bool closeGit = false}) {
    if (!mounted) return;
    setState(() {
      if (closeGit) _git = null;
      _requestedTab = id;
    });
  }

  void _dismiss(Route<Object?>? route) {
    final navigator = route?.navigator;
    if (route == null || navigator == null || !route.isActive) return;
    if (route.isCurrent) {
      navigator.pop();
    } else {
      navigator.removeRoute(route);
    }
  }

  Future<void> _push(WidgetBuilder builder, void Function(Route<Object?>? route) track) async {
    await showGhModal<Object?>(context, (context) {
      track(ModalRoute.of(context));
      return builder(context);
    });
    track(null);
  }

  void _togglePalette() {
    if (_paletteOpen) {
      _dismiss(_paletteRoute);
      return;
    }
    _openPalette();
  }

  void _openPalette() {
    if (_paletteOpen || !mounted) return;
    final currentTab = _tab;
    _paletteOpen = true;
    _push(
      (context) =>
          CommandPalette(isMac: _isMac, currentTab: currentTab, onClose: () => _dismiss(_paletteRoute), onNavigate: (id) => _setTab(id)),
      (route) {
        _paletteRoute = route;
        if (route == null) _paletteOpen = false;
      },
    ).ignore();
  }

  void _openBugReport() {
    if (_bugReportOpen || !mounted) return;
    _bugReportOpen = true;
    _push((context) => PlaceholderModal(title: context.tr.common.report_a_bug, icon: GhIcons.bug), (route) {
      _bugReportRoute = route;
      if (route == null) _bugReportOpen = false;
    }).ignore();
  }

  Future<void> _switchGitProject(Project project) async {
    final updated = await ProjectsApi.update(project.id, ProjectUpdate(path: project.path));
    final status = await GitApi.status(updated.path).then<GitStatus?>((value) => value, onError: (Object _) => null);
    if (mounted) {
      setState(() {
        final current = _git;
        if (current != null && current.project.id == updated.id) _git = GitSidebarTarget(project: updated, gitStatus: status);
      });
    }
    await ref.read(projectsProvider.notifier).refresh();
  }

  void _openCreateProject() {
    if (_createProjectOpen || !mounted) return;
    _createProjectOpen = true;
    showGhModal<void>(
      context,
      (modal) => Consumer(
        builder: (context, ref, _) {
          final settings = ref.watch(settingsProvider).value;
          return CreateProjectModal(
            installedVersions: ref.watch(godotVersionsProvider).installed,
            defaultLocation: settings?.defaultProjectLocation,
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
    ).whenComplete(() => _createProjectOpen = false);
  }

  void _openUpdates() => _showPlaceholder(context.tr.common.update_available, GhIcons.arrowUp);

  void _showPlaceholder(String title, FaIconData icon) {
    if (!mounted) return;
    showPlaceholderModal(context, title: title, icon: icon).ignore();
  }

  Future<void> _confirmRestart() async {
    if (_confirmingRestart || !mounted) return;
    _confirmingRestart = true;
    final tr = context.tr.common;
    final confirmed = await showGhConfirmDialog(
      context,
      title: tr.reload_confirm_title,
      description: tr.reload_confirm_desc,
      confirmLabel: tr.reload,
    );
    _confirmingRestart = false;
    if (!confirmed) return;
    try {
      await Api.relaunch();
    } catch (e) {
      ghToasts.pushToast(GhToastType.error, '$e');
    }
  }

  Future<void> _openProject(String id, bool? withConsole) async {
    try {
      await ProjectsApi.open(id, true, withConsole);
      await ref.read(projectsProvider.notifier).refresh();
    } catch (err) {
      reportLaunchError(err);
    }
  }

  Future<void> _handleOpenProject(Object? detail) async {
    final String id;
    bool? withConsole;
    if (detail is String) {
      id = detail;
    } else if (detail is Map && detail['id'] is String) {
      id = detail['id'] as String;
      withConsole = detail['console'] as bool?;
    } else {
      return;
    }
    final project = ref.read(projectsProvider).data.where((p) => p.id == id).firstOrNull;
    if (project?.sessionStartedAtMs != null && mounted) {
      final tr = context.tr.common;
      final confirmed = await showGhConfirmDialog(
        context,
        title: tr.project_already_open_title,
        description: tr.project_already_open_desc.args({'name': project?.name ?? id}),
        confirmLabel: tr.project_open_anyway,
      );
      if (!confirmed) return;
    }
    await _openProject(id, withConsole);
  }

  Future<void> _importProject() async {
    try {
      final folder = await ProjectsApi.pickFolder();
      if (folder == null) return;
      await ProjectsApi.import(folder, '');
      await ref.read(projectsProvider.notifier).refresh();
    } catch (e) {
      debugPrint('[new-ui] import failed: $e');
    }
  }

  Future<void> _scanProjects() async {
    final settings = ref.read(settingsProvider).value;
    if (settings == null) return;
    if (settings.projectScanDirs.isEmpty) {
      _setTab('settings');
      return;
    }
    try {
      await Api.scanForProjectsWithInfo(settings.projectScanDirs, settings.scanDepth);
      await ref.read(projectsProvider.notifier).refresh();
    } catch (e) {
      debugPrint('[new-ui] scan failed: $e');
    }
  }

  Future<void> _checkProjectsHealth() async {
    LoadStatus health;
    try {
      health = await ProjectsApi.getHealth();
    } catch (_) {
      return;
    }
    if (health != LoadStatus.corrupt || !mounted) return;
    final tr = context.tr.common;
    final restore = await showGhConfirmDialog(
      context,
      title: tr.projects_corrupt_title,
      description: tr.projects_corrupt_desc,
      confirmLabel: tr.projects_corrupt_restore,
      cancelLabel: tr.projects_corrupt_dismiss,
    );
    if (!restore) return;
    try {
      await ProjectsApi.restoreFromBackup();
      await ref.read(projectsProvider.notifier).refresh();
    } catch (_) {}
  }

  void _onTitleBarAction(TitleBarAction action) {
    switch (action) {
      case TitleBarAction.wordmark:
        AppSignals.emit(setTabSignal, 'dashboard');
      case TitleBarAction.changelog:
        AppSignals.emit(setTabSignal, 'changelog');
      case TitleBarAction.support:
        Api.openUrl(ghSupportUrl).ignore();
      case TitleBarAction.star:
        Api.openUrl(_repoUrl).ignore();
      case TitleBarAction.bug:
        AppSignals.emit(reportBugSignal);
    }
  }

  void _resolveTab(AppSettings settings) {
    if (!_landingApplied && !_uiSwitchIntent) {
      _landingApplied = true;
      if (appTabById(settings.defaultLandingTab) != null) _requestedTab = settings.defaultLandingTab;
    }
    final enabled = enabledTabsFor(settings);
    _tab = resolveTab(_requestedTab, enabled);
    _mountedTabs.removeWhere((id) => !enabled.any((tab) => tab.id == id));
    if (!_mountedTabs.contains(_tab)) _mountedTabs.add(_tab);
    if (_emittedTab != _tab) {
      final tab = _tab;
      _emittedTab = tab;
      WidgetsBinding.instance.addPostFrameCallback((_) => AppSignals.emit(viewChangedSignal, tab));
    }
  }

  Widget _view(String id, {required bool active, required bool connected}) {
    final tab = appTabById(id)!;
    final gallery = widget.onOpenGallery;
    final Object inputs = switch (id) {
      'projects' => (connected, active, _git != null, widget.prefs),
      'versions' => (connected, widget.prefs),
      'settings' => (widget.title, gallery),
      _ => (context.tr, gallery),
    };
    final cached = _views[id];
    if (cached != null && cached.inputs == inputs) return cached.view;
    final view = _buildView(id, tab, gallery, active: active, connected: connected);
    _views[id] = (inputs: inputs, view: view);
    return view;
  }

  Widget _buildView(String id, AppTabDef tab, VoidCallback? gallery, {required bool active, required bool connected}) {
    if (id == 'projects') {
      return ProjectsView(
        connected: connected,
        active: active,
        gitSidebarOpen: _git != null,
        prefs: widget.prefs,
        onOpenSettings: () => _setTab('settings'),
      );
    }
    if (id == 'versions') {
      return VersionsView(connected: connected, prefs: widget.prefs, onOpenSettings: () => _setTab('settings'));
    }
    if (id == 'settings') {
      return GhViewInsetPadding(
        child: HelloScreen(title: widget.title, onOpenGallery: kDebugMode ? gallery : null),
      );
    }
    return GhViewInsetPadding(
      child: PlaceholderView(
        icon: tab.icon,
        title: tabLabel(tab, context.tr),
        actions: [
          if (kDebugMode && gallery != null)
            GhButton(
              onPressed: gallery,
              label: 'Widget gallery',
              variant: GhButtonVariant.outline,
              size: GhTextSize.xs,
              paddingX: 3,
              paddingY: 1.5,
            ),
        ],
      ),
    );
  }

  Widget _sidebar(AppSettings settings, bool cardLayout) {
    final update = ref.watch(updateAvailableProvider);
    final newsUnread = ref.watch(newsBadgeProvider);
    final prefs = _prefs;
    void changeTab(String id) => _setTab(id, closeGit: true);
    return GhSidebar(
      tabs: sidebarTabsFor(settings, newsUnread: newsUnread, translations: context.tr),
      activeTab: _tab,
      onTabChange: changeTab,
      connected: !cardLayout,
      paletteKey: settings.commandPaletteKeybind.isEmpty ? 'p' : settings.commandPaletteKeybind,
      onOpenCommandPalette: _openPalette,
      onOpenUpdatesModal: _openUpdates,
      updateAvailable: update.updateAvailable || update.previewUpdate,
      workspacesEnabled: settings.workspacesEnabled,
      fixedResizeKnob: settings.fixedSidebarResizeKnob,
      isMac: _isMac,
      initialWidth: SidebarPrefs.readWidth(prefs),
      onWidthChanged: (width) => prefs.setItem(SidebarPrefs.width, '${width.round()}'),
      initialCollapsed: prefs.getItem(SidebarPrefs.collapsed) == '1',
      onCollapsedChanged: (collapsed) => prefs.setItem(SidebarPrefs.collapsed, collapsed ? '1' : '0'),
      initialSeenNewTabs: SidebarPrefs.readList(prefs, SidebarPrefs.seenNewTabs),
      onSeenNewTabsChanged: (ids) => prefs.setItem(SidebarPrefs.seenNewTabs, jsonEncode(ids)),
      initialClosedGroups: SidebarPrefs.readList(prefs, SidebarPrefs.closedGroups),
      onClosedGroupsChanged: (ids) => prefs.setItem(SidebarPrefs.closedGroups, jsonEncode(ids)),
      workspaceTipSeen: prefs.getItem(SidebarPrefs.workspaceTipSeen) == '1',
      onWorkspaceTipDismissed: () => prefs.setItem(SidebarPrefs.workspaceTipSeen, '1'),
      accountMenuBuilder: (context, trigger) => AccountMenuHost(trigger: trigger, onNavigate: changeTab),
    );
  }

  Widget _main(AppSettings settings) {
    final theme = GhTheme.of(context);
    final cardLayout = settings.cardLayout;
    final insets = cardLayout
        ? EdgeInsetsDirectional.only(start: theme.space(4), end: theme.space(4), bottom: theme.space(4))
        : EdgeInsetsDirectional.zero;
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(top: cardLayout ? theme.space(3) : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: cardLayout ? EdgeInsetsDirectional.only(start: theme.space(4), bottom: theme.space(4)) : EdgeInsets.zero,
                child: GhIntroSidebar(child: _sidebar(settings, cardLayout)),
              ),
              Expanded(
                child: GhViewInsets(
                  insets: insets,
                  child: Stack(
                    children: [
                      for (final id in _mountedTabs)
                        Positioned.fill(
                          key: ValueKey('pane:$id'),
                          child: _ViewPane(
                            active: id == _tab,
                            child: _view(id, active: id == _tab, connected: !cardLayout),
                          ),
                        ),
                      Positioned.fill(
                        child: Padding(
                          padding: insets,
                          child: GhAnnouncementBanner(
                            controller: _announcement,
                            onSupport: () => Api.openUrl(GhAnnouncement.supportUrl).ignore(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: GitSidebarOverlay(
            target: _git,
            initialWidth: GitSidebarWidth.parse(_prefs.getItem(GitSidebarWidth.prefKey)),
            fixedKnob: settings.fixedSidebarResizeKnob,
            onClose: () => setState(() => _git = null),
            onWidthCommitted: (width) => _prefs.setItem(GitSidebarWidth.prefKey, '${width.round()}'),
            builder: (context, target) => GitSidebar(
              project: target.project,
              gitStatus: target.gitStatus,
              connected: !cardLayout,
              onClose: () => setState(() => _git = null),
              onRefresh: () => ref.read(projectsProvider.notifier).refresh().ignore(),
              onSwitchProject: _switchGitProject,
            ),
          ),
        ),
        Positioned.fill(child: ProjectConsoleWindow(prefs: widget.prefs)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(discordRpcProvider);
    ref.watch(openTodosProvider);
    ref.watch(todoDueNotificationsProvider);
    final theme = GhTheme.of(context);
    final settings = ref.watch(settingsProvider).value;
    if (settings != null && !settings.setupComplete) {
      return SizedBox.expand(
        child: GhRevealScope(child: _OnboardingPlaceholder(settings: settings)),
      );
    }
    if (settings == null) {
      return SizedBox.expand(
        child: ColoredBox(
          color: theme.base,
          child: Center(
            child: Text(
              context.tr.common.app_loading,
              style: theme.text(size: GhTextSize.sm, color: theme.muted),
            ),
          ),
        ),
      );
    }
    if (!_splashDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_splashDone) setState(() => _splashDone = true);
      });
    }
    _resolveTab(settings);
    final workspaces = ref.watch(workspacesProvider);
    return SizedBox.expand(
      child: ColoredBox(
        color: theme.base,
        child: ScreenReaderAnnouncer(
          enabled: settings.screenReaderAnnouncements,
          child: GhToastHost(
            child: Stack(
              children: [
                Positioned.fill(
                  child: GhShellIntro(
                    enabled: !_introHandedOff,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GhIntroTitleBar(
                          child: TitleBar(isMac: _isMac, onAction: _onTitleBarAction),
                        ),
                        Expanded(child: _main(settings)),
                      ],
                    ),
                  ),
                ),
                if (settings.workspacesEnabled) ...[
                  const WorkspaceModals(),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: GhWorkspaceSwitchNotice(
                        activeId: workspaces.loaded ? workspaces.activeId : null,
                        workspaces: [for (final w in workspaces.workspaces) GhWorkspaceRef(id: w.id, name: w.name, icon: w.icon)],
                      ),
                    ),
                  ),
                ],
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: _splashDone,
                    child: GhPresence(visible: !_splashDone, kind: GhPresenceKind.splash, child: const GhSplashScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewPane extends StatelessWidget {
  const _ViewPane({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: !active,
      child: TickerMode(
        enabled: active,
        child: ExcludeFocus(
          excluding: !active,
          child: GhRevealScope(active: active, child: child),
        ),
      ),
    );
  }
}

class _OnboardingPlaceholder extends ConsumerWidget {
  const _OnboardingPlaceholder({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = GhTheme.of(context);
    return ColoredBox(
      color: theme.base,
      child: PlaceholderView(
        icon: GhIcons.rocket,
        title: 'Onboarding',
        actions: [
          GhButton(
            onPressed: () => ref.read(settingsProvider.notifier).save(copySettings(settings, setupComplete: true)).ignore(),
            label: 'Continue to GodotHub',
            variant: GhButtonVariant.primary,
          ),
        ],
      ),
    );
  }
}
