import 'dart:async';

import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../../motion/presence.dart';
import '../core/button.dart';
import '../core/tooltip.dart';
import 'strings.dart';

class GhModalFocusHandle {
  GhModalFocusHandle(this.scope);

  final FocusScopeNode scope;
  FocusNode? banner;

  static GhModalFocusHandle? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<GhModalFocusProvider>()?.handle;
}

class GhModalFocusProvider extends InheritedWidget {
  const GhModalFocusProvider({super.key, required this.handle, required super.child});

  final GhModalFocusHandle handle;

  @override
  bool updateShouldNotify(GhModalFocusProvider oldWidget) => handle != oldWidget.handle;
}

class GhModalHeader extends StatefulWidget {
  const GhModalHeader({
    super.key,
    required this.icon,
    required this.title,
    this.onClose,
    this.autoFocusBanner = true,
    this.titleMaxLines = 2,
    this.closeLabel = GhFeedbackStrings.close,
  });

  final Widget icon;
  final String title;
  final VoidCallback? onClose;
  final bool autoFocusBanner;
  final int? titleMaxLines;
  final String closeLabel;

  @override
  State<GhModalHeader> createState() => _GhModalHeaderState();
}

class _GhModalHeaderState extends State<GhModalHeader> {
  final FocusNode _banner = FocusNode(debugLabel: 'GhModalHeader banner', skipTraversal: true);
  GhModalFocusHandle? _handle;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    if (!widget.autoFocusBanner) {
      return;
    }
    final handle = GhModalFocusHandle.maybeOf(context);
    if (handle != null) {
      _handle = handle;
      handle.banner = _banner;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scheduleMicrotask(() {
        if (mounted) {
          _banner.requestFocus();
        }
      });
    });
  }

  @override
  void dispose() {
    if (_handle?.banner == _banner) {
      _handle!.banner = null;
    }
    _banner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final onClose = widget.onClose;
    return Padding(
      padding: EdgeInsets.fromLTRB(theme.space(4), theme.space(4), theme.space(4), theme.space(2)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: theme.space(3),
        children: [
          Expanded(
            child: GhCascadeItem(
              child: Focus(
                focusNode: _banner,
                child: Container(
                  padding: EdgeInsets.all(theme.space(3)),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(theme.radiusBtn),
                  ),
                  child: Row(
                    spacing: theme.space(2),
                    children: [
                      SizedBox.square(
                        dimension: theme.space(9),
                        child: Center(child: widget.icon),
                      ),
                      Flexible(
                        child: GhTooltip(
                          message: widget.title,
                          child: Semantics(
                            header: true,
                            child: Text(
                              widget.title.toUpperCase(),
                              maxLines: widget.titleMaxLines,
                              overflow: widget.titleMaxLines == null ? null : TextOverflow.ellipsis,
                              style: theme.text(size: GhTextSize.x2l, weight: GhWeight.semibold, lineHeight: 1.25),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (onClose != null)
            GhCascadeItem(
              child: GhButton(
                onPressed: onClose,
                icon: GhIcons.x,
                variant: GhButtonVariant.subtle,
                paddingX: 1.5,
                paddingY: 1.5,
                iconSize: theme.space(4),
                semanticLabel: widget.closeLabel,
              ),
            ),
        ],
      ),
    );
  }
}
