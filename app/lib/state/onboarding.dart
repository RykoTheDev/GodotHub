import 'dart:async';

import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/events.dart';
import '../api/settings.dart';
import '../api/templates.dart';
import '../api/versions.dart';
import '../api/workspaces.dart';
import '../design/palette.dart';
import '../i18n/i18n.dart';
import '../logic/features.dart';
import '../logic/settings_copy.dart';
import '../src/rust/api/types.dart';
import 'api_data.dart';
import 'app_lifecycle.dart';
import 'app_signals.dart';
import 'categories.dart';
import 'discord_rpc.dart';
import 'news.dart';
import 'settings.dart';
import 'workspaces.dart';

enum OnboardingStepId { workspace, welcome, setup, projects, versions, templates, categories, appearance, finish }

@immutable
class OnboardingStep {
  const OnboardingStep(this.id, {this.feature, this.firstRunOnly = false});

  final OnboardingStepId id;
  final GhFeatureId? feature;
  final bool firstRunOnly;
}

const allOnboardingSteps = [
  OnboardingStep(OnboardingStepId.workspace, firstRunOnly: true),
  OnboardingStep(OnboardingStepId.welcome),
  OnboardingStep(OnboardingStepId.setup),
  OnboardingStep(OnboardingStepId.projects),
  OnboardingStep(OnboardingStepId.versions),
  OnboardingStep(OnboardingStepId.templates, feature: GhFeatureId.templates),
  OnboardingStep(OnboardingStepId.categories, feature: GhFeatureId.categories),
  OnboardingStep(OnboardingStepId.appearance),
  OnboardingStep(OnboardingStepId.finish),
];

const starterCategories = ['In Progress', 'Prototypes', 'Finished', 'Game Jams'];

final starterCategoryColors = {
  for (var i = 0; i < starterCategories.length; i++) starterCategories[i]: categoryColors[i],
};

List<OnboardingStep> onboardingSteps(AppSettings draft, {required bool firstRun}) => [
  for (final step in allOnboardingSteps)
    if ((step.feature == null || isFeatureEnabled(draft, step.feature!.id)) && (!step.firstRunOnly || firstRun)) step,
];

String onboardingStepLabel(OnboardingStepId id, [Translations? translations]) {
  final tr = translations ?? t;
  return switch (id) {
    OnboardingStepId.workspace => tr.onboarding.workspace_step,
    OnboardingStepId.welcome => tr.onboarding.basics,
    OnboardingStepId.setup => tr.onboarding.setup,
    OnboardingStepId.projects => tr.common.section_projects,
    OnboardingStepId.versions => tr.common.section_versions,
    OnboardingStepId.templates => tr.common.section_templates,
    OnboardingStepId.categories => tr.common.categories,
    OnboardingStepId.appearance => tr.settings.appearance,
    OnboardingStepId.finish => tr.onboarding.finish,
  };
}

Map<String, String> starterCategoryLabels([Translations? translations]) {
  final tr = translations ?? t;
  return {
    'In Progress': tr.onboarding.in_progress,
    'Prototypes': tr.onboarding.prototypes,
    'Finished': tr.onboarding.finished,
    'Game Jams': tr.onboarding.game_jams,
  };
}

@immutable
class PathSuggestion {
  const PathSuggestion(this.path, this.source);

  final String path;
  final String source;

  @override
  bool operator ==(Object other) => other is PathSuggestion && other.path == path && other.source == source;

  @override
  int get hashCode => Object.hash(path, source);

  @override
  String toString() => 'PathSuggestion($path, $source)';
}

List<PathSuggestion> _dedupe(Iterable<PathSuggestion> items) {
  final seen = <String>{};
  return [for (final item in items) if (seen.add(item.path)) item];
}

@immutable
class OnboardingState {
  const OnboardingState({
    required this.draft,
    this.stepId = OnboardingStepId.workspace,
    this.finishing = false,
    this.workspaceSuggestions = const [],
    this.activeWorkspaceId = '',
    this.firstRun = true,
    this.projectScan,
    this.versionScan,
    this.categoryDraft = '',
    required this.categoryColor,
    this.categoryBusy = false,
  });

  final AppSettings draft;
  final OnboardingStepId stepId;
  final bool finishing;
  final List<WorkspaceScanDirs> workspaceSuggestions;
  final String activeWorkspaceId;
  final bool firstRun;
  final ScanProgress? projectScan;
  final ScanProgress? versionScan;
  final String categoryDraft;
  final String categoryColor;
  final bool categoryBusy;

  List<OnboardingStep> get steps => onboardingSteps(draft, firstRun: firstRun);

