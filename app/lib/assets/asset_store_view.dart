import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/asset_library.dart';
import '../design/design.dart';
import '../logic/asset_sort.dart';
import '../motion/animated_number.dart';
import '../src/rust/api/types.dart';
import '../src/ui_prefs.dart';
import '../state/app_signals.dart';
import '../state/keyboard_shortcuts.dart' show focusSearchSignal;
import '../state/settings.dart';
import '../ui/controls/search_bar.dart';
import '../ui/core/i18n.dart';
import '../ui/core/ui_settings.dart' show GhSide;
import '../ui/overlays/dropdown.dart';
import '../ui/overlays/menu.dart';
import '../ui/reusables/view_header.dart';
import '../ui/shell/overlay_scroll_area.dart';
import '../ui/shell/view_insets.dart';
import 'asset_common.dart';
import 'asset_store_browser.dart';

const assetStoreSortKeys = [
  AssetSortKey.relevance,
  AssetSortKey.updatedNew,
  AssetSortKey.updatedOld,
  AssetSortKey.ratingHigh,
  AssetSortKey.ratingLow,
];

const _sourceOptions = [(AssetSource.library, 'asset_source_library'), (AssetSource.store, 'asset_source_store')];

class AssetStoreView extends ConsumerStatefulWidget {
  const AssetStoreView({super.key, this.connected = false, this.prefs});

  final bool connected;
  final UiPrefsStore? prefs;

  @override
  ConsumerState<AssetStoreView> createState() => _AssetStoreViewState();
}

