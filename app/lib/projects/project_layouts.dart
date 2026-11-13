import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/design.dart';
import '../logic/project_drag.dart';
import '../motion/animated_number.dart';
import '../src/rust/api/types.dart';
import '../state/drag_sort.dart';
import '../ui/controls/equal_height_row.dart';
import '../ui/core/i18n.dart';
import '../ui/dnd/sortable.dart';
import 'category_sections.dart';
import '../ui/shell/smooth_scroll.dart';
import 'project_actions.dart' show uncategorizedDot;

typedef ProjectCardBuilder = Widget Function(Project project, {bool preview});
typedef SliverHost = Widget Function(List<Widget> slivers);
typedef CategoryMenuOpener = void Function(Offset position, Category category);

const double _cardGap = 8;
const double _gridGap = 12;
const double _gridMinTile = 260;

int gridColumnsFor(double width) => math.max(1, ((width + _gridGap) / (_gridMinTile + _gridGap)).floor());

class _Grouping {
  _Grouping(List<Project> unpinned, List<Category> categories) {
    for (final p in unpinned) {
      final key = (p.category == null || p.category!.isEmpty) ? uncategorizedKey : p.category!;
      groups.putIfAbsent(key, () => []).add(p);
    }
    for (final c in categories) {
      if (groups.containsKey(c.name)) keys.add(c.name);
    }
    if (groups.containsKey(uncategorizedKey)) keys.add(uncategorizedKey);
    for (final key in groups.keys) {
      if (!keys.contains(key)) keys.add(key);
    }
  }

  final Map<String, List<Project>> groups = {};
  final List<String> keys = [];

  List<Project> operator [](String key) => groups[key] ?? const [];

  List<Project> ordered() => [for (final key in keys) ...this[key]];
}

class ProjectDndBinding {
  ProjectDndBinding(String prefix)
    : controller = ProjectDndController(
        projects: const [],
        categories: const [],
        grouped: false,
        prefixes: DroppablePrefixes(category: prefix),
      );

  final ProjectDndController controller;

  void sync({
    required List<Project> projects,
    required List<Category> categories,
    required bool grouped,
    required Set<String> selectedIds,
    ProjectReorderCallback? onReorder,
    ProjectMoveCallback? onMoveProjects,
  }) {
    controller.update(projects: projects, categories: categories, grouped: grouped, selectedIds: selectedIds);
    controller.onReorder = onReorder;
    controller.onMoveProjects = onMoveProjects;
  }

  Widget scope({required bool enabled, required Widget child, required Widget Function(Project project) overlay, String? ignorePrefix}) {
    final c = controller;
    return GhDndScope(
      enabled: enabled,
      onDragStart: c.dragStart,
      onDragCancel: c.dragCancel,
      onDragEnd: (activeId, overId) => c.dragEnd(activeId, overId),
      collisionDetection: (args) => c.detectCollisions(
        activeId: args.activeId,
        droppables: args.droppables,
        collisionRect: args.collisionRect,
        pointer: args.pointer,
      ),
      overlayCount: c.activeIds.length,
      showDropLine: true,
      dropLineIgnorePrefix: ignorePrefix,
      placement: () => c.placement,
      reflows: c.reflows,
      carriedIds: c.activeIds,
      overlayBuilder: (context, id) {
        final project = c.activeProject ?? _find(c.projects, id);
        return project == null ? const SizedBox.shrink() : overlay(project);
      },
      child: child,
    );
  }

  void dispose() => controller.dispose();
}

Project? _find(List<Project> projects, String id) {
  for (final p in projects) {
    if (p.id == id) return p;
  }
  return null;
}

Widget _sortable(ProjectDndController c, Project p, bool enabled, Widget child) {
  if (!enabled) return KeyedSubtree(key: ValueKey(p.id), child: child);
  return GhSortableItem(key: ValueKey(p.id), id: p.id, isStatic: c.activeIds.length > 1, carried: c.activeIds.contains(p.id), child: child);
}

