import 'dart:async';

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/projects.dart';
import '../design/design.dart';
import '../logic/card_view_settings.dart';
import '../logic/duration.dart';
import '../logic/last_opened.dart';
import '../logic/open_todos.dart';
import '../logic/project_sort.dart';
import '../motion/motion.dart';
import '../motion/shared_ticker.dart';
import '../src/rust/api/types.dart';
import '../state/open_todos_sync.dart';
import '../state/project_tile_data.dart';
import '../state/projects.dart' show copyProject;
import '../state/settings.dart';
import '../ui/controls/dashed_box.dart';
import '../ui/controls/equal_height_row.dart';
import '../ui/controls/spin.dart';
import '../ui/controls/text_input.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/core/tooltip.dart';
import '../ui/core/ui_settings.dart' show GhSide;
import '../ui/overlays/dropdown.dart';
import '../ui/overlays/menu.dart';
import '../ui/reusables/open_button.dart';
import '../state/app_signals.dart';
import '../state/shell_signals.dart';
import '../todos/project_todo_panel.dart';
import 'project_actions.dart';
import 'project_icon.dart';
import 'project_tile.dart' show formatProjectSize;

class ProjectCard extends ConsumerStatefulWidget {
  const ProjectCard({
    super.key,
    required this.project,
    required this.installedVersions,
    required this.callbacks,
    this.categories = const [],
    this.gitStatus,
    this.gitLoading = false,
    this.launchWithConsole = false,
    this.activeTag,
    this.selected = false,
    this.viewMode = ProjectViewMode.list,
    this.saveTags,
  });

  final Project project;
  final List<InstalledGodotVersion> installedVersions;
  final ProjectCallbacks callbacks;
  final List<Category> categories;
  final GitStatus? gitStatus;
  final bool gitLoading;
  final bool launchWithConsole;
  final String? activeTag;
  final bool selected;
  final ProjectViewMode viewMode;
  final Future<Project> Function(String id, String path, List<String> tags)? saveTags;

