import '../i18n/i18n.dart';
import '../src/rust/api/types.dart';

typedef ExportTemplateFile = TemplateFile;

class TemplateFileGroup {
  const TemplateFileGroup({required this.id, required this.label, this.labelKey, required this.files});

  final String id;
  final String? label;
  final String? labelKey;
  final List<TemplateFile> files;

  String? displayLabel([Translations? translations]) {
    final tr = (translations ?? t).versions;
    return switch (labelKey) {
      'export_templates_web_standard' => tr.export_templates_web_standard,
      'export_templates_web_extensions' => tr.export_templates_web_extensions,
      'export_templates_web_single_threaded' => tr.export_templates_web_single_threaded,
      'export_templates_web_extensions_single_threaded' => tr.export_templates_web_extensions_single_threaded,
      _ => label,
    };
  }
}

class TemplateOptionCategory {
  const TemplateOptionCategory({required this.id, required this.labelKey, required this.options});

  final String id;
  final String labelKey;
  final List<TemplateOption> options;

  String label([Translations? translations]) {
    final tr = (translations ?? t).versions;
    return switch (id) {
      'desktop' => tr.export_templates_category_desktop,
      'mobile' => tr.export_templates_category_mobile,
      'web' => tr.export_templates_category_web,
      'common' => tr.export_templates_category_common,
      _ => tr.export_templates_category_other,
    };
  }
}

const _webGroups = <String, (String, String)>{
  'web_standard': ('Web', 'export_templates_web_standard'),
  'web_extensions': ('Web with Extensions', 'export_templates_web_extensions'),
  'web_single_threaded': ('Web Single-Threaded', 'export_templates_web_single_threaded'),
  'web_extensions_single_threaded': (
    'Web with Extensions Single-Threaded',
    'export_templates_web_extensions_single_threaded',
  ),
};

const _architectureLabels = <String, String>{
  'x86_32': 'x86 (32-bit)',
  'x32': 'x86 (32-bit)',
  '32': 'x86 (32-bit)',
  'x86_64': 'x86_64 (64-bit)',
  'amd64': 'x86_64 (64-bit)',
  'x64': 'x86_64 (64-bit)',
  '64': 'x86_64 (64-bit)',
  'arm32': 'ARM32',
  'armv7': 'ARM32',
  'arm64': 'ARM64',
  'aarch64': 'ARM64',
};

const _groupOrder = [
  'x86 (32-bit)',
  'x86_64 (64-bit)',
  'ARM32',
  'ARM64',
  'web_standard',
  'web_extensions',
  'web_single_threaded',
  'web_extensions_single_threaded',
  'files',
];

final _webPrefix = RegExp(r'^(web|javascript|html5)[_./-]');
final _webExtensions = RegExp(r'(?:^|_)(dlink|extensions)(?:_|\.)');
final _architecture = RegExp(r'(?:^|[_./-])(x86_64|x86_32|arm64|arm32|aarch64|armv7|amd64|x64|x32)(?=[_./-]|$)');
final _bitness = RegExp(r'(?:windows|win|x11)[_.-]?(32|64)(?=[_./-]|$)');

List<TemplateFileGroup> groupTemplateFiles(List<TemplateFile> files) {
  final groups = <String, (String?, String?, List<TemplateFile>)>{};
  for (final file in files) {
    final name = file.name.toLowerCase();
    if (_webPrefix.hasMatch(name)) {
      final extensions = _webExtensions.hasMatch(name);
      final singleThreaded = name.contains('nothreads');
      final id = 'web_${extensions ? 'extensions' : 'standard'}${singleThreaded ? '_single_threaded' : ''}'
          .replaceFirst('standard_single_threaded', 'single_threaded');
      final web = _webGroups[id];
      final group = groups[id] ?? (web?.$1, web?.$2, <TemplateFile>[]);
      group.$3.add(file);
      groups[id] = group;
      continue;
    }
    final architecture = _architecture.firstMatch(name)?[1] ?? _bitness.firstMatch(name)?[1];
    final label = architecture != null ? _architectureLabels[architecture] : null;
    final id = label ?? 'files';
    final group = groups[id] ?? (label, null, <TemplateFile>[]);
    group.$3.add(file);
    groups[id] = group;
  }
  final result = [
    for (final MapEntry(key: id, value: (label, labelKey, files)) in groups.entries)
      TemplateFileGroup(id: id, label: label, labelKey: labelKey, files: files),
  ];
  result.sort((a, b) => _groupOrder.indexOf(a.id) - _groupOrder.indexOf(b.id));
  return result;
}

const _optionCategories = [
  ('desktop', 'export_templates_category_desktop', ['windows', 'linux', 'macos', 'uwp', 'server']),
  ('mobile', 'export_templates_category_mobile', ['android', 'ios', 'visionos', 'tvos']),
  ('web', 'export_templates_category_web', ['web']),
  ('common', 'export_templates_category_common', ['icu']),
];

List<TemplateOptionCategory> groupTemplateOptions(List<TemplateOption> options) {
  final known = {for (final (_, _, platforms) in _optionCategories) ...platforms};
  final categories = [
    for (final (id, labelKey, platforms) in _optionCategories)
      TemplateOptionCategory(
        id: id,
        labelKey: labelKey,
        options: [
          for (final platform in platforms) ...options.where((option) => option.id == platform),
        ],
      ),
  ];
  final other = options.where((option) => !known.contains(option.id)).toList();
  if (other.isNotEmpty) {
    categories.add(TemplateOptionCategory(id: 'other', labelKey: 'export_templates_category_other', options: other));
  }
  return categories.where((category) => category.options.isNotEmpty).toList();
}

List<String> toggleTemplateFiles(List<String> selected, List<TemplateFile> files, bool checked) {
  final names = {for (final file in files) if (!file.installed) file.name};
  return checked ? {...selected, ...names}.toList() : selected.where((name) => !names.contains(name)).toList();
}
