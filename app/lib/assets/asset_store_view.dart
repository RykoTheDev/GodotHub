import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/asset_library.dart';
import '../api/templates.dart';
import '../logic/pending_action.dart';
import '../design/design.dart';
import '../logic/asset_sort.dart';
import '../motion/animated_number.dart';
import '../src/rust/api/types.dart';
import '../src/ui_prefs.dart';
import '../state/app_signals.dart';
import '../state/asset_prefs.dart';
import '../state/keyboard_shortcuts.dart' show focusSearchSignal, setTabSignal;
import '../state/shell_signals.dart' show refreshTemplatesSignal;
import '../state/settings.dart';
import '../ui/controls/search_bar.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/reusables/filter_bar.dart';
import '../ui/reusables/modal_kit.dart';
import '../ui/reusables/segmented.dart';
import '../ui/core/ui_settings.dart' show GhSide;
import '../ui/overlays/dropdown.dart';
import '../ui/overlays/menu.dart';
import '../ui/reusables/view_header.dart';
import '../ui/reusables/view_tabs.dart';
import '../ui/shell/overlay_scroll_area.dart';
import '../ui/shell/view_insets.dart';
import 'asset_common.dart';
import 'asset_library_browser.dart';
import 'asset_detail_modal.dart';
import 'asset_store_browser.dart';

const assetStoreSortKeys = [
  AssetSortKey.relevance,
  AssetSortKey.updatedNew,
  AssetSortKey.updatedOld,
  AssetSortKey.ratingHigh,
  AssetSortKey.ratingLow,
];

/// Signal that switches a mounted Asset Store view to a section
/// (detail: `'templates'` or `'addons'`).
const assetStoreSectionSignal = 'app:asset-store-section';
const _templatesAction = 'asset-store:templates';

/// Opens the Asset Store on its Templates section, from anywhere.
void openAssetStoreTemplates() {
  setPendingAction(_templatesAction);
  AppSignals.emit(setTabSignal, 'asset-store');
  AppSignals.emit(assetStoreSectionSignal, 'templates');
}

enum _StoreSection { addons, templates }

