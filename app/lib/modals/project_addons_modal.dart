import 'package:flutter/material.dart';

import '../api/asset_library.dart';
import '../design/design.dart';
import '../src/rust/api/types.dart';
import '../ui/core/i18n.dart';
import '../ui/feedback/confirm_dialog.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/reusables/modal_kit.dart';

String _t(String key, {num? count, Map<String, Object?> args = const {}}) => ghTr('project_addons.$key', count: count, args: args);

class ProjectAddonsModal extends StatefulWidget {
  const ProjectAddonsModal({super.key, required this.project, required this.onClose});

  final Project project;
  final VoidCallback onClose;

  @override
  State<ProjectAddonsModal> createState() => _ProjectAddonsModalState();
}

class _ProjectAddonsModalState extends State<ProjectAddonsModal> {
  List<ProjectAddon>? _addons;
  Map<String, AddonUpdate>? _updates;
  bool _checking = false;
  String? _updating;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await AssetLibraryApi.projectAddons(widget.project.id);
      if (mounted) setState(() => _addons = result);
    } catch (reason) {
      if (mounted) {
        setState(() {
          _addons = const [];
          _error = '$reason';
        });
      }
    }
  }

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _error = '';
    });
    try {
      final result = await AssetLibraryApi.addonUpdates(widget.project.id);
      if (mounted) setState(() => _updates = {for (final u in result) u.folder: u});
    } catch (reason) {
      if (mounted) setState(() => _error = '$reason');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _confirm(AddonUpdate target) async {
    final version = target.latestVersion.isEmpty ? '?' : target.latestVersion;
    final ok = await showGhConfirmDialog(
      context,
      title: _t('confirm_title', args: {'name': target.title}),
      description: _t('confirm_description', args: {'folder': target.folder, 'version': version}),
      confirmLabel: _t('update'),
    );
    if (!ok || !mounted) return;
    setState(() {
      _updating = target.folder;
      _error = '';
    });
    try {
      await AssetLibraryApi.updateAddon(widget.project.id, target.folder, target.assetId);
      ghToasts.pushToast(GhToastType.success, _t('updated', args: {'name': target.title}));
      await _load();
      await _check();
    } catch (reason) {
      if (mounted) setState(() => _error = '$reason');
    } finally {
      if (mounted) setState(() => _updating = null);
    }
  }

  Widget _badge(GhTheme theme, String label, {Color? color}) => Container(
    height: theme.space(5),
    padding: EdgeInsets.symmetric(horizontal: theme.space(2)),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color?.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(theme.radiusTag),
      border: Border.all(color: color?.withValues(alpha: 0.4) ?? theme.line),
    ),
    child: Text(label, style: theme.text(size: GhTextSize.x3s, weight: GhWeight.medium, color: color ?? theme.muted)),
  );

  Widget _row(GhTheme theme, ProjectAddon addon) {
    final info = _updates?[addon.folder];
    final available = info?.updateAvailable ?? false;
    final latest = (info?.latestVersion.isEmpty ?? true) ? '?' : info!.latestVersion;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(3)),
      decoration: BoxDecoration(
        color: theme.overlay,
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: theme.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: theme.space(3),
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: theme.space(2),
                  runSpacing: theme.space(2),
                  children: [
                    Text(addon.name, style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.ink)),
                    if (addon.version.isNotEmpty)
                      Text(
                        'v${addon.version.replaceFirst(RegExp('^v', caseSensitive: false), '')}',
                        style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted),
                      ),
                    if (!addon.hasPlugin)
                      _badge(theme, _t('library'))
                    else if (addon.enabled)
                      _badge(theme, _t('enabled'), color: theme.mint)
                    else
                      _badge(theme, _t('disabled')),
                    if (addon.assetId != null && addon.assetId!.isNotEmpty) _badge(theme, _t('from_library'), color: theme.accentBright),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(top: theme.space(1)),
                  child: Text(
                    'res://addons/${addon.folder}${addon.author.isNotEmpty ? ' · ${addon.author}' : ''}',
                    style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted),
                  ),
                ),
                if (addon.description.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: theme.space(1.5)),
                    child: Text(
                      addon.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.text(size: GhTextSize.xs, color: theme.muted, lineHeight: 1.625),
                    ),
                  ),
                if (_updates != null)
                  Padding(
                    padding: EdgeInsets.only(top: theme.space(2)),
                    child: Text.rich(
                      TextSpan(
                        text: info == null
                            ? _t('not_found')
                            : available
                            ? _t('update_to', args: {'version': latest})
                            : _t('current', args: {'version': latest}),
                        children: [
                          if (info?.matchedBy == 'name')
                            TextSpan(
                              text: ' · ${_t('matched_by_name', args: {'title': info!.title})}',
                              style: TextStyle(color: theme.muted),
                            ),
                        ],
                      ),
                      style: theme.text(size: GhTextSize.xs, color: available ? theme.amber : theme.muted),
                    ),
                  ),
              ],
            ),
          ),
          if (available)
            GhOutlineAction(
              onPressed: _updating != null || _checking ? null : () => _confirm(info!),
              icon: GhIcons.cloudArrowDown,
              busy: _updating == addon.folder,
              label: _updating == addon.folder ? _t('updating') : _t('update'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final addons = _addons;
    final updates = _updates;
    final available = updates == null ? 0 : updates.values.where((u) => u.updateAvailable).length;
    return GhModalShell(
      icon: GhIcon(GhIcons.plug, size: theme.space(5), color: theme.accentBright),
      title: _t('title'),
      maxWidth: GhModalWidth.x2l,
      bodyHeight: GhModalShell.tallBodyHeight(context),
      onClose: widget.onClose,
      footer: [
        Expanded(
          child: Text(_t('footer_hint'), style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625)),
        ),
        GhOutlineAction(onPressed: widget.onClose, label: context.tr.common.close),
      ],
      child: SingleChildScrollView(
        padding: EdgeInsets.all(theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(4),
          children: [
            Container(
              padding: EdgeInsets.only(bottom: theme.space(4)),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.line))),
              child: Row(
                spacing: theme.space(3),
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          addons == null ? _t('loading') : _t('count', count: addons.length),
                          style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.ink),
                        ),
                        if (updates != null)
                          Padding(
                            padding: EdgeInsets.only(top: theme.space(1)),
                            child: Text(
                              available > 0 ? _t('updates_available', count: available) : _t('all_current'),
                              style: theme.text(size: GhTextSize.xs, color: theme.muted),
                            ),
                          ),
                      ],
                    ),
                  ),
                  GhOutlineAction(
                    onPressed: _checking || _updating != null || (addons?.isEmpty ?? true) ? null : _check,
                    icon: GhIcons.refresh,
                    spinIcon: _checking,
                    label: _checking ? _t('checking') : _t('check_updates'),
                  ),
                ],
              ),
            ),
            if (_error.isNotEmpty) GhAlertBox(tone: GhAlertTone.danger, text: _error, strong: true),
            if (addons != null && addons.isEmpty)
              Text(_t('empty'), style: theme.text(size: GhTextSize.xs, color: theme.muted, lineHeight: 1.625)),
            for (final addon in addons ?? const <ProjectAddon>[]) _row(theme, addon),
          ],
        ),
      ),
    );
  }
}
