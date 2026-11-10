import 'package:flutter/material.dart';

import '../../../design/design.dart';
import '../../../ui/core/button.dart';
import '../../../ui/overlays/popup_registry.dart';
import '../../../ui/feedback/feedback.dart';
import '../gallery_kit.dart';

final feedbackSections = <GallerySection>[
  GallerySection('Modals', (context) => const _Modals()),
  GallerySection('Toasts', (context) => const _Toasts()),
  GallerySection('Banners and notices', (context) => const _Notices()),
];

void _announce(String message) => pushToast(GhToastType.info, message);

class _Frame extends StatelessWidget {
  const _Frame({required this.width, required this.height, required this.child});

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

class _SampleBody extends StatelessWidget {
  const _SampleBody({this.lines = 3});

  final int lines;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(theme.space(6), 0, theme.space(6), theme.space(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: theme.space(2),
        children: [
          for (var i = 0; i < lines; i++)
            Text(
              'Body line ${i + 1}. Modal content scrolls inside the shell when it grows past 88% of the viewport.',
              style: theme.text(size: GhTextSize.sm, color: theme.muted, lineHeight: 1.625),
            ),
          Wrap(
            spacing: theme.space(2),
            children: [
              GhButton(onPressed: () => _announce('First'), label: 'First', variant: GhButtonVariant.outline),
              GhButton(onPressed: () => _announce('Second'), label: 'Second', variant: GhButtonVariant.outline),
            ],
          ),
        ],
      ),
    );
  }
}

List<Widget> _sampleFooter(VoidCallback close) => [
      const Spacer(),
      GhButton(onPressed: close, label: GhFeedbackStrings.cancel),
      GhButton(onPressed: close, label: 'Save', variant: GhButtonVariant.primary),
    ];

class _Modals extends StatelessWidget {
  const _Modals();

  void _openShell(BuildContext context, GhModalWidth width, {bool tall = false, int lines = 3}) {
    showGhModal<void>(context, (context) {
      void close() => Navigator.of(context).pop();
      return GhModalShell(
        icon: GhIcon(GhIcons.rocket, size: GhTheme.of(context).space(5), color: GhTheme.of(context).accentBright),
        title: 'Modal ${width.name}',
        maxWidth: width,
        onClose: close,
        bodyHeight: tall ? GhModalShell.tallBodyHeight(context) : null,
        footer: _sampleFooter(close),
        child: tall
            ? ListView(children: [for (var i = 0; i < 4; i++) _SampleBody(lines: 4)])
            : _SampleBody(lines: lines),
      );
    });
  }

  void _openNoClose(BuildContext context) {
    showGhModal<void>(context, (context) {
      void close() => Navigator.of(context).pop();
      return GhModalShell(
        icon: GhIcon(GhIcons.alertTriangle, size: GhTheme.of(context).space(5), color: GhTheme.of(context).amber),
        title: 'No close button',
        maxWidth: GhModalWidth.md,
        onClose: close,
        showClose: false,
        footer: _sampleFooter(close),
        child: const _SampleBody(lines: 1),
      );
    });
  }

  void _openMenuBlocked(BuildContext context) {
    late final GhPopupHandle menu;
    menu = GhPopupRegistry.open(close: () => menu.release());
    showGhModal<void>(context, (context) {
      void close() => Navigator.of(context).pop();
      return GhModalShell(
        icon: GhIcon(GhIcons.alertTriangle, size: GhTheme.of(context).space(5), color: GhTheme.of(context).amber),
        title: 'Escape blocked by an open menu',
        maxWidth: GhModalWidth.md,
        onClose: close,
        footer: [
          const Spacer(),
          GhButton(onPressed: () => menu.release(), label: 'Close menu'),
          GhButton(onPressed: close, label: GhFeedbackStrings.close, variant: GhButtonVariant.primary),
        ],
        child: const _SampleBody(lines: 1),
      );
    }).whenComplete(() => menu.release());
  }

