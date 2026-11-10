import 'package:flutter/material.dart';

import '../../../design/design.dart';
import '../../../ui/core/button.dart';
import '../../../ui/core/ui_settings.dart';
import '../../../ui/overlays/dropdown.dart';
import '../../../ui/overlays/menu.dart';
import '../../../ui/shell/account_menu.dart';
import '../../../ui/shell/color_swatch_picker.dart';
import '../../../ui/shell/disclosure.dart';
import '../../../ui/shell/overlay_scroll_area.dart';
import '../../../ui/shell/sidebar.dart';
import '../../../ui/shell/workspace_form.dart';
import '../../../ui/shell/workspace_switcher.dart';
import '../gallery_kit.dart';

final shellSections = <GallerySection>[
  GallerySection('Sidebar', (context) => const _Sidebars()),
  GallerySection('Sidebar items', (context) => const _SidebarItems()),
  GallerySection('Account menu & workspaces', (context) => const _AccountMenus()),
  GallerySection('Workspace form', (context) => const _WorkspaceForms()),
  GallerySection('Color swatch picker', (context) => const _SwatchPickers()),
  GallerySection('Disclosure & scroll area', (context) => const _Reusables()),
];

const _library = GhSidebarGroup(id: 'library', label: 'Library', icon: GhIcons.book);

const _sampleTabs = [
  GhSidebarTab(id: 'dashboard', label: 'Dashboard', icon: GhIcons.layoutGrid, shortcut: 1),
  GhSidebarTab(id: 'projects', label: 'Projects', icon: GhIcons.folder, shortcut: 2, badge: 3),
  GhSidebarTab(id: 'versions', label: 'Versions', icon: GhIcons.download, shortcut: 3),
  GhSidebarTab(id: 'templates', label: 'Templates', icon: GhIcons.clone, group: _library, shortcut: 4),
  GhSidebarTab(id: 'vault', label: 'Vault', icon: GhIcons.lock, group: _library, isNew: true),
  GhSidebarTab(id: 'storage', label: 'Storage', icon: GhIcons.hardDrive, group: _library, badge: 12),
  GhSidebarTab(id: 'assets', label: 'Asset Store', icon: GhIcons.store, shortcut: 5),
  GhSidebarTab(id: 'news', label: 'Godot News', icon: GhIcons.news, isNew: true),
];

const _workspaces = [
  GhWorkspace(id: 'work', name: 'Work', icon: 'briefcase', color: '#457ff2'),
  GhWorkspace(id: 'personal', name: 'Personal', icon: 'house', color: '#23a55a'),
  GhWorkspace(id: 'jam', name: 'Game Jam', icon: 'gamepad', color: '#eb459e'),
];

void _noop() {}

void _noopId(String _) {}

GhMenuItem? _workspaceItem(String activeId, ValueChanged<String> onSwitch) =>
    ghWorkspaceMenuItem(workspaces: _workspaces, activeId: activeId, onSwitch: onSwitch, onEdit: _noopId, onCreate: _noop);

class _Sidebars extends StatefulWidget {
  const _Sidebars();

  @override
  State<_Sidebars> createState() => _SidebarsState();
}

class _SidebarsState extends State<_Sidebars> {
  String _active = 'projects';
  String _workspace = 'work';
  int _sidebarKey = 0;

  Widget _account(BuildContext context, GhDropdownTriggerBuilder trigger) => GhAccountMenu(
    trigger: trigger,
    onNavigate: (id) => setState(() => _active = id),
    userName: 'ryko',
    githubUsername: 'ryko-dev',
    hasNewChangelog: true,
    workspaceItem: _workspaceItem(_workspace, (id) => setState(() => _workspace = id)),
  );

