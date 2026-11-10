import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/export_template_selection.dart';

import '../ui/i18n_setup.dart';
import 'logic_fixtures.dart';

void main() {
  test('groupTemplateFiles matches the TypeScript grouping and order', () {
    const names = [
      'windows_debug_x86_64.exe',
      'windows_release_x86_32.exe',
      'linux_debug.arm64',
      'linux_release.x86_64',
      'web_debug.zip',
      'web_nothreads_release.zip',
      'web_dlink_debug.zip',
      'web_dlink_nothreads_release.zip',
      'javascript_release.zip',
      'html5-debug.zip',
      'android_debug.apk',
      'windows_64_debug.exe',
      'win32_release.exe',
      'x11_64_debug',
      'version.txt',
      'linux_release.armv7',
      'macos.zip',
      'webmanifest.json',
      'linux_x86_64_amd64x.bin',
    ];
    final groups = groupTemplateFiles([for (final n in names) templateFile(n)]);
    expect([for (final g in groups) [g.id, g.label, g.labelKey, g.files.map((f) => f.name).toList()]], [
      ['x86 (32-bit)', 'x86 (32-bit)', null, ['windows_release_x86_32.exe', 'win32_release.exe']],
      [
        'x86_64 (64-bit)',
        'x86_64 (64-bit)',
        null,
        ['windows_debug_x86_64.exe', 'linux_release.x86_64', 'windows_64_debug.exe', 'x11_64_debug', 'linux_x86_64_amd64x.bin'],
      ],
      ['ARM32', 'ARM32', null, ['linux_release.armv7']],
      ['ARM64', 'ARM64', null, ['linux_debug.arm64']],
      ['web_standard', 'Web', 'export_templates_web_standard', ['web_debug.zip', 'javascript_release.zip', 'html5-debug.zip']],
      ['web_extensions', 'Web with Extensions', 'export_templates_web_extensions', ['web_dlink_debug.zip']],
      ['web_single_threaded', 'Web Single-Threaded', 'export_templates_web_single_threaded', ['web_nothreads_release.zip']],
      [
        'web_extensions_single_threaded',
        'Web with Extensions Single-Threaded',
        'export_templates_web_extensions_single_threaded',
        ['web_dlink_nothreads_release.zip'],
      ],
      ['files', null, null, ['android_debug.apk', 'version.txt', 'macos.zip', 'webmanifest.json']],
    ]);
    expect(groupTemplateFiles([]), isEmpty);
  });

  test('group labels translate web groups and fall back to the raw label', () async {
    await setUpTestI18n();
    final groups = groupTemplateFiles([templateFile('web_dlink_debug.zip'), templateFile('a_x64.zip'), templateFile('readme')]);
    expect([for (final g in groups) g.displayLabel()], ['x86_64 (64-bit)', 'Web with Extensions', null]);
  });

  test('groupTemplateOptions buckets by platform order and collects others', () async {
    await setUpTestI18n();
    final categories = groupTemplateOptions([
      for (final id in ['web', 'zzz', 'android', 'windows', 'icu', 'linux', 'aaa', 'macos']) templateOption(id, []),
    ]);
    expect([for (final c in categories) [c.id, c.labelKey, c.options.map((o) => o.id).toList()]], [
      ['desktop', 'export_templates_category_desktop', ['windows', 'linux', 'macos']],
      ['mobile', 'export_templates_category_mobile', ['android']],
      ['web', 'export_templates_category_web', ['web']],
      ['common', 'export_templates_category_common', ['icu']],
      ['other', 'export_templates_category_other', ['zzz', 'aaa']],
    ]);
    expect(categories.first.label(), 'Desktop');
    expect(categories.last.label(), 'Other');
    expect(groupTemplateOptions([templateOption('ios', [])]).map((c) => c.id), ['mobile']);
  });

  test('toggleTemplateFiles adds missing uninstalled names without duplicates and removes them', () {
    final files = [templateFile('c'), templateFile('b'), templateFile('d', installed: true), templateFile('c')];
    expect(toggleTemplateFiles(['a', 'b', 'a'], files, true), ['a', 'b', 'c']);
    expect(toggleTemplateFiles(['a', 'b', 'd', 'c'], [templateFile('c'), templateFile('d', installed: true)], false), [
      'a',
      'b',
      'd',
    ]);
  });
}
