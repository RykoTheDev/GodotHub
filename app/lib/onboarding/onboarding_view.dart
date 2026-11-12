import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import '../api/projects.dart';
import '../design/design.dart';
import '../i18n/i18n_controller.dart';
import '../i18n/languages.dart';
import '../logic/features.dart';
import '../logic/settings_copy.dart';
import '../modals/category_manager_modal.dart';
import '../modals/theme_presets_modal.dart';
import '../motion/ease.dart';
import '../motion/motion.dart';
import '../motion/tween.dart';
import '../src/rust/api/types.dart';
import '../src/ui_transition.dart';
import '../state/app_lifecycle.dart';
import '../state/categories.dart';
import '../state/godot_versions.dart';
import '../state/onboarding.dart';
import '../state/projects.dart';
import '../state/settings.dart';
import '../state/workspaces.dart';
import '../titlebar/language_menu.dart';
import '../titlebar/title_bar.dart';
import '../ui/controls/slider.dart';
import '../ui/controls/text_input.dart';
import '../ui/controls/toggle.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/core/ui_settings.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/overlays/dropdown.dart';
import '../ui/overlays/menu.dart';
import '../ui/reusables/dir_list.dart';
import '../ui/shell/overlay_scroll_area.dart';
import '../ui/reusables/view_header.dart';
import '../ui/shell/color_swatch_picker.dart';
import '../versions/version_settings.dart';
import 'feature_setup_picker.dart';
import 'mini_app_preview.dart';
import 'onboarding_parts.dart';
import 'welcome_intro.dart';

String _to(String key, {num? count, Map<String, Object?> args = const {}}) => ghTr('onboarding:$key', count: count, args: args);
String _ts(String key) => ghTr('settings:$key');

