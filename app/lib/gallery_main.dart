import 'dart:io';

import 'package:flutter/material.dart';

import 'debug/gallery/widget_gallery.dart';
import 'design/design.dart';

void main() {
  runApp(const GalleryApp());
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
