import 'dart:io';

import 'package:flutter/material.dart';

import '../../api/projects.dart';
import '../../design/design.dart';
import '../core/button.dart';
import '../core/i18n.dart';
import '../feedback/toast.dart';
import 'labelled_field.dart';

/// What a path field must point at.
enum GhPathKind {
  /// An existing folder (scan folders, a project location, a clone parent).
  folder,

  /// An existing file; see [GhPathField.extensions].
  file,

  /// Something that will be created: its parent folder must exist, and the
  /// path itself must not be an existing folder (an output file, for example).
  newFile,
}

typedef GhPathPicker = Future<String?> Function();

/// Checks a typed path and returns the message to show, or null when usable.
typedef GhPathValidator = String? Function(String raw);

/// Cleans up a typed or pasted path: trims it, removes the quotes Windows'
/// "Copy as path" adds, and expands a leading `~` on macOS and Linux.
String ghNormalizePath(String raw) {
  var path = raw.trim();
  if (path.length >= 2 && ((path.startsWith('"') && path.endsWith('"')) || (path.startsWith("'") && path.endsWith("'")))) {
    path = path.substring(1, path.length - 1).trim();
  }
  if (!Platform.isWindows && (path == '~' || path.startsWith('~/'))) {
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) path = home + path.substring(1);
  }
  return path;
}

bool _isAbsolute(String path) {
  if (Platform.isWindows) return RegExp(r'^([A-Za-z]:[\\/]|\\\\|//)').hasMatch(path);
  return path.startsWith('/');
}

String _parentOf(String path) {
  final trimmed = path.replaceAll(RegExp(r'[\\/]+$'), '');
  final idx = trimmed.lastIndexOf(RegExp(r'[\\/]'));
  if (idx <= 0) return trimmed.isEmpty ? path : trimmed.substring(0, idx + 1);
  // Keep the separator after a drive letter: `C:\` not `C:`.
  return RegExp(r'^[A-Za-z]:$').hasMatch(trimmed.substring(0, idx)) ? trimmed.substring(0, idx + 1) : trimmed.substring(0, idx);
}

/// The validation message for [raw] as a [kind] path, or null when it is
/// usable. Touches the file system once, so call it when the user commits a
/// value (Enter, Browse, Apply, submitting the form), not on every keystroke.
String? ghPathError(String raw, GhPathKind kind, {bool required = true, List<String> extensions = const []}) {
  final path = ghNormalizePath(raw);
  if (path.isEmpty) return required ? ghTr('path_error_required') : null;
  if (!_isAbsolute(path)) return ghTr('path_error_relative');
  final type = FileSystemEntity.typeSync(path);
  switch (kind) {
    case GhPathKind.folder:
      if (type == FileSystemEntityType.notFound) return ghTr('path_error_folder_not_found');
      if (type != FileSystemEntityType.directory) return ghTr('path_error_not_a_folder');
    case GhPathKind.file:
      if (type == FileSystemEntityType.notFound) return ghTr('path_error_file_not_found');
      if (type == FileSystemEntityType.directory) return ghTr('path_error_not_a_file');
      if (extensions.isNotEmpty && !extensions.any((e) => path.toLowerCase().endsWith('.${e.toLowerCase()}'))) {
        return ghTr('path_error_extension', args: {'extensions': extensions.map((e) => '.$e').join(', ')});
      }
    case GhPathKind.newFile:
      if (type == FileSystemEntityType.directory) return ghTr('path_error_not_a_file');
      if (FileSystemEntity.typeSync(_parentOf(path)) != FileSystemEntityType.directory) return ghTr('path_error_parent_missing');
  }
  return null;
}

