import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/opener.dart';
import '../api/updates.dart';
import '../design/design.dart';
import '../state/app_version.dart';
import '../state/settings.dart';
import '../ui/controls/spin.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';

const latestReleaseUrl = 'https://github.com/RykoTheDev/GodotHub/releases/latest';
const previewUpdateVersion = '1.0.0';

class AppUpdate {
  const AppUpdate({required this.version, this.body, required this.downloadAndInstall});

  final String version;
  final String? body;
  final Future<void> Function(void Function(double progress) onProgress, {String? githubToken}) downloadAndInstall;
}

typedef AppUpdateCheck = Future<AppUpdate?> Function();

final appUpdateCheckProvider = Provider<AppUpdateCheck>(
  (ref) =>
      () async => throw UnsupportedError('Checking for updates is not available in the Flutter app yet'),
);

final portableInstallCheckProvider = Provider<Future<bool> Function()>((ref) => UpdatesApi.isPortableInstall);

enum CheckForUpdatesMode { manual, preview }

enum UpdateStateType { checking, available, downloading, done, uptodate, portable, error }

enum GithubTokenHint { rateLimited, tokenRejected }

final _status401 = RegExp(r'\b401\b');
final _status403 = RegExp(r'\b403\b');
final _rateLimit = RegExp('rate limit', caseSensitive: false);
final _heading = RegExp(r'^#{2,4}\s+');
final _bullet = RegExp(r'^[-*]\s+');
final _knownIssue = RegExp('known issue', caseSensitive: false);

GithubTokenHint? githubTokenHint(String message, {required bool hasToken}) {
  if (_status401.hasMatch(message)) return GithubTokenHint.tokenRejected;
  if (_status403.hasMatch(message) || _rateLimit.hasMatch(message)) {
    return hasToken ? GithubTokenHint.tokenRejected : GithubTokenHint.rateLimited;
  }
  return null;
}

class ReleaseSection {
  ReleaseSection(this.title);

  final String title;
  final List<String> items = [];

  bool get isKnownIssues => _knownIssue.hasMatch(title);
}

class ParsedReleaseNotes {
  ParsedReleaseNotes(this.intro, this.sections);

  final List<String> intro;
  final List<ReleaseSection> sections;
}

ParsedReleaseNotes parseReleaseNotes(String? md) {
  final intro = <String>[];
  final sections = <ReleaseSection>[];
  if (md == null || md.isEmpty) return ParsedReleaseNotes(intro, sections);
  ReleaseSection? current;
  for (final raw in md.split('\n')) {
    final line = raw.trimRight();
    if (_heading.hasMatch(line)) {
      current = ReleaseSection(line.replaceFirst(_heading, '').trim());
      sections.add(current);
    } else if (current != null) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      current.items.add(trimmed.replaceFirst(_bullet, ''));
    } else if (line.trim().isNotEmpty) {
      intro.add(line.trim());
    }
  }
  return ParsedReleaseNotes(intro, [
    for (final s in sections)
      if (s.items.isNotEmpty) s,
  ]);
}

class CheckForUpdatesModal extends ConsumerStatefulWidget {
  const CheckForUpdatesModal({super.key, required this.onClose, this.onOpenTokenSettings, this.mode = CheckForUpdatesMode.manual});

  final VoidCallback onClose;
  final VoidCallback? onOpenTokenSettings;
  final CheckForUpdatesMode mode;

  @override
  ConsumerState<CheckForUpdatesModal> createState() => _CheckForUpdatesModalState();
}

class _CheckForUpdatesModalState extends ConsumerState<CheckForUpdatesModal> {
  final _random = math.Random();
  UpdateStateType _type = UpdateStateType.checking;
  String? _version;
  String? _notes;
  double _progress = 0;
  String _message = '';
  Future<void> Function()? _install;
  Timer? _simulation;
  Timer? _finish;
  int _check = 0;

  bool get _preview => widget.mode == CheckForUpdatesMode.preview;

  String? get _githubToken {
    final token = ref.read(settingsProvider).value?.githubToken?.trim();
    return token == null || token.isEmpty ? null : token;
  }

  @override
  void initState() {
    super.initState();
    if (_preview) {
      _setAvailablePreview();
    } else {
      _doCheck().ignore();
    }
  }

  @override
  void dispose() {
    _clearSimulation();
    super.dispose();
  }

  void _clearSimulation() {
    _simulation?.cancel();
    _simulation = null;
    _finish?.cancel();
    _finish = null;
  }

