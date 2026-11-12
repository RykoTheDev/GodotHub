import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../api/git.dart';
import '../api/git_auth.dart';
import '../api/projects.dart';
import '../api/templates.dart';
import '../design/design.dart';
import '../logic/naming_convention.dart';
import '../projects/project_icon.dart';
import '../shell/placeholder_view.dart';
import '../src/rust/api/types.dart';
import '../state/settings.dart';
import '../ui/controls/checkbox.dart';
import '../ui/controls/text_input.dart';
import '../ui/controls/toggle.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/reusables/modal_kit.dart';

const createProjectPlaceholders = [
  'My Awesome Game',
  'Untitled Masterpiece',
  'Project Nebula',
  'Game of the Year',
  'Probably Nothing',
  'Friday Night Project',
  'Yet Another Platformer',
  'The Next Big Thing',
  'workspace_simulator',
  'Definitely Not Flappy Bird',
  'Super Secret Project',
  'Roguelike #4',
  'Ctrl+S Adventure',
  'Pixels & Dreams',
  'v0.0.1 - The Beginning',
  'Procrastination.exe',
  'Rapid Unplanned Disassembly',
  'Another One Bites the Dust',
  'Jam Entry 2026',
  'Open World Survival Thing',
];

const _licenses = ['MIT', 'Apache-2.0', 'GPL-3.0', 'Unlicense'];

const _iconPresetPath =
    'm2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909M3.75 21h16.5A2.25 2.25 0 0 0 22.5 18.75V5.25A2.25 2.25 0 0 0 20.25 3H3.75A2.25 2.25 0 0 0 1.5 5.25v13.5A2.25 2.25 0 0 0 3.75 21Zm16.5-13.5h.008v.008h-.008V7.5Z';

String _hex(Color color) => '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

class CreateProjectModal extends ConsumerStatefulWidget {
  const CreateProjectModal({
    super.key,
    required this.installedVersions,
    this.defaultLocation,
    this.initialTemplateId,
    this.categories = const [],
    this.categoriesEnabled = false,
    required this.onClose,
    required this.onCreated,
    this.placeholder,
  });

  final List<InstalledGodotVersion> installedVersions;
  final String? defaultLocation;
  final String? initialTemplateId;
  final List<Category> categories;
  final bool categoriesEnabled;
  final VoidCallback onClose;
  final VoidCallback onCreated;
  final String? placeholder;

  @override
  ConsumerState<CreateProjectModal> createState() => _CreateProjectModalState();
}

class _CreateProjectModalState extends ConsumerState<CreateProjectModal> {
  final TextEditingController _name = TextEditingController();
  late final TextEditingController _location = TextEditingController(text: widget.defaultLocation ?? '');
  final FocusNode _nameNode = FocusNode(debugLabel: 'CreateProjectModal name');
  late final String _placeholder = widget.placeholder ?? createProjectPlaceholders[math.Random().nextInt(createProjectPlaceholders.length)];
  late String _version = widget.installedVersions.firstOrNull?.tag ?? '';
  late String? _templateId = widget.initialTemplateId;
  String? _iconPath;
  String? _iconPreview;
  String? _category;
  List<ProjectTemplate> _templates = const [];
  String? _error;
  late bool _initGit = ref.read(settingsProvider).value?.gitInitNewProjects ?? false;
  bool _gitignore = true;
  bool _gitattributes = true;
  bool _readme = false;
  String _license = '';
  bool _gitAvailable = true;
  String? _gitWarning;
  String? _remoteSuccess;
  bool _busy = false;
  bool _initializingGit = false;
  bool _creatingRemote = false;
  bool _attempted = false;
  GitAuthState? _gitAuth;
  bool _remoteEnabled = false;
  String _remoteProvider = 'github';
  bool _remotePrivate = true;

  bool get _finished => _gitWarning != null || _remoteSuccess != null;

  bool get _hasRemoteAuth => _gitAuth?.github != null || _gitAuth?.gitlab != null;

