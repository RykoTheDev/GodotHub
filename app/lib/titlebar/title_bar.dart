import 'package:flutter/material.dart';

import '../design/design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../motion/intro.dart';
import '../src/providers.dart';
import '../src/rust/api/types.dart';
import 'language_menu.dart';
import 'providers.dart';
import 'running_projects_chip.dart';
import 'strings.dart' as s;
import 'task_tray.dart';
import 'title_bar_theme.dart';
import 'window_controls.dart';

enum TitleBarAction { wordmark, changelog, support, star, bug }

bool hasAnyTitleBarButton(AppSettings settings, {required bool minimal}) =>
    settings.showSupportButton ||
    settings.showStarButton ||
    settings.showBugButton ||
    settings.showLanguageButton ||
    settings.showTrayButton ||
    (!minimal && settings.showChangelogButton);

bool showsCustomWindowControls(AppSettings settings, {required bool isMac}) =>
    !isMac && !settings.useOsDecorations;

class TitleBar extends ConsumerWidget {
  const TitleBar({super.key, required this.isMac, this.minimal = false, this.onAction});

  final bool isMac;
  final bool minimal;
  final void Function(TitleBarAction action)? onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    if (settings == null) return const SizedBox.shrink();
    if (settings.useOsDecorations && !hasAnyTitleBarButton(settings, minimal: minimal)) {
      return const SizedBox.shrink();
    }
    final window = ref.watch(titleBarWindowProvider);
    final hasNewChangelogEntry = ref.watch(changelogBadgeProvider);
    final showControls = showsCustomWindowControls(settings, isMac: isMac);
    final tokens = TitleBarTokens.from(Theme.of(context), cornerRadius: settings.cornerRadius);
    final dashboardEnabled = !settings.disabledFeatures.contains('dashboard');
    final showTrailingGroup = settings.showLanguageButton || (!minimal && settings.showTrayButton);

    void emit(TitleBarAction action) => onAction?.call(action);

    final trailing = <Widget>[
      if (!minimal && settings.showChangelogButton)
        _ChangelogButton(hasNewEntry: hasNewChangelogEntry, onPressed: () => emit(TitleBarAction.changelog)),
      if (!minimal && settings.showSupportButton) _SupportButton(onPressed: () => emit(TitleBarAction.support)),
      if (!minimal && settings.showStarButton)
        TitleBarIconButton(
          key: const ValueKey('titlebar-star'),
          icon: GhIcons.star,
          width: 32,
          height: 32,
          color: tokens.muted,
          hoverColor: tokens.amber,
          hoverBackground: tokens.amber.withValues(alpha: 0.1),
          tooltip: s.starOnGithub,
          semanticLabel: s.starOnGithub,
          onPressed: () => emit(TitleBarAction.star),
        ),
      if (!minimal && settings.showBugButton)
        TitleBarIconButton(
          key: const ValueKey('titlebar-bug'),
          icon: GhIcons.bug,
          width: 24,
          height: 24,
          color: tokens.muted,
          hoverColor: tokens.danger,
          hoverBackground: tokens.danger.withValues(alpha: 0.1),
          tooltip: s.reportABug,
          semanticLabel: s.reportABug,
          onPressed: () => emit(TitleBarAction.bug),
        ),
      if (showTrailingGroup) ...[
        const _Separator(),
        if (settings.showLanguageButton) const LanguageMenu(),
        if (!minimal && settings.showTrayButton) const TaskTray(),
      ],
      if (showControls && showTrailingGroup) const _Separator(),
    ];

    final background = settings.cardLayout ? tokens.raised.withValues(alpha: 0.8) : tokens.raised;

