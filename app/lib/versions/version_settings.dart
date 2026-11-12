import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import '../api/mise.dart';
import '../api/opener.dart';
import '../api/versions.dart';
import '../design/design.dart';
import '../logic/settings_copy.dart';
import '../src/rust/api/types.dart';
import '../state/godot_versions.dart';
import '../state/settings.dart';
import '../ui/controls/text_input.dart';
import '../ui/controls/toggle.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/toast.dart';

String _ts(String key, {num? count, Map<String, Object?> args = const {}}) => ghTr('settings:$key', count: count, args: args);

enum TokenTestState { idle, testing, success, warning, error }

typedef TokenTester = Future<RateLimitInfo> Function();

({TokenTestState state, String message}) describeRateLimit(RateLimitInfo info, {int? nowSeconds}) {
  final now = nowSeconds ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final minutes = ((info.resetAt.toInt() - now) / 60).round().clamp(1, 1 << 30);
  final base = '${info.remaining}/${info.limit}';
  final status = info.usedToken ? '$base ${_ts('token_resets_in', args: {'minutes': minutes})}' : base;
  return (
    state: info.remaining > BigInt.zero ? TokenTestState.success : TokenTestState.warning,
    message: _ts('token_valid', args: {'status': status}),
  );
}

class GithubTokenField extends ConsumerStatefulWidget {
  const GithubTokenField({super.key, this.test});

  final TokenTester? test;

  @override
  ConsumerState<GithubTokenField> createState() => _GithubTokenFieldState();
}

