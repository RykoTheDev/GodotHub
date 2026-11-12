import 'package:flutter/material.dart';

import '../../../design/design.dart';
import '../../../ui/core/button.dart';
import '../../../ui/core/tooltip.dart';
import '../gallery_kit.dart';

final foundationSections = [
  GallerySection('Colors', (context) => const _Colors()),
  GallerySection('Typography', (context) => const _Typography()),
  GallerySection('Radii and shadows', (context) => const _RadiiShadows()),
  GallerySection('Icons', (context) => const _Icons()),
  GallerySection('Buttons', (context) => const _Buttons()),
];

class _Colors extends StatelessWidget {
  const _Colors();

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final vars = theme.toVars();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GalleryGroup(
          title: 'Theme tokens',
          spacing: 10,
          children: [
            for (final entry in vars.entries)
              GalleryItem(
                label: '${entry.key.replaceFirst('--color-', '')} ${entry.value}',
                child: Container(
                  width: 112,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorFromHex(entry.value),
                    borderRadius: BorderRadius.circular(theme.radiusMd),
                    border: Border.all(color: theme.line),
                  ),
                ),
              ),
          ],
        ),
        GalleryGroup(
          title: 'Category and tag colors',
          spacing: 6,
          children: [
            for (final hex in categoryColors)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: colorFromHex(hex), shape: BoxShape.circle),
              ),
          ],
        ),
        GalleryGroup(
          title: 'Tag chips',
          spacing: 8,
          children: [
            for (final tag in const ['godot', 'jam', '2d', 'prototype', 'shipped', 'multiplayer']) _TagChip(tag: tag),
          ],
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final color = colorFromHex(tagColor(tag));
    return Container(
      padding: EdgeInsets.symmetric(horizontal: theme.space(1.5), vertical: theme.space(0.5)),
      decoration: BoxDecoration(color: colorFromHex('${tagColor(tag)}18'), borderRadius: BorderRadius.circular(theme.radiusTag)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: theme.space(1.5),
            height: theme.space(1.5),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: GhShadows.ring(const Color(0x33000000))),
          ),
          SizedBox(width: theme.space(1)),
          Text(
            tag,
            style: theme.text(size: GhTextSize.x3s, mono: true, color: color),
          ),
        ],
      ),
    );
  }
}

class _Typography extends StatelessWidget {
  const _Typography();

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final size in GhTextSize.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    'text-${_sizeName(size)}',
                    style: theme.text(size: GhTextSize.x3s, mono: true, color: theme.muted),
                  ),
                ),
                Expanded(
                  child: Text('The quick brown fox jumps over the lazy dog 0123', style: theme.text(size: size)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        for (final weight in const [GhWeight.normal, GhWeight.medium, GhWeight.semibold, GhWeight.bold])
          Text(
            'Inter weight ${weight.value}  Projects  Godot 4.5',
            style: theme.text(size: GhTextSize.base, weight: weight),
          ),
        const SizedBox(height: 12),
        Text('Google Sans Code 400  res://scenes/main.tscn', style: theme.text(size: GhTextSize.sm, mono: true)),
        Text(
          'Google Sans Code 500  v4.5.1-stable',
          style: theme.text(size: GhTextSize.sm, mono: true, weight: GhWeight.medium),
        ),
        const SizedBox(height: 12),
        Text('Привет мир  Γειά σου  Tiếng Việt  ąęłńśź', style: theme.text(size: GhTextSize.base)),
        Text(
          'UPPERCASE SEMIBOLD TITLE',
          style: theme.text(size: GhTextSize.x2l, weight: GhWeight.semibold, lineHeight: 1.25),
        ),
      ],
    );
  }
}

