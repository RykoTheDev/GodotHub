import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/asset_library.dart';
import '../api/opener.dart';
import '../design/design.dart';
import '../logic/asset_search_cache.dart';
import '../logic/asset_sort.dart';
import '../src/rust/api/types.dart';
import '../state/app_signals.dart';
import '../state/shell_signals.dart';
import '../state/asset_prefs.dart';
import '../ui/core/i18n.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/reusables/filter_bar.dart';
import '../ui/reusables/modal_kit.dart';
import '../ui/core/button.dart';
import '../ui/core/ui_settings.dart' show GhSide;
import '../ui/feedback/confirm_dialog.dart';
import '../ui/feedback/toast.dart';
import '../ui/overlays/dropdown.dart';
import '../ui/overlays/menu.dart';
import '../ui/reusables/card_grid.dart';
import '../ui/reusables/card_kit.dart';
import '../ui/reusables/state_panel.dart';
import 'asset_card.dart';
import 'asset_detail_modal.dart';
import 'asset_common.dart';

const _maxEmptySkip = 15;
const _probeDepth = 5;
const _gatherEmptyRun = 5;

const assetLibrarySortKeys = [
  AssetSortKey.relevance,
  AssetSortKey.updatedNew,
  AssetSortKey.updatedOld,
  AssetSortKey.nameAz,
  AssetSortKey.nameZa,
  AssetSortKey.ratingHigh,
  AssetSortKey.ratingLow,
  AssetSortKey.licenseAz,
  AssetSortKey.licenseZa,
];

final Set<String> _installingAssets = {};

bool assetVersionMatches(String assetVersion, String target) {
  var trimmed = assetVersion.trim();
  if (trimmed.startsWith('v')) trimmed = trimmed.substring(1);
  final a = trimmed.split(RegExp(r'[.\-+]'));
  final t = target.trim().split('.');
  return a[0] == t[0] && (a.length > 1 ? a[1] : '') == (t.length > 1 ? t[1] : '');
}

class AssetLibraryBrowser extends ConsumerStatefulWidget {
  const AssetLibraryBrowser({
    super.key,
    required this.query,
    this.onStatsChange,
    this.installedTemplateNames = const [],
    this.installedTemplateIds = const {},
    this.onClearQuery,
  });

  /// Asset ids local templates were installed from, for "Hide installed".
  final Set<String> installedTemplateIds;

  final String query;

  /// Clears the parent's search box; offered with the version filter when
  /// nothing matches.
  final VoidCallback? onClearQuery;
  final ValueChanged<({bool loading, int total})>? onStatsChange;
  final List<String> installedTemplateNames;

  @override
  ConsumerState<AssetLibraryBrowser> createState() => _AssetLibraryBrowserState();
}

class _AssetLibraryBrowserState extends ConsumerState<AssetLibraryBrowser> {
  List<AssetLibraryAsset> _assets = const [];
  bool _savedOnly = false;
  bool _hideInstalled = false;
  bool _loading = true;
  String? _error;

  /// A follow-up page (neighbour probe, gather or page change) failed while
  /// the current results stay visible.
  bool _partialError = false;

  /// The page a failed page change was heading to, retried by the notice.
  int? _retryPage;
  String _version = '';
  AssetSortKey _sort = AssetSortKey.relevance;
  int _page = 0;
  int _pages = 0;
  int _total = 0;
  String? _installing = _installingAssets.isEmpty ? null : _installingAssets.first;
  final Set<String> _installed = {};
  bool _paging = false;
  bool _canPrev = false;
  bool _canNext = false;
  Timer? _searchTimer;
  int _searchSeq = 0;
  ({bool loading, int total})? _reported;

  @override
  void initState() {
    super.initState();
    // The first search waits for the first layout, which sets the page size.
  }

