import 'package:flutter/widgets.dart';

class BackdropDismissTracker {
  BackdropDismissTracker([this.onDismiss]);

  VoidCallback? onDismiss;
  bool _pressedOnBackdrop = false;

  void pointerDown({required bool onBackdrop}) => _pressedOnBackdrop = onBackdrop;

  bool click({required bool onBackdrop}) {
    final dismiss = _pressedOnBackdrop && onBackdrop;
    _pressedOnBackdrop = false;
    if (dismiss) onDismiss?.call();
    return dismiss;
  }

  void cancel() => _pressedOnBackdrop = false;
}

class GhBackdropDismiss extends StatefulWidget {
  const GhBackdropDismiss({super.key, required this.onDismiss, required this.child, this.backdrop});

  final VoidCallback? onDismiss;
  final Widget child;
  final Widget? backdrop;

  @override
  State<GhBackdropDismiss> createState() => _GhBackdropDismissState();
}

class _GhBackdropDismissState extends State<GhBackdropDismiss> {
  final BackdropDismissTracker _tracker = BackdropDismissTracker();

  @override
  Widget build(BuildContext context) {
    _tracker.onDismiss = widget.onDismiss;
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _tracker.pointerDown(onBackdrop: true),
          onTap: () => _tracker.click(onBackdrop: true),
          onTapCancel: _tracker.cancel,
          child: widget.backdrop ?? const SizedBox.expand(),
        ),
        Listener(
          behavior: HitTestBehavior.deferToChild,
          onPointerDown: (_) => _tracker.pointerDown(onBackdrop: false),
          child: widget.child,
        ),
      ],
    );
  }
}
