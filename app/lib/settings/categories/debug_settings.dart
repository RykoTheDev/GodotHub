import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../api/settings.dart';
import '../../api/updater.dart';
import '../../design/design.dart';
import '../../logic/debug_mode.dart';
import '../../logic/settings_copy.dart';
import '../../shell/sidebar_prefs.dart';
import '../../src/channel.dart';
import '../../src/rust/api/app.dart' as app_rust;
import '../../src/ui_prefs.dart';
import '../../state/app_signals.dart';
import '../../state/app_version.dart';
import '../../state/settings.dart';
import '../../state/shell_signals.dart';
import '../../state/update_available.dart';
import '../../ui/core/interaction.dart';
import '../../ui/feedback/toast.dart';

typedef BetaReimporter = Future<app_rust.BetaImport> Function();

class DebugSettings extends ConsumerStatefulWidget {
  const DebugSettings({super.key, this.channel = buildChannel, this.reimport});

  final String channel;
  final BetaReimporter? reimport;

  @visibleForTesting
  static Future<void> Function()? debugRelaunch;

  @override
  ConsumerState<DebugSettings> createState() => _DebugSettingsState();
}

class _DebugSettingsState extends ConsumerState<DebugSettings> {
  bool _crash = false;
  bool _confirmWipe = false;
  bool _confirmReimport = false;
  bool _reimporting = false;

  Future<void> _relaunch() => (DebugSettings.debugRelaunch ?? Api.relaunch)();

  void _toast(GhToastType type, String message) => ghToasts.pushToast(type, message);

  Future<Object?> _settingsJson() async {
    final dir = await Directory.systemTemp.createTemp('godothub-debug-');
    try {
      final file = File('${dir.path}${Platform.pathSeparator}settings.json');
      await SettingsApi.exportSettings(file.path);
      if (!await file.exists()) return null;
      return jsonDecode(await file.readAsString());
    } catch (_) {
      return null;
    } finally {
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    }
  }

  Future<void> _copyDebugInfo() async {
    final view = View.of(context);
    final size = view.physicalSize / view.devicePixelRatio;
    final ratio = view.devicePixelRatio;
    final appVersion = ref.read(appVersionProvider).value;
    try {
      final info = {
        'app_version': appVersion,
        'user_agent':
            'Flutter on ${Platform.operatingSystem} ${Platform.operatingSystemVersion}, Dart ${Platform.version.split(' ').first}',
        'language': Platform.localeName,
        'window': '${size.width.round()}x${size.height.round()} @${ratio % 1 == 0 ? ratio.toInt() : ratio}x',
        'settings': await _settingsJson(),
      };
      await Clipboard.setData(ClipboardData(text: const JsonEncoder.withIndent('  ').convert(info)));
      _toast(GhToastType.success, 'Debug info copied to clipboard');
    } catch (e) {
      _toast(GhToastType.error, 'Could not copy debug info: $e');
    }
  }

  Future<void> _wipeAppData() async {
    try {
      await Api.resetAppData();
      await _relaunch();
    } catch (e) {
      _toast(GhToastType.error, 'Could not wipe app data: $e');
    }
  }

  Future<void> _reimportFromStable() async {
    if (_reimporting) return;
    setState(() => _reimporting = true);
    try {
      final result = await (widget.reimport ?? app_rust.reimportFromStable)();
      if (!mounted) return;
      setState(() {
        _reimporting = false;
        _confirmReimport = false;
      });
      if (!result.imported) {
        _toast(GhToastType.info, 'Nothing to import: no GodotHub data was found');
        return;
      }
      _toast(GhToastType.success, 'Re-imported ${result.copiedFiles} files from GodotHub');
      try {
        await _relaunch();
      } catch (_) {
        _toast(GhToastType.info, 'Restart GodotHub Beta to load the imported data');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _reimporting = false);
      _toast(GhToastType.error, 'Could not re-import from GodotHub: $e');
    }
  }

  Future<void> _restartAndToast(String failure) async {
    try {
      await _relaunch();
    } catch (e) {
      _toast(GhToastType.error, '$failure: $e');
    }
  }

  void _showWorkspaceTip() {
    UiPrefsStore.instance.removeItem(SidebarPrefs.workspaceTipSeen);
    UiPrefsStore.instance.flush().then((_) => _restartAndToast('Could not reload the window')).ignore();
  }

  void _showOnboarding() {
    final settings = ref.read(settingsProvider).value;
    if (settings == null) return;
    ref.read(settingsProvider.notifier).save(copySettings(settings, setupComplete: false)).ignore();
  }

