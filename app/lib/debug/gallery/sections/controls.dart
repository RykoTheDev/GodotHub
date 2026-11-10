import 'package:flutter/material.dart';

import '../../../design/design.dart';
import '../../../ui/controls/checkbox.dart';
import '../../../ui/controls/feature_setup_picker.dart';
import '../../../logic/features.dart';
import '../../../ui/controls/hsv_color_picker.dart';
import '../../../ui/controls/key_recorder.dart';
import '../../../ui/controls/search_bar.dart';
import '../../../ui/controls/slider.dart';
import '../../../ui/controls/toggle.dart';
import '../gallery_kit.dart';

final controlsSections = [
  GallerySection('Toggle', (context) => const _Toggles()),
  GallerySection('Checkbox', (context) => const _Checkboxes()),
  GallerySection('Slider', (context) => const _Sliders()),
  GallerySection('Search bar', (context) => const _SearchBars()),
  GallerySection('Key recorder', (context) => const _KeyRecorders()),
  GallerySection('Color picker', (context) => const _ColorPickers()),
  GallerySection('Feature setup', (context) => const _FeatureSetups()),
];

class _Toggles extends StatefulWidget {
  const _Toggles();

  @override
  State<_Toggles> createState() => _TogglesState();
}

class _TogglesState extends State<_Toggles> {
  bool _value = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GalleryGroup(
          title: 'Interactive',
          children: [
            GalleryItem(
              label: _value ? 'on' : 'off',
              child: GhToggle(checked: _value, onChanged: (v) => setState(() => _value = v), label: 'Demo toggle'),
            ),
          ],
        ),
        for (final checked in [false, true])
          GalleryGroup(
            title: checked ? 'Checked' : 'Unchecked',
            children: [
              GalleryStates(
                builder: (context, enabled) => GhToggle(checked: checked, disabled: !enabled, onChanged: (_) {}, label: 'Toggle'),
              ),
            ],
          ),
        GalleryGroup(
          title: 'Right to left',
          children: [
            for (final checked in [false, true])
              GalleryItem(
                label: checked ? 'rtl on' : 'rtl off',
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: GhToggle(checked: checked, onChanged: (_) {}),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Checkboxes extends StatefulWidget {
  const _Checkboxes();

  @override
  State<_Checkboxes> createState() => _CheckboxesState();
}

class _CheckboxesState extends State<_Checkboxes> {
  final _items = [true, false, true];

  bool get _all => _items.every((v) => v);
  bool get _some => _items.any((v) => v) && !_all;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GalleryGroup(
          title: 'Interactive',
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GhCheckbox(
                  checked: _all,
                  indeterminate: _some,
                  onChanged: (v) => setState(() => _items.fillRange(0, _items.length, v)),
                  child: const Text('Select all'),
                ),
                for (var i = 0; i < _items.length; i++)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 24, top: 8),
                    child: GhCheckbox(checked: _items[i], onChanged: (v) => setState(() => _items[i] = v), child: Text('Item ${i + 1}')),
                  ),
              ],
            ),
          ],
        ),
        for (final (title, checked, indeterminate) in [
          ('Unchecked', false, false),
          ('Checked', true, false),
          ('Indeterminate', false, true),
        ])
          GalleryGroup(
            title: title,
            children: [
              GalleryStates(
                builder: (context, enabled) => GhCheckbox(
                  checked: checked,
                  indeterminate: indeterminate,
                  disabled: !enabled,
                  onChanged: (_) {},
                  child: const Text('Include addons'),
                ),
              ),
            ],
          ),
        GalleryGroup(
          title: 'Without label',
          children: [
            GalleryStates(
              builder: (context, enabled) => GhCheckbox(checked: true, disabled: !enabled, onChanged: (_) {}, label: 'Select row'),
            ),
          ],
        ),
      ],
    );
  }
}

class _Sliders extends StatefulWidget {
  const _Sliders();

  @override
  State<_Sliders> createState() => _SlidersState();
}

