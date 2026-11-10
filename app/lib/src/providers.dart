import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'rust/api/core.dart' as core;

final settingsJsonProvider = FutureProvider<String>((ref) => core.getSettingsJson());

final cliToolStatusProvider = FutureProvider<String>((ref) => core.cliToolStatusJson());

final cliToolActionsProvider = Provider<CliToolActions>((ref) => CliToolActions(ref));

class CliToolActions {
  CliToolActions(this._ref);

  final Ref _ref;

  Future<void> install() async {
    await core.installCliToolJson();
    _ref.invalidate(cliToolStatusProvider);
  }

  Future<void> uninstall() async {
    await core.uninstallCliToolJson();
    _ref.invalidate(cliToolStatusProvider);
  }
}
