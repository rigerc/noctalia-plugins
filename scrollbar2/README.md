<a id="readme-top"></a>

<div align="center">

<h3>Scrollbar2</h3>

<p>
A configurable window bar with equal-width segments, animated focus tracking, and optional floating panel placement for <a href="https://github.com/noctalia-dev/noctalia-shell">Noctalia Shell</a>.
</p>

<p>
<img src="https://img.shields.io/badge/version-1.6.0-blue" alt="Version">
<img src="https://img.shields.io/badge/noctalia-%E2%89%A54.6.6-purple" alt="Min Noctalia Version">
<img src="https://img.shields.io/badge/license-MIT-green" alt="License">
</p>

</div>

---

## Features

- **Equal-width segments** — each open window gets an evenly sized slot on a horizontal track
- **Animated focus indicator** — spring, ease, linear, or smooth motion follows the active window
- **Two display modes** — embed in the Noctalia bar or render as a floating panel anchored to the screen edge
- **Window labels** — optional app icons and titles with per-state font weights and colors
- **Compositor-synced drag reorder** — drag tiled window segments to change the real manager order without maintaining a separate local sort
- **Workspace indicator** — show the active workspace ID or name with an animated capsule and optional window-count badge
- **Special workspace overlay** — centered overlay for Hyprland special workspaces with window icon previews
- **Pinned apps** — pin applications to the bar with custom icons, focus-cycle or start-new behavior
- **Custom style rules** — regex-based rules to override segment, icon, and title colors per app, title, tags, floating state, grouped state, urgency, or duplicate identity/title state, with blink animation, badges, and icon prefixes
- **Presets system** — save, load, import/export complete configurations with built-in starting points
- **Theme-aware colors** — all colors resolve against the active Noctalia theme with custom hex fallback
- **Settings migrations** — automatic schema migrations with validation and cleanup on import

## Screenshots

<!-- Add screenshots here -->
> Screenshots coming soon.

## Getting Started

### Prerequisites

- [Noctalia Shell](https://github.com/noctalia-dev/noctalia-shell) >= 4.6.6
- A Wayland compositor supported by Noctalia (Hyprland recommended for special workspace features)

### Installation

1. Clone or copy the `scrollbar2` folder into your Noctalia plugins directory
2. Enable the plugin through Noctalia's plugin manager
3. Right-click the bar widget and select **Widget settings** to configure

## Configuration

Settings are organized into five tabs:

| Tab | Description |
|---|---|
| **Layout** | Display mode, track geometry, floating panel sizing, filtering, and animation |
| **Appearance** | Window labels, focus line colors, workspace indicator, special workspace overlay |
| **Pinned Apps** | Manage pinned launchers, custom icons, and click behavior |
| **Style Rules** | Regex-based per-window color, blink, badge, and icon prefix overrides |
| **Presets** | Save, load, import, and export complete configurations |

Drag reordering is enabled by default in the **Appearance** tab. It only applies to tiled live windows; pinned launchers and floating windows remain non-draggable so the bar always mirrors compositor state exactly.

### Style Rule Effects

Each custom style rule can apply one or more of these effects to matched windows:

| Effect | Description |
|---|---|
| **Segment / Icon / Title Colors** | Override colors per focus state (focused, hover, default) |
| **Blink Animation** | Pulse a color overlay on the segment with a configurable interval |
| **Badge** | Show a small colored dot on the icon, title, or segment with customizable size and position |
| **Icon Prefix** | Prepend a custom tabler icon before the window icon or title |

### Style Rule Matchers

Rules can match windows by:

| Matcher | Description |
|---|---|
| **App ID** | Regex match against the application identifier |
| **Window Title** | Regex match against the window title |
| **Tags** | Match windows with specific compositor tags |
| **Floating** | Match floating or tiled windows |
| **Urgent** | Match windows with the urgent flag |
| **Grouped** | Match windows that are part of a group |
| **Has Shared ID** | Match windows sharing an app ID with other windows |
| **Has Shared Title** | Match windows sharing a title with other windows |

### Display Modes

| Mode | Behavior |
|---|---|
| **Bar** | Renders inside the Noctalia bar as a standard widget |
| **Floating Panel** | Creates a reserve-space overlay anchored to the top or bottom of the screen |

### Built-in Presets

| Preset | Description |
|---|---|
| Default | Factory defaults — segments with icons and titles |
| Minimal | Ultra-thin track with no labels |
| Bordered | Thick track with sharp corners and visible separators |
| Floating | Floating panel with background and gradient |
| Compact | Tiny track with focused-only labels |
| Indicator | Track and focus line only, no window content |
| Pill | Fully rounded track with smooth focus indicator |

### Context Menu

Right-click any segment to:

- Focus or close the window
- Pin/unpin the application
- Add or edit a style rule for the app or window title, then switch the matcher in settings to tags, floating state, urgency, or other criteria as needed

## Entry Points

| File | Purpose |
|---|---|
| `Main.qml` | Shared state, window tracking, compositor integration |
| `BarWidget.qml` | Bar-mode widget host |
| `Settings.qml` | Five-tab settings UI with presets management |
| `components/WindowBarView.qml` | Core rendering — segments, focus line, indicators |
| `components/HybridColorChoice.qml` | Theme-aware color picker component |
| `Migrations.js` | Settings schema migration engine |
| `i18n/en.json` | English translations |

## License

Distributed under the [MIT License](https://github.com/noctalia-dev/noctalia-plugins/blob/main/LICENSE).

<p align="right">(<a href="#readme-top">back to top</a>)</p>