  @override
  ConsumerState<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends ConsumerState<ProjectCard> {
  bool _hovered = false;
  bool _focusWithin = false;
  bool _cover = false;
  bool _tagsExpanded = false;
  int? _editingTag;
  bool _addingTag = false;
  bool _savingTags = false;
  String? _tagError;
  String? _brokenIcon;
  final TextEditingController _editTag = TextEditingController();
  final TextEditingController _newTag = TextEditingController();
  final FocusNode _editNode = FocusNode(debugLabel: 'ProjectCard tag edit');
  final FocusNode _addNode = FocusNode(debugLabel: 'ProjectCard tag add');
  StreamSubscription<AppSignal>? _todoSignal;
  bool _showTodos = false;
  bool _todosLoaded = false;

  bool get _todosEnabled => ref.read(settingsProvider).value?.projectTodosEnabled ?? false;

  @override
  void initState() {
    super.initState();
    _todoSignal = AppSignals.on(showProjectTodosSignal).listen((signal) {
      if (signal.detail == widget.project.id) _focusTodos();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusTodos());
  }

  void _focusTodos() {
    if (!mounted || !_todosEnabled || !consumeTodoFocus(widget.project.id)) return;
    setState(() => _showTodos = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Scrollable.ensureVisible(context, alignment: 0.5).ignore();
    });
  }

  void _toggleTodos({bool resetLoaded = true}) => setState(() {
    if (resetLoaded) _todosLoaded = false;
    _showTodos = !_showTodos;
  });

  @override
  void dispose() {
    _todoSignal?.cancel();
    _editTag.dispose();
    _newTag.dispose();
    _editNode.dispose();
    _addNode.dispose();
    super.dispose();
  }

  Project get _project => widget.project;

  InstalledGodotVersion? get _version {
    for (final v in widget.installedVersions) {
      if (v.tag == _project.godotVersion) return v;
    }
    return null;
  }

  Future<void> _saveTags(List<String> tags) async {
    setState(() => _savingTags = true);
    try {
      await (widget.saveTags ?? ProjectsApi.saveTags)(_project.id, _project.path, tags);
      widget.callbacks.onTagsSaved?.call(copyProject(_project, tags: tags));
    } catch (e) {
      debugPrint('Failed to save tags: $e');
    } finally {
      if (mounted) setState(() => _savingTags = false);
    }
  }

  void _startAdd() {
    setState(() {
      _addingTag = true;
      _tagError = null;
    });
    _newTag.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _addNode.requestFocus();
    });
  }

  void _cancelAdd() => setState(() {
    _addingTag = false;
    _newTag.clear();
    _tagError = null;
  });

  void _handleAddTag() {
    final trimmed = _newTag.text.trim();
    if (trimmed.isEmpty || _savingTags) return;
    if (_project.tags.any((t) => t.toLowerCase() == trimmed.toLowerCase())) {
      setState(() => _tagError = context.tr.common.tag_already_exists);
      _addNode.requestFocus();
      return;
    }
    final next = [..._project.tags, trimmed];
    setState(() {
      _addingTag = false;
      _tagError = null;
    });
    _newTag.clear();
    _saveTags(next);
  }

  void _onAddBlur() {
    if (!_addingTag) return;
    if (_newTag.text.trim().isNotEmpty) {
      _handleAddTag();
    } else {
      setState(() {
        _addingTag = false;
        _tagError = null;
      });
    }
  }

  void _removeTag(int index) {
    if (_savingTags) return;
    final next = [
      for (var i = 0; i < _project.tags.length; i++)
        if (i != index) _project.tags[i],
    ];
    setState(() {
      if (_editingTag == index) {
        _editingTag = null;
        _editTag.clear();
      }
      _tagError = null;
    });
    _saveTags(next);
  }

  void _startRename(int index) {
    setState(() {
      _editingTag = index;
      _tagError = null;
    });
    _editTag.text = _project.tags[index];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _editNode.requestFocus();
    });
  }

  void _cancelRename() => setState(() {
    _editingTag = null;
    _editTag.clear();
    _tagError = null;
  });

  void _handleRename(int index) {
    if (_editingTag != index) return;
    final trimmed = _editTag.text.trim();
    final current = _project.tags[index];
    if (trimmed.isEmpty || trimmed == current || _savingTags) {
      _cancelRename();
      return;
    }
    if (_project.tags.asMap().entries.any((e) => e.key != index && e.value.toLowerCase() == trimmed.toLowerCase())) {
      setState(() => _tagError = context.tr.common.tag_already_exists);
      _editNode.requestFocus();
      return;
    }
    final next = [for (var i = 0; i < _project.tags.length; i++) i == index ? trimmed : _project.tags[i]];
    setState(() {
      _editingTag = null;
      _tagError = null;
    });
    _editTag.clear();
    _saveTags(next);
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!mounted) return;
    if (ghHitsControl(event.position, event.viewId, context.findRenderObject())) return;
    final modifiers = SelectModifiers.current();
    if (modifiers.any) {
      widget.callbacks.onToggleSelect?.call(modifiers);
      return;
    }
    if (_todosEnabled) _toggleTodos();
  }

  Widget _hoverIcon(FaIconData icon, double size, Color color) {
    final duration = GhMotion.of(context).css(const Duration(milliseconds: 500));
    return AnimatedRotation(
      turns: _hovered ? 6 / 360 : 0,
      duration: duration,
      curve: GhCurves.spring,
      child: AnimatedScale(
        scale: _hovered ? 1.1 : 1,
        duration: duration,
        curve: GhCurves.spring,
        child: GhIcon(icon, size: size, color: color),
      ),
    );
  }

  List<GhMenuItem> _menuItems(BuildContext context, String displayName) {
    final tr = context.tr.common;
    final cb = widget.callbacks;
    final project = _project;
    return [
      GhMenuItem(
        id: 'build-export',
        label: ghTr('build_export.title'),
        icon: GhIcons.rocket,
        onSelected: () => openProjectBuild(context, project),
      ),
      GhMenuItem(
        id: 'project-doctor',
        label: ghTr('project_doctor.title'),
        icon: GhIcons.bug,
        onSelected: () => openProjectDoctor(context, project, widget.installedVersions),
      ),
      GhMenuItem(
        id: 'project-addons',
        label: ghTr('project_addons.title'),
        icon: GhIcons.plug,
        onSelected: () => openProjectAddons(context, project),
      ),
      GhMenuItem(
        id: 'launch-arguments',
        label: tr.launch_arguments,
        icon: GhIcons.rocket,
        onSelected: () => openLaunchArgs(context, project, cb.onLaunchArgsChange),
      ),
      GhMenuItem(
        id: 'manage-tags',
        label: tr.manage_tags,
        icon: GhIcons.tags,
        dividerAfter: cb.onCategoryChange != null,
        onSelected: () => openTagManager(context, project, cb.onTagsSaved),
      ),
      if (cb.onDuplicate != null) GhMenuItem(id: 'duplicate', label: tr.duplicate, icon: GhIcons.copy, onSelected: cb.onDuplicate),
      if (cb.onCategoryChange != null)
        GhMenuItem(
          id: 'set-category',
          label: tr.set_category,
          icon: GhIcons.tags,
          dividerAfter: true,
          children: categoryMenuChildren(context, project, widget.categories, cb.onCategoryChange!),
        ),
      GhMenuItem(
        id: 'save-as-template',
        label: tr.save_as_template,
        icon: GhIcons.copy,
        dividerAfter: true,
        onSelected: () => openSaveAsTemplate(context, project),
      ),
      GhMenuItem(
        id: 'remove',
        label: tr.project_card_remove_library,
        icon: GhIcons.x,
        onSelected: () => confirmRemoveProject(context, displayName, cb.onRemove),
      ),
      GhMenuItem(
        id: 'delete',
        label: tr.project_card_delete_files,
        icon: GhIcons.trash,
        danger: true,
        onSelected: () => confirmDeleteProject(context, displayName, cb.onDelete ?? () {}),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr.common;
    final settings = ref.watch(settingsProvider).value ?? defaultSettings;
    final options = getCardViewSettings(settings, widget.viewMode);
    final todosEnabled = settings.projectTodosEnabled;
    if (todosEnabled) ref.watch(openTodosProvider);
    final counts = todosEnabled ? projectTodoCounts(_project.id, localDateValue()) : noTodos;
    final project = _project;
    final data = ref.watch(projectTileDataProvider((path: project.path, showSize: options.showSize, preview: false)));
    final displayName = data.displayName(project.name);
    final version = _version;
    final versionInstalled = version != null;
    final cb = widget.callbacks;
    final lastOpened = formatLastOpened(
      project.lastOpened,
      timeFormat: LastOpenedTimeFormat.parse(settings.lastOpenedTimeFormat),
      dateFormat: LastOpenedDateFormat.parse(settings.lastOpenedDateFormat),
    );
    final icon = data.icon != null && data.icon != _brokenIcon ? data.icon : null;
    _cover = settings.projectCardStyle == 'cover';
    final reveal = _hovered || _focusWithin;
    final showTodos = todosEnabled && _showTodos;
    final radius = showTodos ? BorderRadius.vertical(top: Radius.circular(theme.radiusItem)) : BorderRadius.circular(theme.radiusItem);
    final motion = GhMotion.of(context);

    final todoBadge = [if (counts.open > 0) _todoBadge(theme, counts)];
    final gitWidgets = [
      if (widget.gitLoading && widget.gitStatus == null)
        Semantics(
          label: tr.git_sidebar,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: theme.space(1.5), vertical: theme.space(0.5)),
            child: GhSpinning(
              child: GhIcon(GhIcons.spinner, size: theme.space(3), color: theme.muted),
            ),
          ),
        ),
      if (widget.gitStatus?.isRepo ?? false) _gitChip(context, theme, widget.gitStatus!),
    ];
    final lastOpenedChip = [
      if (lastOpened != null && options.showLastOpened)
        Padding(
          padding: _cover
              ? EdgeInsets.symmetric(horizontal: theme.space(1))
              : EdgeInsetsDirectional.only(start: theme.space(1.5), end: theme.space(1), top: theme.space(0.5), bottom: theme.space(0.5)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: theme.space(_cover ? 1.5 : 1),
            children: [
              _hoverIcon(GhIcons.clock, theme.space(2.5), theme.muted.withValues(alpha: 0.6)),
              Text(
                lastOpened,
                style: theme.text(size: GhTextSize.x3s, weight: GhWeight.medium, mono: true, color: theme.muted, letterSpacingEm: -0.025),
              ),
            ],
          ),
        ),
    ];
    final addTagControls = [
      if (_addingTag) _addTagInput(context, theme) else _addTagReveal(context, theme, reveal),
      if (_savingTags)
        Semantics(
          label: tr.saving_tags,
          child: SizedBox.square(
            dimension: theme.space(3),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.accentBright,
              backgroundColor: theme.accentDim.withValues(alpha: 0.3),
            ),
          ),
        ),
    ];
    final showTags = project.tags.isNotEmpty && options.showTags;
    final sizeChip = [
      if (options.showSize && (data.size ?? 0) > 0)
        _chipButton(
          context,
          theme,
          icon: GhIcons.hardDrive,
          label: formatProjectSize(data.size!),
          semanticLabel: tr.project_size,
          onPressed: () => openProjectSize(context, project),
        ),
    ];
    final categoryChip = [if (widget.categories.isNotEmpty && cb.onCategoryChange != null) _categoryDropdown(context, theme)];
    final openButton = GhOpenButton(
      label: versionInstalled ? tr.open_project : tr.no_version_selected,
      disabled: !versionInstalled,
      onOpen: (console) => launchProject(project, console),
      consoleSupported: version?.supportsConsole ?? false,
      consoleInitiallyOn: widget.launchWithConsole && (version?.supportsConsole ?? false),
      showConsole: options.showConsole,
      moreLabel: tr.project_more_aria,
      headerItems: projectHeaderItems(context, project, todosEnabled: todosEnabled, onTodos: () => _toggleTodos(resetLoaded: false)),
      items: _menuItems(context, displayName),
    );
    final loadingBar = [
      if (showTodos && !_todosLoaded)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: LinearProgressIndicator(
              minHeight: theme.space(0.5),
              color: theme.accent,
              backgroundColor: theme.accent.withValues(alpha: 0.15),
            ),
          ),
        ),
    ];
    final decoration = BoxDecoration(
      color: widget.selected ? theme.accent.withValues(alpha: 0.05) : (_hovered ? theme.raised : theme.overlay),
      borderRadius: radius,
      border: Border.all(
        color: widget.selected ? theme.accent : (_hovered ? theme.accentDim.withValues(alpha: 0.6) : theme.outline.withValues(alpha: 0.5)),
      ),
      boxShadow: widget.selected ? [BoxShadow(color: theme.accent.withValues(alpha: 0.6), spreadRadius: 1)] : null,
    );

    final Widget card;
    if (_cover) {
      card = AnimatedContainer(
        duration: motion.css(GhDurations.interactive),
        curve: GhCurves.outExpo,
        decoration: decoration,
        child: _coverLayout(
          context,
          theme,
          icon: icon,
          displayName: displayName,
          showTodos: showTodos,
          canPlay: options.showPlay && versionInstalled,
          showSession: options.showSessionTimer,
          loadingBar: loadingBar,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: theme.space(1.5),
            children: [
              Row(
                spacing: theme.space(2),
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.text(size: GhTextSize.x2l, weight: GhWeight.bold, color: theme.ink, letterSpacingEm: -0.025),
                    ),
                  ),
                  ...todoBadge,
                  ...gitWidgets,
                ],
              ),
              if (showTags)
                _tagsRow(context, theme, trailing: addTagControls)
              else
                Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: addTagControls),
              if (options.showPath) _pathButton(context, theme, options.blurPath),
              Container(
                padding: EdgeInsets.only(top: theme.space(2.5)),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: theme.outline.withValues(alpha: 0.5))),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: theme.space(1.5),
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: theme.space(1.5),
                        runSpacing: theme.space(1.5),
                        children: [_versionDropdown(context, theme, version), ...categoryChip],
                      ),
                    ),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: theme.space(1.5),
                      runSpacing: theme.space(1.5),
                      children: [if (options.showTime) ..._timeButton(context, theme), ...sizeChip, ...lastOpenedChip],
                    ),
                  ],
                ),
              ),
            ],
          ),
          rail: openButton,
        ),
      );
    } else {
      final content = LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: theme.space(1.5),
              runSpacing: theme.space(1.5),
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.text(size: GhTextSize.xl, weight: GhWeight.medium, color: theme.ink),
                  ),
                ),
                ...todoBadge,
                ...gitWidgets,
                ...lastOpenedChip,
                ...addTagControls,
              ],
            ),
            if (showTags) _tagsRow(context, theme),
            if (options.showPath) _pathButton(context, theme, options.blurPath),
            Padding(
              padding: EdgeInsets.only(top: theme.space(1.5)),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: theme.space(1.5),
                runSpacing: theme.space(1.5),
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _versionDropdown(context, theme, version),
                      if (project.pinned || reveal)
                        Padding(
                          padding: EdgeInsetsDirectional.only(start: theme.space(1.5)),
                          child: _pinButton(context, theme),
                        ),
                    ],
                  ),
                  if (options.showTime) ..._timeButton(context, theme),
                  ...sizeChip,
                  ...categoryChip,
                ],
              ),
            ),
          ],
        ),
      );

      card = AnimatedContainer(
        duration: motion.css(GhDurations.interactive),
        curve: GhCurves.outExpo,
        padding: EdgeInsets.all(theme.space(3.5)),
        decoration: decoration,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -theme.space(3.5),
              top: -theme.space(3.5),
              right: -theme.space(3.5),
              bottom: -theme.space(3.5),
              child: IgnorePointer(child: _backdrop(theme, icon, displayName)),
            ),
            if (showTodos && !_todosLoaded)
              Positioned(
                left: -theme.space(3.5),
                right: -theme.space(3.5),
                bottom: -theme.space(3.5),
                child: IgnorePointer(
                  child: LinearProgressIndicator(
                    minHeight: theme.space(0.5),
                    color: theme.accent,
                    backgroundColor: theme.accent.withValues(alpha: 0.15),
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: theme.space(3.5),
              children: [
                Expanded(child: content),
                ..._sessionPill(theme, options.showSessionTimer),
                Transform.translate(
                  offset: Offset(Directionality.of(context) == TextDirection.rtl ? -theme.space(2) : theme.space(2), 0),
                  child: GhEqualWidthColumn(
                    spacing: theme.space(1.5),
                    children: [
                      if (options.showPlay)
                        SizedBox(
                          height: theme.space(12),
                          child: versionInstalled
                              ? Visibility(
                                  visible: _hovered,
                                  maintainSize: true,
                                  maintainAnimation: true,
                                  maintainState: true,
                                  child: _playButton(context, theme),
                                )
                              : null,
                        ),
                      openButton,
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final surface = MouseRegion(
      cursor: todosEnabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (value) => setState(() => _focusWithin = value),
        child: Listener(
          onPointerUp: _onPointerUp,
          child: Semantics(container: true, child: card),
        ),
      ),
    );
    if (!showTodos) return surface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        surface,
        ProjectTodoPanel(
          projectId: project.id,
          onLoaded: () {
            if (mounted && !_todosLoaded) setState(() => _todosLoaded = true);
          },
          onClose: () => setState(() {
            _todosLoaded = false;
            _showTodos = false;
          }),
        ),
      ],
    );
  }

  // Cover: the project icon is the card's cover art. It fills a full-height
  // square on the start edge, and the cover itself is the play surface, the
  // pin, and the live session stamp.
  Widget _coverLayout(
    BuildContext context,
    GhTheme theme, {
    required String? icon,
    required String displayName,
    required bool showTodos,
    required bool canPlay,
    required bool showSession,
    required List<Widget> loadingBar,
    required Widget body,
    required Widget rail,
  }) {
    final coverWidth = theme.space(36);
    final direction = Directionality.of(context);
    final corner = Radius.circular(theme.radiusItem);
    final coverRadius = BorderRadiusDirectional.only(topStart: corner, bottomStart: showTodos ? Radius.zero : corner).resolve(direction);
    return Stack(
      children: [
        PositionedDirectional(
          start: 0,
          top: 0,
          bottom: 0,
          width: coverWidth,
          child: ClipRRect(
            borderRadius: coverRadius,
            child: _coverArt(context, theme, icon: icon, displayName: displayName, canPlay: canPlay, showSession: showSession),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: coverWidth),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(width: coverWidth),
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(start: theme.space(4), top: theme.space(3.5), bottom: theme.space(3.5)),
                  child: body,
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: theme.space(3),
                  end: theme.space(3.5),
                  top: theme.space(3.5),
                  bottom: theme.space(3.5),
                ),
                child: rail,
              ),
            ],
          ),
        ),
        ...loadingBar,
      ],
    );
  }

  Widget _coverArt(
    BuildContext context,
    GhTheme theme, {
    required String? icon,
    required String displayName,
    required bool canPlay,
    required bool showSession,
  }) {
    final tr = context.tr.common;
    final motion = GhMotion.of(context);
    final slow = motion.css(const Duration(milliseconds: 500));
    final pinned = _project.pinned;
    final started = _project.sessionStartedAtMs?.toInt();
    return Stack(
      fit: StackFit.expand,
      children: [
        if (icon != null) ...[
          ColoredBox(color: theme.base),
          IgnorePointer(
            child: AnimatedScale(
              scale: _hovered ? 1.05 : 1,
              duration: slow,
              curve: GhCurves.outExpo,
              child: ProjectIconImage(url: icon, fit: BoxFit.cover, onError: () => setState(() => _brokenIcon = icon)),
            ),
          ),
        ] else ...[
          ColoredBox(color: theme.accent.withValues(alpha: 0.15)),
          IgnorePointer(
            child: Center(
              child: AnimatedScale(
                scale: _hovered ? 1.05 : 1,
                duration: slow,
                curve: GhCurves.outExpo,
                child: Text(
                  projectInitials(displayName),
                  style: theme
                      .text(weight: FontWeight.w900, color: theme.accentBright.withValues(alpha: 0.7), lineHeight: 1)
                      .copyWith(fontSize: 48),
                ),
              ),
            ),
          ),
        ],
        PositionedDirectional(end: 0, top: 0, bottom: 0, width: 1, child: ColoredBox(color: Colors.white.withValues(alpha: 0.1))),
        if (canPlay)
          GhTooltip(
            message: tr.play_project_tooltip,
            side: GhSide.top,
            child: GhPressable(
              onPressed: () => playProject(_project),
              semanticLabel: tr.play_project,
              builder: (context, states) => AnimatedOpacity(
                opacity: states.highlighted ? 1 : 0,
                duration: motion.css(const Duration(milliseconds: 300)),
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.55),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: theme.space(1.5),
                      children: [
                        Container(
                          width: theme.space(11),
                          height: theme.space(11),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            shape: BoxShape.circle,
                            boxShadow: GhShadows.md(Colors.black.withValues(alpha: 0.3)),
                          ),
                          child: Center(
                            child: GhIcon(GhIcons.play, size: theme.space(4), color: Colors.black),
                          ),
                        ),
                        Text(
                          tr.play_project.toUpperCase(),
                          style: theme.text(
                            size: GhTextSize.x3s,
                            weight: GhWeight.semibold,
                            mono: true,
                            color: Colors.white,
                            letterSpacingEm: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        PositionedDirectional(
          top: theme.space(2),
          start: theme.space(2),
          child: AnimatedOpacity(
            opacity: pinned || _hovered || _focusWithin ? 1 : 0,
            duration: motion.css(GhDurations.interactive),
            child: GhTooltip(
              message: pinned ? tr.project_unpin_aria : tr.project_pin_aria,
              side: GhSide.top,
              child: GhPressable(
                onPressed: widget.callbacks.onTogglePin,
                semanticLabel: pinned ? tr.project_unpin_aria : tr.project_pin_aria,
                toggled: pinned,
                borderRadius: BorderRadius.circular(9999),
                builder: (context, states) => GhAnimatedBox(
                  width: theme.space(7),
                  height: theme.space(7),
                  alignment: Alignment.center,
                  color: pinned ? theme.accent : Colors.black.withValues(alpha: states.active ? 0.7 : 0.55),
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: pinned ? GhShadows.md(Colors.black.withValues(alpha: 0.3)) : null,
                  child: GhIcon(
                    GhIcons.pin,
                    size: theme.space(3),
                    color: Colors.white.withValues(alpha: pinned || states.active ? 1 : 0.8),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (showSession && started != null)
          PositionedDirectional(
            start: theme.space(2),
            end: theme.space(2),
            bottom: theme.space(2),
            child: IgnorePointer(
              child: GhNow(
                builder: (context, now) {
                  final ms = now.millisecondsSinceEpoch - started;
                  if (ms <= 0) return const SizedBox.shrink();
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(1)),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(9999)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: theme.space(1.5),
                      children: [
                        Container(
                          width: theme.space(1.5),
                          height: theme.space(1.5),
                          decoration: BoxDecoration(color: theme.danger, shape: BoxShape.circle),
                        ),
                        Text(
                          formatDuration(ms),
                          style: theme.text(size: GhTextSize.x3s, weight: GhWeight.semibold, mono: true, color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _backdrop(GhTheme theme, String? icon, String displayName) {
    Shader mask(Rect bounds) =>
        const LinearGradient(colors: [Colors.black, Colors.black, Colors.transparent], stops: [0, 0.35, 0.9]).createShader(bounds);
    return ClipRRect(
      borderRadius: BorderRadius.circular(theme.radiusItem),
      child: Stack(
        children: [
          if (icon != null)
            PositionedDirectional(
              start: -theme.space(6),
              top: 0,
              bottom: 0,
              child: Center(
                child: SizedBox.square(
                  dimension: theme.space(40),
                  child: Opacity(
                    opacity: theme.projectIconAlpha,
                    child: ShaderMask(
                      shaderCallback: mask,
                      blendMode: BlendMode.dstIn,
                      child: ProjectBackdropIcon(
                        hovered: _hovered,
                        restAngle: -6,
                        child: ProjectIconImage(url: icon, onError: () => setState(() => _brokenIcon = icon)),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            PositionedDirectional(
              start: -theme.space(3),
              top: 0,
              bottom: 0,
              child: Center(
                child: Opacity(
                  opacity: theme.projectIconAlpha,
                  child: ShaderMask(
                    shaderCallback: mask,
                    blendMode: BlendMode.dstIn,
                    child: ProjectBackdropIcon(
                      hovered: _hovered,
                      restAngle: -6,
                      grayscale: false,
                      child: TweenAnimationBuilder<Color?>(
                        tween: ColorTween(end: _hovered ? theme.accentBright : theme.muted),
                        duration: GhMotion.of(context).css(const Duration(milliseconds: 500)),
                        curve: GhCurves.outExpo,
                        builder: (context, color, _) => Text(
                          projectInitials(displayName),
                          style: theme.text(weight: FontWeight.w900, color: color, lineHeight: 1).copyWith(fontSize: 84),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _todoBadge(GhTheme theme, TodoCounts counts) {
    final overdue = counts.overdue > 0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: theme.space(1.5), vertical: theme.space(0.5)),
      decoration: BoxDecoration(
        color: overdue ? theme.danger.withValues(alpha: 0.1) : theme.raised,
        borderRadius: BorderRadius.circular(theme.radiusTag),
        border: Border.all(color: overdue ? theme.danger.withValues(alpha: 0.3) : theme.outline.withValues(alpha: 0.5)),
      ),
      child: Text(
        overdue ? ghTr('todos:overdue_count', count: counts.overdue) : ghTr('todos:open_count', count: counts.open),
        style: theme
            .text(size: GhTextSize.x3s, weight: GhWeight.medium, color: overdue ? theme.danger : theme.muted)
            .copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()]),
      ),
    );
  }

  Widget _gitChip(BuildContext context, GhTheme theme, GitStatus status) {
    final dirty = status.hasUncommitted;
    final radius = BorderRadius.circular(theme.radiusTag);
    return GhPressable(
      onPressed: widget.callbacks.onShowGitSidebar,
      semanticLabel: context.tr.common.git_sidebar,
      borderRadius: radius,
      builder: (context, states) {
        final hover = states.active;
        final color = dirty ? theme.amber : (hover ? theme.ink : theme.muted);
        return GhAnimatedBox(
          color: dirty ? theme.amber.withValues(alpha: 0.1) : (hover ? theme.raised : theme.raised.withValues(alpha: 0)),
          borderRadius: radius,
          padding: EdgeInsets.symmetric(horizontal: theme.space(1.5), vertical: theme.space(0.5)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: theme.space(1.5),
            children: [
              _hoverIcon(GhIcons.gitBranch, theme.space(3), color),
              if (status.branch != null)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: theme.space(24)),
                  child: Text(
                    status.branch!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.text(size: GhTextSize.x3s, weight: GhWeight.medium, mono: true, color: color),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _addTagReveal(BuildContext context, GhTheme theme, bool reveal) {
    final radius = BorderRadius.circular(theme.radiusTag);
    return Padding(
      padding: EdgeInsetsDirectional.only(end: theme.space(1.5)),
      child: AnimatedOpacity(
        opacity: reveal ? 1 : 0,
        duration: GhMotion.of(context).css(GhDurations.interactive),
        child: GhPressable(
          onPressed: _startAdd,
          semanticLabel: context.tr.common.add_tag,
          borderRadius: radius,
          builder: (context, states) {
            final hover = states.active;
            return GhDashedBox(
              color: theme.outline.withValues(alpha: 0.5),
              radius: radius,
              child: GhAnimatedBox(
                color: hover ? theme.raised : theme.raised.withValues(alpha: 0),
                borderRadius: radius,
                padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(0.5)),
                child: Text(
                  context.tr.common.add_tag,
                  style: theme.text(
                    size: GhTextSize.x3s,
                    weight: GhWeight.medium,
                    mono: true,
                    color: hover ? theme.accentBright : theme.muted,
                    letterSpacingEm: -0.025,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  KeyEventResult _inputKey(KeyEvent event, VoidCallback onEscape) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      onEscape();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _tagInput(
    GhTheme theme, {
    required TextEditingController controller,
    required FocusNode node,
    required Color color,
    required VoidCallback onSubmit,
    required VoidCallback onEscape,
    required VoidCallback onBlur,
    String? placeholder,
    Color? placeholderColor,
  }) {
    final error = _tagError;
    return SizedBox(
      width: theme.space(16),
      child: GhTextInput(
        controller: controller,
        focusNode: node,
        autofocus: true,
        placeholder: placeholder,
        placeholderColor: placeholderColor,
        tooltip: error,
        onChanged: (_) {
          if (_tagError != null) setState(() => _tagError = null);
        },
        onSubmitted: (_) => onSubmit(),
        onBlur: onBlur,
        onKeyEvent: (node, event) => _inputKey(event, onEscape),
        size: GhTextSize.x3s,
        weight: GhWeight.medium,
        mono: true,
        textColor: error != null ? theme.danger : color,
        bordered: false,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _addTagInput(BuildContext context, GhTheme theme) {
    final error = _tagError != null;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: theme.space(1.5), vertical: theme.space(0.5)),
      decoration: BoxDecoration(
        color: error ? theme.danger.withValues(alpha: 0.1) : theme.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(theme.radiusTag),
        border: Border.all(color: error ? theme.danger.withValues(alpha: 0.5) : theme.accent.withValues(alpha: 0.3)),
      ),
      child: _tagInput(
        theme,
        controller: _newTag,
        node: _addNode,
        color: theme.accentBright,
        placeholder: context.tr.common.tag_input_placeholder,
        placeholderColor: error ? theme.danger.withValues(alpha: 0.4) : theme.accent.withValues(alpha: 0.4),
        onSubmit: _handleAddTag,
        onEscape: _cancelAdd,
        onBlur: _onAddBlur,
      ),
    );
  }

  Widget _tagsRow(BuildContext context, GhTheme theme, {List<Widget> trailing = const []}) {
    final tags = _project.tags;
    final shown = _tagsExpanded ? tags.length : (tags.length < 2 ? tags.length : 2);
    final tr = context.tr.common;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: theme.space(1),
      runSpacing: theme.space(1),
      children: [
        for (var i = 0; i < shown; i++) _tagChip(context, theme, i),
        if (!_tagsExpanded && tags.length > 2)
          _dashedToggle(context, theme, '+${tags.length - 2}', tr.show_more_tags, () => setState(() => _tagsExpanded = true)),
        if (_tagsExpanded && tags.length > 2)
          _dashedToggle(context, theme, '-${tags.length - 2}', tr.show_fewer_tags, () => setState(() => _tagsExpanded = false)),
        ...trailing,
      ],
    );
  }

  Widget _dashedToggle(BuildContext context, GhTheme theme, String label, String semantic, VoidCallback onPressed) {
    final radius = BorderRadius.circular(theme.radiusTag);
    return GhPressable(
      onPressed: onPressed,
      semanticLabel: semantic,
      borderRadius: radius,
      builder: (context, states) => GhDashedBox(
        color: theme.outline.withValues(alpha: 0.5),
        radius: radius,
        child: GhAnimatedBox(
          color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
          borderRadius: radius,
          padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(0.5)),
          child: Text(
            label,
            style: theme.text(
              size: GhTextSize.x3s,
              weight: GhWeight.medium,
              mono: true,
              color: states.active ? theme.ink : theme.muted,
              letterSpacingEm: -0.025,
            ),
          ),
        ),
      ),
    );
  }

  Widget _tagChip(BuildContext context, GhTheme theme, int index) {
    final tag = _project.tags[index];
    final color = colorFromHex(tagColor(tag));
    final active = widget.activeTag == tag;
    final editing = _editingTag == index;
    final tr = context.tr.common;
    return _TagChip(
      key: ValueKey('$tag-$index'),
      builder: (revealed) => GhBrightness(
        amount: active ? 1.1 : 1,
        child: Container(
          padding: EdgeInsetsDirectional.only(
            start: theme.space(1.5),
            end: theme.space(1),
            top: theme.space(0.5),
            bottom: theme.space(0.5),
          ),
          decoration: BoxDecoration(
            color: color.withAlpha(0x18),
            borderRadius: BorderRadius.circular(theme.radiusTag),
            boxShadow: active ? [BoxShadow(color: theme.accentDim.withValues(alpha: 0.7), spreadRadius: 1)] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: theme.space(1.5),
                height: theme.space(1.5),
                margin: EdgeInsetsDirectional.only(end: theme.space(1)),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black.withValues(alpha: 0.2)),
                ),
              ),
              if (editing)
                _tagInput(
                  theme,
                  controller: _editTag,
                  node: _editNode,
                  color: color,
                  onSubmit: () => _handleRename(index),
                  onEscape: _cancelRename,
                  onBlur: () => _handleRename(index),
                )
              else ...[
                GhPressable(
                  onPressed: () => widget.callbacks.onTagClick?.call(tag),
                  focusStyle: GhFocusStyle.none,
                  pressMotion: false,
                  ripple: false,
                  builder: (context, states) => GhBrightness(
                    amount: states.active ? 1.25 : 1,
                    child: Text(
                      tag,
                      style: theme.text(size: GhTextSize.x3s, weight: GhWeight.medium, mono: true, color: color, letterSpacingEm: -0.025),
                    ),
                  ),
                ),
                if (revealed)
                  Padding(
                    padding: EdgeInsetsDirectional.only(start: theme.space(1)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: theme.space(1),
                      children: [
                        _tinyButton(theme, GhIcons.pencil, tr.tag_rename_aria, color, theme.ink, () => _startRename(index)),
                        _tinyButton(theme, GhIcons.x, tr.remove_tag.args({'tag': tag}), color, theme.danger, () => _removeTag(index)),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tinyButton(GhTheme theme, FaIconData icon, String label, Color color, Color hoverColor, VoidCallback onPressed) {
    return GhPressable(
      onPressed: onPressed,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(9999),
      builder: (context, states) => SizedBox.square(
        dimension: theme.space(3),
        child: Center(
          child: GhIcon(icon, size: theme.space(2.5), color: states.active ? hoverColor : color),
        ),
      ),
    );
  }

  Widget _pathButton(BuildContext context, GhTheme theme, bool blur) {
    final radius = BorderRadius.circular(theme.radiusTag);
    return GhPressable(
      onPressed: () => openProjectFolder(_project),
      borderRadius: radius,
      builder: (context, states) {
        Widget text = Text(
          _project.path,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.text(
            size: GhTextSize.x2s,
            mono: true,
            color: states.active ? theme.accentBright : (_cover ? theme.muted.withValues(alpha: 0.8) : theme.muted),
          ),
        );
        if (blur && !states.active) {
          text = ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4), child: text);
        }
        if (_cover) return text;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(1)),
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.15), borderRadius: radius),
          child: text,
        );
      },
    );
  }

  Widget _chipFace(GhTheme theme, GhStates states, List<Widget> children, {Color? background, Color? border}) {
    final hover = states.active;
    if (_cover) {
      return GhAnimatedBox(
        color: hover ? theme.raised : Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(theme.radiusTag),
        padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(2)),
        child: DefaultTextStyle.merge(
          style: theme.text(size: GhTextSize.x3s, mono: true, color: hover ? theme.ink : theme.muted),
          child: Row(mainAxisSize: MainAxisSize.min, spacing: theme.space(1.5), children: children),
        ),
      );
    }
    return GhAnimatedBox(
      color: background ?? theme.raised,
      borderRadius: BorderRadius.circular(theme.radiusBtn),
      border: Border.all(color: border ?? (hover ? theme.accentDim : theme.outline.withValues(alpha: 0.5))),
      padding: EdgeInsets.all(theme.space(3)),
      child: DefaultTextStyle.merge(
        style: theme.text(size: GhTextSize.x3s, mono: true, color: hover ? theme.ink : theme.muted),
        child: Row(mainAxisSize: MainAxisSize.min, spacing: theme.space(1.5), children: children),
      ),
    );
  }

  Widget _versionDropdown(BuildContext context, GhTheme theme, InstalledGodotVersion? version) {
    final tr = context.tr.common;
    return GhDropdown(
      align: GhSide.left,
      items: [
        for (final v in widget.installedVersions)
          GhMenuItem(
            id: v.tag,
            label: (v.customName?.isNotEmpty ?? false) ? v.customName! : v.tag,
            active: v.tag == _project.godotVersion,
            badge: v.isMono ? tr.version_mono_badge : null,
            onSelected: () => widget.callbacks.onVersionChange(v.tag),
          ),
      ],
      trigger: (context, open, toggle) => GhPressable(
        onPressed: toggle,
        expanded: open,
        borderRadius: BorderRadius.circular(theme.radiusBtn),
        builder: (context, states) => _chipFace(theme, states, [
          _hoverIcon(GhIcons.node, theme.space(2.5), states.active ? theme.ink : theme.muted),
          if (version != null) ...[
            Text((version.customName?.isNotEmpty ?? false) ? version.customName! : version.tag),
            if (version.isMono)
              Container(
                padding: EdgeInsets.symmetric(horizontal: theme.space(1.5), vertical: theme.space(0.5)),
                decoration: BoxDecoration(
                  color: theme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(theme.radiusTag),
                  border: Border.all(color: theme.accentDim.withValues(alpha: 0.4)),
                ),
                child: Text(
                  tr.version_mono_badge,
                  style: theme.text(size: GhTextSize.x3s, weight: GhWeight.semibold, color: theme.accentBright),
                ),
              ),
          ] else
            Text(tr.no_version_selected),
          _chevron(theme, open),
        ]),
      ),
    );
  }

  Widget _chevron(GhTheme theme, bool open) => AnimatedRotation(
    turns: open ? 0.5 : 0,
    duration: GhMotion.of(context).css(const Duration(milliseconds: 500)),
    curve: GhCurves.spring,
    child: GhIcon(GhIcons.chevronDown, size: theme.space(2.5), color: open ? theme.ink : null),
  );

  Widget _pinButton(BuildContext context, GhTheme theme) {
    final tr = context.tr.common;
    final pinned = _project.pinned;
    final radius = BorderRadius.circular(theme.radiusBtn);
    if (pinned) {
      return GhTooltip(
        message: tr.project_unpin_aria,
        side: GhSide.top,
        child: GhPressable(
          onPressed: widget.callbacks.onTogglePin,
          semanticLabel: tr.project_unpin_aria,
          borderRadius: radius,
          builder: (context, states) {
            final hover = states.active;
            return GhAnimatedBox(
              color: theme.accent.withValues(alpha: hover ? 0.2 : 0.1),
              borderRadius: radius,
              border: Border.all(color: hover ? theme.accentDim : theme.accentDim.withValues(alpha: 0.4)),
              padding: EdgeInsets.all(theme.space(2.5)),
              child: GhIcon(GhIcons.pin, size: theme.space(3), color: theme.accentBright),
            );
          },
        ),
      );
    }
    return GhPressable(
      onPressed: widget.callbacks.onTogglePin,
      borderRadius: radius,
      builder: (context, states) => _chipFace(theme, states, [
        GhIcon(GhIcons.pin, size: theme.space(3), color: states.active ? theme.ink : theme.muted),
        Text(tr.project_pin_aria),
      ]),
    );
  }

  List<Widget> _timeButton(BuildContext context, GhTheme theme) {
    final tr = context.tr.common;
    Widget build(int now) {
      final total = effectiveTotalMs(_project, now);
      if (total <= 0) return const SizedBox.shrink();
      return _chipButton(
        context,
        theme,
        icon: GhIcons.stopwatch,
        label: formatDuration(total),
        semanticLabel: tr.time_tracked_title,
        onPressed: () => openTimeTracker(context, _project),
      );
    }

    if (effectiveTotalMs(_project, DateTime.now().millisecondsSinceEpoch) <= 0) return const [];
    if (_project.sessionStartedAtMs == null) return [build(DateTime.now().millisecondsSinceEpoch)];
    return [GhNow(builder: (context, now) => build(now.millisecondsSinceEpoch))];
  }

  Widget _chipButton(
    BuildContext context,
    GhTheme theme, {
    required FaIconData icon,
    required String label,
    required String semanticLabel,
    required VoidCallback onPressed,
  }) {
    return GhPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      borderRadius: BorderRadius.circular(theme.radiusBtn),
      builder: (context, states) => _chipFace(
        theme,
        states,
        [_hoverIcon(icon, theme.space(3), theme.muted.withValues(alpha: 0.6)), Text(label)],
        background: states.active ? theme.raised : Colors.black.withValues(alpha: 0.1),
        border: theme.outline.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _categoryDropdown(BuildContext context, GhTheme theme) {
    final tr = context.tr.common;
    final project = _project;
    Category? category;
    for (final c in widget.categories) {
      if (c.name == project.category) category = c;
    }
    final dot = category == null ? uncategorizedDot : colorFromHex(category.color);
    return GhDropdown(
      align: GhSide.right,
      items: categoryMenuChildren(context, project, widget.categories, widget.callbacks.onCategoryChange!),
      trigger: (context, open, toggle) => GhPressable(
        onPressed: toggle,
        expanded: open,
        borderRadius: BorderRadius.circular(theme.radiusBtn),
        builder: (context, states) => _chipFace(theme, states, [
          Container(
            width: theme.space(1.5),
            height: theme.space(1.5),
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black.withValues(alpha: 0.2)),
            ),
          ),
          Text(project.category ?? tr.uncategorized),
          _chevron(theme, open),
        ]),
      ),
    );
  }

  List<Widget> _sessionPill(GhTheme theme, bool show) {
    final started = _project.sessionStartedAtMs?.toInt();
    if (!show || started == null) return const [];
    return [
      Transform.translate(
        offset: Offset(Directionality.of(context) == TextDirection.rtl ? -theme.space(5) : theme.space(5), -theme.space(1)),
        child: GhNow(
          builder: (context, now) {
            final ms = now.millisecondsSinceEpoch - started;
            if (ms <= 0) return const SizedBox.shrink();
            return Container(
              height: theme.space(10),
              padding: EdgeInsets.symmetric(horizontal: theme.space(4)),
              decoration: BoxDecoration(
                color: theme.base.withValues(alpha: 0.5),
                borderRadius: BorderRadiusDirectional.horizontal(start: Radius.circular(theme.radiusDropdownBtn))
                    .resolve(Directionality.of(context)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: theme.space(2),
                children: [
                  Container(
                    width: theme.space(1.5),
                    height: theme.space(1.5),
                    decoration: BoxDecoration(color: theme.accentBright, shape: BoxShape.circle),
                  ),
                  Text(
                    formatDuration(ms),
                    style: theme.text(size: GhTextSize.xs, mono: true, color: theme.accentBright),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ];
  }

  Widget _playButton(BuildContext context, GhTheme theme) {
    final tr = context.tr.common;
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhTooltip(
      message: tr.play_project_tooltip,
      side: GhSide.left,
      child: GhPressable(
        onPressed: () => playProject(_project),
        semanticLabel: tr.play_project,
        borderRadius: radius,
        builder: (context, states) {
          final hover = states.active;
          final color = hover ? theme.ink : theme.muted;
          return GhAnimatedBox(
            height: theme.space(12),
            alignment: Alignment.center,
            color: hover ? theme.raised : theme.overlay,
            borderRadius: radius,
            border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
            boxShadow: GhShadows.md(Colors.black.withValues(alpha: 0.1)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: theme.space(1.5),
              children: [
                GhIcon(GhIcons.play, size: theme.space(4), color: color),
                Text(
                  tr.play_project,
                  style: theme.text(size: GhTextSize.lg, weight: GhWeight.medium, color: color),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TagChip extends StatefulWidget {
  const _TagChip({super.key, required this.builder});

  final Widget Function(bool revealed) builder;

  @override
  State<_TagChip> createState() => _TagChipState();
}

class _TagChipState extends State<_TagChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (value) => setState(() => _focused = value),
      child: widget.builder(_hovered || _focused),
    ),
  );
}
