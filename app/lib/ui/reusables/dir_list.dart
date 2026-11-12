import 'package:flutter/material.dart';

import '../../api/api.dart';
import '../../design/design.dart';
import '../controls/checkbox.dart';
import '../controls/dashed_box.dart';
import '../core/i18n.dart';
import '../core/interaction.dart';
import '../core/tooltip.dart';
import '../feedback/toast.dart';

class GhDirList extends StatelessWidget {
  const GhDirList({
    super.key,
    required this.dirs,
    required this.onChanged,
    required this.emptyHint,
    this.defaultDir,
    this.onSetDefault,
    this.defaultLabel,
    this.fallbackDownloadPath,
    this.showFallbackDescription = false,
    this.single = false,
    this.pickFolder,
  });

  final List<String> dirs;
  final ValueChanged<List<String>> onChanged;
  final String emptyHint;
  final String? defaultDir;
  final ValueChanged<String?>? onSetDefault;
  final String? defaultLabel;
  final String? fallbackDownloadPath;
  final bool showFallbackDescription;
  final bool single;
  final Future<String?> Function()? pickFolder;

  Future<void> _addDir() async {
    final String? folder;
    try {
      folder = await (pickFolder ?? Api.pickFolder)();
    } catch (e) {
      ghToasts.pushToast(GhToastType.error, '$e');
      return;
    }
    if (folder == null) return;
    if (single) {
      onChanged([folder]);
    } else if (!dirs.contains(folder)) {
      onChanged([...dirs, folder]);
    }
  }

  void _removeDir(String dir) {
    onChanged([
      for (final d in dirs)
        if (d != dir) d,
    ]);
    if (onSetDefault != null && defaultDir == dir) onSetDefault!(null);
  }

