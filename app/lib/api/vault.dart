import '../src/rust/api/types.dart';
import '../src/rust/api/vault.dart' as rust;

abstract final class VaultApi {
  static Future<List<VaultItem>> list() => rust.listVaultItems();

  static Future<VaultItem> saveToVault(String name, String description, List<String> tags, List<VaultSaveSource> sources) =>
      rust.saveToVault(name: name, description: description, tags: tags, sources: sources);

  static Future<List<VaultProjectImportResult>> addToProjects(String itemId, List<String> projectIds, bool overwrite) =>
      rust.addVaultItemToProjects(itemId: itemId, projectIds: projectIds, overwrite: overwrite);

  static Future<void> delete(String itemId) => rust.deleteVaultItem(itemId: itemId);

  static Future<VaultItem> update(String itemId, String name, String description, List<String> tags) =>
      rust.updateVaultItem(itemId: itemId, name: name, description: description, tags: tags);
}
