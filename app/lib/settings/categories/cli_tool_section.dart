import 'package:flutter/widgets.dart';

import '../../api/api.dart';
import '../../design/design.dart';
import '../../src/rust/api/types.dart';
import '../../ui/core/i18n.dart';
import '../settings_parts.dart';
import 'settings_option_controls.dart';

String _ts(String key, {num? count, Map<String, Object?> args = const {}}) => settingsTr(key, count: count, args: args);

final _pathSeparator = RegExp(r'[/\\]');
final _extension = RegExp(r'\.[^.]*$');
const _defaultShimName = 'godothub';

String cliShimName(CliToolStatus status) {
  final file = status.shimPath.split(_pathSeparator).where((part) => part.isNotEmpty).lastOrNull ?? '';
  final name = file.replaceFirst(_extension, '');
  return name.isEmpty ? _defaultShimName : name;
}

String cliChannelMessage(String message, CliToolStatus status) {
  final name = cliShimName(status);
  return name == _defaultShimName ? message : message.replaceAll(_defaultShimName, name);
}

class CliToolSection extends StatefulWidget {
  const CliToolSection({super.key});

  @override
  State<CliToolSection> createState() => _CliToolSectionState();
}

class _CliToolSectionState extends State<CliToolSection> {
  CliToolStatus? _status;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    Api.cliToolStatus().then((status) {
      if (mounted) setState(() => _status = status);
    }, onError: (Object _) {});
  }

  Future<void> _run(Future<CliToolStatus> Function() action, String messageKey) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final status = await action();
      if (!mounted) return;
      setState(() {
        _status = status;
        _message = cliChannelMessage(_ts(messageKey), status);
      });
    } catch (e) {
      if (mounted) setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final installed = _status?.installed ?? false;
    final message = _message;
    final label = _busy ? _ts('cli_tool_installing') : (installed ? ghTr('version_uninstall_confirm') : _ts('cli_tool_install'));
    return SettingsSubsection(
      id: 'integrations-cli',
      title: _ts('cli_tool_title'),
      searchText: _ts('cli_tool_title'),
      child: Row(
        spacing: theme.space(3),
        children: [
          SettingsOutlineButton(
            label: label,
            paddingX: 4,
            onPressed: _busy
                ? null
                : () => installed
                      ? _run(Api.uninstallCliTool, 'cli_tool_uninstalled_msg')
                      : _run(Api.installCliTool, 'cli_tool_installed_msg'),
          ),
          if (message != null)
            Flexible(
              child: Text(
                message,
                style: theme.text(size: GhTextSize.xs, color: theme.muted),
              ),
            ),
        ],
      ),
    );
  }
}