class _GithubTokenFieldState extends ConsumerState<GithubTokenField> {
  late final TextEditingController _token = TextEditingController(text: ref.read(settingsProvider).value?.githubToken ?? '');
  TokenTestState _state = TokenTestState.idle;
  String? _message;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    _token.dispose();
    super.dispose();
  }

  void _save(String value) {
    final settings = ref.read(settingsProvider).value;
    if (settings == null) return;
    ref.read(settingsProvider.notifier).save(copySettings(settings, githubToken: () => value.isEmpty ? null : value)).ignore();
  }

  Future<void> _test() async {
    _reset?.cancel();
    setState(() => _state = TokenTestState.testing);
    try {
      final info = await (widget.test ?? VersionsApi.testGithubToken)();
      final result = describeRateLimit(info);
      if (mounted) {
        setState(() {
          _state = result.state;
          _message = result.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = TokenTestState.error;
          _message = _ts('test_failed', args: {'error': '$e'});
        });
      }
    }
    _reset = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _state = TokenTestState.idle;
          _message = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final message = _message;
    final tone = switch (_state) {
      TokenTestState.success => theme.mint,
      TokenTestState.warning => theme.amber,
      TokenTestState.error => theme.danger,
      _ => theme.muted,
    };
    final radius = BorderRadius.circular(theme.radiusMd);
    final help = theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(2.5),
      children: [
        Text(
          _ts('github_token_title'),
          style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.muted),
        ),
        Stack(
          alignment: AlignmentDirectional.centerEnd,
          children: [
            GhTextInput(
              controller: _token,
              obscureText: true,
              mono: true,
              onChanged: _save,
              placeholder: ghTr('setting_token_placeholder'),
              semanticLabel: _ts('github_token_title'),
              background: theme.base,
              borderColor: theme.outline.withValues(alpha: 0.5),
              focusBorderColor: theme.accentDim,
              borderRadius: BorderRadius.circular(theme.radiusBtn),
              padding: EdgeInsetsDirectional.fromSTEB(theme.space(3.5), theme.space(2.5), theme.space(20), theme.space(2.5)),
            ),
            PositionedDirectional(
              end: theme.space(1.5),
              child: GhPressable(
                onPressed: _test,
                borderRadius: radius,
                builder: (context, states) => GhAnimatedBox(
                  color: theme.overlay,
                  borderRadius: radius,
                  border: Border.all(color: states.active ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
                  padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(1.5)),
                  child: Text(
                    _state == TokenTestState.testing ? _ts('testing') : _ts('test'),
                    style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: states.active ? theme.ink : theme.muted),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (message != null)
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              style: theme.text(size: GhTextSize.x2s, color: tone),
            ),
          ),
        Text.rich(
          TextSpan(
            text: '${_ts('token_help_desc')} ',
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: GhPressable(
                  onPressed: () =>
                      OpenerApi.openUrl('https://github.com/settings/tokens')
                          .catchError((Object e) => ghToasts.pushToast(GhToastType.error, '$e')),
                  builder: (context, states) => Text(
                    'github.com/settings/tokens',
                    style: help.copyWith(color: states.active ? theme.accentBright : theme.accent, decoration: TextDecoration.underline),
                  ),
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
          style: help,
        ),
      ],
    );
  }
}

class MiseSetting extends ConsumerStatefulWidget {
  const MiseSetting({super.key});

  @override
  ConsumerState<MiseSetting> createState() => _MiseSettingState();
}

class _MiseSettingState extends ConsumerState<MiseSetting> {
  MiseStatus? _status;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() => MiseApi.refreshStatus().then(
    (status) {
      if (mounted) setState(() => _status = status);
    },
    onError: (Object _) {
      if (mounted) setState(() => _status = null);
    },
  );

  void _toggle(AppSettings settings, bool checked) {
    ref.read(settingsProvider.notifier).save(copySettings(settings, useMise: checked)).ignore();
    _refresh();
    if (checked) {
      MiseApi.syncVersions().then((_) => ref.read(godotVersionsProvider.notifier).refreshInstalled()).catchError((Object e) {
        ghToasts.pushToast(GhToastType.error, '$e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final settings = ref.watch(settingsProvider).value;
    if (settings == null) return const SizedBox.shrink();
    final status = _status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: theme.space(2),
      children: [
        GhToggle(checked: settings.useMise, label: _ts('mise_label'), onChanged: (checked) => _toggle(settings, checked)),
        if (settings.useMise)
          Text(
            (status?.available ?? false)
                ? _ts('mise_detected', args: {'version': status!.version ?? status.path ?? ''})
                : _ts('mise_not_found'),
            style: theme.text(size: GhTextSize.x2s, color: theme.muted),
          ),
      ],
    );
  }
}

@immutable
class DetectedInstallsState {
  const DetectedInstallsState({
    this.installs = const [],
    this.selected = const {},
    this.imported = const {},
    this.loading = true,
    this.importing = false,
  });

  final List<DiscoveredInstall> installs;
  final Set<String> selected;
  final Set<String> imported;
  final bool loading;
  final bool importing;

  DetectedInstallsState copyWith({
    List<DiscoveredInstall>? installs,
    Set<String>? selected,
    Set<String>? imported,
    bool? loading,
    bool? importing,
  }) => DetectedInstallsState(
    installs: installs ?? this.installs,
    selected: selected ?? this.selected,
    imported: imported ?? this.imported,
    loading: loading ?? this.loading,
    importing: importing ?? this.importing,
  );
}

final detectedInstallsProvider = NotifierProvider.autoDispose<DetectedInstallsNotifier, DetectedInstallsState>(
  DetectedInstallsNotifier.new,
);

class DetectedInstallsNotifier extends Notifier<DetectedInstallsState> {
  @override
  DetectedInstallsState build() {
    scheduleMicrotask(_detect);
    return const DetectedInstallsState();
  }

  Future<void> _detect() async {
    try {
      final list = await Api.detectGodotInstalls();
      if (ref.mounted) state = state.copyWith(installs: list, selected: {for (final i in list) i.path});
    } catch (_) {
    } finally {
      if (ref.mounted) state = state.copyWith(loading: false);
    }
  }

  void toggle(String path) {
    final next = {...state.selected};
    if (!next.remove(path)) next.add(path);
    state = state.copyWith(selected: next);
  }

  Future<int> importSelected() async {
    final targets = [
      for (final i in state.installs)
        if (state.selected.contains(i.path) && !state.imported.contains(i.path)) i,
    ];
    if (targets.isEmpty) return 0;
    state = state.copyWith(importing: true);
    var added = 0;
    for (final install in targets) {
      try {
        await Api.importDetectedInstall(install.path);
        if (ref.mounted) state = state.copyWith(imported: {...state.imported, install.path});
        added++;
      } catch (e) {
        ghToasts.pushToast(GhToastType.error, '${install.name}: $e');
      }
    }
    if (!ref.mounted) return added;
    state = state.copyWith(importing: false);
    ref.read(godotVersionsProvider.notifier).refreshInstalled().ignore();
    if (added > 0) ghToasts.pushToast(GhToastType.success, ghTr('onboarding:discovery_added_versions', count: added));
    return added;
  }
}
