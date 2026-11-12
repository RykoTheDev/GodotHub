import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/design.dart';
import '../../../ui/core/button.dart';
import '../../../ui/core/interaction.dart';
import '../../../ui/core/ui_settings.dart';
import '../../../ui/overlays/context_menu.dart';
import '../../../ui/overlays/date_picker.dart';
import '../../../ui/overlays/dropdown.dart';
import '../../../ui/overlays/menu.dart';
import '../../../ui/overlays/popup_registry.dart';
import '../../../ui/overlays/slash_menu.dart';
import '../gallery_kit.dart';

final overlaysSections = [
  GallerySection('Dropdown', (context) => const _DropdownSection()),
  GallerySection('Menu items', (context) => const _MenuItemsSection()),
  GallerySection('Context menu', (context) => const _ContextMenuSection()),
  GallerySection('Slash menu', (context) => const _SlashMenuSection()),
  GallerySection('Date picker', (context) => const _DatePickerSection()),
];

void _noop() {}

List<GhMenuItem> _sampleItems() => [
  const GhMenuItem(id: 'open', label: 'Open project', icon: GhIcons.folder, onSelected: _noop, shortcut: 'Ctrl+O'),
  const GhMenuItem(id: 'run', label: 'Run', icon: GhIcons.play, onSelected: _noop, active: true),
  const GhMenuItem(id: 'star', label: 'Favorite', icon: GhIcons.star, onSelected: _noop, badge: 'New', dividerAfter: true),
  const GhMenuItem(id: 'terminal', label: 'Open terminal', icon: GhIcons.terminal, disabled: true),
  GhMenuItem(
    id: 'more',
    label: 'More actions',
    icon: GhIcons.more,
    children: const [
      GhMenuItem(id: 'copy', label: 'Copy path', icon: GhIcons.copy, onSelected: _noop),
      GhMenuItem(id: 'code', label: 'Open in editor', icon: GhIcons.code, onSelected: _noop, dividerAfter: true),
      GhMenuItem(id: 'link', label: 'Reveal online', icon: GhIcons.externalLink, onSelected: _noop),
    ],
    dividerAfter: true,
  ),
  const GhMenuItem(id: 'delete', label: 'Delete', icon: GhIcons.trash, danger: true, onSelected: _noop),
];

Widget _triggerButton(String label, bool open, VoidCallback? toggle) {
  return GhButton(
    onPressed: toggle,
    label: open ? '$label (open)' : label,
    icon: GhIcons.chevronDown,
    variant: GhButtonVariant.outline,
    size: GhTextSize.xs,
    paddingX: 3,
    paddingY: 2,
  );
}

class _OpenCount extends StatelessWidget {
  const _OpenCount();

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: GhPopupRegistry.openMenuCount,
      builder: (context, count, _) => Text(
        'GhPopupRegistry.openMenuCount = $count',
        style: theme.text(size: GhTextSize.x2s, mono: true, color: theme.muted),
      ),
    );
  }
}

