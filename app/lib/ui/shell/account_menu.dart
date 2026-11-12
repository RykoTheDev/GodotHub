import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../core/interaction.dart';
import '../core/ui_settings.dart' show GhSide;
import '../overlays/dropdown.dart';
import '../overlays/menu.dart';
import '../core/i18n.dart';

const ghSupportUrl = 'https://www.patreon.com/cw/TheRyko/membership';

class GhAccountMenu extends StatefulWidget {
  const GhAccountMenu({
    super.key,
    required this.trigger,
    required this.onNavigate,
    this.userName,
    this.githubUsername,
    this.gitlabUsername,
    this.hasNewChangelog = false,
    this.workspaceItem,
    this.onOpenChange,
    this.onReportBug,
    this.onSupport,
    this.onManageAccounts,
    this.youLabel,
    this.changelogLabel,
    this.reportBugLabel,
    this.supportLabel,
    this.manageLabel,
    this.newBadgeLabel,
  });

  final GhDropdownTriggerBuilder trigger;
  final ValueChanged<String> onNavigate;
  final String? userName;
  final String? githubUsername;
  final String? gitlabUsername;
  final bool hasNewChangelog;
  final GhMenuItem? workspaceItem;
  final ValueChanged<bool>? onOpenChange;
  final VoidCallback? onReportBug;
  final VoidCallback? onSupport;
  final VoidCallback? onManageAccounts;
  final String? youLabel;
  final String? changelogLabel;
  final String? reportBugLabel;
  final String? supportLabel;
  final String? manageLabel;
  final String? newBadgeLabel;

  @override
  State<GhAccountMenu> createState() => _GhAccountMenuState();
}

class _GhAccountMenuState extends State<GhAccountMenu> {
  final _manageNode = GhMenuItemFocusNode(debugLabel: 'GhAccountMenu manage');

  @override
  void dispose() {
    _manageNode.dispose();
    super.dispose();
  }

  List<GhMenuItem> _items() => [
    if (widget.workspaceItem != null) widget.workspaceItem!,
    GhMenuItem(
      id: 'changelog',
      label: widget.changelogLabel ?? context.tr.nav.changelog,
      icon: GhIcons.bookOpen,
      badge: widget.hasNewChangelog ? widget.newBadgeLabel ?? context.tr.common.new_badge : null,
      onSelected: () => widget.onNavigate('changelog'),
    ),
    GhMenuItem(
      id: 'bug',
      label: widget.reportBugLabel ?? context.tr.common.report_a_bug,
      icon: GhIcons.bug,
      danger: true,
      onSelected: widget.onReportBug ?? () {},
    ),
    GhMenuItem(
      id: 'support',
      label: widget.supportLabel ?? context.tr.common.support,
      icon: GhIcons.heart,
      onSelected: widget.onSupport ?? () {},
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GhDropdown(
      trigger: widget.trigger,
      side: GhSide.top,
      align: GhSide.left,
      onOpenChange: widget.onOpenChange,
      compact: true,
      items: _items(),
      content: (context, close) => _header(context, close),
    );
  }

  Widget _header(BuildContext context, VoidCallback close) {
    final theme = GhTheme.of(context);
    final name = (widget.userName?.isNotEmpty ?? false) ? widget.userName! : widget.youLabel ?? context.tr.nav.you;
    final accounts = <(FaIconData, String, String)>[
      if (widget.githubUsername != null) (GhIcons.github, 'GitHub', widget.githubUsername!),
      if (widget.gitlabUsername != null) (GhIcons.gitlab, 'GitLab', widget.gitlabUsername!),
    ];
    return Container(
      margin: EdgeInsets.only(bottom: theme.space(1)),
      padding: EdgeInsets.only(top: theme.space(1.5), bottom: theme.space(2.5)),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: GhMenuColors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: theme.space(2.5)),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.text(size: GhTextSize.xl, weight: FontWeight.w900, color: theme.ink, letterSpacingEm: -0.025),
            ),
          ),
          if (accounts.isNotEmpty) ...[
            SizedBox(height: theme.space(2)),
            _AccountsBox(
              accounts: accounts,
              manageLabel: widget.manageLabel ?? context.tr.nav.account_manage,
              manageNode: _manageNode,
              onManage: () {
                close();
                widget.onManageAccounts?.call();
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountsBox extends StatelessWidget {
  const _AccountsBox({required this.accounts, required this.manageLabel, required this.manageNode, required this.onManage});

  final List<(FaIconData, String, String)> accounts;
  final String manageLabel;
  final FocusNode manageNode;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final divider = theme.outline.withValues(alpha: 0.4);
    final radius = BorderRadius.circular(theme.rem(1));
    final textStyle = theme.text(size: GhTextSize.xs);
    final rows = <Widget>[];
    for (final (icon, label, username) in accounts) {
      rows.add(
        Container(
          height: theme.space(7),
          padding: EdgeInsets.symmetric(horizontal: theme.space(3)),
          color: theme.accent.withValues(alpha: 0.1),
          child: Row(
            children: [
              GhIcon(icon, size: theme.space(3.5), color: theme.ink),
              SizedBox(width: theme.space(2)),
              Text(label, style: textStyle.copyWith(color: theme.muted)),
              SizedBox(width: theme.space(2)),
              Expanded(
                child: Text(
                  '@$username',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: textStyle.copyWith(color: theme.ink),
                ),
              ),
            ],
          ),
        ),
      );
      rows.add(Container(height: 1, color: divider));
    }
    rows.add(_ManageButton(label: manageLabel, focusNode: manageNode, onPressed: onManage));
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.raised.withValues(alpha: 0.6),
        borderRadius: radius,
        border: Border.all(color: divider),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
    );
  }
}

class _ManageButton extends StatelessWidget {
  const _ManageButton({required this.label, required this.focusNode, required this.onPressed});

  final String label;
  final FocusNode focusNode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return GhPressable(
      onPressed: onPressed,
      focusNode: focusNode,
      semanticLabel: label,
      builder: (context, states) {
        final hover = states.active;
        final foreground = hover ? theme.ink : theme.muted;
        return GhAnimatedBox(
          height: theme.space(7),
          padding: EdgeInsets.symmetric(horizontal: theme.space(3)),
          color: hover ? theme.raised : theme.raised.withValues(alpha: 0),
          child: Row(
            children: [
              GhIconMotionScale(
                states: states,
                child: GhAnimatedIcon(GhIcons.plug, color: foreground, size: theme.space(3.5)),
              ),
              SizedBox(width: theme.space(2)),
              Expanded(
                child: GhAnimatedText(
                  label,
                  style: theme.text(size: GhTextSize.xs, color: foreground),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: theme.space(2)),
              Transform.rotate(
                angle: rtl ? math.pi : 0,
                child: GhIconMotionScale(
                  states: states,
                  child: GhAnimatedIcon(GhIcons.chevronRight, color: foreground, size: theme.space(2.5)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
