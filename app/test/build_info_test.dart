import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/build_info.dart';

void main() {
  test('lists the Flutter and Rust versions a build knows', () {
    expect(builtWithVersions(flutter: '3.50.1', rust: '1.99.1'), 'Flutter 3.50.1\nRust 1.99.1');
  });

  test('leaves out a version the build was not given', () {
    expect(builtWithVersions(flutter: '3.50.1', rust: ''), 'Flutter 3.50.1');
    expect(builtWithVersions(flutter: '', rust: '1.99.1'), 'Rust 1.99.1');
    expect(builtWithVersions(flutter: '', rust: ''), isEmpty);
  });

  test('a build made without the defines has no versions to show', () {
    expect(builtWithVersions(), isEmpty);
  });
}