/// The one path input in the app: an editable, monospace field the user can
/// type or paste into, plus a Browse button that opens the native picker.
///
/// A value is committed with Enter, the Apply button ([showApply]) or a pick
/// from Browse; it is validated then and [onCommitted] receives the cleaned
/// path only when it is valid. Typing clears a shown error until the next
/// commit. Forms that read [controller] on submit should set [showErrors]
/// after a submit attempt so the current text is validated in place.
///
/// The field renders its own label, hint and error through
/// [GhLabelledField]; pass [error] for form-level problems such as "a folder
/// with this name already exists".
class GhPathField extends StatefulWidget {
  const GhPathField({
    super.key,
    required this.controller,
    required this.kind,
    this.label,
    this.hint,
    this.error,
    this.onCommitted,
    this.onChanged,
    this.pick,
    this.extensions = const [],
    this.placeholder,
    this.enabled = true,
    this.autofocus = false,
    this.required = true,
    this.optional = false,
    this.showErrors = false,
    this.showApply = false,
    this.compactBrowse = false,
    this.focusNode,
    this.validator,
    this.browseLabel,
    this.applyLabel,
    this.clearOnCommit = false,
    this.onPickError,
    this.onSubmitted,
  }) : assert(pick != null || kind == GhPathKind.folder, 'File paths need their own picker (image, save path, data file...)');

  final TextEditingController controller;
  final GhPathKind kind;
  final String? label;
  final String? hint;
  final String? error;
  final ValueChanged<String>? onCommitted;
  final ValueChanged<String>? onChanged;

  /// Opens the native picker. Defaults to the folder picker; file kinds must
  /// pass the picker that matches them (for example `pickSavePath`).
  final GhPathPicker? pick;
  final List<String> extensions;
  final String? placeholder;
  final bool enabled;
  final bool autofocus;

  /// An empty value is an error. Turn off for optional paths.
  final bool required;

  /// Marks the label as optional.
  final bool optional;
  final bool showErrors;

  /// Shows an explicit Apply button while the text differs from the last
  /// committed value, for fields that save immediately (settings).
  final bool showApply;

  /// Icon-only Browse (and Apply) buttons for dense rows.
  final bool compactBrowse;
  final FocusNode? focusNode;

  /// Replaces the [kind] check with a field-specific one, for paths with
  /// their own rules (an export output may be relative to the project, for
  /// example). Receives the raw text; normalize it with [ghNormalizePath].
  final GhPathValidator? validator;

  /// Overrides the Browse button text (and its tooltip in [compactBrowse]).
  final String? browseLabel;

  /// Overrides the Apply button text, for example "Add folder" on a field
  /// that adds to a list.
  final String? applyLabel;

  /// Empties the field after each commit, for fields that add to a list.
  final bool clearOnCommit;

  /// Called when the native picker fails. Defaults to an error toast.
  final ValueChanged<Object>? onPickError;

  /// Called after Enter commits a valid path (not after Browse or Apply), for
  /// forms that submit on Enter.
  final ValueChanged<String>? onSubmitted;

  @override
  State<GhPathField> createState() => _GhPathFieldState();
}

