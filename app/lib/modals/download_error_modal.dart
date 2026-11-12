import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/opener.dart';
import '../design/design.dart';
import '../state/app_version.dart';
import '../state/godot_versions.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../versions/version_logic.dart';
import 'current_version_modal.dart';

String _tv(String key) => ghTr('versions:$key');

String hostOsLabel() {
  if (Platform.isWindows) return 'Windows';
  if (Platform.isMacOS) return 'macOS';
  if (Platform.isLinux) return 'Linux';
  return Platform.operatingSystem;
}

class DownloadErrorModal extends ConsumerStatefulWidget {
  const DownloadErrorModal({super.key, required this.error, required this.onRetry, required this.onClose});

  final DownloadErrorInfo error;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  ConsumerState<DownloadErrorModal> createState() => _DownloadErrorModalState();
}

class _DownloadErrorModalState extends ConsumerState<DownloadErrorModal> {
  bool _copied = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  String get _report => downloadReport(
    widget.error,
    appVersion: ref.read(appVersionProvider).value ?? '',
    os: hostOsLabel(),
    platform: Platform.operatingSystemVersion,
  );

  Future<void> _copy() async {
    try {
      await Clipboard.setData(ClipboardData(text: _report));
      if (!mounted) return;
      setState(() => _copied = true);
      _reset?.cancel();
      _reset = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _copied = false);
      });
    } catch (_) {}
  }

  void _openIssue() =>
      OpenerApi.openUrl(downloadIssueUrl(widget.error, _report)).catchError((Object e) => ghToasts.pushToast(GhToastType.error, '$e'));

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    ref.watch(appVersionProvider);
    final error = widget.error;
    final label = theme.text(size: GhTextSize.sm, color: theme.muted);
    final value = theme.text(size: GhTextSize.sm, color: theme.ink);
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhModalShell(
      icon: GhIcon(GhIcons.alertTriangle, size: theme.space(5), color: theme.danger),
      title: _tv('download_failed_title'),
      maxWidth: GhModalWidth.lg,
      onClose: widget.onClose,
      footer: [
        OutlineIconButton(
          label: _copied ? ghTr('bug_report_copied') : _tv('download_failed_copy'),
          icon: _copied ? GhIcons.check : GhIcons.copy,
          onPressed: _copy,
        ),
        const Spacer(),
        OutlineIconButton(label: ghTr('retry'), icon: GhIcons.refresh, onPressed: widget.onRetry),
        GhPressable(
          onPressed: _openIssue,
          rippleColor: Colors.white,
          borderRadius: radius,
          builder: (context, states) => GhAnimatedBox(
            color: theme.danger.withValues(alpha: states.active ? 0.9 : 1),
            borderRadius: radius,
            padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(2.5)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: theme.space(2),
              children: [
                GhIcon(GhIcons.externalLink, size: theme.space(4), color: Colors.white),
                Text(
                  ghTr('bug_report_open_github'),
                  style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), theme.space(2), theme.space(6), theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(4),
          children: [
            Table(
              columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
              children: [
                TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.only(end: theme.space(4), bottom: theme.space(1.5)),
                      child: Text(_tv('source'), style: label),
                    ),
                    Text(downloadSourceLabels[error.source] ?? error.source, style: value),
                  ],
                ),
                if (error.assetName.isNotEmpty)
                  TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsetsDirectional.only(end: theme.space(4)),
                        child: Text(_tv('download_failed_asset_label'), style: label),
                      ),
                      Text(error.assetName, style: value),
                    ],
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(1.5),
              children: [
                Text(
                  _tv('download_failed_error_label').toUpperCase(),
                  style: theme.text(size: GhTextSize.x2s, weight: GhWeight.semibold, color: theme.muted, letterSpacingEm: 0.05),
                ),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  padding: EdgeInsets.all(theme.space(3.5)),
                  decoration: BoxDecoration(
                    color: theme.base,
                    borderRadius: radius,
                    border: Border.all(color: theme.line),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      error.message,
                      style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted, lineHeight: 1.625),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              _tv('download_failed_hint'),
              style: theme.text(size: GhTextSize.xs, color: theme.muted.withValues(alpha: 0.8), lineHeight: 1.625),
            ),
          ],
        ),
      ),
    );
  }
}
