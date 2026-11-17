import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import '../titlebar/window_controls.dart';

/// Resize handles along the window's edges for the custom title bar on Linux.
///
/// With the title bar hidden, nothing on Linux draws a window frame to grab:
/// Windows resizes from the native hit test and macOS keeps its own frame, but GTK
/// only resizes when the app starts the drag itself (#352). The handles go away
/// while the window is maximized, where there is nothing to resize.
class WindowResizeEdges extends StatelessWidget {
  const WindowResizeEdges({super.key, required this.enabled, required this.window, required this.child});

  /// Whether the window draws its own frame; false leaves [child] untouched.
  final bool enabled;
  final TitleBarWindow window;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return MaximizedStateBuilder(
      window: window,
      builder: (context, maximized) =>
          DragToResizeArea(enableResizeEdges: maximized ? const [] : null, child: child),
    );
  }
}
