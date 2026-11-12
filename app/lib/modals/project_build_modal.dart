import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/events.dart';
import '../api/exports.dart';
import '../api/projects.dart';
import '../console/console_request.dart';
import '../design/design.dart';
import '../logic/format_bytes.dart';
import '../shell/placeholder_view.dart';
import '../src/rust/api/dto.dart' as dto;
import '../src/rust/api/types.dart';
import '../state/app_lifecycle.dart';
import '../state/export_template_downloads.dart';
import '../ui/controls/text_input.dart';
import '../ui/core/i18n.dart';
import '../ui/core/ui_settings.dart' show GhSide;
import '../ui/feedback/confirm_dialog.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/overlays/dropdown.dart';
import '../ui/overlays/menu.dart';
import '../ui/reusables/modal_kit.dart';

String _t(String key, {Map<String, Object?> args = const {}}) => ghTr('build_export.$key', args: args);

class ProjectToolsPanel extends StatefulWidget {
  const ProjectToolsPanel({super.key, required this.project, required this.onStarted});

  final Project project;
  final VoidCallback onStarted;

  @override
  State<ProjectToolsPanel> createState() => _ProjectToolsPanelState();
}

class _ProjectToolsPanelState extends State<ProjectToolsPanel> {
  List<ProjectTool>? _tools;
  String? _starting;

  @override
  void initState() {
    super.initState();
    ExportsApi.tools(widget.project.id).then(
      (result) {
        if (mounted) setState(() => _tools = result);
      },
      onError: (Object _) {
        if (mounted) setState(() => _tools = const []);
      },
    );
  }