  Widget _sidebar({required bool collapsed, bool connected = false, bool update = false, bool tip = false}) {
    return SizedBox(
      height: 600,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GhSidebar(
            key: ValueKey('$collapsed-$connected-$update-$tip-$_sidebarKey'),
            tabs: _sampleTabs,
            activeTab: _active,
            onTabChange: (id) => setState(() => _active = id),
            initialCollapsed: collapsed,
            connected: connected,
            updateAvailable: update,
            onOpenUpdatesModal: _noop,
            onOpenCommandPalette: _noop,
            workspacesEnabled: tip,
            accountMenuBuilder: _account,
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'active: $_active · workspace: $_workspace',
              style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted),
            ),
            const SizedBox(width: 16),
            GhButton(
              onPressed: () => setState(() => _sidebarKey++),
              label: 'Reset sidebars',
              variant: GhButtonVariant.outline,
              size: GhTextSize.xs,
              paddingX: 3,
              paddingY: 1.5,
            ),
          ],
        ),
        const SizedBox(height: 16),
        GalleryGroup(
          title: 'Expanded and collapsed',
          spacing: 40,
          children: [
            GalleryItem(label: 'expanded · update · tip', child: _sidebar(collapsed: false, update: true, tip: true)),
            GalleryItem(label: 'collapsed · update', child: _sidebar(collapsed: true, update: true)),
            GalleryItem(label: 'connected', child: _sidebar(collapsed: false, connected: true)),
          ],
        ),
      ],
    );
  }
}

class _SidebarItems extends StatelessWidget {
  const _SidebarItems();

