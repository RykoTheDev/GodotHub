import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/api/opener.dart';
import 'package:godothub/assets/asset_card.dart';
import 'package:godothub/assets/asset_common.dart';
import 'package:godothub/assets/asset_library_browser.dart';
import 'package:godothub/assets/asset_store_view.dart';
import 'package:godothub/logic/asset_search_cache.dart';
import 'package:godothub/modals/install_asset_modal.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/state/app_signals.dart';
import 'package:godothub/state/shell_signals.dart';
import 'package:godothub/ui/core/i18n.dart';

import '../projects/project_actions_test.dart' as base;
import '../support/fake_rust.dart';
import '../ui/i18n_setup.dart';

late FakeRustApi rust;
final opened = <String>[];

AssetLibraryAsset asset(
  String id, {
  String? title,
  String godotVersion = '4.3',
  String source = 'library',
  String assetType = 'addon',
  String rating = '0',
  String? browseUrl,
}) => AssetLibraryAsset(
  assetId: id,
  title: title ?? 'Asset $id',
  author: 'Ryko',
  category: '2D Tools',
  godotVersion: godotVersion,
  cost: 'MIT',
  supportLevel: 'community',
  assetType: assetType,
  description: 'Line one\nline two',
  rating: rating,
  source: source,
  browseUrl: browseUrl,
);

ProjectTemplate template(String id, String name) =>
    ProjectTemplate(id: id, name: name, description: '$name desc', godotVersion: '4.3', createdAt: '', path: 'C:/t/$id', keepName: false);

InstallAssetResult result(String targetType) =>
    InstallAssetResult(assetId: 'a', title: 't', targetType: targetType, targetName: 'x', path: 'C:/x', addonFolders: const []);

class AssetBackend {
  final calls = <String>[];
  List<AssetLibraryAsset> store = [
    asset('store:pub/one', source: 'store', browseUrl: 'https://store/one'),
    asset('store:pub/two', source: 'store'),
  ];
  int storePages = 3;
  Object? storeError;
  Map<int, List<AssetLibraryAsset>> libraryPages = {
    0: [asset('1', godotVersion: '4.2'), asset('2')],
  };

  void install(FakeRustApi rust) {
    rust
      ..on(
        'crateApiAssetLibraryGetAssetLibraryCategories',
        () async => const [
          AssetLibraryCategory(id: '5', name: 'Scripts', categoryType: '0'),
          AssetLibraryCategory(id: '9', name: 'Demos', categoryType: '1'),
        ],
      )
      ..on('crateApiAssetLibrarySearchAssetStore', ({
        String? filter,
        String? godotVersion,
        int? page,
        int? maxResults,
        String? sort,
      }) async {
        calls.add('store:$filter:$godotVersion:$page:$sort');
        if (storeError != null) throw storeError!;
        return AssetLibraryResponse(assets: store, page: page ?? 0, pages: storePages, total: storePages * 12);
      })
      ..on('crateApiAssetLibrarySearchAssetLibrary', ({
        String? filter,
        String? godotVersion,
        int? page,
        int? maxResults,
        String? assetType,
        String? categoryId,
        String? sort,
        bool? reverse,
      }) async {
        calls.add('lib:$filter:$godotVersion:$page:$assetType:$categoryId:$sort');
        final list = libraryPages[page ?? 0] ?? const <AssetLibraryAsset>[];
        return AssetLibraryResponse(assets: list, page: page ?? 0, pages: libraryPages.length, total: 30);
      })
      ..on('crateApiAssetLibraryDownloadStoreAsset', ({
        required String publisherSlug,
        required String assetSlug,
        String? title,
        String? destDir,
      }) async {
        calls.add('download-store:$publisherSlug:$assetSlug:$title');
        return 'C:/dl/$assetSlug/file.zip';
      })
      ..on('crateApiProjectsOpenProjectFolder', ({required String path}) async => calls.add('open:$path'))
      ..on('crateApiAssetLibraryInstallAssetAsTemplate', ({required String assetId}) async {
        calls.add('as-template:$assetId');
        return template('new', 'Fresh template');
      })
      ..on('crateApiAssetLibraryInstallAsset', ({required String assetId, String? projectId, String? templateId}) async {
        calls.add('install:$assetId:$projectId:$templateId');
        return result(projectId != null ? 'project' : 'template');
      })
      ..on('crateApiAssetLibraryInstallStoreAsset', ({
        required String publisherSlug,
        required String assetSlug,
        String? title,
        String? projectId,
        String? templateId,
      }) async {
        calls.add('install-store:$publisherSlug:$assetSlug:$projectId:$templateId');
        return result(projectId != null ? 'project' : 'template');
      })
      ..on('crateApiTemplatesListTemplates', () async => [template('t1', 'Platformer')])
      ..on('crateApiProjectsListProjects', () async => [base.demo]);
  }
}