  void _set(UpdateStateType type, {String? version, String? notes, double progress = 0, String message = '', Future<void> Function()? install}) {
    if (!mounted) return;
    setState(() {
      _type = type;
      _version = version;
      _notes = notes;
      _progress = progress;
      _message = message;
      _install = install;
    });
  }

  void _setAvailablePreview() {
    _type = UpdateStateType.available;
    _version = previewUpdateVersion;
    _notes = ghTr('preview_release_notes');
    _install = _simulateDownload;
  }

  Future<void> _simulateDownload() {
    _clearSimulation();
    final done = Completer<void>();
    _set(UpdateStateType.downloading);
    var progress = 0.0;
    _simulation = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      progress = math.min(progress + 0.045 + _random.nextDouble() * 0.06, 1);
      _set(UpdateStateType.downloading, progress: progress);
      if (progress >= 1) {
        timer.cancel();
        _simulation = null;
        _finish = Timer(const Duration(milliseconds: 350), () {
          _set(UpdateStateType.done);
          done.complete();
        });
      }
    });
    return done.future;
  }

  Future<void> _doCheck() async {
    if (_preview) {
      _clearSimulation();
      _set(UpdateStateType.available, version: previewUpdateVersion, notes: ghTr('preview_release_notes'), install: _simulateDownload);
      return;
    }
    final check = ++_check;
    _set(UpdateStateType.checking);
    try {
      final results = await Future.wait<Object?>([
        ref.read(appUpdateCheckProvider)(),
        ref.read(portableInstallCheckProvider)().catchError((Object _) => false),
      ]);
      if (check != _check) return;
      final update = results[0] as AppUpdate?;
      final portable = results[1] as bool;
      if (update == null) {
        _set(UpdateStateType.uptodate);
        return;
      }
      if (portable) {
        _set(UpdateStateType.portable, version: update.version, notes: update.body);
        return;
      }
      _set(
        UpdateStateType.available,
        version: update.version,
        notes: update.body,
        install: () async {
          _set(UpdateStateType.downloading);
          try {
            await update.downloadAndInstall(
              (progress) => _set(UpdateStateType.downloading, progress: progress.clamp(0, 1).toDouble()),
              githubToken: _githubToken,
            );
            _set(UpdateStateType.done);
          } catch (e) {
            _set(UpdateStateType.error, message: '$e');
          }
        },
      );
    } catch (e) {
      if (check == _check) _set(UpdateStateType.error, message: '$e');
    }
  }

  void _switchPreviewState(UpdateStateType to) {
    _clearSimulation();
    switch (to) {
      case UpdateStateType.checking:
        _set(UpdateStateType.checking);
      case UpdateStateType.available:
        _set(UpdateStateType.available, version: previewUpdateVersion, notes: ghTr('preview_release_notes'), install: _simulateDownload);
      case UpdateStateType.downloading:
        _set(UpdateStateType.downloading);
        var progress = 0.0;
        _simulation = Timer.periodic(const Duration(milliseconds: 160), (timer) {
          progress = math.min(progress + 0.05 + _random.nextDouble() * 0.07, 1);
          _set(UpdateStateType.downloading, progress: progress);
          if (progress >= 1) {
            timer.cancel();
            _simulation = null;
          }
        });
      case UpdateStateType.done:
        _set(UpdateStateType.done);
      case UpdateStateType.uptodate:
        _set(UpdateStateType.uptodate);
      case UpdateStateType.portable:
        _set(UpdateStateType.portable, version: previewUpdateVersion, notes: ghTr('preview_release_notes'));
      case UpdateStateType.error:
        _set(UpdateStateType.error, message: ghTr('preview_error'));
    }
  }

  void _openTokenSettings() {
    widget.onClose();
    widget.onOpenTokenSettings?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    ref.watch(settingsProvider);
    return GhModalShell(
      icon: GhIcon(GhIcons.download, size: theme.space(5), color: theme.accentBright),
      title: ghTr('check_updates_title_modal'),
      maxWidth: GhModalWidth.x2l,
      onClose: widget.onClose,
      showClose: false,
      footer: [
        const Spacer(),
        GhButton(
          onPressed: widget.onClose,
          label: ghTr('close'),
          variant: GhButtonVariant.outline,
          size: GhTextSize.xs,
          paddingX: 4,
          paddingY: 2,
        ),
      ],
      child: Padding(
        padding: EdgeInsets.all(theme.space(6)),
        child: Column(
          spacing: theme.space(5),
          children: [
            if (_preview) _previewSwitcher(theme),
            KeyedSubtree(key: ValueKey(_type), child: _body(theme)),
          ],
        ),
      ),
    );
  }

  Widget _previewSwitcher(GhTheme theme) {
    final radius = BorderRadius.circular(theme.radiusItem);
    return Column(
      spacing: theme.space(2.5),
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(0.5)),
          decoration: BoxDecoration(color: theme.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(theme.radiusTag)),
          child: Text(
            ghTr('check_updates_preview_badge').toUpperCase(),
            style: theme.text(size: GhTextSize.x3s, weight: GhWeight.semibold, color: theme.amber, letterSpacingEm: 0.05),
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: theme.space(1.5),
          runSpacing: theme.space(1.5),
          children: [
            for (final s in UpdateStateType.values)
              GhPressable(
                onPressed: () => _switchPreviewState(s),
                borderRadius: radius,
                builder: (context, states) {
                  final active = _type == s;
                  return GhAnimatedBox(
                    borderRadius: radius,
                    color: active ? theme.accent.withValues(alpha: 0.15) : theme.raised,
                    border: Border.all(
                      color: active ? theme.accentDim.withValues(alpha: 0.4) : (states.active ? theme.accentDim : theme.line),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(1)),
                    child: Text(
                      ghTr('preview_state_${s.name}'),
                      style: theme.text(
                        size: GhTextSize.x3s,
                        weight: GhWeight.medium,
                        color: active || states.active ? theme.ink : theme.muted,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _statusIcon(GhTheme theme, FaIconData icon, Color color, {bool spin = false}) {
    final glyph = GhIcon(icon, size: theme.space(6), color: color);
    return Container(
      width: theme.space(14),
      height: theme.space(14),
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.1)),
      child: spin ? GhSpinning(child: glyph) : glyph,
    );
  }

  Widget _titled(GhTheme theme, String title, String? subtitle, {double? subtitleMaxWidth}) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.ink),
        ),
        if (subtitle != null)
          Padding(
            padding: EdgeInsets.only(top: theme.space(1)),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: subtitleMaxWidth ?? double.infinity),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.text(size: GhTextSize.xs, color: theme.muted, lineHeight: subtitleMaxWidth == null ? null : 1.625),
              ),
            ),
          ),
      ],
    );
  }

  Widget _body(GhTheme theme) {
    final current = ref.watch(appVersionProvider).value;
    switch (_type) {
      case UpdateStateType.checking:
        return Column(
          spacing: theme.space(4),
          children: [
            _statusIcon(theme, GhIcons.refresh, theme.accent, spin: true),
            Text(
              ghTr('checking_updates'),
              style: theme.text(size: GhTextSize.sm, color: theme.muted),
            ),
          ],
        );
      case UpdateStateType.uptodate:
        return Column(
          spacing: theme.space(4),
          children: [
            _statusIcon(theme, GhIcons.check, theme.mint),
            _titled(theme, ghTr('up_to_date'), ghTr('is_latest', args: {'version': current ?? '?'})),
          ],
        );
      case UpdateStateType.portable:
        return _portable(theme);
      case UpdateStateType.available:
        return _available(theme, current);
      case UpdateStateType.downloading:
        return Column(
          spacing: theme.space(4),
          children: [
            _statusIcon(theme, GhIcons.download, theme.accent),
            _titled(theme, ghTr('downloading_update'), ghTr('percent_complete', args: {'percent': (_progress * 100).round()})),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: theme.space(2),
                color: theme.line,
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: _progress.clamp(0, 1).toDouble(),
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: theme.accent, borderRadius: BorderRadius.circular(999)),
                  ),
                ),
              ),
            ),
          ],
        );
      case UpdateStateType.done:
        return Column(
          spacing: theme.space(4),
          children: [
            _statusIcon(theme, GhIcons.check, theme.mint),
            _titled(theme, ghTr('update_downloaded'), ghTr('restart_to_apply')),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: theme.rem(20)),
              child: Text(
                ghTr('update_applied_desc'),
                textAlign: TextAlign.center,
                style: theme.text(size: GhTextSize.x2s, color: theme.muted.withValues(alpha: 0.7)),
              ),
            ),
          ],
        );
      case UpdateStateType.error:
        return _error(theme);
    }
  }

  Widget _portable(GhTheme theme) {
    final version = _version ?? '';
    final radius = BorderRadius.circular(theme.radiusItem);
    return Column(
      spacing: theme.space(5),
      children: [
        _statusIcon(theme, GhIcons.alertTriangle, theme.amber),
        _titled(theme, ghTr('check_updates_portable_title'), ghTr('check_updates_portable_desc'), subtitleMaxWidth: theme.rem(20)),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: theme.rem(24)),
          child: Container(
            padding: EdgeInsets.all(theme.space(4)),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: theme.amber.withValues(alpha: 0.3)),
              color: theme.amber.withValues(alpha: 0.1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(3),
              children: [
                Row(
                  spacing: theme.space(2),
                  children: [
                    Text(
                      'v$version',
                      style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, mono: true, color: theme.ink),
                    ),
                    Text('-', style: theme.text(size: GhTextSize.xs, color: theme.muted)),
                    Flexible(
                      child: Text(
                        ghTr('check_updates_version_available', args: {'version': version}),
                        style: theme.text(size: GhTextSize.xs, color: theme.muted),
                      ),
                    ),
                  ],
                ),
                _AccentButton(
                  icon: GhIcons.externalLink,
                  label: ghTr('check_updates_download_from_github'),
                  onPressed: () => OpenerApi.openUrl(latestReleaseUrl).catchError((Object e) => ghToasts.pushToast(GhToastType.error, '$e')),
                  expand: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _available(GhTheme theme, String? current) {
    final version = _version ?? '';
    final notes = parseReleaseNotes(_notes);
    final knownIssues = [
      for (final s in notes.sections)
        if (s.isKnownIssues) ...s.items,
    ];
    final mainSections = [
      for (final s in notes.sections)
        if (!s.isKnownIssues) s,
    ];
    final hasNotes = mainSections.isNotEmpty || notes.intro.isNotEmpty;
    final radius = BorderRadius.circular(theme.radiusItem);
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(5),
      children: [
        Row(
          spacing: theme.space(3.5),
          children: [
            Container(
              width: theme.space(12),
              height: theme.space(12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(theme.radiusTile),
              ),
              child: GhIcon(GhIcons.download, size: theme.space(5), color: theme.accentBright),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: theme.space(0.5),
                children: [
                  Text(
                    ghTr('check_updates_version_available', args: {'version': version}),
                    style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.ink, lineHeight: 1.375),
                  ),
                  Text(
                    ghTr('check_updates_ask_download'),
                    style: theme.text(size: GhTextSize.xs, color: theme.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: theme.space(2),
          runSpacing: theme.space(2),
          children: [
            _versionPill(theme, 'v${current ?? '?'}', theme.mint, theme.raised, theme.line, theme.ink, false),
            Transform.rotate(
              angle: math.pi,
              child: GhIcon(GhIcons.refresh, size: theme.space(3), color: theme.muted.withValues(alpha: 0.4)),
            ),
            _versionPill(
              theme,
              'v$version',
              theme.accentBright,
              theme.accent.withValues(alpha: 0.15),
              theme.accent.withValues(alpha: 0.3),
              theme.accentBright,
              true,
            ),
          ],
        ),
        if (knownIssues.isNotEmpty)
          Container(
            padding: EdgeInsets.all(theme.space(4)),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: theme.amber.withValues(alpha: 0.3)),
              color: theme.amber.withValues(alpha: 0.1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: theme.space(2)),
                  child: Row(
                    spacing: theme.space(1.5),
                    children: [
                      GhIcon(GhIcons.alertTriangle, size: theme.space(3.5), color: theme.amber),
                      Text(
                        ghTr('changelog_known_issues').toUpperCase(),
                        style: theme.text(size: GhTextSize.x2s, weight: GhWeight.semibold, color: theme.amber, letterSpacingEm: 0.05),
                      ),
                    ],
                  ),
                ),
                for (final issue in knownIssues)
                  Padding(
                    padding: EdgeInsets.only(bottom: theme.space(1.5)),
                    child: _bulletLine(theme, issue, theme.amber, theme.muted),
                  ),
              ],
            ),
          ),
      ],
    );
    final right = hasNotes
        ? Container(
            decoration: BoxDecoration(
              color: theme.raised,
              borderRadius: radius,
              border: Border.all(color: theme.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(2.5)),
                  decoration: BoxDecoration(
                    color: theme.raised,
                    border: Border(bottom: BorderSide(color: theme.line.withValues(alpha: 0.7))),
                  ),
                  child: Text(
                    ghTr('check_updates_release_notes').toUpperCase(),
                    style: theme.text(size: GhTextSize.x2s, weight: GhWeight.semibold, color: theme.muted, letterSpacingEm: 0.05),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: theme.space(64)),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (notes.intro.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.fromLTRB(theme.space(4), theme.space(3), theme.space(4), 0),
                            child: Text(
                              notes.intro.join(' '),
                              style: theme.text(size: GhTextSize.xs, color: theme.muted, lineHeight: 1.625),
                            ),
                          ),
                        for (final (i, section) in mainSections.indexed)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(3)),
                            decoration: BoxDecoration(
                              border: i == mainSections.length - 1
                                  ? null
                                  : Border(bottom: BorderSide(color: theme.line.withValues(alpha: 0.5))),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(bottom: theme.space(1.5)),
                                  child: Text(
                                    section.title.toUpperCase(),
                                    style: theme.text(
                                      size: GhTextSize.x3s,
                                      weight: GhWeight.semibold,
                                      color: theme.muted,
                                      letterSpacingEm: 0.025,
                                    ),
                                  ),
                                ),
                                for (final item in section.items)
                                  Padding(
                                    padding: EdgeInsets.only(bottom: theme.space(1.5)),
                                    child: _bulletLine(theme, item, theme.muted, theme.ink.withValues(alpha: 0.9)),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();
    final wide = MediaQuery.sizeOf(context).width >= 640;
    return Column(
      spacing: theme.space(5),
      children: [
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: theme.space(6),
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: theme.rem(15)),
                child: SizedBox(width: theme.rem(15), child: left),
              ),
              Expanded(child: right),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(6),
            children: [left, right],
          ),
        _AccentButton(icon: GhIcons.download, label: ghTr('install_update'), onPressed: () => _install?.call().ignore()),
      ],
    );
  }

  Widget _versionPill(GhTheme theme, String text, Color dot, Color fill, Color border, Color ink, bool strong) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(1.5)),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: theme.space(1.5),
        children: [
          Container(
            width: theme.space(1.5),
            height: theme.space(1.5),
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          Text(
            text,
            style: theme.text(size: GhTextSize.xs, mono: true, weight: strong ? GhWeight.semibold : GhWeight.normal, color: ink),
          ),
        ],
      ),
    );
  }

  Widget _bulletLine(GhTheme theme, String text, Color bullet, Color color) {
    final style = theme.text(size: GhTextSize.xs, color: color, lineHeight: 1.625);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: theme.space(2),
      children: [
        Text('•', style: style.copyWith(color: bullet)),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }

  Widget _error(GhTheme theme) {
    final hint = githubTokenHint(_message, hasToken: _githubToken != null);
    final title = switch (hint) {
      GithubTokenHint.rateLimited => ghTr('check_updates_rate_limited'),
      GithubTokenHint.tokenRejected => ghTr('check_updates_token_rejected'),
      null => ghTr('check_updates_failed'),
    };
    final radius = BorderRadius.circular(theme.radiusItem);
    return Column(
      spacing: theme.space(4),
      children: [
        _statusIcon(theme, GhIcons.x, theme.danger),
        _titled(theme, title, _message, subtitleMaxWidth: theme.rem(20)),
        if (hint != null)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(theme.space(4)),
            decoration: BoxDecoration(
              color: theme.raised,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: theme.space(3),
              children: [
                Text(
                  hint == GithubTokenHint.tokenRejected
                      ? ghTr('check_updates_rate_limited_token_hint')
                      : ghTr('check_updates_rate_limited_hint'),
                  style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625),
                ),
                _AccentButton(
                  label: hint == GithubTokenHint.tokenRejected ? ghTr('check_updates_open_token_settings') : ghTr('check_updates_add_token'),
                  onPressed: _openTokenSettings,
                  small: true,
                ),
              ],
            ),
          ),
        GhPressable(
          onPressed: () => _doCheck().ignore(),
          borderRadius: radius,
          builder: (context, states) => GhAnimatedBox(
            borderRadius: radius,
            color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
            border: Border.all(color: states.active ? theme.accentDim : theme.line),
            padding: EdgeInsets.symmetric(horizontal: theme.space(5), vertical: theme.space(2.5)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: theme.space(2),
              children: [
                GhIcon(GhIcons.refresh, size: theme.space(4), color: theme.ink),
                Text(
                  ghTr('try_again'),
                  style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.ink),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AccentButton extends StatelessWidget {
  const _AccentButton({required this.label, required this.onPressed, this.icon, this.small = false, this.expand = false});

  final String label;
  final VoidCallback onPressed;
  final FaIconData? icon;
  final bool small;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      onPressed: onPressed,
      rippleColor: Colors.white,
      borderRadius: radius,
      builder: (context, states) => GhAnimatedBox(
        color: states.active ? theme.accentBright : theme.accent,
        borderRadius: radius,
        padding: EdgeInsets.symmetric(horizontal: theme.space(small ? 4 : (expand ? 5 : 6)), vertical: theme.space(small ? 2 : 2.5)),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: theme.space(2),
          children: [
            if (icon != null) GhIcon(icon!, size: theme.space(4), color: Colors.white),
            Text(
              label,
              style: theme.text(size: small ? GhTextSize.xs : GhTextSize.sm, weight: GhWeight.medium, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
