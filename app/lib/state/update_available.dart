import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/updater.dart';

@immutable
class UpdateAvailableState {
  const UpdateAvailableState({this.updateAvailable = false, this.previewUpdate = false, this.applyDownloaded});

  final bool updateAvailable;
  final bool previewUpdate;
  final Future<void> Function()? applyDownloaded;

  bool get downloaded => applyDownloaded != null;

  UpdateAvailableState copyWith({bool? updateAvailable, bool? previewUpdate}) => UpdateAvailableState(
    updateAvailable: updateAvailable ?? this.updateAvailable,
    previewUpdate: previewUpdate ?? this.previewUpdate,
    applyDownloaded: applyDownloaded,
  );

  @override
  bool operator ==(Object other) =>
      other is UpdateAvailableState &&
      other.updateAvailable == updateAvailable &&
      other.previewUpdate == previewUpdate &&
      identical(other.applyDownloaded, applyDownloaded);

  @override
  int get hashCode => Object.hash(updateAvailable, previewUpdate, applyDownloaded);
}

typedef UpdateChecker = Future<bool> Function();

final updateCheckerProvider = Provider<UpdateChecker>((ref) => UpdaterApi.isUpdateAvailable);

final updateAvailableProvider = NotifierProvider<UpdateAvailableNotifier, UpdateAvailableState>(UpdateAvailableNotifier.new);

class UpdateAvailableNotifier extends Notifier<UpdateAvailableState> {
  @override
  UpdateAvailableState build() {
    var cancelled = false;
    ref.onDispose(() => cancelled = true);
    final check = ref.read(updateCheckerProvider);
    scheduleMicrotask(() async {
      try {
        final available = await check();
        if (!cancelled && available) state = state.copyWith(updateAvailable: true);
      } catch (_) {}
    });
    return const UpdateAvailableState();
  }

  void dismissUpdate() => state = state.copyWith(updateAvailable: false);

  void markDownloaded(Future<void> Function() apply) =>
      state = UpdateAvailableState(updateAvailable: true, previewUpdate: state.previewUpdate, applyDownloaded: apply);

  void setPreviewUpdate(bool value) => state = state.copyWith(previewUpdate: value);

  void togglePreviewUpdate() => state = state.copyWith(previewUpdate: !state.previewUpdate);
}
