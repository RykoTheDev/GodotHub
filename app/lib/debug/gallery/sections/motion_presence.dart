import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../design/design.dart';
import '../../../motion/presence.dart';
import '../../../motion/shared.dart';
import '../../../ui/core/button.dart';
import '../../../ui/core/tooltip.dart';
import '../../../ui/core/ui_settings.dart';
import '../../../ui/feedback/feedback.dart';
import '../../../ui/overlays/context_menu.dart';
import '../../../ui/overlays/dropdown.dart';
import '../../../ui/overlays/menu.dart';
import '../../../ui/overlays/slash_menu.dart';
import '../../../ui/shell/disclosure.dart';
import '../../../ui/shell/sidebar.dart';
import '../gallery_kit.dart';

final motionPresenceSections = <GallerySection>[
  GallerySection('Presence: modal', (context) => const _ModalPresence()),
  GallerySection('Presence: popovers', (context) => const _PopoverPresence()),
  GallerySection('Presence: tooltip', (context) => const _TooltipPresence()),
  GallerySection('Presence: toast', (context) => const _ToastPresence()),
  GallerySection('Presence: panel, backdrop, splash', (context) => const _PanelPresence()),
  GallerySection('Presence: workspace notice', (context) => const _NoticePresence()),
  GallerySection('Presence: shared pill & sidebar', (context) => const _SharedPresence()),
  GallerySection('Presence: disclosure & image', (context) => const _DisclosurePresence()),
];

class _Stage extends StatelessWidget {
  const _Stage({required this.width, required this.height, required this.child});

  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.base,
        borderRadius: BorderRadius.circular(theme.radiusLg),
        border: Border.all(color: theme.line),
      ),
      child: child,
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: children);
}

GhButton _button(String label, VoidCallback onPressed, {bool primary = false}) =>
    GhButton(onPressed: onPressed, label: label, variant: primary ? GhButtonVariant.primary : GhButtonVariant.outline);

class _ModalPresence extends StatelessWidget {
  const _ModalPresence();

