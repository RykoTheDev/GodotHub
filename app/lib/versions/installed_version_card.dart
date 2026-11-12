import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/design.dart';
import '../logic/format_bytes.dart';
import '../modals/current_version_modal.dart';
import '../modals/export_templates_modal.dart';
import '../src/rust/api/types.dart';
import '../state/export_template_downloads.dart';
import '../ui/controls/text_input.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/core/tooltip.dart';
import '../ui/feedback/confirm_dialog.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/overlays/menu.dart';
import '../ui/reusables/modal_kit.dart';
import '../ui/reusables/open_button.dart';
import 'version_logic.dart';

String _tv(String key, {num? count, Map<String, Object?> args = const {}}) => ghTr('versions:$key', count: count, args: args);

class InstalledVersionCard extends StatefulWidget {
  const InstalledVersionCard({
    super.key,
    required this.version,
    required this.isCurrent,
    required this.onOpen,
    required this.onRename,
    required this.onSetCurrent,
    required this.onClearCurrent,
    required this.onManageAliases,
    required this.onUninstall,
    this.templates,
    this.templateDownload,
    this.onInstallTemplates,
    this.onCancelTemplates,
    this.onRemoveTemplates,
    this.onOpenTemplates,
    this.onTemplatesChanged,
    this.onOpenFolder,
  });

  final InstalledGodotVersion version;
  final bool isCurrent;
  final void Function(bool? console) onOpen;
  final ValueChanged<String?> onRename;
  final Future<CurrentVersionInfo> Function() onSetCurrent;
  final Future<void> Function() onClearCurrent;
  final VoidCallback onManageAliases;
  final VoidCallback onUninstall;
  final ExportTemplatesVersionInfo? templates;
  final ExportTemplateDownload? templateDownload;
  final ValueChanged<List<String>>? onInstallTemplates;
  final VoidCallback? onCancelTemplates;
  final VoidCallback? onRemoveTemplates;
  final VoidCallback? onOpenTemplates;
  final Future<void> Function()? onTemplatesChanged;
  final ValueChanged<String>? onOpenFolder;

  @override
  State<InstalledVersionCard> createState() => _InstalledVersionCardState();
}

class _InstalledVersionCardState extends State<InstalledVersionCard> {
  final TextEditingController _edit = TextEditingController();
  final FocusNode _editNode = FocusNode(debugLabel: 'InstalledVersionCard rename');
  bool _editing = false;
  bool _hovered = false;

  InstalledGodotVersion get _v => widget.version;

  @override
  void initState() {
    super.initState();
    _editNode.addListener(() {
      if (!_editNode.hasFocus && _editing) _commit();
    });
  }

