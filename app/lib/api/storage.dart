import '../src/rust/api/dto.dart' as dto;
import '../src/rust/api/storage.dart' as rust;
import '../src/rust/api/types.dart' as types;

abstract final class StorageApi {
  static Future<types.StorageReport> report() => rust.getStorageReport();

  static Future<types.ReclaimResult> reclaim(List<dto.ReclaimItem> items) => dto.reclaimStorage(items: items);
}
