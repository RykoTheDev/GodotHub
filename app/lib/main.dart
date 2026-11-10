import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/events.dart';
import 'debug/gallery/widget_gallery.dart';
import 'design/design.dart';
import 'src/app_theme.dart';
import 'src/channel.dart';
import 'src/hello_screen.dart';
import 'src/providers.dart';
import 'src/rust/api/app.dart' as core;
import 'src/rust/api/settings.dart' as settings;
import 'src/rust/api/types.dart';
import 'src/rust/frb_generated.dart';
import 'titlebar/title_bar.dart';
import 'ui/core/ui_settings.dart';
import 'window/app_window.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  AppEvents.all.listen((_) {});
  final title = await core.startCore(channel: buildChannel);
  final current = await settings.getSettings();
  final window = await AppWindow.start(title: title, useOsDecorations: current.useOsDecorations);
  runApp(ProviderScope(child: GodotHubApp(title: title, initialSettings: current)));
  unawaited(window.openLaunchArgs());
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
  void didChangePlatformBrightness() {
    setState(() => _platformBrightness = PlatformDispatcher.instance.platformBrightness);
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(settingsProvider).value ?? widget.initialSettings;
    final theme = ghThemeFromSettings(current, _platformBrightness);
    return GhUiSettings(
      data: ghUiSettingsFrom(current),
      child: MaterialApp(
        title: widget.title,
        debugShowCheckedModeBanner: false,
        theme: theme.toThemeData(),
        themeAnimationDuration: GhDurations.color,
        themeAnimationCurve: GhCurves.outExpo,
        home: Scaffold(
          body: Column(
            children: [
              TitleBar(isMac: Platform.isMacOS),
              Expanded(
                child: _gallery
                    ? WidgetGallery(onClose: () => setState(() => _gallery = false))
                    : HelloScreen(
                        title: widget.title,
                        onOpenGallery: kDebugMode ? () => setState(() => _gallery = true) : null,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
