import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../api/api.dart';
import '../../design/design.dart';
import '../core/button.dart';
import '../core/i18n.dart';

String _messageOf(Object error) {
  final text = '$error';
  return text.startsWith('Exception: ') ? text.substring('Exception: '.length) : text;
}

class GhViewErrorScope extends StatefulWidget {
  const GhViewErrorScope({super.key, required this.child});

  final Widget child;

  @override
  State<GhViewErrorScope> createState() => _GhViewErrorScopeState();
}

class _GhViewErrorScopeState extends State<GhViewErrorScope> {
  Object? _error;
  int _generation = 0;

  void _report(Object error) {
    if (_error != null) return;
    _error = error;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _retry() => setState(() {
    _error = null;
    _generation++;
  });

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) {
      return GhViewErrorPanel(message: _messageOf(error), onRetry: _retry);
    }
    return _ViewErrorScope(
      state: this,
      child: KeyedSubtree(key: ValueKey(_generation), child: widget.child),
    );
  }
}

class _ViewErrorScope extends InheritedWidget {
  const _ViewErrorScope({required this.state, required super.child});

  final _GhViewErrorScopeState state;

  @override
  bool updateShouldNotify(_ViewErrorScope oldWidget) => oldWidget.state != state;
}

class GhViewErrorPanel extends StatefulWidget {
  const GhViewErrorPanel({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  State<GhViewErrorPanel> createState() => _GhViewErrorPanelState();
}

class _GhViewErrorPanelState extends State<GhViewErrorPanel> {
  bool _details = false;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Semantics(
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(theme.space(6)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: theme.rem(32)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: theme.space(3),
              children: [
                Text(
                  ghTr('view_error_title'),
                  textAlign: TextAlign.center,
                  style: theme.text(size: GhTextSize.base, weight: GhWeight.semibold, color: theme.ink),
                ),
                Text(
                  ghTr('view_error_desc'),
                  textAlign: TextAlign.center,
                  style: theme.text(size: GhTextSize.sm, color: theme.muted),
                ),
                GhButton(onPressed: widget.onRetry, label: ghTr('retry'), variant: GhButtonVariant.outline),
                GhButton(
                  onPressed: () => setState(() => _details = !_details),
                  label: ghTr('error_details'),
                  variant: GhButtonVariant.ghost,
                  size: GhTextSize.xs,
                  paddingX: 2,
                  paddingY: 1,
                ),
                if (_details)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(theme.space(3)),
                    decoration: BoxDecoration(color: theme.base, borderRadius: BorderRadius.circular(theme.radiusItem)),
                    child: SelectableText(
                      widget.message,
                      style: theme.text(size: GhTextSize.xs, mono: true, color: theme.muted),
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

Widget ghErrorWidget(FlutterErrorDetails details) => _ErrorReporter(details: details);

class _ErrorReporter extends StatefulWidget {
  const _ErrorReporter({required this.details});

  final FlutterErrorDetails details;

  @override
  State<_ErrorReporter> createState() => _ErrorReporterState();
}

class _ErrorReporterState extends State<_ErrorReporter> {
  bool _inView = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = context.getInheritedWidgetOfExactType<_ViewErrorScope>();
    _inView = scope != null;
    scope?.state._report(widget.details.exception);
  }

  @override
  Widget build(BuildContext context) {
    if (_inView) return const SizedBox.shrink();
    return GhAppErrorScreen(message: _messageOf(widget.details.exception));
  }
}

class GhAppErrorScreen extends StatelessWidget {
  const GhAppErrorScreen({super.key, required this.message});

  final String message;

  static const _background = Color(0xFF1E1F22);
  static const _ink = Color(0xFFF2F3F5);
  static const _muted = Color(0xFF949BA4);
  static const _danger = Color(0xFFF23F42);
  static const _panel = Color(0xFF2B2D31);
  static const _border = Color(0xFF3F4147);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: _background,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                Text(
                  ghTr('app_error_title'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _ink, decoration: TextDecoration.none),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Text(
                    ghTr('app_error_desc'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: _muted, decoration: TextDecoration.none),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      message,
                      style: const TextStyle(fontSize: 11, color: _danger, fontFamily: 'monospace', decoration: TextDecoration.none),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Api.relaunch().ignore(),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        border: Border.all(color: _border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        ghTr('reload'),
                        style: const TextStyle(fontSize: 13, color: _ink, decoration: TextDecoration.none),
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