  @override
  void initState() {
    super.initState();
    _name.addListener(
      () => setState(() {
        if (_error != null) _error = null;
      }),
    );
    TemplatesApi.list().then((value) {
      if (mounted) setState(() => _templates = value);
    }, onError: (Object _) {});
    GitApi.isAvailable().then((available) {
      if (!mounted) return;
      setState(() {
        _gitAvailable = available;
        if (!available) _initGit = false;
      });
    }, onError: (Object _) {});
    GitAuthApi.getState().then((state) {
      if (!mounted) return;
      setState(() {
        _gitAuth = state;
        if (state.github != null && state.gitlab == null) {
          _remoteProvider = 'github';
        } else if (state.gitlab != null && state.github == null) {
          _remoteProvider = 'gitlab';
        }
      });
    }, onError: (Object _) {});
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _nameNode.dispose();
    super.dispose();
  }

  void _dismiss() => _finished ? widget.onCreated() : widget.onClose();

  Future<void> _pickLocation() async {
    try {
      final folder = await ProjectsApi.pickFolder();
      if (folder != null && mounted) {
        setState(() {
          _location.text = folder;
          _error = null;
        });
      }
    } catch (reason) {
      ghToasts.pushToast(GhToastType.error, '$reason');
    }
  }

  Future<void> _pickIcon() async {
    try {
      final file = await ProjectsApi.pickFile();
      if (file == null || !mounted) return;
      setState(() => _iconPath = file);
      final data = await ProjectsApi.readImageFile(file);
      if (mounted && _iconPath == file) setState(() => _iconPreview = data);
    } catch (reason) {
      ghToasts.pushToast(GhToastType.error, '$reason');
    }
  }

