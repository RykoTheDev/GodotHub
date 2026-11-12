import 'package:flutter/material.dart';

import '../api/versions.dart';
import '../design/design.dart';
import '../logic/export_template_catalog.dart';
import '../logic/export_template_selection.dart';
import '../logic/format_bytes.dart';
import '../src/rust/api/types.dart';
import '../ui/controls/checkbox.dart';
import '../ui/core/button.dart';
import '../ui/controls/spin.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/core/tooltip.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/reusables/modal_kit.dart';
import '../ui/shell/disclosure.dart';
import 'current_version_modal.dart';

String _tv(String key, {num? count, Map<String, Object?> args = const {}}) => ghTr('versions:$key', count: count, args: args);

int _sum(Iterable<TemplateFile> files, BigInt Function(TemplateFile file) pick) => files.fold(0, (sum, f) => sum + pick(f).toInt());

class ExportTemplatesModal extends StatefulWidget {
  const ExportTemplatesModal({super.key, required this.tag, required this.onClose, required this.onDownload, this.onChanged, this.fetch});

  final String tag;
  final VoidCallback onClose;
  final ValueChanged<List<String>> onDownload;
  final Future<void> Function()? onChanged;
  final TemplateOptionsFetcher? fetch;

  @override
  State<ExportTemplatesModal> createState() => _ExportTemplatesModalState();
}

