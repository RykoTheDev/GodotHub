import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/design.dart';
import '../logic/card_view_settings.dart';
import '../logic/duration.dart';
import '../logic/last_opened.dart';
import '../logic/project_sort.dart';
import '../motion/motion.dart';
import '../motion/shared_ticker.dart';
import '../src/rust/api/types.dart';
import '../state/project_tile_data.dart';
import '../state/settings.dart';
import '../ui/controls/dashed_box.dart';
import '../ui/controls/negative_margin.dart';
import '../ui/controls/spin.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/core/tooltip.dart';
import '../ui/core/ui_settings.dart' show GhSide;
import '../ui/overlays/dropdown.dart';
import '../ui/overlays/menu.dart';
import '../ui/reusables/open_button.dart';
import 'project_actions.dart';
import 'project_icon.dart';
import '../ui/shell/smooth_scroll.dart';

String shortProjectPath(String path) {
  final parts = path.split(RegExp(r'[\\/]')).where((p) => p.isNotEmpty).toList();
  return parts.length > 2 ? '…/${parts.sublist(parts.length - 2).join('/')}' : path;
}

String formatProjectSize(int bytes) {
  const kb = 1024;
  if (bytes >= kb * kb * kb) return '${(bytes / (kb * kb * kb)).toStringAsFixed(1)} GB';
  if (bytes >= kb * kb) return '${(bytes / (kb * kb)).toStringAsFixed(1)} MB';
  if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(0)} KB';
  return '$bytes B';
}

class ProjectTile extends ConsumerStatefulWidget {
  const ProjectTile({
    super.key,
    required this.project,
    required this.installedVersions,
    required this.callbacks,
    this.categories = const [],
    this.gitStatus,
    this.gitLoading = false,
    this.launchWithConsole = false,
    this.compact = false,
    this.activeTag,
    this.selected = false,
    this.viewMode = ProjectViewMode.grid,
    this.preview = false,
  });

  final Project project;
  final List<InstalledGodotVersion> installedVersions;
  final ProjectCallbacks callbacks;
  final List<Category> categories;
  final GitStatus? gitStatus;
  final bool gitLoading;
  final bool launchWithConsole;
  final bool compact;
  final String? activeTag;
  final bool selected;
  final ProjectViewMode viewMode;
  final bool preview;

  @override
  ConsumerState<ProjectTile> createState() => _ProjectTileState();
}

class _ProjectTileState extends ConsumerState<ProjectTile> {
  bool _hovered = false;
  bool _focusWithin = false;
  String? _brokenIcon;
  Duration? _lastUp;

  bool get _reveal => _hovered || _focusWithin;

  void _onPointerUp(PointerUpEvent event) {
    if (!mounted) return;
    if (widget.preview) return;
    final self = context.findRenderObject();
    final modifiers = SelectModifiers.current();
    final last = _lastUp;
    _lastUp = event.timeStamp;
    if (ghHitsControl(event.position, event.viewId, self)) return;
    if (modifiers.any) {
      widget.callbacks.onToggleSelect?.call(modifiers);
      return;
    }
    final version = _version;
    if (last != null && event.timeStamp - last < kDoubleTapTimeout && version != null) {
      _lastUp = null;
      launchProject(widget.project);
    }
  }

  InstalledGodotVersion? get _version {
    for (final v in widget.installedVersions) {
      if (v.tag == widget.project.godotVersion) return v;
    }
    return null;
  }

