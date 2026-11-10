import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/features.dart';
import '../logic/open_popups.dart';
import '../src/rust/api/types.dart';
import 'app_signals.dart';
import 'settings.dart';
import 'workspaces.dart';

const setTabSignal = 'app:set-tab';
const newProjectRequestSignal = 'app:new-project-request';
const focusSearchSignal = 'app:focus-search';
const launchSelectionSignal = 'app:launch-selection';
const deleteSelectionSignal = 'app:delete-selection';
const toggleCommandPaletteSignal = 'app:toggle-command-palette';
const confirmRestartSignal = 'app:confirm-restart';
const escapeSignal = 'app:escape';

const shortcutTabOrder = ['projects', 'versions', 'templates', 'vault', 'storage', 'asset-store', 'news'];

List<String> shortcutTabsFor(AppSettings settings) =>
    shortcutTabOrder.where((id) => isFeatureEnabled(settings, id)).take(9).toList(growable: false);

enum ShortcutCommandKind {
  commandPalette,
  newProject,
  openSettings,
  restart,
  focusSearch,
  switchTab,
  switchWorkspace,
  escape,
  launchSelection,
  deleteSelection,
}

@immutable
class ShortcutCommand {
  const ShortcutCommand(this.kind, {this.index, this.preventDefault = true});

  final ShortcutCommandKind kind;
  final int? index;
  final bool preventDefault;

  @override
  bool operator ==(Object other) =>
      other is ShortcutCommand && other.kind == kind && other.index == index && other.preventDefault == preventDefault;

  @override
  int get hashCode => Object.hash(kind, index, preventDefault);

  @override
  String toString() => 'ShortcutCommand($kind${index == null ? '' : ', $index'})';
}

@immutable
class ShortcutKeyInput {
  const ShortcutKeyInput({
    required this.key,
    this.digitCode,
    this.ctrl = false,
    this.meta = false,
    this.alt = false,
    this.shift = false,
    this.isInput = false,
    this.nonSelectionTarget = false,
    this.popupOpen = false,
  });

  final String key;
  final int? digitCode;
  final bool ctrl;
  final bool meta;
  final bool alt;
  final bool shift;
  final bool isInput;
  final bool nonSelectionTarget;
  final bool popupOpen;
}

final _digit = RegExp(r'^[1-9]$');

ShortcutCommand? resolveShortcut(ShortcutKeyInput input, {String paletteKey = 'p'}) {
  final mod = input.meta || input.ctrl;
  if (input.key == 'Escape') {
    if (input.popupOpen) return null;
    return const ShortcutCommand(ShortcutCommandKind.escape);
  }
  final isInput = input.isInput;
  if (mod) {
    final key = input.key.toLowerCase();
    if (key == paletteKey.toLowerCase()) return const ShortcutCommand(ShortcutCommandKind.commandPalette);
    switch (key) {
      case 'n':
        return isInput ? null : const ShortcutCommand(ShortcutCommandKind.newProject);
      case ',':
        return !isInput && !input.shift ? const ShortcutCommand(ShortcutCommandKind.openSettings) : null;
      case 'r':
        return const ShortcutCommand(ShortcutCommandKind.restart);
      case 'f':
        return isInput ? null : const ShortcutCommand(ShortcutCommandKind.focusSearch);
    }
    if (!isInput && _digit.hasMatch(input.key)) {
      return ShortcutCommand(ShortcutCommandKind.switchTab, index: int.parse(input.key) - 1);
    }
    return null;
  }
  final digit = input.digitCode;
  if (input.alt && !input.shift && !isInput && digit != null && digit >= 1 && digit <= 9) {
    return ShortcutCommand(ShortcutCommandKind.switchWorkspace, index: digit - 1);
  }
  final selectionTarget = !isInput && !input.nonSelectionTarget && !input.popupOpen;
  if (input.key == 'Enter' && selectionTarget) {
    return const ShortcutCommand(ShortcutCommandKind.launchSelection, preventDefault: false);
  }
  if ((input.key == 'Delete' || input.key == 'Backspace') && selectionTarget) {
    return const ShortcutCommand(ShortcutCommandKind.deleteSelection);
  }
  return null;
}