class PinnedHeader extends StatelessWidget {
  const PinnedHeader({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(top: theme.space(1), bottom: theme.space(0.5)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: theme.space(1)),
        child: Row(
          spacing: theme.space(2),
          children: [
            GhIcon(GhIcons.pin, size: theme.space(3), color: theme.accentBright),
            Text(
              context.tr.common.pinned_section.toUpperCase(),
              style: theme.text(size: GhTextSize.x3s, weight: GhWeight.semibold, color: theme.muted, letterSpacingEm: 0.05),
            ),
            DefaultTextStyle.merge(
              style: theme
                  .text(size: GhTextSize.x3s, weight: GhWeight.medium, color: theme.muted.withValues(alpha: 0.5))
                  .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              child: Row(mainAxisSize: MainAxisSize.min, children: [const Text('· '), GhAnimatedNumber(count)]),
            ),
            Expanded(child: Container(height: 1, color: theme.outline.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: GhTheme.of(context).space(2));
  }
}

Widget _box(Widget child, {double bottom = _cardGap}) => SliverToBoxAdapter(
  child: Padding(
    padding: EdgeInsets.only(bottom: bottom),
    child: child,
  ),
);

class ProjectCardList extends StatefulWidget {
  const ProjectCardList({
    super.key,
    required this.projects,
    required this.cardBuilder,
    required this.host,
    required this.selectedIds,
    this.hasActiveFilters = false,
    this.searchActive = false,
    this.categories = const [],
    this.categoriesEnabled = false,
    this.onReorder,
    this.onReorderPinned,
    this.onMoveProjects,
    this.hiddenCategories = const [],
    this.onUnhideCategory,
    this.onCategoryContextMenu,
  });

  final List<Project> projects;
  final ProjectCardBuilder cardBuilder;
  final SliverHost host;
  final Set<String> selectedIds;
  final bool hasActiveFilters;
  final bool searchActive;
  final List<Category> categories;
  final bool categoriesEnabled;
  final ProjectReorderCallback? onReorder;
  final ProjectReorderCallback? onReorderPinned;
  final ProjectMoveCallback? onMoveProjects;
  final List<HiddenCategoryEntry> hiddenCategories;
  final ValueChanged<String>? onUnhideCategory;
  final CategoryMenuOpener? onCategoryContextMenu;

  @override
  State<ProjectCardList> createState() => _ProjectCardListState();
}

class _ProjectCardListState extends State<ProjectCardList> {
  final ProjectDndBinding _main = ProjectDndBinding('list-cat-');
  final ProjectDndBinding _pinned = ProjectDndBinding('list-pinned-cat-');

  @override
  void dispose() {
    _main.dispose();
    _pinned.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_main.controller, _pinned.controller]),
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr.common;
    final projects = widget.projects;
    final showPinned = !widget.searchActive && projects.any((p) => p.pinned);
    final pinned = showPinned
        ? [
            for (final p in projects)
              if (p.pinned) p,
          ]
        : const <Project>[];
    final unpinned = showPinned
        ? [
            for (final p in projects)
              if (!p.pinned) p,
          ]
        : projects;
    final grouped = !widget.searchActive && widget.categoriesEnabled && widget.categories.isNotEmpty;
    final grouping = _Grouping(unpinned, widget.categories);
    final sortable = grouped ? grouping.ordered() : unpinned;
    final dndEnabled = widget.onReorder != null;
    final main = _main.controller;
    _main.sync(
      projects: sortable,
      categories: widget.categories,
      grouped: grouped,
      selectedIds: widget.selectedIds,
      onReorder: widget.onReorder,
      onMoveProjects: widget.onMoveProjects,
    );
    _pinned.sync(
      projects: pinned,
      categories: widget.categories,
      grouped: false,
      selectedIds: widget.selectedIds,
      onReorder: widget.onReorderPinned,
    );

    Widget cardList(List<Project> list) => GhSortableContext(
      items: [for (final p in list) p.id],
      child: SliverList.separated(
        itemCount: list.length,
        findItemIndexCallback: (key) {
          if (key is ValueKey<String>) {
            final index = list.indexWhere((p) => p.id == key.value);
            return index < 0 ? null : index;
          }
          return null;
        },
        separatorBuilder: (context, index) => const SizedBox(height: _cardGap),
        itemBuilder: (context, index) => _sortable(main, list[index], dndEnabled, widget.cardBuilder(list[index])),
      ),
    );

    Widget section(String key, String title, {Color? color, Category? category}) {
      final list = grouping[key];
      return SliverPadding(
        padding: const EdgeInsets.only(bottom: _cardGap),
        sliver: ProjectCategorySection(
          key: ValueKey('section:$key'),
          title: title,
          color: color,
          count: list.length,
          defaultOpen: list.isNotEmpty,
          droppableId: category != null
              ? 'list-cat-${category.id}'
              : (key == uncategorizedKey ? 'list-cat-uncategorized' : 'list-cat-$key'),
          onContextMenu: category != null && widget.onCategoryContextMenu != null
              ? (position) => widget.onCategoryContextMenu!(position, category)
              : null,
          bodySlivers: [cardList(list)],
        ),
      );
    }

    final slivers = <Widget>[];
    if (projects.isEmpty) {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: theme.space(2),
              children: [
                GhIcon(GhIcons.node, size: theme.space(5), color: theme.muted.withValues(alpha: 0.5)),
                Text(
                  widget.hasActiveFilters ? tr.no_projects_match : tr.no_projects_yet,
                  style: theme.text(size: GhTextSize.sm, color: theme.muted),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      if (showPinned) {
        final pinnedIds = [for (final p in pinned) p.id];
        final pinnedEnabled = widget.onReorderPinned != null;
        final pc = _pinned.controller;
        final block = GhSortableContext(
          items: pinnedIds,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: _cardGap,
            children: [for (final p in pinned) _sortable(pc, p, pinnedEnabled, widget.cardBuilder(p))],
          ),
        );
        slivers
          ..add(_box(const _Divider()))
          ..add(_box(PinnedHeader(count: pinned.length)))
          ..add(
            _box(pinnedEnabled ? _pinned.scope(enabled: true, overlay: (p) => widget.cardBuilder(p, preview: true), child: block) : block),
          )
          ..add(_box(const _Divider()));
      }
      if (grouped) {
        for (final category in widget.categories) {
          if (main.activeId == null && hasOnlyPinnedProjects(projects, category.name)) continue;
          slivers.add(section(category.name, category.name, color: colorFromHex(category.color), category: category));
        }
        if (main.activeId != null || !hasOnlyPinnedProjects(projects, uncategorizedKey)) {
          slivers.add(section(uncategorizedKey, tr.uncategorized));
        }
        for (final key in grouping.keys) {
          if (key == uncategorizedKey || widget.categories.any((c) => c.name == key)) continue;
          slivers.add(section(key, key));
        }
      } else {
        slivers.add(
          SliverPadding(
            padding: const EdgeInsets.only(bottom: _cardGap),
            sliver: cardList(unpinned),
          ),
        );
      }
    }
    if (widget.hiddenCategories.isNotEmpty) {
      slivers.add(
        _box(
          Padding(
            padding: EdgeInsets.only(top: theme.space(3)),
            child: HiddenCategoriesSection(entries: widget.hiddenCategories, onUnhide: (id) => widget.onUnhideCategory?.call(id)),
          ),
        ),
      );
    }
    if (projects.isNotEmpty) slivers.add(SliverToBoxAdapter(child: SizedBox(height: theme.space(4))));
    final hosted = GhSortableContext(items: [for (final p in sortable) p.id], child: widget.host(slivers));
    if (!dndEnabled) return hosted;
    return _main.scope(enabled: true, ignorePrefix: 'list-cat-', overlay: (p) => widget.cardBuilder(p, preview: true), child: hosted);
  }
}

class ProjectCardGrid extends StatefulWidget {
  const ProjectCardGrid({
    super.key,
    required this.projects,
    required this.cardBuilder,
    required this.host,
    required this.selectedIds,
    this.searchActive = false,
    this.categories = const [],
    this.categoriesEnabled = false,
    this.onReorder,
    this.onReorderPinned,
    this.onMoveProjects,
    this.hiddenCategories = const [],
    this.onUnhideCategory,
    this.onCategoryContextMenu,
  });

  final List<Project> projects;
  final ProjectCardBuilder cardBuilder;
  final SliverHost host;
  final Set<String> selectedIds;
  final bool searchActive;
  final List<Category> categories;
  final bool categoriesEnabled;
  final ProjectReorderCallback? onReorder;
  final ProjectReorderCallback? onReorderPinned;
  final ProjectMoveCallback? onMoveProjects;
  final List<HiddenCategoryEntry> hiddenCategories;
  final ValueChanged<String>? onUnhideCategory;
  final CategoryMenuOpener? onCategoryContextMenu;

  @override
  State<ProjectCardGrid> createState() => _ProjectCardGridState();
}

class _ProjectCardGridState extends State<ProjectCardGrid> {
  final ProjectDndBinding _main = ProjectDndBinding('grid-cat-');
  final ProjectDndBinding _pinned = ProjectDndBinding('grid-pinned-cat-');

  @override
  void dispose() {
    _main.dispose();
    _pinned.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: Listenable.merge([_main.controller, _pinned.controller]), builder: (context, _) => _build(context));

  Widget _rows(ProjectDndController c, List<Project> list, bool enabled, {double top = 4, double bottom = 16}) {
    return GhSortableContext(
      items: [for (final p in list) p.id],
      strategy: GhSortStrategy.rect,
      child: SliverPadding(
        padding: EdgeInsets.only(top: top, bottom: bottom),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            final columns = gridColumnsFor(constraints.crossAxisExtent);
            final rows = (list.length / columns).ceil();
            return SliverList.separated(
              itemCount: rows,
              separatorBuilder: (context, index) => const SizedBox(height: _gridGap),
              itemBuilder: (context, row) {
                final start = row * columns;
                final end = math.min(start + columns, list.length);
                return GhEqualHeightRow(
                  columns: columns,
                  spacing: _gridGap,
                  children: [for (var i = start; i < end; i++) _sortable(c, list[i], enabled, widget.cardBuilder(list[i]))],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr.common;
    final projects = widget.projects;
    final grouped = widget.categoriesEnabled && widget.categories.isNotEmpty;
    final dndEnabled = widget.onReorder != null;
    final showPinned = !widget.searchActive && projects.any((p) => p.pinned);
    final pinned = showPinned
        ? [
            for (final p in projects)
              if (p.pinned) p,
          ]
        : const <Project>[];
    final unpinned = showPinned
        ? [
            for (final p in projects)
              if (!p.pinned) p,
          ]
        : projects;
    final grouping = _Grouping(unpinned, widget.categories);
    final main = _main.controller;
    _main.sync(
      projects: unpinned,
      categories: widget.categories,
      grouped: grouped,
      selectedIds: widget.selectedIds,
      onReorder: widget.onReorder,
      onMoveProjects: widget.onMoveProjects,
    );
    _pinned.sync(
      projects: pinned,
      categories: widget.categories,
      grouped: false,
      selectedIds: widget.selectedIds,
      onReorder: widget.onReorderPinned,
    );

    Widget section(String key, String title, {Color? color, Category? category, bool? defaultOpen}) {
      final list = grouping[key];
      return ProjectCategorySection(
        key: ValueKey('grid-section:$key'),
        variant: CategorySectionVariant.grid,
        title: title,
        color: color,
        count: list.length,
        defaultOpen: defaultOpen ?? list.isNotEmpty,
        droppableId: category != null ? 'grid-cat-${category.id}' : (key == uncategorizedKey ? 'grid-cat-uncategorized' : 'grid-cat-$key'),
        onContextMenu: category != null && widget.onCategoryContextMenu != null
            ? (position) => widget.onCategoryContextMenu!(position, category)
            : null,
        bodySlivers: [_rows(main, list, dndEnabled)],
      );
    }

    final slivers = <Widget>[];
    if (showPinned) {
      final pinnedEnabled = widget.onReorderPinned != null;
      final pc = _pinned.controller;
      final grid = GhSortableContext(
        items: [for (final p in pinned) p.id],
        strategy: GhSortStrategy.rect,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = gridColumnsFor(constraints.maxWidth);
              final rows = <Widget>[];
              for (var start = 0; start < pinned.length; start += columns) {
                final end = math.min(start + columns, pinned.length);
                rows.add(
                  GhEqualHeightRow(
                    columns: columns,
                    spacing: _gridGap,
                    children: [for (var i = start; i < end; i++) _sortable(pc, pinned[i], pinnedEnabled, widget.cardBuilder(pinned[i]))],
                  ),
                );
              }
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: _gridGap, children: rows);
            },
          ),
        ),
      );
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(bottom: theme.space(2)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PinnedHeader(count: pinned.length),
                if (pinnedEnabled)
                  _pinned.scope(enabled: true, overlay: (p) => widget.cardBuilder(p, preview: true), child: grid)
                else
                  grid,
                Container(
                  height: 2,
                  margin: EdgeInsets.only(top: theme.space(2)),
                  color: theme.outline,
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (grouped) {
      for (final category in widget.categories) {
        if (main.activeId == null && hasOnlyPinnedProjects(projects, category.name)) continue;
        slivers.add(section(category.name, category.name, color: colorFromHex(category.color), category: category));
      }
      for (final key in grouping.keys) {
        if (key == uncategorizedKey || widget.categories.any((c) => c.name == key)) continue;
        slivers.add(section(key, key, defaultOpen: true));
      }
      if (main.activeId != null || !hasOnlyPinnedProjects(projects, uncategorizedKey)) {
        slivers.add(section(uncategorizedKey, tr.uncategorized));
      }
    } else {
      slivers.add(_rows(main, unpinned, dndEnabled));
    }
    if (widget.hiddenCategories.isNotEmpty) {
      slivers.add(
        _box(
          HiddenCategoriesSection(entries: widget.hiddenCategories, onUnhide: (id) => widget.onUnhideCategory?.call(id)),
          bottom: theme.space(4),
        ),
      );
    }
    slivers.add(SliverToBoxAdapter(child: SizedBox(height: theme.space(4))));
    final hosted = GhSortableContext(items: [for (final p in unpinned) p.id], strategy: GhSortStrategy.rect, child: widget.host(slivers));
    if (!dndEnabled) return hosted;
    return _main.scope(enabled: true, ignorePrefix: 'grid-cat-', overlay: (p) => widget.cardBuilder(p, preview: true), child: hosted);
  }
}

class ProjectCardKanban extends StatefulWidget {
  const ProjectCardKanban({
    super.key,
    required this.projects,
    required this.categories,
    required this.cardBuilder,
    required this.selectedIds,
    this.compact = false,
    this.onReorder,
    this.onMoveProjects,
    this.hiddenCategories = const [],
    this.onUnhideCategory,
    this.onCategoryContextMenu,
  });

  final List<Project> projects;
  final List<Category> categories;
  final ProjectCardBuilder cardBuilder;
  final Set<String> selectedIds;
  final bool compact;
  final ProjectReorderCallback? onReorder;
  final ProjectMoveCallback? onMoveProjects;
  final List<HiddenCategoryEntry> hiddenCategories;
  final ValueChanged<String>? onUnhideCategory;
  final CategoryMenuOpener? onCategoryContextMenu;

  @override
  State<ProjectCardKanban> createState() => _ProjectCardKanbanState();
}

class _ProjectCardKanbanState extends State<ProjectCardKanban> {
  final ProjectDndBinding _dnd = ProjectDndBinding('kanban-cat-');
  final ScrollController _horizontal = GhSmoothScrollController();

  @override
  void dispose() {
    _dnd.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: _dnd.controller, builder: (context, _) => _build(context));

  Widget _build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr.common;
    final grouped = widget.categories.isNotEmpty;
    final groups = <String, List<Project>>{};
    for (final p in widget.projects) {
      final key = grouped ? ((p.category == null || p.category!.isEmpty) ? uncategorizedKey : p.category!) : uncategorizedKey;
      groups.putIfAbsent(key, () => []).add(p);
    }
    final sortable = grouped
        ? [
            for (final c in widget.categories) ...groups[c.name] ?? const <Project>[],
            ...groups[uncategorizedKey] ?? const <Project>[],
            for (final entry in groups.entries)
              if (entry.key != uncategorizedKey && !widget.categories.any((c) => c.name == entry.key)) ...entry.value,
          ]
        : widget.projects;
    final dndEnabled = widget.onReorder != null;
    final c = _dnd.controller;
    _dnd.sync(
      projects: sortable,
      categories: widget.categories,
      grouped: grouped,
      selectedIds: widget.selectedIds,
      onReorder: widget.onReorder,
      onMoveProjects: widget.onMoveProjects,
    );
    final columns = [
      for (final category in widget.categories)
        (
          key: category.id,
          title: category.name,
          color: colorFromHex(category.color),
          projects: groups[category.name] ?? const <Project>[],
          category: category,
        ),
      for (final entry in groups.entries)
        if (entry.key != uncategorizedKey && !widget.categories.any((cat) => cat.name == entry.key))
          (key: entry.key, title: entry.key, color: uncategorizedDot, projects: entry.value, category: null as Category?),
      (
        key: 'uncategorized',
        title: tr.uncategorized,
        color: uncategorizedDot,
        projects: groups[uncategorizedKey] ?? const <Project>[],
        category: null as Category?,
      ),
    ];
    final width = theme.space(widget.compact ? 65 : 75);
    final board = Scrollbar(
      controller: _horizontal,
      child: GhScrollView(
        controller: _horizontal,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(bottom: theme.space(4)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(4),
          children: [
            for (final column in columns)
              SizedBox(
                width: width,
                child: _KanbanColumn(
                  key: ValueKey('kanban:${column.key}'),
                  title: column.title,
                  color: column.color,
                  count: column.projects.length,
                  compact: widget.compact,
                  droppableId: 'kanban-cat-${column.key}',
                  onContextMenu: column.category != null && widget.onCategoryContextMenu != null
                      ? (position) => widget.onCategoryContextMenu!(position, column.category!)
                      : null,
                  child: GhSortableContext(
                    items: [for (final p in column.projects) p.id],
                    child: ListView.builder(
                      padding: EdgeInsets.all(theme.space(widget.compact ? 2.5 : 3)),
                      itemCount: column.projects.length,
                      itemBuilder: (context, index) {
                        final p = column.projects[index];
                        return Padding(
                          key: ValueKey(p.id),
                          padding: EdgeInsets.only(bottom: theme.space(3)),
                          child: _sortable(c, p, dndEnabled, widget.cardBuilder(p)),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    final scoped = dndEnabled
        ? _dnd.scope(enabled: true, ignorePrefix: 'kanban-cat-', overlay: (p) => widget.cardBuilder(p, preview: true), child: board)
        : board;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: scoped),
        if (widget.hiddenCategories.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: theme.space(1)),
            child: HiddenCategoriesSection(entries: widget.hiddenCategories, onUnhide: (id) => widget.onUnhideCategory?.call(id)),
          ),
      ],
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({
    super.key,
    required this.title,
    required this.color,
    required this.count,
    required this.compact,
    required this.droppableId,
    required this.child,
    this.onContextMenu,
  });

  final String title;
  final Color color;
  final int count;
  final bool compact;
  final String droppableId;
  final ValueChanged<Offset>? onContextMenu;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr.common;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onSecondaryTapUp: onContextMenu == null ? null : (details) => onContextMenu!(details.globalPosition),
          child: Padding(
            padding: EdgeInsets.only(bottom: theme.space(2), left: theme.space(1), right: theme.space(1)),
            child: Row(
              spacing: theme.space(2),
              children: [
                Container(
                  width: theme.space(2.5),
                  height: theme.space(2.5),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black.withValues(alpha: 0.2)),
                  ),
                ),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.ink),
                  ),
                ),
                Text(
                  '$count',
                  style: theme.text(size: GhTextSize.xs, color: theme.muted),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: GhDroppable(
            id: droppableId,
            builder: (context, state) => AnimatedContainer(
              duration: GhDurations.color,
              constraints: BoxConstraints(minHeight: compact ? 200 : 250),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: state.isOver ? theme.accent.withValues(alpha: 0.1) : theme.overlay.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(theme.radiusItem),
                border: Border.all(color: state.isOver ? theme.accent.withValues(alpha: 0.5) : theme.outline.withValues(alpha: 0.3)),
              ),
              child: count == 0
                  ? Center(
                      child: Text(
                        state.isOver ? tr.release_to_drop : tr.empty_category,
                        style: theme.text(
                          size: GhTextSize.xs,
                          weight: state.isOver ? GhWeight.medium : GhWeight.normal,
                          color: state.isOver ? theme.accentBright : theme.muted.withValues(alpha: 0.4),
                        ),
                      ),
                    )
                  : child,
            ),
          ),
        ),
      ],
    );
  }
}
