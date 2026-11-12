import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/design.dart';
import '../state/section_search.dart';

export '../ui/reusables/segmented.dart';

class SettingsSubsection extends ConsumerStatefulWidget {
  const SettingsSubsection({
    super.key,
    required this.id,
    this.title,
    this.titleWidget,
    this.inline = false,
    this.fill = false,
    this.searchText,
    required this.child,
  });

  final String id;
  final String? title;
  final Widget? titleWidget;
  final bool inline;
  final bool fill;
  final String? searchText;
  final Widget child;

  @override
  ConsumerState<SettingsSubsection> createState() => _SettingsSubsectionState();
}

class _SettingsSubsectionState extends ConsumerState<SettingsSubsection> {
  bool? _reported;
  late final SectionSearchNotifier _search = ref.read(sectionSearchProvider.notifier);

  void _report(bool matched) {
    if (_reported == matched) return;
    _reported = matched;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && _reported == matched) _search.reportMatch(widget.id, matched);
    });
  }

  @override
  void dispose() {
    if (_reported ?? false) {
      final search = _search;
      final id = widget.id;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        try {
          search.reportMatch(id, false);
        } catch (_) {}
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(sectionSearchProvider.select((s) => s.query));
    final matches = matchesSearch(query, [widget.title, widget.searchText]);
    _report(matches);
    if (!matches) return const SizedBox.shrink();
    final theme = GhTheme.of(context);
    final titleText = widget.title;
    final Widget? heading =
        widget.titleWidget ??
        (titleText == null || titleText.isEmpty
            ? null
            : Text(
                titleText,
                style: theme.text(size: GhTextSize.sm, weight: GhWeight.medium, color: theme.ink),
              ));
    final Widget body;
    if (!widget.inline) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(2),
        children: [?heading, widget.child],
      );
    } else if (widget.fill) {
      body = Row(
        spacing: theme.space(4),
        children: [?heading, Expanded(child: widget.child)],
      );
    } else {
      body = Row(
        spacing: theme.space(4),
        children: [
          ?heading,
          Expanded(child: SettingsDividerLine(theme: theme)),
          widget.child,
        ],
      );
    }
    return Container(
      padding: EdgeInsets.all(theme.space(4)),
      decoration: BoxDecoration(
        color: theme.overlay,
        borderRadius: BorderRadius.circular(theme.radiusItem),
      ),
      child: body,
    );
  }
}

class SettingRow extends StatelessWidget {
  const SettingRow({super.key, required this.label, required this.child, this.divider = false});

  final String label;
  final Widget child;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final row = Row(
      spacing: theme.space(4),
      children: [
        Text(
          label,
          style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.muted),
        ),
        Expanded(child: SettingsDividerLine(theme: theme)),
        child,
      ],
    );
    if (!divider) return row;
    return Container(
      padding: EdgeInsets.only(top: theme.space(4)),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.line)),
      ),
      child: row,
    );
  }
}

class SettingsDividerLine extends StatelessWidget {
  const SettingsDividerLine({super.key, required this.theme});

  final GhTheme theme;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(height: 1, color: theme.outline.withValues(alpha: 0.4)),
    );
  }
}