class _SlidersState extends State<_Sliders> {
  double _density = 1.05;
  double _radius = 7;
  double _plain = 40;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    Widget box(Widget child) => SizedBox(width: 380, child: child);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GalleryGroup(
          title: 'Interactive',
          children: [
            GalleryItem(
              label: 'label, display, default 1.05',
              child: box(
                GhSlider(
                  label: 'Density',
                  value: _density,
                  min: 0.75,
                  max: 1.25,
                  step: 0.05,
                  defaultValue: 1.05,
                  display: Text('${(_density * 100).round()}%'),
                  onChanged: (v) => setState(() => _density = v),
                ),
              ),
            ),
            GalleryItem(
              label: 'display, default 7',
              child: box(
                GhSlider(
                  value: _radius,
                  min: 0,
                  max: 20,
                  defaultValue: 7,
                  display: Text('${_radius.round()}px'),
                  onChanged: (v) => setState(() => _radius = v),
                ),
              ),
            ),
            GalleryItem(
              label: 'bare',
              child: box(GhSlider(value: _plain, min: 0, max: 100, onChanged: (v) => setState(() => _plain = v))),
            ),
          ],
        ),
        for (final value in [0.0, 35.0, 100.0])
          GalleryGroup(
            title: 'Value ${value.round()}',
            children: [
              GalleryStates(
                states: const [GalleryState.normal, GalleryState.hover, GalleryState.focus, GalleryState.disabled],
                builder: (context, enabled) => box(
                  GhSlider(
                    label: 'Volume',
                    value: value,
                    min: 0,
                    max: 100,
                    defaultValue: 50,
                    disabled: !enabled,
                    display: Text('${value.round()}%'),
                    onChanged: (_) {},
                  ),
                ),
              ),
            ],
          ),
        GalleryGroup(
          title: 'Reset button states',
          children: [
            GalleryStates(
              builder: (context, enabled) => SizedBox(
                width: 220,
                child: GhSlider(value: 30, min: 0, max: 100, defaultValue: 50, disabled: !enabled, onChanged: (_) {}),
              ),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Right to left (track stays ltr)',
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: box(
                GhSlider(
                  label: 'Volume',
                  value: 70,
                  min: 0,
                  max: 100,
                  defaultValue: 50,
                  display: Text('70%', style: TextStyle(color: theme.ink)),
                  onChanged: (_) {},
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SearchBars extends StatefulWidget {
  const _SearchBars();

  @override
  State<_SearchBars> createState() => _SearchBarsState();
}

class _SearchBarsState extends State<_SearchBars> {
  String _query = '';
  int _caret = 0;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    Widget box(Widget child) => SizedBox(width: 420, child: child);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GalleryGroup(
          title: 'Interactive',
          children: [
            GalleryItem(
              label: 'query "$_query" caret $_caret',
              child: box(
                GhSearchBar(value: _query, onChanged: (v) => setState(() => _query = v), onCaretChange: (c) => setState(() => _caret = c)),
              ),
            ),
            GalleryItem(
              label: 'with overlay child',
              child: box(
                GhSearchBar(
                  value: _query,
                  placeholder: 'Search the asset library...',
                  onChanged: (v) => setState(() => _query = v),
                  overlay: _query.isEmpty
                      ? null
                      : Positioned(
                          left: 0,
                          right: 0,
                          top: theme.space(12) + 8,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.overlay,
                              border: Border.all(color: theme.line),
                              borderRadius: BorderRadius.circular(theme.radiusMenu),
                            ),
                            child: Text(
                              'Suggestions for "$_query"',
                              style: theme.text(size: GhTextSize.xs, color: theme.muted),
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        for (final value in ['', 'godot'])
          GalleryGroup(
            title: value.isEmpty ? 'Empty' : 'With value',
            children: [
              GalleryStates(
                states: const [GalleryState.normal, GalleryState.hover, GalleryState.pressed, GalleryState.focus],
                builder: (context, enabled) => SizedBox(
                  width: 300,
                  child: GhSearchBar(value: value, onChanged: (_) {}),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _KeyRecorders extends StatefulWidget {
  const _KeyRecorders();

  @override
  State<_KeyRecorders> createState() => _KeyRecordersState();
}

class _KeyRecordersState extends State<_KeyRecorders> {
  String _key = 'k';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GalleryGroup(
          title: 'Interactive (click, press a key, Esc cancels)',
          children: [
            SizedBox(
              width: 420,
              child: GhKeyRecorder(value: _key, onChanged: (v) => setState(() => _key = v), onReset: () => setState(() => _key = 'p')),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Values',
          children: [
            for (final (label, value, mac) in [('default p', 'p', false), ('space', ' ', false), ('none', '', false), ('mac', 'k', true)])
              GalleryItem(
                label: label,
                child: SizedBox(
                  width: 380,
                  child: GhKeyRecorder(value: value, isMac: mac, onChanged: (_) {}, onReset: () {}),
                ),
              ),
          ],
        ),
        GalleryGroup(
          title: 'Button states',
          children: [
            GalleryStates(
              states: const [GalleryState.normal, GalleryState.hover, GalleryState.pressed, GalleryState.focus],
              builder: (context, enabled) => SizedBox(
                width: 340,
                child: GhKeyRecorder(value: 'k', onChanged: (_) {}, onReset: () {}),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ColorPickers extends StatefulWidget {
  const _ColorPickers();

  @override
  State<_ColorPickers> createState() => _ColorPickersState();
}

class _ColorPickersState extends State<_ColorPickers> {
  String _hex = '#4f7cff';

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GalleryGroup(
          title: 'Interactive',
          children: [
            GalleryItem(
              label: _hex,
              child: GhHsvColorPicker(value: _hex, onChanged: (v) => setState(() => _hex = v)),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorFromHex(_hex),
                borderRadius: BorderRadius.circular(theme.radiusLg),
                border: Border.all(color: theme.line),
              ),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Values and sizes',
          children: [
            for (final (hex, size) in [('#ff0000', 140.0), ('#2fbf71', 140.0), ('#ffffff', 140.0), ('#000000', 140.0), ('#f0b132', 240.0)])
              GalleryItem(
                label: '$hex ${size.round()}',
                child: GhHsvColorPicker(value: hex, size: size, onChanged: (_) {}),
              ),
          ],
        ),
      ],
    );
  }
}

class _FeatureSetups extends StatefulWidget {
  const _FeatureSetups();

  @override
  State<_FeatureSetups> createState() => _FeatureSetupsState();
}

class _FeatureSetupsState extends State<_FeatureSetups> {
  Set<GhFeatureId> _enabled = GhSetupProfile.essentials.features.toSet();
  Set<GhFeatureId> _custom = {GhFeatureId.news, GhFeatureId.vault};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GalleryGroup(
          title: 'Matching a profile (essentials)',
          children: [
            SizedBox(
              width: 760,
              child: GhFeatureSetupPicker(enabled: _enabled, onChanged: (v) => setState(() => _enabled = v)),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Custom selection (opens customizing)',
          children: [
            SizedBox(
              width: 760,
              child: GhFeatureSetupPicker(enabled: _custom, onChanged: (v) => setState(() => _custom = v)),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Profile card states',
          children: [
            GalleryStates(
              states: const [GalleryState.normal, GalleryState.hover, GalleryState.focus],
              builder: (context, enabled) => SizedBox(
                width: 760,
                child: GhFeatureSetupPicker(enabled: const {}, onChanged: (_) {}),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