  Future<void> _submit() async {
    if (_busy || _finished) return;
    final name = _name.text.trim();
    final location = _location.text;
    if (name.isEmpty || location.isEmpty) {
      setState(() {
        _attempted = true;
        _error = ghTr('create_project_error');
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final project = await ProjectsApi.create(name, location, _version, _iconPath, _templateId, _category);
      if (_initGit) {
        if (mounted) setState(() => _initializingGit = true);
        try {
          final outcome = await GitApi.initProject(
            project.path,
            GitInitOptions(
              gitignore: _gitignore,
              gitattributes: _gitattributes,
              readme: _readme,
              license: _license.isEmpty ? null : _license,
            ),
          );
          final warning = outcome.warning;
          if (warning != null && warning.isNotEmpty) {
            if (mounted) setState(() => _gitWarning = warning);
            return;
          }
        } catch (reason) {
          if (mounted) setState(() => _gitWarning = '$reason');
          return;
        } finally {
          if (mounted) setState(() => _initializingGit = false);
        }
      }
      if (_remoteEnabled && _hasRemoteAuth) {
        if (mounted) setState(() => _creatingRemote = true);
        try {
          final result = await GitAuthApi.createRemoteRepo(_remoteProvider, name, _remotePrivate, project.path);
          if (mounted) setState(() => _remoteSuccess = result.url);
          return;
        } catch (reason) {
          if (mounted) setState(() => _gitWarning = '$reason');
          return;
        } finally {
          if (mounted) setState(() => _creatingRemote = false);
        }
      }
      widget.onCreated();
    } catch (reason) {
      if (mounted) setState(() => _error = '$reason');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _input(
    GhTheme theme, {
    required TextEditingController controller,
    required bool invalid,
    FocusNode? focusNode,
    String? placeholder,
    bool readOnly = false,
    VoidCallback? onTap,
    ValueChanged<String>? onSubmitted,
    Color? textColor,
  }) => GhTextInput(
    controller: controller,
    focusNode: focusNode,
    autofocus: focusNode != null,
    placeholder: placeholder,
    readOnly: readOnly,
    onTap: onTap,
    onSubmitted: onSubmitted,
    mono: true,
    textColor: textColor,
    background: theme.overlay,
    placeholderColor: theme.muted.withValues(alpha: 0.7),
    borderColor: invalid ? theme.danger.withValues(alpha: 0.7) : theme.outline.withValues(alpha: 0.5),
    focusBorderColor: invalid ? theme.danger : theme.accentDim,
    borderRadius: BorderRadius.circular(theme.radiusItem),
    padding: EdgeInsets.symmetric(horizontal: theme.space(3.5), vertical: theme.space(2.5)),
  );

  Widget _outline(
    GhTheme theme, {
    required String label,
    required VoidCallback? onPressed,
    GhTextSize size = GhTextSize.xs,
    double px = 3,
    double py = 2,
    bool danger = false,
  }) {
    final radius = BorderRadius.circular(theme.radiusBtn);
    return GhPressable(
      onPressed: onPressed,
      borderRadius: radius,
      builder: (context, states) {
        final hover = states.active;
        return GhAnimatedBox(
          color: hover ? (danger ? theme.danger.withValues(alpha: 0.1) : theme.raised) : theme.raised.withValues(alpha: 0),
          borderRadius: radius,
          border: Border.all(
            color: hover ? (danger ? theme.danger.withValues(alpha: 0.3) : theme.accentDim) : theme.outline.withValues(alpha: 0.5),
          ),
          padding: EdgeInsets.symmetric(horizontal: theme.space(px), vertical: theme.space(py)),
          child: Text(
            label,
            style: theme.text(size: size, color: danger ? (hover ? theme.danger : theme.muted) : theme.ink),
          ),
        );
      },
    );
  }

  Widget _section(GhTheme theme, String label, List<Widget> chips, {Widget? after}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: theme.space(2),
    children: [
      GhFieldLabel(label),
      Wrap(spacing: theme.space(1.5), runSpacing: theme.space(1.5), children: chips),
      ?after,
    ],
  );

  Widget _switchRow(
    GhTheme theme, {
    required String label,
    required String description,
    required bool checked,
    required bool disabled,
    required ValueChanged<bool> onChanged,
  }) => Row(
    spacing: theme.space(4),
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.text(size: GhTextSize.xs, weight: GhWeight.medium, color: theme.ink),
            ),
            Padding(
              padding: EdgeInsets.only(top: theme.space(1)),
              child: Text(
                description,
                style: theme.text(size: GhTextSize.x2s, color: theme.muted, lineHeight: 1.625),
              ),
            ),
          ],
        ),
      ),
      GhToggle(checked: checked, onChanged: onChanged, disabled: disabled, label: label),
    ],
  );

  Widget _box(GhTheme theme, {required double padding, required List<Widget> children}) => Container(
    padding: EdgeInsets.all(theme.space(padding)),
    decoration: BoxDecoration(
      color: theme.overlay,
      borderRadius: BorderRadius.circular(theme.radiusItem),
      border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: theme.space(2.5), children: children),
  );

  Widget _notice(GhTheme theme, {required Color color, required FaIconData icon, String? title, required String text}) => Padding(
    padding: EdgeInsets.symmetric(horizontal: theme.space(6)),
    child: Semantics(
      liveRegion: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(3)),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(theme.radiusItem),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: theme.space(2.5),
          children: [
            Padding(
              padding: EdgeInsets.only(top: theme.space(0.5)),
              child: GhIcon(icon, size: theme.space(4), color: color),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title,
                      style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: color),
                    ),
                  Padding(
                    padding: EdgeInsets.only(top: title != null ? theme.space(1) : 0),
                    child: Text(
                      text,
                      style: theme.text(size: GhTextSize.xs, color: title != null ? theme.muted : color, lineHeight: 1.625),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr.common;
    final settings = ref.watch(settingsProvider).value;
    final name = _name.text.trim();
    final folderName = applyNamingConvention(_name.text, NamingConvention.parse(settings?.directoryNamingConvention ?? ''));
    final icon = _iconPreview;
    final locked = _busy || _finished;
    final versions = widget.installedVersions;
    final auth = _gitAuth;
    return GhModalShell(
      icon: GhIcon(GhIcons.folderPlus, size: theme.space(5), color: theme.accentBright),
      title: tr.new_project,
      maxWidth: GhModalWidth.x2l,
      showClose: false,
      onClose: _dismiss,
      initialFocus: _nameNode,
      rawFooter: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null) _notice(theme, color: theme.danger, icon: GhIcons.alertTriangle, text: _error!),
          if (_gitWarning != null)
            _notice(theme, color: theme.amber, icon: GhIcons.alertTriangle, title: tr.git_init_warning_title, text: _gitWarning!),
          if (_remoteSuccess != null)
            _notice(theme, color: theme.mint, icon: GhIcons.check, title: tr.remote_repo_created_title, text: _remoteSuccess!),
          Container(
            padding: EdgeInsets.fromLTRB(theme.space(6), theme.space(4), theme.space(6), theme.space(6)),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.line)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: theme.space(2.5),
              children: [
                if (_finished)
                  GhButton(
                    onPressed: widget.onCreated,
                    label: tr.create_project_done,
                    variant: GhButtonVariant.primary,
                    paddingX: 5,
                    weight: GhWeight.medium,
                  )
                else ...[
                  GhButton(onPressed: _busy ? null : widget.onClose, label: tr.cancel, disabledOpacity: 0.5),
                  GhBusyButton(
                    onPressed: _busy ? null : _submit,
                    busy: _busy,
                    label: !_busy
                        ? tr.create_project_btn
                        : _creatingRemote
                        ? tr.creating_remote_repo
                        : _initializingGit
                        ? tr.initializing_git
                        : tr.creating,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(theme.space(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(4),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(0.5),
              children: [
                GhFieldLabel(tr.project_name_label, inset: true),
                _input(
                  theme,
                  controller: _name,
                  focusNode: _nameNode,
                  invalid: _attempted && name.isEmpty,
                  placeholder: _placeholder,
                  onSubmitted: (_) => _submit(),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.only(start: theme.space(2), top: theme.space(1)),
                  child: Row(
                    spacing: theme.space(1.5),
                    children: [
                      GhIcon(GhIcons.folderPlus, size: theme.space(3), color: theme.accentBright.withValues(alpha: 0.7)),
                      Expanded(
                        child: Text(
                          name.isNotEmpty ? tr.folder_name_preview.args({'name': folderName}) : tr.folder_name_hint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.text(size: GhTextSize.x3s, mono: true, color: theme.muted.withValues(alpha: 0.6)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: theme.space(0.5),
              children: [
                GhFieldLabel(tr.project_location_label, inset: true),
                Row(
                  spacing: theme.space(2.5),
                  children: [
                    Expanded(
                      child: _input(
                        theme,
                        controller: _location,
                        invalid: _attempted && _location.text.isEmpty,
                        placeholder: tr.choose_folder_placeholder,
                        readOnly: true,
                        onTap: _pickLocation,
                        textColor: theme.muted,
                      ),
                    ),
                    _outline(theme, label: tr.browse, onPressed: _pickLocation, size: GhTextSize.sm, px: 4, py: 2.5),
                  ],
                ),
              ],
            ),
            if (widget.categoriesEnabled)
              _section(theme, tr.category_optional, [
                GhChoiceChip(label: tr.no_category_label, active: _category == null, onPressed: () => setState(() => _category = null)),
                for (final cat in widget.categories)
                  GhChoiceChip(
                    label: cat.name,
                    active: _category == cat.name,
                    dotColor: colorFromHex(cat.color),
                    onPressed: () => setState(() => _category = cat.name),
                  ),
              ]),
            if (_templates.isNotEmpty)
              _section(theme, tr.template_optional, [
                GhChoiceChip(label: tr.blank_template, active: _templateId == null, onPressed: () => setState(() => _templateId = null)),
                for (final tpl in _templates)
                  _TemplateChip(
                    template: tpl,
                    active: _templateId == tpl.id,
                    onPressed: () => setState(() => _templateId = tpl.id),
                    onPreview: () => showPlaceholderModal(context, title: tpl.name, icon: GhIcons.bookOpen).ignore(),
                  ),
              ]),
            _section(
              theme,
              tr.godot_version_label,
              [
                for (final v in versions)
                  GhChoiceChip(
                    label: (v.customName?.isNotEmpty ?? false) ? v.customName! : v.tag,
                    active: _version == v.tag,
                    tone: GhChoiceTone.mint,
                    dotColor: theme.mint,
                    onPressed: () => setState(() => _version = v.tag),
                    trailing: v.isMono
                        ? Container(
                            padding: EdgeInsets.symmetric(horizontal: theme.space(1.5), vertical: theme.space(0.5)),
                            decoration: BoxDecoration(
                              color: theme.mint.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(theme.radiusTag),
                              border: Border.all(color: theme.mint.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              'MONO',
                              style: theme.text(size: GhTextSize.x4s, weight: GhWeight.bold, color: theme.mint, letterSpacingEm: 0.05),
                            ),
                          )
                        : null,
                  ),
              ],
              after: versions.isEmpty
                  ? Text(
                      tr.no_engine_warning,
                      style: theme.text(size: GhTextSize.xs, color: theme.amber),
                    )
                  : null,
            ),
            Row(
              spacing: theme.space(3.5),
              children: [
                Container(
                  width: theme.space(14),
                  height: theme.space(14),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.overlay,
                    borderRadius: BorderRadius.circular(theme.radiusTile),
                    border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
                  ),
                  child: icon != null
                      ? ProjectIconImage(url: icon)
                      : SvgPicture.string(
                          '<svg viewBox="0 0 24 24" fill="none" stroke="${_hex(theme.muted)}" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="$_iconPresetPath"/></svg>',
                          width: theme.space(6),
                          height: theme.space(6),
                        ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: theme.space(1.5),
                    children: [
                      Row(
                        spacing: theme.space(2),
                        children: [
                          _outline(theme, label: _iconPath != null ? tr.change_icon : tr.choose_icon, onPressed: _pickIcon),
                          if (_iconPath != null)
                            _outline(
                              theme,
                              label: tr.reset,
                              danger: true,
                              onPressed: () => setState(() {
                                _iconPath = null;
                                _iconPreview = null;
                              }),
                            ),
                        ],
                      ),
                      if (_iconPath != null)
                        Text(
                          _iconPath!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.text(size: GhTextSize.x3s, mono: true, color: theme.muted.withValues(alpha: 0.6)),
                        ),
                      Text(
                        tr.icon_format_desc,
                        style: theme.text(size: GhTextSize.x3s, color: theme.muted.withValues(alpha: 0.4)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.only(top: theme.space(5)),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.line)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: theme.space(3),
                children: [
                  GhFieldLabel(tr.other_settings_label),
                  _switchRow(
                    theme,
                    label: tr.init_git_label,
                    description: _gitAvailable ? tr.init_git_desc : tr.init_git_unavailable,
                    checked: _initGit,
                    disabled: locked || !_gitAvailable,
                    onChanged: (v) => setState(() => _initGit = v),
                  ),
                  if (_initGit && _gitAvailable)
                    _box(
                      theme,
                      padding: 3.5,
                      children: [
                        Wrap(
                          spacing: theme.space(5),
                          runSpacing: theme.space(2),
                          children: [
                            GhCheckbox(
                              checked: _gitignore,
                              disabled: _busy,
                              onChanged: (v) => setState(() => _gitignore = v),
                              child: Text(tr.git_option_gitignore),
                            ),
                            GhCheckbox(
                              checked: _gitattributes,
                              disabled: _busy,
                              onChanged: (v) => setState(() => _gitattributes = v),
                              child: Text(tr.git_option_gitattributes),
                            ),
                            GhCheckbox(
                              checked: _readme,
                              disabled: _busy,
                              onChanged: (v) => setState(() => _readme = v),
                              child: Text(tr.git_option_readme),
                            ),
                          ],
                        ),
                        Row(
                          spacing: theme.space(3),
                          children: [
                            GhFieldLabel(tr.git_option_license),
                            Expanded(
                              child: Wrap(
                                spacing: theme.space(1.5),
                                runSpacing: theme.space(1.5),
                                children: [
                                  GhChoiceChip(
                                    label: tr.git_option_no_license,
                                    active: _license.isEmpty,
                                    tone: GhChoiceTone.muted,
                                    onPressed: () => setState(() => _license = ''),
                                  ),
                                  for (final lic in _licenses)
                                    GhChoiceChip(label: lic, active: _license == lic, onPressed: () => setState(() => _license = lic)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  if (_hasRemoteAuth)
                    Padding(
                      padding: EdgeInsets.only(top: theme.space(1)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: theme.space(2.5),
                        children: [
                          _switchRow(
                            theme,
                            label: tr.create_remote_label,
                            description: tr.create_remote_desc,
                            checked: _remoteEnabled,
                            disabled: locked || !_initGit || !_gitAvailable,
                            onChanged: (v) => setState(() {
                              _remoteEnabled = v;
                              if (v && !_initGit) _initGit = true;
                            }),
                          ),
                          if (_remoteEnabled)
                            _box(
                              theme,
                              padding: 3,
                              children: [
                                Wrap(
                                  spacing: theme.space(1.5),
                                  runSpacing: theme.space(1.5),
                                  children: [
                                    if (auth?.github != null)
                                      GhChoiceChip(
                                        label: 'GitHub',
                                        active: _remoteProvider == 'github',
                                        onPressed: () => setState(() => _remoteProvider = 'github'),
                                      ),
                                    if (auth?.gitlab != null)
                                      GhChoiceChip(
                                        label: 'GitLab',
                                        active: _remoteProvider == 'gitlab',
                                        onPressed: () => setState(() => _remoteProvider = 'gitlab'),
                                      ),
                                  ],
                                ),
                                Row(
                                  spacing: theme.space(2),
                                  children: [
                                    for (final private in const [true, false])
                                      Expanded(
                                        child: GhChoiceChip(
                                          label: private ? tr.remote_private : tr.remote_public,
                                          active: _remotePrivate == private,
                                          tone: GhChoiceTone.mint,
                                          showCheck: false,
                                          expand: true,
                                          onPressed: () => setState(() => _remotePrivate = private),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _TemplateChip extends StatefulWidget {
  const _TemplateChip({required this.template, required this.active, required this.onPressed, required this.onPreview});

  final ProjectTemplate template;
  final bool active;
  final VoidCallback onPressed;
  final VoidCallback onPreview;

  @override
  State<_TemplateChip> createState() => _TemplateChipState();
}

class _TemplateChipState extends State<_TemplateChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final size = theme.space(5);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GhChoiceChip(label: widget.template.name, active: widget.active, onPressed: widget.onPressed),
          PositionedDirectional(
            top: -theme.space(2),
            end: -theme.space(2),
            child: Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onFocusChange: (value) => setState(() => _focused = value),
              child: AnimatedOpacity(
                opacity: _hovered || _focused ? 1 : 0,
                duration: GhDurations.color,
                child: GhPressable(
                  onPressed: widget.onPreview,
                  semanticLabel: ghTr('template_preview_aria', args: {'name': widget.template.name}),
                  borderRadius: BorderRadius.circular(size),
                  builder: (context, states) => GhAnimatedBox(
                    width: size,
                    height: size,
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(size),
                    border: Border.all(color: states.active ? theme.accentDim : theme.line),
                    boxShadow: GhShadows.md(),
                    alignment: Alignment.center,
                    child: GhIcon(GhIcons.bookOpen, size: theme.space(3), color: states.active ? theme.accentBright : theme.muted),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
