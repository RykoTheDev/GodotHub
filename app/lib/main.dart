import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/events.dart';
import 'api/updater.dart';
import 'debug/gallery/widget_gallery.dart';
import 'design/design.dart';
import 'i18n/i18n.dart';
import 'i18n/i18n_controller.dart';
import 'modals/bug_report_modal.dart';
import 'motion/motion.dart';
import 'motion/reveal.dart';
import 'src/app_theme.dart';
import 'src/channel.dart';
import 'shell/app_shell.dart';
import 'src/providers.dart';
import 'src/rust/api/app.dart' as core;
import 'src/rust/api/settings.dart' as settings;
import 'src/rust/api/types.dart';
import 'src/rust/frb_generated.dart';
import 'src/ui_prefs.dart';
import 'state/keyboard_shortcuts.dart';
import 'state/onboarding.dart';
import 'ui/core/ui_settings.dart';
import 'ui/feedback/error_boundary.dart';
import 'window/app_window.dart';
import 'window/tray.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = ghErrorWidget;
  installBugReportErrorCapture();
  await RustLib.init();
  UpdaterApi.applyBuildVersion();
  if (const bool.fromEnvironment('UPDATER_LAB_CRASH')) exit(70);
  AppEvents.all.listen((_) {});
  final title = await core.startCore(channel: buildChannel);
  final current = await settings.getSettings();
  await UiPrefsStore.instance.load();
  await GhI18n.init(settingsLanguage: current.language, settingsRtlLayout: current.rtlLayout);
  warmUpFonts(languageCode: GhI18n.instance.locale.flutterLocale.languageCode);
  final window = await AppWindow.start(title: title, useOsDecorations: current.useOsDecorations);
  final tray = await TrayController.start(tooltip: title).catchError((Object _) => null);
  tray?.minimizeToTray = current.minimizeToTray;
  runApp(
    ProviderScope(
      child: TranslationProvider(
        child: GodotHubApp(title: title, initialSettings: current),
      ),
    ),
  );
  unawaited(window.openLaunchArgs());
  WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(UpdaterApi.confirmLaunch()));
}

class GodotHubApp extends ConsumerStatefulWidget {
  const GodotHubApp({super.key, required this.title, required this.initialSettings});

  final String title;
  final AppSettings initialSettings;

  @override
  ConsumerState<GodotHubApp> createState() => _GodotHubAppState();
}

class _GodotHubAppState extends ConsumerState<GodotHubApp> with WidgetsBindingObserver {
  Brightness _platformBrightness = PlatformDispatcher.instance.platformBrightness;
  bool _gallery = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    final current = ref.read(settingsProvider).value ?? widget.initialSettings;
    GhI18n.instance.setLanguageSetting(current.language, systemLocales: locales);
  }

  @override
  void didChangePlatformBrightness() {
    setState(() => _platformBrightness = PlatformDispatcher.instance.platformBrightness);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsProvider, (previous, next) {
      final value = next.value;
      if (value == null) return;
      GhI18n.instance.setLanguageSetting(value.language);
      GhI18n.instance.setRtlLayout(value.rtlLayout);
    });
    final current = ref.watch(themePreviewProvider) ?? ref.watch(settingsProvider).value ?? widget.initialSettings;
    final theme = ghThemeFromSettings(current, _platformBrightness);
    final i18n = GhI18n.instance;
    return ListenableBuilder(
      listenable: i18n,
      builder: (context, _) => GhUiSettings(
        data: ghUiSettingsFrom(current),
        child: MaterialApp(
          title: widget.title,
          debugShowCheckedModeBanner: false,
          locale: i18n.locale.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: theme.toThemeData(),
          themeAnimationDuration: GhDurations.color,
          themeAnimationCurve: GhCurves.outExpo,
          builder: (context, child) => Directionality(
            textDirection: i18n.layoutDirection,
            child: GhMotion(
              prefs: ghMotionPrefsFrom(current),
              child: GhKeyboardShortcuts(child: child!),
            ),
          ),
          home: Scaffold(
            body: _gallery
                ? GhRevealScope(child: WidgetGallery(onClose: () => setState(() => _gallery = false)))
                : AppShell(title: widget.title, onOpenGallery: kDebugMode ? () => setState(() => _gallery = true) : null),
          ),
        ),
      ),
    );
  }
}
