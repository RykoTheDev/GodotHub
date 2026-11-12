import 'dart:ui';

enum GhThemeMode {
  dark,
  light;

  static GhThemeMode parse(String value) => value == 'light' ? GhThemeMode.light : GhThemeMode.dark;
}

GhThemeMode resolveThemeMode(String setting, Brightness platformBrightness) {
  if (setting == 'system') {
    return platformBrightness == Brightness.light ? GhThemeMode.light : GhThemeMode.dark;
  }
  return GhThemeMode.parse(setting);
}

const String defaultAccent = '#457ff2';
const String defaultBackground = '#15171c';
const String defaultBackgroundLight = '#f8f9fa';
const int defaultRaisedContrast = 8;
const double radiusMdDefault = 10;

({String accentColor, String backgroundColor}) customThemeDefaults(GhThemeMode mode) {
  return (accentColor: defaultAccent, backgroundColor: mode == GhThemeMode.light ? defaultBackgroundLight : defaultBackground);
}

List<int> hexToRgb(String hex) {
  final clean = hex.replaceFirst('#', '');
  final full = clean.length == 3 ? clean.split('').map((c) => '$c$c').join() : clean;
  final digits = RegExp(r'^\s*[0-9a-fA-F]+').stringMatch(full)?.trim();
  final n = digits == null ? 0 : (int.tryParse(digits, radix: 16) ?? 0);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

int _jsRound(num v) => (v + 0.5).floor();

String rgbToHex(num r, num g, num b) {
  return '#${[r, g, b].map((v) => _jsRound(v).clamp(0, 255).toRadixString(16).padLeft(2, '0')).join()}';
}

String shiftHex(String hex, num amount) {
  final rgb = hexToRgb(hex);
  return rgbToHex(rgb[0] + amount, rgb[1] + amount, rgb[2] + amount);
}

bool isDarkColor(String hex) {
  final rgb = hexToRgb(hex);
  final lum = (0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2]) / 255;
  return lum < 0.5;
}

Color colorFromHex(String hex) {
  final clean = hex.replaceFirst('#', '');
  if (clean.length == 8) {
    final n = int.parse(clean, radix: 16);
    return Color(((n & 0xff) << 24) | (n >> 8));
  }
  final rgb = hexToRgb(hex);
  return Color.fromARGB(255, rgb[0], rgb[1], rgb[2]);
}

String colorToHex(Color color) {
  int c(double v) => (v * 255).round().clamp(0, 255);
  return rgbToHex(c(color.r), c(color.g), c(color.b));
}

class ThemePreset {
  const ThemePreset({
    required this.id,
    required this.name,
    required this.mode,
    required this.base,
    required this.surface,
    required this.raised,
    required this.overlay,
    required this.line,
    required this.outline,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.accentDim,
    required this.accentBright,
    required this.mint,
    required this.amber,
    required this.danger,
  });

  final String id;
  final String name;
  final GhThemeMode mode;
  final String base;
  final String surface;
  final String raised;
  final String overlay;
  final String line;
  final String outline;
  final String ink;
  final String muted;
  final String accent;
  final String accentDim;
  final String accentBright;
  final String mint;
  final String amber;
  final String danger;

  Map<String, String> toVars() => {
    '--color-base': base,
    '--color-surface': surface,
    '--color-raised': raised,
    '--color-overlay': overlay,
    '--color-line': line,
    '--color-outline': outline,
    '--color-ink': ink,
    '--color-muted': muted,
    '--color-accent': accent,
    '--color-accent-dim': accentDim,
    '--color-accent-bright': accentBright,
    '--color-mint': mint,
    '--color-amber': amber,
    '--color-danger': danger,
  };
}

const _darkNeutralOverlay = '#222329';
const _darkNeutralInk = '#f2f3f5';
const _darkNeutralMuted = '#949ba4';
const _fallbackMint = '#2fbf71';
const _fallbackAmber = '#f0b132';
const _fallbackDanger = '#f2555a';

ThemePreset buildCustomPalette(String accent, String background, {GhThemeMode mode = GhThemeMode.dark, num? raisedContrast}) {
  final light = mode == GhThemeMode.light;
  final contrast = raisedContrast ?? 8;
  final raisedShift = light ? -contrast : contrast;
  final line = shiftHex(background, light ? -18 : 28);
  return ThemePreset(
    id: 'custom',
    name: 'Custom',
    mode: mode,
    base: background,
    surface: shiftHex(background, light ? 15 : 9),
    raised: shiftHex(background, raisedShift),
    overlay: light ? shiftHex(background, -12) : _darkNeutralOverlay,
    line: line,
    outline: '#3a3d46',
    ink: light ? '#1b1c1f' : _darkNeutralInk,
    muted: light ? '#646b78' : _darkNeutralMuted,
    accent: accent,
    accentDim: shiftHex(accent, -45),
    accentBright: shiftHex(accent, light ? -30 : 35),
    mint: _fallbackMint,
    amber: _fallbackAmber,
    danger: _fallbackDanger,
  );
}

