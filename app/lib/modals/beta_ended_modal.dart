import 'dart:io';

import 'package:flutter/material.dart';

import '../api/opener.dart';
import '../design/design.dart';
import '../ui/core/button.dart';
import '../ui/feedback/confirm_dialog.dart';
import '../ui/feedback/modal_shell.dart';
import '../window/app_window.dart';

const stableReleaseUrl = 'https://github.com/RykoTheDev/GodotHub/releases/latest';

String? betaUninstallerPath([String? executable]) {
  if (!Platform.isWindows) return null;
  final exe = File(executable ?? Platform.resolvedExecutable);
  final appDir = exe.parent;
  final root = RegExp(r'^app-').hasMatch(appDir.uri.pathSegments.where((s) => s.isNotEmpty).last) ? appDir.parent : appDir;
  final uninstaller = File('${root.path}${Platform.pathSeparator}uninstall.exe');
  return uninstaller.existsSync() ? uninstaller.path : null;
}

class BetaEndedModal extends StatelessWidget {
  const BetaEndedModal({
    super.key,
    required this.version,
    required this.onClose,
    this.uninstallerPath,
    this.openUrl = OpenerApi.openUrl,
    this.runUninstaller = _startUninstaller,
  });

  final String version;
  final VoidCallback onClose;
  final String? uninstallerPath;
  final Future<void> Function(String url) openUrl;
  final Future<void> Function(String path) runUninstaller;

  static Future<void> _startUninstaller(String path) async {
    await Process.start(path, const [], mode: ProcessStartMode.detached);
    await AppWindow.instance.quit();
  }

  Future<void> _confirmUninstall(BuildContext context, String path) async {
    final confirmed = await showGhConfirmDialog(
      context,
      title: 'Uninstall GodotHub Beta?',
      description: 'GodotHub Beta closes and its uninstaller starts. The beta data folder stays until you delete it.',
      confirmLabel: 'Uninstall',
      variant: GhConfirmVariant.danger,
    );
    if (confirmed) await runUninstaller(path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final textStyle = theme.text(size: GhTextSize.sm, color: theme.muted, lineHeight: 1.625);
    final uninstaller = uninstallerPath;
    return GhModalShell(
      icon: GhIcon(GhIcons.rocket, size: theme.space(5), color: theme.accentBright),
      title: 'GodotHub Beta has ended',
      maxWidth: GhModalWidth.md,
      onClose: onClose,
      footer: ghModalActions(
        leading: [GhButton(onPressed: onClose, label: 'Later', variant: GhButtonVariant.ghost)],
        trailing: [
          if (uninstaller != null)
            GhButton(
              key: const ValueKey('beta-uninstall'),
              onPressed: () => _confirmUninstall(context, uninstaller),
              label: 'Uninstall Beta',
              variant: GhButtonVariant.outline,
            ),
        ],
        primary: GhButton(onPressed: () => openUrl(stableReleaseUrl), label: 'Get GodotHub', variant: GhButtonVariant.primary),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), 0, theme.space(6), theme.space(4)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: theme.space(3),
          children: [
            Text(
              'GodotHub $version is out. The app you have been testing is now the regular GodotHub, so the beta will not get any more updates.',
              style: textStyle,
            ),
            Text(
              "Your beta projects and settings stay in the beta's own folder. GodotHub keeps using its existing data.",
              style: textStyle,
            ),
            if (uninstaller == null) Text('When you have moved over, remove GodotHub Beta like any other app.', style: textStyle),
          ],
        ),
      ),
    );
  }
}
