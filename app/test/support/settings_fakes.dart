import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/state/settings.dart';

class FakeSettingsNotifier extends SettingsNotifier {
  FakeSettingsNotifier(this._load, {this.onSave});

  final FutureOr<AppSettings> Function() _load;
  final FutureOr<AppSettings> Function(AppSettings next)? onSave;

  @override
  Future<AppSettings> build() async => _load();

  @override
  Future<AppSettings> save(AppSettings next) async {
    state = AsyncData(next);
    final save = onSave;
    final saved = save == null ? next : await save(next);
    state = AsyncData(saved);
    return saved;
  }
}

Override fakeSettings(
  FutureOr<AppSettings> Function() load, {
  FutureOr<AppSettings> Function(AppSettings next)? onSave,
}) => settingsProvider.overrideWith(() => FakeSettingsNotifier(load, onSave: onSave));