class _RadiiShadows extends StatelessWidget {
  const _RadiiShadows();

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    final radii = {
      'sm': theme.radiusSm,
      'md': theme.radiusMd,
      'lg': theme.radiusLg,
      'xl': theme.radiusXl,
      'tag': theme.radiusTag,
      'btn': theme.radiusBtn,
      'dropdown': theme.radiusDropdown,
      'item': theme.radiusItem,
      'tile': theme.radiusTile,
      'menu': theme.radiusMenu,
      'card': theme.radiusCard,
      'modal': theme.radiusModal,
    };
    final shadows = {
      'shadow-sm': GhShadows.sm(),
      'shadow-md': GhShadows.md(),
      'shadow-lg': GhShadows.lg(),
      'shadow-xl': GhShadows.xl(),
      'shadow-2xl': GhShadows.xl2(),
      'md black/20': GhShadows.md(const Color(0x33000000)),
      'lg accent/30': GhShadows.lg(theme.accent.withValues(alpha: 0.3)),
      'hover lift': GhShadows.hoverLift(),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GalleryGroup(
          title: 'Radii',
          children: [
            for (final entry in radii.entries)
              GalleryItem(
                label: 'rounded-${entry.key} ${entry.value.toStringAsFixed(1)}',
                child: Container(
                  width: 96,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.raised,
                    borderRadius: BorderRadius.circular(entry.value),
                    border: Border.all(color: theme.line),
                  ),
                ),
              ),
          ],
        ),
        GalleryGroup(
          title: 'Shadows',
          spacing: 28,
          children: [
            for (final entry in shadows.entries)
              GalleryItem(
                label: entry.key,
                child: Container(
                  width: 110,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(theme.radiusCard),
                    boxShadow: entry.value,
                  ),
                ),
              ),
            GalleryItem(
              label: 'shadow-inner',
              child: CustomPaint(
                foregroundPainter: InsetShadowPainter(borderRadius: BorderRadius.circular(theme.radiusCard)),
                child: Container(
                  width: 110,
                  height: 64,
                  decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(theme.radiusCard)),
                ),
              ),
            ),
          ],
        ),
        GalleryGroup(
          title: 'Gradients',
          children: [
            GalleryItem(
              label: 'bg-linear-to-r',
              child: Container(
                width: 160,
                height: 40,
                decoration: BoxDecoration(
                  gradient: GhGradients.toRight([theme.accent, theme.accentBright]),
                  borderRadius: BorderRadius.circular(theme.radiusMd),
                ),
              ),
            ),
            GalleryItem(
              label: 'bg-linear-to-t',
              child: Container(
                width: 160,
                height: 40,
                decoration: BoxDecoration(
                  gradient: GhGradients.toTop([theme.base, theme.base.withValues(alpha: 0)]),
                  borderRadius: BorderRadius.circular(theme.radiusMd),
                  border: Border.all(color: theme.line),
                ),
              ),
            ),
            GalleryItem(
              label: 'project icon mask',
              child: ShaderMask(
                shaderCallback: GhGradients.projectIconMask,
                blendMode: BlendMode.dstIn,
                child: Container(width: 120, height: 80, color: theme.accent),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Icons extends StatelessWidget {
  const _Icons();

  @override
  Widget build(BuildContext context) {
    final theme = GhTheme.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final entry in galleryIcons.entries)
          GhTooltip(
            message: entry.key,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: theme.raised, borderRadius: BorderRadius.circular(theme.radiusMd)),
              child: GhIcon(entry.value, size: theme.space(4), color: theme.ink),
            ),
          ),
      ],
    );
  }
}

class _Buttons extends StatelessWidget {
  const _Buttons();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final variant in GhButtonVariant.values)
          GalleryGroup(
            title: 'Button ${variant.name}',
            children: [
              GalleryStates(
                builder: (context, enabled) => GhButton(onPressed: enabled ? () {} : null, label: 'Confirm', variant: variant),
              ),
            ],
          ),
        GalleryGroup(
          title: 'Icon button',
          children: [
            GalleryStates(
              builder: (context, enabled) => GhIconButton(icon: GhIcons.x, onPressed: enabled ? () {} : null, tooltip: 'Close'),
            ),
          ],
        ),
      ],
    );
  }
}

