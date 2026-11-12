import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/opener.dart';
import '../design/design.dart';
import '../state/app_version.dart';
import '../ui/controls/spin.dart';
import '../ui/controls/text_input.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import 'download_error_modal.dart';

const bugReportUrl = 'https://github.com/RykoTheDev/GodotHub/issues/new';
const bugReportMaxCaptured = 20;
const bugReportMaxDescription = 2000;

enum CapturedErrorSource {
  flutterError('FlutterError'),
  platformDispatcher('PlatformDispatcher.onError');

  const CapturedErrorSource(this.label);

  final String label;
}

@immutable
class CapturedError {
  const CapturedError({required this.time, required this.source, required this.message});

  final String time;
  final CapturedErrorSource source;
  final String message;
}

abstract final class BugReportErrorLog {
  static List<CapturedError> _errors = [];
  static bool _installed = false;

  static List<CapturedError> get errors => List.unmodifiable(_errors);

  static String _time(DateTime now) =>
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

  static void record(CapturedErrorSource source, String message, [DateTime? now]) {
    _errors = [
      CapturedError(time: _time(now ?? DateTime.now()), source: source, message: message),
      ..._errors,
    ].take(bugReportMaxCaptured).toList();
  }

  static void install() {
    if (_installed) return;
    _installed = true;
    final previousFlutter = FlutterError.onError;
    FlutterError.onError = (details) {
      record(CapturedErrorSource.flutterError, details.exceptionAsString());
      previousFlutter?.call(details);
    };
    final dispatcher = ui.PlatformDispatcher.instance;
    final previousPlatform = dispatcher.onError;
    dispatcher.onError = (error, stack) {
      record(CapturedErrorSource.platformDispatcher, '$error');
      return previousPlatform?.call(error, stack) ?? false;
    };
  }

  @visibleForTesting
  static void debugReset() {
    _errors = [];
  }
}

void installBugReportErrorCapture() => BugReportErrorLog.install();

String _dateStamp(DateTime now) => now.toUtc().toIso8601String().substring(0, 10);

({String specs, String errors}) buildBugSystemReport({
  required String version,
  required DateTime now,
  required String os,
  required String platform,
  required String language,
  required int cpuCores,
  required String screen,
  required String userAgent,
  required List<CapturedError> errors,
}) {
  final specs = [
    '## ${ghTr('bug_report_system')}',
    '',
    '- **${ghTr('bug_report_version')}**: $version',
    '- **${ghTr('bug_report_date')}**: ${_dateStamp(now)}',
    '- **${ghTr('bug_report_os')}**: $os',
    '- **${ghTr('bug_report_platform')}**: $platform',
    '- **${ghTr('bug_report_language')}**: $language',
    '- **${ghTr('bug_report_cpu_cores')}**: $cpuCores',
    '- **${ghTr('bug_report_ram')}**: ${ghTr('unknown')}',
    '- **${ghTr('bug_report_screen')}**: $screen',
    '- **${ghTr('bug_report_gpu')}**: ${ghTr('gpu_info_unavailable')}',
    '- **${ghTr('bug_report_user_agent')}**: $userAgent',
  ].join('\n');
  final lines = ['## ${ghTr('bug_report_recent_errors')}'];
  if (errors.isEmpty) {
    lines.add('- _(${ghTr('bug_report_none_captured')})_');
  } else {
    for (final e in errors) {
      lines.add('- `[${e.time}]` (${e.source.label}) ${e.message}');
    }
  }
  return (specs: specs, errors: lines.join('\n'));
}

String assembleBugReport(String description, String specs, String errors) {
  final desc = description.trim();
  return [
    '## ${ghTr('bug_report_description')}',
    '',
    if (desc.isNotEmpty) desc else '_ ${ghTr('bug_report_no_description')} _',
    '',
    specs,
    '',
    errors,
  ].join('\n');
}