final _physicalDigits = {
  PhysicalKeyboardKey.digit1: 1,
  PhysicalKeyboardKey.digit2: 2,
  PhysicalKeyboardKey.digit3: 3,
  PhysicalKeyboardKey.digit4: 4,
  PhysicalKeyboardKey.digit5: 5,
  PhysicalKeyboardKey.digit6: 6,
  PhysicalKeyboardKey.digit7: 7,
  PhysicalKeyboardKey.digit8: 8,
  PhysicalKeyboardKey.digit9: 9,
};

String shortcutKeyName(KeyEvent event) {
  final logical = event.logicalKey;
  if (logical == LogicalKeyboardKey.escape) return 'Escape';
  if (logical == LogicalKeyboardKey.enter || logical == LogicalKeyboardKey.numpadEnter) return 'Enter';
  if (logical == LogicalKeyboardKey.delete) return 'Delete';
  if (logical == LogicalKeyboardKey.backspace) return 'Backspace';
  final character = event.character;
  if (character != null && character.length == 1 && character.codeUnitAt(0) >= 0x20) return character;
  return logical.keyLabel;
}

ShortcutKeyInput shortcutInputFrom(
  KeyEvent event, {
  HardwareKeyboard? keyboard,
  bool isInput = false,
  bool nonSelectionTarget = false,
  bool? popupOpen,
}) {
  final hw = keyboard ?? HardwareKeyboard.instance;
  return ShortcutKeyInput(
    key: shortcutKeyName(event),
    digitCode: _physicalDigits[event.physicalKey],
    ctrl: hw.isControlPressed,
    meta: hw.isMetaPressed,
    alt: hw.isAltPressed,
    shift: hw.isShiftPressed,
    isInput: isInput,
    nonSelectionTarget: nonSelectionTarget,
    popupOpen: popupOpen ?? isPopupOpen(),
  );
}

class ShortcutHandlers {
  const ShortcutHandlers({
    this.onNewProject,
    this.onOpenSettings,
    this.onSwitchTab,
    this.onSwitchWorkspace,
    this.onCommandPalette,
    this.onRestart,
    this.onEscape,
    this.onFocusSearch,
    this.onLaunchSelection,
    this.onDeleteSelection,
  });

  final VoidCallback? onNewProject;
  final VoidCallback? onOpenSettings;
  final void Function(int index)? onSwitchTab;
  final void Function(int index)? onSwitchWorkspace;
  final VoidCallback? onCommandPalette;
  final VoidCallback? onRestart;
  final VoidCallback? onEscape;
  final VoidCallback? onFocusSearch;
  final VoidCallback? onLaunchSelection;
  final VoidCallback? onDeleteSelection;
}

class ShortcutDispatcher {
  ShortcutDispatcher(this._ref);

  final Ref _ref;

  String get paletteKey {
    final key = _ref.read(settingsProvider).value?.commandPaletteKeybind ?? '';
    return key.isEmpty ? 'p' : key;
  }

  List<String> get shortcutTabs {
    final settings = _ref.read(settingsProvider).value;
    return settings == null ? const [] : shortcutTabsFor(settings);
  }

  void switchTab(int index) {
    final tabs = shortcutTabs;
    if (index >= 0 && index < tabs.length) AppSignals.emit(setTabSignal, tabs[index]);
  }

  void switchWorkspace(int index) {
    final settings = _ref.read(settingsProvider).value;
    if (settings == null || !settings.workspacesEnabled) return;
    final workspaces = _ref.read(workspacesProvider).workspaces;
    if (index < 0 || index >= workspaces.length) return;
    _ref.read(workspacesProvider.notifier).switchWorkspace(workspaces[index].id).ignore();
  }

