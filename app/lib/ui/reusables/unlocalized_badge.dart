import 'package:flutter/widgets.dart';

import '../../design/design.dart';
import '../core/i18n.dart';

bool ghIsUnlocalized(Translations current, List<(String, String)> checks) {
  if (current.$meta.locale.languageCode.toLowerCase().startsWith('en')) return false;
  final english = AppLocale.enUs.translations;
  return checks.every((check) {
    final key = '${check.$1}:${check.$2}';
    final en = ghTr(key, translations: english);
    return en.isNotEmpty && en == ghTr(key, translations: current);
  });
}

class GhUnlocalizedBadge extends StatelessWidget {
  const GhUnlocalizedBadge({super.key, required this.checks});

  final List<(String, String)> checks;

  static Widget? maybe(BuildContext context, List<(String, String)> checks) =>
      ghIsUnlocalized(context.tr, checks) ? GhUnlocalizedBadge(checks: checks) : null;

  @override
  Widget build(BuildContext context) {
    if (!ghIsUnlocalized(context.tr, checks)) return const SizedBox.shrink();
    final theme = GhTheme.of(context);
    return Container(
      key: const ValueKey('unlocalized-badge'),
      height: theme.space(5),
      padding: EdgeInsets.symmetric(horizontal: theme.space(2)),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(theme.radiusTag),
        border: Border.all(color: theme.amber.withValues(alpha: 0.4)),
      ),
      child: Text(
        'UNLOCALIZED',
        style: theme.text(size: GhTextSize.x3s, weight: GhWeight.semibold, color: theme.amber, letterSpacingEm: 0.025),
      ),
    );
  }
}