  void _open(BuildContext context, {int lines = 3}) {
    showGhModal<void>(
      context,
      (context) => GhModalShell(
        icon: GhIcon(GhIcons.star, size: 20, color: GhTheme.of(context).accentBright),
        title: 'Presence demo',
        maxWidth: GhModalWidth.lg,
        onClose: () => Navigator.of(context).pop(),
        footer: [
          const Spacer(),
          GhButton(onPressed: () => Navigator.of(context).pop(), label: 'Cancel'),
          GhButton(onPressed: () => Navigator.of(context).pop(), label: 'Save', variant: GhButtonVariant.primary),
        ],
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              for (var i = 0; i < lines; i++)
                Text('Line ${i + 1}: the panel rises 18px and scales from 0.96 while header, body and footer cascade.'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GalleryGroup(
      title: 'Modal (overlay 0.2 power3.out, panel 0.36 expo.out, parts cascade at 0.05)',
      children: [
        _Controls(
          children: [
            _button('Open modal', () => _open(context), primary: true),
            _button('Open tall modal', () => _open(context, lines: 12)),
            _button(
              'Open confirm',
              () => showGhConfirmDialog(
                context,
                title: 'Delete project?',
                description: 'The confirm dialog uses the same modal presence.',
                confirmLabel: 'Delete',
                variant: GhConfirmVariant.danger,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

const _menuItems = [
  GhMenuItem(id: 'open', label: 'Open', icon: GhIcons.folder),
  GhMenuItem(id: 'rename', label: 'Rename', icon: GhIcons.pencil),
  GhMenuItem(
    id: 'more',
    label: 'More',
    icon: GhIcons.star,
    children: [
      GhMenuItem(id: 'duplicate', label: 'Duplicate'),
      GhMenuItem(id: 'export', label: 'Export'),
      GhMenuItem(id: 'archive', label: 'Archive'),
    ],
  ),
  GhMenuItem(id: 'pin', label: 'Pin', icon: GhIcons.star, dividerAfter: true),
  GhMenuItem(id: 'delete', label: 'Delete', icon: GhIcons.trash, danger: true),
];

const _slashItems = [
  GhSlashMenuItem(id: 'todo', label: 'To-do', hint: '/todo', icon: GhIcons.check),
  GhSlashMenuItem(id: 'heading', label: 'Heading', hint: '/h1', icon: GhIcons.pencil),
  GhSlashMenuItem(id: 'quote', label: 'Quote', hint: '/quote', icon: GhIcons.news),
  GhSlashMenuItem(id: 'code', label: 'Code', hint: '/code', icon: GhIcons.code),
];

class _PopoverPresence extends StatefulWidget {
  const _PopoverPresence();

  @override
  State<_PopoverPresence> createState() => _PopoverPresenceState();
}

class _PopoverPresenceState extends State<_PopoverPresence> {
  bool _slashOpen = false;
  int _slashSelected = 0;

  Widget _trigger(String label, bool open, VoidCallback toggle) =>
      GhButton(onPressed: toggle, label: open ? '$label (open)' : label, variant: GhButtonVariant.outline);

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GalleryGroup(
          title: 'Dropdown (0.28 expo.out, items 0.24 power3.out stagger, exit 0.15 power2.in)',
          children: [
            GhDropdown(trigger: (context, open, toggle) => _trigger('Open below', open, toggle), items: _menuItems),
            GhDropdown(side: GhSide.top, trigger: (context, open, toggle) => _trigger('Open above', open, toggle), items: _menuItems),
            GhDropdown(align: GhSide.left, trigger: (context, open, toggle) => _trigger('Align left', open, toggle), items: _menuItems),
          ],
        ),
        GalleryGroup(
          title: 'Context menu',
          children: [
            GhContextMenuArea(
              items: () => _menuItems.where((item) => !item.hasChildren).toList(),
              child: _Stage(
                width: 360,
                height: 140,
                child: Center(
                  child: Text('Right click anywhere here', style: theme.text(color: theme.muted)),
                ),
              ),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Slash menu',
          children: [
            _button(_slashOpen ? 'Close slash menu' : 'Open slash menu', () => setState(() => _slashOpen = !_slashOpen)),
            SizedBox(
              width: 280,
              child: GhSlashMenuAnchor(
                open: _slashOpen,
                menu: GhSlashMenu(
                  title: 'Commands',
                  items: _slashItems,
                  selectedIndex: _slashSelected,
                  emptyLabel: 'No matches',
                  onHighlight: (index) => setState(() => _slashSelected = index),
                  onSelect: (_, _) => setState(() => _slashOpen = false),
                ),
                child: Container(
                  height: 36,
                  alignment: AlignmentDirectional.centerStart,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.overlay,
                    borderRadius: BorderRadius.circular(theme.radiusItem),
                    border: Border.all(color: theme.outline),
                  ),
                  child: Text('/', style: theme.text(color: theme.muted, mono: true)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TooltipPresence extends StatelessWidget {
  const _TooltipPresence();

  @override
  Widget build(BuildContext context) {
    return GalleryGroup(
      title: 'Tooltip (0.32 back.out(2.6) from the arrow edge, exit 0.14 power2.in), hover a button',
      spacing: 40,
      children: [
        for (final side in GhSide.values) GhTooltip(message: 'Tooltip on ${side.name}', side: side, child: _button(side.name, () {})),
      ],
    );
  }
}

class _ToastPresence extends StatefulWidget {
  const _ToastPresence();

  @override
  State<_ToastPresence> createState() => _ToastPresenceState();
}

class _ToastPresenceState extends State<_ToastPresence> {
  final GhToastStore _store = GhToastStore();
  int _count = 0;

  @override
  void dispose() {
    _store.clear();
    super.dispose();
  }

  void _push(GhToastType type) {
    _count += 1;
    _store.pushToast(
      type,
      'Toast number $_count enters with back.out(1.5) and leaves with a collapse.',
      action: type == GhToastType.success ? GhToastAction(label: 'Undo', onClick: () {}) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GalleryGroup(
          title: 'Toast (enter 0.8 back.out(1.5), leave 0.45 power3.in, leave runs even with motion off)',
          children: [
            _Controls(
              children: [
                _button('Success', () => _push(GhToastType.success), primary: true),
                _button('Info', () => _push(GhToastType.info)),
                _button('Error', () => _push(GhToastType.error)),
                _button('Dismiss oldest', () {
                  final toasts = _store.toasts;
                  if (toasts.isNotEmpty) {
                    _store.dismissToast(toasts.first.id);
                  }
                }),
                _button('Dismiss all', _store.clear),
              ],
            ),
          ],
        ),
        _Stage(
          width: 520,
          height: 360,
          child: GhToastHost(store: _store, child: const SizedBox.expand()),
        ),
      ],
    );
  }
}

class _PanelPresence extends StatefulWidget {
  const _PanelPresence();

  @override
  State<_PanelPresence> createState() => _PanelPresenceState();
}

class _PanelPresenceState extends State<_PanelPresence> {
  bool _panel = false;
  bool _splash = true;
  int _splashKey = 0;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GalleryGroup(
          title: 'Side panel (0.7 expo.out, exit 0.42 power3.in) over a backdrop (0.4 power3.out, exit 0.35 power1.out)',
          children: [_button(_panel ? 'Close panel' : 'Open panel', () => setState(() => _panel = !_panel), primary: true)],
        ),
        _Stage(
          width: 640,
          height: 300,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Text('Workspace content', style: theme.text(color: theme.muted)),
              ),
              GhPresence(
                visible: _panel,
                kind: GhPresenceKind.backdrop,
                child: GestureDetector(
                  onTap: () => setState(() => _panel = false),
                  child: const ColoredBox(color: Color(0x99000000)),
                ),
              ),
              PositionedDirectional(
                top: 0,
                bottom: 0,
                end: 0,
                width: 260,
                child: GhPresence(
                  visible: _panel,
                  kind: GhPresenceKind.panel,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: theme.surface,
                    child: Text('Side panel', style: theme.text(weight: GhWeight.semibold)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        GalleryGroup(
          title: 'Splash exit (0.75 power2.inOut, scale 1.08, blur 12 when blur is allowed)',
          children: [
            _button('Hide splash', () => setState(() => _splash = false), primary: true),
            _button(
              'Reset splash',
              () => setState(() {
                _splash = true;
                _splashKey += 1;
              }),
            ),
          ],
        ),
        _Stage(
          width: 640,
          height: 220,
          child: GhPresence(
            key: ValueKey(_splashKey),
            visible: _splash,
            kind: GhPresenceKind.splash,
            child: ColoredBox(
              color: theme.surface,
              child: Center(
                child: Text(
                  'GodotHub',
                  style: theme.text(size: GhTextSize.x3l, weight: GhWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

const _noticeWorkspaces = [
  GhWorkspaceRef(id: 'work', name: 'Work', icon: 'briefcase'),
  GhWorkspaceRef(id: 'personal', name: 'Personal', icon: 'house'),
  GhWorkspaceRef(id: 'jam', name: 'Game Jam', icon: 'gamepad'),
];

class _NoticePresence extends StatefulWidget {
  const _NoticePresence();

  @override
  State<_NoticePresence> createState() => _NoticePresenceState();
}

class _NoticePresenceState extends State<_NoticePresence> {
  String _active = 'work';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GalleryGroup(
          title: 'Workspace switch notice (in 0.4 back.out(1.8), hold 1.1 s, out 0.3 power2.in; 1.5 s static with motion off)',
          children: [
            for (final workspace in _noticeWorkspaces)
              _button(workspace.name, () => setState(() => _active = workspace.id), primary: workspace.id == _active),
          ],
        ),
        _Stage(
          width: 640,
          height: 280,
          child: GhWorkspaceSwitchNotice(activeId: _active, workspaces: _noticeWorkspaces),
        ),
      ],
    );
  }
}

const _demoTabs = [
  (id: 'dashboard', label: 'Dashboard', icon: GhIcons.layoutGrid),
  (id: 'projects', label: 'Projects', icon: GhIcons.folder),
  (id: 'versions', label: 'Versions', icon: GhIcons.download),
  (id: 'news', label: 'News', icon: GhIcons.news),
];

const _library = GhSidebarGroup(id: 'library', label: 'Library', icon: GhIcons.book);

const _sidebarTabs = [
  GhSidebarTab(id: 'dashboard', label: 'Dashboard', icon: GhIcons.layoutGrid, shortcut: 1),
  GhSidebarTab(id: 'projects', label: 'Projects', icon: GhIcons.folder, shortcut: 2, badge: 3),
  GhSidebarTab(id: 'versions', label: 'Versions', icon: GhIcons.download, shortcut: 3),
  GhSidebarTab(id: 'templates', label: 'Templates', icon: GhIcons.clone, group: _library, shortcut: 4),
  GhSidebarTab(id: 'vault', label: 'Vault', icon: GhIcons.lock, group: _library, isNew: true),
  GhSidebarTab(id: 'storage', label: 'Storage', icon: GhIcons.hardDrive, group: _library, badge: 12),
  GhSidebarTab(id: 'news', label: 'Godot News', icon: GhIcons.news),
];

class _SharedPresence extends StatefulWidget {
  const _SharedPresence();

  @override
  State<_SharedPresence> createState() => _SharedPresenceState();
}

class _SharedPresenceState extends State<_SharedPresence> {
  final Object _tag = Object();
  String _activeChip = 'projects';
  String _activeTab = 'projects';
  bool _vertical = false;
  int _sidebarKey = 0;

  @override
  void dispose() {
    GhSharedElements.forget(_tag);
    super.dispose();
  }

  Widget _chip(GhTheme theme, ({String id, String label, FaIconData icon}) tab) {
    final active = tab.id == _activeChip;
    final radius = BorderRadius.circular(theme.radiusItem);
    return GestureDetector(
      onTap: () => setState(() => _activeChip = tab.id),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Stack(
          children: [
            if (active)
              Positioned.fill(
                child: GhShared(
                  tag: _tag,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.overlay,
                      borderRadius: radius,
                      border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                      boxShadow: GhShadows.md(),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: _vertical ? 12 : 16, vertical: _vertical ? 12 : 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  GhSharedIcon(
                    tag: _tag,
                    enabled: active,
                    child: GhIcon(tab.icon, size: 16, color: active ? theme.accent : theme.muted),
                  ),
                  Text(
                    tab.label,
                    style: theme.text(size: GhTextSize.sm, color: active ? theme.ink : theme.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final chips = [for (final tab in _demoTabs) _chip(theme, tab)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GalleryGroup(
          title: 'Shared pill (FLIP 0.6 expo.out from the rect measured on pointer down, icon 0.9 elastic after 0.12)',
          children: [
            _button(_vertical ? 'Horizontal layout' : 'Vertical layout', () => setState(() => _vertical = !_vertical)),
            _Stage(
              width: 640,
              height: _vertical ? 220 : 80,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _vertical
                    ? Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: chips)
                    : Wrap(spacing: 4, runSpacing: 4, children: chips),
              ),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Sidebar (active pill morph, label stagger on expand, disclosure item stagger)',
          children: [
            _button('Remount sidebar', () => setState(() => _sidebarKey += 1)),
            SizedBox(
              height: 560,
              child: GhSidebar(
                key: ValueKey(_sidebarKey),
                tabs: _sidebarTabs,
                activeTab: _activeTab,
                onTabChange: (id) => setState(() => _activeTab = id),
                onOpenCommandPalette: () {},
                updateAvailable: true,
                onOpenUpdatesModal: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DisclosurePresence extends StatefulWidget {
  const _DisclosurePresence();

  @override
  State<_DisclosurePresence> createState() => _DisclosurePresenceState();
}

class _DisclosurePresenceState extends State<_DisclosurePresence> {
  bool _open = false;
  int _imageKey = 0;
  ImageProvider? _image;

  @override
  void initState() {
    super.initState();
    _makeImage();
  }

  Future<void> _makeImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(240, 150);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(size.width, size.height), const [Color(0xFF478CBF), Color(0xFFEB459E)]),
    );
    canvas.drawCircle(const Offset(170, 60), 34, Paint()..color = const Color(0xCCFFFFFF));
    final image = await recorder.endRecording().toImage(size.width.toInt(), size.height.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (!mounted || data == null) {
      return;
    }
    setState(() => _image = MemoryImage(Uint8List.fromList(data.buffer.asUint8List())));
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final image = _image;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GalleryGroup(
          title: 'Disclosure (height 0.4 expo.out, items y -6 stagger 0.32, close 0.26 power3.out)',
          children: [
            _button(_open ? 'Collapse' : 'Expand', () => setState(() => _open = !_open), primary: true),
            SizedBox(
              width: 320,
              child: GhDisclosure(
                open: _open,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 6; i++)
                      GhDisclosureItem(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: theme.overlay, borderRadius: BorderRadius.circular(theme.radiusItem)),
                          child: Text('Item ${i + 1}', style: theme.text(size: GhTextSize.sm)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Image fade-in (opacity, scale 1.06, blur 8 to identity over 0.7 expo.out on first frame)',
          children: [
            _button('Reload image', () {
              setState(() => _imageKey += 1);
              _makeImage();
            }),
            SizedBox(
              width: 240,
              height: 150,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(theme.radiusCard),
                child: image == null
                    ? ColoredBox(color: theme.overlay)
                    : GhFadeInImage(key: ValueKey(_imageKey), image: image, fit: BoxFit.cover),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
