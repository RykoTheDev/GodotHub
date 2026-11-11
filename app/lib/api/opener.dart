import 'dart:io';

abstract final class OpenerApi {
  static Future<void> openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http') || uri.host.isEmpty) {
      throw ArgumentError.value(url, 'url', 'Only http and https links can be opened');
    }
    final target = uri.toString();
    final ProcessResult result;
    if (Platform.isWindows) {
      result = await Process.run('rundll32', ['url.dll,FileProtocolHandler', target]);
    } else if (Platform.isMacOS) {
      result = await Process.run('open', [target]);
    } else {
      result = await Process.run('xdg-open', [target]);
    }
    if (result.exitCode != 0) {
      throw ProcessException('open', [target], '${result.stderr}', result.exitCode);
    }
  }
}
