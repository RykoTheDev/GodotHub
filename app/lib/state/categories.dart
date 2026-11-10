import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/categories.dart';
import '../src/rust/api/types.dart';
import 'api_data.dart';
import 'workspaces.dart';

final categoriesProvider = NotifierProvider<CategoriesNotifier, ApiData<List<Category>>>(CategoriesNotifier.new);

Category copyCategory(Category c, {bool? hidden}) => Category(
  id: c.id,
  name: c.name,
  sortOrder: c.sortOrder,
  color: c.color,
  hidden: hidden ?? c.hidden,
  folders: c.folders,
);

class CategoriesNotifier extends ApiDataNotifier<List<Category>> {
  @override
  List<Category> get initial => const [];

  @override
  Future<List<Category>> fetch() => CategoriesApi.list();

  @override
  void setup() => ref.watch(activeWorkspaceIdProvider);

  List<Category> get categories => state.data;

  Future<Category> create(String name, [String? color]) async {
    final category = await CategoriesApi.create(name, color);
    await refresh();
    return category;
  }

  Future<void> rename(String id, String name) async {
    await CategoriesApi.rename(id, name);
    await refresh();
  }

  Future<Category> update(String id, [String? name, String? color, bool? hidden]) async {
    final result = await CategoriesApi.update(id, name, color, hidden);
    await refresh();
    return result;
  }

  Future<void> setHidden(String id, bool hidden) async {
    setData((prev) => [for (final c in prev) c.id == id ? copyCategory(c, hidden: hidden) : c]);
    try {
      await CategoriesApi.update(id, null, null, hidden);
    } finally {
      await refresh();
    }
  }

  Future<void> remove(String id) async {
    await CategoriesApi.delete(id);
    await refresh();
  }

  Future<void> reorder(List<String> orderedIds) async {
    final rank = {for (var i = 0; i < orderedIds.length; i++) orderedIds[i]: i};
    setData((prev) {
      final indexed = [for (var i = 0; i < prev.length; i++) (i, prev[i])];
      indexed.sort((a, b) {
        final byRank = (rank[a.$2.id] ?? 0) - (rank[b.$2.id] ?? 0);
        return byRank != 0 ? byRank : a.$1 - b.$1;
      });
      return [for (final entry in indexed) entry.$2];
    });
    await CategoriesApi.reorder(orderedIds);
  }

  Future<Category> assignFolder(String id, String folder) async {
    final updated = await CategoriesApi.addFolder(id, folder);
    await refresh();
    return updated;
  }

  Future<Category> unassignFolder(String id, String folder) async {
    final updated = await CategoriesApi.removeFolder(id, folder);
    await refresh();
    return updated;
  }
}
