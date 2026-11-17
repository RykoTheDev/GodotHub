import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/onyx.dart';
import '../../api/opener.dart';
import '../../design/design.dart';
import '../../logic/settings_copy.dart';
import '../../src/rust/api/types.dart';
import '../../state/settings.dart';
import '../../ui/controls/toggle.dart';
import '../../ui/core/i18n.dart';
import '../../ui/feedback/toast.dart';
import 'settings_buttons.dart';

String _ts(String key, {Map<String, Object?> args = const {}}) => ghTr('settings:$key', args: args);

/// Onyx uploads builds to Steamworks. It can only be turned on while an up-to-date
/// copy is installed; otherwise the section links to its GitHub releases.
class OnyxSetting extends ConsumerStatefulWidget {
  const OnyxSetting({super.key});

  @override
  ConsumerState<OnyxSetting> createState() => _OnyxSettingState();
}

class _OnyxSettingState extends ConsumerState<OnyxSetting> {
  OnyxStatus? _status;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() => _checking = true);
    OnyxApi.status()
        .then(
          (status) {
            if (mounted) setState(() => _status = status);
          },
          onError: (Object _) {
            if (mounted) setState(() => _status = null);
          },
        )
        .whenComplete(() {
          if (mounted) setState(() => _checking = false);
        });
  }

  String _message(OnyxStatus status) {
    final version = status.version;
    if (status.path == null) return _ts('onyx_not_installed');
    if (version == null) return _ts('onyx_too_old');
    if (!status.upToDate) return _ts('onyx_outdated', args: {'version': version, 'latest': status.latest ?? ''});
    return _ts('onyx_detected', args: {'version': version});
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final settings = ref.watch(settingsProvider).value;
    if (settings == null) return const SizedBox.shrink();
    final status = _status;
    final help = theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625);
    if (status != null && !status.supported) return Text(_ts('onyx_unavailable_mac'), style: help);
    final ready = status != null && status.upToDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: theme.space(2.5),
      children: [
        GhToggle(
          checked: settings.onyxEnabled,
          label: _ts('onyx_label'),
          // Turning it off always works; turning it on needs a current install.
          onChanged: ready || settings.onyxEnabled
              ? (checked) => ref.read(settingsProvider.notifier).save(copySettings(settings, onyxEnabled: checked)).ignore()
              : null,
        ),
        Text(_ts('onyx_desc'), style: help),
        Text(
          _checking || status == null ? _ts('onyx_checking') : _message(status),
          style: theme.text(size: GhTextSize.x2s, weight: GhWeight.medium, color: ready ? theme.mint : theme.muted),
        ),
        Row(
          spacing: theme.space(2),
          children: [
            if (status != null && !ready)
              SettingsButton(
                onPressed: () =>
                    OpenerApi.openUrl(status.releasesUrl).catchError((Object e) => ghToasts.pushToast(GhToastType.error, '$e')),
                icon: GhIcons.externalLink,
                label: _ts(status.path == null ? 'onyx_download' : 'onyx_update'),
                tone: SettingsButtonTone.accent,
                compact: true,
              ),
            SettingsButton(
              onPressed: _checking ? null : _refresh,
              icon: GhIcons.refresh,
              label: _ts('onyx_check_again'),
              tone: SettingsButtonTone.quiet,
              compact: true,
            ),
          ],
        ),
      ],
    );
  }
}
