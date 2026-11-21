import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/build_info.dart';

void main() {
  test('lists the Flutter and Rust versions a build knows', () {
    expect(builtWithVersions(flutter: '3.50.1', rust: '1.99.1'), 'Flutter 3.50.1\nRust 1.99.1');
  });

  test('leaves out a version the build was not given', () {
    expect(builtWithVersions(flutter: '3.50.1', rust: ''), 'Flutter 3.50.1');
    expect(builtWithVersions(flutter: '', rust: '1.99.1'), 'Rust 1.99.1');
  });

  test('a release build without the defines shows no tooltip', () {
    expect(builtWithVersions(flutter: '', rust: '', release: true), isEmpty);
  });

  test('a development build without the defines says how to see the versions', () {
    final message = builtWithVersions(flutter: '', rust: '', release: false);
    expect(message, contains('development build'));
    expect(message, contains('FLUTTER_BUILD_VERSION'));
    expect(message, contains('RUST_BUILD_VERSION'));
  });

  test('versions win over the development message', () {
    expect(builtWithVersions(flutter: '3.50.1', rust: '1.99.1', release: false), 'Flutter 3.50.1\nRust 1.99.1');
  });
}
