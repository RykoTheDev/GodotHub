import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/diagnostics.dart';
import '../api/opener.dart';
import '../design/design.dart';
import '../motion/motion.dart';
import '../state/app_version.dart';
import '../ui/controls/spin.dart';
import '../ui/controls/text_input.dart';
import '../ui/controls/toggle.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import 'download_error_modal.dart';
import '../ui/shell/smooth_scroll.dart';

const bugReportUrl = 'https://github.com/RykoTheDev/GodotHub/issues/new';
const bugReportMaxCaptured = 20;
const bugReportMaxDescription = 2000;
const bugReportLogLines = 40;
const bugReportMaxIssueLogChars = 3000;

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
      Diagnostics.record('flutter', Diagnostics.describe(details.exceptionAsString(), details.stack));
      previousFlutter?.call(details);
    };
    final dispatcher = ui.PlatformDispatcher.instance;
    final previousPlatform = dispatcher.onError;
    dispatcher.onError = (error, stack) {
      record(CapturedErrorSource.platformDispatcher, '$error');
      Diagnostics.record('dart', Diagnostics.describe(error, stack));
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

String _logBlock(String log) => '```\n${log.trimRight()}\n```';

String assembleBugReport(String description, String specs, String errors, [String log = '', String steps = '', String expected = '']) {
  final desc = description.trim();
  return [
    '## ${ghTr('bug_report_description')}',
    '',
    if (desc.isNotEmpty) desc else '_ ${ghTr('bug_report_no_description')} _',
    if (steps.trim().isNotEmpty) ...['', '## ${ghTr('bug_report_steps_label')}', '', steps.trim()],
    if (expected.trim().isNotEmpty) ...['', '## ${ghTr('bug_report_expected_label')}', '', expected.trim()],
    '',
    specs,
    '',
    errors,
    if (log.trim().isNotEmpty) ...['', '## ${ghTr('bug_report_log')}', '', _logBlock(log)],
  ].join('\n');
}

String bugReportIssueUrl(String description, String specs, String errors, [String log = '', String steps = '', String expected = '']) {
  final trimmed = log.trim();
  final issueLog = trimmed.length > bugReportMaxIssueLogChars ? trimmed.substring(trimmed.length - bugReportMaxIssueLogChars) : trimmed;
  final firstLine = description.trim().split('\n').first;
  final title = (firstLine.isNotEmpty ? firstLine : ghTr('report_a_bug'));
  return Uri.parse(bugReportUrl)
      .replace(
        queryParameters: {
          'template': 'bug_report.yaml',
          'title': title.length > 72 ? title.substring(0, 72) : title,
          'description': description.trim(),
          if (steps.trim().isNotEmpty) 'steps-to-reproduce': steps.trim(),
          if (expected.trim().isNotEmpty) 'expected-behavior': expected.trim(),
          'environment': specs,
          'actual-behavior': errors,
          if (issueLog.isNotEmpty) 'additional-context': '## ${ghTr('bug_report_log')}\n\n${_logBlock(issueLog)}',
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
  const BugReportModal({super.key, required this.onClose, this.initialDescription = ''});

  final VoidCallback onClose;
  final String initialDescription;

  @visibleForTesting
  static Future<String> Function(String name, String content)? debugSaveReport;

  @visibleForTesting
  static Future<String> Function()? debugLogTail;

  @override
  ConsumerState<BugReportModal> createState() => _BugReportModalState();
}

class _BugReportModalState extends ConsumerState<BugReportModal> {
  late final _description = TextEditingController(text: widget.initialDescription);
  final _steps = TextEditingController();
  final _expected = TextEditingController();
  final _descriptionFocus = FocusNode(debugLabel: 'bug-report-description');
  ({String specs, String errors})? _system;
  String _version = '';
  String _log = '';
  bool _includeLog = true;
  bool _preview = false;
  bool _missingDescription = false;
  bool _copied = false;
  Timer? _reset;
  final _previewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    for (final controller in [_description, _steps, _expected]) {
      controller.addListener(() => _limit(controller));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _build());
  }

  void _limit(TextEditingController controller) {
    final text = controller.text;
    if (text.length > bugReportMaxDescription) {
      controller.value = TextEditingValue(
        text: text.substring(0, bugReportMaxDescription),
        selection: const TextSelection.collapsed(offset: bugReportMaxDescription),
      );
      return;
    }
    setState(() {
      if (identical(controller, _description) && text.trim().isNotEmpty) _missingDescription = false;
    });
  }

  @override
  void dispose() {
    _reset?.cancel();
    _description.dispose();
    _steps.dispose();
    _expected.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  Future<void> _build() async {
    final version = await ref.read(appVersionProvider.future).then((v) => v ?? '', onError: (Object _) => '');
    final log = await (BugReportModal.debugLogTail ?? () => Diagnostics.tail(lines: bugReportLogLines))();
    if (!mounted) return;
    final view = View.of(context);
    final display = view.display;
    final size = display.size;
    final ratio = display.devicePixelRatio;
    setState(() {
      _version = version;
      _log = log;
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

  String get _sentLog => _includeLog ? _log : '';

  int get _logLines => _log.trim().isEmpty ? 0 : '\n'.allMatches(_log.trim()).length + 1;

  String? get _report {
    final system = _system;
    return system == null ? null : assembleBugReport(_description.text, system.specs, system.errors, _sentLog, _steps.text, _expected.text);
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

  void _togglePreview() {
    setState(() => _preview = !_preview);
    if (!_preview) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _previewKey.currentContext;
      if (target != null && mounted) {
        Scrollable.ensureVisible(target, duration: GhMotion.of(context).css(const Duration(milliseconds: 300)), curve: Curves.easeOutCubic);
      }
    });
  }

  void _openIssue() {
    final system = _system;
    if (system == null) return;
    if (_description.text.trim().isEmpty) {
      setState(() => _missingDescription = true);
      _descriptionFocus.requestFocus();
      return;
    }
    OpenerApi.openUrl(bugReportIssueUrl(_description.text, system.specs, system.errors, _sentLog, _steps.text, _expected.text))
        .catchError((Object e) => ghToasts.pushToast(GhToastType.error, '$e'));
    widget.onClose();
  }

  Widget _field(
    GhTheme theme, {
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required int lines,
    bool optional = false,
    bool autofocus = false,
    FocusNode? focusNode,
    String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(1.5),
      children: [
        Row(
          spacing: theme.space(2),
          children: [
            Flexible(
              child: Text(
                label,
                style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: theme.ink),
              ),
            ),
            if (optional)
              Text(
                ghTr('bug_report_optional'),
                style: theme.text(size: GhTextSize.x2s, color: theme.muted.withValues(alpha: 0.7)),
              ),
          ],
        ),
        GhTextInput(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          size: GhTextSize.sm,
          minLines: lines,
          maxLines: lines,
          placeholder: placeholder,
          semanticLabel: label,
          background: theme.base,
          borderColor: error != null ? theme.danger : theme.outline.withValues(alpha: 0.5),
          focusBorderColor: error != null ? theme.danger : theme.accentDim,
          placeholderColor: theme.muted.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(theme.radiusBtn),
          padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(2.5)),
        ),
        if (error != null)
          Text(
            error,
            style: theme.text(size: GhTextSize.x2s, color: theme.danger),
          ),
      ],
    );
  }

  Widget _includedRow(GhTheme theme, FaIconData icon, String text, {Color? color, Widget? trailing}) {
    return Row(
      spacing: theme.space(2.5),
      children: [
        GhIcon(icon, size: theme.space(3.5), color: color ?? theme.muted),
        Expanded(
          child: Text(
            text,
            style: theme.text(size: GhTextSize.xs, color: color ?? theme.muted),
          ),
        ),
        ?trailing,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final report = _report;
    final ready = report != null;
    final radius = BorderRadius.circular(theme.radiusItem);
    final errorCount = BugReportErrorLog.errors.length;
    return GhModalShell(
      icon: GhIcon(GhIcons.bug, size: theme.space(5), color: theme.danger),
      title: ghTr('report_a_bug'),
      maxWidth: GhModalWidth.x2l,
      onClose: widget.onClose,
      footer: ghModalActions(
        leading: [GhButton(onPressed: widget.onClose, label: ghTr('cancel'), variant: GhButtonVariant.ghost)],
        primary: GhButton(
          key: const ValueKey('bug-report-github'),
          onPressed: ready ? _openIssue : null,
          icon: GhIcons.github,
          label: ghTr('bug_report_open_github'),
          variant: GhButtonVariant.primary,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), 0, theme.space(6), theme.space(5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(4),
          children: [
            Text(
              ghTr('bug_report_intro'),
              style: theme.text(size: GhTextSize.sm, color: theme.muted, lineHeight: 1.6),
            ),
            _field(
              theme,
              label: ghTr('bug_report_describe_label'),
              controller: _description,
              placeholder: ghTr('bug_report_what_happened_placeholder'),
              lines: 4,
              autofocus: true,
              focusNode: _descriptionFocus,
              error: _missingDescription ? ghTr('bug_report_describe_first') : null,
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final steps = _field(
                  theme,
                  label: ghTr('bug_report_steps_label'),
                  controller: _steps,
                  placeholder: ghTr('bug_report_steps_placeholder'),
                  lines: 3,
                  optional: true,
                );
                final expected = _field(
                  theme,
                  label: ghTr('bug_report_expected_label'),
                  controller: _expected,
                  placeholder: ghTr('bug_report_expected_placeholder'),
                  lines: 3,
                  optional: true,
                );
                if (constraints.maxWidth < theme.rem(34)) {
                  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: theme.space(4), children: [steps, expected]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: theme.space(3),
                  children: [
                    Expanded(child: steps),
                    Expanded(child: expected),
                  ],
                );
              },
            ),
            Container(
              padding: EdgeInsets.all(theme.space(4)),
              decoration: BoxDecoration(
                color: theme.base.withValues(alpha: 0.5),
                borderRadius: radius,
                border: Border.all(color: theme.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: theme.space(2.5),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ghTr('bug_report_included_title'),
                          style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: theme.ink),
                        ),
                      ),
                      if (!ready)
                        GhSpinning(
                          child: GhIcon(GhIcons.spinner, size: theme.space(3.5), color: theme.muted),
                        ),
                    ],
                  ),
                  _includedRow(
                    theme,
                    GhIcons.monitor,
                    ghTr('bug_report_included_system', args: {'version': _version.isEmpty ? '?' : _version, 'os': hostOsLabel()}),
                  ),
                  _includedRow(
                    theme,
                    errorCount > 0 ? GhIcons.alertTriangle : GhIcons.circleCheck,
                    errorCount > 0 ? ghTr('bug_report_included_errors', count: errorCount) : ghTr('bug_report_included_no_errors'),
                    color: errorCount > 0 ? theme.amber : null,
                  ),
                  _includedRow(
                    theme,
                    GhIcons.terminal,
                    ghTr('bug_report_included_log', count: _logLines),
                    color: _includeLog ? null : theme.muted.withValues(alpha: 0.5),
                    trailing: GhToggle(
                      key: const ValueKey('bug-report-include-log'),
                      checked: _includeLog,
                      label: ghTr('bug_report_include_log'),
                      onChanged: _logLines == 0 ? null : (value) => setState(() => _includeLog = value),
                    ),
                  ),
                  Wrap(
                    spacing: theme.space(2),
                    runSpacing: theme.space(2),
                    children: [
                      GhButton(
                        key: const ValueKey('bug-report-preview'),
                        onPressed: ready ? _togglePreview : null,
                        icon: _preview ? GhIcons.chevronUp : GhIcons.chevronDown,
                        label: ghTr(_preview ? 'bug_report_preview_hide' : 'bug_report_preview_show'),
                        variant: GhButtonVariant.outline,
                        size: GhTextSize.xs,
                        paddingX: 3,
                        paddingY: 1.5,
                      ),
                      GhButton(
                        key: const ValueKey('bug-report-copy'),
                        onPressed: ready ? _copy : null,
                        icon: _copied ? GhIcons.check : GhIcons.copy,
                        label: _copied ? ghTr('bug_report_copied') : ghTr('bug_report_copy_log'),
                        variant: GhButtonVariant.outline,
                        size: GhTextSize.xs,
                        paddingX: 3,
                        paddingY: 1.5,
                      ),
                      GhButton(
                        key: const ValueKey('bug-report-download'),
                        onPressed: ready ? _download : null,
                        icon: GhIcons.download,
                        label: ghTr('bug_report_download_log'),
                        variant: GhButtonVariant.outline,
                        size: GhTextSize.xs,
                        paddingX: 3,
                        paddingY: 1.5,
                      ),
                    ],
                  ),
                  if (_preview && report != null)
                    Container(
                      key: _previewKey,
                      constraints: const BoxConstraints(maxHeight: 220),
                      padding: EdgeInsets.all(theme.space(3)),
                      decoration: BoxDecoration(
                        color: theme.base,
                        borderRadius: radius,
                        border: Border.all(color: theme.line),
                      ),
                      child: GhScrollView(
                        child: SelectableText(
                          report,
                          style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted, lineHeight: 1.625),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              ghTr('bug_report_github_hint'),
              style: theme.text(size: GhTextSize.x2s, color: theme.muted.withValues(alpha: 0.7), lineHeight: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
