import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import '../api/projects.dart';
import '../design/design.dart';
import '../logic/card_view_settings.dart';
import '../logic/locale.dart';
import '../logic/project_drag.dart';
import '../logic/project_search.dart';
import '../logic/project_sort.dart';
import '../modals/bulk_tag_modal.dart';
import '../modals/category_manager_modal.dart';
import '../motion/animated_number.dart';
import '../motion/motion.dart';
import '../shell/git_sidebar_overlay.dart';
import '../src/rust/api/types.dart';
import '../src/ui_prefs.dart';
import '../state/app_signals.dart';
import '../state/categories.dart';
import '../state/git_status.dart';
import '../state/godot_versions.dart';
import '../state/keyboard_shortcuts.dart';
import '../state/projects.dart';
import '../state/scroll_compensation.dart';
import '../state/settings.dart';
import '../state/shell_signals.dart';
import '../ui/controls/toggle.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/core/tooltip.dart';
import '../ui/feedback/confirm_dialog.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/overlays/context_menu.dart';
import '../ui/overlays/dropdown.dart';
import '../ui/overlays/menu.dart';
import '../ui/overlays/slash_menu.dart';
import '../ui/controls/search_bar.dart';
import '../ui/reusables/tool_buttons.dart';
import '../ui/reusables/view_header.dart';
import '../ui/shell/disclosure.dart';
import '../ui/shell/overlay_scroll_area.dart';
import '../ui/shell/view_insets.dart';
import 'category_sections.dart';
import 'project_actions.dart';
import 'project_card.dart';
import 'project_layouts.dart';
import 'project_tile.dart';

abstract final class ProjectsViewPrefs {
  static const viewMode = 'godothub_projects_view_mode';
  static const sortBy = 'godothub_projects_sort_by';
  static const tagFilter = 'godothub_projects_tag_filter';
  static const categoryFilter = 'godothub_projects_category_filter';
  static const uncategorized = '__uncategorized__';
  static final Map<String, String> session = {};
}

const _fieldIcons = {
  ProjectSearchField.name: GhIcons.node,
  ProjectSearchField.tag: GhIcons.tags,
  ProjectSearchField.category: GhIcons.filter,
  ProjectSearchField.version: GhIcons.gitBranch,
  ProjectSearchField.path: GhIcons.folder,
  ProjectSearchField.pinned: GhIcons.pin,
};

const _cardToggles = [
  (CardViewKey.showSize, GhIcons.hardDrive, 'customize_card_show_size'),
  (CardViewKey.showTime, GhIcons.stopwatch, 'customize_card_show_time'),
  (CardViewKey.showSessionTimer, GhIcons.stopwatch, 'customize_card_show_session_timer'),
  (CardViewKey.blurPath, GhIcons.eyeSlash, 'customize_card_blur_path'),
  (CardViewKey.showPath, GhIcons.folder, 'customize_card_show_path'),
  (CardViewKey.showTags, GhIcons.tags, 'customize_card_show_tags'),
  (CardViewKey.showLastOpened, GhIcons.clock, 'customize_card_show_last_opened'),
  (CardViewKey.showPlay, GhIcons.play, 'customize_card_show_play'),
  (CardViewKey.showConsole, GhIcons.terminal, 'customize_card_show_console'),
];

class _SlashMenuState {
  const _SlashMenuState({
    required this.field,
    required this.title,
    required this.items,
    required this.emptyLabel,
    required this.token,
    this.footer,
  });

  final bool field;
  final String title;
  final String? footer;
  final List<GhSlashMenuItem> items;
  final String emptyLabel;
  final ProjectSearchToken token;
}

class ProjectsView extends ConsumerStatefulWidget {
  const ProjectsView({super.key, this.onOpenSettings, this.connected = false, this.gitSidebarOpen = false, this.active = true, this.prefs});

  final VoidCallback? onOpenSettings;
  final bool connected;
  final bool gitSidebarOpen;
  final bool active;
  final UiPrefsStore? prefs;

  @override
  ConsumerState<ProjectsView> createState() => ProjectsViewState();
}