  @override
  Widget build(BuildContext context) {
    if (_crash) throw StateError('Debug crash test triggered from Settings > Debug');
    ref.watch(settingsProvider);
    ref.watch(appVersionProvider);
    final theme = GhTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(3),
      children: [
        _DebugSection(
          title: 'Debug',
          description: 'Developer tools for testing GodotHub. These are not translated and may change at any time. Only you can see this tab; it stays unlocked until you hide it.',
          children: [
            _DebugRow(
              label: 'Hide Debug tab',
              description: 'Locks this tab again. Click the sidebar Settings button 5 times quickly to bring it back.',
              children: [_DebugButton(label: 'Hide', onPressed: () => setDebugUnlocked(false))],
            ),
            _DebugRow(
              label: 'Copy debug info',
              description: 'Copies the app version, platform, window size and current settings as JSON, for bug reports.',
              children: [_DebugButton(label: 'Copy', onPressed: () => _copyDebugInfo().ignore())],
            ),
          ],
        ),
        _DebugSection(
          title: 'Toasts',
          description: 'Fire a test notification of each kind.',
          children: [
            _DebugRow(
              label: 'Show test toast',
              children: [
                _DebugButton(label: 'Success', onPressed: () => _toast(GhToastType.success, 'This is a success toast')),
                _DebugButton(label: 'Info', onPressed: () => _toast(GhToastType.info, 'This is an info toast')),
                _DebugButton(label: 'Error', onPressed: () => _toast(GhToastType.error, 'This is an error toast')),
              ],
            ),
          ],
        ),
        _DebugSection(
          title: 'Caches & watchers',
          children: [
            _DebugRow(
              label: 'Clear project icon and name cache',
              description: "Reloads every project's icon and name from disk.",
              children: [
                _DebugButton(
                  label: 'Clear',
                  onPressed: () {
                    Api.clearProjectIconCache();
                    Api.clearProjectNameCache();
                    _toast(GhToastType.success, 'Project icon and name cache cleared');
                  },
                ),
              ],
            ),
            _DebugRow(
              label: 'Restart file watchers',
              description: 'Tears down and recreates the project, version and template watchers.',
              children: [
                _DebugButton(
                  label: 'Restart',
                  onPressed: () => Api.restartWatchers()
                      .then((_) => _toast(GhToastType.success, 'File watchers restarted'))
                      .catchError((Object e) => _toast(GhToastType.error, 'Could not restart watchers: $e'))
                      .ignore(),
                ),
              ],
            ),
          ],
        ),
        _DebugSection(
          title: 'Tips & banners',
          description: 'Re-trigger one-time UI hints.',
          children: [
            _DebugRow(
              label: 'Re-show workspace tip',
              description: 'Clears the dismissed flag for the sidebar workspace-switcher tip and reloads the window so it appears again.',
              children: [_DebugButton(label: 'Show', onPressed: _showWorkspaceTip)],
            ),
            _DebugRow(
              label: 'Show announcement banner',
              description: 'Displays the one-time bottom banner now, ignoring the 30-minute usage timer and the dismissed flag.',
              children: [_DebugButton(label: 'Show', onPressed: () => AppSignals.emit(showAnnouncementSignal))],
            ),
          ],
        ),
        _DebugSection(
          title: 'Updater',
          description: 'See the update flow without a real release. The preview uses a made-up version, file, speed and progress, and never downloads or installs anything.',
          children: [
            _DebugRow(
              label: 'Preview update modal',
              description: 'Opens Check for Updates in preview mode. Use the state chips at the top to jump between checking, available, downloading, done, up to date, portable and error.',
              children: [_DebugButton(label: 'Preview', onPressed: () => AppSignals.emit(previewUpdateModalSignal))],
            ),
            _DebugRow(
              label: 'Fake update badge',
              description: 'Shows the "update available" badge in the sidebar. Clicking it opens the preview.',
              children: [
                _DebugButton(
                  label: ref.watch(updateAvailableProvider.select((s) => s.previewUpdate)) ? 'Turn off' : 'Turn on',
                  onPressed: () => ref.read(updateAvailableProvider.notifier).togglePreviewUpdate(),
                ),
              ],
            ),
            _DebugRow(
              label: 'Build version',
              description: appBuildVersion.isEmpty
                  ? 'APP_VERSION is not set, so the background update check is off. Pass --dart-define=APP_VERSION=x.y.z to test real updates.'
                  : 'Built as $appBuildVersion. The background update check compares against this version.',
              children: const [],
            ),
          ],
        ),
        _DebugSection(
          title: 'App',
          children: [
            _DebugRow(
              label: 'Show onboarding',
              description: 'Reopens the first-run setup wizard. Your settings are kept.',
              children: [_DebugButton(label: 'Open', onPressed: _showOnboarding)],
            ),
            _DebugRow(
              label: 'Reload window',
              description: 'Reloads the interface without restarting the backend.',
              children: [_DebugButton(label: 'Reload', onPressed: () => _restartAndToast('Could not reload the window').ignore())],
            ),
            _DebugRow(
              label: 'Restart app',
              description: 'Fully restarts GodotHub.',
              children: [_DebugButton(label: 'Restart', onPressed: () => _restartAndToast('Could not restart').ignore())],
            ),
            _DebugRow(
              label: 'Trigger crash',
              description: 'Throws a render error to test the crash screen.',
              children: [_DebugButton(label: 'Crash', danger: true, onPressed: () => setState(() => _crash = true))],
            ),
          ],
        ),
        if (widget.channel == 'beta')
          _DebugSection(
            title: 'Beta data',
            description: 'Data shared with the stable GodotHub app.',
            children: [
              _DebugRow(
                label: 'Re-import from GodotHub',
                description:
                    "Deletes GodotHub Beta's data and copies it again from GodotHub, then restarts. GodotHub's own data is never changed.",
                children: _confirmReimport
                    ? [
                        _DebugButton(
                          label: _reimporting ? 'Re-importing...' : 'Confirm re-import',
                          danger: true,
                          onPressed: _reimporting ? null : () => _reimportFromStable().ignore(),
                        ),
                        _DebugButton(label: 'Cancel', onPressed: _reimporting ? null : () => setState(() => _confirmReimport = false)),
                      ]
                    : [_DebugButton(label: 'Re-import', danger: true, onPressed: () => setState(() => _confirmReimport = true))],
              ),
            ],
          ),
        _DebugSection(
          title: 'Danger zone',
          description: 'Destructive actions, for testing a fresh install.',
          children: [
            _DebugRow(
              label: 'Wipe all app data',
              description: 'Deletes every workspace, project entry, setting and cache, then restarts. Installed Godot files on disk are not touched.',
              children: _confirmWipe
                  ? [
                      _DebugButton(label: 'Confirm wipe', danger: true, onPressed: () => _wipeAppData().ignore()),
                      _DebugButton(label: 'Cancel', onPressed: () => setState(() => _confirmWipe = false)),
                    ]
                  : [_DebugButton(label: 'Wipe', danger: true, onPressed: () => setState(() => _confirmWipe = true))],
            ),
          ],
        ),
      ],
    );
  }
}