  void _toggleDefault(String dir) => onSetDefault?.call(defaultDir == dir ? null : dir);

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final label = defaultLabel ?? ghTr('default_folder');
    final makeDefaultLabel = ghTr('make_this_default', args: {'label': label.toLowerCase()});
    if (dirs.isEmpty) {
      final radius = BorderRadius.circular(theme.radiusItem);
      return GhPressable(
        onPressed: _addDir,
        borderRadius: radius,
        builder: (context, states) => GhDashedBox(
          color: states.highlighted ? theme.accentDim : theme.outline.withValues(alpha: 0.6),
          radius: BorderRadius.circular(theme.radiusItem),
          child: GhAnimatedBox(
            color: states.highlighted ? theme.overlay.withValues(alpha: 0.4) : Colors.transparent,
            borderRadius: radius,
            padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(3)),
            child: Row(
              spacing: theme.space(3),
              children: [
                Container(
                  width: theme.space(8),
                  height: theme.space(8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: theme.overlay, borderRadius: BorderRadius.circular(theme.radiusTile)),
                  child: GhIcon(GhIcons.folderPlus, size: theme.space(4), color: states.highlighted ? theme.accentBright : theme.muted),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ghTr('add_folder'),
                        style: theme.text(
                          size: GhTextSize.xs,
                          weight: GhWeight.medium,
                          color: states.highlighted ? theme.accentBright : theme.ink,
                        ),
                      ),
                      Text(
                        emptyHint,
                        style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(1.5),
      children: [
        for (final dir in dirs) _row(context, theme, dir, makeDefaultLabel),
        if (!single)
          GhPressable(
            onPressed: _addDir,
            borderRadius: BorderRadius.circular(theme.radiusItem),
            builder: (context, states) => GhDashedBox(
              color: states.highlighted ? theme.accentDim : theme.outline.withValues(alpha: 0.6),
              radius: BorderRadius.circular(theme.radiusItem),
              child: GhAnimatedBox(
                color: states.highlighted ? theme.overlay.withValues(alpha: 0.4) : Colors.transparent,
                borderRadius: BorderRadius.circular(theme.radiusItem),
                padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(2)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: theme.space(1.5),
                  children: [
                    GhIcon(GhIcons.folderPlus, size: theme.space(3.5), color: states.highlighted ? theme.accentBright : theme.muted),
                    Text(
                      ghTr('add_folder'),
                      style: theme.text(size: GhTextSize.xs, color: states.highlighted ? theme.accentBright : theme.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (showFallbackDescription && onSetDefault != null && defaultDir == null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: theme.space(1)),
            child: Text(
              ghTr('default_downloads_go_to', args: {'path': fallbackDownloadPath ?? 'AppData/${Api.channelIdentifier()}/godot-versions/'}),
              style: theme.text(size: GhTextSize.x3s, color: theme.muted, lineHeight: 1.625),
            ),
          ),
      ],
    );
  }

  Widget _row(BuildContext context, GhTheme theme, String dir, String makeDefaultLabel) {
    final isDefault = onSetDefault != null && defaultDir == dir;
    return Container(
      key: ValueKey(dir),
      decoration: BoxDecoration(
        color: isDefault ? theme.accent.withValues(alpha: 0.05) : theme.base.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: isDefault ? theme.accentDim.withValues(alpha: 0.6) : theme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(theme.space(2), theme.space(1.5), theme.space(1.5), theme.space(1.5)),
            child: Row(
              spacing: theme.space(2.5),
              children: [
                Container(
                  width: theme.space(8),
                  height: theme.space(8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDefault ? theme.accent.withValues(alpha: 0.15) : theme.overlay,
                    borderRadius: BorderRadius.circular(theme.radiusTile),
                  ),
                  child: GhIcon(GhIcons.folder, size: theme.space(3.5), color: isDefault ? theme.accentBright : theme.muted),
                ),
                Expanded(
                  child: GhTooltip(
                    message: dir,
                    child: GhPressable(
                      onPressed: () => Api.openProjectFolder(dir).catchError((Object _) {}),
                      semanticLabel: '${ghTr('open_folder')}: $dir',
                      builder: (context, states) => Text(
                        dir,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.text(size: GhTextSize.xs, mono: true, color: states.highlighted ? theme.accentBright : theme.ink),
                      ),
                    ),
                  ),
                ),
                if (isDefault)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: theme.space(1.5), vertical: theme.space(0.5)),
                    decoration: BoxDecoration(
                      color: theme.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(theme.radiusTag),
                    ),
                    child: Text(
                      ghTr('default_folder').toUpperCase(),
                      style: theme.text(size: GhTextSize.x4s, weight: GhWeight.bold, color: theme.accentBright, letterSpacingEm: 0.05),
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: theme.space(0.5),
                  children: [
                    if (single) _iconButton(theme, GhIcons.pencil, ghTr('browse'), _addDir),
                    _iconButton(theme, GhIcons.trash, ghTr('remove_folder'), () => _removeDir(dir), danger: true),
                  ],
                ),
              ],
            ),
          ),
          if (onSetDefault != null)
            Container(
              margin: EdgeInsetsDirectional.only(start: theme.space(2), end: theme.space(2), bottom: theme.space(1.5)),
              padding: EdgeInsets.only(top: theme.space(1.5), left: theme.space(1), right: theme.space(1)),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.outline.withValues(alpha: 0.4))),
              ),
              child: GhCheckbox(
                checked: isDefault,
                onChanged: (_) => _toggleDefault(dir),
                label: makeDefaultLabel,
                child: Text(
                  makeDefaultLabel,
                  style: theme.text(size: GhTextSize.xs, color: isDefault ? theme.accentBright : theme.muted),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _iconButton(GhTheme theme, FaIconData icon, String label, VoidCallback onPressed, {bool danger = false}) {
    final radius = BorderRadius.circular(theme.radiusTag);
    return GhTooltip(
      message: label,
      child: GhPressable(
        onPressed: onPressed,
        semanticLabel: label,
        borderRadius: radius,
        builder: (context, states) {
          final hover = states.highlighted;
          final color = hover ? (danger ? theme.danger : theme.ink) : theme.muted;
          final fill = hover ? (danger ? theme.danger.withValues(alpha: 0.1) : theme.overlay) : Colors.transparent;
          return GhAnimatedBox(
            width: theme.space(7),
            height: theme.space(7),
            alignment: Alignment.center,
            color: fill,
            borderRadius: radius,
            child: GhIcon(icon, size: theme.space(3.5), color: color),
          );
        },
      ),
    );
  }
}
