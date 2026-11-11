import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/design.dart';
import '../logic/features.dart';
import '../logic/last_opened.dart';
import '../logic/project_sort.dart' show stableSorted;
import '../logic/settings_copy.dart';
import '../motion/presence.dart';
import '../motion/tween.dart';
import '../src/rust/api/types.dart';
import '../state/app_signals.dart';
import '../state/categories.dart';
import '../state/godot_versions.dart';
import '../state/keyboard_shortcuts.dart';
import '../state/projects.dart';
import '../state/settings.dart';
import '../state/shell_signals.dart';
import '../state/workspaces.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/modal_header.dart';
import '../ui/shell/sidebar.dart' show ghModLabel;

@immutable
class _Command {
  const _Command({
    required this.id,
    required this.labelKey,
    required this.icon,
    required this.sectionKey,
    required this.action,
    this.nav = false,
    this.shortcut,
    this.context,
  });

  final String id;
  final String labelKey;
  final bool nav;
  final String? shortcut;
  final FaIconData icon;
  final String sectionKey;
  final String? context;
  final VoidCallback action;
}

class _Item {
  const _Item({
    required this.id,
    required this.label,
    required this.section,
    required this.icon,
    required this.action,
    this.sublabel,
    this.shortcut,
    this.iconColor,
  });

  final String id;
  final String label;
  final String? sublabel;
  final String? shortcut;
  final FaIconData icon;
  final Color? iconColor;
  final String section;
  final VoidCallback action;
}

const _settingsSearchItems = [
  ('project_scan_dirs', 'storage'),
  ('version_scan_dirs', 'storage'),
  ('default_project_location', 'storage'),
  ('download_dir', 'storage'),
  ('scan_depth', 'storage'),
  ('icon_scan_depth', 'storage'),
  ('download_concurrency', 'storage'),
  ('close_on_project_open', 'behavior'),
  ('minimize_to_tray', 'behavior'),
  ('reopen_after_godot_closes', 'behavior'),
  ('auto_scan_on_startup', 'behavior'),
  ('workspaces_enabled', 'behavior'),
  ('directory_naming_convention', 'behavior'),
  ('git_init_new_projects', 'behavior'),
  ('tooltip_delay', 'accessibility'),
  ('command_palette_keybind', 'behavior'),
  ('tray_recent_projects_count', 'behavior'),
  ('last_opened_time_format', 'display'),
  ('last_opened_date_format', 'display'),
  ('theme_mode', 'appearance'),
  ('accent_color', 'appearance'),
  ('background_color', 'appearance'),
  ('corner_radius', 'appearance'),
  ('ui_density', 'appearance'),
  ('font_scale', 'appearance'),
  ('custom_css', 'appearance'),
  ('project_icon_opacity', 'appearance'),
  ('show_scrollbars', 'accessibility'),
  ('setup_wizard', 'advanced'),
  ('reset_settings', 'advanced'),
  ('delete_app_data', 'advanced'),
  ('check_updates', 'advanced'),
  ('show_support_button', 'advanced'),
  ('show_star_button', 'advanced'),
  ('discord_rpc_enabled', 'integrations'),
  ('discord_app_id', 'integrations'),
  ('discord_rpc_show_projects', 'integrations'),
  ('discord_rpc_excluded_projects', 'integrations'),
  ('discord_rpc_project_presences', 'integrations'),
];

