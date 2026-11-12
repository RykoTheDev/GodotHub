import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api.dart';
import '../design/design.dart';
import '../src/rust/api/types.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/reusables/modal_kit.dart';

String _ts(String key, {num? count}) => ghTr('settings:$key', count: count);

enum RestorePhase { fetching, preview, applying, done, error }

class RestoreProgressModal extends StatefulWidget {
  const RestoreProgressModal({super.key, required this.onClose, this.relaunch});

  final VoidCallback onClose;
  final Future<void> Function()? relaunch;

  @override
  State<RestoreProgressModal> createState() => _RestoreProgressModalState();
}

class _RestoreProgressModalState extends State<RestoreProgressModal> {
  RestorePhase _phase = RestorePhase.fetching;
  RestorePreview? _preview;
  String? _error;
  Timer? _restart;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _restart?.cancel();
    super.dispose();
  }

  void _fetch() {
    Api.gistSyncFetchBackup().then(
      (data) {
        if (mounted) {
          setState(() {
            _preview = data;
            _phase = RestorePhase.preview;
          });
        }
      },
      onError: (Object e) {
        if (mounted) {
          setState(() {
            _error = '$e';
            _phase = RestorePhase.error;
          });
        }
      },
    );
  }

  void _retry() {
    setState(() {
      _phase = RestorePhase.fetching;
      _error = null;
    });
    _fetch();
  }

  Future<void> _relaunch() async {
    try {
      await (widget.relaunch ?? Api.relaunch)();
    } catch (e) {
      ghToasts.pushToast(GhToastType.error, '$e');
    }
  }

  Future<void> _apply() async {
    setState(() => _phase = RestorePhase.applying);
    try {
      await Api.gistSyncPull();
      if (!mounted) return;
      setState(() => _phase = RestorePhase.done);
      _restart = Timer(const Duration(milliseconds: 1200), _relaunch);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _phase = RestorePhase.error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final icon = switch (_phase) {
      RestorePhase.done => GhIcon(GhIcons.check, size: theme.space(5), color: theme.mint),
      RestorePhase.error => GhIcon(GhIcons.alertTriangle, size: theme.space(5), color: theme.danger),
      _ => GhIcon(GhIcons.cloudArrowDown, size: theme.space(5), color: theme.accent),
    };
    final cancel = GhButton(onPressed: widget.onClose, label: ghTr('cancel'));
    final footer = switch (_phase) {
      RestorePhase.preview => [
        const Spacer(),
        cancel,
        GhButton(onPressed: _apply, label: _ts('restore_modal_apply_btn'), variant: GhButtonVariant.primary, weight: GhWeight.medium),
      ],
      RestorePhase.error => [
        const Spacer(),
        cancel,
        GhButton(onPressed: _retry, label: ghTr('retry'), variant: GhButtonVariant.outline, weight: GhWeight.medium),
      ],
      RestorePhase.done => [
        const Spacer(),
        GhButton(
          onPressed: _relaunch,
          label: _ts('restart_app'),
          icon: GhIcons.refresh,
          variant: GhButtonVariant.primary,
          weight: GhWeight.medium,
        ),
      ],
      _ => null,
    };
    return GhModalShell(
      icon: icon,
      title: _phase == RestorePhase.done ? _ts('restore_modal_done_title') : _ts('restore_modal_title'),
      maxWidth: GhModalWidth.md,
      onClose: widget.onClose,
      showClose: _phase == RestorePhase.preview || _phase == RestorePhase.error,
      footer: footer,
      child: Padding(padding: EdgeInsets.fromLTRB(theme.space(6), 0, theme.space(6), theme.space(6)), child: _body(theme)),
    );
  }

  Widget _spinner(GhTheme theme, String label) => Padding(
    padding: EdgeInsets.symmetric(vertical: theme.space(4)),
    child: Row(
      spacing: theme.space(3),
      children: [
        GhSpinnerIcon(size: 5, color: theme.accent),
        Text(
          label,
          style: theme.text(size: GhTextSize.sm, color: theme.muted),
        ),
      ],
    ),
  );

  Widget _checkLine(GhTheme theme, String text) => Row(
    spacing: theme.space(2),
    children: [
      GhIcon(GhIcons.check, size: theme.space(3.5), color: theme.mint),
      Expanded(
        child: Text(
          text,
          style: theme.text(size: GhTextSize.xs, color: theme.muted),
        ),
      ),
    ],
  );

  Widget _stat(GhTheme theme, BigInt value, String label) => Container(
    padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2.5)),
    decoration: BoxDecoration(color: theme.overlay, borderRadius: BorderRadius.circular(theme.radiusLg)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: theme.text(size: GhTextSize.lg, weight: GhWeight.semibold, color: theme.ink),
        ),
        Text(
          label,
          style: theme.text(size: GhTextSize.x2s, color: theme.muted),
        ),
      ],
    ),
  );

  Widget _body(GhTheme theme) {
    switch (_phase) {
      case RestorePhase.fetching:
        return _spinner(theme, _ts('restore_modal_fetching'));
      case RestorePhase.applying:
        return _spinner(theme, _ts('restore_modal_applying'));
      case RestorePhase.error:
        return Padding(
          padding: EdgeInsets.symmetric(vertical: theme.space(4)),
          child: GhAlertBox(tone: GhAlertTone.danger, icon: GhIcons.alertTriangle, text: _error ?? ''),
        );
      case RestorePhase.done:
        return Padding(
          padding: EdgeInsets.symmetric(vertical: theme.space(4)),
          child: Column(
            spacing: theme.space(2),
            children: [
              Container(
                width: theme.space(10),
                height: theme.space(10),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: theme.mint.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: GhIcon(GhIcons.check, size: theme.space(5), color: theme.mint),
              ),
              Text(
                _ts('restore_modal_done_hint'),
                textAlign: TextAlign.center,
                style: theme.text(size: GhTextSize.sm, color: theme.muted),
              ),
            ],
          ),
        );
      case RestorePhase.preview:
        final preview = _preview;
        if (preview == null) return const SizedBox.shrink();
        int n(BigInt v) => v.toInt();
        final gap = theme.space(2);
        return Padding(
          padding: EdgeInsets.symmetric(vertical: theme.space(2)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(3),
            children: [
              Text(
                _ts('restore_modal_preview_desc'),
                style: theme.text(size: GhTextSize.sm, color: theme.muted),
              ),
              Column(
                spacing: gap,
                children: [
                  Row(
                    spacing: gap,
                    children: [
                      Expanded(
                        child: _stat(theme, preview.workspaceCount, _ts('restore_modal_workspaces', count: n(preview.workspaceCount))),
                      ),
                      Expanded(child: _stat(theme, preview.projectCount, _ts('restore_modal_projects', count: n(preview.projectCount)))),
                    ],
                  ),
                  Row(
                    spacing: gap,
                    children: [
                      Expanded(
                        child: _stat(theme, preview.categoryCount, _ts('restore_modal_categories', count: n(preview.categoryCount))),
                      ),
                      Expanded(child: _stat(theme, preview.templateCount, _ts('restore_modal_templates', count: n(preview.templateCount)))),
                    ],
                  ),
                ],
              ),
              if (preview.hasTimeStats) _checkLine(theme, _ts('restore_modal_time_stats')),
              if (preview.todoCount > BigInt.zero) _checkLine(theme, _ts('restore_modal_todos', count: n(preview.todoCount))),
              if (preview.projectScanDirs.isNotEmpty)
                _checkLine(theme, _ts('restore_modal_project_scan_dirs', count: preview.projectScanDirs.length)),
              if (preview.versionScanDirs.isNotEmpty)
                _checkLine(theme, _ts('restore_modal_version_scan_dirs', count: preview.versionScanDirs.length)),
              if (preview.workspaceNames.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: theme.space(1)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: theme.space(1),
                    children: [
                      Text(
                        '${_ts('restore_modal_workspace_list')}:',
                        style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.muted),
                      ),
                      Wrap(
                        spacing: theme.space(1.5),
                        runSpacing: theme.space(1.5),
                        children: [
                          for (final name in preview.workspaceNames)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(0.5)),
                              decoration: BoxDecoration(color: theme.overlay, borderRadius: BorderRadius.circular(999)),
                              child: Text(
                                name,
                                style: theme.text(size: GhTextSize.xs, color: theme.ink),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(top: theme.space(1)),
                child: Text(
                  _ts('restore_modal_warning'),
                  style: theme.text(size: GhTextSize.xs, color: theme.amber),
                ),
              ),
            ],
          ),
        );
    }
  }
}