void main() {
  setUpAll(() async {
    await base.loadFont('Inter', ['assets/fonts/inter-latin.ttf']);
    await base.loadFont('GoogleSansCode', ['assets/fonts/gsc-latin-400.ttf', 'assets/fonts/gsc-latin-500.ttf']);
  });
  setUp(setUpTestI18n);
  setUp(() {
    rust = installFakeRust();
    base.rust = rust;
    UiPrefsStore.instance = UiPrefsStore(MemoryUiPrefsBackend());
    clearAssetSearchCache();
    opened.clear();
    OpenerApi.debugOpenUrl = (url) async => opened.add(url);
  });
  tearDown(() => OpenerApi.debugOpenUrl = null);

  group('logic', () {
    test('ids, paths, page items, versions and ratings', () {
      expect(parseStoreId('store:pub/my-asset'), ('pub', 'my-asset'));
      expect(parseStoreId('lonely'), ('lonely', ''));
      expect(assetDirname('C:\\dl\\a\\file.zip'), 'C:\\dl\\a');
      expect(assetDirname('/tmp/x/y.zip'), '/tmp/x');
      expect(assetPageItems(0, 5), [0, 1, 2, 3, 4]);
      expect(assetPageItems(0, 20), [0, 1, null, 19]);
      expect(assetPageItems(10, 20), [0, null, 9, 10, 11, null, 19]);
      expect(assetPageItems(19, 20), [0, null, 18, 19]);
      expect(assetVersionMatches('v4.3.1', '4.3'), isTrue);
      expect(assetVersionMatches('4.3-stable', '4.3'), isTrue);
      expect(assetVersionMatches('4.2', '4.3'), isFalse);
      expect(parseAssetRating('4.56 stars'), closeTo(4.56, 0.001));
      expect(parseAssetRating(''), isNull);
      expect(AssetGrid.columnsFor(1400), 3);
      expect(AssetGrid.columnsFor(800), 2);
      expect(AssetGrid.columnsFor(500), 1);
    });
  });

  group('asset store view', () {
    testWidgets('loads store results, paginates and switches to the library with categories', (tester) async {
      final backend = AssetBackend()..install(rust);
      await base.pumpHost(tester, body: const AssetStoreView());
      await base.settle(tester);
      expect(find.text('Asset store:pub/one'), findsOneWidget);
      expect(find.text(ghTr('asset_by_author', args: {'author': 'Ryko'})), findsNWidgets(2));
      expect(find.text('Line one line two'), findsNWidgets(2));
      expect(backend.calls.first, 'store:null:null:0:relevance');
      await tester.tap(find.bySemanticsLabel(ghTr('asset_page_x_of_y', args: {'page': 2, 'total': 3})));
      await base.settle(tester);
      expect(backend.calls.last, 'store:null:null:1:relevance');
      await tester.tap(find.text(ghTr('asset_source_store')));
      await base.settle(tester, 4);
      await tester.tap(find.text(ghTr('asset_source_library')).last);
      await base.settle(tester);
      expect(find.text(ghTr('all_categories')), findsOneWidget);
      expect(backend.calls.last, 'lib:null:4.7:0:addon:null:null');
      await tester.tap(find.text(ghTr('all_categories')));
      await base.settle(tester, 4);
      expect(find.text('Demos'), findsNothing);
      await tester.tap(find.text('Scripts'));
      await base.settle(tester);
      expect(backend.calls.last, 'lib:null:4.7:0:addon:5:null');
    });

    testWidgets('shows the load error and retries', (tester) async {
      final backend = AssetBackend()
        ..storeError = 'offline'
        ..install(rust);
      await base.pumpHost(tester, body: const AssetStoreView());
      await base.settle(tester);
      expect(find.text(ghTr('asset_load_error')), findsOneWidget);
      backend.storeError = null;
      await tester.tap(find.text(ghTr('retry')));
      await base.settle(tester);
      expect(find.text('Asset store:pub/one'), findsOneWidget);
    });

    testWidgets('downloads a store asset outside and opens the page link', (tester) async {
      final backend = AssetBackend()..install(rust);
      await base.pumpHost(tester, body: const AssetStoreView());
      await base.settle(tester);
      await tester.tap(find.bySemanticsLabel(ghTr('project_more_aria')).first);
      await base.settle(tester, 4);
      await tester.tap(find.text(ghTr('asset_download_outside')));
      await base.settle(tester);
      expect(backend.calls, containsAll(['download-store:pub:one:Asset store:pub/one', 'open:C:/dl/one']));
      expect(find.text('${ghTr('asset_downloaded_to')} C:/dl/one'), findsOneWidget);
      final card = find.ancestor(of: find.text('Asset store:pub/one'), matching: find.byType(AssetCard));
      await tester.tap(find.descendant(of: card, matching: find.bySemanticsLabel(ghTr('asset_open_page'))));
      await base.settle(tester, 2);
      expect(opened, ['https://store/one']);
      await tester.pump(const Duration(seconds: 6));
      expect(find.text('${ghTr('asset_downloaded_to')} C:/dl/one'), findsNothing);
    });

    testWidgets('install inside opens the modal and marks the asset installed', (tester) async {
      final backend = AssetBackend()..install(rust);
      await base.pumpHost(tester, body: const AssetStoreView());
      await base.settle(tester);
      await tester.tap(find.text(ghTr('asset_install_inside')).first);
      await base.settle(tester);
      expect(find.bySemanticsLabel(ghTr('asset_install_modal_title', args: {'title': 'Asset store:pub/one'})), findsWidgets);
      await tester.tap(find.text('Demo'));
      await base.settle(tester, 3);
      await tester.tap(find.text(ghTr('asset_install_into', args: {'name': 'Demo'})));
      await base.settle(tester);
      expect(backend.calls, contains('install-store:pub:one:p1:null'));
      expect(find.text(ghTr('asset_install_success_project', args: {'target': 'Demo'})), findsOneWidget);
      expect(find.text(ghTr('asset_installed')), findsOneWidget);
    });
  });

  group('install modal', () {
    testWidgets('template tab filters, saves as new template and shows errors', (tester) async {
      final backend = AssetBackend()..install(rust);
      final outcomes = <AssetInstallOutcome>[];
      var signals = 0;
      final sub = AppSignals.on(refreshTemplatesSignal).listen((_) => signals++);
      addTearDown(sub.cancel);
      var closed = 0;
      await base.openModal(
        tester,
        (close) => InstallAssetModal(
          asset: asset('42', title: 'Starter kit', assetType: 'project'),
          onClose: () {
            closed++;
            close();
          },
          onInstalled: outcomes.add,
        ),
      );
      expect(find.text(ghTr('asset_new_template_btn')), findsNothing);
      await tester.tap(find.text(ghTr('asset_install_tab_template')));
      await base.settle(tester, 3);
      expect(find.text('Platformer'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'zzz');
      await base.settle(tester, 2);
      expect(find.text(ghTr('asset_install_no_templates')), findsOneWidget);
      await tester.enterText(find.byType(EditableText), '');
      await base.settle(tester, 2);
      await tester.tap(find.text('Platformer'));
      await base.settle(tester, 2);
      rust.on(
        'crateApiAssetLibraryInstallAsset',
        ({required String assetId, String? projectId, String? templateId}) async => throw 'disk full',
      );
      await tester.tap(find.text(ghTr('asset_install_into', args: {'name': 'Platformer'})));
      await base.settle(tester);
      expect(find.text('disk full'), findsOneWidget);
      expect(closed, 0);
      await tester.tap(find.text(ghTr('asset_new_template_btn')));
      await base.settle(tester);
      expect(backend.calls, contains('as-template:42'));
      expect(signals, 1);
      expect(outcomes.single.targetType, AssetInstallTarget.template);
      expect(outcomes.single.targetName, 'Fresh template');
      expect(closed, 1);
    });
  });

  group('asset library browser', () {
    testWidgets('installs as template, confirms duplicates and filters by version', (tester) async {
      final backend = AssetBackend()..install(rust);
      var signals = 0;
      final sub = AppSignals.on(refreshTemplatesSignal).listen((_) => signals++);
      addTearDown(sub.cancel);
      final stats = <({bool loading, int total})>[];
      await base.pumpHost(
        tester,
        body: SingleChildScrollView(
          child: AssetLibraryBrowser(query: '', installedTemplateNames: const ['Asset 2'], onStatsChange: stats.add),
        ),
      );
      await base.settle(tester);
      expect(stats.last, (loading: false, total: 30));
      expect(find.text(ghTr('asset_result_count', args: {'count': 30})), findsOneWidget);
      expect(find.text(ghTr('asset_installed')), findsOneWidget);
      await tester.tap(find.text(ghTr('asset_install')).first);
      await base.settle(tester);
      expect(backend.calls, contains('as-template:1'));
      expect(signals, 1);
      expect(find.text(ghTr('asset_installed')), findsNWidgets(2));
      await tester.tap(find.text(ghTr('asset_installed')).last);
      await base.settle(tester, 4);
      expect(find.text(ghTr('asset_duplicate_desc', args: {'name': 'Asset 2'})), findsOneWidget);
      await tester.tap(find.text(ghTr('asset_install')).last);
      await base.settle(tester);
      expect(backend.calls, contains('as-template:2'));
      await tester.tap(find.text(ghTr('asset_all_versions')));
      await base.settle(tester, 4);
      await tester.tap(find.text('Godot 4.3').first);
      await base.settle(tester);
      expect(find.text('Asset 1'), findsNothing);
      expect(find.text('Asset 2'), findsOneWidget);
      expect(find.text(ghTr('asset_result_count', args: {'count': 1})), findsOneWidget);
    });
  });
}