ThemePreset resolvePalette({
  required String accent,
  required String background,
  required GhThemeMode mode,
  required String presetId,
  num? raisedContrast,
}) {
  return themePreset(presetId) ?? buildCustomPalette(accent, background, mode: mode, raisedContrast: raisedContrast);
}

const radiusScale = <String, double>{
  '--radius-sm': 0.8,
  '--radius-md': 1.0,
  '--radius-lg': 1.4,
  '--radius-xl': 2.0,
  '--radius-tag': 1.0,
  '--radius-btn': 1.6,
  '--radius-dropdown-btn': 1.3,
  '--radius-dropdown': 1.3,
  '--radius-item': 2.2,
  '--radius-tile': 1.6,
  '--radius-menu': 2.4,
  '--radius-card': 2.4,
  '--radius-modal': 3.0,
};

Map<String, double> radiusVars([double mdPx = radiusMdDefault]) {
  return {for (final entry in radiusScale.entries) entry.key: mdPx * entry.value};
}

const categoryColors = [
  '#457ff2',
  '#f28b45',
  '#45c97f',
  '#e74c8a',
  '#a855f7',
  '#22d3ee',
  '#f59e0b',
  '#ef4444',
  '#10b981',
  '#6366f1',
  '#ec4899',
  '#14b8a6',
  '#f97316',
  '#8b5cf6',
  '#06b6d4',
  '#84cc16',
  '#d946ef',
  '#0ea5e9',
  '#eab308',
  '#3b82f6',
];

const tagColors = categoryColors;

String tagColor(String tag) {
  var hash = 0;
  for (final unit in tag.codeUnits) {
    final shifted = (hash.toSigned(32) << 5).toSigned(32);
    hash = unit + (shifted - hash);
  }
  return tagColors[hash.abs() % tagColors.length];
}

const accentPresetsDark = [
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
  '#facc15',
  '#8b5cf6',
  '#f23f42',
  '#22c55e',
  '#3b82f6',
  '#f43f5e',
];

const accentPresetsLight = [
  '#457ff2',
  '#5b75e6',
  '#7480e8',
  '#36a05b',
  '#e0a832',
  '#d9458e',
  '#00a1e8',
  '#2dc4b4',
  '#9d7ae0',
  '#ec7031',
  '#78b820',
  '#d1263f',
  '#1b9ce0',
  '#e8c420',
  '#8470e8',
  '#e04244',
  '#28b45a',
  '#4285d4',
  '#d94562',
];

const bgPresetsDark = [
  '#15171c',
  '#1a1c23',
  '#10131a',
  '#1e1f22',
  '#111214',
  '#13151a',
  '#0f1115',
  '#20232a',
  '#171a21',
  '#1c1e24',
  '#0d0e11',
  '#232630',
  '#1b1d24',
  '#101114',
  '#191b20',
  '#181a1e',
  '#1f2127',
  '#1a1c21',
  '#0e1014',
  '#1c1e23',
  '#121418',
];

const bgPresetsLight = [
  '#f8f9fa',
  '#ffffff',
  '#f0f2f5',
  '#f5f5f5',
  '#fafafa',
  '#eceff1',
  '#f3f4f6',
  '#f9fafb',
  '#eef1f5',
  '#f8f6f3',
  '#f2f6fc',
  '#faf5ef',
  '#edf2f7',
  '#f6f8fa',
  '#f1f3f5',
  '#e8ecf1',
  '#faf6f0',
];

