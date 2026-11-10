import 'dart:async';

import 'package:flutter/material.dart';

import '../design/design.dart';

import 'strings.dart' as s;
import 'title_bar_theme.dart';

const _menuWidth = 320.0;
const _triggerWidth = 36.0;

class TaskTray extends StatefulWidget {
  const TaskTray({super.key, this.activeCount = 0});

  final int activeCount;

  @override
  State<TaskTray> createState() => _TaskTrayState();
}

class _TaskTrayState extends State<TaskTray> {
  final MenuController _menu = MenuController();
  bool _open = false;
  Timer? _autoClose;

  void _onOpen() {
    setState(() => _open = true);
    _autoClose?.cancel();
    _autoClose = Timer(const Duration(seconds: 2), () {
      if (mounted && _menu.isOpen) _menu.close();
    });
  }

  void _onClose() {
    _autoClose?.cancel();
    _autoClose = null;
    if (mounted) setState(() => _open = false);
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TitleBarTokens.of(context);
    final count = widget.activeCount;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: MenuAnchor(
        controller: _menu,
        style: tokens.menuStyle(padding: const EdgeInsets.all(8)),
        alignmentOffset: const Offset(_triggerWidth - _menuWidth, 8),
        onOpen: _onOpen,
        onClose: _onClose,
        menuChildren: [
          SizedBox(
            width: _menuWidth - 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: tokens.line.withValues(alpha: 0.5))),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.taskTrayTitle.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: tokens.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.taskTrayEmpty,
                        style: TextStyle(fontSize: 10, color: tokens.muted.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: tokens.raised,
                          borderRadius: BorderRadius.circular(tokens.btnRadius),
                          border: Border.all(color: tokens.line.withValues(alpha: 0.5)),
                        ),
                        child: GhIcon(
                          GhIcons.bell,
                          size: 16,
                          color: tokens.muted.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        s.noTasksRunning,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: tokens.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        builder: (context, controller, child) => TitleBarButton(
          key: const ValueKey('task-tray-trigger'),
          tooltip: s.taskTrayAria,
          semanticLabel: s.taskTrayAria,
          expanded: _open,
          onPressed: () => controller.isOpen ? controller.close() : controller.open(),
          builder: (context, hovered) => Container(
            width: _triggerWidth,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hovered ? tokens.ink.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(tokens.itemRadius),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GhIcon(GhIcons.bell, size: 16, color: hovered ? tokens.ink : tokens.muted),
                if (count > 0)
                  PositionedDirectional(
                    top: -6,
                    end: -8,
                    child: Container(
                      width: 16,
                      height: 16,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: tokens.amber, shape: BoxShape.circle),
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