class _AssetStoreViewState extends ConsumerState<AssetStoreView> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchNode = FocusNode(debugLabel: 'AssetStoreView search');
  StreamSubscription<Object?>? _focusSub;
  AssetSource _source = AssetSource.store;
  String _categoryId = '';
  String _version = '';
  AssetSortKey _sort = AssetSortKey.relevance;
  List<AssetLibraryCategory> _categories = const [];
  ({bool loading, int total}) _stats = (loading: true, total: 0);

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _focusSub = AppSignals.on(focusSearchSignal).listen((_) => _searchNode.requestFocus());
    AssetLibraryApi.listCategories().then(
      (list) {
        if (mounted) setState(() => _categories = list);
      },
      onError: (Object _) {
        if (mounted) setState(() => _categories = const []);
      },
    );
  }

  @override
  void dispose() {
    _focusSub?.cancel();
    _search.dispose();
    _searchNode.dispose();
    super.dispose();
  }

  List<AssetLibraryCategory> get _categoryOptions => [
    for (final c in _categories)
      if (c.categoryType == '0') c,
  ];

  List<AssetSortKey> _sortKeys(AssetSource source) => source == AssetSource.store ? assetStoreSortKeys : sortKeysForSource(source);

  String _sortLabel(AssetSortKey key) => _source == AssetSource.store ? ghTr('asset_store_${key.id}') : ghTr('asset_sort_${key.id}');

  void _setSource(AssetSource source) {
    setState(() {
      _source = source;
      if (!_sortKeys(source).contains(_sort)) _sort = AssetSortKey.relevance;
    });
  }

  Widget _filters(GhTheme theme) {
    final options = _categoryOptions;
    final categoryId = options.any((c) => c.id == _categoryId) ? _categoryId : '';
    final categoryLabel = categoryId.isEmpty
        ? ghTr('all_categories')
        : (options.where((c) => c.id == categoryId).firstOrNull?.name ?? categoryId);
    return Wrap(
      spacing: theme.space(2),
      runSpacing: theme.space(2),
      children: [
        GhDropdown(
          align: GhSide.left,
          items: [
            for (final (value, labelKey) in _sourceOptions)
              GhMenuItem(id: value.name, label: ghTr(labelKey), active: _source == value, onSelected: () => _setSource(value)),
          ],
          trigger: (context, open, toggle) =>
              AssetDropButton(label: ghTr(_sourceOptions.firstWhere((o) => o.$1 == _source).$2), open: open, onPressed: toggle),
        ),
        if (_source == AssetSource.library)
          GhDropdown(
            align: GhSide.left,
            items: [
              GhMenuItem(
                id: 'all',
                label: ghTr('all_categories'),
                active: categoryId.isEmpty,
                onSelected: () => setState(() => _categoryId = ''),
              ),
              for (final c in options)
                GhMenuItem(id: c.id, label: c.name, active: categoryId == c.id, onSelected: () => setState(() => _categoryId = c.id)),
            ],
            trigger: (context, open, toggle) =>
                AssetDropButton(label: categoryLabel, open: open, onPressed: toggle, maxLabelWidth: theme.space(32)),
          ),
        GhDropdown(
          align: GhSide.left,
          items: [
            for (final key in _sortKeys(_source))
              GhMenuItem(id: key.id, label: _sortLabel(key), active: _sort == key, onSelected: () => setState(() => _sort = key)),
          ],
          trigger: (context, open, toggle) => AssetDropButton(label: _sortLabel(_sort), open: open, onPressed: toggle),
        ),
        GhDropdown(
          align: GhSide.left,
          items: [
            GhMenuItem(
              id: 'all',
              label: ghTr('asset_all_versions'),
              active: _version.isEmpty,
              onSelected: () => setState(() => _version = ''),
            ),
            for (final v in assetVersionOptions)
              GhMenuItem(id: v, label: 'Godot $v', active: _version == v, onSelected: () => setState(() => _version = v)),
          ],
          trigger: (context, open, toggle) =>
              AssetDropButton(label: _version.isNotEmpty ? 'Godot $_version' : ghTr('asset_all_versions'), open: open, onPressed: toggle),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final settings = ref.watch(settingsProvider).value ?? defaultSettings;
    final insets = GhViewInsets.of(context);
    final connected = widget.connected;
    final categoryId = _categoryOptions.any((c) => c.id == _categoryId) ? _categoryId : '';
    final scrollInsets = EdgeInsetsDirectional.only(
      start: insets.start >= theme.space(2) ? insets.start - theme.space(2) : insets.start,
      end: insets.end >= theme.space(4) ? insets.end - theme.space(4) : insets.end,
      bottom: insets.bottom >= theme.space(4) ? insets.bottom - theme.space(4) : insets.bottom,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: insets.start, end: insets.end, bottom: theme.space(2)),
          child: GhViewHeader(
            connected: connected,
            title: context.tr.nav.asset_store,
            metric: [
              DefaultTextStyle.merge(
                style: theme.text(size: GhTextSize.x4l, weight: GhWeight.bold, color: theme.muted),
                child: GhAnimatedNumber(_stats.total),
              ),
              Text(
                ghTr('asset_store_count', count: _stats.total).toUpperCase(),
                style: theme.text(size: GhTextSize.lg, weight: GhWeight.medium, color: theme.muted),
              ),
            ],
            child: GhSearchBar(
              value: _search.text,
              controller: _search,
              focusNode: _searchNode,
              placeholder: ghTr('asset_search_placeholder'),
              onChanged: (_) {},
            ),
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(start: insets.start + (connected ? theme.space(3) : 0), end: insets.end + theme.space(6)),
          child: _filters(theme),
        ),
        Expanded(
          child: Padding(
            padding: scrollInsets,
            child: GhOverlayScrollArea(
              hideThumb: !settings.showScrollbars,
              topButtonBottom: theme.space(14),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(theme.space(connected ? 3 : 2), theme.space(2), theme.space(5), theme.space(8)),
                child: AssetStoreBrowser(
                  query: _search.text,
                  source: _source,
                  categoryId: categoryId,
                  version: _version,
                  sort: _sort,
                  onStatsChange: (stats) {
                    if (mounted && stats != _stats) setState(() => _stats = stats);
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
