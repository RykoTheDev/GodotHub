import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../src/rust/api/app.dart' as core;

final appVersionLoaderProvider = Provider<Future<String?> Function()>((ref) => () async => core.appVersion());

final appVersionProvider = FutureProvider<String?>((ref) async {
  try {
    return await ref.watch(appVersionLoaderProvider)();
  } catch (_) {
    return null;
  }
}, retry: (_, _) => null);
