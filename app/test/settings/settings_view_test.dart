import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/design/design.dart';
import 'package:godothub/logic/debug_mode.dart';
import 'package:godothub/logic/settings_category_nav.dart';
import 'package:godothub/logic/settings_copy.dart';
import 'package:godothub/settings/categories/appearance_settings.dart';
import 'package:godothub/settings/categories/display_settings.dart';
import 'package:godothub/settings/settings_parts.dart';
import 'package:godothub/settings/settings_view.dart';
import 'package:godothub/src/rust/api/types.dart';
import 'package:godothub/src/ui_prefs.dart';
import 'package:godothub/state/app_signals.dart';
import 'package:godothub/state/app_version.dart';
import 'package:godothub/state/contributors.dart';
import 'package:godothub/state/shell_signals.dart';
import 'package:godothub/ui/controls/toggle.dart';
import 'package:godothub/ui/core/i18n.dart';
import 'package:godothub/ui/feedback/toast_host.dart';

import '../projects/project_actions_test.dart' as base;
import '../support/fake_rust.dart';
import '../support/settings_fakes.dart';
import '../titlebar_test.dart' show baseSettings;
import '../ui/i18n_setup.dart';

late FakeRustApi rust;

String ts(String key, {num? count, Map<String, Object?> args = const {}}) => ghTr('settings:$key', count: count, args: args);

class Host {
  final saved = <AppSettings>[];
  AppSettings get last => saved.last;
}

Future<Host> pumpSettings(WidgetTester tester, {AppSettings? settings, Widget? body}) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final host = Host();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        fakeSettings(
          () => settings ?? copySettings(baseSettings, setupComplete: true),
          onSave: (next) {
            host.saved.add(next);
            return next;
          },
        ),
        appVersionLoaderProvider.overrideWithValue(() async => '2.0.0'),
        contributorsFetcherProvider.overrideWithValue(() async => const <Contributor>[]),
      ],
      child: MaterialApp(
        theme: GhTheme.defaults().toThemeData(),
        home: Scaffold(body: GhToastHost(child: body ?? const SettingsView())),
      ),
    ),
  );
  await base.settle(tester, 4);
  return host;
}

Finder railItem(String id) => find.byKey(ValueKey('settings-rail:$id'));

