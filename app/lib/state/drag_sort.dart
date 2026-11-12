import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart' hide Category;

import '../logic/project_drag.dart';
import '../motion/drag_feel.dart';
import '../src/rust/api/types.dart';
import '../ui/feedback/toast.dart';

List<T> arrayMove<T>(List<T> items, int from, int to) {
  final next = [...items];
  final item = next.removeAt(from);
  next.insert((to < 0 ? next.length + to : to).clamp(0, next.length), item);
  return next;
}

bool passesActivationDistance(Offset delta, [double distance = GhDragFeel.activationDistance]) =>
    math.sqrt(delta.dx * delta.dx + delta.dy * delta.dy) >= distance;

class SortableListController<T> extends ChangeNotifier {
  SortableListController({required List<T> items, required this.getId, required this.onReorder}) {
    _items = items;
  }

  late List<T> _items;
  final String Function(T item) getId;
  void Function(List<String> orderedIds, String activeId, String overId) onReorder;
  String? _activeId;

  List<T> get items => _items;

  set items(List<T> value) {
    _items = value;
    notifyListeners();
  }

  List<String> get ids => [for (final item in _items) getId(item)];

  String? get activeId => _activeId;

  bool get dragging => _activeId != null;

  T? get activeItem {
    final id = _activeId;
    if (id == null) return null;
    for (final item in _items) {
      if (getId(item) == id) return item;
    }
    return null;
  }

  void dragStart(String id) {
    _activeId = id;
    notifyListeners();
  }

  void dragCancel() {
    _activeId = null;
    notifyListeners();
  }

  void dragEnd(String activeId, String? overId) {
    _activeId = null;
    notifyListeners();
    if (overId == null || activeId == overId) return;
    final current = ids;
    final from = current.indexOf(activeId);
    final to = current.indexOf(overId);
    if (from == -1 || to == -1) return;
    onReorder(arrayMove(current, from, to), activeId, overId);
  }
}

@immutable
class DroppableRect {
  const DroppableRect(this.id, this.rect);

  final String id;
  final Rect rect;
}

double _distance(Offset a, Offset b) => (a - b).distance;

List<DroppableRect> closestCenter(Rect collisionRect, List<DroppableRect> droppables) {
  final center = collisionRect.center;
  final scored = [for (final d in droppables) (d, _distance(center, d.rect.center))];
  scored.sort((a, b) => a.$2.compareTo(b.$2));
  return [for (final entry in scored) entry.$1];
}

bool _contains(Rect rect, Offset point) =>
    point.dx >= rect.left && point.dx <= rect.right && point.dy >= rect.top && point.dy <= rect.bottom;

List<DroppableRect> pointerWithin(Offset pointer, List<DroppableRect> droppables) {
  final scored = <(DroppableRect, double)>[];
  for (final d in droppables) {
    if (!_contains(d.rect, pointer)) continue;
    final r = d.rect;
    final corners = [r.topLeft, r.topRight, r.bottomLeft, r.bottomRight];
    final total = corners.fold<double>(0, (sum, corner) => sum + _distance(pointer, corner));
    scored.add((d, total / 4));
  }
  scored.sort((a, b) => a.$2.compareTo(b.$2));
  return [for (final entry in scored) entry.$1];
}

List<DroppableRect> rectIntersection(Rect collisionRect, List<DroppableRect> droppables) {
  final scored = <(DroppableRect, double)>[];
  for (final d in droppables) {
    final left = math.max(d.rect.left, collisionRect.left);
    final top = math.max(d.rect.top, collisionRect.top);
    final right = math.min(d.rect.right, collisionRect.right);
    final bottom = math.min(d.rect.bottom, collisionRect.bottom);
    if (left >= right || top >= bottom) continue;
    final intersection = (right - left) * (bottom - top);
    final ratio = intersection / (d.rect.width * d.rect.height + collisionRect.width * collisionRect.height - intersection);
    if (ratio > 0) scored.add((d, ratio));
  }
  scored.sort((a, b) => b.$2.compareTo(a.$2));
  return [for (final entry in scored) entry.$1];
}

const projectDropGapSlop = 12.0;

List<DroppableRect> detectProjectCollisions({
  required String categoryPrefix,
  required List<DroppableRect> droppables,
  required Rect collisionRect,
  Offset? pointer,
}) {
  final zones = droppables.where((d) => d.id.startsWith(categoryPrefix)).toList();
  final cards = droppables.where((d) => !d.id.startsWith(categoryPrefix)).toList();
  if (pointer == null) {
    final cardHits = rectIntersection(collisionRect, cards);
    if (cardHits.isNotEmpty) return cardHits;
    final zoneHits = rectIntersection(collisionRect, zones);
    return zoneHits.isNotEmpty ? zoneHits : closestCenter(collisionRect, cards);
  }
  final hits = pointerWithin(pointer, cards);
  if (hits.isNotEmpty) return hits;
  final zoneHits = pointerWithin(pointer, zones);
  if (zoneHits.isNotEmpty) {
    final zone = zoneHits.first.rect;
    final inside = cards
        .where((c) => c.rect.top >= zone.top && c.rect.bottom <= zone.bottom && c.rect.left >= zone.left && c.rect.right <= zone.right)
        .toList();
    final betweenCards = inside.any(
      (c) => pointer.dy >= c.rect.top - projectDropGapSlop && pointer.dy <= c.rect.bottom + projectDropGapSlop,
    );
    return betweenCards ? closestCenter(collisionRect, inside) : zoneHits;
  }
  final nearby = cards
      .where(
        (c) =>
            pointer.dx >= c.rect.left &&
            pointer.dx <= c.rect.right &&
            pointer.dy >= c.rect.top - projectDropGapSlop &&
            pointer.dy <= c.rect.bottom + projectDropGapSlop,
      )
      .toList();
  return closestCenter(collisionRect, nearby);
}