const galleryIcons = <String, FaIconData>{
  'folderPlus': GhIcons.folderPlus,
  'import': GhIcons.import,
  'pause': GhIcons.pause,
  'play': GhIcons.play,
  'trash': GhIcons.trash,
  'download': GhIcons.download,
  'node': GhIcons.node,
  'chevronUp': GhIcons.chevronUp,
  'chevronDown': GhIcons.chevronDown,
  'chevronLeft': GhIcons.chevronLeft,
  'chevronRight': GhIcons.chevronRight,
  'x': GhIcons.x,
  'gear': GhIcons.gear,
  'plus': GhIcons.plus,
  'pin': GhIcons.pin,
  'grip': GhIcons.grip,
  'layoutGrid': GhIcons.layoutGrid,
  'layoutList': GhIcons.layoutList,
  'kanban': GhIcons.kanban,
  'language': GhIcons.language,
  'textDirection': GhIcons.textDirection,
  'sun': GhIcons.sun,
  'moon': GhIcons.moon,
  'pencil': GhIcons.pencil,
  'check': GhIcons.check,
  'clock': GhIcons.clock,
  'search': GhIcons.search,
  'filter': GhIcons.filter,
  'arrowUpDown': GhIcons.arrowUpDown,
  'tags': GhIcons.tags,
  'news': GhIcons.news,
  'chevronsLeft': GhIcons.chevronsLeft,
  'arrowUp': GhIcons.arrowUp,
  'externalLink': GhIcons.externalLink,
  'refresh': GhIcons.refresh,
  'wifiOff': GhIcons.wifiOff,
  'briefcase': GhIcons.briefcase,
  'house': GhIcons.house,
  'user': GhIcons.user,
  'universalAccess': GhIcons.universalAccess,
  'code': GhIcons.code,
  'gitBranch': GhIcons.gitBranch,
  'lock': GhIcons.lock,
  'terminal': GhIcons.terminal,
  'cloudArrowDown': GhIcons.cloudArrowDown,
  'history': GhIcons.history,
  'gamepad': GhIcons.gamepad,
  'palette': GhIcons.palette,
  'graduationCap': GhIcons.graduationCap,
  'rocket': GhIcons.rocket,
  'flask': GhIcons.flask,
  'heart': GhIcons.heart,
  'dumbbell': GhIcons.dumbbell,
  'book': GhIcons.book,
  'bookOpen': GhIcons.bookOpen,
  'bug': GhIcons.bug,
  'hardDrive': GhIcons.hardDrive,
  'checkCircle': GhIcons.checkCircle,
  'alertTriangle': GhIcons.alertTriangle,
  'info': GhIcons.info,
  'bomb': GhIcons.bomb,
  'copy': GhIcons.copy,
  'more': GhIcons.more,
  'bell': GhIcons.bell,
  'spinner': GhIcons.spinner,
  'circleCheck': GhIcons.circleCheck,
  'circleX': GhIcons.circleX,
  'star': GhIcons.star,
  'store': GhIcons.store,
  'stopwatch': GhIcons.stopwatch,
  'monitor': GhIcons.monitor,
  'folder': GhIcons.folder,
  'minus': GhIcons.minus,
  'square': GhIcons.square,
  'windowMaximize': GhIcons.windowMaximize,
  'windowRestore': GhIcons.windowRestore,
  'clone': GhIcons.clone,
  'plug': GhIcons.plug,
  'eye': GhIcons.eye,
  'eyeSlash': GhIcons.eyeSlash,
  'github': GhIcons.github,
  'gitlab': GhIcons.gitlab,
};

String _sizeName(GhTextSize size) => switch (size) {
  GhTextSize.x4s => '4xs',
  GhTextSize.x3s => '3xs',
  GhTextSize.x2s => '2xs',
  GhTextSize.x2l => '2xl',
  GhTextSize.x3l => '3xl',
  GhTextSize.x4l => '4xl',
  GhTextSize.x5l => '5xl',
  _ => size.name,
};
