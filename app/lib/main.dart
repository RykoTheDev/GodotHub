import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/channel.dart';
import 'src/hello_screen.dart';
import 'src/rust/api/core.dart' as core;
import 'src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  final title = core.startCore(channel: buildChannel);
  runApp(ProviderScope(child: GodotHubApp(title: title)));
}

class GodotHubApp extends StatelessWidget {
  const GodotHubApp({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF478CBF), useMaterial3: true),
      home: HelloScreen(title: title),
    );
  }
}
