import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/opener.dart';
import '../api/updater.dart';
import '../api/updates.dart';
import '../design/design.dart';
import '../motion/motion.dart';
import '../state/app_version.dart';
import '../state/settings.dart';
import '../ui/controls/spin.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/reusables/modal_kit.dart';
import '../ui/core/interaction.dart';
import '../ui/core/tooltip.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/shell/smooth_scroll.dart';
import '../logic/format_bytes.dart';
import '../logic/duration.dart';

import 'package:intl/intl.dart';

export '../api/updater.dart' show AppUpdate, UpdateDownloadProgress;

const latestReleaseUrl = 'https://github.com/RykoTheDev/GodotHub/releases/latest';
const previewUpdateVersion = '1.0.0';
const previewUpdateSize = 92 * 1024 * 1024;
const previewReleaseNotes =
    '## What\'s new in v1.0.0 - The Preview Update\n\n## New\n\n- Revamped the Check for Updates modal with structured release notes\n- Added screen reader announcements with an Accessibility settings tab\n\n## Fixes\n\n- Fixed a crash when switching workspaces with pinned projects\n- Fixed update checks failing silently when GitHub rate limits are hit\n\n## Improvements\n\n- Faster startup times across all platforms\n- Reworked workspace modals with compact style pickers\n\n## Known Issues\n\n- Linux OS: AppImage won\'t work on some distros, use the .rpm or .deb package instead\n- Windows: the taskbar may briefly show a duplicate icon until the app restarts';
const previewError = 'Preview error: GitHub API rate limit reached (HTTP 403). Add a token in Settings to keep checking.';
const previewStateLabels = {
  UpdateStateType.checking: 'Checking',
  UpdateStateType.available: 'Available',
  UpdateStateType.downloading: 'Downloading',
  UpdateStateType.done: 'Done',
  UpdateStateType.uptodate: 'Up to date',
  UpdateStateType.portable: 'Portable',
  UpdateStateType.error: 'Error',
};
const maxUpdateLogLines = 1000;
const previewLogLines = [
  'Downloaded 92.0 MB',
  'Signature verified',
  'Output folder: C:\\Users\\you\\AppData\\Local\\GodotHub\\app-1.0.0',
  'Extract: godothub.exe (104.0 KB)',
  'Extract: flutter_windows.dll (18.4 MB)',
  'Extract: godothub_bridge.dll (31.2 MB)',
  'Extract: data/app.so (12.6 MB)',
  'Extract: data/icudtl.dat (781.2 KB)',
  'Extract: data/flutter_assets/fonts/Inter.ttf (309.8 KB)',
  'GodotHub 1.0.0 starts on the next launch',
];
const previewUpdateUrl = 'https://github.com/RykoTheDev/GodotHub/releases/download/v1.0.0/GodotHub-1.0.0-setup.exe';

class DownloadStats {
  const DownloadStats({this.downloaded = 0, this.total, this.speed, this.eta});

  final int downloaded;
  final int? total;
  final double? speed;
  final Duration? eta;
}

String? formatReleaseDate(String? date, String locale) {
  final parsed = date == null ? null : DateTime.tryParse(date);
  if (parsed == null) return null;
  return DateFormat.yMMMd(locale).format(parsed.toLocal());
}

typedef AppUpdateCheck = Future<AppUpdate?> Function();