void main() {
  setUpAll(() async {
    await base.loadFont('Inter', ['assets/fonts/inter-latin.ttf']);
    await base.loadFont('GoogleSansCode', ['assets/fonts/gsc-latin-400.ttf', 'assets/fonts/gsc-latin-500.ttf']);
  });
  setUp(setUpTestI18n);
  setUp(() {
    rust = installFakeRust();
    UiPrefsStore.instance = UiPrefsStore(MemoryUiPrefsBackend());
    debugResetDebugMode();
    consumePendingSettingsCategory();
  });

  test('theme helpers follow React: mode swaps the background only when its darkness mismatches', () {
    final dark = copySettings(baseSettings, themeMode: 'dark', backgroundColor: '#101010');
    expect(withThemeMode(dark, 'light').backgroundColor, defaultBackgroundLight);
    expect(withThemeMode(dark, 'dark').backgroundColor, '#101010');
    final custom = withCustomTheme(copySettings(dark, accentColor: '#ff0000', themePreset: 'nord'));
    expect(custom.themePreset, 'custom');
    expect(custom.accentColor, defaultAccent);
    expect(withPreset(custom, 'custom'), isNull);
    final preset = darkThemePresets.first;
    expect(withPreset(custom, preset.id)!.themeMode, 'dark');
    final reset = withAppearanceReset(copySettings(dark, cornerRadius: 3, customCss: 'x', animationIntensity: 'none'));
    expect(reset.cornerRadius, defaultCornerRadius);
    expect(reset.customCss, '');
    expect(reset.animationIntensity, 'full');
    expect(reset.themePreset, 'custom');
  });

  testWidgets('shows the rail, switches categories by click and arrows, and opens credits from the version chip', (tester) async {
    await pumpSettings(tester);
    for (final (id, _) in settingsCategories) {
      expect(railItem(id), findsOneWidget);
    }
    expect(railItem('debug'), findsNothing);
    expect(find.text(ts('appearance').toUpperCase()), findsOneWidget);
    expect(find.text(ts('theme_preset_label')), findsOneWidget);

    await tester.tap(railItem('motion'));
    await base.settle(tester, 3);
    expect(find.text(ts('motion').toUpperCase()), findsOneWidget);
    expect(find.text(ts('animation_intensity_label')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await base.settle(tester, 3);
    expect(find.text(ts('display').toUpperCase()), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await base.settle(tester, 3);
    expect(find.text(ts('appearance').toUpperCase()), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await base.settle(tester, 3);
    expect(find.text(ts('experimental').toUpperCase()), findsOneWidget);

    await tester.tap(find.text(ts('app_version_label', args: {'version': '2.0.0'})));
    await base.settle(tester, 3);
    expect(find.text(ts('credits').toUpperCase()), findsOneWidget);
  });

  testWidgets('search hides unmatched sections, shows the empty state and clears', (tester) async {
    await pumpSettings(tester);
    await tester.enterText(find.byType(TextField).first, ts('project_icon_opacity_label'));
    await base.settle(tester, 3);
    expect(find.descendant(of: find.byType(SettingsSubsection), matching: find.text(ts('project_icon_opacity_label'))), findsOneWidget);
    expect(find.text(ts('theme_preset_label')), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'zzzz-nothing');
    await base.settle(tester, 3);
    expect(find.text(ts('no_settings_match')), findsOneWidget);
    await tester.tap(find.text(ts('clear')));
    await base.settle(tester, 3);
    expect(find.text(ts('no_settings_match')), findsNothing);
    expect(find.text(ts('theme_preset_label')), findsOneWidget);
  });

  testWidgets('opens the pending category, follows the open-category signal and shows Debug once unlocked', (tester) async {
    setPendingSettingsCategory('accessibility');
    await pumpSettings(tester);
    expect(find.text(ts('accessibility').toUpperCase()), findsOneWidget);
    expect(find.text(ts('ui_density_label')), findsOneWidget);

    AppSignals.emit(openSettingsCategorySignal, 'display');
    await base.settle(tester, 3);
    expect(find.text(ts('display').toUpperCase()), findsOneWidget);

    setDebugUnlocked(true);
    await base.settle(tester, 3);
    expect(railItem('debug'), findsOneWidget);
    expect(find.descendant(of: railItem('debug'), matching: find.text('Debug')), findsOneWidget);
    await tester.tap(railItem('debug'));
    await base.settle(tester, 3);
    expect(find.text('DEBUG'), findsOneWidget);
    setDebugUnlocked(false);
    await base.settle(tester, 3);
    expect(railItem('debug'), findsNothing);
    expect(find.text(ts('appearance').toUpperCase()), findsOneWidget);
  });

  testWidgets('appearance saves custom theme, mode, sliders, css and reset', (tester) async {
    final host = await pumpSettings(
      tester,
      settings: copySettings(baseSettings, setupComplete: true, themePreset: darkThemePresets.first.id),
      body: const SingleChildScrollView(child: AppearanceSettings()),
    );
    expect(find.text(ts('setting_accent_color')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('preset-custom')));
    await base.settle(tester, 3);
    expect(host.last.themePreset, 'custom');
    expect(find.text(ts('setting_accent_color')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('segment:light')));
    await base.settle(tester, 3);
    expect(host.last.themeMode, 'light');
    expect(host.last.backgroundColor, defaultBackgroundLight);

    await tester.tap(find.byKey(const ValueKey('preset-group:dark')));
    await base.settle(tester);
    expect(find.text(ts('preset_dark_group').toUpperCase()), findsOneWidget);
    await tester.tap(find.text(darkThemePresets[1].name).last);
    await base.settle(tester, 3);
    expect(host.last.themePreset, darkThemePresets[1].id);
    expect(host.last.themeMode, 'dark');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await base.settle(tester);

    expect(find.text(ts('custom_css_label')), findsNothing);

    await tester.tap(find.text(ts('reset_appearance')));
    await base.settle(tester, 3);
    expect(host.last.themePreset, 'custom');
    expect(host.last.themeMode, 'dark');
    expect(host.last.cornerRadius, defaultCornerRadius);
  });

  testWidgets('motion disables effect toggles when animations are off and saves segments', (tester) async {
    final host = await pumpSettings(tester);
    await tester.tap(railItem('motion'));
    await base.settle(tester, 3);
    final ripple = find.byWidgetPredicate((w) => w is GhToggle && w.label == ts('click_ripple_label'));
    expect(tester.widget<GhToggle>(ripple).disabled, isFalse);
    await tester.tap(find.byKey(const ValueKey('segment:none')).first);
    await base.settle(tester, 3);
    expect(host.last.animationIntensity, 'none');
    expect(tester.widget<GhToggle>(ripple).disabled, isTrue);
    await tester.tap(find.byKey(const ValueKey('segment:scale')));
    await base.settle(tester, 3);
    expect(host.last.viewEntrance, 'scale');
    expect(find.text(ts('n_projects', count: baseSettings.animationThreshold)), findsOneWidget);
  });

  testWidgets('display saves formats and toggles, and asks before switching OS decorations', (tester) async {
    final host = await pumpSettings(tester, body: const SingleChildScrollView(child: DisplaySettings(mac: false)));
    await tester.tap(find.byKey(const ValueKey('segment:24h')));
    await base.settle(tester, 3);
    expect(host.last.lastOpenedTimeFormat, '24h');
    await tester.tap(find.byKey(const ValueKey('segment:YYYY-MM-DD')));
    await base.settle(tester, 3);
    expect(host.last.lastOpenedDateFormat, 'YYYY-MM-DD');
    final star = find.byWidgetPredicate((w) => w is GhToggle && w.label == ts('show_star_label'));
    await tester.tap(star);
    await base.settle(tester, 3);
    expect(host.last.showStarButton, !baseSettings.showStarButton);

    final count = host.saved.length;
    await tester.tap(find.byWidgetPredicate((w) => w is GhToggle && w.label == ts('use_os_decorations')));
    await base.settle(tester);
    expect(find.text(ghTr('restart_required_title').toUpperCase()), findsOneWidget);
    await tester.tap(find.text(ghTr('cancel')));
    await base.settle(tester);
    expect(host.saved.length, count);

    await tester.tap(find.byWidgetPredicate((w) => w is GhToggle && w.label == ts('use_os_decorations')));
    await base.settle(tester);
    await tester.tap(find.text(ghTr('restart_now')));
    await base.settle(tester);
    expect(host.last.useOsDecorations, !baseSettings.useOsDecorations);
    await base.drainToasts(tester);
  });

  testWidgets('display hides the window chrome rows on macOS', (tester) async {
    await pumpSettings(tester, body: const SingleChildScrollView(child: DisplaySettings(mac: true)));
    expect(find.text(ts('use_os_decorations')), findsNothing);
    expect(find.text(ts('colored_titlebar_buttons_label')), findsNothing);
  });

  testWidgets('accessibility saves toggles and shows slider values', (tester) async {
    final host = await pumpSettings(tester);
    await tester.tap(railItem('accessibility'));
    await base.settle(tester, 3);
    expect(find.text('105%'), findsOneWidget);
    expect(find.text('${baseSettings.tooltipDelay}ms'), findsOneWidget);
    await tester.tap(find.byWidgetPredicate((w) => w is GhToggle && w.label == ts('screen_reader_label')));
    await base.settle(tester, 3);
    expect(host.last.screenReaderAnnouncements, !baseSettings.screenReaderAnnouncements);
    await tester.tap(find.byWidgetPredicate((w) => w is GhToggle && w.label == ts('fixed_sidebar_resize_knob_label')));
    await base.settle(tester, 3);
    expect(host.last.fixedSidebarResizeKnob, !baseSettings.fixedSidebarResizeKnob);
  });

  testWidgets('setting rows and inline subsections render their label, line and control', (tester) async {
    await pumpSettings(
      tester,
      body: const Column(
        children: [
          SettingsSubsection(id: 'a', title: 'Alpha', inline: true, child: Text('control')),
          SettingRow(label: 'Beta', divider: true, child: Text('value')),
        ],
      ),
    );
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.byType(SettingsDividerLine), findsNWidgets(2));
  });
}