class ProjectsViewState extends ConsumerState<ProjectsView> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchNode = FocusNode(debugLabel: 'ProjectsView search');
  final ScrollCompensation _scroll = ScrollCompensation();
  final List<StreamSubscription<AppSignal>> _subscriptions = [];
  final GlobalKey<GhImportButtonState> _import = GlobalKey();
  int _caret = 0;
  int _menuIndex = 0;
  bool _menuDismissed = false;
  Set<String> _selected = {};
  int? _lastClicked;
  int _lastSelectionCount = 0;
  late ProjectViewMode _viewMode;
  late ProjectSortOption _sortBy;
  String? _tagFilter;
  String? _categoryFilter;
  int _sortNow = DateTime.now().millisecondsSinceEpoch;
  Timer? _sortTimer;
  ({Offset position, Category category})? _categoryMenu;
  bool _categoryMenuVisible = false;
  String _pinnedSignature = '';
  String? _lastTagFilter;

  UiPrefsStore get _prefs => widget.prefs ?? UiPrefsStore.instance;

  @override
  void initState() {
    super.initState();
    final rawMode = _prefs.getItem(ProjectsViewPrefs.viewMode);
    _viewMode = ProjectViewMode.fromId(rawMode ?? '') ?? ProjectViewMode.list;
    final rawSort = _prefs.getItem(ProjectsViewPrefs.sortBy);
    _sortBy = (rawSort != null ? ProjectSortOption.fromValue(rawSort) : null) ?? ProjectSortOption.categories;
    _tagFilter = ProjectsViewPrefs.session[ProjectsViewPrefs.tagFilter];
    final rawCategory = ProjectsViewPrefs.session[ProjectsViewPrefs.categoryFilter];
    _categoryFilter = rawCategory == ProjectsViewPrefs.uncategorized ? '' : rawCategory;
    _prefs.removeItem(ProjectsViewPrefs.tagFilter);
    _search.addListener(_onSearchChanged);
    void on(String name, void Function(Object? detail) handler) =>
        _subscriptions.add(AppSignals.on(name).listen((signal) => handler(signal.detail)));
    on(switchViewSignal, (detail) {
      final mode = detail is String ? ProjectViewMode.fromId(detail) : null;
      if (mode != null) _setViewMode(mode);
    });
    on(focusSearchSignal, (_) => _searchNode.requestFocus());
    on(launchSelectionSignal, (_) {
      if (_selected.isNotEmpty) _batchLaunch();
    });
    on(deleteSelectionSignal, (_) {
      if (_selected.isNotEmpty) _confirmBatch(delete: false);
    });
    on(setCategoryFilterSignal, (detail) {
      if (detail is! String) return;
      _setCategoryFilter(detail.isEmpty ? null : detail);
      _clearSelection();
    });
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void didUpdateWidget(ProjectsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active && !widget.active) _clearSelection();
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    HardwareKeyboard.instance.removeHandler(_onKey);
    _sortTimer?.cancel();
    _search.dispose();
    _searchNode.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape && _selected.isNotEmpty && mounted) {
      _clearSelection();
    }
    return false;
  }

  void _onSearchChanged() {
    final selection = _search.selection;
    final caret = selection.isValid ? selection.start : _search.text.length;
    if (caret != _caret) setState(() => _caret = caret);
  }

  void _setViewMode(ProjectViewMode mode) {
    setState(() => _viewMode = mode);
    _prefs.setItem(ProjectsViewPrefs.viewMode, mode.id);
  }

  void _setSortBy(ProjectSortOption sort) {
    setState(() => _sortBy = sort);
    _prefs.setItem(ProjectsViewPrefs.sortBy, sort.value);
  }

  void _setTagFilter(String? tag) {
    setState(() => _tagFilter = tag);
    if (tag == null) {
      ProjectsViewPrefs.session.remove(ProjectsViewPrefs.tagFilter);
    } else {
      ProjectsViewPrefs.session[ProjectsViewPrefs.tagFilter] = tag;
    }
  }

  void _setCategoryFilter(String? category) {
    setState(() => _categoryFilter = category);
    if (category == null) {
      ProjectsViewPrefs.session.remove(ProjectsViewPrefs.categoryFilter);
    } else {
      ProjectsViewPrefs.session[ProjectsViewPrefs.categoryFilter] = category.isEmpty ? ProjectsViewPrefs.uncategorized : category;
    }
  }

  void _clearSelection() {
    if (!mounted) return;
    setState(() {
      _selected = {};
      _lastClicked = null;
    });
  }

  void _toggleSelect(String id, SelectModifiers modifiers, List<Project> visualOrder) {
    final clicked = visualOrder.indexWhere((p) => p.id == id);
    setState(() {
      final next = {..._selected};
      final last = _lastClicked;
      if (modifiers.shift && last != null) {
        final start = last < clicked ? last : clicked;
        final end = last < clicked ? clicked : last;
        for (final p in visualOrder.sublist(start, end + 1)) {
          next.add(p.id);
        }
      } else if (!next.remove(id)) {
        next.add(id);
      }
      _selected = next;
      _lastClicked = clicked;
    });
  }

  ProjectsNotifier get _projects => ref.read(projectsProvider.notifier);

  void _batchLaunch() {
    final console = ref.read(settingsProvider).value?.launchWithConsole ?? false;
    for (final id in _selected) {
      AppSignals.emit(openProjectSignal, {'id': id, 'console': console});
    }
    _clearSelection();
  }

  void _batchPin() {
    final projects = ref.read(projectsProvider).data;
    final ids = [..._selected];
    final allPinned = ids.every((id) => projects.where((p) => p.id == id).firstOrNull?.pinned ?? false);
    for (final id in ids) {
      _projects.setPinned(id, !allPinned).ignore();
    }
    _clearSelection();
  }

  Future<void> _reimport(List<Project> removed) async {
    await Future.wait([
      for (final p in removed)
        ProjectsApi.import(p.path, p.godotVersion, p.category).then<void>((_) {}, onError: (Object e) => ghToasts.reportError(e)),
    ]);
    await _projects.refresh();
  }

  Future<void> _removeWithUndo(Project project, bool deleteFiles) async {
    if (deleteFiles) {
      await _projects.remove(project.id, true);
      return;
    }
    final undo = context.tr.common.undo;
    await _projects.remove(project.id, false);
    ghToasts.pushToast(
      GhToastType.info,
      ghTr('removed_from_library', count: 1),
      ttlMs: 6000,
      action: GhToastAction(label: undo, onClick: () => _reimport([project])),
    );
  }

  Future<void> _confirmBatch({required bool delete}) async {
    final tr = context.tr.common;
    final count = _selected.length;
    final ok = await showGhConfirmDialog(
      context,
      title: ghTr(delete ? 'bulk_delete_title' : 'bulk_remove_title', count: count),
      description: ghTr(delete ? 'bulk_delete_desc' : 'bulk_remove_desc', count: count),
      confirmLabel: delete ? tr.project_delete_confirm : tr.bulk_remove,
      variant: delete ? GhConfirmVariant.danger : GhConfirmVariant.normal,
    );
    if (!ok || !mounted) return;
    final undo = context.tr.common.undo;
    final projects = ref.read(projectsProvider).data;
    if (delete) {
      for (final id in [..._selected]) {
        await _projects.remove(id, true);
      }
      _clearSelection();
      return;
    }
    final targets = [for (final id in _selected) ?projects.where((p) => p.id == id).firstOrNull];
    for (final p in targets) {
      await _projects.remove(p.id, false);
    }
    _clearSelection();
    if (targets.isNotEmpty) {
      ghToasts.pushToast(
        GhToastType.info,
        ghTr('removed_from_library', count: targets.length),
        ttlMs: 6000,
        action: GhToastAction(label: undo, onClick: () => _reimport(targets)),
      );
    }
  }

  Future<void> _hideCategory(Category category) async {
    final projects = ref.read(projectsProvider).data;
    if (_selected.isNotEmpty) {
      setState(() {
        _selected = {
          for (final id in _selected)
            if ((projects.where((p) => p.id == id).firstOrNull?.category ?? '') != category.name) id,
        };
      });
    }
    final message = context.tr.common.category_hidden_toast.args({'name': category.name});
    await ref.read(categoriesProvider.notifier).setHidden(category.id, true);
    ghToasts.pushToast(GhToastType.info, message);
  }

  _SlashMenuState? _slashMenu(ParsedProjectQuery parsed, List<Project> projects, List<Category> categories) {
    if (_menuDismissed) return null;
    final token = parsed.activeToken;
    if (token == null) return null;
    final tr = context.tr.common;
    final labels = {
      ProjectSearchField.name: tr.search_filter_name,
      ProjectSearchField.tag: tr.search_filter_tag,
      ProjectSearchField.category: tr.category,
      ProjectSearchField.version: tr.search_filter_version,
      ProjectSearchField.path: tr.search_filter_path,
      ProjectSearchField.pinned: tr.pinned_section,
    };
    final field = token.field;
    if (field != null) {
      if (field == ProjectSearchField.name || field == ProjectSearchField.path) return null;
      final partial = token.value.trim().toLowerCase();
      final items = switch (field) {
        ProjectSearchField.tag => [
          for (final tag in collectTags(projects))
            if (tag.toLowerCase().contains(partial)) GhSlashMenuItem(id: 'tag:$tag', label: tag, hint: 'tag', icon: GhIcons.tags),
        ],
        ProjectSearchField.category => [
          for (final c in categories)
            if (c.name.toLowerCase().contains(partial))
              GhSlashMenuItem(id: 'category:${c.name}', label: c.name, hint: 'category', dotColor: colorFromHex(c.color)),
        ],
        ProjectSearchField.version => [
          for (final v in collectVersions(projects))
            if (v.toLowerCase().contains(partial)) GhSlashMenuItem(id: 'version:$v', label: v, hint: 'version', icon: GhIcons.gitBranch),
        ],
        _ => [
          for (final item in [
            GhSlashMenuItem(id: 'pinned:true', label: tr.search_filter_pinned_yes, hint: 'true', icon: GhIcons.pin),
            GhSlashMenuItem(id: 'pinned:false', label: tr.search_filter_pinned_no, hint: 'false', icon: GhIcons.pin),
          ])
            if (partial.isEmpty || item.label.toLowerCase().contains(partial) || item.id.contains(partial)) item,
        ],
      };
      return _SlashMenuState(field: false, title: labels[field]!, items: items, emptyLabel: tr.search_filter_no_values, token: token);
    }
    if (!token.raw.startsWith('/')) return null;
    final partial = token.raw.substring(1).toLowerCase();
    final items = [
      for (final f in ProjectSearchField.values)
        if (partial.isEmpty || f.name.startsWith(partial) || labels[f]!.toLowerCase().startsWith(partial))
          GhSlashMenuItem(id: f.name, label: labels[f]!, hint: '${f.name}:', icon: _fieldIcons[f]),
    ];
    return _SlashMenuState(
      field: true,
      title: tr.search_filter_title,
      footer: tr.search_slash_hint,
      items: items,
      emptyLabel: tr.search_filter_no_matches,
      token: token,
    );
  }

  void _applySlashItem(_SlashMenuState menu, GhSlashMenuItem item) {
    final replacement = menu.field ? (item.id == 'name' || item.id == 'path' ? '${item.id}: ' : '${item.id}:') : '${item.id} ';
    final next = replaceToken(_search.text, menu.token.range, replacement);
    _search.value = TextEditingValue(
      text: next.value,
      selection: TextSelection.collapsed(offset: next.caret),
    );
    setState(() {
      _caret = next.caret;
      _menuIndex = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchNode.requestFocus();
    });
  }

  KeyEventResult _onSearchKey(_SlashMenuState? menu, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (menu != null && menu.items.isNotEmpty) {
      final count = menu.items.length;
      if (key == LogicalKeyboardKey.arrowDown) {
        setState(() => _menuIndex = (_menuIndex + 1) % count);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowUp) {
        setState(() => _menuIndex = (_menuIndex - 1 + count) % count);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter || key == LogicalKeyboardKey.tab) {
        _applySlashItem(menu, menu.items[_menuIndex.clamp(0, count - 1)]);
        return KeyEventResult.handled;
      }
    } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      setState(() => _menuDismissed = true);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape && menu != null) {
      setState(() => _menuDismissed = true);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _syncSortTimer(bool needed) {
    if (needed && _sortTimer == null) {
      _sortNow = DateTime.now().millisecondsSinceEpoch;
      _sortTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) setState(() => _sortNow = DateTime.now().millisecondsSinceEpoch);
      });
    } else if (!needed && _sortTimer != null) {
      _sortTimer!.cancel();
      _sortTimer = null;
    }
  }

  Future<void> _openCategoryManager() => showGhModal<void>(context, (modalContext) {
    return Consumer(
      builder: (context, ref, _) {
        final categories = ref.watch(categoriesProvider).data;
        final projects = ref.watch(projectsProvider).data;
        final notifier = ref.read(categoriesProvider.notifier);
        return CategoryManagerModal(
          categories: categories,
          projects: projects,
          onClose: () => Navigator.of(modalContext).pop(),
          onCreate: (name, color) => notifier.create(name, color),
          onUpdate: (id, name, color) => notifier.update(id, name, color),
          onDelete: notifier.remove,
          onReorder: notifier.reorder,
          onAssignFolder: (id, folder) async {
            final updated = await notifier.assignFolder(id, folder);
            await ref.read(projectsProvider.notifier).refresh();
            return updated;
          },
          onUnassignFolder: (id, folder) async {
            final updated = await notifier.unassignFolder(id, folder);
            await ref.read(projectsProvider.notifier).refresh();
            return updated;
          },
        );
      },
    );
  });

  Future<void> _openBulkTags() {
    final projects = ref.read(projectsProvider).data;
    final selected = [for (final id in _selected) ?projects.where((p) => p.id == id).firstOrNull];
    return showGhModal<void>(
      context,
      (modalContext) =>
          BulkTagModal(projects: selected, onClose: () => Navigator.of(modalContext).pop(), onApplied: () => _projects.refresh().ignore()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr;
    final settings = ref.watch(settingsProvider).value ?? defaultSettings;
    final projectsState = ref.watch(projectsProvider);
    final projects = projectsState.data;
    final categories = ref.watch(categoriesProvider).data;
    final installed = ref.watch(godotVersionsProvider.select((state) => state.installed));
    final paths = [for (final p in projects) p.path];
    final git = ref.watch(gitStatusMapProvider(gitStatusRequest(paths, widget.active)));

    if (!settings.customizeViewEnabled && _viewMode != ProjectViewMode.list) {
      _viewMode = ProjectViewMode.list;
      _prefs.setItem(ProjectsViewPrefs.viewMode, _viewMode.id);
    }
    if (_tagFilter != null && !projects.any((p) => p.tags.contains(_tagFilter))) {
      WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _setTagFilter(null) : null);
    }
    if (_categoryFilter != null) {
      final filter = _categoryFilter!;
      final missing = filter.isNotEmpty && !categories.any((c) => c.name == filter && !c.hidden);
      if (!settings.categoriesEnabled || missing) {
        WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _setCategoryFilter(null) : null);
      }
    }
    _syncSortTimer(widget.active && _sortBy == ProjectSortOption.timeDesc && projects.any((p) => p.sessionStartedAtMs != null));

    final parsed = parseProjectQuery(_search.text, _caret);
    final scores = <String, int>{};
    if (parsed.active) {
      for (final p in projects) {
        final score = matchProject(p, parsed);
        if (score != null) scores[p.id] = score;
      }
    }
    var base = projects;
    if (parsed.active) {
      base = [for (final p in base) if (scores.containsKey(p.id)) p];
    }
    if (_tagFilter != null) {
      base = [for (final p in base) if (p.tags.contains(_tagFilter)) p];
    }
    if (_categoryFilter != null) {
      base = _categoryFilter!.isEmpty
          ? [
              for (final p in base)
                if (p.category == null || p.category!.isEmpty) p,
            ]
          : [
              for (final p in base)
                if ((p.category ?? '') == _categoryFilter) p,
            ];
    }
    final effectiveSort = _sortBy == ProjectSortOption.categories && !settings.categoriesEnabled ? ProjectSortOption.manual : _sortBy;
    final categoriesSorted = settings.categoriesEnabled && effectiveSort == ProjectSortOption.categories;
    final groupingEnabled = categoriesSorted && !parsed.active;
    final visibleCategories = [
      for (final c in categories)
        if (!c.hidden) c,
    ];
    final hiddenCategories = <HiddenCategoryEntry>[];
    final hidden = [
      for (final c in categories)
        if (c.hidden) c,
    ];
    if (hidden.isNotEmpty) {
      final counts = <String, int>{};
      for (final p in base) {
        if (p.category != null && p.category!.isNotEmpty) counts[p.category!] = (counts[p.category!] ?? 0) + 1;
      }
      for (final c in hidden) {
        hiddenCategories.add(HiddenCategoryEntry(c, counts[c.name] ?? 0));
      }
    }
    final hiddenNames = {for (final h in hiddenCategories) h.category.name};
    final surfaceCategories = settings.categoriesEnabled ? visibleCategories : const <Category>[];
    final hiddenEntries = categoriesSorted ? hiddenCategories : const <HiddenCategoryEntry>[];
    final listed = groupingEnabled && hiddenNames.isNotEmpty
        ? [
            for (final p in base)
              if (p.category == null || p.category!.isEmpty || !hiddenNames.contains(p.category)) p,
          ]
        : base;
    final cmp = comparatorFor(effectiveSort, _sortNow);
    final filtered = stableSorted(listed, (a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      if (a.pinned) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        return order != 0 ? order : ghLocaleCompare(a.name, b.name);
      }
      if (parsed.active) {
        final diff = (scores[b.id] ?? 0) - (scores[a.id] ?? 0);
        if (diff != 0) return diff;
      }
      return cmp != null ? cmp(a, b) : a.sortOrder.compareTo(b.sortOrder);
    });
    final hasActiveFilters = _search.text.trim().isNotEmpty || _tagFilter != null || _categoryFilter != null;
    final dragEnabled = !hasActiveFilters;
    final visualOrder = _visualOrder(filtered, groupingEnabled, visibleCategories, surfaceCategories);

    final pinnedSignature = [
      for (final p in projects)
        if (p.pinned) p.id,
    ].join(',');
    if (pinnedSignature != _pinnedSignature || _tagFilter != _lastTagFilter) {
      _pinnedSignature = pinnedSignature;
      _lastTagFilter = _tagFilter;
      _scroll.restoreScroll();
    }
    if (_selected.isNotEmpty) _lastSelectionCount = _selected.length;
    final shownSelection = _selected.isNotEmpty ? _selected.length : _lastSelectionCount;
    final allVisibleSelected = filtered.isNotEmpty && filtered.every((p) => _selected.contains(p.id));
    final menu = _slashMenu(parsed, projects, categories);

    ProjectCallbacks callbacksFor(Project p) => ProjectCallbacks(
      onTogglePin: () => _projects.setPinned(p.id, !p.pinned).ignore(),
      onVersionChange: (tag) => _projects.updateVersion(p.id, tag).ignore(),
      onRemove: () => _removeWithUndo(p, false).ignore(),
      onDelete: () => _projects.remove(p.id, true).ignore(),
      onCategoryChange: _viewMode == ProjectViewMode.list
          ? (settings.categoriesEnabled && _sortBy != ProjectSortOption.categories
                ? (cat) => _projects.setCategory(p.id, cat).ignore()
                : null)
          : (cat) => _projects.setCategory(p.id, cat).ignore(),
      onDuplicate: () => showProjectModalPlaceholder(context, 'duplicate', GhIcons.copy),
      onTagsSaved: (updated) => _projects.updateTags(updated.id, updated.tags).ignore(),
      onTagClick: (tag) => _setTagFilter(_tagFilter == tag ? null : tag),
      onLaunchArgsChange: (args) =>
          ProjectsApi.update(p.id, ProjectUpdate(launchArguments: args)).then((_) => _projects.refresh()).ignore(),
      onShowGitSidebar: () => AppSignals.emit(showGitSidebarSignal, GitSidebarTarget(project: p, gitStatus: git.statusMap[p.path])),
      onToggleSelect: (modifiers) => _toggleSelect(p.id, modifiers, visualOrder),
    );

    Widget cardBuilder(Project p, {bool preview = false}) {
      final status = git.statusMap[p.path];
      if (_viewMode == ProjectViewMode.list) {
        return ProjectCard(
          key: preview ? null : ValueKey('card:${p.id}'),
          project: p,
          installedVersions: installed,
          categories: surfaceCategories,
          gitStatus: status,
          gitLoading: git.loading && status == null,
          launchWithConsole: settings.launchWithConsole,
          activeTag: _tagFilter,
          selected: _selected.contains(p.id),
          callbacks: callbacksFor(p),
        );
      }
      return ProjectTile(
        key: preview ? null : ValueKey('tile:${p.id}'),
        project: p,
        installedVersions: installed,
        categories: surfaceCategories,
        gitStatus: status,
        gitLoading: git.loading && status == null,
        launchWithConsole: settings.launchWithConsole,
        compact: _viewMode == ProjectViewMode.kanban && widget.gitSidebarOpen,
        activeTag: _tagFilter,
        selected: _selected.contains(p.id),
        viewMode: _viewMode,
        preview: preview,
        callbacks: preview ? ProjectCallbacks.preview : callbacksFor(p),
      );
    }

    final reorder = dragEnabled
        ? (List<String> ids) async {
            if (!categoriesSorted) _setSortBy(ProjectSortOption.manual);
            await _projects.reorder(ids);
          }
        : null;
    final reorderPinned = dragEnabled ? (List<String> ids) => _projects.reorder(ids) : null;
    Future<void> move(List<String> ids, String category, List<String> dest) async {
      _setSortBy(settings.categoriesEnabled ? ProjectSortOption.categories : ProjectSortOption.manual);
      await _projects.moveProjects(ids, category, dest);
    }

    void openCategoryMenu(Offset position, Category category) => setState(() {
      _categoryMenu = (position: position, category: category);
      _categoryMenuVisible = true;
    });

    final contentPadding = EdgeInsetsDirectional.only(
      start: theme.space(widget.connected ? 5 : 2),
      end: theme.space(5),
      bottom: theme.space(4),
    );

    Widget host(List<Widget> slivers) => GhOverlayScrollArea(
      controller: _scroll.controller,
      hideThumb: !settings.showScrollbars,
      scrollToTopOn: '${_tagFilter ?? ''}-${_categoryFilter ?? ''}',
      slivers: [
        SliverPadding(
          padding: contentPadding,
          sliver: SliverMainAxisGroup(slivers: slivers),
        ),
      ],
    );

    Widget body;
    if (projectsState.error != null && projects.isEmpty) {
      body = Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: theme.space(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: theme.space(3),
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: theme.rem(24)),
                child: Text(
                  tr.common.projects_load_error,
                  textAlign: TextAlign.center,
                  style: theme.text(size: GhTextSize.sm, color: theme.muted),
                ),
              ),
              _AccentButton(label: tr.common.retry, onPressed: () => _projects.refresh().ignore()),
            ],
          ),
        ),
      );
    } else if (_viewMode == ProjectViewMode.kanban) {
      body = Padding(
        padding: contentPadding,
        child: ProjectCardKanban(
          projects: filtered,
          categories: surfaceCategories,
          cardBuilder: cardBuilder,
          selectedIds: _selected,
          compact: widget.gitSidebarOpen,
          onReorder: dragEnabled
              ? (ids) async {
                  _setSortBy(settings.categoriesEnabled ? ProjectSortOption.categories : ProjectSortOption.manual);
                  await _projects.reorder(ids);
                }
              : null,
          onMoveProjects: dragEnabled && settings.categoriesEnabled ? move : null,
          hiddenCategories: hiddenEntries,
          onUnhideCategory: (id) => ref.read(categoriesProvider.notifier).setHidden(id, false).ignore(),
          onCategoryContextMenu: openCategoryMenu,
        ),
      );
    } else if (_viewMode == ProjectViewMode.grid) {
      body = ProjectCardGrid(
        projects: filtered,
        cardBuilder: cardBuilder,
        host: host,
        selectedIds: _selected,
        searchActive: parsed.active,
        categories: surfaceCategories,
        categoriesEnabled: groupingEnabled,
        onReorder: reorder,
        onReorderPinned: reorderPinned,
        onMoveProjects: dragEnabled && categoriesSorted ? move : null,
        hiddenCategories: hiddenEntries,
        onUnhideCategory: (id) => ref.read(categoriesProvider.notifier).setHidden(id, false).ignore(),
        onCategoryContextMenu: openCategoryMenu,
      );
    } else {
      body = ProjectCardList(
        projects: filtered,
        cardBuilder: cardBuilder,
        host: host,
        selectedIds: _selected,
        hasActiveFilters: hasActiveFilters,
        searchActive: parsed.active,
        categories: surfaceCategories,
        categoriesEnabled: groupingEnabled,
        onReorder: reorder,
        onReorderPinned: reorderPinned,
        onMoveProjects: dragEnabled && categoriesSorted ? move : null,
        hiddenCategories: hiddenEntries,
        onUnhideCategory: (id) => ref.read(categoriesProvider.notifier).setHidden(id, false).ignore(),
        onCategoryContextMenu: openCategoryMenu,
      );
    }
    final insets = GhViewInsets.of(context);
    body = Padding(
      padding: EdgeInsetsDirectional.only(
        start: insets.start >= theme.space(2) ? insets.start - theme.space(2) : insets.start,
        end: insets.end >= theme.space(4) ? insets.end - theme.space(4) : insets.end,
        bottom: insets.bottom >= theme.space(4) ? insets.bottom - theme.space(4) : insets.bottom,
      ),
      child: body,
    );

    final categoryMenu = _categoryMenu;
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.only(start: insets.start, end: insets.end),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: theme.space(2),
                children: [
                  GhViewHeader(
                    connected: widget.connected,
                    title: tr.nav.projects,
                    leadingAction: _NewPillButton(
                      label: tr.common.kNew,
                      semanticLabel: tr.common.new_project,
                      onPressed: () => AppSignals.emit(newProjectRequestSignal),
                    ),
                    metric: [
                      DefaultTextStyle.merge(
                        style: theme.text(size: GhTextSize.x4l, weight: GhWeight.bold, color: theme.muted),
                        child: GhAnimatedNumber(filtered.length),
                      ),
                      Text(
                        ghTr('nav:projects_count', count: filtered.length).toUpperCase(),
                        style: theme.text(size: GhTextSize.lg, weight: GhWeight.medium, color: theme.muted),
                      ),
                    ],
                    actions: [
                      GhImportButton(
                        key: _import,
                        onImport: (folder) async {
                          await ProjectsApi.import(folder, '');
                          await _projects.refresh();
                        },
                        options: [
                          GhMenuItem(
                            id: 'clone-repo',
                            label: tr.common.clone_import_repo,
                            icon: GhIcons.gitBranch,
                            onSelected: () => showProjectModalPlaceholder(context, 'clone_import_repo', GhIcons.gitBranch),
                          ),
                        ],
                      ),
                      GhScanButton(
                        onOpenSettings: widget.onOpenSettings,
                        scanDirs: settings.projectScanDirs,
                        scan: () async => (await Api.scanForProjectsWithInfo(settings.projectScanDirs, settings.scanDepth)).foundDismissed,
                        onComplete: () => _projects.refresh().ignore(),
                        onReadd: (paths) => Api.reintroduceDismissedProjects(paths).then((_) => _projects.refresh()),
                      ),
                      if (settings.categoriesEnabled)
                        GhTooltip(
                          message: tr.common.manage_categories,
                          side: GhSide.bottom,
                          child: _SquareToolButton(icon: GhIcons.tags, label: tr.common.manage_categories, onPressed: _openCategoryManager),
                        ),
                    ],
                    child: GhSearchBar(
                      value: _search.text,
                      controller: _search,
                      focusNode: _searchNode,
                      onChanged: (_) => setState(() {
                        _menuDismissed = false;
                        _menuIndex = 0;
                      }),
                      onCaretChange: (caret) => setState(() => _caret = caret),
                      onBlur: () => setState(() => _menuDismissed = true),
                      onKeyEvent: (node, event) => _onSearchKey(menu, event),
                      overlay: menu == null
                          ? null
                          : GhSlashMenu(
                              title: menu.title,
                              footer: menu.footer,
                              items: menu.items,
                              selectedIndex: menu.items.isEmpty ? 0 : _menuIndex.clamp(0, menu.items.length - 1),
                              emptyLabel: menu.emptyLabel,
                              onSelect: (item, _) => _applySlashItem(menu, item),
                              onHighlight: (index) => setState(() => _menuIndex = index),
                            ),
                    ),
                  ),
                  _toolbar(context, theme, settings, effectiveSort, visibleCategories),
                  GhDisclosure(
                    open: _selected.isNotEmpty,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: theme.space(3)),
                      child: _selectionBar(context, theme, shownSelection, allVisibleSelected, filtered),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
        if (categoryMenu != null)
          GhContextMenu(
            key: ValueKey(categoryMenu.category.id),
            label: categoryMenu.category.name,
            position: categoryMenu.position,
            compact: true,
            visible: _categoryMenuVisible,
            onClose: () => setState(() => _categoryMenuVisible = false),
            onExited: () => setState(() => _categoryMenu = null),
            items: [
              GhMenuItem(
                id: 'hide-category',
                label: tr.common.hide_category,
                icon: GhIcons.eyeSlash,
                onSelected: () => _hideCategory(categoryMenu.category).ignore(),
              ),
            ],
          ),
      ],
    );
  }

  List<Project> _visualOrder(List<Project> filtered, bool grouping, List<Category> visible, List<Category> surface) {
    if (_viewMode == ProjectViewMode.kanban) return kanbanColumnOrder(filtered, surface);
    if (!grouping) return filtered;
    final pinned = [
      for (final p in filtered)
        if (p.pinned) p,
    ];
    final groups = <String, List<Project>>{};
    for (final p in filtered) {
      if (p.pinned) continue;
      final key = (p.category == null || p.category!.isEmpty) ? uncategorizedKey : p.category!;
      groups.putIfAbsent(key, () => []).add(p);
    }
    return [...pinned, for (final c in visible) ...groups[c.name] ?? const <Project>[], ...groups[uncategorizedKey] ?? const <Project>[]];
  }

  Widget _toolbar(BuildContext context, GhTheme theme, AppSettings settings, ProjectSortOption effectiveSort, List<Category> visible) {
    final tr = context.tr.common;
    final defaultSort = settings.categoriesEnabled ? ProjectSortOption.categories : ProjectSortOption.manual;
    return Padding(
      padding: EdgeInsetsDirectional.only(start: widget.connected ? theme.space(5) : 0, bottom: theme.space(3)),
      child: Row(
        spacing: theme.space(2),
        children: [
          GhDropdown(
            align: GhSide.left,
            items: [
              for (final option in ProjectSortOption.values)
                if (option != ProjectSortOption.categories || settings.categoriesEnabled)
                  GhMenuItem(
                    id: option.value,
                    label: option.label(context.tr),
                    active: option == effectiveSort,
                    onSelected: () => _setSortBy(option),
                  ),
            ],
            trigger: (context, open, toggle) => _FilterButton(
              icon: GhIcons.arrowUpDown,
              label: tr.sort,
              value: effectiveSort.label(context.tr),
              highlighted: effectiveSort != defaultSort,
              open: open,
              onPressed: toggle,
            ),
          ),
          if (settings.categoriesEnabled)
            GhDropdown(
              align: GhSide.left,
              items: [
                GhMenuItem(
                  id: 'filter-all',
                  label: tr.no_filter,
                  active: _categoryFilter == null,
                  onSelected: () => _setCategoryFilter(null),
                ),
                GhMenuItem(
                  id: 'filter-uncategorized',
                  label: tr.uncategorized,
                  active: _categoryFilter == '',
                  dotColor: uncategorizedDot,
                  onSelected: () => _setCategoryFilter(''),
                ),
                for (final c in visible)
                  GhMenuItem(
                    id: 'filter-${c.id}',
                    label: c.name,
                    active: _categoryFilter == c.name,
                    dotColor: colorFromHex(c.color),
                    onSelected: () => _setCategoryFilter(c.name),
                  ),
              ],
              trigger: (context, open, toggle) => _FilterButton(
                icon: GhIcons.filter,
                label: tr.filter,
                value: _categoryFilter == null ? null : (_categoryFilter!.isEmpty ? tr.uncategorized : _categoryFilter),
                highlighted: _categoryFilter != null,
                open: open,
                onPressed: toggle,
              ),
            ),
          if (_tagFilter != null) _TagFilterChip(tag: _tagFilter!, tooltip: tr.clear_tag_filter, onPressed: () => _setTagFilter(null)),
          if (settings.customizeViewEnabled) ...[
            const Spacer(),
            GhDropdown(
              align: GhSide.right,
              compact: true,
              content: (context, close) => _cardSettings(context, theme, settings),
              trigger: (context, open, toggle) => _OutlineToolButton(
                onPressed: toggle,
                open: open,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: theme.space(1.5),
                  children: [
                    Text(
                      tr.customize_card_section,
                      style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium),
                    ),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: GhMotion.of(context).css(const Duration(milliseconds: 500)),
                      curve: GhCurves.spring,
                      child: GhIcon(GhIcons.chevronDown, size: theme.space(2.5)),
                    ),
                  ],
                ),
              ),
            ),
            GhDropdown(
              align: GhSide.right,
              compact: true,
              items: [
                for (final (mode, icon, label) in [
                  (ProjectViewMode.list, GhIcons.layoutList, tr.view_list),
                  (ProjectViewMode.grid, GhIcons.layoutGrid, tr.view_grid),
                  (ProjectViewMode.kanban, GhIcons.kanban, tr.view_kanban),
                ])
                  GhMenuItem(id: mode.id, label: label, icon: icon, active: _viewMode == mode, onSelected: () => _setViewMode(mode)),
              ],
              trigger: (context, open, toggle) {
                final (icon, label) = switch (_viewMode) {
                  ProjectViewMode.grid => (GhIcons.layoutGrid, tr.view_grid),
                  ProjectViewMode.kanban => (GhIcons.kanban, tr.view_kanban),
                  ProjectViewMode.list => (GhIcons.layoutList, tr.view_list),
                };
                return GhTooltip(
                  message: label,
                  child: _OutlineToolButton(
                    onPressed: toggle,
                    open: open,
                    square: true,
                    semanticLabel: label,
                    child: GhIcon(icon, size: theme.space(3.5)),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _cardSettings(BuildContext context, GhTheme theme, AppSettings settings) {
    final options = getCardViewSettings(settings, _viewMode);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(0.5),
      children: [
        for (final (key, icon, labelKey) in _cardToggles)
          Builder(
            builder: (context) {
              final disabled = key == CardViewKey.blurPath && !options.showPath;
              final label = ghTr(labelKey);
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(1.5)),
                child: Row(
                  spacing: theme.space(2.5),
                  children: [
                    Opacity(
                      opacity: disabled ? 0.5 : 1,
                      child: GhIcon(icon, size: theme.space(3.5), color: theme.muted.withValues(alpha: 0.7)),
                    ),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.text(
                          size: GhTextSize.xs,
                          weight: GhWeight.medium,
                          color: disabled ? theme.muted.withValues(alpha: 0.5) : theme.ink,
                        ),
                      ),
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final current = ref.watch(settingsProvider).value ?? settings;
                        final checked = key.of(getCardViewSettings(current, _viewMode));
                        final blurDisabled = key == CardViewKey.blurPath && !getCardViewSettings(current, _viewMode).showPath;
                        return GhToggle(
                          checked: checked,
                          disabled: blurDisabled,
                          label: label,
                          onChanged: (value) =>
                              ref.read(settingsProvider.notifier).save(setCardViewOverride(current, _viewMode, key, value)).ignore(),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _selectionBar(BuildContext context, GhTheme theme, int count, bool allSelected, List<Project> filtered) {
    final tr = context.tr.common;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
      decoration: BoxDecoration(
        color: theme.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: theme.accentDim.withValues(alpha: 0.4)),
      ),
      child: Row(
        spacing: theme.space(2),
        children: [
          GhTooltip(
            message: tr.select_all_visible,
            side: GhSide.bottom,
            child: GhPressable(
              onPressed: () => setState(() {
                final next = {..._selected};
                if (allSelected) {
                  for (final p in filtered) {
                    next.remove(p.id);
                  }
                } else {
                  for (final p in filtered) {
                    next.add(p.id);
                  }
                }
                _selected = next;
              }),
              semanticLabel: tr.select_all_visible,
              checked: allSelected,
              borderRadius: BorderRadius.circular(theme.radiusItem),
              builder: (context, states) => GhAnimatedBox(
                width: theme.space(5),
                height: theme.space(5),
                alignment: Alignment.center,
                color: allSelected ? theme.accent : null,
                borderRadius: BorderRadius.circular(theme.radiusItem),
                border: Border.all(
                  width: 2,
                  color: allSelected
                      ? theme.accent
                      : (states.active ? theme.accent.withValues(alpha: 0.6) : theme.muted.withValues(alpha: 0.4)),
                ),
                child: GhIcon(GhIcons.check, size: theme.space(3), color: allSelected ? Colors.white : Colors.transparent),
              ),
            ),
          ),
          Text(
            ghTr('selected_count', count: count),
            style: theme
                .text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.ink)
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          const Spacer(),
          _BatchButton(icon: GhIcons.play, label: tr.bulk_launch, style: _BatchStyle.accent, onPressed: _batchLaunch),
          _BatchButton(icon: GhIcons.pin, label: tr.bulk_pin, onPressed: _batchPin),
          _BatchButton(icon: GhIcons.tags, label: tr.bulk_tags, onPressed: () => _openBulkTags().ignore()),
          _BatchButton(icon: GhIcons.x, label: tr.bulk_remove, onPressed: () => _confirmBatch(delete: false).ignore()),
          _BatchButton(
            icon: GhIcons.trash,
            label: tr.delete,
            style: _BatchStyle.danger,
            onPressed: () => _confirmBatch(delete: true).ignore(),
          ),
          GhTooltip(
            message: tr.clear_selection,
            side: GhSide.bottom,
            child: GhPressable(
              onPressed: _clearSelection,
              semanticLabel: tr.clear_selection,
              borderRadius: BorderRadius.circular(theme.radiusBtn),
              builder: (context, states) => GhAnimatedBox(
                width: theme.space(8),
                height: theme.space(8),
                alignment: Alignment.center,
                color: states.active ? theme.overlay : theme.overlay.withValues(alpha: 0),
                borderRadius: BorderRadius.circular(theme.radiusBtn),
                child: GhIcon(GhIcons.x, size: theme.space(3.5), color: states.active ? theme.ink : theme.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _BatchStyle { neutral, accent, danger }

class _BatchButton extends StatelessWidget {
  const _BatchButton({required this.icon, required this.label, required this.onPressed, this.style = _BatchStyle.neutral});

  final FaIconData icon;
  final String label;
  final VoidCallback onPressed;
  final _BatchStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      builder: (context, states) {
        final hover = states.active;
        final (background, foreground) = switch (style) {
          _BatchStyle.accent => (hover ? theme.accentBright : theme.accent, theme.ink),
          _BatchStyle.danger => (theme.danger.withValues(alpha: hover ? 0.2 : 0.1), theme.danger),
          _BatchStyle.neutral => (hover ? theme.overlay : theme.raised, hover ? theme.ink : theme.muted),
        };
        return GhAnimatedBox(
          height: theme.space(8),
          padding: EdgeInsets.symmetric(horizontal: theme.space(3)),
          color: background,
          borderRadius: radius,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: theme.space(1.5),
            children: [
              GhIcon(icon, size: theme.space(3), color: foreground),
              Text(
                label,
                style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: foreground),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.icon,
    required this.label,
    required this.highlighted,
    required this.open,
    required this.onPressed,
    this.value,
  });

  final FaIconData icon;
  final String label;
  final String? value;
  final bool highlighted;
  final bool open;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      onPressed: onPressed,
      expanded: open,
      borderRadius: radius,
      builder: (context, states) {
        final hover = states.active;
        final background = highlighted ? theme.accent.withValues(alpha: 0.15) : (hover ? theme.raised : theme.overlay);
        final iconColor = highlighted ? theme.accentBright : (hover ? theme.ink : theme.muted);
        return GhAnimatedBox(
          height: theme.space(8),
          padding: EdgeInsets.symmetric(horizontal: theme.space(4)),
          color: background,
          borderRadius: radius,
          border: highlighted ? Border.all(color: theme.accentDim.withValues(alpha: 0.7)) : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: theme.space(1),
            children: [
              GhIcon(icon, size: theme.space(3), color: iconColor),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                spacing: theme.space(1),
                children: [
                  Text(
                    label,
                    style: theme.text(size: GhTextSize.base, weight: GhWeight.medium, color: theme.ink),
                  ),
                  if (value != null)
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: theme.space(30)),
                      child: Text(
                        value!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme
                            .text(size: GhTextSize.xs, color: theme.muted)
                            .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TagFilterChip extends StatelessWidget {
  const _TagFilterChip({required this.tag, required this.tooltip, required this.onPressed});

  final String tag;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      onPressed: onPressed,
      tooltip: tooltip,
      borderRadius: radius,
      builder: (context, states) => GhAnimatedBox(
        height: theme.space(8),
        padding: EdgeInsets.symmetric(horizontal: theme.space(3)),
        color: theme.accent.withValues(alpha: states.active ? 0.25 : 0.15),
        borderRadius: radius,
        border: Border.all(color: theme.accentDim.withValues(alpha: 0.7)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: theme.space(1.5),
          children: [
            Container(
              width: theme.space(1.5),
              height: theme.space(1.5),
              decoration: BoxDecoration(color: colorFromHex(tagColor(tag)), shape: BoxShape.circle),
            ),
            Text(
              tag,
              style: theme.text(size: GhTextSize.base, weight: GhWeight.medium, color: theme.accentBright),
            ),
            GhIcon(GhIcons.x, size: theme.space(3), color: theme.accentBright),
          ],
        ),
      ),
    );
  }
}

class _OutlineToolButton extends StatelessWidget {
  const _OutlineToolButton({required this.onPressed, required this.open, required this.child, this.square = false, this.semanticLabel});

  final VoidCallback onPressed;
  final bool open;
  final bool square;
  final String? semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      onPressed: onPressed,
      expanded: open,
      semanticLabel: semanticLabel,
      borderRadius: radius,
      builder: (context, states) {
        final hover = states.active;
        return GhAnimatedBox(
          width: square ? theme.space(8) : null,
          height: theme.space(8),
          padding: square ? null : EdgeInsets.symmetric(horizontal: theme.space(4)),
          alignment: Alignment.center,
          color: hover ? theme.raised : theme.overlay,
          borderRadius: radius,
          border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
          child: IconTheme.merge(
            data: IconThemeData(color: hover ? theme.ink : theme.muted),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: hover ? theme.ink : theme.muted),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _SquareToolButton extends StatelessWidget {
  const _SquareToolButton({required this.icon, required this.label, required this.onPressed});

  final FaIconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      onPressed: onPressed,
      semanticLabel: label,
      borderRadius: radius,
      builder: (context, states) => GhToolButtonFace(
        states: states,
        width: theme.space(10),
        borderRadius: radius,
        child: GhIcon(icon, size: theme.space(4), color: states.active ? theme.ink : theme.muted),
      ),
    );
  }
}

class _AccentButton extends StatelessWidget {
  const _AccentButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      builder: (context, states) => GhAnimatedBox(
        color: states.active ? theme.accentBright : theme.accent,
        borderRadius: radius,
        padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(2)),
        child: Text(
          label,
          style: theme.text(size: GhTextSize.sm, color: theme.ink),
        ),
      ),
    );
  }
}

class _NewPillButton extends StatefulWidget {
  const _NewPillButton({required this.label, required this.semanticLabel, required this.onPressed});

  final String label;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  State<_NewPillButton> createState() => _NewPillButtonState();
}

class _NewPillButtonState extends State<_NewPillButton> {
  final GlobalKey<GhSpinState> _spin = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final motion = GhMotion.of(context);
    final duration = motion.css(const Duration(milliseconds: 500));
    return GhPressable(
      onPressed: () {
        _spin.currentState?.spin();
        widget.onPressed();
      },
      semanticLabel: widget.semanticLabel,
      borderRadius: BorderRadius.circular(9999),
      builder: (context, states) {
        final hover = states.active;
        return GhAnimatedBox(
          height: theme.space(9),
          constraints: BoxConstraints(minWidth: theme.space(9)),
          padding: EdgeInsetsDirectional.only(start: theme.space(2)),
          color: hover ? theme.accentBright : theme.accent,
          borderRadius: BorderRadius.circular(9999),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GhSpin(
                key: _spin,
                child: AnimatedRotation(
                  turns: hover ? 0.25 : 0,
                  duration: duration,
                  curve: GhCurves.spring,
                  child: GhIcon(GhIcons.plus, size: theme.space(5), color: theme.ink),
                ),
              ),
              ClipRect(
                child: AnimatedAlign(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: hover ? 1 : 0,
                  duration: duration,
                  curve: GhCurves.outExpo,
                  child: AnimatedOpacity(
                    opacity: hover ? 1 : 0,
                    duration: duration,
                    curve: GhCurves.outExpo,
                    child: AnimatedSlide(
                      offset: hover ? Offset.zero : const Offset(-0.15, 0),
                      duration: duration,
                      curve: GhCurves.outExpo,
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(start: theme.space(1), end: theme.space(3)),
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          softWrap: false,
                          style: theme.text(size: GhTextSize.sm, weight: GhWeight.semibold, color: theme.ink),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