  @override
  void didUpdateWidget(AssetLibraryBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _error = null;
      _schedule();
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  void _schedule() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 250), () => _runSearch().ignore());
  }

  void _setVersion(String version) {
    setState(() {
      _version = version;
      _error = null;
    });
    _schedule();
  }

  void _setSort(AssetSortKey sort) {
    setState(() {
      _sort = sort;
      _error = null;
    });
    _schedule();
  }

  void _reportStats() {
    final stats = (loading: _loading, total: _total);
    if (stats == _reported) return;
    _reported = stats;
    final callback = widget.onStatsChange;
    if (callback != null) WidgetsBinding.instance.addPostFrameCallback((_) => callback(stats));
  }

  /// Page size matched to the column count, set from the first layout.
  int _pageSize = assetPageSize;
  bool _sized = false;

  /// Requests pages that fill whole rows. Measured from the grid's width
  /// before the first search, and again when a resize changes the columns.
  Widget _sizedTo(BoxConstraints constraints, Widget child) {
    final theme = GhTheme.of(context);
    final size = assetPageSizeFor(GhGridBreakpoints.cards.columnsFor(constraints.maxWidth, fontScale: theme.fontScale));
    if (!_sized || size != _pageSize) {
      final first = !_sized;
      _sized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!first && size == _pageSize) return;
        _pageSize = size;
        _reloadForPageSize();
      });
    }
    return child;
  }

  void _reloadForPageSize() => _schedule();

  bool _isExactVersion(AssetLibraryAsset asset) => _version.isEmpty || assetVersionMatches(asset.godotVersion, _version);

  List<AssetLibraryAsset> _ranked(List<AssetLibraryAsset> list) =>
      _sort == AssetSortKey.relevance && widget.query.trim().isNotEmpty ? rankByRelevance(list, widget.query) : list;

  Future<AssetLibraryResponse?> _fetchPage(int nextPage, int seq, {bool partial = false}) async {
    final query = widget.query.trim();
    final version = _version;
    final params = assetSortParams(_sort);
    try {
      return await cachedAssetSearch(
        'lib|$query|$version|$nextPage|$_pageSize|${params.sort}|${params.reverse}',
        () => AssetLibraryApi.search(
          query.isEmpty ? null : query,
          version.isEmpty ? assetVersionOptions.first : version,
          nextPage,
          _pageSize,
          null,
          null,
          params.sort,
          params.reverse,
        ),
      );
    } catch (e) {
      if (seq == _searchSeq && mounted) {
        setState(() {
          if (partial && _assets.isNotEmpty) {
            _partialError = true;
          } else {
            _error = '$e';
          }
        });
      }
      return null;
    }
  }

  Future<AssetLibraryResponse?> _load(int nextPage, int seq, {bool partial = false}) async {
    final res = await _fetchPage(nextPage, seq, partial: partial);
    if (res == null || seq != _searchSeq || !mounted) return null;
    setState(() {
      _assets = _ranked(res.assets.where(_isExactVersion).toList());
      _pages = res.pages;
      _total = res.total;
      _page = res.page.clamp(0, res.pages - 1 < 0 ? 0 : res.pages - 1);
      _error = null;
    });
    return res;
  }

  Future<void> _probeNeighbors(int cursor, int seq) async {
    if (_version.isEmpty) {
      if (!mounted) return;
      setState(() {
        _canPrev = cursor > 0;
        _canNext = cursor + 1 < _pages;
      });
      return;
    }
    var prev = false;
    var next = false;
    for (var i = 1; i <= _probeDepth && !(prev && next); i++) {
      if (!prev && cursor - i >= 0) {
        final r = await _fetchPage(cursor - i, seq, partial: true);
        if (r != null && r.assets.any(_isExactVersion)) prev = true;
      }
      if (!next && cursor + i < _pages) {
        final r = await _fetchPage(cursor + i, seq, partial: true);
        if (r != null && r.assets.any(_isExactVersion)) next = true;
      }
    }
    if (seq != _searchSeq || !mounted) return;
    setState(() {
      _canPrev = prev;
      _canNext = next;
    });
  }

  Future<void> _gatherAll(int startPage, int seq) async {
    var collected = <AssetLibraryAsset>[];
    var emptyRun = 0;
    var cursor = startPage;
    for (var i = 0; i <= _maxEmptySkip && collected.length < (_pageSize * 3); i++) {
      final res = await _fetchPage(cursor, seq, partial: true);
      if (res == null) break;
      final matched = res.assets.where(_isExactVersion).toList();
      if (matched.isNotEmpty) {
        collected = [...collected, ...matched];
        emptyRun = 0;
      } else {
        emptyRun += 1;
        if (collected.isNotEmpty && emptyRun >= _gatherEmptyRun) break;
      }
      cursor += 1;
      if (cursor >= res.pages) break;
    }
    if (seq != _searchSeq || !mounted) return;
    setState(() {
      _assets = _ranked(collected);
      _total = collected.length;
      _pages = 1;
      _page = 0;
      _canPrev = false;
      _canNext = false;
    });
  }

  Future<void> _runSearch() async {
    final seq = ++_searchSeq;
    if (!mounted) return;
    setState(() {
      _loading = true;
      _partialError = false;
      _retryPage = null;
    });
    var cursor = 0;
    var landedPage = 0;
    AssetLibraryResponse? landedRes;
    for (var i = 0; i <= _maxEmptySkip; i++) {
      final res = await _load(cursor, seq);
      if (res != null) {
        landedPage = res.page.clamp(0, res.pages - 1 < 0 ? 0 : res.pages - 1);
        landedRes = res;
      }
      if (res == null || res.assets.any(_isExactVersion)) break;
      cursor += 1;
    }
    if (seq != _searchSeq || !mounted) return;
    if (_version.isNotEmpty && landedRes != null) {
      final firstCount = landedRes.assets.where(_isExactVersion).length;
      if (firstCount > 0 && firstCount < _pageSize) {
        await _gatherAll(landedPage, seq);
        if (seq == _searchSeq && mounted) setState(() => _loading = false);
        return;
      }
    }
    setState(() => _loading = false);
    await _probeNeighbors(landedPage, seq);
  }

  Future<void> _navigate(int target) async {
    if (_paging || _pages <= 1) return;
    final clamped = target.clamp(0, _pages - 1);
    final dir = clamped >= _page ? 1 : -1;
    setState(() {
      _paging = true;
      _partialError = false;
      _retryPage = clamped;
    });
    final seq = _searchSeq;
    var cursor = clamped;
    var landedPage = clamped;
    for (var i = 0; i <= _maxEmptySkip; i++) {
      final res = await _load(cursor, seq, partial: true);
      if (res != null) landedPage = res.page.clamp(0, res.pages - 1 < 0 ? 0 : res.pages - 1);
      if (res == null || res.assets.any(_isExactVersion)) break;
      cursor += dir;
      if (cursor < 0 || cursor >= _pages) break;
    }
    await _probeNeighbors(landedPage, seq);
    if (!mounted) return;
    setState(() => _paging = false);
    scrollAssetsToTop(context);
  }

  bool _isAlreadyInstalled(AssetLibraryAsset asset) =>
      _installed.contains(asset.assetId) ||
      widget.installedTemplateIds.contains(asset.assetId) ||
      widget.installedTemplateNames.any((name) => name.toLowerCase() == asset.title.toLowerCase());

  Future<void> _setFavorite(AssetLibraryAsset asset, bool favorite) async {
    try {
      await ref.read(assetPrefsProvider.notifier).setFavorite(asset, favorite);
    } catch (e) {
      ghToasts.pushToast(GhToastType.error, '$e');
    }
  }

  Future<void> _hide(AssetLibraryAsset asset) async {
    try {
      await ref.read(assetPrefsProvider.notifier).setHidden(asset.assetId, asset.title, true);
      ghToasts.pushToast(GhToastType.info, ghTr('asset_hidden_toast', args: {'title': asset.title}));
    } catch (e) {
      ghToasts.pushToast(GhToastType.error, '$e');
    }
  }

  Widget _card(AssetLibraryAsset asset, AssetPrefs prefs) {
    final favorite = prefs.isFavorite(asset.assetId);
    final installed = _isAlreadyInstalled(asset);
    final browse = asset.browseUrl;
    return AssetCard(
      key: ValueKey(asset.assetId),
      asset: asset,
      favorite: favorite,
      onToggleFavorite: () => _setFavorite(asset, !favorite).ignore(),
      onHide: () => _hide(asset).ignore(),
      onOpenDetails: () => showAssetDetails(
        context,
        asset,
        primaryLabel: installed ? ghTr('asset_installed') : ghTr('asset_install'),
        onPrimary: () => _install(asset).ignore(),
      ).ignore(),
      onOpenPage: browse != null && browse.isNotEmpty ? () => OpenerApi.openUrl(browse).ignore() : null,
      actions: [_installButton(asset)],
    );
  }

  Future<void> _doInstall(AssetLibraryAsset asset) async {
    if (_installing != null || _installingAssets.contains(asset.assetId)) return;
    _installingAssets.add(asset.assetId);
    setState(() => _installing = asset.assetId);
    try {
      await AssetLibraryApi.installAsTemplate(asset.assetId);
      if (mounted) setState(() => _installed.add(asset.assetId));
      AppSignals.emit(refreshTemplatesSignal);
    } catch (e) {
      ghToasts.pushToast(GhToastType.error, ghTr('asset_install_failed_toast', args: {'title': asset.title, 'error': '$e'}));
    } finally {
      _installingAssets.remove(asset.assetId);
      if (mounted) setState(() => _installing = null);
    }
  }

  Future<void> _install(AssetLibraryAsset asset) async {
    if (_isAlreadyInstalled(asset)) {
      final confirmed = await showGhConfirmDialog(
        context,
        title: ghTr('asset_duplicate_title'),
        description: ghTr('asset_duplicate_desc', args: {'name': asset.title}),
        confirmLabel: ghTr('asset_install'),
      );
      if (!confirmed || !mounted) return;
    }
    await _doInstall(asset);
  }

  Widget _installButton(AssetLibraryAsset asset) {
    final isInstalled = _installed.contains(asset.assetId) || _isAlreadyInstalled(asset);
    final isInstalling = _installing == asset.assetId || _installingAssets.contains(asset.assetId);
    return GhButton(
      onPressed: isInstalling ? null : () => _install(asset).ignore(),
      label: ghTr(
        isInstalling
            ? 'asset_installing'
            : isInstalled
            ? 'asset_installed'
            : 'asset_install',
      ),
      icon: isInstalling
          ? GhIcons.spinner
          : isInstalled
          ? GhIcons.check
          : GhIcons.download,
      variant: isInstalled ? GhButtonVariant.outline : GhButtonVariant.primary,
      expand: true,
      disabledOpacity: 0.7,
    );
  }

  void _retryPartial() {
    final page = _retryPage;
    if (page != null && _pages > 1) {
      _navigate(page).ignore();
    } else {
      _runSearch().ignore();
    }
  }

  void _clearFilters() {
    widget.onClearQuery?.call();
    if (_hideInstalled) setState(() => _hideInstalled = false);
    if (_version.isNotEmpty) _setVersion('');
  }

  List<Widget> _quickFilters(GhTheme theme) {
    final prefs = ref.watch(assetPrefsProvider).data;
    final savedCount = prefs.favorites.where((a) => a.source == 'library').length;
    return [
      GhChoiceChip(
        key: const ValueKey('library-filter-saved'),
        label: ghTr('asset_saved_filter', args: {'count': savedCount}),
        active: _savedOnly,
        onPressed: () => setState(() => _savedOnly = !_savedOnly),
      ),
      GhChoiceChip(
        key: const ValueKey('library-filter-hide-installed'),
        label: ghTr('templates_hide_installed'),
        active: _hideInstalled,
        tone: GhChoiceTone.mint,
        onPressed: () => setState(() => _hideInstalled = !_hideInstalled),
      ),
      if (prefs.hidden.isNotEmpty)
        GhButton(
          key: const ValueKey('library-hidden-manage'),
          onPressed: () => showGhModal<void>(context, (modal) => HiddenAssetsModal(onClose: () => Navigator.of(modal).pop())).ignore(),
          icon: GhIcons.eyeSlash,
          label: ghTr('asset_hidden_manage', args: {'count': prefs.hidden.length}),
          variant: GhButtonVariant.ghost,
          size: GhTextSize.xs,
        ),
    ];
  }

  Widget _filters(GhTheme theme) => GhFilterBar(
    primary: [
      GhDropdown(
        align: GhSide.left,
        items: [
          for (final key in assetLibrarySortKeys)
            GhMenuItem(id: key.id, label: ghTr('asset_store_${key.id}'), active: _sort == key, onSelected: () => _setSort(key)),
        ],
        trigger: (context, open, toggle) => AssetDropButton(label: ghTr('asset_store_${_sort.id}'), open: open, onPressed: toggle),
      ),
      GhDropdown(
        align: GhSide.left,
        items: [
          GhMenuItem(id: 'all', label: ghTr('asset_all_versions'), active: _version.isEmpty, onSelected: () => _setVersion('')),
          for (final v in assetVersionOptions)
            GhMenuItem(id: v, label: 'Godot $v', active: _version == v, onSelected: () => _setVersion(v)),
        ],
        trigger: (context, open, toggle) =>
            AssetDropButton(label: _version.isNotEmpty ? 'Godot $_version' : ghTr('asset_all_versions'), open: open, onPressed: toggle),
      ),
    ],
    secondary: _quickFilters(theme),
    trailing: _loading
        ? null
        : Text(
            ghTr('asset_result_count', args: {'count': _total}),
            style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.muted),
          ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final prefs = ref.watch(assetPrefsProvider).data;
    final hidden = prefs.hiddenIds;
    final visible = [
      for (final a in _assets)
        if (!hidden.contains(a.assetId) && !(_hideInstalled && _isAlreadyInstalled(a))) a,
    ];
    _reportStats();
    final Widget body;
    final filtered = _version.isNotEmpty || _hideInstalled || (widget.query.trim().isNotEmpty && widget.onClearQuery != null);
    if (_savedOnly) {
      final query = widget.query.trim().toLowerCase();
      final saved = [
        for (final a in prefs.favorites)
          if (a.source == 'library' && (query.isEmpty || a.title.toLowerCase().contains(query))) a,
      ];
      body = saved.isEmpty
          ? GhStatePanel.empty(icon: GhIcons.star, title: ghTr('asset_saved_empty_title'), message: ghTr('asset_saved_empty_desc'))
          : GhCardGrid(children: [for (final a in saved) _card(a, prefs)]);
    } else if (_loading) {
      body = GhCardGrid.fill(rows: 2, builder: (context, _) => const GhCardSkeleton(mediaHeight: 40, showcase: true));
    } else if (_error != null) {
      body = GhStatePanel.error(
        title: ghTr('asset_load_error_title'),
        message: ghTr('asset_load_error'),
        onRetry: () => _runSearch().ignore(),
        actions: [
          GhButton(
            onPressed: () => OpenerApi.openUrl(assetLibrarySiteUrl).ignore(),
            label: ghTr('asset_open_page'),
            icon: GhIcons.externalLink,
            variant: GhButtonVariant.ghost,
          ),
        ],
      );
    } else if (_assets.isEmpty) {
      body = GhStatePanel.empty(
        icon: GhIcons.store,
        title: ghTr('asset_no_results_title'),
        message: filtered ? ghTr('asset_no_results_filtered') : null,
        actions: [
          if (filtered) GhButton(onPressed: _clearFilters, label: ghTr('clear_filters'), icon: GhIcons.x, variant: GhButtonVariant.outline),
        ],
      );
    } else {
      final Widget? pager;
      if (_version.isEmpty) {
        pager = _page > 0 || _page + 1 < _pages
            ? AssetPagination(page: _page, pages: _pages, paging: _paging, onNavigate: _navigate)
            : null;
      } else {
        pager = _canPrev || _canNext
            ? AssetPagination(
                page: _page,
                pages: _pages,
                paging: _paging,
                onNavigate: _navigate,
                numbered: false,
                canPrev: _canPrev,
                canNext: _canNext,
              )
            : null;
      }
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(3),
        children: [
          if (_partialError)
            GhCardNotice(
              tone: GhTone.danger,
              message: ghTr('asset_partial_error'),
              action: GhButton(onPressed: _retryPartial, label: ghTr('retry'), size: GhTextSize.xs, paddingY: 1.5),
            ),
          if (visible.isEmpty)
            GhCardNotice(message: ghTr('asset_page_all_hidden'))
          else
            GhCardGrid(gap: 4, children: [for (final asset in visible) _card(asset, prefs)]),
          ?pager,
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => _sizedTo(
        constraints,
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: theme.space(3), children: [_filters(theme), body]),
      ),
    );
  }
}
