import 'package:flutter/foundation.dart';

import '../api/versions.dart';
import '../src/rust/api/types.dart';

typedef TemplateOptionsFetcher = Future<List<TemplateOption>> Function(String tag, bool refresh);

final _catalogs = <String, List<TemplateOption>>{};
final _requests = <String, Future<List<TemplateOption>>>{};

List<TemplateOption>? getCachedTemplateOptions(String tag) => _catalogs[tag];

void cacheTemplateOptions(String tag, List<TemplateOption> options) {
  _catalogs[tag] = options;
}

void setTemplateFilesInstalled(String tag, List<String>? names, bool installed) {
  final options = _catalogs[tag];
  if (options == null) return;
  final changed = names?.toSet();
  cacheTemplateOptions(tag, [
    for (final option in options)
      _withFiles(option, [
        for (final file in option.files)
          changed == null || changed.contains(file.name)
              ? TemplateFile(name: file.name, sizeBytes: file.sizeBytes, downloadBytes: file.downloadBytes, installed: installed)
              : file,
      ]),
  ]);
}

TemplateOption _withFiles(TemplateOption option, List<TemplateFile> files) => TemplateOption(
  id: option.id,
  label: option.label,
  files: files,
  sizeBytes: option.sizeBytes,
  downloadBytes: option.downloadBytes,
  installed: files.every((file) => file.installed),
);

Future<List<TemplateOption>> loadTemplateOptions(String tag, {bool refresh = false, TemplateOptionsFetcher? fetch}) {
  final key = '$tag:$refresh';
  final existing = _requests[key];
  if (existing != null) return existing;
  final fetcher = fetch ?? VersionsApi.getExportTemplateOptions;
  final request = Future<List<TemplateOption>>.sync(() => fetcher(tag, refresh))
      .then((options) {
        cacheTemplateOptions(tag, options);
        return options;
      })
      .whenComplete(() {
        _requests.remove(key);
      });
  _requests[key] = request;
  return request;
}

@visibleForTesting
void clearTemplateCatalog() {
  _catalogs.clear();
  _requests.clear();
}
