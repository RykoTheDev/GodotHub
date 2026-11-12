import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/vault.dart';
import '../design/design.dart';
import '../logic/locale.dart';
import '../motion/animated_number.dart';
import '../src/rust/api/types.dart';
import '../src/ui_prefs.dart';
import '../state/app_signals.dart';
import '../state/keyboard_shortcuts.dart' show focusSearchSignal;
import '../state/projects.dart';
import '../state/settings.dart';
import '../state/workspaces.dart';
import '../ui/controls/dashed_box.dart';
import '../ui/controls/search_bar.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/core/tooltip.dart';
import '../ui/feedback/confirm_dialog.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/overlays/dropdown.dart';
import '../ui/overlays/menu.dart';
import '../ui/reusables/view_header.dart';
import '../ui/shell/overlay_scroll_area.dart';
import '../ui/shell/view_insets.dart';
import 'add_vault_item_modal.dart';
import 'edit_vault_item_modal.dart';
import 'save_to_vault_modal.dart';
import 'vault_item_preview_modal.dart';
import 'vault_modal_parts.dart';

const vaultSortKey = 'godothub_vault_sort';

enum VaultSort {
  nameAsc('name_asc', 'sort_name_asc'),
  nameDesc('name_desc', 'sort_name_desc'),
  newest('newest', 'sort_created_desc'),
  oldest('oldest', 'sort_created_asc');

  const VaultSort(this.id, this.labelKey);

  final String id;
  final String labelKey;

  static VaultSort parse(String? id) => values.where((v) => v.id == id).firstOrNull ?? nameAsc;
}

int _createdMs(VaultItem item) => DateTime.tryParse(item.createdAt)?.millisecondsSinceEpoch ?? 0;

List<VaultItem> filterVaultItems(List<VaultItem> items, {required String query, required List<String> tags, required VaultSort sort}) {
  final q = query.trim().toLowerCase();
  final filtered = items.where((item) {
    if (tags.isNotEmpty && !tags.every(item.tags.contains)) return false;
    if (q.isEmpty) return true;
    return item.name.toLowerCase().contains(q) ||
        item.description.toLowerCase().contains(q) ||
        item.tags.any((tag) => tag.toLowerCase().contains(q));
  }).toList();
  int byName(VaultItem a, VaultItem b) => ghLocaleCompare(a.name, b.name);
  filtered.sort(switch (sort) {
    VaultSort.nameAsc => byName,
    VaultSort.nameDesc => (a, b) => byName(b, a),
    VaultSort.newest => (a, b) => _createdMs(b) - _createdMs(a),
    VaultSort.oldest => (a, b) => _createdMs(a) - _createdMs(b),
  });
  return filtered;
}

class VaultView extends ConsumerStatefulWidget {
  const VaultView({super.key, this.connected = false, this.prefs});

  final bool connected;
  final UiPrefsStore? prefs;

  @override
  ConsumerState<VaultView> createState() => _VaultViewState();
}