  int get stepIndex {
    final index = steps.indexWhere((step) => step.id == stepId);
    return index < 0 ? 0 : index;
  }

  OnboardingStep get step => steps[stepIndex];

  bool get presetActive => draft.themePreset != 'custom';

  Iterable<WorkspaceScanDirs> get _others => workspaceSuggestions.where((w) => w.workspaceId != activeWorkspaceId);

  List<PathSuggestion> get projectSuggestions =>
      _dedupe(_others.expand((w) => w.projectScanDirs.map((path) => PathSuggestion(path, w.workspaceName))));

  List<PathSuggestion> get versionSuggestions =>
      _dedupe(_others.expand((w) => w.versionScanDirs.map((path) => PathSuggestion(path, w.workspaceName))));

  List<PathSuggestion> get templateSuggestions => _dedupe(
    _others.expand((w) => w.templateScanDir == null ? const <PathSuggestion>[] : [PathSuggestion(w.templateScanDir!, w.workspaceName)]),
  );

  List<PathSuggestion> get pendingTemplateSuggestions =>
      templateSuggestions.where((s) => s.path != draft.templateScanDir).toList(growable: false);

  OnboardingState copyWith({
    AppSettings? draft,
    OnboardingStepId? stepId,
    bool? finishing,
    List<WorkspaceScanDirs>? workspaceSuggestions,
    String? activeWorkspaceId,
    bool? firstRun,
    ValueGetter<ScanProgress?>? projectScan,
    ValueGetter<ScanProgress?>? versionScan,
    String? categoryDraft,
    String? categoryColor,
    bool? categoryBusy,
  }) => OnboardingState(
    draft: draft ?? this.draft,
    stepId: stepId ?? this.stepId,
    finishing: finishing ?? this.finishing,
    workspaceSuggestions: workspaceSuggestions ?? this.workspaceSuggestions,
    activeWorkspaceId: activeWorkspaceId ?? this.activeWorkspaceId,
    firstRun: firstRun ?? this.firstRun,
    projectScan: projectScan != null ? projectScan() : this.projectScan,
    versionScan: versionScan != null ? versionScan() : this.versionScan,
    categoryDraft: categoryDraft ?? this.categoryDraft,
    categoryColor: categoryColor ?? this.categoryColor,
    categoryBusy: categoryBusy ?? this.categoryBusy,
  );
}

final themePreviewProvider = NotifierProvider<ThemePreviewNotifier, AppSettings?>(ThemePreviewNotifier.new);

class ThemePreviewNotifier extends Notifier<AppSettings?> {
  @override
  AppSettings? build() => null;

  void preview(AppSettings settings) => state = settings;

  void clear() => state = null;
}