const _sourceOptions = [(AssetSource.store, 'asset_source_new'), (AssetSource.library, 'asset_source_old')];

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
  StreamSubscription<Object?>? _sectionSub;
  StreamSubscription<Object?>? _templatesSub;
  _StoreSection _section = _StoreSection.addons;
  List<ProjectTemplate> _templates = const [];
  ({bool loading, int total}) _templateStats = (loading: true, total: 0);
  AssetSource _source = AssetSource.store;
  String _categoryId = '';
  String _version = '';
  AssetSortKey _sort = AssetSortKey.relevance;
  bool _savedOnly = false;

  List<AssetLibraryCategory> _categories = const [];
  ({bool loading, int total}) _stats = (loading: true, total: 0);

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _focusSub = AppSignals.on(focusSearchSignal).listen((_) => _searchNode.requestFocus());
    if (consumePendingActionIf(_templatesAction)) _section = _StoreSection.templates;
    _sectionSub = AppSignals.on(assetStoreSectionSignal).listen((signal) {
      consumePendingActionIf(_templatesAction);
      final section = signal.detail == 'templates' ? _StoreSection.templates : _StoreSection.addons;
      if (mounted) _setSection(section);
    });
    _templatesSub = AppSignals.on(refreshTemplatesSignal).listen((_) => _loadTemplates());
    _loadTemplates();
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
    _sectionSub?.cancel();
    _templatesSub?.cancel();
    _search.dispose();
    _searchNode.dispose();
    super.dispose();
  }

  /// Local templates, so the template library can mark and hide the ones
  /// already installed.
  void _loadTemplates() {
    TemplatesApi.list().then((list) {
      if (mounted) setState(() => _templates = list);
    }, onError: (Object _) {});
  }

  void _setSection(_StoreSection section) {
    if (section == _section) return;
    _search.clear();
    setState(() => _section = section);
  }

  List<AssetLibraryCategory> get _categoryOptions => [
    for (final c in _categories)
      if (c.categoryType == '0') c,
  ];

  List<AssetSortKey> _sortKeys(AssetSource source) => source == AssetSource.store ? assetStoreSortKeys : sortKeysForSource(source);

  String _sortLabel(AssetSortKey key) => ghTr('asset_store_${key.id}');

  void _setSource(AssetSource source) {
    setState(() {
      _source = source;
      if (!_sortKeys(source).contains(_sort)) _sort = AssetSortKey.relevance;
    });
  }

  void _clearFilters() {
    _search.clear();
    setState(() {
      _version = '';
      _categoryId = '';
    });
  }

  List<Widget> _quickFilters(GhTheme theme) {
    final prefs = ref.watch(assetPrefsProvider).data;
    final source = _source == AssetSource.library ? 'library' : 'store';
    final savedCount = prefs.favorites.where((a) => a.source == source).length;
    return [
      GhChoiceChip(
        key: const ValueKey('asset-filter-saved'),
        label: ghTr('asset_saved_filter', args: {'count': savedCount}),
        active: _savedOnly,
        tone: GhChoiceTone.accent,
        onPressed: () => setState(() => _savedOnly = !_savedOnly),
      ),
      if (prefs.hidden.isNotEmpty)
        GhButton(
          key: const ValueKey('asset-hidden-manage'),
          onPressed: () => showGhModal<void>(context, (modal) => HiddenAssetsModal(onClose: () => Navigator.of(modal).pop())).ignore(),
          icon: GhIcons.eyeSlash,
          label: ghTr('asset_hidden_manage', args: {'count': prefs.hidden.length}),
          variant: GhButtonVariant.ghost,
          size: GhTextSize.xs,
        ),
    ];
  }

  List<Widget> _filters(GhTheme theme) {
    final shown = _version;
    final options = _categoryOptions;
    final categoryId = options.any((c) => c.id == _categoryId) ? _categoryId : '';
    final categoryLabel = categoryId.isEmpty
        ? ghTr('all_categories')
        : (options.where((c) => c.id == categoryId).firstOrNull?.name ?? categoryId);
    return [
      Padding(
        padding: EdgeInsetsDirectional.only(start: theme.space(2)),
        child: Text(
          ghTr('asset_source_label'),
          style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: theme.muted),
        ),
      ),
      GhSegmented(
        key: const ValueKey('asset-source-tabs'),
        value: _source.name,
        options: [for (final (value, labelKey) in _sourceOptions) ghSegment(value.name, ghTr(labelKey))],
        onChanged: (name) => _setSource(AssetSource.values.firstWhere((s) => s.name == name)),
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
            active: shown.isEmpty,
            onSelected: () => setState(() {
              _version = '';
            }),
          ),
          for (final v in assetVersionOptions)
            GhMenuItem(
              id: v,
              label: 'Godot $v',
              active: shown == v,
              onSelected: () => setState(() {
                _version = v;
              }),
            ),
        ],
        trigger: (context, open, toggle) =>
            AssetDropButton(label: shown.isNotEmpty ? 'Godot $shown' : ghTr('asset_all_versions'), open: open, onPressed: toggle),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final settings = ref.watch(settingsProvider).value ?? defaultSettings;
    final insets = GhViewInsets.of(context);
    final templates = _section == _StoreSection.templates;
    final total = templates ? _templateStats.total : _stats.total;
    final connected = widget.connected;
    final categoryId = _categoryOptions.any((c) => c.id == _categoryId) ? _categoryId : '';
    final version = _version;
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
                child: GhAnimatedNumber(total),
              ),
              Text(
                ghTr('asset_store_count', count: total),
                style: theme.text(size: GhTextSize.lg, weight: GhWeight.medium, color: theme.muted),
              ),
            ],
            child: LayoutBuilder(
              builder: (context, constraints) {
                final search = GhSearchBar(
                  value: _search.text,
                  controller: _search,
                  focusNode: _searchNode,
                  placeholder: ghTr(templates ? 'template_search_placeholder' : 'asset_search_placeholder'),
                  onChanged: (_) {},
                );
                final tabs = GhViewTabs(
                  value: _section.name,
                  onChanged: (v) => _setSection(_StoreSection.values.firstWhere((s) => s.name == v)),
                  tabs: [
                    (value: _StoreSection.addons.name, label: ghTr('asset_section_addons'), icon: GhIcons.plug),
                    (value: _StoreSection.templates.name, label: ghTr('asset_section_templates'), icon: GhIcons.copy),
                  ],
                );
                // Narrow windows stack the section switch under the search box.
                if (constraints.maxWidth < theme.space(110)) {
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: theme.space(2), children: [search, tabs]);
                }
                return Row(
                  spacing: theme.space(2),
                  children: [
                    Expanded(child: search),
                    tabs,
                  ],
                );
              },
            ),
          ),
        ),
        if (!templates)
          Padding(
            padding: EdgeInsetsDirectional.only(
              // The same edges as the card grid below.
              start: scrollInsets.start + theme.space(connected ? 3 : 2),
              end: scrollInsets.end + theme.space(5),
              bottom: theme.space(1),
            ),
            child: GhFilterBar(primary: _filters(theme), secondary: _quickFilters(theme)),
          ),
        Expanded(
          child: Padding(
            padding: scrollInsets,
            child: GhOverlayScrollArea(
              hideThumb: !settings.showScrollbars,
              topButtonBottom: theme.space(24),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(theme.space(connected ? 3 : 2), theme.space(2), theme.space(5), theme.space(8)),
                child: templates
                    ? AssetLibraryBrowser(
                        key: const ValueKey('asset-store-templates'),
                        query: _search.text,
                        onClearQuery: _search.clear,
                        onStatsChange: (stats) {
                          if (mounted && stats != _templateStats) setState(() => _templateStats = stats);
                        },
                        installedTemplateNames: [for (final t in _templates) t.name],
                        installedTemplateIds: {
                          for (final t in _templates)
                            if (t.sourceAssetId != null) t.sourceAssetId!,
                        },
                      )
                    : AssetStoreBrowser(
                        query: _search.text,
                        source: _source,
                        categoryId: categoryId,
                        version: version,
                        sort: _sort,
                        savedOnly: _savedOnly,
                        onClearFilters: _search.text.trim().isNotEmpty || version.isNotEmpty || categoryId.isNotEmpty
                            ? _clearFilters
                            : null,
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