class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key, required this.settings, this.isMac});

  final AppSettings settings;
  final bool? isMac;

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> with SingleTickerProviderStateMixin {
  final GlobalKey _wordmark = GlobalKey();
  final GlobalKey _preview = GlobalKey();
  final TextEditingController _categoryInput = TextEditingController();
  late final GhTimeline _reveal = GhTimeline(vsync: this);
  late final List<Animation<double>> _revealTracks = [
    _reveal.add(GhTrack(start: 0, duration: 0.7, ease: GhEase.out)),
    _reveal.add(GhTrack(start: 0.08, duration: 0.7, ease: GhEase.out)),
  ];
  late bool _intro;
  late bool _introDecided;
  bool _introStarted = false;
  bool _wordmarkHidden = false;
  bool _celebrating = false;
  bool _shellFading = false;
  bool _previewHidden = false;
  LiftedPreview? _lifted;

  List<DiscoveredProject> _recentProjects = const [];
  Set<String> _selectedProjects = const {};
  Set<String> _importedProjects = const {};
  bool _importingProjects = false;
  bool _discoveringProjects = true;

  @override
  void initState() {
    super.initState();
    final workspaces = ref.read(workspacesProvider);
    _intro = _introFor(workspaces);
    _introDecided = workspaces.loaded;
    _reveal.finish();
    Api.scanGodotRecentProjects()
        .then((list) {
          if (!mounted) return;
          setState(() {
            _recentProjects = list;
            _selectedProjects = {for (final p in list) p.path};
          });
        }, onError: (Object _) {})
        .whenComplete(() {
          if (mounted) setState(() => _discoveringProjects = false);
        });
  }

  @override
  void dispose() {
    _reveal.dispose();
    _categoryInput.dispose();
    super.dispose();
  }

  OnboardingNotifier get _notifier => ref.read(onboardingProvider.notifier);

  static bool _introFor(WorkspacesView view) => !view.loaded || view.workspaces.length <= 1;

  void _decideIntro(WorkspacesView view) {
    if (_introDecided || !view.loaded) return;
    _introDecided = true;
    if (!_introStarted && _intro && !_introFor(view)) setState(() => _intro = false);
  }

  void _revealShell() {
    _introStarted = true;
    final motion = GhMotion.of(context);
    if (motion.off) return;
    _reveal.play(motion, from: 0);
  }

  Future<void> _importProjects() async {
    final targets = [
      for (final p in _recentProjects)
        if (_selectedProjects.contains(p.path) && !_importedProjects.contains(p.path)) p,
    ];
    if (targets.isEmpty) return;
    setState(() => _importingProjects = true);
    var added = 0;
    for (final p in targets) {
      try {
        await ProjectsApi.import(p.path, '');
        if (mounted) setState(() => _importedProjects = {..._importedProjects, p.path});
        added++;
      } catch (e) {
        ghToasts.pushToast(GhToastType.error, '${p.name}: $e');
      }
    }
    if (!mounted) return;
    setState(() => _importingProjects = false);
    ref.read(projectsProvider.notifier).refresh().ignore();
    if (added > 0) ghToasts.pushToast(GhToastType.success, _to('discovery_added_projects', count: added));
  }

  void _toggleProject(String path) {
    final next = {..._selectedProjects};
    if (!next.remove(path)) next.add(path);
    setState(() => _selectedProjects = next);
  }

  Future<void> _celebrate() async {
    try {
      await Future.wait([ref.read(projectsProvider.notifier).refresh(), ref.read(godotVersionsProvider.notifier).refreshInstalled()]);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _celebrating = true);
    final motion = GhMotion.of(context);
    if (motion.off) return;
    await Future<void>.delayed(celebrationHold);
    if (!mounted) return;
    final draft = ref.read(onboardingProvider).draft;
    final workspace = _currentWorkspace(ref.read(workspacesProvider));
    final projects = ref.read(projectsProvider).data;
    final versions = ref.read(godotVersionsProvider).installed.length;
    _lifted = await LiftedPreview.lift(
      context: context,
      preview: _preview,
      clone: (opacity) =>
          MiniAppWindow(settings: draft, workspace: workspace, projects: projects, versionCount: versions, contentOpacity: opacity),
      onShellFade: () {
        if (mounted) {
          setState(() {
            _shellFading = true;
            _previewHidden = true;
          });
        }
      },
    );
    if (_lifted != null) GhUiTransition.handOffShellIntro();
  }

  Future<void> _morph() async => _lifted?.morph();

  void _finish(bool skip) {
    _notifier.finish(skip, beforeComplete: skip ? null : _celebrate, afterComplete: skip ? null : _morph).ignore();
  }

  Workspace? _currentWorkspace(WorkspacesView view) {
    for (final w in view.workspaces) {
      if (w.id == view.activeId) return w;
    }
    return null;
  }

  void _openPresets(GhThemeMode mode, String currentId) {
    showGhModal<void>(
      context,
      (modal) => ThemePresetsModal(
        mode: mode,
        currentId: currentId,
        onSelect: (id) {
          _notifier.selectPreset(id);
          Navigator.of(modal).pop();
        },
        onClose: () => Navigator.of(modal).pop(),
      ),
    ).ignore();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final state = ref.watch(onboardingProvider);
    ref.listen<WorkspacesView>(workspacesProvider, (_, next) => _decideIntro(next));
    final workspaces = ref.watch(workspacesProvider);
    final projects = ref.watch(projectsProvider.select((d) => d.data));
    final versionCount = ref.watch(godotVersionsProvider.select((s) => s.installed.length));
    final settings = ref.watch(settingsProvider).value ?? widget.settings;
    final steps = state.steps;
    final stepIndex = state.stepIndex;
    final step = state.step;
    final finishing = state.finishing;
    final motion = GhMotion.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 640;

    final aside = Container(
      width: theme.space(60),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: theme.raised, borderRadius: BorderRadius.circular(theme.radiusCard)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: theme.space(14),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: theme.space(5)),
              child: Row(
                spacing: theme.space(2),
                children: [
                  Opacity(
                    opacity: _wordmarkHidden ? 0 : 1,
                    child: Text(
                      welcomeWordmark,
                      key: _wordmark,
                      style: theme.text(size: GhTextSize.xl, weight: FontWeight.w900, color: theme.ink, letterSpacingEm: -0.025),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(0.5)),
                    decoration: BoxDecoration(
                      color: theme.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(theme.radiusTag),
                    ),
                    child: Text(
                      _to('setup').toUpperCase(),
                      style: theme.text(size: GhTextSize.x4s, weight: GhWeight.semibold, color: theme.accentBright, letterSpacingEm: 0.025),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: GhOverlayScrollArea(
              hideThumb: !settings.showScrollbars,
              hideTopButton: true,
              child: Semantics(
                label: _to('setup'),
                container: true,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(theme.space(3), theme.space(1), theme.space(3), theme.space(3)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: theme.space(0.5),
                    children: [
                      for (var i = 0; i < steps.length; i++)
                        _StepButton(
                          key: ValueKey('step:${steps[i].id.name}'),
                          index: i,
                          label: onboardingStepLabel(steps[i].id),
                          active: i == stepIndex,
                          done: i < stepIndex,
                          onPressed: finishing ? null : () => _notifier.jumpTo(i),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          MiniAppPreview(
            previewKey: _preview,
            settings: state.draft,
            workspace: _currentWorkspace(workspaces),
            projects: projects,
            versionCount: versionCount,
            hidden: _previewHidden,
          ),
        ],
      ),
    );

    final main = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(4),
      children: [
        GhViewHeader(
          title: onboardingStepLabel(step.id),
          metric: [
            Text(
              _to('step_of', args: {'current': stepIndex + 1, 'total': steps.length}),
              style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.muted),
            ),
          ],
          child: ExcludeSemantics(
            child: Row(
              spacing: theme.space(1),
              children: [
                for (var i = 0; i < steps.length; i++)
                  Expanded(
                    child: AnimatedContainer(
                      duration: GhDurations.interactive,
                      height: theme.space(1),
                      decoration: BoxDecoration(
                        color: i < stepIndex ? theme.accent : (i == stepIndex ? theme.accentBright : theme.line.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: theme.raised, borderRadius: BorderRadius.circular(theme.radiusCard)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: GhOverlayScrollArea(
                    hideThumb: !settings.showScrollbars,
                    hideTopButton: true,
                    scrollToTopOn: step.id,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: theme.space(narrow ? 6 : 10), vertical: theme.space(narrow ? 6 : 8)),
                      child: Center(key: ValueKey(step.id), child: _stepContent(theme, state, settings, projects, versionCount)),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: theme.space(6), vertical: theme.space(4)),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: theme.line)),
                  ),
                  child: Row(
                    children: [
                      _FooterBack(
                        first: stepIndex == 0,
                        onPressed: finishing ? null : () => stepIndex == 0 ? _finish(true) : _notifier.goBack(),
                      ),
                      const Spacer(),
                      if (step.id == OnboardingStepId.finish)
                        _PrimaryFooterButton(
                          key: const ValueKey('onboarding-get-started'),
                          label: finishing ? ghTr('finishing') : ghTr('get_started'),
                          onPressed: finishing ? null : () => _finish(false),
                        )
                      else
                        _PrimaryFooterButton(
                          key: const ValueKey('onboarding-continue'),
                          label: ghTr('onboarding_continue'),
                          trailing: GhIcons.chevronRight,
                          onPressed: _notifier.goNext,
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

    return ColoredBox(
      color: theme.base,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitleBar(isMac: widget.isMac ?? Platform.isMacOS, minimal: true),
              Expanded(
                child: AnimatedOpacity(
                  opacity: _shellFading ? 0 : 1,
                  duration: motion.gsap(0.4),
                  curve: GhEase.easeIn,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(theme.space(4), theme.space(2), theme.space(4), theme.space(4)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: theme.space(4),
                      children: [
                        GhPoseTransition(animation: _revealTracks[0], from: _shellFrom, child: aside),
                        Expanded(
                          child: GhPoseTransition(animation: _revealTracks[1], from: _shellFrom, child: main),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_intro)
            Positioned.fill(
              child: WelcomeIntro(
                target: _wordmark,
                onLeave: _revealShell,
                onDone: () {
                  if (mounted) setState(() => _intro = false);
                },
                targetHidden: (hidden) {
                  if (mounted) setState(() => _wordmarkHidden = hidden);
                },
              ),
            ),
        ],
      ),
    );
  }

  static const _shellFrom = GhPose(opacity: 0, y: 24, scale: 0.985);

  Widget _stepContent(GhTheme theme, OnboardingState state, AppSettings settings, List<Project> projects, int versionCount) {
    final draft = state.draft;
    switch (state.step.id) {
      case OnboardingStepId.workspace:
        return StepShell(
          icon: GhIcons.briefcase,
          title: _to('first_workspace_title'),
          description: _to('first_workspace_desc'),
          child: const OnboardingFirstWorkspace(),
        );
      case OnboardingStepId.welcome:
        return StepShell(
          icon: GhIcons.house,
          title: _to('basics_title'),
          description: _to('basics_desc'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(6),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: theme.space(2.5),
                children: [
                  Text(
                    _to('language_label').toUpperCase(),
                    style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: theme.muted, letterSpacingEm: 0.025),
                  ),
                  _LanguageDropdown(
                    value: draft.language,
                    onSelected: (value) {
                      GhI18n.instance.setLanguageSetting(value);
                      _notifier.setDraft((d) => copySettings(d, language: value));
                    },
                  ),
                ],
              ),
              const OnboardingCloudBackup(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(3)),
                decoration: BoxDecoration(
                  color: theme.overlay,
                  borderRadius: BorderRadius.circular(theme.radiusItem),
                  border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                ),
                child: Row(
                  spacing: theme.space(4),
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ghTr('onboarding_discord_rpc'),
                            style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink),
                          ),
                          SizedBox(height: theme.space(0.5)),
                          Text(
                            ghTr('onboarding_discord_rpc_desc'),
                            style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625),
                          ),
                        ],
                      ),
                    ),
                    GhToggle(
                      checked: draft.discordRpcEnabled,
                      label: ghTr('onboarding_discord_rpc'),
                      onChanged: (checked) => _notifier.setDraft((d) => copySettings(d, discordRpcEnabled: checked)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case OnboardingStepId.setup:
        return StepShell(
          wide: true,
          icon: GhIcons.layoutGrid,
          title: _to('setup_title'),
          description: _to('setup_desc'),
          child: FeatureSetupPicker(value: draft, onChanged: _notifier.replaceDraft),
        );
      case OnboardingStepId.projects:
        return StepShell(
          icon: GhIcons.folderPlus,
          title: ghTr('onboarding_projects_title'),
          description: ghTr('onboarding_projects_desc'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(4),
            children: [
              GhDirList(
                dirs: draft.projectScanDirs,
                onChanged: (dirs) => _notifier.setDraft((d) => copySettings(d, projectScanDirs: dirs)),
                emptyHint: _to('onboard_empty_projects'),
                defaultDir: draft.defaultProjectLocation,
                onSetDefault: (dir) => _notifier.setDraft((d) => copySettings(d, defaultProjectLocation: () => dir)),
                defaultLabel: _ts('new_project_default'),
              ),
              DiscoveryList(
                heading: _to('discovery_recent_heading'),
                loading: _discoveringProjects,
                loadingLabel: _to('discovery_scanning_projects'),
                hint: _to('discovery_link_hint'),
                rows: [
                  for (final p in _recentProjects)
                    DiscoveryRow(
                      key: p.path,
                      primary: p.name,
                      secondary: p.path,
                      badges: [
                        if (p.engine != null) _to('discovery_engine', args: {'version': p.engine}),
                        if (p.favorite) _to('discovery_favorite'),
                      ],
                    ),
                ],
                selected: _selectedProjects,
                imported: _importedProjects,
                busy: _importingProjects,
                onToggle: _toggleProject,
                onAdd: _importProjects,
                addLabel: _addLabel,
              ),
              if (state.projectSuggestions.isNotEmpty)
                PathSuggestionChips(
                  suggestions: [for (final s in state.projectSuggestions) (path: s.path, source: s.source)],
                  added: draft.projectScanDirs.contains,
                  onAdd: (path) => _notifier.setDraft((d) => copySettings(d, projectScanDirs: [...d.projectScanDirs, path])),
                ),
            ],
          ),
        );
      case OnboardingStepId.versions:
        final detected = ref.watch(detectedInstallsProvider);
        return StepShell(
          icon: GhIcons.download,
          title: ghTr('onboarding_versions_title'),
          description: ghTr('onboarding_versions_desc'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(4),
            children: [
              GhDirList(
                dirs: draft.versionScanDirs,
                onChanged: (dirs) => _notifier.setDraft((d) => copySettings(d, versionScanDirs: dirs)),
                emptyHint: _to('onboard_empty_versions'),
                defaultDir: draft.downloadDir,
                onSetDefault: (dir) => _notifier.setDraft((d) => copySettings(d, downloadDir: () => dir)),
                defaultLabel: _ts('download_folder'),
              ),
              DiscoveryList(
                heading: _to('discovery_installs_heading'),
                loading: detected.loading,
                loadingLabel: _to('discovery_scanning_installs'),
                rows: [
                  for (final i in detected.installs)
                    DiscoveryRow(
                      key: i.path,
                      primary: i.version != null ? _to('discovery_engine', args: {'version': i.version}) : i.name,
                      secondary: i.path,
                      badges: [i.source],
                    ),
                ],
                selected: detected.selected,
                imported: detected.imported,
                busy: detected.importing,
                onToggle: ref.read(detectedInstallsProvider.notifier).toggle,
                onAdd: () => ref.read(detectedInstallsProvider.notifier).importSelected().ignore(),
                addLabel: _addLabel,
              ),
              if (state.versionSuggestions.isNotEmpty)
                PathSuggestionChips(
                  suggestions: [for (final s in state.versionSuggestions) (path: s.path, source: s.source)],
                  added: draft.versionScanDirs.contains,
                  onAdd: (path) => _notifier.setDraft((d) => copySettings(d, versionScanDirs: [...d.versionScanDirs, path])),
                ),
            ],
          ),
        );
      case OnboardingStepId.templates:
        final templateDir = draft.templateScanDir;
        return StepShell(
          icon: GhIcons.copy,
          title: ghTr('onboarding_templates_title'),
          description: ghTr('onboarding_templates_desc'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(3),
            children: [
              GhDirList(
                single: true,
                dirs: templateDir == null ? const [] : [templateDir],
                onChanged: (dirs) => _notifier.setDraft((d) => copySettings(d, templateScanDir: () => dirs.isEmpty ? null : dirs.first)),
                emptyHint: _to('onboard_no_template_folder'),
              ),
              if (state.pendingTemplateSuggestions.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: theme.space(1.5),
                  children: [
                    sectionCaps(theme, ghTr('suggested_from_workspaces')),
                    for (final s in state.pendingTemplateSuggestions)
                      _TemplateSuggestion(
                        key: ValueKey(s.path),
                        path: s.path,
                        source: s.source,
                        onPressed: () => _notifier.setDraft((d) => copySettings(d, templateScanDir: () => s.path)),
                      ),
                  ],
                ),
            ],
          ),
        );
      case OnboardingStepId.categories:
        return StepShell(
          icon: GhIcons.tags,
          title: ghTr('onboarding_categories_title'),
          description: ghTr('onboarding_categories_desc_full'),
          child: _categoriesStep(theme, state),
        );
      case OnboardingStepId.appearance:
        return StepShell(
          icon: GhIcons.palette,
          title: ghTr('onboarding_customize_title'),
          description: ghTr('onboarding_customize_desc'),
          child: _appearanceStep(theme, draft, state.presetActive),
        );
      case OnboardingStepId.finish:
        if (_celebrating) {
          return StepShell(
            icon: GhIcons.check,
            title: _to('found_title'),
            description: _to('found_desc'),
            child: FinishCelebration(projects: projects, versionCount: versionCount),
          );
        }
        return StepShell(
          icon: GhIcons.check,
          title: ghTr(state.finishing ? 'onboarding_setting_up_title' : 'onboarding_finish_title'),
          description: ghTr(state.finishing ? 'onboarding_setting_up_desc' : 'onboarding_finish_desc'),
          child: state.finishing ? _finishProgress(theme, state) : _finishSummary(theme, draft),
        );
    }
  }

  String _addLabel(int count) => count > 0 ? _to('discovery_add_selected_count', count: count) : _to('discovery_add_selected');

  Widget _categoriesStep(GhTheme theme, OnboardingState state) {
    final categories = ref.watch(categoriesProvider).data;
    final notifier = ref.read(categoriesProvider.notifier);
    final labels = starterCategoryLabels();
    final canAdd = !state.categoryBusy && state.categoryDraft.trim().isNotEmpty;
    final btnRadius = BorderRadius.circular(theme.radiusBtn);
    Future<void> addCustom() async {
      if (!canAdd) return;
      await _notifier.addCustomCategory();
      if (mounted && ref.read(onboardingProvider).categoryDraft.isEmpty) _categoryInput.clear();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(4),
      children: [
        Wrap(
          spacing: theme.space(2),
          runSpacing: theme.space(2),
          children: [
            for (final name in starterCategories)
              Builder(
                key: ValueKey('starter:$name'),
                builder: (context) {
                  final added = _notifier.isStarterCategoryAdded(name, categories);
                  final color = colorFromHex(starterCategoryColors[name] ?? categoryColors.first);
                  return GhPressable(
                    onPressed: added || state.categoryBusy ? null : () => _notifier.addStarterCategory(name).ignore(),
                    disabledOpacity: 1,
                    borderRadius: btnRadius,
                    builder: (context, states) {
                      final hover = states.highlighted;
                      final fg = added || hover ? theme.accentBright : theme.muted;
                      final body = GhAnimatedBox(
                        padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(2)),
                        color: added ? theme.accent.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: btnRadius,
                        border: added ? Border.all(color: theme.accentDim.withValues(alpha: 0.5)) : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: theme.space(1.5),
                          children: [
                            GhIcon(added ? GhIcons.check : GhIcons.plus, size: theme.space(3), color: fg),
                            Container(
                              width: theme.space(2),
                              height: theme.space(2),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black.withValues(alpha: 0.2)),
                              ),
                            ),
                            Text(
                              labels[name] ?? name,
                              style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: fg),
                            ),
                          ],
                        ),
                      );
                      if (added) return body;
                      return DashedOutline(
                        color: hover ? theme.accentDim : theme.outline.withValues(alpha: 0.5),
                        radius: btnRadius,
                        child: body,
                      );
                    },
                  );
                },
              ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(3),
          children: [
            Row(
              spacing: theme.space(2.5),
              children: [
                Expanded(
                  child: GhTextInput(
                    controller: _categoryInput,
                    placeholder: ghTr('onboarding_custom_category_placeholder'),
                    onChanged: _notifier.setCategoryDraft,
                    onSubmitted: (_) => addCustom().ignore(),
                    background: theme.base,
                    borderColor: theme.outline.withValues(alpha: 0.5),
                    focusBorderColor: theme.accentDim,
                    borderRadius: btnRadius,
                    padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(2.5)),
                  ),
                ),
                _PrimaryFooterButton(
                  key: const ValueKey('onboarding-add-category'),
                  label: ghTr('add'),
                  leading: GhIcons.plus,
                  compact: true,
                  onPressed: canAdd ? () => addCustom().ignore() : null,
                ),
              ],
            ),
            GhColorSwatchPicker(
              label: ghTr('color_label'),
              value: state.categoryColor,
              presets: categoryColors,
              onChanged: _notifier.setCategoryColor,
            ),
          ],
        ),
        if (categories.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(2),
            children: [
              Text(
                ghTr('onboarding_your_categories').toUpperCase(),
                style: theme.text(size: GhTextSize.x2s, weight: GhWeight.medium, color: theme.muted, letterSpacingEm: 0.025),
              ),
              SortableCategoryList(
                categories: categories,
                onUpdate: (id, name, color) => notifier.update(id, name, color),
                onDelete: notifier.remove,
                onReorder: notifier.reorder,
                onAssignFolder: notifier.assignFolder,
                onUnassignFolder: notifier.unassignFolder,
                onError: (message) {
                  if (message != null && message.isNotEmpty) ghToasts.pushToast(GhToastType.error, message);
                },
              ),
            ],
          ),
      ],
    );
  }

  Widget _appearanceStep(GhTheme theme, AppSettings draft, bool presetActive) {
    final light = resolveThemeMode(draft.themeMode, ghPlatformBrightness()) == GhThemeMode.light;
    final btnRadius = BorderRadius.circular(theme.radiusBtn);
    Widget presetRow({required FaIconData icon, required String label, int? count, bool active = false, required VoidCallback onPressed}) =>
        GhPressable(
          onPressed: onPressed,
          borderRadius: btnRadius,
          semanticLabel: label,
          builder: (context, states) => GhAnimatedBox(
            padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(3.5)),
            color: active ? theme.accent.withValues(alpha: 0.1) : (states.highlighted ? theme.overlay : Colors.transparent),
            borderRadius: btnRadius,
            border: Border.all(
              color: active ? theme.accent : (states.highlighted ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
            ),
            child: Row(
              spacing: theme.space(3),
              children: [
                GhIcon(icon, size: theme.space(4), color: theme.muted),
                Text(
                  label,
                  style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink),
                ),
                if (count != null)
                  Text(
                    '$count',
                    style: theme.text(size: GhTextSize.x3s, weight: GhWeight.medium, color: theme.muted.withValues(alpha: 0.6)),
                  ),
                const Spacer(),
                if (count != null)
                  Transform.flip(
                    flipX: Directionality.of(context) == TextDirection.rtl,
                    child: GhIcon(GhIcons.chevronRight, size: theme.space(3.5), color: theme.muted),
                  )
                else if (active)
                  GhIcon(GhIcons.check, size: theme.space(3.5), color: theme.accentBright),
              ],
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(7),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(2.5),
          children: [
            Text(
              _ts('theme_preset_label'),
              style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.muted),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(2),
              children: [
                presetRow(
                  icon: GhIcons.sun,
                  label: _ts('preset_light_group'),
                  count: lightThemePresets.length,
                  onPressed: () => _openPresets(GhThemeMode.light, draft.themePreset),
                ),
                presetRow(
                  icon: GhIcons.moon,
                  label: _ts('preset_dark_group'),
                  count: darkThemePresets.length,
                  onPressed: () => _openPresets(GhThemeMode.dark, draft.themePreset),
                ),
                presetRow(
                  icon: GhIcons.palette,
                  label: _ts('theme_preset_custom'),
                  active: !presetActive,
                  onPressed: () => _notifier.selectPreset('custom'),
                ),
              ],
            ),
          ],
        ),
        if (!presetActive) ...[
          Wrap(
            spacing: theme.space(8),
            runSpacing: theme.space(4),
            children: [
              GhColorSwatchPicker(
                label: ghTr('onboarding_accent_color'),
                value: draft.accentColor,
                presets: light ? accentPresetsLight : accentPresetsDark,
                onChanged: _notifier.setAccentColor,
              ),
              GhColorSwatchPicker(
                label: ghTr('onboarding_bg_color'),
                value: draft.backgroundColor,
                presets: light ? bgPresetsLight : bgPresetsDark,
                onChanged: _notifier.setBackgroundColor,
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _ThemeModeSegmented(value: draft.themeMode, onChanged: _notifier.setThemeMode),
          ),
        ],
        GhSlider(
          label: ghTr('onboarding_corner_radius'),
          display: Text(
            '${_fmt(draft.cornerRadius)}px',
            style: theme.text(size: GhTextSize.xs, mono: true, color: theme.ink),
          ),
          value: draft.cornerRadius,
          min: 0,
          max: 15,
          step: 1,
          defaultValue: defaultCornerRadius,
          onChanged: _notifier.setCornerRadius,
        ),
      ],
    );
  }

  Widget _finishProgress(GhTheme theme, OnboardingState state) {
    final draft = state.draft;
    final scanProjects = draft.projectScanDirs.isNotEmpty;
    final scanVersions = draft.versionScanDirs.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(3),
      children: [
        ProgressRow(
          label: scanProjects ? ghTr('scanning_projects') : ghTr('skipped'),
          progress: scanProjects ? state.projectScan : null,
          running: scanProjects,
        ),
        ProgressRow(
          label: scanVersions ? ghTr('scanning_versions') : ghTr('skipped'),
          progress: scanVersions ? state.versionScan : null,
          running: scanVersions,
        ),
        if (draft.templateScanDir != null && isFeatureEnabled(draft, GhFeatureId.templates.id))
          ProgressRow(label: ghTr('syncing'), progress: null, running: true),
      ],
    );
  }

  Widget _finishSummary(GhTheme theme, AppSettings draft) {
    GhLanguageOption? language;
    for (final l in ghLanguages) {
      if (l.value == draft.language) language = l;
    }
    final pages = previewPages(draft).map((p) => p.label).join(', ');
    final mode = _ts(draft.themeMode == 'system' ? 'system' : draft.themeMode);
    final presetName = themePreset(draft.themePreset)?.name ?? _ts('theme_preset_custom');
    final templates = isFeatureEnabled(draft, GhFeatureId.templates.id);
    final none = ghTr('none');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(4),
      children: [
        SummarySection(
          title: _ts('interface_label'),
          children: [
            SummaryRow(
              label: _ts('language_label'),
              value: language == null
                  ? Text(draft.language)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: theme.space(1.5),
                      children: [
                        LanguageFlag(country: language.country),
                        Flexible(child: Text(language.displayLabel())),
                      ],
                    ),
            ),
          ],
        ),
        SummarySection(
          title: _to('setup'),
          children: [SummaryRow(label: _to('preview_heading'), value: Text(pages))],
        ),
        SummarySection(
          title: _ts('appearance'),
          children: [
            SummaryRow(label: _ts('theme'), value: Text('$mode · $presetName')),
            SummaryRow(label: _ts('onboarding_corner_radius'), value: Text('${_fmt(draft.cornerRadius)}px')),
          ],
        ),
        SummarySection(
          title: _ts('storage'),
          children: [
            SummaryRow(
              label: _to('project_folders'),
              value: Text(draft.projectScanDirs.isEmpty ? none : '${draft.projectScanDirs.length}'),
            ),
            SummaryRow(
              label: _to('version_folders'),
              value: Text(draft.versionScanDirs.isEmpty ? none : '${draft.versionScanDirs.length}'),
            ),
            if (templates) SummaryRow(label: ghTr('section_templates'), value: Text(draft.templateScanDir ?? none)),
          ],
        ),
      ],
    );
  }
}

String _fmt(double value) => value == value.roundToDouble() ? '${value.round()}' : '$value';

class _StepButton extends StatelessWidget {
  const _StepButton({
    super.key,
    required this.index,
    required this.label,
    required this.active,
    required this.done,
    required this.onPressed,
  });

  final int index;
  final String label;
  final bool active;
  final bool done;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      onPressed: onPressed,
      selected: active,
      semanticLabel: label,
      disabledOpacity: 1,
      disabledCursor: SystemMouseCursors.basic,
      borderRadius: radius,
      builder: (context, states) {
        final hover = states.highlighted;
        final fg = active ? theme.ink : (done ? theme.ink.withValues(alpha: 0.8) : (hover ? theme.ink : theme.muted));
        return GhAnimatedBox(
          padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
          color: active ? theme.overlay : (hover ? theme.overlay.withValues(alpha: 0.6) : Colors.transparent),
          borderRadius: radius,
          border: Border.all(color: active ? theme.outline.withValues(alpha: 0.5) : Colors.transparent),
          boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 4))] : null,
          child: Row(
            spacing: theme.space(2.5),
            children: [
              Container(
                width: theme.space(6),
                height: theme.space(6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: done ? theme.accent : (active ? theme.accent.withValues(alpha: 0.15) : theme.overlay),
                  borderRadius: BorderRadius.circular(theme.radiusTag),
                ),
                child: done
                    ? GhIcon(GhIcons.check, size: theme.space(3), color: Colors.white)
                    : Text(
                        '${index + 1}',
                        style: theme.text(size: GhTextSize.x3s, weight: GhWeight.bold, color: active ? theme.accentBright : theme.muted),
                      ),
              ),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: fg),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FooterBack extends StatelessWidget {
  const _FooterBack({required this.first, required this.onPressed});

  final bool first;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      key: const ValueKey('onboarding-back'),
      onPressed: onPressed,
      borderRadius: radius,
      disabledOpacity: 0.5,
      builder: (context, states) {
        final color = states.active ? theme.ink : theme.muted;
        return GhAnimatedBox(
          padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(2.5)),
          color: states.active ? theme.overlay : Colors.transparent,
          borderRadius: radius,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: theme.space(1.5),
            children: [
              if (!first)
                Transform.flip(
                  flipX: Directionality.of(context) == TextDirection.rtl,
                  child: GhIcon(GhIcons.chevronLeft, size: theme.space(3.5), color: color),
                ),
              Text(
                first ? ghTr('skip_setup') : ghTr('back'),
                style: theme.text(size: GhTextSize.sm, color: color),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrimaryFooterButton extends StatelessWidget {
  const _PrimaryFooterButton({super.key, required this.label, required this.onPressed, this.trailing, this.leading, this.compact = false});

  final String label;
  final VoidCallback? onPressed;
  final FaIconData? trailing;
  final FaIconData? leading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(compact ? theme.radiusBtn : theme.radiusItem);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      rippleColor: Colors.white,
      disabledOpacity: compact ? 0.5 : 0.6,
      builder: (context, states) => GhAnimatedBox(
        padding: EdgeInsets.symmetric(horizontal: theme.space(compact ? 4 : 6), vertical: theme.space(2.5)),
        color: states.active ? theme.accentBright : theme.accent,
        borderRadius: radius,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: theme.space(1.5),
          children: [
            if (leading != null) GhIcon(leading!, size: theme.space(3.5), color: Colors.white),
            Text(
              label,
              style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: Colors.white),
            ),
            if (trailing != null)
              Transform.flip(
                flipX: rtl,
                child: GhIcon(trailing!, size: theme.space(3.5), color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}

class _TemplateSuggestion extends StatelessWidget {
  const _TemplateSuggestion({super.key, required this.path, required this.source, required this.onPressed});

  final String path;
  final String source;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      semanticLabel: path,
      builder: (context, states) => DashedOutline(
        color: states.highlighted ? theme.accentDim : theme.outline.withValues(alpha: 0.6),
        radius: radius,
        child: GhAnimatedBox(
          padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
          color: states.highlighted ? theme.overlay.withValues(alpha: 0.6) : Colors.transparent,
          borderRadius: radius,
          child: Row(
            spacing: theme.space(2),
            children: [
              Container(
                width: theme.space(4),
                height: theme.space(4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(theme.radiusTag),
                ),
                child: GhIcon(GhIcons.copy, size: theme.space(3), color: theme.accentBright),
              ),
              Flexible(
                child: Text(
                  path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.ink),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: theme.space(32)),
                child: Text(
                  ghTr('from_workspace', args: {'name': source}),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text(size: GhTextSize.x3s, color: theme.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeModeSegmented extends StatelessWidget {
  const _ThemeModeSegmented({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    final modes = [
      ('dark', _ts('theme_dark'), GhIcons.moon),
      ('light', _ts('theme_light'), GhIcons.sun),
      ('system', _ts('system'), GhIcons.monitor),
    ];
    return Container(
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
          for (final (mode, label, icon) in modes)
            GhPressable(
              key: ValueKey('theme-mode:$mode'),
              onPressed: () => onChanged(mode),
              selected: value == mode,
              borderRadius: radius,
              builder: (context, states) {
                final active = value == mode;
                final fg = active ? Colors.white : (states.highlighted ? theme.ink : theme.muted);
                return GhAnimatedBox(
                  padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(1.5)),
                  color: active ? theme.accent : (states.highlighted ? theme.raised : Colors.transparent),
                  borderRadius: radius,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: theme.space(2),
                    children: [
                      GhIcon(icon, size: theme.space(3.5), color: fg),
                      Text(
                        label,
                        style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: fg),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown({required this.value, required this.onSelected});

  final String value;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    GhLanguageOption? current;
    for (final l in ghLanguages) {
      if (l.value == value) current = l;
    }
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhDropdown(
      align: GhSide.left,
      items: [
        for (final option in ghLanguages)
          GhMenuItem(
            id: option.value,
            label: option.displayLabel(),
            leading: SizedBox(
              width: 20,
              height: 14,
              child: FittedBox(child: LanguageFlag(country: option.country)),
            ),
            active: value == option.value,
            onSelected: () => onSelected(option.value),
          ),
      ],
      trigger: (context, open, toggle) => GhPressable(
        onPressed: toggle,
        expanded: open,
        borderRadius: radius,
        builder: (context, states) => GhAnimatedBox(
          padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(2)),
          color: theme.overlay,
          borderRadius: radius,
          border: Border.all(color: states.highlighted ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: theme.space(2),
            children: [
              if (current != null) LanguageFlag(country: current.country),
              Text(
                current?.displayLabel() ?? GhI18n.instance.language,
                style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.ink),
              ),
              AnimatedRotation(
                turns: open ? 0.5 : 0,
                duration: GhDurations.iconTransform,
                child: GhIcon(GhIcons.chevronDown, size: theme.space(3), color: theme.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
