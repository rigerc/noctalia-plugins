# Model Usage

A [Noctalia Shell](https://github.com/noctalia-dev/noctalia-shell) bar plugin for tracking AI coding assistant usage across multiple providers. It shows compact usage metrics in the bar and opens a detailed panel with rate-limit status, daily activity, model token totals, and provider-specific health messages.

> This plugin is a fork of [`255792417/noctalia-model-usage`](https://github.com/255792417/noctalia-model-usage).

## Features

- **Multi-provider usage tracking** for Claude Code, Codex, Copilot, OpenRouter, Zen, DeepSeek, Kilo Code, Z.ai, and Gemini.
- **Bar widget metrics** for prompts, tokens, 7-day usage, 5-hour usage, or combined 5-hour/7-day usage.
- **Detailed provider panel** with rate-limit bars, reset times, today totals, recent activity, and all-time model breakdowns.
- **Configurable provider order** with manual ordering or automatic front-sorting when 7-day usage changes.
- **Compact bar modes** including provider cycling, show-text-on-hover, per-provider visibility, and rate-limit alert coloring.
- **Local + API data sources** where supported, with optional Codexbar CLI integration for several providers.
- **Codexbar CLI support** as an alternate fetch path for Claude Code, Codex, Copilot, OpenRouter, Zen, Kilo Code, Z.ai, and Gemini.
- **Internationalization-ready UI** with English strings in `i18n/en.json`.

## Supported Providers

| Provider | Data source | Notes |
|---|---|---|
| Claude Code | Local files + Anthropic OAuth usage probe | Reads Claude local history and credentials; supports 7-day and 5-hour limits when available. |
| Codex | Local files or ChatGPT backend API | Local mode reads `~/.codex`; API mode uses `~/.codex/auth.json`. |
| Copilot | GitHub CLI + Copilot API | Uses `gh auth token` and Copilot internal usage endpoints. |
| OpenRouter | OpenRouter API | Uses `OPENROUTER_API_KEY` or the API key configured in settings. |
| Zen | OpenCode / Zen API | Uses `OPENCODE_ZEN_API_KEY`, `OPENCODE_API_KEY`, `ZEN_API_KEY`, or a configured key. |
| DeepSeek | DeepSeek API | Uses `DEEPSEEK_API_KEY` or a configured key. |
| Kilo Code | Kilo API or local auth | Uses `KILO_API_KEY`, a configured key, or Kilo login auth data. |
| Z.ai | Z.ai quota API | Uses `Z_AI_API_KEY`; `Z_AI_API_HOST` and `Z_AI_QUOTA_URL` can override endpoints. |
| Gemini | Gemini local OAuth + API | Reads Gemini OAuth credentials and usage data. |

## Installation

Copy the plugin folder into your Noctalia plugins directory, then enable it from Noctalia's plugin settings:

```bash
cp -r noctalia-model-usage ~/.config/noctalia/plugins/
```

Restart or reload Noctalia Shell after installing if the plugin does not appear immediately.

## Usage

1. Add **Model Usage** as a bar widget.
2. Open the plugin settings.
3. Enable the providers you want to track.
4. Configure any provider credentials or data-source options.
5. Left-click the bar widget to open the usage panel.
6. Right-click the bar widget for quick actions such as refresh and settings.

## Settings Overview

### Bar Display

- Cycle through providers or show all visible providers together.
- Choose the bar metric: prompts, tokens, 7-day usage, 5-hour usage, or combined 5-hour/7-day usage.
- Show text only on hover for a compact icon-first bar.
- Display used percentage or remaining percentage for usage metrics.
- Color provider icons when usage crosses a configurable alert threshold.

### Refresh Behavior

- Configure polling for local file-backed providers.
- Configure API refresh intervals for API-backed providers.
- Include or exclude cache tokens from token totals.

### Providers

- Enable or disable each provider independently.
- Choose whether each provider appears in the bar.
- Drag providers to set manual order.
- Optionally sort providers by most recently changed 7-day usage.
- Use Codexbar CLI for supported providers instead of native provider logic.

## Codexbar CLI Support

For supported providers, Model Usage can delegate usage collection to the external [`codexbar`](https://github.com/255792417/noctalia-model-usage) CLI instead of using this plugin's native local-file or API logic.

Supported Codexbar-backed providers:

- Claude Code
- Codex
- Copilot
- OpenRouter
- Zen / OpenCode
- Kilo Code
- Z.ai
- Gemini

When enabled for a provider, the plugin runs:

```bash
codexbar usage --provider <provider> --json-only --no-color
```

Enable this per provider in **Settings → Providers → Provider details → Use Codexbar CLI**. The `codexbar` executable must be installed and available in Noctalia Shell's environment `PATH`. DeepSeek currently uses the plugin's native provider implementation only.

## Privacy and Network Access

This plugin reads local usage/auth files for local providers and calls provider APIs for API-backed usage and rate-limit information. API keys can be supplied through environment variables or plugin settings, depending on the provider. Do not commit real API keys or private auth files.

## Development

Run targeted QML linting from the repository root:

```bash
./scripts/qmllint-plugins.sh --plugin noctalia-model-usage --summary
```

Main files:

- `manifest.json` — plugin metadata and default settings.
- `Main.qml` — shared provider state, refresh timers, and bar provider selection.
- `BarWidget.qml` — bar display and context menu.
- `Panel.qml` — detailed usage panel.
- `Settings.qml` — plugin configuration UI.
- `providers/*.qml` — provider-specific data collection.
- `components/*.qml` — shared helpers and visuals.
- `i18n/en.json` — English translations.

## License

MIT. See [`LICENSE`](./LICENSE).
