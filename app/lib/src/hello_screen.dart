import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

class HelloScreen extends ConsumerWidget {
  const HelloScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsJsonProvider);
    final cliStatus = ref.watch(cliToolStatusProvider);
    final actions = ref.read(cliToolActionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('$title: Hello from core')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _Section(
            title: 'get_settings',
            onRefresh: () => ref.invalidate(settingsJsonProvider),
            child: _JsonView(value: settings),
          ),
          const SizedBox(height: 24),
          _Section(
            title: 'Command line tool',
            onRefresh: () => ref.invalidate(cliToolStatusProvider),
            actions: [
              FilledButton(
                onPressed: () => _run(context, actions.install),
                child: const Text('Install command'),
              ),
              OutlinedButton(
                onPressed: () => _run(context, actions.uninstall),
                child: const Text('Uninstall command'),
              ),
            ],
            child: _JsonView(value: cliStatus),
          ),
        ],
      ),
    );
  }

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
  const _Section({
    required this.title,
    required this.onRefresh,
    required this.child,
    this.actions = const [],
  });

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
            IconButton(
              tooltip: 'Refresh',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        if (actions.isNotEmpty) Wrap(spacing: 12, children: actions),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _JsonView extends StatelessWidget {
  const _JsonView({required this.value});

  final AsyncValue<String> value;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (json) => SelectableText(
        json,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text(
        '$error',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