class _DropdownSection extends StatelessWidget {
  const _DropdownSection();

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _OpenCount(),
        const SizedBox(height: 16),
        GalleryGroup(
          title: 'Trigger states',
          children: [
            GalleryStates(
              builder: (context, enabled) => GhDropdown(
                trigger: (context, open, toggle) => _triggerButton('Actions', open, enabled ? toggle : null),
                items: _sampleItems(),
              ),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Placement',
          children: [
            GalleryItem(
              label: 'align right · bottom',
              child: GhDropdown(trigger: (context, open, toggle) => _triggerButton('Right', open, toggle), items: _sampleItems()),
            ),
            GalleryItem(
              label: 'align left · bottom',
              child: GhDropdown(
                align: GhSide.left,
                trigger: (context, open, toggle) => _triggerButton('Left', open, toggle),
                items: _sampleItems(),
              ),
            ),
            GalleryItem(
              label: 'side top',
              child: GhDropdown(
                side: GhSide.top,
                align: GhSide.left,
                trigger: (context, open, toggle) => _triggerButton('Top', open, toggle),
                items: _sampleItems(),
              ),
            ),
            GalleryItem(
              label: 'side left · compact',
              child: GhDropdown(
                side: GhSide.left,
                compact: true,
                trigger: (context, open, toggle) => _triggerButton('Side', open, toggle),
                items: _sampleItems(),
              ),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Variants',
          children: [
            GalleryItem(
              label: 'header + actions',
              child: GhDropdown(
                trigger: (context, open, toggle) => _triggerButton('Header', open, toggle),
                header: const [
                  GhDropdownHeaderItem(id: 'search', icon: GhIcons.search, label: 'Search', onPressed: _noop),
                  GhDropdownHeaderItem(id: 'filter', icon: GhIcons.filter, label: 'Filter', tooltip: 'Filter list', onPressed: _noop),
                  GhDropdownHeaderItem(id: 'settings', icon: GhIcons.gear, label: 'Settings', onPressed: _noop),
                ],
                items: const [
                  GhMenuItem(
                    id: 'a',
                    label: 'Godot 4.3 stable',
                    dotColor: Color(0xFF2FBF71),
                    onSelected: _noop,
                    action: GhMenuItemAction(icon: GhIcons.trash, label: 'Remove', onPressed: _noop),
                  ),
                  GhMenuItem(
                    id: 'b',
                    label: 'Godot 4.4 beta 2',
                    dotColor: Color(0xFFF0B132),
                    onSelected: _noop,
                    active: true,
                    action: GhMenuItemAction(icon: GhIcons.trash, label: 'Remove', onPressed: _noop),
                  ),
                ],
              ),
            ),
            GalleryItem(
              label: 'compact · raised active · min-w-40',
              child: GhDropdown(
                compact: true,
                activeStyle: GhMenuActiveStyle.raised,
                menuMinWidth: theme.space(40),
                trigger: (context, open, toggle) => _triggerButton('Status', open, toggle),
                items: const [
                  GhMenuItem(id: 'todo', label: 'To do', dotColor: Color(0xFF9AA3B2), onSelected: _noop),
                  GhMenuItem(id: 'doing', label: 'In progress', dotColor: Color(0xFF4F7CFF), onSelected: _noop, active: true),
                  GhMenuItem(id: 'done', label: 'Done', dotColor: Color(0xFF2FBF71), onSelected: _noop),
                ],
              ),
            ),
            GalleryItem(
              label: 'custom content (account menu)',
              child: GhDropdown(
                side: GhSide.top,
                align: GhSide.left,
                trigger: (context, open, toggle) => _triggerButton('Account', open, toggle),
                content: (context, close) => _AccountHeader(onManage: close),
                items: const [
                  GhMenuItem(id: 'changelog', label: 'Changelog', icon: GhIcons.bookOpen, badge: 'New', onSelected: _noop),
                  GhMenuItem(id: 'bug', label: 'Report a bug', icon: GhIcons.bug, danger: true, onSelected: _noop),
                  GhMenuItem(id: 'support', label: 'Support', icon: GhIcons.heart, onSelected: _noop),
                ],
              ),
            ),
            GalleryItem(
              label: 'nested dropdown in content',
              child: GhDropdown(
                align: GhSide.left,
                trigger: (context, open, toggle) => _triggerButton('Outer', open, toggle),
                content: (context, close) => Padding(
                  padding: const EdgeInsets.all(8),
                  child: GhDropdown(
                    align: GhSide.left,
                    trigger: (context, open, toggle) => _triggerButton('Inner', open, toggle),
                    items: _sampleItems(),
                  ),
                ),
              ),
            ),
            GalleryItem(
              label: 'expand (w-full)',
              child: SizedBox(
                width: 260,
                child: GhDropdown(
                  align: GhSide.left,
                  expand: true,
                  trigger: (context, open, toggle) => GhButton(
                    onPressed: toggle,
                    label: 'Full width trigger',
                    variant: GhButtonVariant.outline,
                    size: GhTextSize.xs,
                    expand: true,
                  ),
                  items: _sampleItems(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AccountHeader extends StatefulWidget {
  const _AccountHeader({required this.onManage});

  final VoidCallback onManage;

  @override
  State<_AccountHeader> createState() => _AccountHeaderState();
}

class _AccountHeaderState extends State<_AccountHeader> {
  final _manageNode = GhMenuItemFocusNode(debugLabel: 'manage');

  @override
  void dispose() {
    _manageNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: theme.space(1)),
      padding: EdgeInsets.only(top: theme.space(1.5), bottom: theme.space(2.5)),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: GhMenuColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: theme.space(2.5)),
            child: Text(
              'You',
              style: theme.text(size: GhTextSize.xl, weight: FontWeight.w900, color: theme.ink),
            ),
          ),
          SizedBox(height: theme.space(2)),
          GhPressable(
            onPressed: widget.onManage,
            focusNode: _manageNode,
            builder: (context, states) => GhAnimatedBox(
              height: theme.space(7),
              padding: EdgeInsets.symmetric(horizontal: theme.space(3)),
              color: states.hovered ? theme.raised : theme.raised.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  GhIcon(GhIcons.plug, size: theme.space(3.5), color: states.hovered ? theme.ink : theme.muted),
                  SizedBox(width: theme.space(2)),
                  Expanded(
                    child: Text(
                      'Manage accounts',
                      style: theme.text(size: GhTextSize.xs, color: states.hovered ? theme.ink : theme.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemsSection extends StatelessWidget {
  const _MenuItemsSection();

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    Widget row(
      String label,
      GhMenuItem item, {
      bool compact = false,
      bool hovered = false,
      bool focused = false,
      bool caret = false,
      GhMenuActiveStyle style = GhMenuActiveStyle.accent,
    }) {
      return GalleryItem(
        label: label,
        child: GhMenuSurface(
          compact: compact,
          child: GhForcedStates(
            hovered: hovered,
            focused: focused,
            child: GhMenuButton(item: item, compact: compact, caret: caret, activeStyle: style, onSelect: _noop),
          ),
        ),
      );
    }

    const plain = GhMenuItem(id: 'p', label: 'Open project', icon: GhIcons.folder, onSelected: _noop);
    const danger = GhMenuItem(id: 'd', label: 'Delete', icon: GhIcons.trash, danger: true, onSelected: _noop);
    const active = GhMenuItem(id: 'a', label: 'Selected', icon: GhIcons.check, active: true, badge: 'Current', onSelected: _noop);
    const disabled = GhMenuItem(id: 'x', label: 'Unavailable', icon: GhIcons.terminal, disabled: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GalleryGroup(
          title: 'Item states',
          children: [
            row('normal', plain),
            row('hover', plain, hovered: true),
            row('focus', plain, focused: true),
            row('disabled', disabled),
            row('disabled hover', disabled, hovered: true),
            row('danger', danger),
            row('danger hover', danger, hovered: true),
            row('active (checked)', active),
            row('active raised style', active, style: GhMenuActiveStyle.raised),
          ],
        ),
        GalleryGroup(
          title: 'Item parts',
          children: [
            row('shortcut', const GhMenuItem(id: 's', label: 'Save', shortcut: 'Ctrl+S', onSelected: _noop)),
            row('badge', const GhMenuItem(id: 'b', label: 'Changelog', icon: GhIcons.bookOpen, badge: 'New', onSelected: _noop)),
            row('dot', const GhMenuItem(id: 'c', label: 'Category', dotColor: Color(0xFFF0B132), onSelected: _noop)),
            row(
              'leading',
              GhMenuItem(
                id: 'l',
                label: 'Workspace',
                leading: Container(
                  width: theme.space(5),
                  height: theme.space(5),
                  decoration: BoxDecoration(color: theme.accent, borderRadius: BorderRadius.circular(theme.radiusSm)),
                ),
                onSelected: _noop,
              ),
            ),
            row(
              'caret',
              const GhMenuItem(
                id: 'm',
                label: 'More actions',
                icon: GhIcons.more,
                children: [GhMenuItem(id: 'c', label: 'c')],
              ),
              caret: true,
            ),
            row('compact', plain, compact: true),
            row('compact hover', plain, compact: true, hovered: true),
          ],
        ),
        GalleryGroup(
          title: 'Open menu with submenu (static)',
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GhMenuSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final item in _sampleItems()) ...[
                        GhForcedStates(
                          hovered: item.id == 'more',
                          child: GhMenuButton(item: item, caret: item.hasChildren, onSelect: _noop),
                        ),
                        if (item.dividerAfter) const GhMenuDivider(),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 10 + ghMenuGap),
                Padding(
                  padding: const EdgeInsets.only(top: 140),
                  child: GhMenuSurface(
                    compact: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final child in _sampleItems().firstWhere((i) => i.id == 'more').children) ...[
                          GhMenuButton(item: child, compact: true, onSelect: _noop),
                          if (child.dividerAfter) const GhMenuDivider(compact: true),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _ContextMenuSection extends StatelessWidget {
  const _ContextMenuSection();

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    List<GhMenuItem> items() => const [
      GhMenuItem(id: 'open', label: 'Open', icon: GhIcons.folder, onSelected: _noop),
      GhMenuItem(id: 'rename', label: 'Rename', icon: GhIcons.pencil, onSelected: _noop, shortcut: 'F2'),
      GhMenuItem(id: 'pin', label: 'Pinned', icon: GhIcons.pin, active: true, onSelected: _noop, dividerAfter: true),
      GhMenuItem(
        id: 'more',
        label: 'More',
        icon: GhIcons.more,
        children: [GhMenuItem(id: 'x', label: 'x')],
      ),
      GhMenuItem(id: 'archive', label: 'Archive', disabled: true, dividerAfter: true),
      GhMenuItem(id: 'delete', label: 'Delete', icon: GhIcons.trash, danger: true, onSelected: _noop),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _OpenCount(),
        const SizedBox(height: 16),
        GalleryGroup(
          title: 'Live',
          children: [
            GalleryItem(
              label: 'right-click the box',
              child: GhContextMenuArea(
                label: 'Project actions',
                items: items,
                child: Container(
                  width: 280,
                  height: 140,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(theme.radiusCard),
                    border: Border.all(color: theme.line),
                  ),
                  child: Text(
                    'Right-click here',
                    style: theme.text(size: GhTextSize.xs, color: theme.muted),
                  ),
                ),
              ),
            ),
            GalleryItem(
              label: 'compact',
              child: GhContextMenuArea(
                compact: true,
                items: items,
                child: Container(
                  width: 200,
                  height: 140,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(theme.radiusCard),
                    border: Border.all(color: theme.line),
                  ),
                  child: Text(
                    'Compact menu',
                    style: theme.text(size: GhTextSize.xs, color: theme.muted),
                  ),
                ),
              ),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Static',
          children: [
            for (final compact in const [false, true])
              GalleryItem(
                label: compact ? 'compact' : 'regular',
                child: GhMenuSurface(
                  compact: compact,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final item in items()) ...[
                        GhForcedStates(
                          hovered: item.id == 'rename',
                          child: GhMenuButton(item: item, compact: compact, caret: item.hasChildren, onSelect: _noop),
                        ),
                        if (item.dividerAfter) GhMenuDivider(compact: compact),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

const _slashItems = [
  GhSlashMenuItem(id: 'todo', label: 'Todo', hint: '/todo', icon: GhIcons.check),
  GhSlashMenuItem(id: 'note', label: 'Note', hint: '/note', icon: GhIcons.pencil),
  GhSlashMenuItem(id: 'bug', label: 'Bug', hint: '/bug', dotColor: Color(0xFFF2555A)),
  GhSlashMenuItem(id: 'idea', label: 'Idea', hint: '/idea', dotColor: Color(0xFFF0B132)),
];

class _SlashMenuSection extends StatefulWidget {
  const _SlashMenuSection();

  @override
  State<_SlashMenuSection> createState() => _SlashMenuSectionState();
}

class _SlashMenuSectionState extends State<_SlashMenuSection> {
  final _controller = TextEditingController();
  int _selected = 0;
  int _staticSelected = 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<GhSlashMenuItem> get _filtered {
    final text = _controller.text;
    if (!text.startsWith('/')) {
      return const [];
    }
    final query = text.substring(1).toLowerCase();
    return _slashItems.where((item) => item.label.toLowerCase().contains(query)).toList();
  }

  void _insert(GhSlashMenuItem item) {
    _controller.text = '${item.label}: ';
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    setState(() => _selected = 0);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final items = _filtered;
    if (items.isEmpty || (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _selected = (_selected + 1) % items.length);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() => _selected = (_selected - 1 + items.length) % items.length);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _insert(items[_selected.clamp(0, items.length - 1)]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final filtered = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GalleryGroup(
          title: 'Static',
          children: [
            GalleryItem(
              label: 'items · hover changes highlight',
              child: SizedBox(
                width: 320,
                child: GhSlashMenu(
                  title: 'Commands',
                  footer: '↑↓ to navigate · Enter to insert',
                  items: _slashItems,
                  selectedIndex: _staticSelected,
                  emptyLabel: 'No matches',
                  onHighlight: (index) => setState(() => _staticSelected = index),
                  onSelect: (_, index) => setState(() => _staticSelected = index),
                ),
              ),
            ),
            GalleryItem(
              label: 'empty',
              child: SizedBox(
                width: 320,
                child: GhSlashMenu(
                  title: 'Commands',
                  items: const [],
                  selectedIndex: 0,
                  emptyLabel: 'No matches',
                  onHighlight: (_) {},
                  onSelect: (_, _) {},
                ),
              ),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Live (type / in the field)',
          children: [
            SizedBox(
              width: 360,
              child: GhSlashMenuAnchor(
                open: _controller.text.startsWith('/'),
                menu: GhSlashMenu(
                  title: 'Commands',
                  footer: '↑↓ to navigate · Enter to insert',
                  items: filtered,
                  selectedIndex: _selected,
                  emptyLabel: 'No matches',
                  onHighlight: (index) => setState(() => _selected = index),
                  onSelect: (item, _) => _insert(item),
                ),
                child: Focus(
                  onKeyEvent: _onKey,
                  child: TextField(
                    controller: _controller,
                    onChanged: (_) => setState(() => _selected = 0),
                    style: theme.text(size: GhTextSize.sm),
                    decoration: InputDecoration(
                      hintText: 'Type / for commands',
                      hintStyle: theme.text(size: GhTextSize.sm, color: theme.placeholder),
                      filled: true,
                      fillColor: theme.overlay,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(theme.radiusItem),
                        borderSide: BorderSide(color: theme.outline.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DatePickerSection extends StatefulWidget {
  const _DatePickerSection();

  @override
  State<_DatePickerSection> createState() => _DatePickerSectionState();
}

class _DatePickerSectionState extends State<_DatePickerSection> {
  String _value = ghDateToValue(DateTime.now());
  String _empty = '';
  String _compact = '';
  String _past = ghDateToValue(DateTime.now().subtract(const Duration(days: 3)));
  DateTime _view = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final today = ghDateToValue(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GalleryGroup(
          title: 'Triggers',
          children: [
            GalleryItem(
              label: 'with value',
              child: SizedBox(
                width: 240,
                child: GhDatePicker(
                  value: _value,
                  placeholder: 'Pick a date',
                  clearLabel: 'Clear date',
                  onChanged: (v) => setState(() => _value = v),
                ),
              ),
            ),
            GalleryItem(
              label: 'placeholder',
              child: SizedBox(
                width: 240,
                child: GhDatePicker(
                  value: _empty,
                  placeholder: 'Pick a date',
                  clearLabel: 'Clear date',
                  onChanged: (v) => setState(() => _empty = v),
                ),
              ),
            ),
            GalleryItem(
              label: 'past date marked',
              child: SizedBox(
                width: 240,
                child: GhDatePicker(
                  value: _past,
                  placeholder: 'Pick a date',
                  clearLabel: 'Clear date',
                  markPastDates: true,
                  pastDateMessage: 'This date is in the past',
                  onChanged: (v) => setState(() => _past = v),
                ),
              ),
            ),
            GalleryItem(
              label: 'disabled',
              child: SizedBox(
                width: 240,
                child: GhDatePicker(value: _value, placeholder: 'Pick a date', clearLabel: 'Clear date', disabled: true, onChanged: (_) {}),
              ),
            ),
            GalleryStates(
              states: const [GalleryState.normal, GalleryState.hover, GalleryState.focus],
              builder: (context, enabled) => GhDatePicker(
                value: _compact,
                placeholder: 'Due',
                clearLabel: 'Clear date',
                compact: true,
                onChanged: (v) => setState(() => _compact = v),
              ),
            ),
            GalleryItem(
              label: 'compact disabled',
              child: GhDatePicker(
                value: _value,
                placeholder: 'Due',
                clearLabel: 'Clear date',
                compact: true,
                disabled: true,
                onChanged: (_) {},
              ),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Calendar (static)',
          children: [
            GalleryItem(
              label: 'selected + clear',
              child: GhDatePickerPanel(
                viewDate: _view,
                value: _value,
                todayValue: today,
                clearLabel: 'Clear date',
                onSelect: (date) => setState(() => _value = ghDateToValue(date)),
                onClear: () => setState(() => _value = ''),
                onPreviousMonth: () => setState(() => _view = DateTime(_view.year, _view.month - 1, 1)),
                onNextMonth: () => setState(() => _view = DateTime(_view.year, _view.month + 1, 1)),
              ),
            ),
            GalleryItem(
              label: 'markPastDates · no value',
              child: GhForcedStates(
                child: GhDatePickerPanel(
                  viewDate: DateTime.now(),
                  value: '',
                  todayValue: today,
                  markPastDates: true,
                  clearLabel: 'Clear date',
                  onSelect: (_) {},
                  onClear: () {},
                  onPreviousMonth: () {},
                  onNextMonth: () {},
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
