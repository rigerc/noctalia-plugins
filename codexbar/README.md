# CodexBar (Noctalia plugin)

Show AI provider usage stats in your Noctalia bar and panel by running the external `codexbar` CLI.

Upstream project: <https://github.com/steipete/CodexBar>

## Requirements

- Noctalia `>= 4.6.6` (see `codexbar/manifest.json`).
- `codexbar` installed and available on your `PATH`.
  - CLI docs: <https://github.com/steipete/CodexBar/blob/main/docs/cli.md>

## Features

- **Bar widget**
  - Show up to three selected providers in one widget, with remaining usage for one or more fields (primary / secondary / tertiary / status).
  - Optional **Show on hover** (icon-only until hovered).
  - Optional low-usage icon alert for primary, secondary, or tertiary window.
  - Right-click menu: Refresh, Settings.
- **Panel**
  - Per-provider cards with up to three usage windows (primary/secondary/tertiary), reset countdown, credits, status indicator.
  - Quick refresh button.
  - Codex provider shortcut: “Open Codex usage”.
- **Notifications**
  - Optional toast on usage reset.
  - Optional toast when remaining usage drops below a threshold.
- **Config editor (built-in)**
  - Edit `~/.codexbar/config.json` directly from Noctalia settings.
  - Quick editor for provider list + common fields, with JSON schema validation.
  - Raw JSON mode (format/apply/template), open in external editor.
- **IPC**
  - `qs ipc call plugin:codexbar refresh` triggers an immediate refresh.

## Install / Setup

1. Install `codexbar` (pick one approach from the upstream docs).
   - Homebrew (macOS / Linux): `brew install steipete/tap/codexbar`
2. Verify the CLI works:
   - `codexbar --format json --pretty`
3. Configure providers for CodexBar:
   - CodexBar reads `~/.codexbar/config.json`
4. Add the `codexbar` plugin to your Noctalia bar.

## Usage

- Left click: open/toggle the panel.
- Right click: open the widget menu (refresh / settings).

## Settings (UI)

Open the plugin settings to configure:

- **Bar icon**, **widget providers**, and **text content** (choose which providers and fields are shown, plus their order).
- **Show on hover** (when enabled, the bar widget shows icon-only until hovered).
- **Low-usage icon alert** (choose primary, secondary, or tertiary; choose the tint color; 0% remaining forces full error red).
- **Text styling** (color + opacity).
- **Refresh interval** and provider selection display mode.
- **Notifications** (reset / low usage).

Notes:

- Status display requires `codexbar --status` (CodexBar runs this automatically when you select the Status field).
- The bar widget keeps Noctalia-style hover reveal behavior and still does not expose custom font family/size/weight controls.
- Existing installs keep the current single-provider behavior until you save a widget provider selection.

## Settings reference (plugin settings)

These values live in Noctalia’s plugin settings store (`pluginApi.pluginSettings`), not in `~/.codexbar/config.json`.

- `barIcon` (string): Tabler icon name (e.g. `sparkles`).
- `barIconColor` (string): Noctalia color key.
- `barProviderIds` (array): Ordered provider IDs shown in the widget, max 3. Empty keeps legacy single-provider fallback.
- `barProviderLabelMode` (string): `icon` or `prefix`.
- `barProviderSeparator` (string): Separator between provider segments.
- `barProviderSeparatorSpacing` (number): Spaces around the provider separator.
- `barTextFields` (array): Any of `primary`, `secondary`, `tertiary`, `status`.
- `barTextSeparator` (string): Separator between fields.
- `barTextSeparatorSpacing` (number): Spaces around the separator.
- `barTextUseIconColor` (bool): Currently unused (reserved for a future “text follows icon color” option).
- `barTextShowOnHover` (bool): Icon-only until hover.
- `barTextExpandOnChange` (bool): Temporarily expand a hover-only pill after a value change.
- `barTextColor` (string): Noctalia color key.
- `barTextOpacity` (number 0–1): Applied to bar text color.
- `barLowUsageAlertEnabled` (bool): Tint the bar icon when the selected window is low.
- `barLowUsageAlertWindow` (string): `primary`, `secondary`, or `tertiary`.
- `barLowUsageAlertColor` (string): Noctalia color key used at 50% opacity while low.
- `refreshInterval` (number seconds): Auto-refresh interval.
- `defaultProvider` (string): Legacy fallback provider when `barProviderIds` is empty.
- `notifyOnReset` (bool): Toast on detected reset.
- `notifyOnLowUsage` (bool): Toast when remaining usage is low.
- `lowUsageThreshold` (number 5–50): Remaining percentage used by low-usage toasts and the optional bar icon alert.

## Config editor (CodexBar config)

CodexBar’s provider configuration is stored in `~/.codexbar/config.json` and can include secrets (API keys / cookies). The built-in editor supports:

- **Quick editor**
  - Add/remove/reorder providers (provider order affects CodexBar display order).
  - Per-provider fields:
    - `enabled` (bool)
    - `source` (`auto|web|cli|oauth|api`)
    - `cookieSource` (`auto|manual|off`)
    - `region` (string|null)
    - `workspaceID` (string|null)
    - `apiKey` (string|null)
    - `cookieHeader` (string|null)
    - `tokenAccounts` (object|null)
- **Raw JSON mode**
  - Validate + format JSON.
  - Apply raw JSON into the quick editor model.
  - Reset to a template.
  - Save to `~/.codexbar/config.json` (creates `~/.codexbar/` if needed) and open the file in an external editor.
  - Open upstream configuration docs.

<details>
<summary>Known provider IDs (as listed in the UI)</summary>

`codex`, `claude`, `cursor`, `opencode`, `factory`, `gemini`, `antigravity`, `copilot`, `zai`, `minimax`, `kimi`, `kilo`, `kiro`, `vertexai`, `augment`, `jetbrains`, `kimik2`, `amp`, `ollama`, `synthetic`, `warp`, `openrouter`
</details>

## Troubleshooting

- If the widget shows no data, run `codexbar --format json --pretty` in a terminal and fix any CLI/config issues first.
- If Noctalia can’t find `codexbar`, make sure it’s installed system-wide and that Noctalia inherits the correct `PATH`.
