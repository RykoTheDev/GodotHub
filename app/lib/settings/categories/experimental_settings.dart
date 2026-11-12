import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/design.dart';
import '../../logic/settings_copy.dart';
import '../../src/rust/api/types.dart';
import '../../state/settings.dart';
import '../../ui/controls/toggle.dart';
import '../../ui/core/i18n.dart';
import '../settings_parts.dart';

String _ts(String key) => ghTr('settings:$key');

class ExperimentalSettings extends ConsumerWidget {
  const ExperimentalSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = GhTheme.of(context);
    final settings = ref.watch(settingsProvider).value;
    if (settings == null) return const SizedBox.shrink();
    void save(AppSettings next) => ref.read(settingsProvider.notifier).save(next).ignore();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(3),
      children: [
        Container(
          padding: EdgeInsets.all(theme.space(5)),
          decoration: BoxDecoration(color: theme.overlay, borderRadius: BorderRadius.circular(theme.radiusItem)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.space(5),
            children: [
              SettingRow(
                label: _ts('customize_view_label'),
                child: GhToggle(
                  checked: settings.customizeViewEnabled,
                  label: _ts('customize_view_label'),
                  onChanged: (checked) => save(copySettings(settings, customizeViewEnabled: checked)),
                ),
              ),
              SettingRow(
                label: _ts('project_todos_label'),
                child: GhToggle(
                  checked: settings.projectTodosEnabled,
                  label: _ts('project_todos_label'),
                  onChanged: (checked) => save(copySettings(settings, projectTodosEnabled: checked)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
