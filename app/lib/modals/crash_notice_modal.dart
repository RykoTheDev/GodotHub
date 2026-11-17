import 'package:material_ui/material_ui.dart';

import '../design/design.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/feedback/modal_shell.dart';

class CrashNoticeModal extends StatelessWidget {
  const CrashNoticeModal({super.key, required this.version, required this.onClose, required this.onReport, this.rolledBackTo});

  final String version;
  final String? rolledBackTo;
  final VoidCallback onClose;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final textStyle = theme.text(size: GhTextSize.sm, color: theme.muted, lineHeight: 1.625);
    final previous = rolledBackTo;
    return GhModalShell(
      icon: GhIcon(GhIcons.alertTriangle, size: theme.space(5), color: theme.danger),
      title: ghTr('crash_notice_title'),
      maxWidth: GhModalWidth.md,
      onClose: onClose,
      footer: [
        GhButton(onPressed: onClose, label: ghTr('dismiss'), variant: GhButtonVariant.ghost),
        const Spacer(),
        GhButton(onPressed: onReport, label: ghTr('report_a_bug'), variant: GhButtonVariant.primary),
      ],
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), 0, theme.space(6), theme.space(4)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: theme.space(3),
          children: [
            Text(ghTr('crash_notice_desc', args: {'version': version}), style: textStyle),
            if (previous != null) Text(ghTr('crash_notice_rolled_back', args: {'previous': previous}), style: textStyle),
            Text(ghTr('crash_notice_log'), style: textStyle),
          ],
        ),
      ),
    );
  }
}