List<_Command> _buildCommands(ValueChanged<String> onNavigate, String mod) {
  void emit(String name, [Object? detail]) => AppSignals.emit(name, detail);
  return [
    _Command(
      id: 'go-projects',
      labelKey: 'projects',
      nav: true,
      shortcut: '${mod}1',
      icon: GhIcons.layoutGrid,
      sectionKey: 'section_navigation',
      action: () => onNavigate('projects'),
    ),
    _Command(
      id: 'go-versions',
      labelKey: 'versions',
      nav: true,
      shortcut: '${mod}2',
      icon: GhIcons.cloudArrowDown,
      sectionKey: 'section_navigation',
      action: () => onNavigate('versions'),
    ),
    _Command(
      id: 'go-templates',
      labelKey: 'templates',
      nav: true,
      shortcut: '${mod}4',
      icon: GhIcons.rocket,
      sectionKey: 'section_navigation',
      action: () => onNavigate('templates'),
    ),
    _Command(
      id: 'go-vault',
      labelKey: 'vault',
      nav: true,
      icon: GhIcons.briefcase,
      sectionKey: 'section_navigation',
      action: () => onNavigate('vault'),
    ),
    _Command(
      id: 'go-asset-store',
      labelKey: 'asset_store',
      nav: true,
      icon: GhIcons.store,
      sectionKey: 'section_navigation',
      action: () => onNavigate('asset-store'),
    ),
    _Command(
      id: 'go-news',
      labelKey: 'news',
      nav: true,
      shortcut: '${mod}3',
      icon: GhIcons.news,
      sectionKey: 'section_navigation',
      action: () => onNavigate('news'),
    ),
    _Command(
      id: 'go-storage',
      labelKey: 'storage_view',
      nav: true,
      icon: GhIcons.hardDrive,
      sectionKey: 'section_navigation',
      action: () => onNavigate('storage'),
    ),
    _Command(
      id: 'go-changelog',
      labelKey: 'changelog',
      nav: true,
      icon: GhIcons.bookOpen,
      sectionKey: 'section_navigation',
      action: () => onNavigate('changelog'),
    ),
    _Command(
      id: 'open-settings',
      labelKey: 'settings',
      nav: true,
      shortcut: '$mod,',
      icon: GhIcons.gear,
      sectionKey: 'section_navigation',
      action: () => onNavigate('settings'),
    ),
    _Command(
      id: 'new-project',
      labelKey: 'new_project',
      shortcut: '${mod}N',
      icon: GhIcons.folderPlus,
      sectionKey: 'section_projects',
      context: 'projects',
      action: () => emit(newProjectRequestSignal),
    ),
    _Command(
      id: 'import-project',
      labelKey: 'import_project',
      icon: GhIcons.import,
      sectionKey: 'section_projects',
      context: 'projects',
      action: () => emit(importProjectRequestSignal),
    ),
    _Command(
      id: 'scan-projects',
      labelKey: 'scan_for_projects',
      icon: GhIcons.refresh,
      sectionKey: 'section_projects',
      context: 'projects',
      action: () => emit(scanProjectsSignal),
    ),
    _Command(
      id: 'switch-view-list',
      labelKey: 'view_list',
      icon: GhIcons.layoutList,
      sectionKey: 'section_views',
      context: 'projects',
      action: () => emit(switchViewSignal, 'list'),
    ),
    _Command(
      id: 'switch-view-grid',
      labelKey: 'view_grid',
      icon: GhIcons.layoutGrid,
      sectionKey: 'section_views',
      context: 'projects',
      action: () => emit(switchViewSignal, 'grid'),
    ),
    _Command(
      id: 'switch-view-kanban',
      labelKey: 'view_kanban',
      icon: GhIcons.kanban,
      sectionKey: 'section_views',
      context: 'projects',
      action: () => emit(switchViewSignal, 'kanban'),
    ),
    _Command(
      id: 'scan-versions',
      labelKey: 'scan_for_engines',
      icon: GhIcons.refresh,
      sectionKey: 'section_engines',
      context: 'versions',
      action: () => emit(scanVersionsSignal),
    ),
    _Command(
      id: 'import-version',
      labelKey: 'import_version',
      icon: GhIcons.import,
      sectionKey: 'section_engines',
      context: 'versions',
      action: () => emit(importVersionSignal),
    ),
    _Command(
      id: 'sync-templates',
      labelKey: 'sync_templates_from_directory',
      icon: GhIcons.refresh,
      sectionKey: 'section_templates',
      action: () => emit(syncTemplatesSignal),
    ),
    _Command(
      id: 'create-workspace',
      labelKey: 'create_workspace',
      icon: GhIcons.briefcase,
      sectionKey: 'section_workspaces',
      action: () => emit(createWorkspaceRequestSignal),
    ),
    _Command(
      id: 'report-bug',
      labelKey: 'report_a_bug',
      icon: GhIcons.bug,
      sectionKey: 'section_help',
      action: () => emit(reportBugSignal),
    ),
    if (kDebugMode)
      _Command(
        id: 'preview-update-modal',
        labelKey: 'preview_update_modal',
        icon: GhIcons.rocket,
        sectionKey: 'section_help',
        action: () => emit(previewUpdateModalSignal),
      ),
  ];
}

const _noCascade = GhCascade(role: GhCascadeRole.part, from: GhPose.identity, duration: 0, ease: Curves.linear);