  Future<void> _openConfirm(BuildContext context, GhConfirmVariant variant) async {
    final danger = variant == GhConfirmVariant.danger;
    final confirmed = await showGhConfirmDialog(
      context,
      title: danger ? 'Delete project' : 'Discard changes',
      description: danger
          ? 'This removes the project folder from disk. This cannot be undone.'
          : 'You have unsaved changes. Discard them and close?',
      confirmLabel: danger ? 'Delete' : 'Discard',
      variant: variant,
    );
    _announce(confirmed ? 'Confirmed' : 'Cancelled');
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GalleryGroup(
              title: 'Open for real',
              spacing: 8,
              children: [
                for (final width in GhModalWidth.values.take(6))
                  GhButton(onPressed: () => _openShell(context, width), label: 'Shell ${width.name}', variant: GhButtonVariant.outline),
                GhButton(onPressed: () => _openShell(context, GhModalWidth.x2l, lines: 40), label: 'Long body', variant: GhButtonVariant.outline),
                GhButton(onPressed: () => _openShell(context, GhModalWidth.x2l, tall: true), label: 'Tall body height', variant: GhButtonVariant.outline),
                GhButton(onPressed: () => _openNoClose(context), label: 'showClose false', variant: GhButtonVariant.outline),
                GhButton(onPressed: () => _openMenuBlocked(context), label: 'Menu open', variant: GhButtonVariant.outline),
                GhButton(onPressed: () => _openConfirm(context, GhConfirmVariant.normal), label: 'Confirm default', variant: GhButtonVariant.primary),
                GhButton(onPressed: () => _openConfirm(context, GhConfirmVariant.danger), label: 'Confirm danger', variant: GhButtonVariant.danger),
              ],
            ),
            GalleryGroup(
              title: 'ModalHeader',
              children: [
                GalleryItem(
                  label: 'with close',
                  child: Container(
                    width: 460,
                    color: theme.surface,
                    child: GhModalHeader(
                      icon: GhIcon(GhIcons.rocket, size: theme.space(5), color: theme.accentBright),
                      title: 'Export templates',
                      autoFocusBanner: false,
                      onClose: () => _announce('Close pressed'),
                    ),
                  ),
                ),
                GalleryItem(
                  label: 'no close, long title clamps to 2 lines',
                  child: Container(
                    width: 460,
                    color: theme.surface,
                    child: GhModalHeader(
                      icon: GhIcon(GhIcons.alertTriangle, size: theme.space(5), color: theme.amber),
                      title: 'A very long modal title that keeps going so it has to clamp at two lines with an ellipsis',
                      autoFocusBanner: false,
                    ),
                  ),
                ),
              ],
            ),
            GalleryGroup(
              title: 'ModalShell preview',
              children: [
                GalleryItem(
                  label: 'max-w-md with footer, inside a 620x420 frame',
                  child: _Frame(
                    width: 620,
                    height: 420,
                    child: GhModalShell(
                      staticPreview: true,
                      icon: GhIcon(GhIcons.rocket, size: theme.space(5), color: theme.accentBright),
                      title: 'Launch arguments',
                      maxWidth: GhModalWidth.md,
                      onClose: () => _announce('Shell closed'),
                      footer: _sampleFooter(() => _announce('Footer pressed')),
                      child: const _SampleBody(lines: 2),
                    ),
                  ),
                ),
              ],
            ),
            GalleryGroup(
              title: 'ConfirmDialog preview',
              children: [
                for (final variant in GhConfirmVariant.values)
                  GalleryItem(
                    label: variant.name,
                    child: _Frame(
                      width: 480,
                      height: 340,
                      child: GhConfirmDialog(
                        staticPreview: true,
                        title: variant == GhConfirmVariant.danger ? 'Delete project' : 'Discard changes',
                        description: variant == GhConfirmVariant.danger
                            ? 'This removes the project folder from disk. This cannot be undone.'
                            : 'You have unsaved changes. Discard them and close?',
                        confirmLabel: variant == GhConfirmVariant.danger ? 'Delete' : 'Discard',
                        variant: variant,
                        onConfirm: () => _announce('Confirm pressed'),
                        onCancel: () => _announce('Cancel pressed'),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const GhToastHost(),
      ],
    );
  }
}

class _Toasts extends StatelessWidget {
  const _Toasts();

  @override
  Widget build(BuildContext context) {
    final action = GhToastAction(label: 'Undo', onClick: () => _announce('Undo clicked'));
    var nextId = 1000;
    GhToastItem sample(GhToastType type, String message, {GhToastAction? action}) =>
        GhToastItem(id: nextId++, type: type, message: message, action: action);
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GalleryGroup(
              title: 'Push real toasts',
              spacing: 8,
              children: [
                GhButton(
                  onPressed: () => pushToast(GhToastType.success, 'Project created'),
                  label: 'Success',
                  variant: GhButtonVariant.outline,
                ),
                GhButton(
                  onPressed: () => pushToast(GhToastType.error, 'Could not open the project folder'),
                  label: 'Error',
                  variant: GhButtonVariant.outline,
                ),
                GhButton(
                  onPressed: () => pushToast(GhToastType.info, 'Godot 4.5 is downloading in the background'),
                  label: 'Info',
                  variant: GhButtonVariant.outline,
                ),
                GhButton(
                  onPressed: () => pushToast(GhToastType.success, 'Project removed', ttlMs: 8000, action: action),
                  label: 'With action',
                  variant: GhButtonVariant.outline,
                ),
                GhButton(
                  onPressed: () => reportError(Exception('Failed to read project.godot')),
                  label: 'reportError',
                  variant: GhButtonVariant.outline,
                ),
                GhButton(
                  onPressed: () => reportError(null),
                  label: 'reportError empty',
                  variant: GhButtonVariant.outline,
                ),
                GhButton(onPressed: ghToasts.clear, label: 'Clear all', variant: GhButtonVariant.ghost),
              ],
            ),
            GalleryGroup(
              title: 'Static cards',
              children: [
                for (final type in GhToastType.values) ...[
                  GalleryItem(
                    label: type.name,
                    child: GhToastCard(
                      toast: sample(type, 'A ${type.name} toast message that can wrap onto a second line.'),
                      onDismiss: () => _announce('Dismiss pressed'),
                    ),
                  ),
                  GalleryItem(
                    label: '${type.name} with action',
                    child: GhToastCard(
                      toast: sample(type, 'A ${type.name} toast with an action.', action: action),
                      onDismiss: () => _announce('Dismiss pressed'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        const GhToastHost(),
      ],
    );
  }
}

class _Notices extends StatefulWidget {
  const _Notices();

  @override
  State<_Notices> createState() => _NoticesState();
}

class _NoticesState extends State<_Notices> {
  static const _workspaces = [
    GhWorkspaceRef(id: 'work', name: 'Studio work', icon: 'briefcase'),
    GhWorkspaceRef(id: 'home', name: 'Personal projects', icon: 'house'),
    GhWorkspaceRef(id: 'jam', name: 'Game jams and prototypes with a very long workspace name', icon: 'gamepad'),
  ];

  final Map<String, String> _prefs = {};
  late final GhAnnouncementController _announcement = GhAnnouncementController(
    getItem: (key) => _prefs[key],
    setItem: (key, value) => _prefs[key] = value,
  );
  int _active = 0;

  @override
  void dispose() {
    _announcement.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GalleryGroup(
              title: 'AnnouncementBanner',
              spacing: 8,
              children: [
                GalleryItem(
                  label: 'static card',
                  child: SizedBox(
                    width: 820,
                    child: GhAnnouncementCard(
                      animate: false,
                      onSupport: () => _announce('Support pressed: ${GhAnnouncement.supportUrl}'),
                      onDismiss: () => _announce('Dismiss pressed'),
                    ),
                  ),
                ),
                GhButton(onPressed: _announcement.show, label: 'Show banner', variant: GhButtonVariant.outline),
                GhButton(
                  onPressed: () {
                    _prefs.clear();
                    _announcement.start();
                  },
                  label: 'Reset prefs',
                  variant: GhButtonVariant.ghost,
                ),
              ],
            ),
            GalleryGroup(
              title: 'Live banner frame',
              children: [
                _Frame(
                  width: 820,
                  height: 160,
                  child: GhAnnouncementBanner(
                    controller: _announcement,
                    onSupport: () => _announce('Support pressed: ${GhAnnouncement.supportUrl}'),
                  ),
                ),
              ],
            ),
            GalleryGroup(
              title: 'WorkspaceSwitchNotice',
              spacing: 8,
              children: [
                GalleryItem(
                  label: 'static card',
                  child: GhWorkspaceSwitchCard(icon: workspaceIcon('briefcase'), name: 'Studio work'),
                ),
                GhButton(
                  onPressed: () => setState(() => _active = (_active + 1) % _workspaces.length),
                  label: 'Switch workspace',
                  variant: GhButtonVariant.primary,
                ),
                Text('Active: ${_workspaces[_active].name}', style: theme.text(size: GhTextSize.xs, color: theme.muted)),
              ],
            ),
          ],
        ),
        Positioned.fill(
          child: GhWorkspaceSwitchNotice(activeId: _workspaces[_active].id, workspaces: _workspaces),
        ),
        const GhToastHost(),
      ],
    );
  }
}
