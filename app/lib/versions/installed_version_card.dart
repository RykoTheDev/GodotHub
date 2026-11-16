import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/design.dart';
import '../logic/format_bytes.dart';
import '../modals/current_version_modal.dart';
import '../modals/export_templates_modal.dart';
import '../motion/reveal.dart';
import '../src/rust/api/types.dart';
import '../state/export_template_downloads.dart';
import '../ui/controls/text_input.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/core/tooltip.dart';
import '../ui/feedback/confirm_dialog.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/overlays/menu.dart';
import '../ui/reusables/card_kit.dart';
import '../ui/reusables/open_button.dart';
import 'version_logic.dart';

String _tv(String key, {num? count, Map<String, Object?> args = const {}}) => ghTr('versions:$key', count: count, args: args);

/// Below this width (in spacing units) the card stacks the launch button
/// under the details instead of beside them.
const double installedCardStackBelow = 120;

/// One installed Godot version.
///
/// Anatomy: the name (custom name or tag) with an inline rename button, the
/// original tag under a custom name, then a row of state badges (current,
/// channel, .NET, custom build, mise, update available, export templates).
/// The split Open button is the one primary action; everything else lives in
/// its menu. The pinned current version gets a mint resting border.
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
    this.updateTag,
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

  /// A newer stable patch release in the same minor line, when one exists.
  final String? updateTag;

  @override
  State<InstalledVersionCard> createState() => _InstalledVersionCardState();
}

class _InstalledVersionCardState extends State<InstalledVersionCard> {
  final TextEditingController _edit = TextEditingController();
  final FocusNode _editNode = FocusNode(debugLabel: 'InstalledVersionCard rename');
  bool _editing = false;

  InstalledGodotVersion get _v => widget.version;

  bool get _hasCustomName => (_v.customName?.isNotEmpty ?? false) && _v.customName != _v.tag;

  String get _displayName => (_v.customName?.isNotEmpty ?? false) ? _v.customName! : _v.tag;

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

  bool get _templatesBusy => widget.templateDownload != null || (widget.templates?.downloading ?? false);

  /// A badge that opens the export templates dialog when pressed.
  Widget _pressableBadge(
    GhTheme theme, {
    required String label,
    required FaIconData icon,
    required GhTone tone,
    GhTone? hoverTone,
    required String tooltip,
    required String semanticLabel,
  }) => GhTooltip(
    message: tooltip,
    child: GhPressable(
      onPressed: _openTemplatesDialog,
      semanticLabel: semanticLabel,
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(theme.radiusTag),
      builder: (context, states) =>
          GhBadge(label: label, icon: icon, tone: states.active ? (hoverTone ?? tone) : tone, maxWidth: theme.space(72)),
    ),
  );

  Widget? _templateBadge(GhTheme theme) {
    final templates = widget.templates;
    final download = widget.templateDownload;
    if (_templatesBusy) {
      final percent = download != null && download.total > 0 ? (download.downloaded / download.total * 100).round().clamp(0, 100) : null;
      final label = download == null
          ? ghTr('downloading_update')
          : download.stage == 'extracting'
          ? ghTr('export_templates_extracting')
          : download.stage == 'verifying'
          ? ghTr('export_templates_verifying')
          : percent != null
          ? '${_tv('export_templates_installed')} $percent%'
          : ghTr('downloading_update');
      final tooltip = [
        if (download?.platforms?.isNotEmpty ?? false) download!.platforms!.join(', '),
        if (download?.file?.isNotEmpty ?? false) download!.file!,
      ].join(' · ');
      return Row(
        mainAxisSize: MainAxisSize.min,
        spacing: theme.space(0.5),
        children: [
          GhBadge(label: label, icon: GhIcons.download, tone: GhTone.amber, tooltip: tooltip.isEmpty ? null : tooltip),
          if (widget.onCancelTemplates != null)
            GhIconButton(
              icon: GhIcons.x,
              onPressed: widget.onCancelTemplates,
              tooltip: _tv('cancel_download'),
              variant: GhButtonVariant.ghost,
              padding: 0.75,
              iconSpace: 3,
            ),
        ],
      );
    }
    if (templates?.installed ?? false) {
      final platforms = templates!.platforms.join(', ');
      return _pressableBadge(
        theme,
        label: '${_tv('export_templates_installed')}${platforms.isNotEmpty ? ' · $platforms' : ''}',
        icon: GhIcons.check,
        tone: GhTone.mint,
        tooltip: '${templates.folder} · ${formatBytes(templates.sizeBytes.toInt())}',
        semanticLabel: _tv('export_templates_choose'),
      );
    }
    if (widget.onInstallTemplates == null) return null;
    return _pressableBadge(
      theme,
      label: _tv('export_templates_missing'),
      icon: GhIcons.download,
      tone: GhTone.muted,
      hoverTone: GhTone.accent,
      tooltip: _tv('templates_none_hint'),
      semanticLabel: _tv('export_templates_install'),
    );
  }

