import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/project_drag.dart';
import 'package:godothub/motion/drag_feel.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/state/drag_sort.dart';
import 'package:godothub/ui/feedback/toast.dart';

Project _p(String id, [String? category]) => Project(
  id: id,
  name: id,
  path: '/projects/$id',
  godotVersion: '4.3',
  createdAt: '2026-01-01',
  category: category,
  pinned: false,
  sortOrder: 0,
  launchArguments: '',
  tags: const [],
  totalTimeSeconds: BigInt.zero,
  timeTodaySeconds: BigInt.zero,
  timeWeekSeconds: BigInt.zero,
);

Category _cat(String name) => Category(id: name, name: name, sortOrder: 0, color: '#fff', hidden: false, folders: const []);

const _prefixes = DroppablePrefixes(category: 'cat:');

DroppableRect _rect(String id, double left, double top, double width, double height) =>
    DroppableRect(id, Rect.fromLTWH(left, top, width, height));

void main() {
  test('arrayMove matches dnd-kit', () {
    expect(arrayMove(['a', 'b', 'c', 'd'], 0, 2), ['b', 'c', 'a', 'd']);
    expect(arrayMove(['a', 'b', 'c', 'd'], 3, 0), ['d', 'a', 'b', 'c']);
    expect(arrayMove(['a', 'b', 'c'], 0, -1), ['b', 'a', 'c']);
  });

  test('activation distance uses the shared drag feel', () {
    expect(passesActivationDistance(const Offset(4, 5)), isFalse);
    expect(passesActivationDistance(const Offset(GhDragFeel.activationDistance, 0)), isTrue);
    expect(passesActivationDistance(const Offset(3, 3), 4), isTrue);
  });

  group('SortableListController', () {
    test('tracks the active item and reorders on a drop over another item', () {
      final calls = <(List<String>, String, String)>[];
      final sortable = SortableListController<String>(
        items: ['a', 'b', 'c'],
        getId: (item) => item,
        onReorder: (ids, active, over) => calls.add((ids, active, over)),
      );
      var notified = 0;
      sortable.addListener(() => notified++);
      sortable.dragStart('a');
      expect(sortable.activeItem, 'a');
      expect(sortable.dragging, isTrue);
      sortable.dragEnd('a', 'c');
      expect(sortable.activeId, isNull);
      expect(calls.single.$1, ['b', 'c', 'a']);
      expect((calls.single.$2, calls.single.$3), ('a', 'c'));

      sortable.dragStart('b');
      sortable.dragEnd('b', 'b');
      sortable.dragEnd('b', null);
      sortable.dragEnd('b', 'zzz');
      sortable.dragStart('b');
      sortable.dragCancel();
      expect(calls, hasLength(1));
      expect(sortable.activeItem, isNull);
      expect(notified, greaterThan(5));
    });
  });

  group('collision helpers', () {
    final a = _rect('a', 0, 0, 100, 50);
    final b = _rect('b', 0, 60, 100, 50);

    test('pointerWithin, closestCenter and rectIntersection rank like dnd-kit', () {
      expect(pointerWithin(const Offset(10, 10), [a, b]).map((d) => d.id), ['a']);
      expect(pointerWithin(const Offset(10, 55), [a, b]), isEmpty);
      expect(closestCenter(const Rect.fromLTWH(0, 70, 100, 50), [a, b]).map((d) => d.id), ['b', 'a']);
      expect(rectIntersection(const Rect.fromLTWH(0, 40, 100, 50), [a, b]).map((d) => d.id), ['b', 'a']);
      expect(rectIntersection(const Rect.fromLTWH(500, 500, 10, 10), [a, b]), isEmpty);
    });

    test('project collisions allow the gaps between cards and fall back to zones', () {
      final zone = _rect('cat:X', 0, 0, 120, 400);
      final far = _rect('far', 300, 0, 100, 50);
      final drop = [a, b, zone, far];
      const collision = Rect.fromLTWH(0, 20, 100, 50);
      expect(detectProjectCollisions(categoryPrefix: 'cat:', droppables: drop, collisionRect: collision, pointer: const Offset(10, 20)).first.id, 'a');
      expect(detectProjectCollisions(categoryPrefix: 'cat:', droppables: drop, collisionRect: collision, pointer: const Offset(10, 55)).first.id, 'a');
      expect(detectProjectCollisions(categoryPrefix: 'cat:', droppables: drop, collisionRect: collision, pointer: const Offset(10, 300)).single.id, 'cat:X');
      expect(detectProjectCollisions(categoryPrefix: 'cat:', droppables: [a, far], collisionRect: collision, pointer: const Offset(200, 20)), isEmpty);
      expect(detectProjectCollisions(categoryPrefix: 'cat:', droppables: drop, collisionRect: collision).first.id, 'a');
      expect(
        detectProjectCollisions(categoryPrefix: 'cat:', droppables: [zone], collisionRect: const Rect.fromLTWH(10, 10, 10, 10)).single.id,
        'cat:X',
      );
    });
  });

  group('ProjectDndController', () {
    final projects = [_p('a', 'X'), _p('b', 'X'), _p('c', 'Y')];
    final categories = [_cat('X'), _cat('Y')];

    ProjectDndController controller({Set<String>? selected, ProjectReorderCallback? onReorder, ProjectMoveCallback? onMove, bool grouped = true}) =>
        ProjectDndController(
          projects: projects,
          categories: categories,
          grouped: grouped,
          prefixes: _prefixes,
          selectedIds: selected,
          onReorder: onReorder,
          onMoveProjects: onMove,
        );

    test('drag start carries the selection only when it includes the dragged card', () {
      final dnd = controller(selected: {'a', 'c'});
      dnd.dragStart('a');
      expect(dnd.activeIds, ['a', 'c']);
      expect(dnd.activeProject?.id, 'a');
      expect(dnd.reflows('a', 'b'), isFalse);
      dnd.dragCancel();
      expect(dnd.dragging, isFalse);
      dnd.dragStart('b');
      expect(dnd.activeIds, ['b']);
      expect(controller(selected: {'a', 'zzz'})..dragStart('a'), isA<ProjectDndController>().having((d) => d.activeIds, 'ids', ['a']));
    });

    test('placement follows list order in a category, else the pointer half', () {
      final dnd = controller();
      dnd.dragStart('a');
      expect(dnd.placementFor(activeId: 'a', overId: 'b'), DropPlacement.after);
      expect(dnd.placementFor(activeId: 'b', overId: 'a'), DropPlacement.before);
      const rect = Rect.fromLTWH(0, 100, 100, 50);
      expect(dnd.placementFor(activeId: 'a', overId: 'c', overRect: rect, pointerY: 140), DropPlacement.after);
      expect(dnd.placementFor(activeId: 'a', overId: 'c', overRect: rect, pointerY: 110), DropPlacement.before);
      expect(
        dnd.placementFor(activeId: 'a', overId: 'cat:Y', overRect: rect, collisionRect: const Rect.fromLTWH(0, 120, 10, 40)),
        DropPlacement.after,
      );
      expect(dnd.reflows('a', 'b'), isTrue);
      expect(dnd.reflows('a', 'c'), isFalse);
      expect(controller(grouped: false).reflows('a', 'c'), isTrue);

      dnd.detectCollisions(
        activeId: 'a',
        droppables: [_rect('c', 0, 100, 100, 50)],
        collisionRect: const Rect.fromLTWH(0, 120, 100, 50),
        pointer: const Offset(10, 140),
      );
      expect(dnd.placement, DropPlacement.after);
    });

    test('drop resolves through project_drag and calls reorder or move', () async {
      final reorders = <List<String>>[];
      final moves = <(List<String>, String, List<String>)>[];
      final dnd = controller(onReorder: reorders.add, onMove: (ids, category, dest) => moves.add((ids, category, dest)));

      dnd.dragStart('a');
      dnd.placement = DropPlacement.after;
      expect(await dnd.dragEnd('a', 'b'), const ProjectDropReorder(['b', 'a']));
      expect(reorders.single, ['b', 'a']);

      dnd.dragStart('a');
      final moved = await dnd.dragEnd('a', 'cat:Y');
      expect(moved, isA<ProjectDropMove>());
      expect(moves.single.$2, 'Y');

      dnd.dragStart('a');
      expect(await dnd.dragEnd('a', null), const ProjectDropNone());
    });

    test('a failing callback raises an error toast', () async {
      final toasts = <GhToastItem>[];
      final unsubscribe = subscribeToasts((items) => toasts
        ..clear()
        ..addAll(items));
      addTearDown(unsubscribe);
      final dnd = controller(onReorder: (_) => throw StateError('save failed'));
      dnd.dragStart('a');
      dnd.placement = DropPlacement.after;
      await dnd.dragEnd('a', 'b');
      expect(toasts.last.type, GhToastType.error);
      expect(toasts.last.message, contains('save failed'));
    });
  });
}
