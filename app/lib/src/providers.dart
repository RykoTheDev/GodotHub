import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'rust/api/cli_shim.dart' as cli;
import 'rust/api/types.dart';

export '../state/settings.dart' show SettingsNotifier, defaultSettings, settingsLoadedProvider, settingsProvider;

final cliToolStatusProvider = FutureProvider<CliToolStatus>((ref) => cli.cliToolStatus());

final cliToolActionsProvider = Provider<CliToolActions>((ref) => CliToolActions(ref));

class CliToolActions {
  CliToolActions(this._ref);

  final Ref _ref;

  Future<void> install() async {
    await cli.installCliTool();
    _ref.invalidate(cliToolStatusProvider);
  }

  Future<void> uninstall() async {
    await cli.uninstallCliTool();
    _ref.invalidate(cliToolStatusProvider);
  }
}