final onboardingProvider = NotifierProvider.autoDispose<OnboardingNotifier, OnboardingState>(OnboardingNotifier.new);

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    final settings = ref.read(settingsProvider).value ?? defaultSettings;
    final workspaces = ref.read(workspacesProvider);
    ref.listen<WorkspacesView>(workspacesProvider, (_, next) {
      state = state.copyWith(activeWorkspaceId: next.activeId, firstRun: next.workspaces.length <= 1);
    });
    ref.listenAppEvent(AppEventKind.projectScanProgress, (event) {
      final progress = event.scanProgress;
      if (progress != null) state = state.copyWith(projectScan: () => progress);
    });
    ref.listenAppEvent(AppEventKind.versionScanProgress, (event) {
      final progress = event.scanProgress;
      if (progress != null) state = state.copyWith(versionScan: () => progress);
    });
    final discord = ref.read(discordRpcDraftProvider.notifier);
    final preview = ref.read(themePreviewProvider.notifier);
    ref.onDispose(() {
      scheduleMicrotask(() {
        try {
          discord.set(null);
          preview.clear();
        } catch (_) {}
      });
    });
    listenSelf((previous, next) {
      if (previous != null && previous.draft != next.draft) discord.set(next.draft);
    });
    scheduleMicrotask(() async {
      if (!ref.mounted) return;
      discord.set(state.draft);
      AppSignals.emit(viewChangedSignal, 'onboarding');
      try {
        final suggestions = await WorkspacesApi.scanDirs();
        if (ref.mounted) state = state.copyWith(workspaceSuggestions: suggestions);
      } catch (_) {}
    });
    return OnboardingState(
      draft: settings,
      activeWorkspaceId: workspaces.activeId,
      firstRun: workspaces.workspaces.length <= 1,
      categoryColor: categoryColors.first,
    );
  }

  AppSettings get draft => state.draft;

  void setDraft(AppSettings Function(AppSettings draft) update) => state = state.copyWith(draft: update(state.draft));

  void replaceDraft(AppSettings draft) => state = state.copyWith(draft: draft);

  void _preview() => ref.read(themePreviewProvider.notifier).preview(state.draft);

  GhThemeMode _resolve(String mode) => resolveThemeMode(mode, ghPlatformBrightness());

  void selectPreset(String id) {
    final current = state.draft;
    if (id == current.themePreset) return;
    if (id == 'custom') {
      final defaults = customThemeDefaults(_resolve(current.themeMode));
      setDraft(
        (d) => copySettings(d, themePreset: id, accentColor: defaults.accentColor, backgroundColor: defaults.backgroundColor),
      );
      _preview();
      return;
    }
    final preset = themePreset(id);
    if (preset == null) return;
    setDraft((d) => copySettings(d, themePreset: id, themeMode: preset.mode.name));
    _preview();
  }

  void setThemeMode(String mode) {
    final current = state.draft;
    final targetDark = _resolve(mode) == GhThemeMode.dark;
    final background = isDarkColor(current.backgroundColor) == targetDark
        ? current.backgroundColor
        : (targetDark ? defaultBackground : defaultBackgroundLight);
    setDraft((d) => copySettings(d, themeMode: mode, backgroundColor: background));
    _preview();
  }

  void setAccentColor(String hex) {
    setDraft((d) => copySettings(d, accentColor: hex));
    _preview();
  }

  void setBackgroundColor(String hex) {
    setDraft((d) => copySettings(d, backgroundColor: hex));
    _preview();
  }

  void setCornerRadius(double value) {
    setDraft((d) => copySettings(d, cornerRadius: value));
    _preview();
  }

  void jumpTo(int index) {
    final steps = state.steps;
    state = state.copyWith(stepId: steps[index.clamp(0, steps.length - 1)].id);
  }

  void goNext() => jumpTo(state.stepIndex + 1);

  void goBack() => jumpTo(state.stepIndex - 1);

  void setCategoryDraft(String value) => state = state.copyWith(categoryDraft: value);

  void setCategoryColor(String value) => state = state.copyWith(categoryColor: value);

  List<Category> get categories => ref.read(categoriesProvider).data;

  bool isStarterCategoryAdded(String name, [List<Category>? existing]) {
    final label = (starterCategoryLabels()[name] ?? name).toLowerCase();
    return (existing ?? categories).any((c) {
      final current = c.name.toLowerCase();
      return current == name.toLowerCase() || current == label;
    });
  }

  Future<void> addStarterCategory(String name) async {
    if (isStarterCategoryAdded(name)) return;
    state = state.copyWith(categoryBusy: true);
    try {
      await ref
          .read(categoriesProvider.notifier)
          .create(starterCategoryLabels()[name] ?? name, starterCategoryColors[name] ?? state.categoryColor);
    } finally {
      if (ref.mounted) state = state.copyWith(categoryBusy: false);
    }
  }

  Future<void> addCustomCategory() async {
    final name = state.categoryDraft.trim();
    if (name.isEmpty) return;
    state = state.copyWith(categoryBusy: true);
    try {
      await ref.read(categoriesProvider.notifier).create(name, state.categoryColor);
      if (ref.mounted) state = state.copyWith(categoryDraft: '', categoryColor: categoryColors.first);
    } finally {
      if (ref.mounted) state = state.copyWith(categoryBusy: false);
    }
  }

  Future<void> finish(bool skip, {Future<void> Function()? beforeComplete, Future<void> Function()? afterComplete}) async {
    state = state.copyWith(finishing: true, projectScan: () => null, versionScan: () => null);
    final settings = ref.read(settingsProvider).value ?? defaultSettings;
    final draft = state.draft;
    final result = skip
        ? copySettings(settings, setupComplete: true, language: draft.language)
        : copySettings(draft, setupComplete: true);
    await Future.wait([
      if (result.projectScanDirs.isNotEmpty) SettingsApi.scanForProjects(result.projectScanDirs, result.scanDepth),
      if (result.versionScanDirs.isNotEmpty) VersionsApi.scan(result.versionScanDirs, result.scanDepth),
      if (result.templateScanDir != null && isFeatureEnabled(result, GhFeatureId.templates.id))
        TemplatesApi.syncWithScanDir().then<void>((_) {}, onError: (Object _) {}),
    ]);
    if (!skip) await beforeComplete?.call();
    await ref.read(settingsProvider.notifier).save(result);
    if (!skip && afterComplete != null) unawaited(afterComplete());
    ref.read(themePreviewProvider.notifier).clear();
    try {
      await SettingsApi.restartWatchers();
    } catch (_) {}
    if (ref.mounted) state = state.copyWith(finishing: false);
  }
}