String bugReportIssueUrl(String description, String specs, String errors) {
  final firstLine = description.trim().split('\n').first;
  final title = (firstLine.isNotEmpty ? firstLine : ghTr('report_a_bug'));
  return Uri.parse(bugReportUrl)
      .replace(
        queryParameters: {
          'template': 'bug_report.yaml',
          'title': title.length > 72 ? title.substring(0, 72) : title,
          'description': description.trim(),
          'environment': specs,
          'actual-behavior': errors,
        },
      )
      .toString();
}

String bugReportFileName(DateTime now) => 'godothub-bug-report-${_dateStamp(now)}.txt';

Future<String> _saveToDownloads(String name, String content) async {
  final home = Platform.environment[Platform.isWindows ? 'USERPROFILE' : 'HOME'];
  if (home == null || home.isEmpty) throw StateError('Could not find the Downloads folder');
  final dir = Directory('$home${Platform.pathSeparator}Downloads');
  if (!await dir.exists()) await dir.create(recursive: true);
  var file = File('${dir.path}${Platform.pathSeparator}$name');
  final dot = name.lastIndexOf('.');
  for (var n = 1; await file.exists(); n++) {
    file = File('${dir.path}${Platform.pathSeparator}${name.substring(0, dot)} ($n)${name.substring(dot)}');
  }
  await file.writeAsString(content);
  return file.path;
}

class BugReportModal extends ConsumerStatefulWidget {
  const BugReportModal({super.key, required this.onClose});

  final VoidCallback onClose;

  @visibleForTesting
  static Future<String> Function(String name, String content)? debugSaveReport;

  @override
  ConsumerState<BugReportModal> createState() => _BugReportModalState();
}

class _BugReportModalState extends ConsumerState<BugReportModal> {
  final _description = TextEditingController();
  ({String specs, String errors})? _system;
  bool _copied = false;
  Timer? _reset;

