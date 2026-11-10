import 'dart:io';

import 'package:flutter/material.dart';

import 'debug/gallery/widget_gallery.dart';
import 'design/design.dart';
import 'i18n/i18n.dart';
import 'i18n/i18n_controller.dart';
import 'src/ui_prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  UiPrefsStore.instance = UiPrefsStore(MemoryUiPrefsBackend());
  await GhI18n.init(settingsLanguage: Platform.environment['GH_GALLERY_LANGUAGE'] ?? 'en-US', settingsRtlLayout: false);
  runApp(TranslationProvider(child: const GalleryApp()));
}

class GalleryApp extends StatelessWidget {
  const GalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GodotHub widget gallery',
      debugShowCheckedModeBanner: false,
      theme: GhTheme.defaults().toThemeData(),
      home: Scaffold(body: WidgetGallery(initialSection: Platform.environment['GH_GALLERY_SECTION'])),
    );
  }
}
