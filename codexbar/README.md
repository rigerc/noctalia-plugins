# CodexBar (Noctalia plugin)

Show AI provider usage stats in your Noctalia bar and panel by running the external `codexbar` CLI.

Upstream project: <https://github.com/steipete/CodexBar>

## Requirements

- Noctalia `>= 4.6.6` (see `codexbar/manifest.json`).
- `codexbar` installed and available on your `PATH`.
  - CLI docs: <https://github.com/steipete/CodexBar/blob/main/docs/cli.md>

## Features

- **Bar widget**
  - Show remaining usage for one or more fields (session / weekly / status).
  - Optional **Show on hover** (icon-only until hovered).
  - Right-click menu: Refresh, Settings.
- **Panel**
  - Per-provider cards with session + weekly bars, reset countdown, credits, status indicator.
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

- **Bar icon** and **text content** (choose which fields are shown and their order).
- **Show on hover** (when enabled, the bar widget shows icon-only until hovered).
- **Text styling** (color + opacity).
- **Refresh interval** and **default provider**.
- **Notifications** (reset / low usage).

Notes:

- Status display requires `codexbar --status` (CodexBar runs this automatically when you select the Status field).
- The bar widget uses Noctalia’s `BarPill` for hover-reveal behavior, so it does not support custom font family/size/weight controls.

## Settings reference (plugin settings)

These values live in Noctalia’s plugin settings store (`pluginApi.pluginSettings`), not in `~/.codexbar/config.json`.

- `barIcon` (string): Tabler icon name (e.g. `sparkles`).
- `barIconColor` (string): Noctalia color key.
- `barTextFields` (array): Any of `primary`, `secondary`, `status`.
- `barTextSeparator` (string): Separator between fields.
- `barTextSeparatorSpacing` (number): Spaces around the separator.
- `barTextUseIconColor` (bool): Currently unused (reserved for a future “text follows icon color” option).
- `barTextShowOnHover` (bool): Icon-only until hover.
- `barTextColor` (string): Noctalia color key.
- `barTextOpacity` (number 0–1): Applied to bar text color.
- `refreshInterval` (number seconds): Auto-refresh interval.
- `defaultProvider` (string): Provider ID to prefer in the bar widget (empty = auto).
- `notifyOnReset` (bool): Toast on detected reset.
- `notifyOnLowUsage` (bool): Toast when remaining usage is low.
- `lowUsageThreshold` (number 5–50): Remaining percentage to trigger low-usage toasts.

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
