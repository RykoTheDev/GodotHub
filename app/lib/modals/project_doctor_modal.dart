import 'dart:async';

import 'package:flutter/material.dart';

import '../api/events.dart';
import '../api/projects.dart';
import '../api/versions.dart';
import '../design/design.dart';
import '../logic/format_bytes.dart';
import '../shell/placeholder_view.dart';
import '../src/rust/api/dto.dart' as dto;
import '../src/rust/api/types.dart';
import '../state/app_signals.dart';
import '../state/keyboard_shortcuts.dart' show setTabSignal;
import '../state/projects.dart' show projectHealthChangedSignal;
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/core/ui_settings.dart' show GhSide;
import '../ui/feedback/confirm_dialog.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/overlays/dropdown.dart';
import '../ui/overlays/menu.dart';
import '../ui/reusables/modal_kit.dart';
import '../ui/shell/disclosure.dart';

const doctorCategories = ['engine', 'templates', 'android', 'cache', 'scenes', 'addons', 'git', 'exports', 'registrations'];
const _translatedDetails = {'android_possible', 'android_sdk_incomplete'};
const _rank = {'error': 0, 'warning': 1, 'info': 2, 'ok': 3};

String _t(String key, {num? count, Map<String, Object?> args = const {}}) => ghTr('project_doctor.$key', count: count, args: args);

String _bare(String tag) => tag.replaceFirst(RegExp('^v'), '');

class ProjectDoctorModal extends StatefulWidget {
  const ProjectDoctorModal({super.key, required this.project, required this.installedVersions, required this.onClose});

  final Project project;
  final List<InstalledGodotVersion> installedVersions;
  final VoidCallback onClose;

  @override
  State<ProjectDoctorModal> createState() => _ProjectDoctorModalState();
}

class _ProjectDoctorModalState extends State<ProjectDoctorModal> {
  final List<StreamSubscription<AppEvent>> _subscriptions = [];
  dto.HealthReport? _report;
  bool _loading = true;
  String _error = '';
  String? _busy;
  bool _showPassed = false;
  bool _queuedVersion = false;
  bool _mutation = false;
  int _sequence = 0;

  String get _version => widget.project.godotVersion;

  @override
  void initState() {
    super.initState();
    _subscriptions
      ..add(
        AppEvents.of(AppEventKind.godotDownloadComplete).listen((event) {
          if (event.text != _version || !mounted) return;
          setState(() => _queuedVersion = false);
          _scan();
        }),
      )
      ..add(
        AppEvents.of(AppEventKind.godotDownloadCanceled).listen((event) {
          if (event.text == _version && mounted) setState(() => _queuedVersion = false);
        }),
      )
      ..add(
        AppEvents.of(AppEventKind.godotDownloadError).listen((event) {
          final failure = event.downloadFailure;
          if (failure == null || failure.tag != _version || !mounted) return;
          setState(() {
            _queuedVersion = false;
            _error = failure.message;
          });
        }),
      );
    _scan();
  }

  @override
  void dispose() {
    _sequence++;
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }

