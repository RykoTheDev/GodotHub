import '../src/rust/api/categories.dart' as rust;
import '../src/rust/api/types.dart';

abstract final class CategoriesApi {
  static Future<List<Category>> list() => rust.listCategories();

  static Future<Category> create(String name, [String? color]) => rust.createCategory(name: name, color: color);

  static Future<Category> rename(String id, String name) => rust.renameCategory(id: id, name: name);

  static Future<Category> update(String id, [String? name, String? color, bool? hidden]) =>
      rust.updateCategory(id: id, name: name, color: color, hidden: hidden);

  static Future<void> delete(String id) => rust.deleteCategory(id: id);

  static Future<void> reorder(List<String> orderedIds) => rust.reorderCategories(orderedIds: orderedIds);

  static Future<Category> addFolder(String id, String folder) => rust.addCategoryFolder(id: id, folder: folder);

  static Future<Category> removeFolder(String id, String folder) => rust.removeCategoryFolder(id: id, folder: folder);
}