  List<GhMenuItem> _menuItems(BuildContext context, String displayName) {
    final tr = context.tr.common;
    final project = widget.project;
    final cb = widget.callbacks;
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
        id: 'pin',
        label: project.pinned ? tr.project_unpin_aria : tr.project_pin_aria,
        icon: GhIcons.pin,
        onSelected: cb.onTogglePin,
      ),
      if (cb.onLaunchArgsChange != null)
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
        onSelected: () => openTagManager(context, project, cb.onTagsSaved),
      ),
      if (cb.onDuplicate != null) GhMenuItem(id: 'duplicate', label: tr.duplicate, icon: GhIcons.copy, onSelected: cb.onDuplicate),
      if (cb.onCategoryChange != null)
        GhMenuItem(
          id: 'set-category',
          label: tr.set_category,
          icon: GhIcons.tags,
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
      if (cb.onDelete != null)
        GhMenuItem(
          id: 'delete',
          label: tr.project_card_delete_files,
          icon: GhIcons.trash,
          danger: true,
          onSelected: () => confirmDeleteProject(context, displayName, cb.onDelete!),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr.common;
    final settings = ref.watch(settingsProvider).value ?? defaultSettings;
    final options = getCardViewSettings(settings, widget.viewMode);
    final project = widget.project;
    final data = ref.watch(projectTileDataProvider((path: project.path, showSize: options.showSize, preview: widget.preview)));
    final displayName = data.displayName(project.name);
    final grid = widget.viewMode == ProjectViewMode.grid;
    final compact = widget.compact;
    final version = _version;
    final versionLabel = (version?.customName?.isNotEmpty ?? false)
        ? version!.customName!
        : (version?.tag ?? (project.godotVersion.isNotEmpty ? project.godotVersion : tr.no_version_selected));
    final unavailable = project.godotVersion.isNotEmpty && version == null;
    final unavailableHint = widget.installedVersions.isEmpty
        ? tr.no_engine_warning
        : unavailable
        ? tr.project_card_version_unavailable.args({'version': project.godotVersion})
        : tr.no_version_selected;
    final running = project.sessionStartedAtMs != null;
    final gitStatus = widget.gitStatus;
    final cb = widget.callbacks;
    final hasGit = (gitStatus?.isRepo ?? false) && cb.onShowGitSidebar != null;
    final gitPending = widget.gitLoading && gitStatus == null && cb.onShowGitSidebar != null;
    final lastOpened = formatLastOpened(
      project.lastOpened,
      timeFormat: LastOpenedTimeFormat.parse(settings.lastOpenedTimeFormat),
      dateFormat: LastOpenedDateFormat.parse(settings.lastOpenedDateFormat),
    );
    final icon = data.icon != null && data.icon != _brokenIcon ? data.icon : null;
    final preview = widget.preview;

    Widget hoverReveal(Widget child) =>
        grid ? AnimatedOpacity(opacity: _reveal ? 1 : 0, duration: GhMotion.of(context).css(GhDurations.interactive), child: child) : child;

    final border = widget.selected
        ? theme.accent
        : running
        ? (_hovered ? theme.accentDim : theme.accentDim.withValues(alpha: 0.5))
        : (_hovered ? theme.accentDim.withValues(alpha: 0.5) : theme.outline.withValues(alpha: 0.5));
    final background = widget.selected ? theme.accent.withValues(alpha: 0.05) : theme.overlay;
    final radius = BorderRadius.circular(theme.radiusItem);

    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: theme.space(3),
      children: [
        Container(
          width: theme.space(grid ? 12 : (compact ? 9 : 10)),
          height: theme.space(grid ? 12 : (compact ? 9 : 10)),
          alignment: Alignment.center,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.raised,
            borderRadius: BorderRadius.circular(theme.radiusTile),
            border: Border.all(color: theme.outline.withValues(alpha: 0.4)),
          ),
          child: icon != null
              ? Padding(
                  padding: EdgeInsets.all(theme.space(1)),
                  child: ProjectIconImage(url: icon, onError: () => setState(() => _brokenIcon = icon)),
                )
              : Text(
                  projectInitials(displayName, tileStyle: true),
                  style: theme.text(size: GhTextSize.sm, weight: GhWeight.semibold, color: theme.accentBright.withValues(alpha: 0.8)),
                ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: theme.space(1),
            children: [
              Tooltip(
                message: displayName,
                waitDuration: const Duration(milliseconds: 600),
                child: Text(
                  displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text(
                    size: grid ? GhTextSize.base : (compact ? GhTextSize.sm : GhTextSize.base),
                    weight: GhWeight.semibold,
                    color: theme.ink,
                    lineHeight: 1.375,
                  ),
                ),
              ),
              if (options.showPath) _pathButton(context, theme, grid, options.blurPath),
              if (running) _runningBadge(context, theme, options.showSessionTimer),
            ],
          ),
        ),
        _iconButton(
          context,
          icon: GhIcons.pin,
          label: project.pinned ? tr.project_unpin_aria : tr.project_pin_aria,
          onPressed: preview ? null : cb.onTogglePin,
          active: project.pinned,
          reveal: !project.pinned && grid,
          toggled: project.pinned,
          iconSize: 3.5,
        ),
      ],
    );

    final metaChildren = <Widget>[
      if (gitPending)
        Container(
          padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(1)),
          decoration: BoxDecoration(color: theme.raised, borderRadius: BorderRadius.circular(theme.radiusTag)),
          child: GhSpinning(
            child: GhIcon(GhIcons.spinner, size: theme.space(3), color: theme.muted),
          ),
        ),
      if (hasGit) _gitButton(context, theme, gitStatus!),
      if (options.showTime) ..._timeButton(context, theme),
      if (options.showSize && (data.size != null || !data.sizeFailed)) _sizeButton(context, theme, data),
      if (options.showLastOpened && lastOpened != null)
        Tooltip(
          message: tr.project_card_last_opened.args({'date': _localeDate(project.lastOpened)}),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: theme.space(1.5),
            children: [
              GhIcon(GhIcons.history, size: theme.space(3), color: theme.muted.withValues(alpha: 0.7)),
              Text(lastOpened),
            ],
          ),
        ),
    ];

    final tags = project.tags;
    final tagChildren = <Widget>[
      for (final tag in tags.take(2)) _tagChip(context, theme, tag),
      if (tags.length > 2)
        _smallChip(
          context,
          theme,
          label: '+${tags.length - 2}',
          semanticLabel: tr.project_card_more_tags.args({'count': tags.length - 2}),
          onPressed: preview ? null : () => openTagManager(context, project, cb.onTagsSaved),
        ),
      if (tags.isEmpty)
        hoverReveal(_addTagButton(context, theme, onPressed: preview ? null : () => openTagManager(context, project, cb.onTagsSaved))),
    ];
    final tagsRow = Row(
      spacing: theme.space(1.5),
      children: [
        Expanded(
          child: grid
              ? ClipRect(
                  child: GhScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(spacing: theme.space(1.5), children: tagChildren),
                  ),
                )
              : Wrap(spacing: theme.space(1.5), runSpacing: theme.space(1.5), children: tagChildren),
        ),
        if (tags.isNotEmpty)
          _iconButton(
            context,
            icon: GhIcons.tags,
            label: tr.manage_tags,
            onPressed: preview ? null : () => openTagManager(context, project, cb.onTagsSaved),
            reveal: grid,
            iconSize: 3,
            muted: theme.muted.withValues(alpha: 0.6),
          ),
      ],
    );

    final footerContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(2),
      children: [
        _versionDropdown(context, theme, version, versionLabel, unavailable, unavailableHint),
        if (version == null)
          Tooltip(
            message: unavailableHint,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: theme.space(1)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: theme.space(1.5),
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: theme.space(0.5)),
                    child: GhIcon(GhIcons.alertTriangle, size: theme.space(2.5), color: theme.amber.withValues(alpha: 0.8)),
                  ),
                  Expanded(
                    child: Text(
                      unavailableHint,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.text(size: GhTextSize.x3s, color: theme.amber.withValues(alpha: 0.8), lineHeight: 1.625),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Row(
          spacing: theme.space(1.5),
          children: [
            if (options.showPlay) _playButton(context, theme, version, unavailableHint),
            Expanded(
              child: GhOpenButton(
                label: tr.open_project,
                disabled: version == null || preview,
                disabledReason: unavailableHint,
                size: GhOpenButtonSize.compact,
                onOpen: (console) => launchProject(project, console),
                consoleSupported: version?.supportsConsole ?? false,
                consoleInitiallyOn: widget.launchWithConsole,
                showConsole: options.showConsole,
                moreLabel: tr.project_more_aria,
                items: _menuItems(context, displayName),
                headerItems: projectHeaderItems(context, project, todosEnabled: false),
              ),
            ),
          ],
        ),
      ],
    );

    final footer = grid
        ? GhNegativeMargin(
            margin: EdgeInsets.fromLTRB(theme.space(4), 0, theme.space(4), theme.space(4)),
            child: Container(
              padding: EdgeInsets.fromLTRB(theme.space(4), theme.space(3), theme.space(4), theme.space(4)),
              decoration: BoxDecoration(
                color: theme.base.withValues(alpha: 0.3),
                border: Border(top: BorderSide(color: theme.outline.withValues(alpha: 0.3))),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(theme.radiusItem)),
              ),
              child: footerContent,
            ),
          )
        : Container(
            padding: EdgeInsets.only(top: theme.space(3)),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.outline.withValues(alpha: 0.3))),
            ),
            child: footerContent,
          );

    final top = <Widget>[
      header,
      if (metaChildren.isNotEmpty)
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: theme.space(6)),
          child: DefaultTextStyle.merge(
            style: theme.text(size: GhTextSize.x2s, color: theme.muted.withValues(alpha: 0.7)),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: theme.space(3),
              runSpacing: theme.space(1.5),
              children: metaChildren,
            ),
          ),
        ),
      if (options.showTags) tagsRow,
    ];
    final body = grid
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: theme.space(3), children: top),
              Padding(
                padding: EdgeInsets.only(top: theme.space(3)),
                child: footer,
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: theme.space(3),
            children: [...top, footer],
          );

    Widget tile = AnimatedContainer(
      duration: GhMotion.of(context).css(GhDurations.interactive),
      curve: GhCurves.outExpo,
      constraints: grid ? BoxConstraints(minHeight: theme.space(60)) : null,
      padding: EdgeInsets.all(theme.space(grid ? 4 : (compact ? 3 : 3.5))),
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        border: Border.all(color: border),
        boxShadow: widget.selected ? [BoxShadow(color: theme.accent.withValues(alpha: 0.6), spreadRadius: 1)] : null,
      ),
      clipBehavior: Clip.none,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (grid)
            Positioned(
              left: -theme.space(4),
              top: -theme.space(4),
              right: -theme.space(4),
              bottom: -theme.space(4),
              child: IgnorePointer(child: _backdrop(theme, icon, displayName)),
            ),
          body,
        ],
      ),
    );
    tile = Semantics(container: true, label: displayName, child: tile);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (value) => setState(() => _focusWithin = value),
        child: Listener(onPointerUp: _onPointerUp, child: tile),
      ),
    );
  }

  String _localeDate(String? value) {
    final date = parseJsDate(value)?.toLocal();
    if (date == null) return value ?? '';
    final material = MaterialLocalizations.of(context);
    return '${material.formatShortDate(date)}, ${material.formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
  }

  Widget _backdrop(GhTheme theme, String? icon, String displayName) {
    Shader mask(Rect bounds) => const RadialGradient(
      center: Alignment(0.4, -0.4),
      radius: 0.7,
      colors: [Colors.black, Colors.black, Colors.transparent],
      stops: [0, 0.357, 1],
    ).createShader(bounds);
    return ClipRRect(
      borderRadius: BorderRadius.circular(theme.radiusItem),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          if (icon != null)
            PositionedDirectional(
              end: -theme.space(10),
              top: -theme.space(10),
              width: theme.space(44),
              height: theme.space(44),
              child: Opacity(
                opacity: theme.projectIconAlpha,
                child: ShaderMask(
                  shaderCallback: mask,
                  blendMode: BlendMode.dstIn,
                  child: ProjectBackdropIcon(
                    hovered: _hovered,
                    restAngle: -12,
                    hoverAngle: -3,
                    child: ProjectIconImage(url: icon),
                  ),
                ),
              ),
            )
          else
            PositionedDirectional(
              end: -theme.space(3),
              top: -theme.space(5),
              child: Opacity(
                opacity: theme.projectIconAlpha,
                child: ShaderMask(
                  shaderCallback: mask,
                  blendMode: BlendMode.dstIn,
                  child: ProjectBackdropIcon(
                    hovered: _hovered,
                    restAngle: -12,
                    hoverAngle: -3,
                    grayscale: false,
                    child: TweenAnimationBuilder<Color?>(
                      tween: ColorTween(end: _hovered ? theme.accentBright : theme.muted),
                      duration: GhMotion.of(context).css(const Duration(milliseconds: 500)),
                      curve: GhCurves.outExpo,
                      builder: (context, color, _) => Text(
                        projectInitials(displayName, tileStyle: true),
                        style: theme.text(weight: FontWeight.w900, color: color, lineHeight: 1).copyWith(fontSize: 112),
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

  Widget _pathButton(BuildContext context, GhTheme theme, bool grid, bool blur) {
    final project = widget.project;
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhTooltip(
      message: project.path,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: GhPressable(
          onPressed: widget.preview ? null : () => openProjectFolder(project),
          disabledOpacity: null,
          semanticLabel: context.tr.common.open_folder,
          borderRadius: radius,
          builder: (context, states) {
            Widget text = Text(
              grid ? shortProjectPath(project.path) : project.path,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.text(
                size: GhTextSize.x2s,
                mono: true,
                color: states.active ? theme.accentBright : theme.muted.withValues(alpha: 0.7),
              ),
            );
            if (blur && !states.highlighted) {
              text = ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4), child: text);
            }
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: theme.space(1), vertical: theme.space(0.5)),
              child: text,
            );
          },
        ),
      ),
    );
  }

  Widget _runningBadge(BuildContext context, GhTheme theme, bool showTimer) {
    final tr = context.tr.common;
    final started = widget.project.sessionStartedAtMs?.toInt();
    return Tooltip(
      message: tr.running,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(0.5)),
        decoration: BoxDecoration(color: theme.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(theme.radiusTag)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: theme.space(1.5),
          children: [
            Container(
              width: theme.space(2),
              height: theme.space(2),
              decoration: BoxDecoration(color: theme.accentBright, shape: BoxShape.circle),
            ),
            Text(
              tr.running,
              style: theme.text(size: GhTextSize.x3s, weight: GhWeight.medium, color: theme.accentBright),
            ),
            if (showTimer && started != null)
              GhNow(
                builder: (context, now) => Text(
                  formatDuration((now.millisecondsSinceEpoch - started).clamp(0, 1 << 62)),
                  style: theme
                      .text(size: GhTextSize.x3s, weight: GhWeight.medium, mono: true, color: theme.accentBright)
                      .copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _iconButton(
    BuildContext context, {
    required FaIconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool active = false,
    bool reveal = false,
    bool? toggled,
    double iconSize = 3,
    Color? muted,
  }) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusBtn);
    Widget button = GhPressable(
      onPressed: onPressed,
      semanticLabel: label,
      tooltip: label,
      toggled: toggled,
      borderRadius: radius,
      builder: (context, states) {
        final hover = states.active;
        final background = active
            ? theme.accent.withValues(alpha: hover ? 0.2 : 0.1)
            : (hover ? theme.raised : theme.raised.withValues(alpha: 0));
        final color = active ? theme.accentBright : (hover ? theme.ink : (muted ?? theme.muted.withValues(alpha: 0.7)));
        return GhAnimatedBox(
          width: theme.space(7),
          height: theme.space(7),
          alignment: Alignment.center,
          color: background,
          borderRadius: radius,
          child: GhIcon(icon, size: theme.space(iconSize), color: color),
        );
      },
    );
    if (reveal) {
      button = AnimatedOpacity(opacity: _reveal ? 1 : 0, duration: GhMotion.of(context).css(GhDurations.interactive), child: button);
    }
    return button;
  }

  Widget _gitButton(BuildContext context, GhTheme theme, GitStatus status) {
    final tr = context.tr.common;
    final dirty = status.hasUncommitted;
    final radius = BorderRadius.circular(theme.radiusTag);
    final branch = status.branch ?? '';
    return GhPressable(
      onPressed: widget.preview ? null : widget.callbacks.onShowGitSidebar,
      disabledOpacity: null,
      semanticLabel: tr.git_sidebar,
      tooltip: '$branch · ${dirty ? tr.git_uncommitted : tr.git_clean}',
      borderRadius: radius,
      builder: (context, states) {
        final hover = states.active;
        final color = dirty ? theme.amber : (hover ? theme.ink : theme.muted);
        return GhAnimatedBox(
          color: dirty ? theme.amber.withValues(alpha: hover ? 0.15 : 0.1) : theme.raised,
          borderRadius: radius,
          padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(1)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: theme.space(1.5),
            children: [
              GhIcon(GhIcons.gitBranch, size: theme.space(3), color: color),
              Flexible(
                child: Text(
                  branch.isNotEmpty ? branch : tr.git_sidebar,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text(size: GhTextSize.x2s, color: color),
                ),
              ),
              if (dirty)
                Container(
                  width: theme.space(1.5),
                  height: theme.space(1.5),
                  decoration: BoxDecoration(color: theme.amber, shape: BoxShape.circle),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _timeButton(BuildContext context, GhTheme theme) {
    final project = widget.project;
    final tr = context.tr.common;
    Widget build(int now) {
      final total = effectiveTotalMs(project, now);
      if (total <= 0) return const SizedBox.shrink();
      final label = formatDuration(total);
      return _metaButton(
        context,
        theme,
        icon: GhIcons.clock,
        label: label,
        mono: true,
        semanticLabel: tr.time_tracked_title,
        tooltip: tr.project_card_total_time.args({'time': label}),
        onPressed: () => openTimeTracker(context, project),
      );
    }

    final total = effectiveTotalMs(project, DateTime.now().millisecondsSinceEpoch);
    if (total <= 0) return const [];
    if (project.sessionStartedAtMs == null) return [build(DateTime.now().millisecondsSinceEpoch)];
    return [GhNow(builder: (context, now) => build(now.millisecondsSinceEpoch))];
  }

  Widget _sizeButton(BuildContext context, GhTheme theme, ProjectTileData data) {
    final tr = context.tr.common;
    final size = data.size;
    return _metaButton(
      context,
      theme,
      icon: GhIcons.hardDrive,
      label: size == null ? null : formatProjectSize(size),
      semanticLabel: tr.project_size,
      tooltip: tr.project_size,
      placeholder: Container(
        width: theme.space(10),
        height: theme.space(2.5),
        decoration: BoxDecoration(color: theme.raised, borderRadius: BorderRadius.circular(theme.rem(0.25))),
      ),
      onPressed: () => openProjectSize(context, widget.project),
    );
  }

  Widget _metaButton(
    BuildContext context,
    GhTheme theme, {
    required FaIconData icon,
    required String? label,
    required String semanticLabel,
    required String tooltip,
    required VoidCallback onPressed,
    bool mono = false,
    Widget? placeholder,
  }) {
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhPressable(
      onPressed: widget.preview ? null : onPressed,
      disabledOpacity: null,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      borderRadius: radius,
      builder: (context, states) {
        final color = states.active ? theme.ink : theme.muted.withValues(alpha: 0.7);
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.space(1), vertical: theme.space(0.5)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: theme.space(1.5),
            children: [
              GhIcon(icon, size: theme.space(3), color: color),
              if (label != null)
                Text(
                  label,
                  style: theme
                      .text(size: GhTextSize.x2s, mono: mono, color: color)
                      .copyWith(fontFeatures: const [ui.FontFeature.tabularFigures()]),
                )
              else
                ?placeholder,
            ],
          ),
        );
      },
    );
  }

  Widget _tagChip(BuildContext context, GhTheme theme, String tag) {
    final color = colorFromHex(tagColor(tag));
    final active = widget.activeTag == tag;
    final radius = BorderRadius.circular(theme.radiusTag);
    final cb = widget.callbacks;
    return GhPressable(
      onPressed: widget.preview
          ? null
          : () => cb.onTagClick != null ? cb.onTagClick!(tag) : openTagManager(context, widget.project, cb.onTagsSaved),
      disabledOpacity: null,
      toggled: active,
      tooltip: tag,
      borderRadius: radius,
      builder: (context, states) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: theme.space(28)),
        child: GhBrightness(
          amount: states.active ? 1.25 : 1,
          child: Container(
            height: theme.space(6),
            padding: EdgeInsets.symmetric(horizontal: theme.space(2)),
            decoration: BoxDecoration(
              color: color.withAlpha(0x18),
              borderRadius: radius,
              border: active ? Border.all(color: theme.accentDim) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: theme.space(1.5),
              children: [
                Container(
                  width: theme.space(1),
                  height: theme.space(1),
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                Flexible(
                  child: Text(
                    tag,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.text(size: GhTextSize.x3s, weight: GhWeight.medium, color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallChip(BuildContext context, GhTheme theme, {required String label, required String semanticLabel, VoidCallback? onPressed}) {
    final radius = BorderRadius.circular(theme.radiusTag);
    return GhPressable(
      onPressed: onPressed,
      disabledOpacity: null,
      semanticLabel: semanticLabel,
      borderRadius: radius,
      builder: (context, states) => Container(
        height: theme.space(6),
        padding: EdgeInsets.symmetric(horizontal: theme.space(2)),
        decoration: BoxDecoration(color: theme.raised, borderRadius: radius),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style: theme.text(size: GhTextSize.x3s, color: states.active ? theme.ink : theme.muted),
          ),
        ),
      ),
    );
  }

  Widget _addTagButton(BuildContext context, GhTheme theme, {VoidCallback? onPressed}) {
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhPressable(
      onPressed: onPressed,
      disabledOpacity: null,
      borderRadius: radius,
      builder: (context, states) {
        final hover = states.active;
        final color = hover ? theme.ink : theme.muted.withValues(alpha: 0.7);
        return GhDashedBox(
          color: theme.outline.withValues(alpha: 0.5),
          radius: radius,
          child: GhAnimatedBox(
            height: theme.space(6),
            padding: EdgeInsets.symmetric(horizontal: theme.space(2)),
            color: hover ? theme.raised : theme.raised.withValues(alpha: 0),
            borderRadius: radius,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: theme.space(1),
              children: [
                GhIcon(GhIcons.plus, size: theme.space(2.5), color: color),
                Text(
                  context.tr.common.add_tag,
                  style: theme.text(size: GhTextSize.x3s, color: color),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _versionDropdown(
    BuildContext context,
    GhTheme theme,
    InstalledGodotVersion? version,
    String label,
    bool unavailable,
    String unavailableHint,
  ) {
    final tr = context.tr.common;
    final disabled = widget.preview || widget.installedVersions.isEmpty;
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhDropdown(
      align: GhSide.left,
      expand: true,
      items: [
        for (final entry in widget.installedVersions)
          GhMenuItem(
            id: entry.tag,
            label: (entry.customName?.isNotEmpty ?? false) ? entry.customName! : entry.tag,
            badge: (entry.customName?.isNotEmpty ?? false) && entry.customName != entry.tag ? entry.tag : null,
            active: entry.tag == widget.project.godotVersion,
            onSelected: () => widget.callbacks.onVersionChange(entry.tag),
          ),
      ],
      trigger: (context, open, toggle) => GhPressable(
        onPressed: disabled ? null : toggle,
        disabledOpacity: 0.6,
        disabledCursor: SystemMouseCursors.forbidden,
        expanded: open,
        semanticLabel: tr.godot_version_label,
        tooltip: version == null ? unavailableHint : tr.godot_version_label,
        borderRadius: radius,
        builder: (context, states) {
          final color = unavailable ? theme.amber : theme.muted;
          return GhAnimatedBox(
            color: theme.raised,
            borderRadius: radius,
            border: Border.all(color: states.active ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
            padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(2)),
            child: Row(
              spacing: theme.space(2),
              children: [
                GhIcon(GhIcons.node, size: theme.space(3), color: color),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.text(size: GhTextSize.x2s, color: color),
                  ),
                ),
                GhIcon(GhIcons.chevronDown, size: theme.space(2.5), color: color),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _playButton(BuildContext context, GhTheme theme, InstalledGodotVersion? version, String unavailableHint) {
    final tr = context.tr.common;
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhPressable(
      onPressed: version == null || widget.preview ? null : () => playProject(widget.project),
      disabledCursor: SystemMouseCursors.forbidden,
      semanticLabel: tr.play_project_tooltip,
      tooltip: version == null ? unavailableHint : tr.play_project_tooltip,
      borderRadius: radius,
      builder: (context, states) {
        final hover = states.active;
        return GhAnimatedBox(
          width: theme.space(9),
          height: theme.space(9),
          alignment: Alignment.center,
          color: theme.raised,
          borderRadius: radius,
          border: Border.all(color: hover ? theme.mint.withValues(alpha: 0.4) : theme.outline.withValues(alpha: 0.5)),
          child: GhIcon(GhIcons.play, size: theme.space(3), color: hover ? theme.mint : theme.muted),
        );
      },
    );
  }
}