  Future<void> _scan() async {
    if (!mounted) return;
    final sequence = ++_sequence;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final result = await ProjectsApi.diagnose(widget.project.id);
      if (mounted && sequence == _sequence) setState(() => _report = result);
    } catch (reason) {
      if (mounted && sequence == _sequence) setState(() => _error = '$reason');
    } finally {
      if (mounted && sequence == _sequence) setState(() => _loading = false);
    }
  }

  void _changed() => AppSignals.emit(projectHealthChangedSignal);

  Future<void> _run(String id, Future<void> Function() action) async {
    if (_mutation) return;
    _mutation = true;
    setState(() {
      _busy = id;
      _error = '';
    });
    try {
      await action();
    } catch (reason) {
      if (mounted) setState(() => _error = '$reason');
    } finally {
      _mutation = false;
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _apply(dto.HealthCheck finding) => _run(finding.id, () async {
    await ProjectsApi.fixHealth(widget.project.id, finding.id);
    _changed();
    ghToasts.pushToast(GhToastType.success, _t('fix_complete'));
    if (finding.action?.kind == 'remove_registration' && finding.action?.target == widget.project.id) {
      widget.onClose();
    } else {
      await _scan();
    }
  });

  Future<void> _bind(String tag) => _run('binding', () async {
    await ProjectsApi.update(widget.project.id, ProjectUpdate(godotVersion: tag));
    _changed();
    await _scan();
  });

  Future<void> _installBoundVersion(dto.HealthCheck finding) => _run(finding.id, () async {
    final mono = _version.endsWith('-mono');
    final tag = _bare(_version.replaceFirst(RegExp(r'-mono$'), ''));
    GodotRelease? release;
    for (final source in const ['github', 'archive']) {
      final releases = await VersionsApi.fetchAvailable(source);
      release = releases.where((r) => _bare(r.tag) == tag).firstOrNull;
      if (release != null) break;
    }
    final asset = release?.assets.where((a) => a.isMono == mono).firstOrNull;
    if (release == null || asset == null) throw _t('version_asset_unavailable');
    await VersionsApi.download(release.tag, asset.name, asset.downloadUrl);
    if (mounted) setState(() => _queuedVersion = true);
    ghToasts.pushToast(GhToastType.success, _t('version_queued'));
  });

  void _manageVersions() {
    widget.onClose();
    AppSignals.emit(setTabSignal, 'versions');
  }

  Future<void> _press(dto.HealthCheck finding) async {
    final action = finding.action!;
    final kind = action.kind;
    if (action.confirm) {
      final ok = await showGhConfirmDialog(
        context,
        title: _t('action_$kind'),
        description: _t('confirm_$kind'),
        confirmLabel: _t('action_$kind'),
        variant: kind == 'enable_addon' ? GhConfirmVariant.normal : GhConfirmVariant.danger,
      );
      if (ok && mounted) await _apply(finding);
      return;
    }
    switch (kind) {
      case 'templates':
        await showPlaceholderModal(context, title: _t('action_templates'), icon: GhIcons.download);
      case 'install_version':
        await _installBoundVersion(finding);
      case 'manage_versions':
        _manageVersions();
      case 'open_editor':
        await _run(finding.id, () => ProjectsApi.open(widget.project.id, true));
      case 'open_presets' || 'open_addons':
        await _run(finding.id, () => ProjectsApi.openInEditor(widget.project.path));
      default:
        await _apply(finding);
    }
  }

  Widget? _action(dto.HealthCheck finding) {
    final kind = finding.action?.kind;
    if (kind == null) return null;
    final idle = _busy == null && !_loading;
    if (kind == 'choose_version') {
      return GhDropdown(
        align: GhSide.left,
        items: [
          for (final v in widget.installedVersions)
            GhMenuItem(id: v.tag, label: (v.customName?.isNotEmpty ?? false) ? v.customName! : v.tag, onSelected: () => _bind(v.tag)),
        ],
        trigger: (context, open, toggle) => GhOutlineAction(
          onPressed: idle && widget.installedVersions.isNotEmpty ? toggle : null,
          label: _t('action_choose_version'),
          trailingIcon: GhIcons.chevronDown,
          iconSize: 3,
        ),
      );
    }
    final queued = kind == 'install_version' && _queuedVersion;
    return GhOutlineAction(
      onPressed: idle && !queued ? () => _press(finding) : null,
      busy: _busy == finding.id,
      iconSize: 3,
      label: _t(queued ? 'version_queued_short' : 'action_$kind'),
    );
  }

  Widget _row(GhTheme theme, dto.HealthCheck finding, {required bool last}) {
    final severity = finding.severity;
    final icon = severity == 'ok'
        ? GhIcons.checkCircle
        : severity == 'info'
        ? GhIcons.info
        : GhIcons.alertTriangle;
    final tone = switch (severity) {
      'error' => theme.danger,
      'warning' => theme.amber,
      'ok' => theme.mint,
      _ => theme.muted,
    };
    final values = <String, Object?>{...finding.values, 'size': formatBytes(num.tryParse(finding.values['bytes'] ?? '') ?? 0)};
    final action = _action(finding);
    return Container(
      padding: EdgeInsets.symmetric(vertical: theme.space(4)),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: theme.line.withValues(alpha: 0.7))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: theme.space(3),
        children: [
          Padding(
            padding: EdgeInsets.only(top: theme.space(0.5)),
            child: GhIcon(icon, size: theme.space(4), color: tone),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: theme.space(3),
                  runSpacing: theme.space(1),
                  children: [
                    Text(
                      _t('${finding.code}_title', args: values),
                      style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.ink),
                    ),
                    Text(
                      _t('severity_$severity'),
                      style: theme.text(size: GhTextSize.x3s, weight: GhWeight.medium, color: tone),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(top: theme.space(1)),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: theme.rem(40)),
                    child: Text(
                      _t('${finding.code}_description', args: values),
                      style: theme.text(size: GhTextSize.xs, color: theme.muted, lineHeight: 1.625),
                    ),
                  ),
                ),
                if (finding.details.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: theme.space(2)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: theme.space(1),
                      children: [
                        for (final detail in finding.details)
                          Text(
                            _translatedDetails.contains(finding.code) ? _t(detail) : detail,
                            style: theme.text(
                              size: GhTextSize.x2s,
                              mono: !_translatedDetails.contains(finding.code),
                              color: theme.muted.withValues(alpha: 0.8),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (action != null)
                  Padding(
                    padding: EdgeInsets.only(top: theme.space(3)),
                    child: action,
                  ),
                if (finding.action?.kind == 'choose_version' && widget.installedVersions.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: theme.space(2)),
                    child: GhOutlineAction(onPressed: _manageVersions, label: _t('action_manage_versions')),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _rows(GhTheme theme, List<dto.HealthCheck> entries) => [
    for (var i = 0; i < entries.length; i++) _row(theme, entries[i], last: i == entries.length - 1),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final report = _report;
    final passed = report?.checks.where((c) => c.severity == 'ok').toList() ?? const <dto.HealthCheck>[];
    final findings = report?.checks.where((c) => c.severity != 'ok').toList() ?? const <dto.HealthCheck>[];
    final errors = findings.where((c) => c.severity == 'error').length;
    final warnings = findings.where((c) => c.severity == 'warning').length;
    final summary = _loading
        ? _t('scanning')
        : errors > 0
        ? _t('summary_errors', count: errors)
        : warnings > 0
        ? _t('summary_warnings', count: warnings)
        : report != null
        ? _t('summary_ready')
        : _t('scan_failed');
    final sections = <Widget>[];
    if (report != null) {
      for (final category in doctorCategories) {
        final entries = findings.where((c) => c.category == category).toList()
          ..sort((a, b) => (_rank[a.severity] ?? 3) - (_rank[b.severity] ?? 3));
        if (entries.isEmpty) continue;
        sections.add(
          Padding(
            padding: EdgeInsets.only(top: theme.space(5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _t('category_$category'),
                  style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: theme.muted),
                ),
                ..._rows(theme, entries),
              ],
            ),
          ),
        );
      }
      if (passed.isNotEmpty) {
        sections.add(
          Container(
            margin: EdgeInsets.only(top: theme.space(5)),
            padding: EdgeInsets.only(top: theme.space(4)),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GhPressable(
                  onPressed: () => setState(() => _showPassed = !_showPassed),
                  expanded: _showPassed,
                  borderRadius: BorderRadius.circular(theme.radiusBtn),
                  builder: (context, states) => Row(
                    spacing: theme.space(2),
                    children: [
                      GhIcon(GhIcons.checkCircle, size: theme.space(3.5), color: theme.mint),
                      Expanded(
                        child: Text(
                          _t('passed_checks', count: passed.length),
                          style: theme.text(size: GhTextSize.xs, color: states.active ? theme.ink : theme.muted),
                        ),
                      ),
                      IconTheme.merge(
                        data: IconThemeData(color: states.active ? theme.ink : theme.muted),
                        child: GhDisclosureChevron(open: _showPassed),
                      ),
                    ],
                  ),
                ),
                GhDisclosure(
                  open: _showPassed,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _rows(theme, passed)),
                ),
              ],
            ),
          ),
        );
      }
    }
    return GhModalShell(
      icon: GhIcon(GhIcons.bug, size: theme.space(5), color: theme.accentBright),
      title: _t('title'),
      maxWidth: GhModalWidth.x3l,
      bodyHeight: GhModalShell.tallBodyHeight(context),
      onClose: widget.onClose,
      footer: [
        Expanded(
          child: Text(
            _t('local_checks'),
            style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625),
          ),
        ),
        GhOutlineAction(onPressed: _manageVersions, label: _t('action_manage_versions')),
        GhOutlineAction(onPressed: widget.onClose, label: context.tr.common.close),
      ],
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(theme.space(6), 0, theme.space(6), theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.only(bottom: theme.space(4)),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.line)),
              ),
              child: Row(
                spacing: theme.space(3),
                children: [
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary,
                            style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.ink),
                          ),
                          if (report != null)
                            Padding(
                              padding: EdgeInsets.only(top: theme.space(1)),
                              child: Text(
                                _t('summary_counts', args: {'passed': passed.length, 'findings': findings.length}),
                                style: theme.text(size: GhTextSize.xs, color: theme.muted),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  GhOutlineAction(
                    onPressed: _loading || _busy != null ? null : _scan,
                    icon: GhIcons.refresh,
                    iconSize: 3,
                    spinIcon: _loading,
                    label: _t('run_again'),
                  ),
                ],
              ),
            ),
            if (_error.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: theme.space(4)),
                child: GhAlertBox(tone: GhAlertTone.danger, text: _error),
              ),
            if (_loading && report == null)
              Padding(
                padding: EdgeInsets.symmetric(vertical: theme.space(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: theme.space(3),
                  children: [
                    GhSpinnerIcon(size: 4, color: theme.muted),
                    Text(
                      _t('scanning'),
                      style: theme.text(size: GhTextSize.sm, color: theme.muted),
                    ),
                  ],
                ),
              ),
            if (report != null)
              Opacity(
                opacity: _loading ? 0.6 : 1,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: sections),
              ),
          ],
        ),
      ),
    );
  }
}