  List<Widget> _badges(GhTheme theme) {
    final v = _v;
    final custom = v.managedBy == 'custom';
    final stable = isStableTag(v.tag);
    final templates = _templateBadge(theme);
    return [
      if (widget.isCurrent)
        GhBadge(key: const ValueKey('version-badge-current'), label: ghTr('cleanup_current_badge'), icon: GhIcons.pin, tone: GhTone.mint),
      if (!custom)
        GhBadge(
          key: const ValueKey('version-badge-channel'),
          label: stable ? _tv('stable') : _tv('unstable'),
          tone: stable ? GhTone.muted : GhTone.amber,
        ),
      if (v.isMono) GhBadge(key: const ValueKey('version-badge-mono'), label: '.NET', tone: GhTone.accent, tooltip: _tv('mono')),
      if (custom) GhBadge(key: const ValueKey('version-badge-custom'), label: _tv('custom_build_badge'), tone: GhTone.accent),
      if (v.managedBy == 'mise') GhBadge(key: const ValueKey('version-badge-mise'), label: _tv('managed_by_mise'), mono: true),
      if (widget.updateTag != null)
        GhBadge(
          key: const ValueKey('version-badge-update'),
          label: ghTr('update_available'),
          icon: GhIcons.arrowUp,
          tone: GhTone.amber,
          tooltip: _tv('update_available_tag', args: {'tag': widget.updateTag}),
        ),
      ?templates,
    ];
  }

  List<GhMenuItem> _menu() {
    final installed = widget.templates?.installed ?? false;
    final canInstallTemplates = !installed && widget.onInstallTemplates != null && !_templatesBusy;
    return [
      GhMenuItem(
        id: 'open',
        label: _tv('open_editor'),
        icon: GhIcons.rocket,
        onSelected: () => widget.onOpen(null),
        dividerAfter: !_v.supportsConsole,
      ),
      if (_v.supportsConsole)
        GhMenuItem(
          id: 'open-console',
          label: _tv('open_editor_with_console'),
          icon: GhIcons.terminal,
          dividerAfter: true,
          onSelected: () => widget.onOpen(true),
        ),
      GhMenuItem(id: 'rename', label: _tv('rename'), icon: GhIcons.pencil, onSelected: _startEditing),
      GhMenuItem(
        id: 'current',
        label: widget.isCurrent ? _tv('unset_current') : _tv('set_as_current'),
        icon: GhIcons.pin,
        onSelected: widget.isCurrent ? _clearCurrent : _setCurrent,
      ),
      GhMenuItem(id: 'alias', label: _tv('alias_create'), icon: GhIcons.terminal, onSelected: widget.onManageAliases),
      GhMenuItem(
        id: 'folder',
        label: _tv('open_install_folder'),
        icon: GhIcons.folder,
        dividerAfter: installed || canInstallTemplates,
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
        GhMenuItem(
          id: 'templates-remove',
          label: _tv('export_templates_remove'),
          icon: GhIcons.trash,
          dividerAfter: true,
          onSelected: _confirmRemoveTemplates,
        ),
      ] else if (canInstallTemplates)
        GhMenuItem(
          id: 'templates-install',
          label: _tv('export_templates_install'),
          icon: GhIcons.download,
          dividerAfter: true,
          onSelected: _openTemplatesDialog,
        ),
      GhMenuItem(
        id: 'uninstall',
        label: _tv('version_uninstall_confirm'),
        icon: GhIcons.trash,
        danger: true,
        onSelected: _confirmUninstall,
      ),
    ];
  }