  void run(ShortcutCommand command, [ShortcutHandlers handlers = const ShortcutHandlers()]) {
    final index = command.index ?? 0;
    switch (command.kind) {
      case ShortcutCommandKind.commandPalette:
        (handlers.onCommandPalette ?? () => AppSignals.emit(toggleCommandPaletteSignal))();
      case ShortcutCommandKind.newProject:
        (handlers.onNewProject ?? () => AppSignals.emit(newProjectRequestSignal))();
      case ShortcutCommandKind.openSettings:
        (handlers.onOpenSettings ?? () => AppSignals.emit(setTabSignal, 'settings'))();
      case ShortcutCommandKind.restart:
        (handlers.onRestart ?? () => AppSignals.emit(confirmRestartSignal))();
      case ShortcutCommandKind.focusSearch:
        (handlers.onFocusSearch ?? () => AppSignals.emit(focusSearchSignal))();
      case ShortcutCommandKind.switchTab:
        (handlers.onSwitchTab ?? switchTab)(index);
      case ShortcutCommandKind.switchWorkspace:
        (handlers.onSwitchWorkspace ?? switchWorkspace)(index);
      case ShortcutCommandKind.escape:
        (handlers.onEscape ?? () => AppSignals.emit(escapeSignal))();
      case ShortcutCommandKind.launchSelection:
        (handlers.onLaunchSelection ?? () => AppSignals.emit(launchSelectionSignal))();
      case ShortcutCommandKind.deleteSelection:
        (handlers.onDeleteSelection ?? () => AppSignals.emit(deleteSelectionSignal))();
    }
  }

  ShortcutCommand? handle(ShortcutKeyInput input, [ShortcutHandlers handlers = const ShortcutHandlers()]) {
    final command = resolveShortcut(input, paletteKey: paletteKey);
    if (command != null) run(command, handlers);
    return command;
  }
}

final keyboardShortcutsProvider = Provider<ShortcutDispatcher>(ShortcutDispatcher.new);

class GhShortcutSelectionRegion extends StatelessWidget {
  const GhShortcutSelectionRegion({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

bool focusIsTextInput(FocusNode? node) {
  final context = node?.context;
  if (context == null) return false;
  if (context.widget is EditableText) return true;
  return context.findAncestorWidgetOfExactType<EditableText>() != null;
}

bool focusIsNonSelectionTarget(FocusNode? node, FocusNode scopeNode) {
  if (node == null || identical(node, scopeNode)) return false;
  final context = node.context;
  if (context == null) return false;
  if (context.findAncestorWidgetOfExactType<GhShortcutSelectionRegion>() != null) return false;
  final route = ModalRoute.of(context);
  if (route != null && route is PopupRoute) return true;
  return node.canRequestFocus;
}

class GhKeyboardShortcuts extends ConsumerStatefulWidget {
  const GhKeyboardShortcuts({super.key, required this.child, this.handlers = const ShortcutHandlers(), this.autofocus = true});

  final Widget child;
  final ShortcutHandlers handlers;
  final bool autofocus;

  @override
  ConsumerState<GhKeyboardShortcuts> createState() => _GhKeyboardShortcutsState();
}

class _GhKeyboardShortcutsState extends ConsumerState<GhKeyboardShortcuts> {
  final FocusNode _node = FocusNode(debugLabel: 'gh-keyboard-shortcuts', skipTraversal: true);

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final primary = FocusManager.instance.primaryFocus;
    final input = shortcutInputFrom(
      event,
      isInput: focusIsTextInput(primary),
      nonSelectionTarget: focusIsNonSelectionTarget(primary, _node),
    );
    final command = ref.read(keyboardShortcutsProvider).handle(input, widget.handlers);
    if (command == null || !command.preventDefault) return KeyEventResult.ignored;
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(focusNode: _node, autofocus: widget.autofocus, onKeyEvent: _onKey, child: widget.child);
  }
}