  @override
  void dispose() {
    _edit.dispose();
    _editNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() => _editing = true);
    _edit.text = _v.customName ?? _v.tag;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _editNode.requestFocus();
    });
  }

  void _commit() {
    if (_editing) {
      final trimmed = _edit.text.trim();
      widget.onRename(trimmed.isEmpty ? null : trimmed);
    }
    setState(() => _editing = false);
  }

  void _cancel() => setState(() => _editing = false);

  Future<void> _setCurrent() async {
    try {
      final info = await widget.onSetCurrent();
      if (!mounted) return;
      await showGhModal<void>(context, (modal) => CurrentVersionModal(info: info, onClose: () => Navigator.of(modal).pop()));
    } catch (e) {
      ghToasts.pushToast(GhToastType.error, '$e');
    }
  }

  Future<void> _clearCurrent() async {
    try {
      await widget.onClearCurrent();
    } catch (e) {
      ghToasts.pushToast(GhToastType.error, '$e');
    }
  }

  Future<void> _confirmUninstall() async {
    final ok = await showGhConfirmDialog(
      context,
      title: ghTr('version_uninstall_title'),
      description: _v.managedBy == 'mise'
          ? _tv('mise_uninstall_desc', args: {'tag': _v.tag})
          : ghTr('version_uninstall_desc', args: {'tag': _v.tag}),
      confirmLabel: ghTr('version_uninstall_confirm'),
      variant: GhConfirmVariant.danger,
    );
    if (ok) widget.onUninstall();
  }

  Future<void> _openTemplatesDialog() => showGhModal<void>(
    context,
    (modal) => ExportTemplatesModal(
      tag: _v.tag,
      onChanged: widget.onTemplatesChanged,
      onDownload: (files) {
        Navigator.of(modal).pop();
        widget.onInstallTemplates?.call(files);
      },
      onClose: () => Navigator.of(modal).pop(),
    ),
  );

  Future<void> _confirmRemoveTemplates() async {
    final ok = await showGhConfirmDialog(
      context,
      title: _tv('export_templates_remove_title'),
      description: _tv('export_templates_remove_desc', args: {'tag': _v.tag}),
      confirmLabel: _tv('export_templates_remove_confirm'),
      variant: GhConfirmVariant.danger,
    );
    if (ok) widget.onRemoveTemplates?.call();
  }

  Widget _badge(
    GhTheme theme,
    String label, {
    required Color background,
    required Color foreground,
    required Color border,
    FaIconData? icon,
    bool mono = false,
  }) => Container(
    padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(0.5)),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(theme.radiusTag),
      border: Border.all(color: border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: theme.space(1),
      children: [
        if (icon != null) GhIcon(icon, size: theme.space(2.5), color: foreground),
        Text(
          label,
          style: theme.text(size: GhTextSize.x3s, weight: GhWeight.semibold, mono: mono, color: foreground),
        ),
      ],
    ),
  );

  Widget _accentBadge(GhTheme theme, String label, {FaIconData? icon}) => _badge(
    theme,
    label,
    icon: icon,
    background: theme.accent.withValues(alpha: 0.15),
    foreground: theme.accentBright,
    border: theme.accentDim.withValues(alpha: 0.4),
  );

  Widget _mintBadge(GhTheme theme, String label, {bool mono = false}) => _badge(
    theme,
    label,
    mono: mono,
    background: theme.mint.withValues(alpha: 0.1),
    foreground: theme.mint,
    border: theme.mint.withValues(alpha: 0.3),
  );

  Widget _templateChip(GhTheme theme) {
    final templates = widget.templates;
    final download = widget.templateDownload;
    final busy = download != null || (templates?.downloading ?? false);
    if (busy) {
      final percent = download != null && download.total > 0 ? (download.downloaded / download.total * 100).round().clamp(0, 100) : null;
      final label = download == null
          ? _tv('downloading_update')
          : download.stage == 'extracting'
          ? ghTr('export_templates_extracting')
          : download.stage == 'verifying'
          ? ghTr('export_templates_verifying')
          : percent != null
          ? '$percent%'
          : _tv('downloading_update');
      final tooltip = [
        if (download?.platforms?.isNotEmpty ?? false) download!.platforms!.join(', '),
        if (download?.file?.isNotEmpty ?? false) download!.file!,
      ].join(' · ');
      return Row(
        mainAxisSize: MainAxisSize.min,
        spacing: theme.space(1),
        children: [
          GhTooltip(
            message: tooltip,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(0.5)),
              decoration: BoxDecoration(
                color: theme.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(theme.radiusTag),
                border: Border.all(color: theme.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: theme.space(1),
                children: [
                  GhSpinnerIcon(size: 2.5, color: theme.amber),
                  Text(
                    label,
                    style: theme.text(size: GhTextSize.x3s, weight: GhWeight.semibold, color: theme.amber),
                  ),
                ],
              ),
            ),
          ),
          if (widget.onCancelTemplates != null)
            GhTooltip(
              message: _tv('cancel_download'),
              child: GhPressable(
                onPressed: widget.onCancelTemplates,
                semanticLabel: _tv('cancel_download'),
                borderRadius: BorderRadius.circular(theme.radiusBtn),
                builder: (context, states) => GhAnimatedBox(
                  width: theme.space(5),
                  height: theme.space(5),
                  color: theme.danger.withValues(alpha: states.active ? 0.1 : 0),
                  borderRadius: BorderRadius.circular(theme.radiusBtn),
                  alignment: Alignment.center,
                  child: GhIcon(GhIcons.x, size: theme.space(3), color: states.active ? theme.danger : theme.muted.withValues(alpha: 0.5)),
                ),
              ),
            ),
        ],
      );
    }
    if (templates?.installed ?? false) {
      final platforms = templates!.platforms.join(', ');
      return GhTooltip(
        message: '${templates.folder} · $platforms · ${formatBytes(templates.sizeBytes.toInt())}',
        child: GhPressable(
          onPressed: _openTemplatesDialog,
          borderRadius: BorderRadius.circular(theme.radiusTag),
          builder: (context, states) => _badge(
            theme,
            '${_tv('export_templates_installed')}${platforms.isNotEmpty ? ' · $platforms' : ''}',
            icon: GhIcons.check,
            background: theme.mint.withValues(alpha: states.active ? 0.2 : 0.1),
            foreground: theme.mint,
            border: theme.mint.withValues(alpha: 0.3),
          ),
        ),
      );
    }
    if (widget.onInstallTemplates == null) return const SizedBox.shrink();
    return GhTooltip(
      message: _tv('export_templates_install'),
      child: GhPressable(
        onPressed: _openTemplatesDialog,
        semanticLabel: _tv('export_templates_install'),
        borderRadius: BorderRadius.circular(theme.radiusTag),
        builder: (context, states) => _badge(
          theme,
          _tv('export_templates_missing'),
          icon: GhIcons.download,
          background: theme.overlay,
          foreground: states.active ? theme.amber : theme.muted,
          border: states.active ? theme.amber.withValues(alpha: 0.4) : theme.outline.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  List<GhMenuItem> _menu() {
    final templates = widget.templates;
    final installed = templates?.installed ?? false;
    return [
      GhMenuItem(id: 'rename', label: _tv('rename'), icon: GhIcons.pencil, onSelected: _startEditing),
      GhMenuItem(
        id: 'current',
        label: widget.isCurrent ? _tv('unset_current') : _tv('set_as_current'),
        icon: GhIcons.pin,
        onSelected: widget.isCurrent ? _clearCurrent : _setCurrent,
      ),
      GhMenuItem(id: 'alias', label: _tv('alias_create'), icon: GhIcons.terminal, onSelected: widget.onManageAliases),
      GhMenuItem(id: 'open', label: _tv('open_editor'), icon: GhIcons.rocket, onSelected: () => widget.onOpen(null)),
      if (_v.supportsConsole)
        GhMenuItem(
          id: 'open-console',
          label: _tv('open_editor_with_console'),
          icon: GhIcons.terminal,
          onSelected: () => widget.onOpen(true),
        ),
      GhMenuItem(
        id: 'folder',
        label: _tv('open_install_folder'),
        icon: GhIcons.externalLink,
        onSelected: () {
          final dir = installFolderOf(_v.executablePath);
          if (dir.isNotEmpty) (widget.onOpenFolder ?? openFolderOrToast)(dir);
        },
      ),
      if (installed) ...[
        GhMenuItem(
          id: 'templates-folder',
          label: _tv('export_templates_open_folder'),
          icon: GhIcons.externalLink,
          onSelected: widget.onOpenTemplates,
        ),
        GhMenuItem(
          id: 'templates-reinstall',
          label: _tv('export_templates_choose'),
          icon: GhIcons.download,
          onSelected: _openTemplatesDialog,
        ),
        GhMenuItem(id: 'templates-remove', label: _tv('export_templates_remove'), icon: GhIcons.trash, onSelected: _confirmRemoveTemplates),
      ] else if (widget.onInstallTemplates != null)
        GhMenuItem(
          id: 'templates-install',
          label: _tv('export_templates_install'),
          icon: GhIcons.download,
          onSelected: _openTemplatesDialog,
        ),
      GhMenuItem(
        id: 'uninstall',
        label: _tv('version_uninstall_confirm'),
        icon: GhIcons.trash,
        danger: true,
        dividerAfter: true,
        onSelected: _confirmUninstall,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final v = _v;
    final download = widget.templateDownload;
    final busy = download != null || (widget.templates?.downloading ?? false);
    final radius = BorderRadius.circular(theme.radiusItem);
    final Widget head;
    if (_editing) {
      head = Row(
        spacing: theme.space(1.5),
        children: [
          SizedBox(
            width: theme.space(48),
            child: GhTextInput(
              controller: _edit,
              focusNode: _editNode,
              mono: true,
              onSubmitted: (_) => _commit(),
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
                  _cancel();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              background: theme.raised,
              borderColor: theme.accent,
              focusBorderColor: theme.accent,
              borderRadius: BorderRadius.circular(theme.radiusBtn),
              padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
            ),
          ),
          GhPressable(
            onPressed: _commit,
            semanticLabel: ghTr('version_save_name_aria'),
            borderRadius: BorderRadius.circular(theme.radiusBtn),
            builder: (context, states) => GhAnimatedBox(
              color: theme.accent.withValues(alpha: states.active ? 0.1 : 0),
              borderRadius: BorderRadius.circular(theme.radiusBtn),
              padding: EdgeInsets.all(theme.space(1.5)),
              child: GhIcon(GhIcons.check, size: theme.space(4), color: theme.accent),
            ),
          ),
        ],
      );
    } else {
      head = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: theme.space(1.5),
            runSpacing: theme.space(1),
            children: [
              Text(
                (v.customName?.isNotEmpty ?? false) ? v.customName! : v.tag,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.text(size: GhTextSize.xl, weight: GhWeight.medium, color: theme.ink),
              ),
              GhPressable(
                onPressed: _startEditing,
                semanticLabel: ghTr('version_rename_aria'),
                borderRadius: BorderRadius.circular(theme.radiusBtn),
                builder: (context, states) => GhAnimatedBox(
                  color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
                  borderRadius: BorderRadius.circular(theme.radiusBtn),
                  padding: EdgeInsets.all(theme.space(1)),
                  child: GhIcon(
                    GhIcons.pencil,
                    size: theme.space(3.5),
                    color: states.active ? theme.ink : theme.muted.withValues(alpha: 0.6),
                  ),
                ),
              ),
              v.isMono
                  ? _accentBadge(theme, _tv('mono'))
                  : _badge(
                      theme,
                      _tv('standard'),
                      background: Colors.black.withValues(alpha: 0.15),
                      foreground: theme.muted,
                      border: theme.outline.withValues(alpha: 0.4),
                    ),
              if (widget.isCurrent) _accentBadge(theme, _tv('cleanup_current_badge'), icon: GhIcons.pin),
              if (v.managedBy == 'custom') _accentBadge(theme, _tv('custom_build_badge')),
              if (v.managedBy == 'mise') _mintBadge(theme, _tv('managed_by_mise'), mono: true),
              if (v.supportsConsole) _mintBadge(theme, _tv('console_title')),
              _templateChip(theme),
            ],
          ),
          if ((v.customName?.isNotEmpty ?? false) && v.customName != v.tag)
            Padding(
              padding: EdgeInsets.only(top: theme.space(1)),
              child: Text(
                '${_tv('original_name')}: ${v.tag}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.text(size: GhTextSize.xs, mono: true, color: theme.muted),
              ),
            ),
        ],
      );
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GhAnimatedBox(
        color: _hovered ? theme.raised : theme.overlay,
        borderRadius: radius,
        border: Border.all(color: _hovered ? theme.accentDim.withValues(alpha: 0.6) : theme.outline.withValues(alpha: 0.5)),
        padding: EdgeInsets.all(theme.space(3.5)),
        child: Row(
          spacing: theme.space(3.5),
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  head,
                  if (busy && download != null)
                    Padding(
                      padding: EdgeInsets.only(top: theme.space(1)),
                      child: GhTooltip(
                        message: download.file ?? '',
                        child: Text(
                          [
                            if (download.platforms?.isNotEmpty ?? false) download.platforms!.join(', '),
                            if (download.file?.isNotEmpty ?? false) download.file!,
                            if (download.total > 0) '${formatBytes(download.downloaded)} / ${formatBytes(download.total)}',
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.text(size: GhTextSize.xs, color: theme.muted),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            GhOpenButton(
              label: _tv('open'),
              onOpen: widget.onOpen,
              consoleSupported: v.supportsConsole,
              moreLabel: _tv('more_editor_launch_options'),
              items: _menu(),
            ),
          ],
        ),
      ),
    );
  }
}