final appUpdateCheckProvider = Provider<AppUpdateCheck>((ref) => UpdaterApi.check);

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
  Future<void> Function()? _restart;
  bool _restarting = false;
  final _log = <String>[];
  String? _date;
  String? _package;
  UpdateSource _source = const UpdateSource();
  DownloadStats _stats = const DownloadStats();
  int? _doneSize;
  Duration? _doneElapsed;
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

  void _set(
    UpdateStateType type, {
    String? version,
    String? notes,
    double progress = 0,
    String message = '',
    Future<void> Function()? install,
    AppUpdate? update,
    DownloadStats stats = const DownloadStats(),
    int? doneSize,
    Duration? doneElapsed,
  }) {
    if (!mounted) return;
    setState(() {
      _type = type;
      _version = version ?? _version;
      _notes = notes ?? _notes;
      _progress = progress;
      _message = message;
      _install = install;
      if (update != null) {
        _date = update.date;
        _package = update.package;
        _source = updateSourceFrom(update.downloadUrl);
      }
      _stats = stats;
      _doneSize = doneSize;
      _doneElapsed = doneElapsed;
    });
  }

  AppUpdate get _previewUpdate => AppUpdate(
    version: previewUpdateVersion,
    body: previewReleaseNotes,
    date: DateTime.now().toUtc().toIso8601String(),
    downloadUrl: previewUpdateUrl,
    package: 'windows-x86_64-nsis',
    download: (_, {githubToken, onLog}) async {},
    restart: () async {},
  );

  void _addLog(String line) {
    if (!mounted) return;
    setState(() {
      _log.add(line);
      if (_log.length > maxUpdateLogLines) _log.removeRange(0, _log.length - maxUpdateLogLines);
    });
  }

  void _simulateTick(double progress, DownloadSpeedMeter meter, Stopwatch clock) {
    final downloaded = (previewUpdateSize * progress).round();
    final rates = meter.sample(downloaded, previewUpdateSize, clock.elapsed);
    _set(
      UpdateStateType.downloading,
      progress: progress,
      stats: DownloadStats(downloaded: downloaded, total: previewUpdateSize, speed: rates.speed, eta: rates.eta),
    );
  }

  void _setAvailablePreview() {
    final update = _previewUpdate;
    _type = UpdateStateType.available;
    _version = previewUpdateVersion;
    _notes = previewReleaseNotes;
    _install = _simulateDownload;
    _date = update.date;
    _package = update.package;
    _source = updateSourceFrom(update.downloadUrl);
  }

  Future<void> _simulateDownload() {
    _clearSimulation();
    _log
      ..clear()
      ..add('Downloading GodotHub-$previewUpdateVersion-setup.exe from github.com');
    final done = Completer<void>();
    final meter = DownloadSpeedMeter();
    final clock = Stopwatch()..start();
    _simulateTick(0, meter, clock);
    var progress = 0.0;
    _simulation = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      progress = math.min(progress + 0.045 + _random.nextDouble() * 0.06, 1);
      _simulateTick(progress, meter, clock);
      if (progress >= 1) {
        timer.cancel();
        _simulation = null;
        _finish = Timer(const Duration(milliseconds: 350), () {
          _log.addAll(previewLogLines);
          _set(UpdateStateType.done, doneSize: previewUpdateSize, doneElapsed: clock.elapsed);
          done.complete();
        });
      }
    });
    return done.future;
  }

  Future<void> _doCheck() async {
    if (_preview) {
      _clearSimulation();
      _set(
        UpdateStateType.available,
        version: previewUpdateVersion,
        notes: previewReleaseNotes,
        install: _simulateDownload,
        update: _previewUpdate,
      );
      return;
    }
    final check = ++_check;
    _log.clear();
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
        update: update,
        install: () async {
          final meter = DownloadSpeedMeter();
          final clock = Stopwatch()..start();
          var last = const UpdateDownloadProgress(downloaded: 0);
          Duration? painted;
          _log.clear();
          _set(UpdateStateType.downloading);
          try {
            await update.download(
              (progress) {
                last = progress;
                final now = clock.elapsed;
                final rates = meter.sample(progress.downloaded, progress.total, now);
                final total = progress.total;
                final finished = total != null && progress.downloaded >= total;
                if (!finished && painted != null && now - painted! < const Duration(milliseconds: 100)) return;
                painted = now;
                _set(
                  UpdateStateType.downloading,
                  progress: total != null && total > 0 ? (progress.downloaded / total).clamp(0, 1).toDouble() : 0,
                  stats: DownloadStats(
                    downloaded: progress.downloaded,
                    total: total,
                    speed: finished ? null : rates.speed,
                    eta: finished ? Duration.zero : rates.eta,
                  ),
                );
              },
              githubToken: _githubToken,
              onLog: _addLog,
            );
            _restart = update.restart;
            _set(UpdateStateType.done, doneSize: last.total ?? last.downloaded, doneElapsed: clock.elapsed);
          } catch (e) {
            _set(UpdateStateType.error, message: '$e');
          }
        },
      );
    } catch (e) {
      if (check == _check) _set(UpdateStateType.error, message: '$e');
    }
  }

  Future<void> _restartNow() async {
    final restart = _restart;
    if (_preview || restart == null) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _restarting = true);
    try {
      await restart();
    } catch (e) {
      _set(UpdateStateType.error, message: '$e');
    } finally {
      if (mounted) setState(() => _restarting = false);
    }
  }

  void _switchPreviewState(UpdateStateType to) {
    _clearSimulation();
    _log.clear();
    switch (to) {
      case UpdateStateType.checking:
        _set(UpdateStateType.checking);
      case UpdateStateType.available:
        _set(
          UpdateStateType.available,
          version: previewUpdateVersion,
          notes: previewReleaseNotes,
          install: _simulateDownload,
          update: _previewUpdate,
        );
      case UpdateStateType.downloading:
        _log.add('Downloading GodotHub-$previewUpdateVersion-setup.exe from github.com');
        final meter = DownloadSpeedMeter();
        final clock = Stopwatch()..start();
        _simulateTick(0, meter, clock);
        var progress = 0.0;
        _simulation = Timer.periodic(const Duration(milliseconds: 160), (timer) {
          progress = math.min(progress + 0.05 + _random.nextDouble() * 0.07, 1);
          _simulateTick(progress, meter, clock);
          if (progress >= 1) {
            timer.cancel();
            _simulation = null;
          }
        });
      case UpdateStateType.done:
        _log
          ..clear()
          ..add('Downloading GodotHub-$previewUpdateVersion-setup.exe from github.com')
          ..addAll(previewLogLines);
        _set(UpdateStateType.done, doneSize: previewUpdateSize, doneElapsed: const Duration(milliseconds: 21400));
      case UpdateStateType.uptodate:
        _set(UpdateStateType.uptodate);
      case UpdateStateType.portable:
        _set(UpdateStateType.portable, version: previewUpdateVersion, notes: previewReleaseNotes);
      case UpdateStateType.error:
        _set(UpdateStateType.error, message: previewError);
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
      footer: _footer(theme),
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), theme.space(1), theme.space(6), theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(5),
          children: [
            if (_preview) _previewSwitcher(theme),
            KeyedSubtree(key: ValueKey(_type), child: _body(theme)),
          ],
        ),
      ),
    );
  }

  List<Widget> _footer(GhTheme theme) {
    final releaseUrl = _source.releaseUrl;
    final primary = switch (_type) {
      UpdateStateType.available => GhButton(
        onPressed: () => _install?.call().ignore(),
        label: ghTr('install_update'),
        icon: GhIcons.download,
        variant: GhButtonVariant.primary,
        weight: GhWeight.medium,
      ),
      UpdateStateType.done => GhBusyButton(
        onPressed: _restarting ? null : () => _restartNow().ignore(),
        busy: _restarting,
        label: ghTr('restart_now'),
        icon: GhIcons.refresh,
      ),
      UpdateStateType.portable => GhButton(
        onPressed: () => OpenerApi.openUrl(latestReleaseUrl).catchError((Object e) => ghToasts.pushToast(GhToastType.error, '$e')),
        label: ghTr('check_updates_download_from_github'),
        icon: GhIcons.externalLink,
        variant: GhButtonVariant.primary,
        weight: GhWeight.medium,
      ),
      UpdateStateType.error => GhButton(
        onPressed: () => _doCheck().ignore(),
        label: ghTr('try_again'),
        icon: GhIcons.refresh,
        variant: GhButtonVariant.primary,
        weight: GhWeight.medium,
      ),
      _ => null,
    };
    return [
      if (releaseUrl != null && (_type == UpdateStateType.available || _type == UpdateStateType.done))
        GhButton(
          onPressed: () => OpenerApi.openUrl(releaseUrl).catchError((Object e) => ghToasts.pushToast(GhToastType.error, '$e')),
          label: ghTr('check_updates_view_release'),
          icon: GhIcons.externalLink,
          variant: GhButtonVariant.ghost,
          size: GhTextSize.xs,
          paddingX: 3,
          paddingY: 2,
        ),
      const Spacer(),
      GhButton(
        onPressed: widget.onClose,
        label: ghTr('close'),
        variant: GhButtonVariant.outline,
        size: GhTextSize.xs,
        paddingX: 4,
        paddingY: 2,
      ),
      ?primary,
    ];
  }

  Widget _previewSwitcher(GhTheme theme) {
    final radius = BorderRadius.circular(theme.radiusTag);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: theme.space(1.5),
      runSpacing: theme.space(1.5),
      children: [
        Container(
          margin: EdgeInsetsDirectional.only(end: theme.space(1.5)),
          padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(0.5)),
          decoration: BoxDecoration(color: theme.amber.withValues(alpha: 0.15), borderRadius: radius),
          child: Text(
            'PREVIEW',
            style: theme.text(size: GhTextSize.x3s, weight: GhWeight.semibold, color: theme.amber, letterSpacingEm: 0.05),
          ),
        ),
        for (final s in UpdateStateType.values)
          GhPressable(
            onPressed: () => _switchPreviewState(s),
            borderRadius: radius,
            builder: (context, states) {
              final active = _type == s;
              return GhAnimatedBox(
                borderRadius: radius,
                color: active ? theme.accent.withValues(alpha: 0.15) : (states.active ? theme.overlay : theme.raised),
                border: Border.all(color: active ? theme.accent.withValues(alpha: 0.4) : theme.line),
                padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(1)),
                child: Text(
                  previewStateLabels[s]!,
                  style: theme.text(
                    size: GhTextSize.x2s,
                    weight: GhWeight.medium,
                    color: active ? theme.accentBright : (states.active ? theme.ink : theme.muted),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _body(GhTheme theme) {
    final current = ref.watch(appVersionProvider).value;
    final hint = githubTokenHint(_message, hasToken: _githubToken != null);
    switch (_type) {
      case UpdateStateType.checking:
        return _hero(
          theme,
          icon: GhIcons.refresh,
          color: theme.accent,
          spin: true,
          title: ghTr('checking_updates'),
          subtitle: current == null ? null : 'v$current',
        );
      case UpdateStateType.uptodate:
        return _hero(
          theme,
          icon: GhIcons.check,
          color: theme.mint,
          title: ghTr('up_to_date'),
          subtitle: ghTr('is_latest', args: {'version': current ?? '?'}),
        );
      case UpdateStateType.portable:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(5),
          children: [
            _hero(
              theme,
              icon: GhIcons.alertTriangle,
              color: theme.amber,
              title: ghTr('check_updates_portable_title'),
              subtitle: ghTr('check_updates_version_available', args: {'version': _version ?? ''}),
              trailing: _versionChange(theme, current),
            ),
            GhAlertBox(tone: GhAlertTone.amber, icon: GhIcons.info, text: ghTr('check_updates_portable_desc')),
          ],
        );
      case UpdateStateType.available:
        return _available(theme, current);
      case UpdateStateType.downloading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(5),
          children: [
            _hero(
              theme,
              icon: GhIcons.cloudArrowDown,
              color: theme.accent,
              title: ghTr('downloading_update'),
              subtitle: ghTr('percent_complete', args: {'percent': (_progress * 100).round()}),
              trailing: _versionChange(theme, current),
            ),
            _progressCard(theme),
            if (_log.isNotEmpty) _logPanel(theme),
          ],
        );
      case UpdateStateType.done:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(5),
          children: [
            _hero(
              theme,
              icon: GhIcons.check,
              color: theme.mint,
              title: ghTr('update_downloaded'),
              subtitle: ghTr('restart_to_apply'),
              trailing: _versionChange(theme, current),
            ),
            _doneSummary(theme),
            if (_log.isNotEmpty) _logPanel(theme),
          ],
        );
      case UpdateStateType.error:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(4),
          children: [
            _hero(
              theme,
              icon: GhIcons.x,
              color: theme.danger,
              title: switch (hint) {
                GithubTokenHint.rateLimited => ghTr('check_updates_rate_limited'),
                GithubTokenHint.tokenRejected => ghTr('check_updates_token_rejected'),
                null => ghTr('check_updates_failed'),
              },
            ),
            if (_message.isNotEmpty) GhAlertBox(tone: GhAlertTone.danger, icon: GhIcons.alertTriangle, text: _message),
            if (hint != null) _tokenHint(theme, hint),
            if (_log.isNotEmpty) _logPanel(theme),
          ],
        );
    }
  }

  Widget _hero(
    GhTheme theme, {
    required FaIconData icon,
    required Color color,
    required String title,
    String? subtitle,
    bool spin = false,
    Widget? trailing,
  }) {
    final glyph = GhIcon(icon, size: theme.space(5), color: color);
    final tile = Container(
      width: theme.space(11),
      height: theme.space(11),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(theme.radiusTile),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: spin ? GhSpinning(child: glyph) : glyph,
    );
    return Row(
      spacing: theme.space(3.5),
      children: [
        tile,
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: theme.space(0.5),
              children: [
                Text(
                  title,
                  style: theme.text(size: GhTextSize.base, weight: GhWeight.semibold, color: theme.ink, lineHeight: 1.3),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: theme.text(size: GhTextSize.xs, color: theme.muted, lineHeight: 1.5),
                  ),
              ],
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }

  Widget? _versionChange(GhTheme theme, String? current) {
    final next = _version;
    if (next == null || next.isEmpty) return null;
    Widget chip(String text, {required bool strong}) => Container(
      padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(1)),
      decoration: BoxDecoration(
        color: strong ? theme.accent.withValues(alpha: 0.15) : theme.overlay,
        borderRadius: BorderRadius.circular(theme.radiusTag),
        border: Border.all(color: strong ? theme.accent.withValues(alpha: 0.35) : theme.line),
      ),
      child: Text(
        text,
        style: theme.text(
          size: GhTextSize.xs,
          mono: true,
          weight: strong ? GhWeight.semibold : GhWeight.normal,
          color: strong ? theme.accentBright : theme.muted,
        ),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: theme.space(1.5),
      children: [
        if (current != null) ...[
          chip('v$current', strong: false),
          GhIcon(GhIcons.chevronRight, size: theme.space(3), color: theme.muted.withValues(alpha: 0.6)),
        ],
        chip('v$next', strong: true),
      ],
    );
  }

  Widget _sectionLabel(GhTheme theme, String text, {Color? color, FaIconData? icon}) {
    final label = Text(
      text.toUpperCase(),
      style: theme.text(size: GhTextSize.x2s, weight: GhWeight.semibold, color: color ?? theme.muted, letterSpacingEm: 0.06),
    );
    if (icon == null) return label;
    return Row(
      spacing: theme.space(1.5),
      children: [
        GhIcon(icon, size: theme.space(3.5), color: color ?? theme.muted),
        Flexible(child: label),
      ],
    );
  }

  BoxDecoration _panel(GhTheme theme) => BoxDecoration(
    color: theme.raised,
    borderRadius: BorderRadius.circular(theme.radiusItem),
    border: Border.all(color: theme.line),
  );

  Widget _panelHeader(GhTheme theme, String label, {Widget? trailing}) => Container(
    padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(2.5)),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: theme.line.withValues(alpha: 0.7))),
    ),
    child: Row(
      children: [
        Expanded(child: _sectionLabel(theme, label)),
        ?trailing,
      ],
    ),
  );

  Widget _available(GhTheme theme, String? current) {
    final notes = parseReleaseNotes(_notes);
    final knownIssues = [
      for (final s in notes.sections)
        if (s.isKnownIssues) ...s.items,
    ];
    final sections = [
      for (final s in notes.sections)
        if (!s.isKnownIssues) s,
    ];
    final hasNotes = sections.isNotEmpty || notes.intro.isNotEmpty || knownIssues.isNotEmpty;
    final hero = _hero(
      theme,
      icon: GhIcons.download,
      color: theme.accent,
      title: ghTr('check_updates_version_available', args: {'version': _version ?? ''}),
      subtitle: ghTr('check_updates_ask_download'),
      trailing: _versionChange(theme, current),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(4),
      children: [hero, _details(theme), if (hasNotes) _releaseNotes(theme, notes.intro, sections, knownIssues)],
    );
  }

  Widget _releaseNotes(GhTheme theme, List<String> intro, List<ReleaseSection> sections, List<String> knownIssues) {
    final maxHeight = math.max(theme.rem(9), math.min(theme.rem(22), MediaQuery.sizeOf(context).height * 0.28));
    final blocks = <Widget>[
      if (intro.isNotEmpty)
        Text(
          intro.join(' '),
          style: theme.text(size: GhTextSize.xs, color: theme.muted, lineHeight: 1.625),
        ),
      for (final section in sections)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(1.5),
          children: [
            _sectionLabel(theme, section.title),
            for (final item in section.items) _bulletLine(theme, item, theme.accent, theme.ink.withValues(alpha: 0.9)),
          ],
        ),
      if (knownIssues.isNotEmpty)
        GhAlertBox(
          tone: GhAlertTone.amber,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(1.5),
            children: [
              _sectionLabel(theme, ghTr('changelog_known_issues'), color: theme.amber, icon: GhIcons.alertTriangle),
              for (final issue in knownIssues) _bulletLine(theme, issue, theme.amber, theme.ink.withValues(alpha: 0.85)),
            ],
          ),
        ),
    ];
    return Container(
      decoration: _panel(theme),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _panelHeader(theme, ghTr('check_updates_release_notes')),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: GhScrollView(
              padding: EdgeInsets.all(theme.space(4)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: theme.space(4), children: blocks),
            ),
          ),
        ],
      ),
    );
  }

  Widget _details(GhTheme theme) {
    final released = formatReleaseDate(_date, Localizations.localeOf(context).toLanguageTag());
    Widget fact(FaIconData icon, String label, String value, {bool mono = false, Color? color}) => GhTooltip(
      message: label,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(1.25)),
        decoration: BoxDecoration(
          color: theme.raised,
          borderRadius: BorderRadius.circular(theme.radiusTag),
          border: Border.all(color: theme.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: theme.space(1.5),
          children: [
            GhIcon(icon, size: theme.space(3.25), color: color ?? theme.muted),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.text(size: GhTextSize.x2s, mono: mono, color: color ?? theme.ink.withValues(alpha: 0.9)),
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      label: ghTr('check_updates_details'),
      container: true,
      child: Wrap(
        spacing: theme.space(1.5),
        runSpacing: theme.space(1.5),
        children: [
          if (released != null) fact(GhIcons.clock, ghTr('check_updates_released'), released),
          if (_source.host != null) fact(GhIcons.cloudArrowDown, ghTr('check_updates_source'), _source.host!, mono: true),
          if (_source.file != null) fact(GhIcons.hardDrive, ghTr('check_updates_file'), _source.file!, mono: true),
          if (_package != null) fact(GhIcons.monitor, ghTr('check_updates_package'), _package!, mono: true),
          fact(GhIcons.lock, ghTr('check_updates_signature'), ghTr('check_updates_signature_checked'), color: theme.mint),
        ],
      ),
    );
  }

  Widget _progressCard(GhTheme theme) {
    final stats = _stats;
    final total = stats.total;
    final speed = stats.speed;
    final eta = stats.eta;
    final numbers = theme
        .text(size: GhTextSize.xs, mono: true, color: theme.ink)
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final quiet = numbers.copyWith(color: theme.muted);
    return Container(
      padding: EdgeInsets.all(theme.space(4)),
      decoration: _panel(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(3),
        children: [
          Row(
            spacing: theme.space(3),
            children: [
              Expanded(
                child: Text(
                  total != null
                      ? ghTr(
                          'check_updates_progress_size',
                          args: {'downloaded': formatBytes(stats.downloaded), 'total': formatBytes(total)},
                        )
                      : formatBytes(stats.downloaded),
                  style: numbers,
                ),
              ),
              if (speed != null && speed > 0) Text(ghTr('check_updates_speed', args: {'speed': formatBytes(speed)}), style: quiet),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: theme.space(1.5),
              color: theme.line,
              alignment: AlignmentDirectional.centerStart,
              child: AnimatedFractionallySizedBox(
                duration: GhMotion.of(context).css(GhDurations.progress),
                curve: GhCurves.outExpo,
                widthFactor: _progress.clamp(0, 1).toDouble(),
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(colors: [theme.accent, theme.accentBright]),
                  ),
                ),
              ),
            ),
          ),
          Row(
            spacing: theme.space(3),
            children: [
              if (_source.host != null)
                Expanded(
                  child: Text(
                    ghTr('check_updates_from_host', args: {'host': _source.host!}),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.text(size: GhTextSize.x2s, color: theme.muted),
                  ),
                )
              else
                const Spacer(),
              if (eta != null && eta > Duration.zero)
                Text(
                  ghTr('check_updates_time_left', args: {'time': formatDuration(math.max(1000, eta.inMilliseconds))}),
                  style: theme.text(size: GhTextSize.x2s, color: theme.muted),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _doneSummary(GhTheme theme) {
    final size = _doneSize;
    final elapsed = _doneElapsed;
    return GhAlertBox(
      tone: GhAlertTone.mint,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: theme.space(5),
        runSpacing: theme.space(2),
        children: [
          if (size != null && elapsed != null)
            Text(
              ghTr(
                'check_updates_download_summary',
                args: {'size': formatBytes(size), 'time': formatDuration(math.max(1000, elapsed.inMilliseconds))},
              ),
              style: theme.text(size: GhTextSize.xs, color: theme.ink),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: theme.space(1.5),
            children: [
              GhIcon(GhIcons.lock, size: theme.space(3.5), color: theme.mint),
              Text(
                ghTr('check_updates_signature_verified'),
                style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.mint),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _logPanel(GhTheme theme) {
    final lines = _log.reversed.toList(growable: false);
    final height = math.max(theme.rem(5), math.min(theme.rem(11), MediaQuery.sizeOf(context).height * 0.18));
    Color colorOf(String line) {
      if (line.startsWith('Failed')) return theme.danger;
      if (line.startsWith('Extract:')) return theme.muted;
      return theme.ink;
    }

    return Container(
      decoration: _panel(theme),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _panelHeader(
            theme,
            ghTr('check_updates_log'),
            trailing: Text(
              '${_log.length}',
              style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted),
            ),
          ),
          Container(
            height: height,
            color: theme.base.withValues(alpha: 0.35),
            child: ListView.builder(
              key: const ValueKey('update-log'),
              reverse: true,
              padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(2.5)),
              itemCount: lines.length,
              itemBuilder: (context, i) => Padding(
                padding: EdgeInsets.symmetric(vertical: theme.space(0.25)),
                child: Text(
                  lines[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text(size: GhTextSize.x2s, mono: true, color: colorOf(lines[i]), lineHeight: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tokenHint(GhTheme theme, GithubTokenHint hint) {
    return GhAlertBox(
      tone: GhAlertTone.amber,
      icon: GhIcons.github,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: theme.space(3),
        children: [
          Text(
            hint == GithubTokenHint.tokenRejected ? ghTr('check_updates_rate_limited_token_hint') : ghTr('check_updates_rate_limited_hint'),
            style: theme.text(size: GhTextSize.xs, color: theme.ink.withValues(alpha: 0.85), lineHeight: 1.6),
          ),
          GhButton(
            onPressed: _openTokenSettings,
            label: hint == GithubTokenHint.tokenRejected ? ghTr('check_updates_open_token_settings') : ghTr('check_updates_add_token'),
            icon: GhIcons.gear,
            variant: GhButtonVariant.outline,
            size: GhTextSize.xs,
            paddingX: 3,
            paddingY: 1.5,
          ),
        ],
      ),
    );
  }

  Widget _bulletLine(GhTheme theme, String text, Color bullet, Color color) {
    final style = theme.text(size: GhTextSize.xs, color: color, lineHeight: 1.6);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: theme.space(2.5),
      children: [
        Padding(
          padding: EdgeInsets.only(top: theme.space(1.75)),
          child: Container(
            width: theme.space(1.25),
            height: theme.space(1.25),
            decoration: BoxDecoration(color: bullet.withValues(alpha: 0.8), shape: BoxShape.circle),
          ),
        ),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}