  Widget _renameField(GhTheme theme) => Row(
    spacing: theme.space(1.5),
    children: [
      Flexible(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: theme.space(64)),
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
      ),
      GhIconButton(icon: GhIcons.check, onPressed: _commit, tooltip: ghTr('version_save_name_aria'), variant: GhButtonVariant.ghost),
    ],
  );

  Widget _title(GhTheme theme, bool highlighted) => Row(
    spacing: theme.space(1),
    children: [
      Flexible(
        child: GhTooltip(
          message: _displayName,
          child: Text(
            _displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.text(size: GhTextSize.lg, weight: GhWeight.semibold, color: theme.ink, mono: !_hasCustomName),
          ),
        ),
      ),
      AnimatedOpacity(
        opacity: highlighted ? 1 : 0.55,
        duration: GhDurations.iconTransform,
        child: GhIconButton(
          icon: GhIcons.pencil,
          onPressed: _startEditing,
          tooltip: _tv('rename'),
          semanticLabel: ghTr('version_rename_aria'),
          variant: GhButtonVariant.ghost,
          padding: 1,
          iconSpace: 3.5,
        ),
      ),
    ],
  );

  Widget _details(GhTheme theme, bool highlighted) {
    final download = widget.templateDownload;
    final progress = download == null
        ? ''
        : [
            if (download.platforms?.isNotEmpty ?? false) download.platforms!.join(', '),
            if (download.file?.isNotEmpty ?? false) download.file!,
            if (download.total > 0) '${formatBytes(download.downloaded)} / ${formatBytes(download.total)}',
          ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_editing) _renameField(theme) else _title(theme, highlighted),
        if (_hasCustomName && !_editing)
          Padding(
            padding: EdgeInsets.only(top: theme.space(0.5)),
            child: Text(
              '${_tv('original_name')}: ${_v.tag}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.text(size: GhTextSize.xs, mono: true, color: theme.muted),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(top: theme.space(2.5)),
          child: Wrap(
            spacing: theme.space(1.5),
            runSpacing: theme.space(1.5),
            crossAxisAlignment: WrapCrossAlignment.center,
            children: _badges(theme),
          ),
        ),
        if (progress.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: theme.space(1.5)),
            child: Text(
              progress,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.text(size: GhTextSize.xs, color: theme.muted).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return GhReveal(
      id: 'version:${_v.tag}',
      child: GhCard(
        tone: widget.isCurrent ? GhTone.mint : null,
        padding: EdgeInsets.all(theme.space(4)),
        builder: (context, highlighted) => LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < theme.space(installedCardStackBelow);
            final open = GhOpenButton(
              label: _tv('open'),
              onOpen: widget.onOpen,
              consoleSupported: _v.supportsConsole,
              moreLabel: _tv('more_editor_launch_options'),
              items: _menu(),
              size: narrow ? GhOpenButtonSize.compact : GhOpenButtonSize.normal,
            );
            final details = _details(theme, highlighted);
            if (narrow) {
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: theme.space(3), children: [details, open]);
            }
            return Row(
              spacing: theme.space(4),
              children: [
                Expanded(child: details),
                open,
              ],
            );
          },
        ),
      ),
    );
  }
}
