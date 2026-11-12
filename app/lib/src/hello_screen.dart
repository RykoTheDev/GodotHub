import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'rust/api/types.dart';

class HelloScreen extends ConsumerWidget {
  const HelloScreen({super.key, required this.title, this.onOpenGallery});

  final String title;
  final VoidCallback? onOpenGallery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final cliStatus = ref.watch(cliToolStatusProvider);
    final actions = ref.read(cliToolActionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('$title: Hello from core'),
        actions: [if (onOpenGallery != null) TextButton(onPressed: onOpenGallery, child: const Text('Widget gallery'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _Section(
            title: 'get_settings',
            onRefresh: () => ref.invalidate(settingsProvider),
            child: _AsyncRows<AppSettings>(value: settings, rows: _settingsRows),
          ),
          const SizedBox(height: 24),
          _Section(
            title: 'Command line tool',
            onRefresh: () => ref.invalidate(cliToolStatusProvider),
            actions: [
              FilledButton(onPressed: () => _run(context, actions.install), child: const Text('Install command')),
              OutlinedButton(onPressed: () => _run(context, actions.uninstall), child: const Text('Uninstall command')),
            ],
            child: _AsyncRows<CliToolStatus>(value: cliStatus, rows: _cliRows),
          ),
        ],
      ),
    );
  }

  static Map<String, String> _settingsRows(AppSettings settings) => {
    'language': settings.language,
    'theme_mode': settings.themeMode,
    'accent_color': settings.accentColor,
    'download_dir': settings.downloadDir ?? '(default)',
    'project_scan_dirs': settings.projectScanDirs.join(', '),
    'setup_complete': '${settings.setupComplete}',
  };

  static Map<String, String> _cliRows(CliToolStatus status) => {
    'installed': '${status.installed}',
    'on_path': '${status.onPath}',
    'shim_path': status.shimPath,
    'platform': status.platform,
  };

  Future<void> _run(BuildContext context, Future<void> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.onRefresh, required this.child, this.actions = const []});

  final String title;
  final VoidCallback onRefresh;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
            IconButton(tooltip: 'Refresh', onPressed: onRefresh, icon: const Icon(Icons.refresh)),
          ],
        ),
        if (actions.isNotEmpty) Wrap(spacing: 12, children: actions),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _AsyncRows<T> extends StatelessWidget {
  const _AsyncRows({required this.value, required this.rows});

  final AsyncValue<T> value;
  final Map<String, String> Function(T data) rows;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in rows(data).entries)
            SelectableText('${entry.key}: ${entry.value}', style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
        ],
      ),
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text('$error', style: TextStyle(color: Theme.of(context).colorScheme.error)),
    );
  }
}