class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({super.key, required this.onClose, required this.currentTab, required this.onNavigate, this.isMac});

  final VoidCallback onClose;
  final String currentTab;
  final ValueChanged<String> onNavigate;
  final bool? isMac;

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  final TextEditingController _query = TextEditingController();
  final FocusNode _input = FocusNode(debugLabel: 'CommandPalette input');
  final ScrollController _scroll = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() => _selectedIndex = 0));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _input.requestFocus();
    });
  }

  @override
  void dispose() {
    _query.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _mod => ghModLabel('', isMac: widget.isMac);

  List<_Item> _items(Translations tr) {
    final settings = ref.watch(settingsProvider).value ?? defaultSettings;
    final workspaces = ref.watch(workspacesProvider);
    final categories = ref.watch(categoriesProvider).data;
    final projects = ref.watch(projectsProvider).data;
    final installed = ref.watch(godotVersionsProvider.select((state) => state.installed));
    final mod = _mod;
    String common(String key, [Map<String, Object?> args = const {}]) => ghTr(key, args: args, translations: tr);

    final commands = _buildCommands(widget.onNavigate, mod).where(
      (cmd) =>
          (settings.workspacesEnabled || cmd.id != 'create-workspace') &&
          (!cmd.id.startsWith('go-') || isFeatureEnabled(settings, cmd.id.substring(3))) &&
          (cmd.context == null || cmd.context == widget.currentTab),
    );
    final navShortcuts = {'projects': '${mod}1', 'versions': '${mod}2', 'settings': '$mod,'};

    final items = <_Item>[
      for (final cmd in commands)
        _Item(
          id: cmd.id,
          label: cmd.nav ? ghTr('nav:${cmd.labelKey}', translations: tr) : common(cmd.labelKey),
          shortcut: cmd.shortcut,
          icon: cmd.icon,
          section: common(cmd.sectionKey),
          action: cmd.action,
        ),
    ];

    void openProject(Project p) {
      widget.onNavigate('projects');
      AppSignals.emit(openProjectSignal, p.id);
    }

    final recent = stableSorted(
      projects.where((p) => p.lastOpened != null && p.lastOpened!.isNotEmpty),
      (a, b) => (jsTimeOf(b.lastOpened) ?? 0).compareTo(jsTimeOf(a.lastOpened) ?? 0),
    ).take(5);
    for (final p in recent) {
      items.add(
        _Item(
          id: 'recent:${p.id}',
          label: p.name,
          sublabel: common('opened_recently', {'label': formatLastOpened(p.lastOpened) ?? 'recently'}),
          shortcut: navShortcuts['projects'],
          icon: GhIcons.clock,
          section: common('recent_section'),
          action: () => openProject(p),
        ),
      );
    }
    for (final p in projects) {
      items.add(
        _Item(
          id: 'project:${p.id}',
          label: p.name,
          sublabel: p.path,
          shortcut: navShortcuts['projects'],
          icon: GhIcons.node,
          section: common('section_projects'),
          action: () => openProject(p),
        ),
      );
    }
    for (final v in installed) {
      items.add(
        _Item(
          id: 'version:${v.tag}',
          label: (v.customName?.isNotEmpty ?? false) ? v.customName! : v.tag,
          sublabel: v.executablePath,
          shortcut: navShortcuts['versions'],
          icon: GhIcons.play,
          section: common('installed_versions_section'),
          action: () => widget.onNavigate('versions'),
        ),
      );
    }
    for (final (key, tab) in _settingsSearchItems) {
      items.add(
        _Item(
          id: 'setting:$key',
          label: common('setting_$key'),
          sublabel: common('settings_label', {'tab': '${tab[0].toUpperCase()}${tab.substring(1)}'}),
          shortcut: navShortcuts['settings'],
          icon: GhIcons.gear,
          section: common('settings_title'),
          action: () => AppSignals.emit(openSettingSignal, key),
        ),
      );
    }
    if (settings.workspacesEnabled) {
      for (final w in workspaces.workspaces) {
        final active = w.id == workspaces.activeId;
        items.add(
          _Item(
            id: 'workspace:${w.id}',
            label: active ? common('active_workspace', {'name': w.name}) : w.name,
            sublabel: active ? common('current_workspace') : common('switch_workspace'),
            icon: workspaceIcon(w.icon),
            iconColor: colorFromHex(w.color),
            section: common('section_workspaces'),
            action: () => ref.read(workspacesProvider.notifier).switchWorkspace(w.id).ignore(),
          ),
        );
      }
    }
    if (settings.categoriesEnabled && categories.isNotEmpty) {
      items.add(
        _Item(
          id: 'category-all',
          label: common('all_categories'),
          sublabel: common('clear_category_filter'),
          icon: GhIcons.tags,
          section: common('categories'),
          action: () => AppSignals.emit(setCategoryFilterSignal, ''),
        ),
      );
      for (final c in categories) {
        items.add(
          _Item(
            id: 'category:${c.id}',
            label: c.name,
            sublabel: common('filter_by_category'),
            icon: GhIcons.tags,
            iconColor: colorFromHex(c.color),
            section: common('categories'),
            action: () => AppSignals.emit(setCategoryFilterSignal, c.name),
          ),
        );
      }
    }
    for (final preset in themePresets) {
      items.add(
        _Item(
          id: 'preset:${preset.id}',
          label: preset.name,
          sublabel: common(preset.mode == GhThemeMode.light ? 'theme_light' : 'theme_dark'),
          icon: GhIcons.palette,
          section: common('theme_presets_section'),
          action: () => ref.read(settingsProvider.notifier).save(copySettings(settings, themePreset: preset.id)).ignore(),
        ),
      );
    }
    return items;
  }

  List<(String, List<_Item>)> _sections(List<_Item> all) {
    final q = _query.text.trim().toLowerCase();
    final results = q.isEmpty
        ? all
        : all.where(
            (item) =>
                item.label.toLowerCase().contains(q) ||
                (item.sublabel?.toLowerCase().contains(q) ?? false) ||
                item.section.toLowerCase().contains(q),
          );
    final sections = <String, List<_Item>>{};
    for (final item in results) {
      sections.putIfAbsent(item.section, () => []).add(item);
    }
    return [for (final entry in sections.entries) (entry.key, entry.value)];
  }

  void _execute(_Item item) {
    widget.onClose();
    item.action();
  }

  void _select(int index, int count, {required bool forward}) {
    final next = count == 0 ? 0 : index.clamp(0, count - 1);
    setState(() => _selectedIndex = next);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _itemKeys[next]?.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        alignmentPolicy: forward ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    });
  }

  KeyEventResult _onKey(List<_Item> flat, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _select(_selectedIndex + 1, flat.length, forward: true);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _select(_selectedIndex - 1, flat.length, forward: false);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (_selectedIndex < flat.length) _execute(flat[_selectedIndex]);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      widget.onClose();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr;
    final sections = _sections(_items(tr));
    final flat = [for (final (_, items) in sections) ...items];
    if (_selectedIndex >= flat.length && flat.isNotEmpty) _selectedIndex = flat.length - 1;
    final viewport = MediaQuery.sizeOf(context);
    final mutedHint = theme.muted.withValues(alpha: 0.5);

    final list = <Widget>[];
    var index = 0;
    for (final (section, items) in sections) {
      list.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.space(2), vertical: theme.space(1.5)),
          child: Text(
            section.toUpperCase(),
            style: theme.text(size: GhTextSize.x3s, weight: GhWeight.semibold, color: mutedHint, letterSpacingEm: 0.05),
          ),
        ),
      );
      for (final item in items) {
        final idx = index++;
        list.add(
          _PaletteRow(
            key: _itemKeys.putIfAbsent(idx, GlobalKey.new),
            item: item,
            selected: idx == _selectedIndex,
            onHover: () => setState(() => _selectedIndex = idx),
            onPressed: () => _execute(item),
          ),
        );
      }
    }

    final panel = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.radiusModal),
        boxShadow: GhShadows.xl2(Colors.black.withValues(alpha: 0.6)),
      ),
      child: GhCascadeHost(
        cascade: _noCascade,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GhModalHeader(
              icon: GhIcon(GhIcons.search, size: theme.space(5), color: theme.accentBright),
              title: tr.common.command_palette_title,
              onClose: widget.onClose,
              autoFocusBanner: false,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.symmetric(horizontal: BorderSide(color: theme.line)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(3)),
                child: Row(
                  spacing: theme.space(3),
                  children: [
                    GhIcon(GhIcons.search, size: theme.space(4), color: theme.muted.withValues(alpha: 0.6)),
                    Expanded(
                      child: Focus(
                        onKeyEvent: (node, event) => _onKey(flat, event),
                        child: TextField(
                          controller: _query,
                          focusNode: _input,
                          style: theme.text(size: GhTextSize.sm, color: theme.ink),
                          cursorColor: theme.caret,
                          decoration: InputDecoration.collapsed(
                            hintText: tr.common.command_palette_placeholder,
                            hintStyle: theme.text(size: GhTextSize.sm, color: mutedHint),
                          ),
                        ),
                      ),
                    ),
                    _Kbd(label: 'ESC', color: theme.muted.withValues(alpha: 0.6), paddingX: 1.5),
                  ],
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: viewport.height * 0.5),
              child: flat.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(theme.space(2)),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: theme.space(8)),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: '${tr.common.command_palette_no_results} '),
                              TextSpan(
                                text: '"${_query.text}"',
                                style: theme.text(size: GhTextSize.xs, mono: true, color: theme.ink),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          style: theme.text(size: GhTextSize.xs, color: theme.muted),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      controller: _scroll,
                      padding: EdgeInsets.all(theme.space(2)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: list),
                    ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.line)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(2)),
                child: DefaultTextStyle(
                  style: theme.text(size: GhTextSize.x3s, color: mutedHint),
                  child: Row(
                    spacing: theme.space(4),
                    children: [
                      _FooterHint(kbd: '↑↓', label: tr.common.command_palette_navigate),
                      _FooterHint(kbd: '↵', label: tr.common.clone_repo_select),
                      _FooterHint(kbd: tr.common.command_palette_escape, label: tr.common.close),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle(
        style: theme.text(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onClose,
              child: GhPresenceLayerView(
                layer: GhPresenceSpecs.modalPanel,
                child: const ColoredBox(color: Color(0x99000000)),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: viewport.height * 0.12),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: theme.rem(32)),
                  child: Semantics(
                    scopesRoute: true,
                    namesRoute: true,
                    explicitChildNodes: true,
                    label: tr.common.command_palette_title,
                    child: GestureDetector(onTap: () {}, child: panel),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaletteRow extends StatelessWidget {
  const _PaletteRow({super.key, required this.item, required this.selected, required this.onHover, required this.onPressed});

  final _Item item;
  final bool selected;
  final VoidCallback onHover;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radius = BorderRadius.circular(theme.radiusItem);
    return MouseRegion(
      onEnter: (_) => onHover(),
      child: GhPressable(
        onPressed: onPressed,
        borderRadius: radius,
        canRequestFocus: false,
        semanticLabel: item.label,
        builder: (context, states) {
          final hover = states.active && !selected;
          final textColor = selected || hover ? theme.ink : theme.muted;
          return GhAnimatedBox(
            borderRadius: radius,
            color: selected
                ? theme.accent.withValues(alpha: 0.15)
                : hover
                ? theme.raised
                : theme.raised.withValues(alpha: 0),
            padding: EdgeInsets.symmetric(horizontal: theme.space(3), vertical: theme.space(2.5)),
            child: Row(
              spacing: theme.space(3),
              children: [
                GhIcon(
                  item.icon,
                  size: theme.space(4),
                  color: item.iconColor ?? (selected ? theme.accentBright : theme.muted.withValues(alpha: 0.7)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.text(size: GhTextSize.sm, color: textColor),
                      ),
                      if (item.sublabel != null)
                        Text(
                          item.sublabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.text(size: GhTextSize.x3s, color: theme.muted.withValues(alpha: 0.5)),
                        ),
                    ],
                  ),
                ),
                if (item.shortcut != null) _Kbd(label: item.shortcut!, color: theme.muted.withValues(alpha: 0.5), paddingX: 1.5),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Kbd extends StatelessWidget {
  const _Kbd({required this.label, required this.color, required this.paddingX, this.paddingY = 0.5});

  final String label;
  final Color color;
  final double paddingX;
  final double paddingY;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: theme.space(paddingX), vertical: theme.space(paddingY)),
      decoration: BoxDecoration(
        color: theme.overlay,
        borderRadius: BorderRadius.circular(theme.radiusSm),
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        style: theme.text(size: GhTextSize.x3s, mono: true, color: color),
      ),
    );
  }
}

class _FooterHint extends StatelessWidget {
  const _FooterHint({required this.kbd, required this.label});

  final String kbd;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final style = DefaultTextStyle.of(context).style;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Kbd(label: kbd, color: style.color ?? theme.muted, paddingX: 1, paddingY: 0),
        Text(' $label', style: style),
      ],
    );
  }
}