class _ExportTemplatesModalState extends State<ExportTemplatesModal> {
  late List<TemplateOption> _options = getCachedTemplateOptions(widget.tag) ?? const [];
  List<String> _selected = const [];
  final Set<String> _expanded = {};
  final Set<String> _expandedArchitectures = {};
  final Set<String> _collapsedCategories = {};
  late bool _loading = getCachedTemplateOptions(widget.tag) == null;
  bool _checking = true;
  String _error = '';
  int _attempt = 0;
  List<String> _removing = const [];
  bool _mutation = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final attempt = ++_attempt;
    final cached = getCachedTemplateOptions(widget.tag);
    setState(() {
      _options = cached ?? const [];
      _loading = cached == null;
      _checking = true;
      _error = '';
    });
    try {
      final result = await loadTemplateOptions(widget.tag, refresh: attempt > 1, fetch: widget.fetch);
      if (!mounted || attempt != _attempt) return;
      final available = {
        for (final o in result)
          for (final f in o.files)
            if (!f.installed) f.name,
      };
      final platforms = {for (final o in result) o.id};
      final groups = {
        for (final o in result)
          for (final g in groupTemplateFiles(o.files)) '${o.id}:${g.id}',
      };
      setState(() {
        _options = result;
        _selected = [
          for (final name in _selected)
            if (available.contains(name)) name,
        ];
        _expanded.removeWhere((key) => !platforms.contains(key));
        _expandedArchitectures.removeWhere((key) => !groups.contains(key));
      });
    } catch (reason) {
      if (!mounted || attempt != _attempt) return;
      if (cached != null) {
        ghToasts.pushToast(GhToastType.error, '${_tv('export_templates_options_failed')} $reason', ttlMs: 6000);
      } else {
        setState(() => _error = '$reason');
      }
    } finally {
      if (mounted && attempt == _attempt) {
        setState(() {
          _loading = false;
          _checking = false;
        });
      }
    }
  }

  bool get _busy => _removing.isNotEmpty || _checking;

  void _toggle(List<TemplateFile> files, bool checked) => setState(() => _selected = toggleTemplateFiles(_selected, files, checked));

  Future<void> _uninstall(List<TemplateFile> files) async {
    final names = [
      for (final f in files)
        if (f.installed) f.name,
    ];
    if (_mutation || names.isEmpty) return;
    _mutation = true;
    setState(() => _removing = names);
    try {
      await VersionsApi.uninstallExportTemplateFiles(widget.tag, names);
      final removed = names.toSet();
      final next = [
        for (final option in _options)
          () {
            final files = [
              for (final f in option.files)
                removed.contains(f.name)
                    ? TemplateFile(name: f.name, sizeBytes: f.sizeBytes, downloadBytes: f.downloadBytes, installed: false)
                    : f,
            ];
            return TemplateOption(
              id: option.id,
              label: option.label,
              files: files,
              sizeBytes: option.sizeBytes,
              downloadBytes: option.downloadBytes,
              installed: files.every((f) => f.installed),
            );
          }(),
      ];
      cacheTemplateOptions(widget.tag, next);
      if (mounted) {
        setState(() {
          _options = next;
          _selected = [
            for (final name in _selected)
              if (!removed.contains(name)) name,
          ];
        });
      }
      await widget.onChanged?.call();
      ghToasts.pushToast(GhToastType.success, _tv('export_templates_removed_toast'));
    } catch (reason) {
      ghToasts.pushToast(GhToastType.error, _tv('export_templates_uninstall_failed', args: {'error': '$reason'}), ttlMs: 6000);
    } finally {
      _mutation = false;
      if (mounted) setState(() => _removing = const []);
    }
  }

  Widget _installedMark(GhTheme theme, String label) => GhTooltip(
    message: label,
    child: Semantics(
      checked: true,
      readOnly: true,
      label: label,
      child: Container(
        width: 18,
        height: 18,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.mint.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(theme.radiusSm),
          border: Border.all(color: theme.mint.withValues(alpha: 0.4)),
        ),
        child: GhIcon(GhIcons.check, size: theme.space(3), color: theme.mint),
      ),
    ),
  );

  Widget _selector(GhTheme theme, {required List<TemplateFile> files, required String label}) {
    final available = [
      for (final f in files)
        if (!f.installed) f,
    ];
    if (available.isEmpty) return _installedMark(theme, '$label · ${_tv('export_templates_option_installed')}');
    final selected = _selected.toSet();
    final count = available.where((f) => selected.contains(f.name)).length;
    return GhCheckbox(
      checked: count == available.length,
      indeterminate: count > 0 && count < available.length,
      disabled: _busy,
      label: label,
      onChanged: (checked) => _toggle(files, count < available.length),
    );
  }

  Widget? _uninstallButton(GhTheme theme, List<TemplateFile> files, String label) {
    if (!files.any((f) => f.installed)) return null;
    final name = _tv('export_templates_uninstall_named', args: {'name': label});
    final removing = files.any((f) => _removing.contains(f.name));
    return GhTooltip(
      message: name,
      child: GhPressable(
        onPressed: _busy ? null : () => _uninstall(files),
        semanticLabel: name,
        disabledOpacity: 0.4,
        disabledCursor: SystemMouseCursors.forbidden,
        borderRadius: BorderRadius.circular(theme.radiusBtn),
        builder: (context, states) => GhAnimatedBox(
          color: theme.danger.withValues(alpha: states.active ? 0.1 : 0),
          borderRadius: BorderRadius.circular(theme.radiusBtn),
          padding: EdgeInsets.all(theme.space(1.5)),
          child: removing
              ? GhSpinnerIcon(size: 3, color: theme.muted)
              : GhIcon(GhIcons.trash, size: theme.space(3), color: states.active ? theme.danger : theme.muted.withValues(alpha: 0.6)),
        ),
      ),
    );
  }

  Widget _expandButton(GhTheme theme, {required bool open, required VoidCallback onPressed, required Widget child}) => GhPressable(
    onPressed: onPressed,
    expanded: open,
    borderRadius: BorderRadius.circular(theme.radiusBtn),
    builder: (context, states) => IconTheme.merge(
      data: IconThemeData(color: states.active ? theme.ink : theme.muted),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: states.active ? theme.ink : null),
        child: child,
      ),
    ),
  );

  Widget _fileRow(GhTheme theme, TemplateFile file, {required bool indent}) {
    final selected = _selected.contains(file.name);
    final installedLabel = _tv('export_templates_option_installed');
    return Container(
      key: ValueKey(file.name),
      margin: EdgeInsetsDirectional.only(start: indent ? theme.space(5) : 0),
      padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2.5)),
      decoration: BoxDecoration(
        color: selected ? theme.accent.withValues(alpha: 0.05) : theme.base.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(theme.radiusBtn),
        border: Border.all(color: selected ? theme.accentDim.withValues(alpha: 0.4) : Colors.transparent),
      ),
      child: Row(
        spacing: theme.space(3),
        children: [
          Expanded(
            child: file.installed
                ? Row(
                    spacing: theme.space(2.5),
                    children: [
                      _installedMark(theme, '${file.name} · $installedLabel'),
                      Flexible(child: _fileName(theme, file.name)),
                    ],
                  )
                : GhCheckbox(
                    checked: selected,
                    disabled: _busy,
                    label: file.name,
                    onChanged: (checked) => _toggle([file], checked),
                    child: _fileName(theme, file.name),
                  ),
          ),
          if (file.installed)
            Text(
              installedLabel,
              style: theme.text(size: GhTextSize.x3s, color: theme.mint),
            ),
          Text(
            formatBytes((file.installed ? file.sizeBytes : file.downloadBytes).toInt()),
            style: theme.text(size: GhTextSize.x2s, color: theme.muted).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          ?_uninstallButton(theme, [file], file.name),
        ],
      ),
    );
  }

  Widget _fileName(GhTheme theme, String name) => GhTooltip(
    message: name,
    child: Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.ink),
    ),
  );

  Widget _group(GhTheme theme, TemplateOption option, TemplateFileGroup group) {
    final groupLabel = group.displayLabel();
    final groupName = groupLabel == null ? option.label : (option.id == 'web' ? groupLabel : '${option.label} $groupLabel');
    final available = [
      for (final f in group.files)
        if (!f.installed) f,
    ];
    final installedCount = group.files.length - available.length;
    final fully = available.isEmpty;
    final count = available.where((f) => _selected.contains(f.name)).length;
    final key = '${option.id}:${group.id}';
    final open = group.label == null || _expandedArchitectures.contains(key);
    final installedLabel = _tv('export_templates_option_installed');
    final files = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(1.5),
      children: [for (final f in group.files) _fileRow(theme, f, indent: group.label != null)],
    );
    return Column(
      key: ValueKey(key),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (groupLabel != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: theme.space(1), vertical: theme.space(1)),
            child: Row(
              spacing: theme.space(3),
              children: [
                _selector(theme, files: group.files, label: groupName),
                Expanded(
                  child: _expandButton(
                    theme,
                    open: open,
                    onPressed: () => setState(() => open ? _expandedArchitectures.remove(key) : _expandedArchitectures.add(key)),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: theme.space(1)),
                      child: Row(
                        spacing: theme.space(2),
                        children: [
                          Expanded(
                            child: Text(
                              groupLabel,
                              style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink),
                            ),
                          ),
                          if (installedCount > 0)
                            Text(
                              '${fully ? '' : '$installedCount/${group.files.length} '}$installedLabel',
                              style: theme.text(size: GhTextSize.x3s, color: theme.mint),
                            ),
                          if (!fully)
                            Text(
                              '$count/${available.length}',
                              style: theme.text(size: GhTextSize.x3s, color: theme.muted),
                            ),
                          GhDisclosureChevron(open: open),
                        ],
                      ),
                    ),
                  ),
                ),
                ?_uninstallButton(theme, group.files, groupName),
              ],
            ),
          ),
        GhDisclosure(
          open: open,
          child: Padding(
            padding: EdgeInsets.only(top: group.label != null ? theme.space(1.5) : 0),
            child: files,
          ),
        ),
      ],
    );
  }

  Widget _option(GhTheme theme, TemplateOption option) {
    final available = [
      for (final f in option.files)
        if (!f.installed) f,
    ];
    final installedCount = option.files.length - available.length;
    final selectedCount = available.where((f) => _selected.contains(f.name)).length;
    final fully = available.isEmpty;
    final open = _expanded.contains(option.id);
    final installedLabel = _tv('export_templates_option_installed');
    return Container(
      key: ValueKey(option.id),
      padding: EdgeInsets.all(theme.space(3.5)),
      decoration: BoxDecoration(
        color: theme.overlay,
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            spacing: theme.space(3),
            children: [
              _selector(theme, files: option.files, label: option.label),
              Expanded(
                child: _expandButton(
                  theme,
                  open: open,
                  onPressed: () => setState(() => open ? _expanded.remove(option.id) : _expanded.add(option.id)),
                  child: Row(
                    spacing: theme.space(2),
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.label,
                              style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.ink),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: theme.space(0.5)),
                              child: Text(
                                _tv('export_templates_files', count: option.files.length),
                                style: theme.text(size: GhTextSize.x2s, color: theme.muted),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (installedCount > 0)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(0.5)),
                          decoration: BoxDecoration(
                            color: theme.mint.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(theme.radiusTag),
                            border: Border.all(color: theme.mint.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${fully ? '' : '$installedCount/${option.files.length} '}$installedLabel',
                            style: theme.text(size: GhTextSize.x3s, weight: GhWeight.medium, color: theme.mint),
                          ),
                        ),
                      if (selectedCount > 0)
                        Text(
                          '$selectedCount/${available.length}',
                          style: theme.text(size: GhTextSize.x3s, color: theme.accentBright),
                        ),
                      Text(
                        formatBytes(fully ? option.sizeBytes.toInt() : _sum(available, (f) => f.downloadBytes)),
                        style: theme.text(size: GhTextSize.xs, color: theme.muted),
                      ),
                      GhDisclosureChevron(open: open),
                    ],
                  ),
                ),
              ),
              ?_uninstallButton(theme, option.files, option.label),
            ],
          ),
          GhDisclosure(
            open: open,
            child: Container(
              margin: EdgeInsets.only(top: theme.space(3)),
              padding: EdgeInsets.only(top: theme.space(3)),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.outline.withValues(alpha: 0.5))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: theme.space(3),
                children: [for (final g in groupTemplateFiles(option.files)) _group(theme, option, g)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _category(GhTheme theme, TemplateOptionCategory category) {
    final files = [for (final o in category.options) ...o.files];
    final open = !_collapsedCategories.contains(category.id);
    final label = category.label();
    return Column(
      key: ValueKey(category.id),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.space(1), vertical: theme.space(2)),
          child: Row(
            spacing: theme.space(3),
            children: [
              _selector(theme, files: files, label: label),
              Expanded(
                child: _expandButton(
                  theme,
                  open: open,
                  onPressed: () => setState(() => open ? _collapsedCategories.add(category.id) : _collapsedCategories.remove(category.id)),
                  child: Row(
                    spacing: theme.space(2),
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.muted),
                        ),
                      ),
                      GhDisclosureChevron(open: open),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        GhDisclosure(
          open: open,
          child: Padding(
            padding: EdgeInsets.only(top: theme.space(2.5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(2.5),
              children: [for (final o in category.options) _option(theme, o)],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final allFiles = [for (final o in _options) ...o.files];
    final available = [
      for (final f in allFiles)
        if (!f.installed) f,
    ];
    final selected = _selected.toSet();
    final chosen = [
      for (final f in available)
        if (selected.contains(f.name)) f,
    ];
    final allSelected = available.isNotEmpty && chosen.length == available.length;
    final Widget body;
    if (_loading) {
      body = Padding(
        padding: EdgeInsets.symmetric(vertical: theme.space(12)),
        child: ModalSpinnerLabel(label: _tv('export_templates_loading_options')),
      );
    } else if (_error.isNotEmpty) {
      body = Container(
        padding: EdgeInsets.all(theme.space(4)),
        decoration: BoxDecoration(
          color: theme.danger.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(theme.radiusItem),
          border: Border.all(color: theme.danger.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tv('export_templates_options_failed'),
              style: theme.text(size: GhTextSize.sm, color: theme.danger),
            ),
            Padding(
              padding: EdgeInsets.only(top: theme.space(2), bottom: theme.space(4)),
              child: Text(
                _error,
                style: theme.text(size: GhTextSize.sm, color: theme.muted),
              ),
            ),
            GhOutlineAction(onPressed: _load, label: ghTr('try_again')),
          ],
        ),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(3),
        children: [
          Row(
            spacing: theme.space(3),
            children: [
              Text(
                _tv('export_templates_available', count: _options.length),
                style: theme.text(size: GhTextSize.xs, color: theme.muted),
              ),
              const Spacer(),
              GhTooltip(
                message: _tv('export_templates_refresh'),
                child: GhPressable(
                  onPressed: _busy ? null : _load,
                  semanticLabel: _tv('export_templates_refresh'),
                  disabledOpacity: 0.4,
                  borderRadius: BorderRadius.circular(theme.radiusBtn),
                  builder: (context, states) {
                    Widget glyph = GhIcon(GhIcons.refresh, size: theme.space(3), color: states.active ? theme.ink : theme.muted);
                    if (_checking) glyph = GhSpinning(child: glyph);
                    return GhAnimatedBox(
                      color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
                      borderRadius: BorderRadius.circular(theme.radiusBtn),
                      padding: EdgeInsets.all(theme.space(1.5)),
                      child: glyph,
                    );
                  },
                ),
              ),
              GhPressable(
                onPressed: _busy || available.isEmpty
                    ? null
                    : () => setState(() => _selected = allSelected ? const [] : [for (final f in available) f.name]),
                disabledOpacity: 0.4,
                borderRadius: BorderRadius.circular(theme.radiusBtn),
                builder: (context, states) => GhAnimatedBox(
                  color: theme.accent.withValues(alpha: states.active ? 0.1 : 0),
                  borderRadius: BorderRadius.circular(theme.radiusBtn),
                  padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(1.5)),
                  child: Text(
                    allSelected ? _tv('clear_selection') : _tv('export_templates_select_all'),
                    style: theme.text(size: GhTextSize.xs, color: theme.accentBright),
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(2.5),
            children: [for (final c in groupTemplateOptions(_options)) _category(theme, c)],
          ),
          Text(
            _tv('export_templates_keep_existing'),
            style: theme.text(size: GhTextSize.x2s, color: theme.muted.withValues(alpha: 0.7), lineHeight: 1.625),
          ),
        ],
      );
    }
    return GhModalShell(
      icon: GhIcon(GhIcons.download, size: theme.space(5), color: theme.accentBright),
      title: _tv('export_templates_choose'),
      maxWidth: GhModalWidth.x2l,
      bodyHeight: GhModalShell.tallBodyHeight(context),
      onClose: widget.onClose,
      footer: [
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _tv('export_templates_selected', count: chosen.length),
                  style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink),
                ),
                if (chosen.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: theme.space(1)),
                    child: Text(
                      _tv(
                        'export_templates_size_summary',
                        args: {
                          'download': formatBytes(_sum(chosen, (f) => f.downloadBytes)),
                          'installed': formatBytes(_sum(chosen, (f) => f.sizeBytes)),
                        },
                      ),
                      style: theme.text(size: GhTextSize.x2s, color: theme.muted),
                    ),
                  ),
              ],
            ),
          ),
        ),
        GhButton(onPressed: widget.onClose, label: ghTr('cancel'), variant: GhButtonVariant.outline),
        GhBusyButton(
          onPressed: _loading || _error.isNotEmpty || _busy || chosen.isEmpty
              ? null
              : () => widget.onDownload([for (final f in chosen) f.name]),
          busy: false,
          icon: GhIcons.download,
          paddingX: 4,
          label: _tv('export_templates_download_selected'),
        ),
      ],
      child: SingleChildScrollView(padding: EdgeInsets.fromLTRB(theme.space(6), 0, theme.space(6), theme.space(6)), child: body),
    );
  }
}
