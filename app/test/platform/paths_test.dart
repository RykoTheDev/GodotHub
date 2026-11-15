import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dart:io reads and lists files in long non-ASCII paths with spaces', () {
    final root = Directory.systemTemp.createTempSync('godothub-paths-');
    addTearDown(() => root.deleteSync(recursive: true));
    var dir = '${root.path}${Platform.pathSeparator}Ünïcödé Üser 名前 Ряко';
    while (dir.length < 300) {
      dir = '$dir${Platform.pathSeparator}a folder with spaces ñ';
    }
    final project = Directory('$dir${Platform.pathSeparator}My Gämé 🎮')..createSync(recursive: true);
    final file = File('${project.path}${Platform.pathSeparator}project.godot')..writeAsStringSync('config/name="Gämé"');
    expect(project.path.length, greaterThan(260));
    expect(file.readAsStringSync(), 'config/name="Gämé"');
    expect(file.statSync().size, greaterThan(0));
    expect(file.existsSync(), isTrue);
  });
}