  @override
  Widget build(BuildContext context) {
    const tab = GhSidebarTab(id: 'projects', label: 'Projects', icon: GhIcons.folder);
    const badged = GhSidebarTab(id: 'projects', label: 'Projects', icon: GhIcons.folder, badge: 14);
    const fresh = GhSidebarTab(id: 'vault', label: 'Vault', icon: GhIcons.lock, isNew: true);
    const you = GhSidebarTab(id: 'account', label: 'You', icon: GhIcons.user);
    const settings = GhSidebarTab(id: 'settings', label: 'Settings', icon: GhIcons.gear);
    Widget sized(Widget child, {double width = 220}) => SizedBox(width: width, child: child);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GalleryGroup(
          title: 'Tab',
          children: [
            GalleryStates(
              states: const [GalleryState.normal, GalleryState.hover, GalleryState.pressed, GalleryState.focus],
              builder: (context, enabled) => sized(GhSidebarTabButton(tab: tab, shortcut: 'Ctrl+2', onPressed: _noop)),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Active tab',
          children: [
            GalleryStates(
              states: const [GalleryState.normal, GalleryState.hover, GalleryState.focus],
              builder: (context, enabled) => sized(GhSidebarTabButton(tab: tab, active: true, onPressed: _noop)),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Badges',
          children: [
            GalleryItem(
              label: 'count',
              child: sized(GhSidebarTabButton(tab: badged, onPressed: _noop)),
            ),
            GalleryItem(
              label: 'new',
              child: sized(GhSidebarTabButton(tab: fresh, showNew: true, onPressed: _noop)),
            ),
            GalleryItem(
              label: 'collapsed count',
              child: GhSidebarTabButton(tab: badged, layout: GhSidebarTabLayout.square, hideLabel: true, onPressed: _noop),
            ),
            GalleryItem(
              label: 'collapsed new',
              child: GhSidebarTabButton(tab: fresh, layout: GhSidebarTabLayout.square, hideLabel: true, showNew: true, onPressed: _noop),
            ),
            GalleryItem(
              label: 'collapsed active',
              child: GhSidebarTabButton(tab: tab, layout: GhSidebarTabLayout.square, hideLabel: true, active: true, onPressed: _noop),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Account and settings',
          children: [
            GalleryStates(
              states: const [GalleryState.normal, GalleryState.hover, GalleryState.focus],
              builder: (context, enabled) => SizedBox(
                width: 220,
                height: 42,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: GhSidebarTabButton(tab: you, chrome: true, onPressed: _noop),
                    ),
                    const SizedBox(width: 6),
                    GhSidebarTabButton(tab: settings, chrome: true, hideLabel: true, layout: GhSidebarTabLayout.narrow, onPressed: _noop),
                  ],
                ),
              ),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Group header',
          children: [
            GalleryStates(
              states: const [GalleryState.normal, GalleryState.hover, GalleryState.focus],
              builder: (context, enabled) => sized(GhSidebarGroupHeader(group: _library, open: true, onPressed: _noop)),
            ),
            GalleryItem(
              label: 'closed · active child · badge',
              child: sized(GhSidebarGroupHeader(group: _library, open: false, activeLabel: 'Templates', badge: 12, onPressed: _noop)),
            ),
          ],
        ),
      ],
    );
  }
}

class _AccountMenus extends StatefulWidget {
  const _AccountMenus();

  @override
  State<_AccountMenus> createState() => _AccountMenusState();
}

class _AccountMenusState extends State<_AccountMenus> {
  String _workspace = 'work';
  String _last = '—';

  GhDropdownTriggerBuilder _trigger(bool collapsed) =>
      (context, open, toggle) => SizedBox(
        width: collapsed ? null : 200,
        child: GhSidebarTabButton(
          tab: const GhSidebarTab(id: 'account', label: 'You', icon: GhIcons.user),
          chrome: true,
          layout: collapsed ? GhSidebarTabLayout.square : GhSidebarTabLayout.full,
          hideLabel: collapsed,
          menuOpen: open,
          onPressed: toggle,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final workspace = _workspaces.firstWhere((w) => w.id == _workspace);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'last action: $_last',
          style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted),
        ),
        const SizedBox(height: 16),
        GalleryGroup(
          title: 'Account menu',
          children: [
            GalleryItem(
              label: 'accounts + workspaces',
              child: GhAccountMenu(
                trigger: _trigger(false),
                onNavigate: (id) => setState(() => _last = 'navigate $id'),
                userName: 'ryko',
                githubUsername: 'ryko-dev',
                gitlabUsername: 'ryko',
                hasNewChangelog: true,
                workspaceItem: _workspaceItem(_workspace, (id) => setState(() => _workspace = id)),
                onReportBug: () => setState(() => _last = 'report bug'),
                onSupport: () => setState(() => _last = 'support'),
                onManageAccounts: () => setState(() => _last = 'manage accounts'),
              ),
            ),
            GalleryItem(
              label: 'minimal · collapsed trigger',
              child: GhAccountMenu(trigger: _trigger(true), onNavigate: (id) => setState(() => _last = 'navigate $id')),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Workspace switcher',
          children: [
            GalleryItem(
              label: 'switcher item',
              child: GhDropdown(
                align: GhSide.left,
                trigger: (context, open, toggle) => GhButton(
                  onPressed: toggle,
                  label: workspace.name,
                  icon: workspaceIcon(workspace.icon),
                  variant: GhButtonVariant.outline,
                  size: GhTextSize.xs,
                  paddingX: 3,
                  paddingY: 2,
                ),
                items: [_workspaceItem(_workspace, (id) => setState(() => _workspace = id))!],
              ),
            ),
            for (final w in _workspaces)
              GalleryItem(
                label: w.id == _workspace ? '${w.name} (active)' : w.name,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: w.id == _workspace ? theme.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(theme.radiusItem),
                  ),
                  child: GhWorkspaceBadge(workspace: w, active: w.id == _workspace),
                ),
              ),
            GalleryItem(
              label: 'avatar',
              child: GhWorkspaceAvatar(icon: workspace.icon, color: workspace.color),
            ),
          ],
        ),
      ],
    );
  }
}

class _WorkspaceForms extends StatefulWidget {
  const _WorkspaceForms();

  @override
  State<_WorkspaceForms> createState() => _WorkspaceFormsState();
}