  Future<void> _run(ProjectTool tool) async {
    setState(() => _starting = tool.id);
    try {
      final id = await ExportsApi.runTool(widget.project.id, tool.id);
      requestOpenConsole(id, name: '${widget.project.name} · ${_t('tool_${tool.id}')}');
      widget.onStarted();
    } catch (reason) {
      ghToasts.pushToast(GhToastType.error, '$reason');
    } finally {
      if (mounted) setState(() => _starting = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tools = _tools;
    if (tools == null) return const SizedBox.shrink();
    final theme = GhTheme.of(context);
    return Container(
      padding: EdgeInsets.only(top: theme.space(5)),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.line))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(2),
        children: [
          GhFieldLabel(_t('tools_title')),
          if (!tools.any((tool) => tool.kind == 'test'))
            Text(_t('tools_no_tests'), style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625)),
          for (final tool in tools)
            Container(
              padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2.5)),
              decoration: BoxDecoration(
                color: theme.overlay,
                borderRadius: BorderRadius.circular(theme.radiusItem),
                border: Border.all(color: theme.line),
              ),
              child: Row(
                spacing: theme.space(3),
                children: [
                  GhIcon(tool.kind == 'test' ? GhIcons.flask : GhIcons.code, size: theme.space(3.5), color: theme.muted),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_t('tool_${tool.id}'), style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink)),
                        Tooltip(
                          message: tool.detail ?? '',
                          child: Text(
                            tool.available ? _t('tool_${tool.id}_hint', args: {'target': tool.detail ?? ''}) : _t('tool_reason_${tool.reason}'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.text(size: GhTextSize.x2s, color: theme.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GhOutlineAction(
                    onPressed: !tool.available || _starting != null ? null : () => _run(tool),
                    icon: GhIcons.play,
                    iconSize: 3,
                    busy: _starting == tool.id,
                    label: _t('tool_run'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class ProjectBuildModal extends ConsumerStatefulWidget {
  const ProjectBuildModal({super.key, required this.project, required this.onClose});

  final Project project;
  final VoidCallback onClose;

  @override
  ConsumerState<ProjectBuildModal> createState() => _ProjectBuildModalState();
}

class _ProjectBuildModalState extends ConsumerState<ProjectBuildModal> {
  final TextEditingController _output = TextEditingController();
  final FocusNode _closeNode = FocusNode(debugLabel: 'ProjectBuildModal close');
  final List<StreamSubscription<AppEvent>> _subscriptions = [];
  dto.ExportCatalog? _catalog;
  int? _selected;
  String _error = '';
  bool _loading = true;
  bool _starting = false;
  bool _mutation = false;
  ExportRun? _run;
  int _sequence = 0;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _output.addListener(() => setState(() {}));
    _subscriptions
      ..add(
        AppEvents.of(AppEventKind.exportTemplatesComplete).listen((event) {
          if (event.text == _catalog?.versionTag) _refresh();
        }),
      )
      ..add(
        AppEvents.of(AppEventKind.exportFinished).listen((event) {
          final finished = event.exportRun;
          if (finished != null && finished.id == _run?.id && mounted) _setRun(finished);
        }),
      );
    _refresh();
  }

  @override
  void dispose() {
    _sequence++;
    _poll?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    _output.dispose();
    _closeNode.dispose();
    super.dispose();
  }

  void _setRun(ExportRun? run) {
    setState(() => _run = run);
    _poll?.cancel();
    _poll = null;
    if (run == null || run.status != 'running') return;
    void tick() {
      if (ghAppHidden()) return;
      ExportsApi.get(run.id).then((next) {
        if (!mounted || _run?.id != run.id) return;
        if (next != _run) {
          setState(() => _run = next);
          if (next.status != 'running') {
            _poll?.cancel();
            _poll = null;
          }
        }
      }, onError: (Object _) {});
    }

    tick();
    _poll = Timer.periodic(const Duration(milliseconds: 700), (_) => tick());
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final request = ++_sequence;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final next = await ExportsApi.presets(widget.project.id);
      final runs = await ExportsApi.list(widget.project.id);
      if (!mounted || request != _sequence) return;
      final active = runs.where((job) => job.status == 'running').firstOrNull;
      setState(() => _catalog = next);
      _setRun(active ?? runs.firstOrNull);
      if (active != null) {
        _selected = next.presets.where((p) => p.name == active.presetName).firstOrNull?.id;
        _output.text = active.outputPath;
      } else if (!next.presets.any((p) => p.id == _selected)) {
        final first = next.presets.firstOrNull;
        _output.text = first?.outputPath ?? '';
        _selected = first?.id;
      }
    } catch (reason) {
      if (mounted && request == _sequence) setState(() => _error = '$reason');
    } finally {
      if (mounted && request == _sequence) setState(() => _loading = false);
    }
  }

  dto.ExportPreset? get _preset => _catalog?.presets.where((p) => p.id == _selected).firstOrNull;

  bool get _running => _run?.status == 'running';

  bool get _blocked {
    final preset = _preset;
    return _loading ||
        _starting ||
        _running ||
        _catalog?.engineError != null ||
        preset == null ||
        preset.templateError != null ||
        preset.missingTemplates.isNotEmpty ||
        _output.text.trim().isEmpty;
  }

  Future<void> _start([bool replace = false]) async {
    final preset = _preset;
    if (preset == null || _blocked || _mutation) return;
    _mutation = true;
    setState(() {
      _starting = true;
      _error = '';
    });
    try {
      final job = await ExportsApi.start(widget.project.id, preset.id, _output.text, replace);
      requestOpenExportConsole(job);
      widget.onClose();
    } catch (reason) {
      final message = '$reason';
      if (!mounted) return;
      if (message.contains('OUTPUT_EXISTS:')) {
        setState(() => _starting = false);
        _mutation = false;
        final ok = await showGhConfirmDialog(
          context,
          title: _t('overwrite_title'),
          description: _t('overwrite_description', args: {'path': _output.text}),
          confirmLabel: _t('overwrite'),
        );
        if (ok && mounted) await _start(true);
        return;
      }
      setState(() => _error = message);
      if (message.contains('INSTALL_EXPORT_TEMPLATES:')) _refresh();
    } finally {
      _mutation = false;
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _browse() async {
    try {
      final name = _output.text.split(RegExp(r'[\\/]')).last;
      final path = await ProjectsApi.pickSavePath(name.isEmpty ? 'game.zip' : name);
      if (path != null && mounted) _output.text = path;
    } catch (reason) {
      ghToasts.pushToast(GhToastType.error, '$reason');
    }
  }

  void _toast(Future<void> action) => action.catchError((Object reason) => ghToasts.pushToast(GhToastType.error, '$reason'));

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final catalog = _catalog;
    final preset = _preset;
    final run = _run;
    final busy = _starting || _running;
    final downloading = catalog != null && ref.watch(exportTemplateDownloadsProvider).containsKey(catalog.versionTag);
    final small = theme.text(size: GhTextSize.xs, color: theme.muted);
    final body = <Widget>[
      Row(
        spacing: theme.space(3),
        children: [
          Expanded(
            child: Text(
              catalog != null && catalog.versionTag.isNotEmpty ? _t('engine', args: {'version': catalog.versionTag}) : _t('release'),
              style: small,
            ),
          ),
          GhOutlineAction(
            onPressed: _loading || busy ? null : _refresh,
            icon: GhIcons.refresh,
            spinIcon: _loading,
            label: _t('refresh'),
          ),
        ],
      ),
    ];
    if (_loading && catalog == null) {
      body.add(
        Row(
          spacing: theme.space(2),
          children: [
            GhSpinnerIcon(size: 4, color: theme.muted),
            Text(_t('loading'), style: theme.text(size: GhTextSize.sm, color: theme.muted)),
          ],
        ),
      );
    } else if (catalog != null) {
      if (catalog.engineError != null) body.add(GhAlertBox(tone: GhAlertTone.amber, text: catalog.engineError, strong: true));
      if (catalog.presets.isEmpty) {
        body.add(
          Container(
            padding: EdgeInsets.all(theme.space(5)),
            decoration: BoxDecoration(
              color: theme.overlay,
              borderRadius: BorderRadius.circular(theme.radiusItem),
              border: Border.all(color: theme.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_t('no_presets'), style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.ink)),
                Padding(
                  padding: EdgeInsets.only(top: theme.space(2), bottom: theme.space(4)),
                  child: Text(_t('no_presets_hint'), style: small.copyWith(height: 1.625)),
                ),
                GhOutlineAction(
                  onPressed: catalog.engineError != null ? null : () => _toast(ProjectsApi.open(widget.project.id, true)),
                  label: _t('open_editor'),
                ),
              ],
            ),
          ),
        );
      } else if (preset != null) {
        body.addAll([
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(2),
            children: [
              GhFieldLabel(_t('preset')),
              GhDropdown(
                align: GhSide.left,
                expand: true,
                items: [
                  for (final p in catalog.presets)
                    GhMenuItem(
                      id: '${p.id}',
                      label: p.name,
                      badge: p.platform,
                      active: p.id == _selected,
                      onSelected: () {
                        setState(() {
                          _selected = p.id;
                          _error = '';
                        });
                        _output.text = p.outputPath;
                      },
                    ),
                ],
                trigger: (context, open, toggle) => GhOutlineAction(
                  onPressed: busy ? null : toggle,
                  expand: true,
                  semanticLabel: _t('preset'),
                  trailingIcon: GhIcons.chevronDown,
                  child: Text.rich(
                    TextSpan(
                      text: preset.name,
                      children: [
                        TextSpan(
                          text: ' · ${preset.platform}',
                          style: TextStyle(color: theme.muted),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(2),
            children: [
              GhFieldLabel(_t('output')),
              Row(
                spacing: theme.space(2),
                children: [
                  Expanded(
                    child: GhTextInput(
                      controller: _output,
                      enabled: !busy,
                      size: GhTextSize.xs,
                      mono: true,
                      background: theme.overlay,
                      borderColor: theme.line,
                      padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2.5)),
                    ),
                  ),
                  GhOutlineAction(onPressed: busy ? null : _browse, icon: GhIcons.folder, iconSize: 4, semanticLabel: _t('browse')),
                ],
              ),
              Text(_t('output_hint'), style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625)),
            ],
          ),
          if (preset.templateError != null) Text(preset.templateError!, style: theme.text(size: GhTextSize.xs, color: theme.danger)),
          if (preset.missingTemplates.isNotEmpty)
            GhAlertBox(
              tone: GhAlertTone.amber,
              strong: true,
              padding: 4,
              text: _t('missing_templates'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: theme.space(2), bottom: theme.space(3)),
                    child: Text(
                      preset.missingTemplates.join(', '),
                      style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted),
                    ),
                  ),
                  GhOutlineAction(
                    onPressed: downloading || busy
                        ? null
                        : () => showPlaceholderModal(context, title: _t('install_templates'), icon: GhIcons.download).ignore(),
                    icon: GhIcons.download,
                    label: downloading ? _t('downloading_templates') : _t('install_templates'),
                  ),
                ],
              ),
            ),
        ]);
      }
    }
    if (_error.isNotEmpty) body.add(GhAlertBox(tone: GhAlertTone.danger, text: _error, strong: true));
    if (run != null) {
      final size = run.sizeBytes;
      body.add(
        Container(
          padding: EdgeInsets.all(theme.space(4)),
          decoration: BoxDecoration(
            color: theme.overlay,
            borderRadius: BorderRadius.circular(theme.radiusItem),
            border: Border.all(color: theme.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                run.status == 'running' ? _t('running', args: {'preset': run.presetName}) : _t(run.status),
                style: theme.text(
                  size: GhTextSize.sm,
                  weight: GhWeight.medium,
                  color: run.status == 'failed'
                      ? theme.danger
                      : run.status == 'succeeded'
                      ? theme.mint
                      : theme.ink,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: theme.space(2)),
                child: Text(
                  '${run.outputPath}${size != null ? ' · ${formatBigBytes(size)}' : ''}',
                  style: theme.text(size: GhTextSize.xs, mono: true, color: theme.muted),
                ),
              ),
              if (run.error != null)
                Padding(
                  padding: EdgeInsets.only(top: theme.space(2)),
                  child: Text(run.error!, style: theme.text(size: GhTextSize.xs, color: theme.danger)),
                ),
              if (run.status == 'cancelled')
                Padding(
                  padding: EdgeInsets.only(top: theme.space(2)),
                  child: Text(_t('cancel_hint'), style: small),
                ),
              if (_running || run.status == 'succeeded')
                Padding(
                  padding: EdgeInsets.only(top: theme.space(3)),
                  child: Row(
                    spacing: theme.space(2),
                    children: [
                      if (_running) GhOutlineAction(onPressed: () => _toast(ExportsApi.cancel(run.id)), label: _t('cancel_export')),
                      if (run.status == 'succeeded')
                        GhOutlineAction(
                          onPressed: () => _toast(ExportsApi.openFolder(run.id)),
                          icon: GhIcons.folder,
                          label: _t('open_folder'),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }
    body.addAll([
      ProjectToolsPanel(project: widget.project, onStarted: widget.onClose),
      Text('${_t('run_hint')} ${_t('platform_tools')}', style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625)),
    ]);
    return GhModalShell(
      icon: GhIcon(GhIcons.rocket, size: theme.space(5), color: theme.accentBright),
      title: _t('title'),
      maxWidth: GhModalWidth.x2l,
      bodyHeight: GhModalShell.tallBodyHeight(context),
      onClose: widget.onClose,
      initialFocus: _closeNode,
      footer: [
        if (run != null)
          GhOutlineAction(
            onPressed: () {
              requestOpenExportConsole(run);
              widget.onClose();
            },
            icon: GhIcons.terminal,
            label: _t('open_console'),
          ),
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: theme.space(2),
          children: [
            GhOutlineAction(onPressed: widget.onClose, focusNode: _closeNode, label: context.tr.common.close),
            GhOutlineAction(
              onPressed: _blocked ? null : _start,
              primary: true,
              icon: GhIcons.rocket,
              busy: _starting,
              label: _starting ? _t('starting') : _t('start'),
            ),
          ],
        ),
      ],
      child: SingleChildScrollView(
        padding: EdgeInsets.all(theme.space(6)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: theme.space(5), children: body),
      ),
    );
  }
}
