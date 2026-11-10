import '../src/rust/api/install_mode.dart' as rust;

abstract final class UpdatesApi {
  static Future<bool> isPortableInstall() => rust.isPortableInstall();
}
