import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/launch_errors.dart';
import 'package:godothub/ui/feedback/toast.dart';

void main() {
  late GhToastStore store;
  late List<GhToastItem> toasts;

  setUp(() {
    store = GhToastStore();
    toasts = [];
    store.subscribe((items) => toasts = items);
  });

  tearDown(() => store.clear());

  test('plain errors become an error toast', () {
    reportLaunchError('Project folder is missing', toasts: store);
    expect(toasts.single.type, GhToastType.error);
    expect(toasts.single.message, 'Project folder is missing');
    expect(toasts.single.action, isNull);
  });

  test('missing engine errors offer a download that reports progress and failures', () async {
    final downloads = <String>[];
    reportLaunchError(
      Exception('godot 4.3-stable mono IS NOT INSTALLED'),
      toasts: store,
      download: (tag) async {
        downloads.add(tag);
        throw 'network down';
      },
    );
    expect(toasts.single.type, GhToastType.error);
    expect(toasts.single.message, 'Exception: godot 4.3-stable mono IS NOT INSTALLED');
    expect(toasts.single.action?.label, 'Download');
    toasts.single.action!.onClick();
    expect(downloads, ['4.3-stable mono']);
    expect(toasts.last.type, GhToastType.info);
    expect(toasts.last.message, 'Downloading Godot 4.3-stable mono…');
    await Future<void>.delayed(Duration.zero);
    expect(toasts.last.type, GhToastType.error);
    expect(toasts.last.message, 'network down');
  });

  test('the download tag is the shortest match', () {
    final downloads = <String>[];
    reportLaunchError(
      'Godot 4.2 is not installed; Godot 4.3 is not installed',
      toasts: store,
      download: (tag) async => downloads.add(tag),
    );
    toasts.single.action!.onClick();
    expect(downloads, ['4.2']);
  });
}
