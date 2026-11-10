import 'package:godothub/src/rust/api/types.dart';

export '../titlebar_test.dart' show baseSettings;

Project project({
  String id = 'p',
  String name = 'Project',
  String path = '/projects/p',
  String godotVersion = '4.3-stable',
  String createdAt = '2026-01-01T00:00:00Z',
  String? lastOpened,
  String? category,
  bool pinned = false,
  int sortOrder = 0,
  List<String> tags = const [],
  int totalTimeSeconds = 0,
  int? sessionStartedAtMs,
}) => Project(
  id: id,
  name: name,
  path: path,
  godotVersion: godotVersion,
  createdAt: createdAt,
  lastOpened: lastOpened,
  category: category,
  pinned: pinned,
  sortOrder: sortOrder,
  launchArguments: '',
  tags: tags,
  totalTimeSeconds: BigInt.from(totalTimeSeconds),
  sessionStartedAtMs: sessionStartedAtMs == null ? null : BigInt.from(sessionStartedAtMs),
  timeTodaySeconds: BigInt.zero,
  timeWeekSeconds: BigInt.zero,
);

AssetLibraryAsset asset({
  required String id,
  required String title,
  String author = 'someone',
  String category = 'Misc',
  String? description,
}) => AssetLibraryAsset(
  assetId: id,
  title: title,
  author: author,
  category: category,
  godotVersion: '4.3',
  cost: 'MIT',
  supportLevel: 'community',
  assetType: 'addon',
  description: description,
  rating: '0',
  source: 'library',
);

TemplateFile templateFile(String name, {bool installed = false}) =>
    TemplateFile(name: name, sizeBytes: BigInt.one, downloadBytes: BigInt.one, installed: installed);

TemplateOption templateOption(String id, List<TemplateFile> files, {bool installed = false}) => TemplateOption(
  id: id,
  label: id,
  files: files,
  sizeBytes: BigInt.zero,
  downloadBytes: BigInt.zero,
  installed: installed,
);
