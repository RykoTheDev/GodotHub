# Custom CSS in the New UI

GodotHub lets you inject your own CSS into the interface. You can restyle colors, spacing, fonts, corner radii, or even individual components, going beyond what the built-in settings can express. This page covers where the feature lives, how it works, which CSS variables and selectors you can use, and a few ready-to-paste recipes.

---

## Table of contents

- [Where to find it](#where-to-find-it)
- [How it works](#how-it-works)
- [Theme with CSS variables](#theme-with-css-variables)
  - [Colors](#colors)
  - [Corner radius](#corner-radius)
  - [Spacing](#spacing)
  - [Fonts](#fonts)
  - [Miscellaneous](#miscellaneous)
- [Built-in appearance options (for reference)](#built-in-appearance-options-for-reference)
- [Selectors and structural hooks](#selectors-and-structural-hooks)
- [Cascade and specificity tips](#cascade-and-specificity-tips)
- [Recipes](#recipes)
- [Caveats](#caveats)

---

## Where to find it

1. Open **Settings → Appearance**.
2. Scroll to the bottom. The **Custom CSS** box is the last section.
3. Type or paste your CSS into the editor.
4. Click **Apply CSS**. The styles apply immediately and you'll see a green "CSS applied" confirmation.
5. Click **Clear** to remove your CSS and restore the default look. The button only appears once you have CSS saved.

The editor is a plain monospace textarea. There's no CSS linter or validation. If you paste something broken, the app simply ignores or partially applies it, so keep a backup of your rules.

> The same setting exists in the Classic UI, and your custom CSS applies app-wide (both interfaces), because it's injected into the app's document root, not into a specific view. Use the `html[data-ui="new"]` scoping trick below if you only want your rules to affect the new UI.

---

## How it works

- Your CSS is saved with your app settings, so it persists across restarts.
- On apply, it's injected into `<head>` as a `<style id="app-user-css">` element.
- It's inserted after the app's own stylesheets and theme variables, so for rules of equal specificity, your CSS wins the cascade.
- It applies instantly when you hit **Apply CSS**. No restart needed. Clearing the field (and clicking the **Clear** button) removes the style element entirely.

---

## Theme with CSS variables

The entire UI is styled through a small set of CSS custom properties (variables). Every component reads its colors, radii, spacing, and fonts from these variables, so overriding variables is the most reliable way to restyle the app. Your tweaks keep working across layouts, components, and future updates.

Override them at `:root` (or on `.new-ui`) and they apply everywhere:

```css
:root {
  --color-accent: #ff6b6b;
  --color-ink: #ffffff;
  --color-muted: #c9cdd4;
}
```

### Colors

| Variable | What it controls |
|---|---|
| `--color-base` | Main app background |
| `--color-surface` | Secondary surfaces (cards' parent containers, panels) |
| `--color-raised` | Hover/raised surfaces (cards, buttons on hover) |
| `--color-overlay` | Overlays, dropdowns, menus, darker wells |
| `--color-line` | Borders, dividers, scrollbar thumb |
| `--color-outline` | Outlines (card borders, input borders) |
| `--color-ink` | Primary text |
| `--color-muted` | Secondary text, captions, meta info |
| `--color-accent` | Accent: active tabs, primary buttons, highlights |
| `--color-accent-dim` | Darker accent variant (borders, secondary accents) |
| `--color-accent-bright` | Brighter accent (links, highlights on accent) |
| `--color-mint` | Success / positive states |
| `--color-amber` | Warnings, ratings |
| `--color-danger` | Errors, destructive actions |

**Note on light/dark mode:** these variables always hold the resolved colors of whichever mode is currently active (Dark, Light, or System). There is no `.light` / `.dark` class on the document to scope rules against. The values themselves swap. Override a variable and it applies to the mode that's active; it does not apply to both modes at once unless you scope with a media query.

### Corner radius

Corner radii are scaled from the **Corner radius** slider, but each surface has its own variable, so you can fine-tune them independently:

| Variable | Typical use |
|---|---|
| `--radius-sm` | Small chips, tags |
| `--radius-md` | Base radius |
| `--radius-lg` | Larger panels |
| `--radius-xl` | Extra-large elements |
| `--radius-tag` | Tag/pill chips |
| `--radius-btn` | Buttons, inputs |
| `--radius-dropdown-btn` | Dropdown trigger buttons |
| `--radius-dropdown` | Dropdown menus |
| `--radius-item` | Cards / list items |
| `--radius-tile` | Icon tiles, thumbnails |
| `--radius-menu` | Context menus |
| `--radius-card` | Main card containers |
| `--radius-modal` | Modals / dialogs |

Example: sharp, minimal corners

```css
:root {
  --radius-sm: 3px;
  --radius-md: 5px;
  --radius-lg: 7px;
  --radius-xl: 9px;
  --radius-tag: 4px;
  --radius-btn: 6px;
  --radius-item: 6px;
  --radius-card: 8px;
  --radius-modal: 10px;
}
```

### Spacing

`--spacing` is the base unit behind all the padding / margin / gap utilities. The default is `4.5px`, scaled by the **Density** setting.

```css
:root {
  --spacing: 4px; /* tighter layout */
}
```

> `--spacing` must remain a length value (e.g. `4px`, `0.25rem`). It's registered with `@property`, so a non-length value will be ignored.

### Fonts

The new UI uses two font variables, which in turn pull from overridable `--app-*` variables:

- `--app-font-display` → `--font-display` (headings, display text)
- `--app-font-body` → `--font-body` (body text)
- `--font-mono` is the monospace font (code, tags, paths)

Swap fonts by overriding the `--app-*` variables. These are what the app itself reads, so this is the reliable way to change fonts:

```css
:root {
  --app-font-display: 'Space Grotesk', sans-serif;
  --app-font-body: 'Inter', sans-serif;
}
```

### Miscellaneous

- `--project-icon-opacity` is project icon transparency as a 0-1 fraction (set by the *Project Icon Opacity* slider). Overriding it in CSS also works.

---

## Built-in appearance options (for reference)

The Custom CSS box sits alongside these built-in options in **Settings → Appearance**. Knowing what they do helps you decide when to reach for CSS instead:

| Option | What it does | CSS equivalent |
|---|---|---|
| Theme preset | Full color themes (Atom One Dark, Nord, Dracula, Catppuccin, GitHub, Solarized, Gruvbox, Tokyo Night, Rosé Pine, Everforest, Ayu) + Custom | `--color-*` variables |
| Theme mode | Dark / Light / System | (colors resolve automatically) |
| Accent color | Custom accent picker with swatches | `--color-accent` |
| Background color | Custom background picker with swatches | `--color-base` |
| Raised contrast | How much "raised" surfaces contrast with the background | `--color-raised` |
| Corner radius | Global radius slider (0-20px) | `--radius-*` |
| UI density | Compact ↔ roomy spacing (75%–125%) | `--spacing` |
| Text size | Global text scale (85%–130%) | `font-size` on `:root` |
| Animation intensity | Full / Subtle / None | `.reduce-motion` class |
| View entrance | Fade / Slide / Scale entrance animations | n/a |
| Animation threshold | Only animate above N projects | n/a |
| Show scrollbar | Toggle the overlay scrollbar | `.hide-scrollbars` class |
| Animated numbers | Animate header counters | n/a |
| Project icon opacity | Transparency of project icons | `--project-icon-opacity` |
| **Custom CSS** | **Anything the above can't express** | **this whole page** |

---

## Selectors and structural hooks

The new UI is built with Tailwind, so most classes you'll see in the DOM are utility classes (`bg-overlay`, `text-ink`, `border-outline`, `rounded-item`). You can target them directly, but prefer variable overrides where possible (see [Cascade and specificity tips](#cascade-and-specificity-tips)).

Useful hooks that are stable across the app:

| Selector | What it is |
|---|---|
| `html[data-ui="new"]` | Set on `<html>` only when the **new UI** is active. Scope every new-UI-only rule with this so your CSS doesn't bleed into the Classic UI. |
| `body.new-ui` | The body class for the new UI (same purpose). |
| `.new-ui-scroll-viewport` | The scroll containers used by every view. |
| `.reduce-motion` | Added to `<html>` when animations are disabled (Animation intensity = None, or the OS prefers reduced motion). |
| `.hide-scrollbars` | Added to `<html>` when scrollbars are hidden. |
| `.focus-ring` | The keyboard-focus ring applied to interactive elements. |
| `.theme-transitioning` | Added briefly while colors animate during a theme change (useful if your rules fight with the fade). |
| `:root` | Applies to the whole document (both UIs). |

Example: new-UI-only rules

```css
html[data-ui="new"] {
  --color-accent: #f97316;
}

html[data-ui="new"] .new-ui-scroll-viewport {
  scroll-behavior: smooth;
}
```

---

## Cascade and specificity tips

1. **Override variables, not classes.** Components change class names between releases; the variables stay. Variable overrides also naturally cascade into hover/active/focus states.
2. **Your CSS loads last.** Injected after the app's stylesheets, so equal-specificity rules win without `!important`.
3. **Use `!important` sparingly**, only when a Tailwind utility has higher specificity than your rule and you can't easily target the variable instead.
4. **Scope to the new UI.** Custom CSS applies to both interfaces. Wrap new-UI tweaks in `html[data-ui="new"] { ... }` unless you intend them globally.
5. **Transitions can mask changes.** Color changes animate for about 350ms via `.theme-transitioning`. If your overrides look like they "fade in" oddly, that's expected. The animation is what makes theme changes feel smooth.

---

## Recipes

### 1. Change the accent color app-wide

```css
:root {
  --color-accent: #22c55e;
  --color-accent-dim: #15803d;
  --color-accent-bright: #4ade80;
}
```

(Setting all three keeps borders, highlights, and text variants consistent.)

### 2. Squarer, more minimal corners

```css
:root {
  --radius-sm: 2px;
  --radius-md: 4px;
  --radius-lg: 6px;
  --radius-xl: 8px;
  --radius-btn: 4px;
  --radius-item: 6px;
  --radius-tile: 6px;
  --radius-menu: 8px;
  --radius-card: 10px;
  --radius-modal: 12px;
}
```

### 3. Custom fonts

```css
:root {
  --app-font-display: 'Inter', sans-serif;
  --app-font-body: 'Inter', sans-serif;
  --font-mono: 'JetBrains Mono', monospace;
}
```

### 4. Compact layout

```css
html[data-ui="new"] {
  --spacing: 3.5px;          /* tighter gutters & gaps */
  --radius-item: 10px;       /* smaller cards */
  font-size: 92%;            /* smaller base text */
}
```

### 5. Restyle the new UI's scrollbar thumb

The new UI draws its own overlay scrollbar; its thumb takes its color from `--color-line` (and `--color-accent` while dragging):

```css
html[data-ui="new"] {
  --color-line: #2f3542; /* calmer thumb */
}
```

You can also target the scroll area's internals directly if you want a thicker thumb. The thumb is the 5px-wide pill inside each `.new-ui-scroll-viewport` track.

### 6. Softer, dimmer text

```css
:root {
  --color-ink: #dfe3ea;
  --color-muted: #7d8794;
}
```

### 7. Only-in-dark-mode tweaks (when following the system)

Since the theme variables resolve to the active mode, use a media query to scope rules to the OS preference when your theme mode is set to **System**:

```css
@media (prefers-color-scheme: dark) {
  html[data-ui="new"] {
    --color-accent: #818cf8;
  }
}
```

---

## Caveats

- **It's global.** Custom CSS applies to the Classic UI too. Scope with `html[data-ui="new"]` if that's not what you want.
- **No validation.** Malformed CSS is applied as-is; the app won't warn you. Keep a copy of working rules before experimenting.
- **Class names can change.** Prefer variables and the documented hooks over utility classes for anything you want to survive updates.
- **Reverting is easy.** Clear the box and hit the **Clear** button, or use *Reset* in Appearance to reset all appearance settings, including custom CSS.
