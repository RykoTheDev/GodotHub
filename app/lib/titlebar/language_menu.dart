import 'package:flutter/material.dart';

import '../design/design.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/i18n_controller.dart';
import '../i18n/languages.dart';
import '../src/providers.dart';
import '../src/rust/api/types.dart';
import '../ui/core/i18n.dart';
import '../logic/settings_copy.dart';
import 'title_bar_theme.dart';

const _menuWidth = 240.0;
const _triggerWidth = 36.0;
const _switchToLtrLayoutLabel = 'التبديل إلى التخطيط من اليسار إلى اليمين';
const _switchToRtlLayoutLabel = 'التبديل إلى التخطيط من اليمين إلى اليسار';

bool languageMenuItemActive(String value, String setting, String currentLanguage) {
  if (value == ghSystemLanguage) return setting == ghSystemLanguage;
  if (setting == ghSystemLanguage) return false;
  return currentLanguage == value || currentLanguage.startsWith(value.split('-').first);
}

class LanguageMenu extends ConsumerStatefulWidget {
  const LanguageMenu({super.key});

  @override
  ConsumerState<LanguageMenu> createState() => _LanguageMenuState();
}

class _LanguageMenuState extends ConsumerState<LanguageMenu> {
  final MenuController _menu = MenuController();
  bool _open = false;

  Future<void> _save(AppSettings next) async {
    try {
      await ref.read(settingsProvider.notifier).save(next);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _select(AppSettings settings, String value) {
    GhI18n.instance.setLanguageSetting(value);
    _save(copySettings(settings, language: value));
    _menu.close();
  }

  void _toggleLayout(AppSettings settings) {
    _save(copySettings(settings, rtlLayout: !settings.rtlLayout));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TitleBarTokens.of(context);
    final settings = ref.watch(settingsProvider).value;
    final label = context.tr.common.language_label;
    final i18n = GhI18n.instance;
    return MenuAnchor(
      controller: _menu,
      style: tokens.menuStyle(),
      alignmentOffset: const Offset(_triggerWidth - _menuWidth, 8),
      onOpen: () => setState(() => _open = true),
      onClose: () {
        if (mounted) setState(() => _open = false);
      },
      menuChildren: [
        if (settings != null)
          ListenableBuilder(
            listenable: i18n,
            builder: (context, _) {
              final tr = context.tr;
              final current = i18n.language;
              final rtl = ghTextDirectionOf(current) == TextDirection.rtl;
              return SizedBox(
                width: _menuWidth - 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                      child: Text(
                        tr.common.language_label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: tokens.muted.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    for (final language in ghLanguages)
                      _LanguageRow(
                        key: ValueKey('language-${language.value}'),
                        language: language,
                        label: language.displayLabel(tr),
                        statusLabel: ghTr(languageStatusLabelKey(language.status), translations: tr),
                        active: languageMenuItemActive(language.value, settings.language, current),
                        showLayoutToggle: rtl && languageMenuItemActive(language.value, settings.language, current),
                        mirrored: settings.rtlLayout,
                        onSelect: () => _select(settings, language.value),
                        onToggleLayout: () => _toggleLayout(settings),
                      ),
                  ],
                ),
              );
            },
          ),
      ],
      builder: (context, controller, child) => TitleBarIconButton(
        key: const ValueKey('language-menu-trigger'),
        icon: GhIcons.language,
        iconSize: 16,
        width: _triggerWidth,
        height: 32,
        color: tokens.muted,
        hoverColor: tokens.ink,
        hoverBackground: tokens.ink.withValues(alpha: 0.08),
        tooltip: label,
        semanticLabel: label,
        expanded: _open,
        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    super.key,
    required this.language,
    required this.label,
    required this.statusLabel,
    required this.active,
    required this.showLayoutToggle,
    required this.mirrored,
    required this.onSelect,
    required this.onToggleLayout,
  });

  final GhLanguageOption language;
  final String label;
  final String statusLabel;
  final bool active;
  final bool showLayoutToggle;
  final bool mirrored;
  final VoidCallback onSelect;
  final VoidCallback onToggleLayout;

  @override
  Widget build(BuildContext context) {
    final tokens = TitleBarTokens.of(context);
    final big = Radius.circular(tokens.itemRadius);
    final small = Radius.circular(tokens.smRadius);
    final itemRadius = showLayoutToggle ? BorderRadiusDirectional.horizontal(start: big, end: small) : BorderRadiusDirectional.all(big);
    final item = TitleBarButton(
      semanticLabel: label,
      onPressed: onSelect,
      builder: (context, hovered) {
        final foreground = active ? tokens.accentBright : (hovered ? tokens.ink : tokens.muted);
        final background = active ? tokens.accent.withValues(alpha: 0.15) : (hovered ? tokens.raised : Colors.transparent);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: background, borderRadius: itemRadius),
          child: Row(
            children: [
              LanguageFlag(country: language.country),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: foreground),
                      ),
                    ),
                    if (!language.isSystem) ...[const SizedBox(width: 6), LanguageStatusBadge(status: language.status, label: statusLabel)],
                  ],
                ),
              ),
              if (active) ...[const SizedBox(width: 8), GhIcon(GhIcons.check, size: 14, color: foreground)],
            ],
          ),
        );
      },
    );
    if (!showLayoutToggle) return item;
    final toggleLabel = mirrored ? _switchToLtrLayoutLabel : _switchToRtlLayoutLabel;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: item),
          const SizedBox(width: 2),
          TitleBarButton(
            key: const ValueKey('rtl-layout-toggle'),
            tooltip: toggleLabel,
            semanticLabel: toggleLabel,
            onPressed: onToggleLayout,
            builder: (context, hovered) {
              final alpha = mirrored ? (hovered ? 0.35 : 0.25) : (hovered ? 0.25 : 0.15);
              return Container(
                width: 36,
                decoration: BoxDecoration(
                  color: tokens.accent.withValues(alpha: alpha),
                  borderRadius: BorderRadiusDirectional.horizontal(start: small, end: big),
                ),
                child: GhIcon(
                  GhIcons.textDirection,
                  size: 14,
                  color: mirrored || hovered ? tokens.accentBright : tokens.accentBright.withValues(alpha: 0.7),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class LanguageFlag extends StatelessWidget {
  const LanguageFlag({super.key, required this.country});

  final String country;

  @override
  Widget build(BuildContext context) {
    final tokens = TitleBarTokens.of(context);
    if (country == 'SYSTEM') {
      return GhIcon(GhIcons.language, size: 16, color: tokens.muted);
    }
    return Container(
      width: 22,
      height: 15,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.ink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      child: Text(
        country,
        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, height: 1, color: tokens.muted),
      ),
    );
  }
}

class LanguageStatusBadge extends StatelessWidget {
  const LanguageStatusBadge({super.key, required this.status, required this.label});

  final GhLanguageStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = TitleBarTokens.of(context);
    final (background, foreground, border) = switch (status) {
      GhLanguageStatus.complete => (tokens.mint.withValues(alpha: 0.1), tokens.mint, tokens.mint.withValues(alpha: 0.3)),
      GhLanguageStatus.beta => (tokens.amber.withValues(alpha: 0.1), tokens.amber, tokens.amber.withValues(alpha: 0.3)),
      GhLanguageStatus.incomplete => (Colors.black.withValues(alpha: 0.15), tokens.muted, tokens.line.withValues(alpha: 0.4)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(tokens.tagRadius),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: foreground),
      ),
    );
  }
}