typedef ProjectReorderCallback = FutureOr<void> Function(List<String> orderedIds);
typedef ProjectMoveCallback = FutureOr<void> Function(List<String> ids, String category, List<String> destOrderedIds);

class ProjectDndController extends ChangeNotifier {
  ProjectDndController({
    required List<Project> projects,
    required List<Category> categories,
    required this.grouped,
    required this.prefixes,
    this.selectedIds,
    this.onReorder,
    this.onMoveProjects,
  }) {
    _projects = projects;
    _categories = categories;
  }

  late List<Project> _projects;
  late List<Category> _categories;
  bool grouped;
  DroppablePrefixes prefixes;
  Set<String>? selectedIds;
  ProjectReorderCallback? onReorder;
  ProjectMoveCallback? onMoveProjects;

  List<String> _activeIds = const [];
  String? _activeId;
  DropPlacement placement = DropPlacement.before;

  List<Project> get projects => _projects;

  List<Category> get categories => _categories;

  void update({
    List<Project>? projects,
    List<Category>? categories,
    bool? grouped,
    DroppablePrefixes? prefixes,
    Set<String>? selectedIds,
    ProjectReorderCallback? onReorder,
    ProjectMoveCallback? onMoveProjects,
  }) {
    if (projects != null) _projects = projects;
    if (categories != null) _categories = categories;
    if (grouped != null) this.grouped = grouped;
    if (prefixes != null) this.prefixes = prefixes;
    if (selectedIds != null) this.selectedIds = selectedIds;
    if (onReorder != null) this.onReorder = onReorder;
    if (onMoveProjects != null) this.onMoveProjects = onMoveProjects;
  }

  String? get activeId => _activeId;

  List<String> get activeIds => _activeIds;

  bool get dragging => _activeIds.isNotEmpty;

  Project? _byId(String? id) {
    if (id == null) return null;
    for (final project in _projects) {
      if (project.id == id) return project;
    }
    return null;
  }

  Project? get activeProject => _byId(_activeId);

  void dragStart(String id) {
    _activeId = id;
    final draggable = {for (final p in _projects) p.id};
    final selected = selectedIds;
    final carriesSelection = selected != null && selected.length > 1 && selected.contains(id) && selected.every(draggable.contains);
    _activeIds = carriesSelection
        ? [
            for (final p in _projects)
              if (selected.contains(p.id)) p.id,
          ]
        : [id];
    notifyListeners();
  }

  DropPlacement placementFor({required String activeId, required String? overId, Rect? overRect, double? pointerY, Rect? collisionRect}) {
    final dragged = _byId(activeId);
    final over = _byId(overId);
    if (dragged != null && over != null && _activeIds.length <= 1 && (!grouped || categoryKeyOf(dragged) == categoryKeyOf(over))) {
      return _projects.indexOf(dragged) < _projects.indexOf(over) ? DropPlacement.after : DropPlacement.before;
    }
    if (overRect != null) {
      final y = pointerY ?? (collisionRect == null ? overRect.center.dy : collisionRect.top + collisionRect.height / 2);
      return y > overRect.top + overRect.height / 2 ? DropPlacement.after : DropPlacement.before;
    }
    return DropPlacement.before;
  }

  List<DroppableRect> detectCollisions({
    required String activeId,
    required List<DroppableRect> droppables,
    required Rect collisionRect,
    Offset? pointer,
  }) {
    final hits = detectProjectCollisions(
      categoryPrefix: prefixes.category,
      droppables: droppables,
      collisionRect: collisionRect,
      pointer: pointer,
    );
    final target = hits.isEmpty ? null : hits.first;
    placement = placementFor(
      activeId: activeId,
      overId: target?.id,
      overRect: target?.rect,
      pointerY: pointer?.dy,
      collisionRect: collisionRect,
    );
    return hits;
  }

  void _reset() {
    _activeIds = const [];
    _activeId = null;
    notifyListeners();
  }

  void dragCancel() => _reset();

  Future<ProjectDropResolution> dragEnd(String activeId, String? overId) async {
    final group = _activeIds.isNotEmpty ? _activeIds : [activeId];
    _reset();
    if (overId == null) return const ProjectDropNone();
    final resolution = resolveProjectDrop(
      ProjectDropInput(
        activeId: activeId,
        activeIds: group,
        overId: overId,
        projects: _projects,
        categories: _categories,
        grouped: grouped,
        prefixes: prefixes,
        placement: placement,
      ),
    );
    try {
      switch (resolution) {
        case ProjectDropReorder(:final orderedIds):
          await onReorder?.call(orderedIds);
        case ProjectDropMove(:final activeIds, :final categoryName, :final destOrderedIds):
          await onMoveProjects?.call(activeIds, categoryName, destOrderedIds);
        case ProjectDropNone():
          break;
      }
    } catch (error) {
      pushToast(GhToastType.error, '$error');
    }
    return resolution;
  }

  bool reflows(String dragId, String overId) {
    if (_activeIds.length > 1) return false;
    final dragged = _byId(dragId);
    final over = _byId(overId);
    if (dragged == null || over == null) return false;
    return !grouped || categoryKeyOf(dragged) == categoryKeyOf(over);
  }
}
