import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../core/button.dart';
import 'modal_shell.dart';
import '../core/i18n.dart';

enum GhConfirmVariant { normal, danger }

class GhConfirmDialog extends StatefulWidget {
  const GhConfirmDialog({
    super.key,
    required this.title,
    this.description,
    this.descriptionContent,
    required this.confirmLabel,
    this.cancelLabel,
    this.variant = GhConfirmVariant.normal,
    required this.onConfirm,
    required this.onCancel,
    this.isMenuOpen,
    this.staticPreview = false,
  });

  final String title;
  final String? description;
  final Widget? descriptionContent;
  final String confirmLabel;
  final String? cancelLabel;
  final GhConfirmVariant variant;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool Function()? isMenuOpen;
  final bool staticPreview;

  @override
  State<GhConfirmDialog> createState() => _GhConfirmDialogState();
}

class _GhConfirmDialogState extends State<GhConfirmDialog> {
  final FocusNode _cancelNode = FocusNode(debugLabel: 'GhConfirmDialog cancel');
  final FocusNode _confirmNode = FocusNode(debugLabel: 'GhConfirmDialog confirm');

  @override
  void dispose() {
    _cancelNode.dispose();
    _confirmNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final danger = widget.variant == GhConfirmVariant.danger;
    final cancelLabel = widget.cancelLabel;
    final descriptionStyle = theme.text(size: GhTextSize.sm, color: theme.muted, lineHeight: 1.625);
    return GhModalShell(
      icon: danger
          ? GhIcon(GhIcons.trash, size: theme.space(5), color: theme.danger)
          : GhIcon(GhIcons.alertTriangle, size: theme.space(5), color: theme.amber),
      title: widget.title,
      maxWidth: GhModalWidth.sm,
      onClose: widget.onCancel,
      showClose: false,
      initialFocus: danger ? _cancelNode : _confirmNode,
      isMenuOpen: widget.isMenuOpen,
      staticPreview: widget.staticPreview,
      footer: [
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: theme.space(2.5),
          children: [
            GhButton(
              onPressed: widget.onCancel,
              focusNode: _cancelNode,
              label: cancelLabel != null && cancelLabel.isNotEmpty ? cancelLabel : context.tr.common.cancel,
              variant: GhButtonVariant.ghost,
            ),
            GhButton(
              onPressed: widget.onConfirm,
              focusNode: _confirmNode,
              label: widget.confirmLabel,
              variant: danger ? GhButtonVariant.danger : GhButtonVariant.primary,
            ),
          ],
        ),
      ],
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), 0, theme.space(6), theme.space(4)),
        child: widget.descriptionContent != null
            ? DefaultTextStyle(style: descriptionStyle, child: widget.descriptionContent!)
            : Text(widget.description ?? '', style: descriptionStyle),
      ),
    );
  }
}

Future<bool> showGhConfirmDialog(
  BuildContext context, {
  required String title,
  String? description,
  Widget? descriptionContent,
  required String confirmLabel,
  String? cancelLabel,
  GhConfirmVariant variant = GhConfirmVariant.normal,
}) async {
  final result = await showGhModal<bool>(
    context,
    (context) => GhConfirmDialog(
      title: title,
      description: description,
      descriptionContent: descriptionContent,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      variant: variant,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    ),
  );
  return result ?? false;
}