class _DebugSection extends StatelessWidget {
  const _DebugSection({required this.title, this.description, required this.children});

  final String title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Container(
      padding: EdgeInsets.all(theme.space(5)),
      decoration: BoxDecoration(color: theme.overlay, borderRadius: BorderRadius.circular(theme.radiusItem)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(5),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: theme.space(1),
            children: [
              Text(
                title,
                style: theme.text(size: GhTextSize.sm, weight: GhWeight.semibold, color: theme.ink),
              ),
              if (description != null)
                Text(
                  description!,
                  style: theme.text(size: GhTextSize.x2s, color: theme.muted),
                ),
            ],
          ),
          ...children,
        ],
      ),
    );
  }
}

class _DebugRow extends StatelessWidget {
  const _DebugRow({required this.label, this.description, required this.children});

  final String label;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Row(
      spacing: theme.space(4),
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: theme.space(1),
            children: [
              Text(
                label,
                style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.muted),
              ),
              if (description != null)
                Text(
                  description!,
                  style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625),
                ),
            ],
          ),
        ),
        Row(mainAxisSize: MainAxisSize.min, spacing: theme.space(2), children: children),
      ],
    );
  }
}

class _DebugButton extends StatelessWidget {
  const _DebugButton({required this.label, required this.onPressed, this.danger = false});

  final String label;
  final VoidCallback? onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: GhPressable(
        onPressed: onPressed,
        borderRadius: radius,
        builder: (context, states) => GhAnimatedBox(
          borderRadius: radius,
          color: danger
              ? theme.danger.withValues(alpha: states.active ? 0.2 : 0.1)
              : (states.active ? theme.raised : theme.raised.withValues(alpha: 0.4)),
          border: Border.all(color: danger ? theme.danger.withValues(alpha: 0.3) : theme.outline.withValues(alpha: 0.5)),
          padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(1.5)),
          child: Text(
            label,
            style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: danger ? theme.danger : theme.ink),
          ),
        ),
      ),
    );
  }
}
