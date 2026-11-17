import 'package:material_ui/material_ui.dart';

import '../../api/api.dart';
import '../../design/design.dart';
import '../controls/checkbox.dart';
import '../core/i18n.dart';
import '../core/interaction.dart';
import '../core/tooltip.dart';
import 'path_field.dart';

/// A list of folders (scan folders, download folders) or a single folder.
///
/// Folders are added with a [GhPathField]: type or paste a path and press
/// Enter or Add folder, or choose Browse. In [single] mode the field edits the
/// one folder in place and saves on Enter, Apply or Browse.
class GhDirList extends StatefulWidget {
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

  @override
  State<GhDirList> createState() => _GhDirListState();
}

class _GhDirListState extends State<GhDirList> {
  late final TextEditingController _add = TextEditingController(text: widget.single ? (widget.dirs.firstOrNull ?? '') : '');

  @override
  void didUpdateWidget(GhDirList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the single folder field in step with the saved value.
    final current = widget.dirs.firstOrNull ?? '';
    if (widget.single && current != (oldWidget.dirs.firstOrNull ?? '') && _add.text != current) _add.text = current;
  }

  @override
  void dispose() {
    _add.dispose();
    super.dispose();
  }

  List<String> get dirs => widget.dirs;
  bool get single => widget.single;
  ValueChanged<String?>? get onSetDefault => widget.onSetDefault;
  String? get defaultDir => widget.defaultDir;

  void _addDir(String picked) {
    // `C:\games\` and `C:\games` are the same folder.
    final trimmed = picked.replaceFirst(RegExp(r'[\\/]+$'), '');
    final folder = trimmed.isEmpty || RegExp(r'^[A-Za-z]:$').hasMatch(trimmed) ? picked : trimmed;
    if (single) {
      if (dirs.firstOrNull != folder) widget.onChanged([folder]);
    } else if (!dirs.contains(folder)) {
      widget.onChanged([...dirs, folder]);
    }
  }

  void _removeDir(String dir) {
    widget.onChanged([
      for (final d in dirs)
        if (d != dir) d,
    ]);
    if (onSetDefault != null && defaultDir == dir) onSetDefault!(null);
    if (single) _add.clear();
  }

  void _toggleDefault(String dir) => onSetDefault?.call(defaultDir == dir ? null : dir);

  Widget _field(GhTheme theme, {String? hint}) => GhPathField(
    // Re-created when the saved folder changes so Apply tracks the new value.
    key: single ? ValueKey('dir-single:${dirs.firstOrNull ?? ''}') : null,
    controller: _add,
    kind: GhPathKind.folder,
    pick: widget.pickFolder,
    hint: hint,
    showApply: true,
    applyLabel: single ? null : ghTr('add_folder'),
    clearOnCommit: !single,
    compactBrowse: true,
    onCommitted: _addDir,
  );

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final label = widget.defaultLabel ?? ghTr('default_folder');
    final makeDefaultLabel = ghTr('make_this_default', args: {'label': label.toLowerCase()});
    if (single) {
      final dir = dirs.firstOrNull;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: theme.space(1),
        children: [
          Expanded(child: _field(theme, hint: dir == null ? widget.emptyHint : null)),
          if (dir != null)
            Padding(
              padding: EdgeInsets.only(top: theme.space(1)),
              child: _iconButton(theme, GhIcons.trash, ghTr('remove_folder'), () => _removeDir(dir), danger: true),
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(1.5),
      children: [
        for (final dir in dirs) _row(context, theme, dir, makeDefaultLabel),
        _field(theme, hint: dirs.isEmpty ? widget.emptyHint : null),
        if (widget.showFallbackDescription && onSetDefault != null && defaultDir == null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: theme.space(1)),
            child: Text(
              ghTr(
                'default_downloads_go_to',
                args: {'path': widget.fallbackDownloadPath ?? 'AppData/${Api.appIdentifier()}/godot-versions/'},
              ),
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
                  children: [_iconButton(theme, GhIcons.trash, ghTr('remove_folder'), () => _removeDir(dir), danger: true)],
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
