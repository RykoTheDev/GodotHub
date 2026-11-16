import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/opener.dart';
import '../design/design.dart';
import '../state/app_version.dart';
import '../state/godot_versions.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../versions/version_logic.dart';
import '../ui/shell/smooth_scroll.dart';

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
  bool _details = false;
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
    final label = theme.text(size: GhTextSize.xs, color: theme.muted);
    final value = theme.text(size: GhTextSize.xs, color: theme.ink);
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhModalShell(
      icon: GhIcon(GhIcons.alertTriangle, size: theme.space(5), color: theme.danger),
      title: _tv('download_failed_title'),
      maxWidth: GhModalWidth.lg,
      onClose: widget.onClose,
      footer: ghModalActions(
        trailing: [GhButton(key: const ValueKey('download-error-close'), onPressed: widget.onClose, label: ghTr('close'))],
        primary: GhButton(
          key: const ValueKey('download-error-retry'),
          onPressed: widget.onRetry,
          icon: GhIcons.refresh,
          label: ghTr('retry'),
          variant: GhButtonVariant.primary,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), theme.space(2), theme.space(6), theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(4),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(1.5),
              children: [
                Text(
                  ghTr('versions:download_failed_summary', args: {'tag': error.tag}),
                  style: theme.text(size: GhTextSize.sm, weight: GhWeight.semibold, color: theme.ink),
                ),
                Text(
                  _tv('download_failed_hint'),
                  style: theme.text(size: GhTextSize.sm, color: theme.muted, lineHeight: 1.6),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.all(theme.space(3.5)),
              decoration: BoxDecoration(
                color: theme.base.withValues(alpha: 0.5),
                borderRadius: radius,
                border: Border.all(color: theme.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: theme.space(1.5),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: theme.space(3),
                    children: [
                      SizedBox(
                        width: theme.space(16),
                        child: Text(_tv('source'), style: label),
                      ),
                      Expanded(child: Text(downloadSourceLabels[error.source] ?? error.source, style: value)),
                    ],
                  ),
                  if (error.assetName.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: theme.space(3),
                      children: [
                        SizedBox(
                          width: theme.space(16),
                          child: Text(_tv('download_failed_asset_label'), style: label),
                        ),
                        Expanded(
                          child: Text(
                            error.assetName,
                            style: theme.text(size: GhTextSize.xs, mono: true, color: theme.ink),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Wrap(
              spacing: theme.space(2),
              runSpacing: theme.space(2),
              children: [
                GhButton(
                  key: const ValueKey('download-error-details'),
                  onPressed: () => setState(() => _details = !_details),
                  icon: _details ? GhIcons.chevronUp : GhIcons.chevronDown,
                  label: _tv(_details ? 'download_failed_hide_details' : 'download_failed_show_details'),
                  variant: GhButtonVariant.outline,
                  size: GhTextSize.xs,
                  paddingX: 3,
                  paddingY: 1.5,
                ),
                GhButton(
                  key: const ValueKey('download-error-copy'),
                  onPressed: _copy,
                  icon: _copied ? GhIcons.check : GhIcons.copy,
                  label: _copied ? ghTr('bug_report_copied') : _tv('download_failed_copy'),
                  variant: GhButtonVariant.outline,
                  size: GhTextSize.xs,
                  paddingX: 3,
                  paddingY: 1.5,
                ),
                GhButton(
                  key: const ValueKey('download-error-report'),
                  onPressed: _openIssue,
                  icon: GhIcons.github,
                  label: _tv('download_failed_report'),
                  variant: GhButtonVariant.ghost,
                  size: GhTextSize.xs,
                  paddingX: 3,
                  paddingY: 1.5,
                ),
              ],
            ),
            if (_details)
              Container(
                key: const ValueKey('download-error-message'),
                constraints: const BoxConstraints(maxHeight: 200),
                padding: EdgeInsets.all(theme.space(3.5)),
                decoration: BoxDecoration(
                  color: theme.base,
                  borderRadius: radius,
                  border: Border.all(color: theme.line),
                ),
                child: GhScrollView(
                  child: SelectableText(
                    error.message,
                    style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted, lineHeight: 1.625),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