class _WorkspaceFormsState extends State<_WorkspaceForms> {
  GhWorkspaceDraft _draft = const GhWorkspaceDraft(name: 'Game Jam', icon: 'gamepad', color: '#eb459e');
  GhWorkspaceDraft _empty = const GhWorkspaceDraft(name: '', icon: 'briefcase', color: '#457ff2');

  @override
  Widget build(BuildContext context) {
    final taken = _workspaces.map((w) => w.name).toList();
    return GalleryGroup(
      title: 'Form',
      spacing: 32,
      children: [
        GalleryItem(
          label: 'live errors (name "Work" is taken)',
          child: SizedBox(
            width: 520,
            child: GhWorkspaceForm(value: _draft, onChanged: (next) => setState(() => _draft = next), takenNames: taken, showErrors: true),
          ),
        ),
        GalleryItem(
          label: 'empty · errors hidden',
          child: SizedBox(
            width: 520,
            child: GhWorkspaceForm(value: _empty, onChanged: (next) => setState(() => _empty = next), takenNames: taken, showErrors: false),
          ),
        ),
      ],
    );
  }
}

class _SwatchPickers extends StatefulWidget {
  const _SwatchPickers();

  @override
  State<_SwatchPickers> createState() => _SwatchPickersState();
}

class _SwatchPickersState extends State<_SwatchPickers> {
  String _accent = defaultAccent;
  String _background = defaultBackground;

  @override
  Widget build(BuildContext context) {
    return GalleryGroup(
      title: 'Picker',
      children: [
        GalleryItem(
          label: 'label · accent presets',
          child: GhColorSwatchPicker(
            label: 'Accent color',
            value: _accent,
            onChanged: (hex) => setState(() => _accent = hex),
            presets: accentPresetsDark,
          ),
        ),
        GalleryItem(
          label: 'background presets',
          child: GhColorSwatchPicker(
            value: _background,
            onChanged: (hex) => setState(() => _background = hex),
            presets: [...bgPresetsDark, ...bgPresetsLight],
          ),
        ),
        GalleryItem(
          label: 'custom trigger',
          child: GhColorSwatchPicker(
            value: _accent,
            onChanged: (hex) => setState(() => _accent = hex),
            presets: workspaceColorPresets,
            trigger: (context, open, toggle) => GhButton(
              onPressed: toggle,
              label: open ? 'Close picker' : 'Pick color',
              icon: GhIcons.palette,
              variant: GhButtonVariant.outline,
              size: GhTextSize.xs,
              paddingX: 3,
              paddingY: 2,
            ),
          ),
        ),
      ],
    );
  }
}

class _Reusables extends StatefulWidget {
  const _Reusables();

  @override
  State<_Reusables> createState() => _ReusablesState();
}

class _ReusablesState extends State<_Reusables> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return GalleryGroup(
      title: 'Reusables',
      spacing: 32,
      children: [
        GalleryItem(
          label: 'disclosure',
          child: SizedBox(
            width: 240,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GhSidebarGroupHeader(group: _library, open: _open, onPressed: () => setState(() => _open = !_open)),
                GhDisclosure(
                  open: _open,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final line in ['Templates', 'Vault', 'Storage'])
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(line, style: theme.text(color: theme.muted)),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        GalleryItem(
          label: 'overlay scroll area',
          child: Container(
            width: 260,
            height: 220,
            decoration: BoxDecoration(color: theme.raised, borderRadius: BorderRadius.circular(theme.radiusCard)),
            clipBehavior: Clip.antiAlias,
            child: GhOverlayScrollArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 1; i <= 40; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Row $i',
                          style: theme.text(size: GhTextSize.xs, color: theme.muted),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        GalleryItem(
          label: 'chevrons',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [GhDisclosureChevron(open: false), SizedBox(width: 12), GhDisclosureChevron(open: true)],
          ),
        ),
      ],
    );
  }
}