    return TitleBarTheme(
      tokens: tokens,
      child: TooltipTheme(
        data: TooltipTheme.of(context).copyWith(waitDuration: Duration(milliseconds: settings.tooltipDelay)),
        child: Container(
          key: const ValueKey('titlebar'),
          height: showControls ? 32 : 44,
          decoration: BoxDecoration(
            color: background,
            border: settings.cardLayout ? null : Border(bottom: BorderSide(color: tokens.line)),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                key: const ValueKey('titlebar-drag-area'),
                behavior: HitTestBehavior.opaque,
                onPanStart: (_) => window.startDragging(),
                onDoubleTap: showControls ? window.toggleMaximize : null,
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(start: isMac ? 80 : 16, end: showControls ? 0 : 16),
                child: Row(
                  children: [
                    if (!minimal) ...[
                      GhIntroPart(child: _Wordmark(onPressed: dashboardEnabled ? () => emit(TitleBarAction.wordmark) : null)),
                      const SizedBox(width: 12),
                      const GhIntroPart(child: RunningProjectsChip()),
                      const SizedBox(width: 12),
                    ],
                    const Spacer(),
                    GhIntroPart(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < trailing.length; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            Center(widthFactor: 1, child: trailing[i]),
                          ],
                          if (showControls) ...[
                            if (trailing.isNotEmpty) const SizedBox(width: 6),
                            MaximizedStateBuilder(
                              window: window,
                              builder: (context, isMaximized) => WindowControls(
                                key: const ValueKey('window-controls'),
                                colored: settings.coloredTitlebarButtons,
                                isMaximized: isMaximized,
                                onMinimize: window.minimize,
                                onToggleMaximize: window.toggleMaximize,
                                onClose: window.close,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = TitleBarTokens.of(context);
    TextStyle style(bool hovered) => TextStyle(
      fontSize: 18,
      height: 1,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.45,
      color: hovered ? tokens.ink : tokens.ink.withValues(alpha: 0.5),
    );
    final onPressed = this.onPressed;
    if (onPressed == null) {
      return IgnorePointer(child: Text('GodotHub', key: const ValueKey('titlebar-wordmark'), style: style(false)));
    }
    return TitleBarButton(
      key: const ValueKey('titlebar-wordmark'),
      tooltip: s.dashboard,
      semanticLabel: 'GodotHub',
      ripple: false,
      onPressed: onPressed,
      builder: (context, hovered) => Text('GodotHub', style: style(hovered)),
    );
  }
}

class _ChangelogButton extends StatelessWidget {
  const _ChangelogButton({required this.hasNewEntry, required this.onPressed});

  final bool hasNewEntry;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = TitleBarTokens.of(context);
    if (!hasNewEntry) {
      return TitleBarIconButton(
        key: const ValueKey('titlebar-changelog'),
        icon: GhIcons.bookOpen,
        width: 32,
        height: 32,
        color: tokens.muted,
        hoverColor: tokens.ink,
        hoverBackground: tokens.ink.withValues(alpha: 0.1),
        tooltip: s.changelog,
        semanticLabel: s.changelog,
        onPressed: onPressed,
      );
    }
    return TitleBarButton(
      key: const ValueKey('titlebar-changelog'),
      tooltip: s.changelog,
      semanticLabel: '${s.changelog} (${s.newBadge})',
      onPressed: onPressed,
      builder: (context, hovered) => Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: tokens.accent.withValues(alpha: hovered ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(tokens.itemRadius),
          border: Border.all(color: tokens.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: tokens.accentBright, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            GhIcon(GhIcons.bookOpen, size: 14, color: tokens.accentBright),
            const SizedBox(width: 6),
            Text(
              s.changelog,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.accentBright),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportButton extends StatelessWidget {
  const _SupportButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = TitleBarTokens.of(context);
    return TitleBarButton(
      key: const ValueKey('titlebar-support'),
      tooltip: s.supportDev,
      semanticLabel: s.support,
      onPressed: onPressed,
      builder: (context, hovered) => Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: tokens.danger.withValues(alpha: hovered ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(tokens.itemRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GhIcon(GhIcons.heart, size: 14, color: tokens.danger),
            const SizedBox(width: 6),
            Text(
              s.support,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.danger),
            ),
          ],
        ),
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    final tokens = TitleBarTokens.of(context);
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: tokens.line.withValues(alpha: 0.4),
    );
  }
}
