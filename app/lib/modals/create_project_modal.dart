import 'dart:io';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../api/git.dart';
import '../api/git_auth.dart';
import '../api/projects.dart';
import '../api/templates.dart';
import '../design/design.dart';
import '../logic/naming_convention.dart';
import '../projects/project_icon.dart';
import '../src/rust/api/types.dart';
import '../state/settings.dart';
import '../ui/controls/checkbox.dart';
import '../ui/controls/toggle.dart';
import '../ui/core/button.dart';
import '../ui/core/i18n.dart';
import '../ui/core/interaction.dart';
import '../ui/feedback/modal_shell.dart';
import '../ui/feedback/toast.dart';
import '../ui/reusables/labelled_field.dart';
import '../ui/reusables/modal_kit.dart';
import '../ui/reusables/path_field.dart';
import 'template_preview_modal.dart';

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

  /// The last location the user committed; the name check only touches
  /// the disk under this folder, never under half-typed text.
  late String _checkedLocation = ghNormalizePath(widget.defaultLocation ?? '');
  final FocusNode _nameNode = FocusNode(debugLabel: 'CreateProjectModal name');
  late final String _placeholder = widget.placeholder ?? createProjectPlaceholders[math.Random().nextInt(createProjectPlaceholders.length)];
  late String _version = widget.installedVersions.firstOrNull?.tag ?? '';
  late String? _templateId = widget.initialTemplateId;
  String? _iconPath;
  String? _iconPreview;
  String? _category;
  List<ProjectTemplate> _templates = const [];
  String? _error;
  String? _locationPathError;
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
    _location.addListener(
      () => setState(() {
        _error = null;
        _locationPathError = null;
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
    final location = _locationText;
    setState(() => _attempted = true);
    if (name.isEmpty || location.isEmpty || _nameError != null) {
      _nameNode.requestFocus();
      return;
    }
    final pathError = ghPathError(location, GhPathKind.folder);
    if (pathError != null) {
      setState(() => _locationPathError = pathError);
      return;
    }
    setState(() => _checkedLocation = location);
    if (_nameError != null) {
      _nameNode.requestFocus();
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

  String get _folderName =>
      applyNamingConvention(_name.text.trim(), NamingConvention.parse(ref.read(settingsProvider).value?.directoryNamingConvention ?? ''));

  String get _locationText => ghNormalizePath(_location.text);

  String get _targetPath {
    final dir = _locationText;
    final folder = _folderName;
    if (dir.isEmpty) return folder;
    final separator = dir.contains(r'\') && !dir.contains('/') ? r'\' : '/';
    return dir.endsWith('/') || dir.endsWith(r'\') ? '$dir$folder' : '$dir$separator$folder';
  }

  String? get _nameError {
    final name = _name.text.trim();
    if (name.isEmpty) return _attempted ? ghTr('create_project_name_required') : null;
    if (!isValidFolderName(_folderName)) return ghTr('folder_name_invalid_chars');
    if (_locationText.isNotEmpty && _locationText == _checkedLocation && Directory(_targetPath).existsSync()) {
      return ghTr('duplicate_folder_exists');
    }
    return null;
  }

  String? get _locationError => _attempted && _locationText.isEmpty ? ghTr('create_project_location_required') : _locationPathError;

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
              style: theme.text(size: GhTextSize.xs, weight: GhWeight.semibold, color: theme.ink),
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

  Widget _notice(GhTheme theme, {required Color color, required FaIconData icon, String? title, required String text}) => Semantics(
    liveRegion: true,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: theme.space(4), vertical: theme.space(3.5)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: theme.space(3),
        children: [
          Padding(
            padding: EdgeInsets.only(top: theme.space(0.5)),
            child: GhIcon(icon, size: theme.space(4), color: color),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: theme.space(1),
              children: [
                if (title != null)
                  Text(
                    title,
                    style: theme.text(size: GhTextSize.sm, weight: GhWeight.semibold, color: color),
                  ),
                SelectableText(
                  text,
                  style: theme.text(size: GhTextSize.xs, color: title != null ? theme.muted : color, lineHeight: 1.625),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _iconTile(GhTheme theme, Translations$common$en_US tr) {
    final icon = _iconPreview;
    final size = theme.space(16);
    final radius = BorderRadius.circular(theme.radiusTile);
    return Column(
      spacing: theme.space(1),
      children: [
        Tooltip(
          message: tr.icon_format_desc,
          child: GhPressable(
            key: const ValueKey('create-project-icon'),
            onPressed: _busy ? null : _pickIcon,
            borderRadius: radius,
            semanticLabel: _iconPath != null ? tr.change_icon : tr.choose_icon,
            builder: (context, states) => GhAnimatedBox(
              width: size,
              height: size,
              alignment: Alignment.center,
              color: theme.overlay,
              borderRadius: radius,
              border: Border.all(color: states.active ? theme.accentDim : theme.outline.withValues(alpha: 0.5)),
              child: ClipRRect(
                borderRadius: radius,
                child: icon != null
                    ? ProjectIconImage(url: icon)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: theme.space(1),
                        children: [
                          SvgPicture.string(
                            '<svg viewBox="0 0 24 24" fill="none" stroke="${_hex(states.active ? theme.accentBright : theme.muted)}" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="$_iconPresetPath"/></svg>',
                            width: theme.space(6),
                            height: theme.space(6),
                          ),
                          Text(
                            tr.choose_icon,
                            style: theme.text(size: GhTextSize.x3s, color: states.active ? theme.ink : theme.muted),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        if (_iconPath != null)
          GhButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                    _iconPath = null;
                    _iconPreview = null;
                  }),
            label: tr.reset,
            variant: GhButtonVariant.subtle,
            size: GhTextSize.x2s,
            paddingX: 2,
            paddingY: 1,
          ),
      ],
    );
  }

  Widget _versionControl(GhTheme theme, Translations$common$en_US tr, bool locked) {
    final auth = _gitAuth;
    return Container(
      padding: EdgeInsets.all(theme.space(4)),
      decoration: BoxDecoration(
        color: theme.overlay,
        borderRadius: BorderRadius.circular(theme.radiusItem),
        border: Border.all(color: theme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(3.5),
        children: [
          _switchRow(
            theme,
            label: tr.init_git_label,
            description: _gitAvailable ? tr.init_git_desc : tr.init_git_unavailable,
            checked: _initGit,
            disabled: locked || !_gitAvailable,
            onChanged: (v) => setState(() {
              _initGit = v;
              if (!v) _remoteEnabled = false;
            }),
          ),
          if (_initGit && _gitAvailable) ...[
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
            _section(theme, tr.git_option_license, [
              GhChoiceChip(
                label: tr.git_option_no_license,
                active: _license.isEmpty,
                tone: GhChoiceTone.muted,
                onPressed: () => setState(() => _license = ''),
              ),
              for (final lic in _licenses)
                GhChoiceChip(label: lic, active: _license == lic, onPressed: () => setState(() => _license = lic)),
            ]),
            if (_hasRemoteAuth) ...[
              Container(height: 1, color: theme.line),
              _switchRow(
                theme,
                label: tr.create_remote_label,
                description: tr.create_remote_desc,
                checked: _remoteEnabled,
                disabled: locked,
                onChanged: (v) => setState(() => _remoteEnabled = v),
              ),
              if (_remoteEnabled)
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
                    for (final private in const [true, false])
                      GhChoiceChip(
                        label: private ? tr.remote_private : tr.remote_public,
                        active: _remotePrivate == private,
                        tone: GhChoiceTone.mint,
                        onPressed: () => setState(() => _remotePrivate = private),
                      ),
                  ],
                ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _form(GhTheme theme, Translations$common$en_US tr, bool locked) {
    final versions = widget.installedVersions;
    final nameError = _nameError;
    final locationError = _locationError;
    final hasName = _name.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.space(5),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: theme.space(4),
          children: [
            Column(
              children: [
                ExcludeSemantics(
                  child: Visibility(
                    visible: false,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: GhFieldLabel(tr.project_name_label, inset: true),
                  ),
                ),
                SizedBox(height: theme.space(1.5)),
                _iconTile(theme, tr),
              ],
            ),
            Expanded(
              child: GhLabelledField(
                label: tr.project_name_label,
                error: nameError,
                hint: hasName ? ghTr('create_project_path_preview', args: {'path': _targetPath}) : tr.folder_name_hint,
                child: GhFieldInput(
                  controller: _name,
                  focusNode: _nameNode,
                  autofocus: true,
                  mono: true,
                  placeholder: _placeholder,
                  onSubmitted: (_) => _submit(),
                ),
              ),
            ),
          ],
        ),
        GhPathField(
          key: const ValueKey('create-project-location'),
          controller: _location,
          kind: GhPathKind.folder,
          label: tr.project_location_label,
          error: locationError,
          enabled: !locked,
          onCommitted: (path) => setState(() => _checkedLocation = path),
        ),
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
        if (_templates.isNotEmpty)
          _section(theme, tr.template_optional, [
            GhChoiceChip(label: tr.blank_template, active: _templateId == null, onPressed: () => setState(() => _templateId = null)),
            for (final tpl in _templates)
              _TemplateChip(
                template: tpl,
                active: _templateId == tpl.id,
                onPressed: () => setState(() => _templateId = tpl.id),
                onPreview: () => showGhModal<void>(
                  context,
                  (modal) => TemplatePreviewModal(template: tpl, onClose: () => Navigator.of(modal).pop()),
                ).ignore(),
              ),
          ]),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(2),
          children: [GhFieldLabel(ghTr('create_project_version_control')), _versionControl(theme, tr, locked)],
        ),
      ],
    );
  }

  Widget _result(GhTheme theme, Translations$common$en_US tr) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: theme.space(3),
    children: [
      if (_gitWarning != null)
        _notice(theme, color: theme.amber, icon: GhIcons.alertTriangle, title: tr.git_init_warning_title, text: _gitWarning!),
      if (_remoteSuccess != null)
        _notice(theme, color: theme.mint, icon: GhIcons.circleCheck, title: tr.remote_repo_created_title, text: _remoteSuccess!),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final tr = context.tr.common;
    ref.watch(settingsProvider);
    final locked = _busy || _finished;
    return GhModalShell(
      icon: GhIcon(GhIcons.folderPlus, size: theme.space(5), color: theme.accentBright),
      title: tr.new_project,
      maxWidth: GhModalWidth.x2l,
      showClose: false,
      onClose: _dismiss,
      initialFocus: _nameNode,
      error: _error,
      footer: _finished
          ? ghModalActions(
              primary: GhButton(onPressed: widget.onCreated, label: tr.create_project_done, variant: GhButtonVariant.primary, paddingX: 5),
            )
          : ghModalActions(
              trailing: [GhButton(onPressed: _busy ? null : widget.onClose, label: tr.cancel, disabledOpacity: 0.5)],
              primary: GhBusyButton(
                key: const ValueKey('create-project-submit'),
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
            ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(theme.space(6), theme.space(2), theme.space(6), theme.space(6)),
        child: _finished ? _result(theme, tr) : _form(theme, tr, locked),
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
