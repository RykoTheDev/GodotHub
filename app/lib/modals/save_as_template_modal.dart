import 'package:flutter/material.dart';

import '../api/templates.dart';
import '../design/design.dart';
import '../src/rust/api/types.dart';
import '../ui/controls/text_input.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/reusables/modal_kit.dart';

class SaveAsTemplateModal extends StatefulWidget {
  const SaveAsTemplateModal({super.key, required this.project, required this.onClose});

  final Project project;
  final VoidCallback onClose;

  @override
  State<SaveAsTemplateModal> createState() => _SaveAsTemplateModalState();
}

class _SaveAsTemplateModalState extends State<SaveAsTemplateModal> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _desc = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final trimmed = _name.text.trim();
    if (trimmed.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await TemplatesApi.saveAsTemplate(widget.project.id, trimmed, _desc.text.trim());
      ghToasts.pushToast(GhToastType.success, ghTr('template_saved_toast'));
      widget.onClose();
    } catch (e) {
      ghToasts.pushToast(GhToastType.error, '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr.common;
    final radius = BorderRadius.circular(theme.radiusItem);
    final enabled = !_busy && _name.text.trim().isNotEmpty;
    Widget field(TextEditingController controller, String placeholder, {int lines = 1, bool autofocus = false}) => GhTextInput(
      controller: controller,
      autofocus: autofocus,
      placeholder: placeholder,
      placeholderColor: theme.muted,
      maxLines: lines,
      minLines: lines,
      onSubmitted: lines == 1 ? (_) => _save() : null,
      background: theme.raised,
      focusBorderColor: theme.accentDim,
      padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(2.5)),
    );
    return GhModalShell(
      icon: GhIcon(GhIcons.copy, size: theme.space(4), color: theme.ink),
      title: tr.save_as_template,
      maxWidth: GhModalWidth.sm,
      onClose: widget.onClose,
      footer: [
        GhPressable(
          onPressed: widget.onClose,
          borderRadius: radius,
          builder: (context, states) => GhAnimatedBox(
            color: states.active ? theme.raised : theme.raised.withValues(alpha: 0),
            borderRadius: radius,
            padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(2.5)),
            child: Text(
              tr.cancel,
              style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: states.active ? theme.ink : theme.muted),
            ),
          ),
        ),
        Expanded(
          child: GhPressable(
            onPressed: enabled ? _save : null,
            disabledOpacity: 0.5,
            disabledCursor: SystemMouseCursors.forbidden,
            borderRadius: radius,
            rippleColor: Colors.white,
            builder: (context, states) => GhAnimatedBox(
              alignment: Alignment.center,
              color: states.active ? theme.accentBright : theme.accent,
              borderRadius: radius,
              padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(2.5)),
              child: Text(
                _busy ? tr.saving : tr.project_save_template_btn,
                style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), theme.space(4), theme.space(6), theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(4),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(2),
              children: [GhFieldLabel(tr.project_template_name_label), field(_name, widget.project.name, autofocus: true)],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(2),
              children: [
                GhFieldLabel(tr.project_template_desc_label, optional: tr.optional),
                field(_desc, tr.project_template_desc_placeholder, lines: 3),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
