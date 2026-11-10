import 'fa_icon_data.dart';
import 'icons.g.dart';

const workspaceIcons = <String, FaIconData>{
  'briefcase': GhIcons.briefcase,
  'house': GhIcons.house,
  'user': GhIcons.user,
  'code': GhIcons.code,
  'gamepad': GhIcons.gamepad,
  'palette': GhIcons.palette,
  'graduation_cap': GhIcons.graduationCap,
  'rocket': GhIcons.rocket,
  'flask': GhIcons.flask,
  'heart': GhIcons.heart,
  'dumbbell': GhIcons.dumbbell,
  'book': GhIcons.book,
};

final workspaceIconKeys = workspaceIcons.keys.toList(growable: false);

FaIconData workspaceIcon(String key) => workspaceIcons[key] ?? GhIcons.briefcase;

const workspaceColorPresets = [
  '#457ff2',
  '#5865f2',
  '#7983f5',
  '#23a55a',
  '#f0b132',
  '#eb459e',
  '#00a8fc',
  '#2dd4bf',
  '#a78bfa',
  '#f97316',
  '#84cc16',
  '#e11d48',
  '#0ea5e9',
  '#8b5cf6',
];
