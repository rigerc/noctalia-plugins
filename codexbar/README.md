# CodexBar (Noctalia plugin)

Shows AI provider usage stats in your Noctalia bar and panel by running the external `codexbar` CLI.

## Requirements

- Noctalia `>= 4.6.6` (see `codexbar/manifest.json`).
- The `codexbar` CLI must be installed and available on your `PATH`.
  - CodexBar repo: https://github.com/steipete/CodexBar
  - CLI docs: https://github.com/steipete/CodexBar/blob/main/docs/cli.md

## Install / Setup

1. Install `codexbar` (pick one approach from the CodexBar docs above).
   - Homebrew (macOS / Linux):
     - `brew install steipete/tap/codexbar`
2. Verify the CLI works:
   - `codexbar --format json --pretty`
3. Configure providers for CodexBar (CodexBar reads `~/.codexbar/config.json`).
4. Add the `codexbar` plugin to your Noctalia bar.

## Settings

Open the plugin settings to configure:

- Bar icon, text content, and text styling (color/opacity).
- Show bar text only on hover (icon-only when idle).
- Refresh interval and default provider.
- Notifications (reset / low usage).

## Troubleshooting

- If the widget shows no data, run `codexbar --format json --pretty` in a terminal and fix any CLI/config issues first.
- If Noctalia can’t find `codexbar`, make sure it’s installed system-wide and that Noctalia inherits the correct `PATH`.