class _GhPathFieldState extends State<GhPathField> {
  late String _committed = widget.controller.text;
  bool _touched = false;
  String? _error;
  FocusNode? _ownNode;

  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode(debugLabel: 'GhPathField'));

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
    _node.addListener(_onFocus);
    if (widget.showErrors) _validate();
  }

  @override
  void didUpdateWidget(GhPathField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
      _committed = widget.controller.text;
    }
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownNode)?.removeListener(_onFocus);
      _node.addListener(_onFocus);
    }
    if (widget.showErrors && !oldWidget.showErrors) _validate();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _node.removeListener(_onFocus);
    _ownNode?.dispose();
    super.dispose();
  }

  void _onText() {
    if (_error != null || _touched) {
      setState(() {
        _error = null;
        _touched = false;
      });
    } else if (widget.showApply) {
      setState(() {});
    }
  }

  void _onFocus() {
    // Leaving the field validates what was typed so a mistake is visible
    // before the user reaches the submit button.
    if (!_node.hasFocus && widget.controller.text.trim().isNotEmpty && widget.controller.text != _committed) _validate();
  }

  String? _validate() {
    final validator = widget.validator;
    final error = validator != null
        ? validator(widget.controller.text)
        : ghPathError(widget.controller.text, widget.kind, required: widget.required, extensions: widget.extensions);
    setState(() {
      _touched = true;
      _error = error;
    });
    return error;
  }

  bool _commit() {
    if (!widget.enabled) return false;
    if (_validate() != null) return false;
    _accept(ghNormalizePath(widget.controller.text));
    return true;
  }

  void _submit() {
    final path = ghNormalizePath(widget.controller.text);
    if (_commit()) widget.onSubmitted?.call(path);
  }

  void _accept(String path) {
    final shown = widget.clearOnCommit ? '' : path;
    if (shown != widget.controller.text) {
      widget.controller.value = TextEditingValue(
        text: shown,
        selection: TextSelection.collapsed(offset: shown.length),
      );
    }
    setState(() {
      _committed = shown;
      _error = null;
      _touched = false;
    });
    widget.onCommitted?.call(path);
  }

  Future<void> _browse() async {
    final picker = widget.pick ?? ProjectsApi.pickFolder;
    String? picked;
    try {
      picked = await picker();
    } catch (e) {
      if (!mounted) return;
      final onPickError = widget.onPickError;
      if (onPickError != null) {
        onPickError(e);
      } else {
        ghToasts.pushToast(GhToastType.error, '$e');
      }
      return;
    }
    if (!mounted || picked == null || picked.isEmpty) return;
    // The native dialog only returns paths that exist (or, for a save dialog,
    // can be created), so a pick is accepted as is.
    final path = ghNormalizePath(picked);
    widget.onChanged?.call(path);
    _accept(path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final dirty = widget.showApply && widget.controller.text != _committed;
    final error = widget.error ?? (_touched || widget.showErrors ? _error : null);
    final browseLabel = widget.browseLabel ?? ghTr('browse');
    final applyLabel = widget.applyLabel ?? ghTr('path_apply');
    final row = Row(
      spacing: theme.space(2),
      children: [
        Expanded(
          child: GhFieldInput(
            controller: widget.controller,
            focusNode: _node,
            autofocus: widget.autofocus,
            enabled: widget.enabled,
            mono: true,
            textDirection: TextDirection.ltr,
            placeholder: widget.placeholder ?? ghTr('path_placeholder'),
            semanticLabel: widget.label == null ? ghTr('path_input_label') : null,
            invalid: error != null,
            onChanged: widget.onChanged,
            onSubmitted: (_) => _submit(),
          ),
        ),
        if (dirty && widget.compactBrowse)
          GhIconButton(
            key: const ValueKey('path-apply'),
            icon: GhIcons.check,
            onPressed: widget.enabled ? _commit : null,
            tooltip: applyLabel,
            semanticLabel: applyLabel,
            variant: GhButtonVariant.primary,
          )
        else if (dirty)
          GhButton(
            key: const ValueKey('path-apply'),
            onPressed: widget.enabled ? _commit : null,
            icon: GhIcons.check,
            label: applyLabel,
            variant: GhButtonVariant.primary,
          ),
        if (widget.compactBrowse)
          GhIconButton(
            key: const ValueKey('path-browse'),
            icon: GhIcons.folder,
            onPressed: widget.enabled ? _browse : null,
            tooltip: browseLabel,
            semanticLabel: browseLabel,
            variant: GhButtonVariant.outline,
          )
        else
          GhButton(
            key: const ValueKey('path-browse'),
            onPressed: widget.enabled ? _browse : null,
            label: browseLabel,
            icon: GhIcons.folder,
            variant: GhButtonVariant.outline,
          ),
      ],
    );
    if (widget.label == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(1.5),
        children: [
          GhFieldScope(label: ghTr('path_input_label'), describedBy: error ?? widget.hint, invalid: error != null, child: row),
          if (error != null) GhFieldMessage(error, error: true) else if (widget.hint != null) GhFieldMessage(widget.hint!),
        ],
      );
    }
    return GhLabelledField(label: widget.label!, hint: widget.hint, error: error, optional: widget.optional, child: row);
  }
}
