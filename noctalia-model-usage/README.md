# Model Usage — Noctalia Plugin

A Noctalia bar widget and detail panel for AI coding assistant usage stats.

**Enhanced fork of the original [noctalia-plugins/model-usage](https://github.com/noctalia-dev/noctalia-plugins) plugin.**

## Credits

- **Original plugin** by [cmptr](https://github.com/noctalia-dev) — MIT License
- **Enhancements**: DeepSeek provider, fixed bar display mode, Claude third-party API support, `~/.claude.json` data source migration

## Providers

| Provider | Data Source | Auth |
|---|---|---|
| **Claude Code** | `~/.claude.json` + `~/.claude/history.jsonl` | OAuth (optional, for rate limits) |
| **Codex** | `~/.codex/` local files | Local auth |
| **Copilot** | GitHub Copilot API | `gh auth` |
| **OpenRouter** | OpenRouter API | API key |
| **Zen** | OpenCode Zen API | API key |
| **DeepSeek** | DeepSeek API (`/user/balance`) | API key |

## Features added in this fork

### DeepSeek provider
Shows account balance from the DeepSeek API. Set `DEEPSEEK_API_KEY` env var or enter the key in Settings.

### Claude Code — third-party API support
When Claude Code is configured with a third-party API backend (e.g. DeepSeek, OpenAI), the plugin reads `~/.claude.json` and aggregates `lastModelUsage` across all projects. No Anthropic OAuth required — stats display normally without auth warnings.

### Fixed bar display mode
Bar Display Mode now has three options: **Active provider** (first enabled), **Cycle providers**, and **Fixed provider** — pin a specific provider to always show in the bar.

### Data source migration
Claude provider reads from `~/.claude.json` instead of the non-existent `stats-cache.json`. Aggregates per-project `lastModelUsage` data and extracts all-time prompt/session counts from `history.jsonl`.

## Installation

1. Copy this directory to your Noctalia plugins folder
2. Enable the plugin in Noctalia settings
3. Configure providers in the plugin Settings panel

## API keys

| Provider | Environment Variable | Settings Field |
|---|---|---|
| OpenRouter | `OPENROUTER_API_KEY` | Yes |
| Zen | `OPENCODE_ZEN_API_KEY` / `OPENCODE_API_KEY` | Yes |
| DeepSeek | `DEEPSEEK_API_KEY` | Yes |

## License

MIT License — see original [noctalia-plugins](https://github.com/noctalia-dev/noctalia-plugins) repository.

Original plugin copyright (c) cmptr. Modifications copyright (c) 2025.