  @override
  void initState() {
    super.initState();
    _description.addListener(() {
      final text = _description.text;
      if (text.length > bugReportMaxDescription) {
        _description.value = TextEditingValue(
          text: text.substring(0, bugReportMaxDescription),
          selection: const TextSelection.collapsed(offset: bugReportMaxDescription),
        );
        return;
      }
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _build());
  }

  @override
  void dispose() {
    _reset?.cancel();
    _description.dispose();
    super.dispose();
  }

  Future<void> _build() async {
    final version = await ref.read(appVersionProvider.future).then((v) => v ?? '', onError: (Object _) => '');
    if (!mounted) return;
    final view = View.of(context);
    final display = view.display;
    final size = display.size;
    final ratio = display.devicePixelRatio;
    setState(() {
      _system = buildBugSystemReport(
        version: version,
        now: DateTime.now(),
        os: hostOsLabel(),
        platform: Platform.operatingSystemVersion,
        language: Platform.localeName,
        cpuCores: Platform.numberOfProcessors,
        screen: '${(size.width / ratio).round()}x${(size.height / ratio).round()} @${ratio % 1 == 0 ? ratio.toInt() : ratio}x',
        userAgent: 'GodotHub/$version Flutter Dart/${Platform.version.split(' ').first}',
        errors: BugReportErrorLog.errors,
      );
    });
  }

  String? get _report {
    final system = _system;
    return system == null ? null : assembleBugReport(_description.text, system.specs, system.errors);
  }

  Future<void> _copy() async {
    final report = _report;
    if (report == null) return;
    try {
      await Clipboard.setData(ClipboardData(text: report));
      if (!mounted) return;
      setState(() => _copied = true);
      _reset?.cancel();
      _reset = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _copied = false);
      });
    } catch (_) {}
  }

  Future<void> _download() async {
    final report = _report;
    if (report == null) return;
    try {
      final path = await (BugReportModal.debugSaveReport ?? _saveToDownloads)(bugReportFileName(DateTime.now()), report);
      ghToasts.pushToast(GhToastType.success, path);
    } catch (e) {
      ghToasts.pushToast(GhToastType.error, '$e');
    }
  }

  void _openIssue() {
    final system = _system;
    if (system == null) return;
    OpenerApi.openUrl(
      bugReportIssueUrl(_description.text, system.specs, system.errors),
    ).catchError((Object e) => ghToasts.pushToast(GhToastType.error, '$e'));
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final report = _report;
    final ready = report != null;
    final radius = BorderRadius.circular(theme.radiusItem);
    final caption = theme.text(size: GhTextSize.x2s, weight: GhWeight.semibold, color: theme.muted, letterSpacingEm: 0.05);
    return GhModalShell(
      icon: GhIcon(GhIcons.bug, size: theme.space(5), color: theme.danger),
      title: ghTr('report_a_bug'),
      maxWidth: GhModalWidth.lg,
      onClose: widget.onClose,
      footer: [
        Flexible(
          child: _FooterButton(
            label: _copied ? ghTr('bug_report_copied') : ghTr('bug_report_copy_log'),
            icon: _copied ? GhIcons.check : GhIcons.copy,
            iconColor: _copied ? theme.mint : null,
            onPressed: ready ? _copy : null,
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: theme.space(2.5),
            children: [
              Flexible(
                flex: 8,
                child: _FooterButton(label: ghTr('bug_report_download_log'), icon: GhIcons.download, onPressed: ready ? _download : null),
              ),
              Flexible(
                flex: 9,
                child: _FooterButton(
                  label: ghTr('bug_report_open_github'),
                  icon: GhIcons.externalLink,
                  onPressed: ready ? _openIssue : null,
                  danger: true,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: EdgeInsets.all(theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(4),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(1.5),
              children: [
                Text(ghTr('bug_report_describe_label').toUpperCase(), style: caption),
                GhTextInput(
                  controller: _description,
                  autofocus: true,
                  size: GhTextSize.sm,
                  minLines: 3,
                  maxLines: 3,
                  placeholder: ghTr('bug_report_describe_placeholder'),
                  semanticLabel: ghTr('bug_report_describe_label'),
                  background: theme.base,
                  borderColor: theme.outline.withValues(alpha: 0.5),
                  focusBorderColor: theme.accentDim,
                  placeholderColor: theme.muted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(theme.radiusBtn),
                  padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(2.5)),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(1.5),
              children: [
                Row(
                  spacing: theme.space(3),
                  children: [
                    Expanded(child: Text(ghTr('bug_report_diagnostics_label').toUpperCase(), style: caption)),
                    Text(
                      ghTr('bug_report_diagnostics_hint'),
                      style: theme.text(size: GhTextSize.x3s, color: theme.muted.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
                if (report == null)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: theme.space(10)),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: theme.base, borderRadius: radius, border: Border.all(color: theme.line)),
                    child: GhSpinning(child: GhIcon(GhIcons.refresh, size: theme.space(5), color: theme.muted)),
                  )
                else
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    padding: EdgeInsets.all(theme.space(3.5)),
                    decoration: BoxDecoration(color: theme.base, borderRadius: radius, border: Border.all(color: theme.line)),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        report,
                        style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted, lineHeight: 1.625),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({required this.label, required this.icon, required this.onPressed, this.danger = false, this.iconColor});

  final String label;
  final FaIconData icon;
  final VoidCallback? onPressed;
  final bool danger;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return Opacity(
      opacity: onPressed == null ? 0.4 : 1,
      child: GhPressable(
        onPressed: onPressed,
        rippleColor: danger ? Colors.white : null,
        borderRadius: radius,
        builder: (context, states) {
          final fg = danger ? Colors.white : (states.active ? theme.ink : theme.muted);
          return GhAnimatedBox(
            color: danger
                ? theme.danger.withValues(alpha: states.active ? 0.9 : 1)
                : (states.active ? theme.raised : theme.raised.withValues(alpha: 0)),
            borderRadius: radius,
            border: danger ? null : Border.all(color: states.active ? theme.accentDim : theme.line),
            padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(2.5)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: theme.space(2),
              children: [
                GhIcon(icon, size: theme.space(4), color: iconColor ?? fg),
                Flexible(
                  child: Text(
                    label,
                    style: theme.text(size: GhTextSize.sm, weight: danger ? GhWeight.medium : GhWeight.normal, color: fg),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