class _VaultViewState extends ConsumerState<VaultView> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchNode = FocusNode(debugLabel: 'VaultView search');
  StreamSubscription<Object?>? _focusSub;
  List<VaultItem> _items = const [];
  bool _loaded = false;
  List<String> _activeTags = const [];
  bool _deleting = false;
  late VaultSort _sort = VaultSort.parse(_prefs.getItem(vaultSortKey));

  UiPrefsStore get _prefs => widget.prefs ?? UiPrefsStore.instance;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _focusSub = AppSignals.on(focusSearchSignal).listen((_) => _searchNode.requestFocus());
    _load();
    ref.listenManual(activeWorkspaceIdProvider, (prev, next) {
      if (prev != next) _load();
    });
  }

  @override
  void dispose() {
    _focusSub?.cancel();
    _search.dispose();
    _searchNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await VaultApi.list();
      if (mounted) setState(() => _items = items);
    } catch (_) {}
    if (mounted) setState(() => _loaded = true);
  }

  List<String> get _allTags {
    final set = <String>{for (final item in _items) ...item.tags};
    return set.toList()..sort(ghLocaleCompare);
  }

  void _setSort(VaultSort sort) {
    setState(() => _sort = sort);
    _prefs.setItem(vaultSortKey, sort.id);
  }

  void _toggleTag(String tag) => setState(() {
    _activeTags = _activeTags.contains(tag) ? _activeTags.where((t) => t != tag).toList() : [..._activeTags, tag];
  });

  List<Project> get _projects => ref.read(projectsProvider).data;

  void _openSave() => showGhModal<void>(
    context,
    (context) => SaveToVaultModal(projects: _projects, onClose: () => Navigator.of(context).pop(), onSaved: _load),
  ).ignore();

  void _openPreview(VaultItem item) =>
      showGhModal<void>(context, (context) => VaultItemPreviewModal(item: item, onClose: () => Navigator.of(context).pop())).ignore();

  void _openEdit(VaultItem item) => showGhModal<void>(
    context,
    (context) => EditVaultItemModal(
      item: item,
      onClose: () => Navigator.of(context).pop(),
      onSaved: (updated) => setState(() => _items = [for (final i in _items) i.id == updated.id ? updated : i]),
    ),
  ).ignore();

  void _openAdd(VaultItem item) => showGhModal<void>(
    context,
    (context) => AddVaultItemModal(item: item, projects: _projects, onClose: () => Navigator.of(context).pop()),
  ).ignore();

  Future<void> _confirmDelete(VaultItem item) async {
    final ok = await showGhConfirmDialog(
      context,
      variant: GhConfirmVariant.danger,
      title: ghTr('vault_delete_title'),
      description: item.name.isNotEmpty ? ghTr('vault_delete_desc', args: {'name': item.name}) : ghTr('cannot_undo'),
      confirmLabel: ghTr('delete'),
    );
    if (!ok || _deleting) return;
    _deleting = true;
    try {
      await VaultApi.delete(item.id);
      if (mounted) setState(() => _items = _items.where((i) => i.id != item.id).toList());
    } catch (e) {
      ghToasts.pushToast(GhToastType.error, '$e');
    } finally {
      _deleting = false;
    }
  }

  Widget _saveButton(GhTheme theme) {
    final radius = BorderRadius.circular(theme.radiusItem);
    return GhPressable(
      onPressed: _openSave,
      borderRadius: radius,
      rippleColor: Colors.white,
      builder: (context, states) => GhAnimatedBox(
        height: theme.space(10),
        color: states.active ? theme.accentBright : theme.accent,
        borderRadius: radius,
        padding: EdgeInsets.symmetric(horizontal: theme.space(6)),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: theme.space(1.5),
          children: [
            GhIcon(GhIcons.plus, size: theme.space(4), color: Colors.white),
            Text(
              ghTr('vault_save_btn'),
              style: theme.text(weight: GhWeight.semibold, color: Colors.white).copyWith(fontSize: theme.rem(1.0625)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tagChips(GhTheme theme, List<String> tags) => Padding(
    padding: EdgeInsets.only(top: theme.space(1)),
    child: Wrap(
      spacing: theme.space(1.5),
      runSpacing: theme.space(1.5),
      children: [
        for (final tag in tags)
          Builder(
            key: ValueKey(tag),
            builder: (context) {
              final active = _activeTags.contains(tag);
              final radius = BorderRadius.circular(theme.radiusTag);
              return GhPressable(
                onPressed: () => _toggleTag(tag),
                toggled: active,
                borderRadius: radius,
                builder: (context, states) => GhAnimatedBox(
                  color: active
                      ? theme.accent
                      : states.active
                      ? theme.raised
                      : theme.overlay,
                  borderRadius: radius,
                  padding: EdgeInsets.symmetric(horizontal: theme.space(2.5), vertical: theme.space(1)),
                  child: Text(
                    tag,
                    style: theme.text(
                      size: GhTextSize.x2s,
                      mono: true,
                      color: active
                          ? Colors.white
                          : states.active
                          ? theme.ink
                          : theme.muted,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    ),
  );

  Widget _sortDropdown(GhTheme theme) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: GhDropdown(
      align: GhSide.left,
      items: [
        for (final option in VaultSort.values)
          GhMenuItem(id: option.id, label: ghTr(option.labelKey), active: option == _sort, onSelected: () => _setSort(option)),
      ],
      trigger: (context, open, toggle) {
        final radius = BorderRadius.circular(theme.radiusItem);
        return GhPressable(
          onPressed: toggle,
          expanded: open,
          borderRadius: radius,
          builder: (context, states) => GhAnimatedBox(
            height: theme.space(7),
            color: states.active ? theme.raised : theme.overlay,
            borderRadius: radius,
            padding: EdgeInsets.symmetric(horizontal: theme.space(3)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: theme.space(1.5),
              children: [
                Text(
                  '${ghTr('sort')}:',
                  style: theme.text(size: GhTextSize.xs, color: theme.muted),
                ),
                Text(
                  ghTr(_sort.labelKey),
                  style: theme.text(weight: GhWeight.medium, color: theme.ink).copyWith(fontSize: theme.rem(0.8125)),
                ),
                GhIcon(GhIcons.chevronDown, size: theme.space(3), color: theme.muted),
              ],
            ),
          ),
        );
      },
    ),
  );

  Widget _grid(GhTheme theme, List<Widget> children, {double? rowHeight}) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1024 ? 3 : (width >= 640 ? 2 : 1);
    final gap = theme.space(3);
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final cells = <Widget>[
        for (var c = 0; c < columns; c++) Expanded(child: i + c < children.length ? children[i + c] : const SizedBox.shrink()),
      ];
      final row = Row(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: gap, children: cells);
      rows.add(rowHeight != null ? SizedBox(height: rowHeight, child: row) : IntrinsicHeight(child: row));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: gap, children: rows);
  }

  Widget _skeleton(GhTheme theme) => _grid(theme, [
    for (var i = 0; i < 3; i++)
      DecoratedBox(
        decoration: BoxDecoration(
          color: theme.overlay,
          borderRadius: BorderRadius.circular(theme.radiusItem),
          border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
        ),
      ),
  ], rowHeight: theme.rem(13));

  Widget _emptyBox(GhTheme theme, {required double paddingY, required List<Widget> children}) => GhDashedBox(
    color: theme.outline.withValues(alpha: 0.5),
    radius: BorderRadius.circular(theme.radiusItem),
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: theme.space(6), vertical: theme.space(paddingY)),
      child: Column(spacing: theme.space(3), children: children),
    ),
  );

  Widget _empty(GhTheme theme) {
    final style = theme.text(color: theme.muted, lineHeight: 1.625);
    return _emptyBox(
      theme,
      paddingY: 20,
      children: [
        Container(
          width: theme.space(12),
          height: theme.space(12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.overlay,
            borderRadius: BorderRadius.circular(theme.radiusTile),
            border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
          ),
          child: GhIcon(GhIcons.briefcase, size: theme.space(5), color: theme.muted),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: theme.rem(24)),
          child: Text.rich(
            TextSpan(
              children: ghTrans(
                ghTr('vault_empty'),
                tags: {
                  '1': (text, children) => TextSpan(
                    children: children,
                    style: const TextStyle(fontWeight: GhWeight.bold),
                  ),
                },
              ),
            ),
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
      ],
    );
  }

  Widget _noMatch(GhTheme theme) => _emptyBox(
    theme,
    paddingY: 16,
    children: [
      GhIcon(GhIcons.search, size: theme.space(5), color: theme.muted),
      Text(ghTr('vault_no_match'), style: theme.text(color: theme.muted)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr;
    final settings = ref.watch(settingsProvider).value ?? defaultSettings;
    ref.watch(projectsProvider);
    final allTags = _allTags;
    final activeTags = _activeTags.where(allTags.contains).toList();
    if (activeTags.length != _activeTags.length) _activeTags = activeTags;
    final filtered = filterVaultItems(_items, query: _search.text, tags: activeTags, sort: _sort);
    final insets = GhViewInsets.of(context);
    final scrollInsets = EdgeInsetsDirectional.only(
      start: insets.start >= theme.space(2) ? insets.start - theme.space(2) : insets.start,
      end: insets.end >= theme.space(4) ? insets.end - theme.space(4) : insets.end,
      bottom: insets.bottom >= theme.space(4) ? insets.bottom - theme.space(4) : insets.bottom,
    );
    final Widget body;
    if (!_loaded) {
      body = _skeleton(theme);
    } else if (_items.isEmpty) {
      body = _empty(theme);
    } else if (filtered.isEmpty) {
      body = _noMatch(theme);
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(2),
        children: [
          _sortDropdown(theme),
          _grid(theme, [
            for (final item in filtered)
              VaultItemCard(
                key: ValueKey(item.id),
                item: item,
                onPreview: () => _openPreview(item),
                onEdit: () => _openEdit(item),
                onDelete: () => _confirmDelete(item).ignore(),
                onAdd: () => _openAdd(item),
              ),
          ]),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: insets.start, end: insets.end, bottom: theme.space(2)),
          child: GhViewHeader(
            connected: widget.connected,
            title: tr.nav.vault,
            metric: [
              DefaultTextStyle.merge(
                style: theme.text(size: GhTextSize.x4l, weight: GhWeight.bold, color: theme.muted),
                child: GhAnimatedNumber(_items.length),
              ),
              Text(
                ghTr('vault_item_count', count: _items.length).toUpperCase(),
                style: theme.text(size: GhTextSize.lg, weight: GhWeight.medium, color: theme.muted),
              ),
            ],
            actions: [_saveButton(theme)],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GhSearchBar(
                  value: _search.text,
                  controller: _search,
                  focusNode: _searchNode,
                  placeholder: ghTr('vault_search_placeholder'),
                  onChanged: (_) {},
                ),
                if (allTags.isNotEmpty) _tagChips(theme, allTags),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: scrollInsets,
            child: GhOverlayScrollArea(
              hideThumb: !settings.showScrollbars,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  theme.space(widget.connected ? 5 : 2),
                  theme.space(2),
                  theme.space(5),
                  theme.space(8),
                ),
                child: body,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class VaultItemCard extends StatefulWidget {
  const VaultItemCard({
    super.key,
    required this.item,
    required this.onPreview,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  });

  final VaultItem item;
  final VoidCallback onPreview;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAdd;

  @override
  State<VaultItemCard> createState() => _VaultItemCardState();
}

class _VaultItemCardState extends State<VaultItemCard> {
  bool _hovered = false;

  Widget _iconAction(
    GhTheme theme, {
    required String label,
    required FaIconData icon,
    required bool danger,
    required VoidCallback onPressed,
  }) {
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhTooltip(
      message: label,
      side: GhSide.top,
      child: GhPressable(
        onPressed: onPressed,
        semanticLabel: label,
        borderRadius: radius,
        builder: (context, states) => GhAnimatedBox(
          color: states.active ? (danger ? theme.danger.withValues(alpha: 0.1) : theme.raised) : theme.raised.withValues(alpha: 0),
          borderRadius: radius,
          padding: EdgeInsets.all(theme.space(1.5)),
          child: GhIcon(
            icon,
            size: theme.space(3.5),
            color: states.active ? (danger ? theme.danger : theme.ink) : theme.muted.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final item = widget.item;
    final radius = BorderRadius.circular(theme.radiusItem);
    final faint = theme.text(size: GhTextSize.x3s, mono: true, color: theme.muted.withValues(alpha: 0.5));
    final created = DateTime.tryParse(item.createdAt);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GhPressable(
        onPressed: widget.onPreview,
        semanticLabel: item.name,
        borderRadius: radius,
        ripple: false,
        pressMotion: false,
        builder: (context, states) => GhAnimatedBox(
          color: theme.overlay,
          borderRadius: radius,
          border: Border.all(color: states.active ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
          padding: EdgeInsets.all(theme.space(5)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(3),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: theme.space(10),
                    height: theme.space(10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.raised,
                      borderRadius: BorderRadius.circular(theme.radiusTile),
                      border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                    ),
                    child: GhIcon(GhIcons.briefcase, size: theme.space(4), color: theme.muted),
                  ),
                  AnimatedOpacity(
                    opacity: _hovered ? 1 : 0,
                    alwaysIncludeSemantics: true,
                    duration: const Duration(milliseconds: 150),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: theme.space(0.5),
                      children: [
                        _iconAction(theme, label: ghTr('vault_edit_action'), icon: GhIcons.pencil, danger: false, onPressed: widget.onEdit),
                        _iconAction(
                          theme,
                          label: ghTr('vault_delete_action', args: {'name': item.name}),
                          icon: GhIcons.trash,
                          danger: true,
                          onPressed: widget.onDelete,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.text(weight: GhWeight.semibold, color: theme.ink),
                    ),
                    if (item.description.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: theme.space(1)),
                        child: Text(
                          item.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.text(size: GhTextSize.xs, color: theme.muted, lineHeight: 1.625),
                        ),
                      ),
                  ],
                ),
              ),
              if (item.tags.isNotEmpty)
                Wrap(
                  spacing: theme.space(1),
                  runSpacing: theme.space(1),
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final tag in item.tags.take(4)) VaultTagChip(tag),
                    if (item.tags.length > 4) Text('+${item.tags.length - 4}', style: faint),
                  ],
                ),
              Row(
                spacing: theme.space(1.5),
                children: [
                  if (item.godotVersion.isNotEmpty) Text('${ghTr('godot')} ${item.godotVersion}', style: faint),
                  if (item.createdAt.isNotEmpty) ...[
                    Text('·', style: faint),
                    Text(created != null ? formatLocaleDate(created) : item.createdAt, style: faint),
                  ],
                ],
              ),
              GhPressable(
                onPressed: widget.onAdd,
                borderRadius: radius,
                builder: (context, states) => GhAnimatedBox(
                  alignment: Alignment.center,
                  color: theme.accent.withValues(alpha: states.active ? 0.2 : 0.1),
                  borderRadius: radius,
                  border: Border.all(color: theme.accentDim.withValues(alpha: 0.3)),
                  padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: theme.space(1.5),
                    children: [
                      GhIcon(GhIcons.folderPlus, size: theme.space(3.5), color: theme.accentBright),
                      Text(
                        ghTr('vault_add_btn'),
                        style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: theme.accentBright),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