const themePresets = <ThemePreset>[
  ThemePreset(
    id: 'atom-one-dark',
    name: 'Atom One Dark',
    mode: GhThemeMode.dark,
    base: '#282c34',
    surface: '#21252b',
    raised: '#2c313a',
    overlay: '#2c313a',
    line: '#3e4451',
    outline: '#3e4451',
    ink: '#abb2bf',
    muted: '#5c6370',
    accent: '#61afef',
    accentDim: '#4b8bbd',
    accentBright: '#82aaff',
    mint: '#98c379',
    amber: '#e5c07b',
    danger: '#e06c75',
  ),
  ThemePreset(
    id: 'nord',
    name: 'Nord',
    mode: GhThemeMode.dark,
    base: '#2e3440',
    surface: '#272c36',
    raised: '#3b4252',
    overlay: '#3b4252',
    line: '#434c5e',
    outline: '#434c5e',
    ink: '#eceff4',
    muted: '#8a94ad',
    accent: '#88c0d0',
    accentDim: '#5e81ac',
    accentBright: '#8fbcbb',
    mint: '#a3be8c',
    amber: '#ebcb8b',
    danger: '#bf616a',
  ),
  ThemePreset(
    id: 'catppuccin-latte',
    name: 'Catppuccin Latte',
    mode: GhThemeMode.light,
    base: '#eff1f5',
    surface: '#e6e9ef',
    raised: '#dce0e8',
    overlay: '#e6e9ef',
    line: '#ccd0da',
    outline: '#ccd0da',
    ink: '#4c4f69',
    muted: '#6c6f85',
    accent: '#1e66f5',
    accentDim: '#7287fd',
    accentBright: '#04a5e5',
    mint: '#40a02b',
    amber: '#df8e1d',
    danger: '#d20f39',
  ),
  ThemePreset(
    id: 'catppuccin-mocha',
    name: 'Catppuccin Mocha',
    mode: GhThemeMode.dark,
    base: '#1e1e2e',
    surface: '#313244',
    raised: '#45475a',
    overlay: '#313244',
    line: '#45475a',
    outline: '#45475a',
    ink: '#cdd6f4',
    muted: '#a6adc8',
    accent: '#89b4fa',
    accentDim: '#7287fd',
    accentBright: '#b4befe',
    mint: '#a6e3a1',
    amber: '#f9e2af',
    danger: '#f38ba8',
  ),
  ThemePreset(
    id: 'dracula',
    name: 'Dracula',
    mode: GhThemeMode.dark,
    base: '#282a36',
    surface: '#21222c',
    raised: '#343746',
    overlay: '#343746',
    line: '#44475a',
    outline: '#44475a',
    ink: '#f8f8f2',
    muted: '#6272a4',
    accent: '#bd93f9',
    accentDim: '#9a6fe0',
    accentBright: '#d6b4ff',
    mint: '#50fa7b',
    amber: '#f1fa8c',
    danger: '#ff5555',
  ),
  ThemePreset(
    id: 'github-dark',
    name: 'GitHub Dark',
    mode: GhThemeMode.dark,
    base: '#0d1117',
    surface: '#161b22',
    raised: '#21262d',
    overlay: '#161b22',
    line: '#30363d',
    outline: '#30363d',
    ink: '#e6edf3',
    muted: '#8b949e',
    accent: '#58a6ff',
    accentDim: '#388bfd',
    accentBright: '#79c0ff',
    mint: '#3fb950',
    amber: '#d29922',
    danger: '#f85149',
  ),
  ThemePreset(
    id: 'solarized-dark',
    name: 'Solarized Dark',
    mode: GhThemeMode.dark,
    base: '#002b36',
    surface: '#073642',
    raised: '#0a3a46',
    overlay: '#073642',
    line: '#0a3a46',
    outline: '#0a3a46',
    ink: '#93a1a1',
    muted: '#657b83',
    accent: '#268bd2',
    accentDim: '#2aa198',
    accentBright: '#6c71c4',
    mint: '#859900',
    amber: '#b58900',
    danger: '#dc322f',
  ),
  ThemePreset(
    id: 'gruvbox',
    name: 'Gruvbox',
    mode: GhThemeMode.dark,
    base: '#282828',
    surface: '#1d2021',
    raised: '#32302f',
    overlay: '#32302f',
    line: '#3c3836',
    outline: '#3c3836',
    ink: '#ebdbb2',
    muted: '#928374',
    accent: '#d65d0e',
    accentDim: '#b57614',
    accentBright: '#fe8019',
    mint: '#b8bb26',
    amber: '#fabd2f',
    danger: '#fb4934',
  ),
  ThemePreset(
    id: 'atom-one-light',
    name: 'Atom One Light',
    mode: GhThemeMode.light,
    base: '#fafafa',
    surface: '#f0f0f0',
    raised: '#e6e6e6',
    overlay: '#ececec',
    line: '#d8d8d8',
    outline: '#d8d8d8',
    ink: '#383a42',
    muted: '#a0a1a7',
    accent: '#4078f2',
    accentDim: '#3158b8',
    accentBright: '#0184bc',
    mint: '#50a14f',
    amber: '#c18401',
    danger: '#e45649',
  ),
  ThemePreset(
    id: 'nord-light',
    name: 'Nord Light',
    mode: GhThemeMode.light,
    base: '#e5e9f0',
    surface: '#eceff4',
    raised: '#d8dee9',
    overlay: '#eceff4',
    line: '#c8d0dc',
    outline: '#c8d0dc',
    ink: '#2e3440',
    muted: '#4c566a',
    accent: '#5e81ac',
    accentDim: '#81a1c1',
    accentBright: '#88c0d0',
    mint: '#a3be8c',
    amber: '#ebcb8b',
    danger: '#bf616a',
  ),
  ThemePreset(
    id: 'github-light',
    name: 'GitHub Light',
    mode: GhThemeMode.light,
    base: '#ffffff',
    surface: '#f6f8fa',
    raised: '#eaeef2',
    overlay: '#f6f8fa',
    line: '#d0d7de',
    outline: '#d0d7de',
    ink: '#1f2328',
    muted: '#656d76',
    accent: '#0969da',
    accentDim: '#0550ae',
    accentBright: '#218bff',
    mint: '#1a7f37',
    amber: '#9a6700',
    danger: '#cf222e',
  ),
  ThemePreset(
    id: 'solarized-light',
    name: 'Solarized Light',
    mode: GhThemeMode.light,
    base: '#fdf6e3',
    surface: '#eee8d5',
    raised: '#e3dcc8',
    overlay: '#f0ead9',
    line: '#d8d1bd',
    outline: '#d8d1bd',
    ink: '#657b83',
    muted: '#93a1a1',
    accent: '#268bd2',
    accentDim: '#2aa198',
    accentBright: '#6c71c4',
    mint: '#859900',
    amber: '#b58900',
    danger: '#dc322f',
  ),
  ThemePreset(
    id: 'gruvbox-light',
    name: 'Gruvbox Light',
    mode: GhThemeMode.light,
    base: '#fbf1c7',
    surface: '#f2e5bc',
    raised: '#ebdbb2',
    overlay: '#f2e5bc',
    line: '#d5c4a1',
    outline: '#d5c4a1',
    ink: '#3c3836',
    muted: '#928374',
    accent: '#458588',
    accentDim: '#689d6a',
    accentBright: '#83a598',
    mint: '#98971a',
    amber: '#d79921',
    danger: '#cc241d',
  ),
  ThemePreset(
    id: 'tokyo-night-day',
    name: 'Tokyo Night Day',
    mode: GhThemeMode.light,
    base: '#e1e2e7',
    surface: '#d4d6de',
    raised: '#c8cbd6',
    overlay: '#d4d6de',
    line: '#b6b9c8',
    outline: '#b6b9c8',
    ink: '#2f3b54',
    muted: '#6b7394',
    accent: '#2e7de9',
    accentDim: '#2653b8',
    accentBright: '#007197',
    mint: '#587539',
    amber: '#8c6c3e',
    danger: '#f52a65',
  ),
  ThemePreset(
    id: 'rose-pine-dawn',
    name: 'Rosé Pine Dawn',
    mode: GhThemeMode.light,
    base: '#faf4ed',
    surface: '#fffaf3',
    raised: '#f2e9e1',
    overlay: '#fffaf3',
    line: '#ece5dd',
    outline: '#ece5dd',
    ink: '#575279',
    muted: '#9893a5',
    accent: '#286983',
    accentDim: '#56949f',
    accentBright: '#907aa9',
    mint: '#56949f',
    amber: '#ea9d34',
    danger: '#b4637a',
  ),
  ThemePreset(
    id: 'everforest-light',
    name: 'Everforest Light',
    mode: GhThemeMode.light,
    base: '#f4ead5',
    surface: '#efe3cb',
    raised: '#e9dcc0',
    overlay: '#efe3cb',
    line: '#d9cdbb',
    outline: '#d9cdbb',
    ink: '#5c6a72',
    muted: '#859289',
    accent: '#3a94c5',
    accentDim: '#2e7fae',
    accentBright: '#df69ba',
    mint: '#8da101',
    amber: '#dfa000',
    danger: '#f85552',
  ),
  ThemePreset(
    id: 'ayu-light',
    name: 'Ayu Light',
    mode: GhThemeMode.light,
    base: '#fafafa',
    surface: '#f3f4f5',
    raised: '#e8e9ea',
    overlay: '#f3f4f5',
    line: '#d6d8da',
    outline: '#d6d8da',
    ink: '#5c6773',
    muted: '#8a9199',
    accent: '#399ee6',
    accentDim: '#55b4d4',
    accentBright: '#ff9940',
    mint: '#86b300',
    amber: '#ffb454',
    danger: '#f07178',
  ),
];

final lightThemePresets = themePresets.where((p) => p.mode == GhThemeMode.light).toList(growable: false);
final darkThemePresets = themePresets.where((p) => p.mode == GhThemeMode.dark).toList(growable: false);

ThemePreset? themePreset(String id) {
  for (final preset in themePresets) {
    if (preset.id == id) {
      return preset;
    }
  }
  return null;
}
