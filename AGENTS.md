# AI-Assisted Development Guidelines

## MANDATORY: Use td for Task Management

Run td usage --new-session at conversation start (or after /clear). This tells you what to work on next.

Sessions are automatic (based on terminal/agent context). Optional:
- td session "name" to label the current session
- td session --new to force a new session in the same context

Use td usage -q after first read.

References:
  - Noctalia documentation: @docs/noctalia-docs/src/content/docs/
  - Noctalia source: @docs/noctalia-shell/
  - Example plugins for Noctalia: @docs/noctalia-plugins/

  For API research, use context7 tool. For icon usage, use iconify tool (Noctalia uses tabler icons)

Guidelines for AI tools contributing to the Noctalia Plugins repository. **Study the official plugins before writing code** — especially `hello-world` (minimal reference) and `timer` (complex example with shared state). Official plugins have `"official": true` in their manifest.

## Plugin API

Every plugin component receives a `pluginApi` property. This is the core interface:

```qml
Item {
  property var pluginApi: null

  // Settings access pattern — always use this fallback chain
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  property string message: cfg.message ?? defaults.message ?? "fallback"
}
```

**Key pluginApi members:**
- `pluginSettings` — mutable settings object, persisted via `saveSettings()`
- `manifest` — read-only manifest.json data
- `pluginId`, `pluginDir` — plugin identity and path
- `mainInstance` — reference to Main.qml instance (for shared state)
- `tr(key, interpolations)` — translate a key, e.g. `pluginApi?.tr("widget.label")`
- `trp(key, count, singular, plural)` — plural translation
- `openPanel(screen, widget)`, `togglePanel(screen, widget)` — panel control
- `saveSettings()` — persist `pluginSettings` to disk
- `withCurrentScreen(callback)` — get current screen in IPC handlers
- `panelOpenScreen` — the screen where this plugin's panel is open

## Entry Points

Only include the entry points your plugin uses. Available types:

| Entry Point | File | Purpose |
|---|---|---|
| `main` | Main.qml | Shared state, IPC handlers |
| `barWidget` | BarWidget.qml | Bar widget |
| `panel` | Panel.qml | Overlay panel |
| `controlCenterWidget` | ControlCenterWidget.qml | Control center button |
| `settings` | Settings.qml | Plugin settings UI |
| `desktopWidget` | DesktopWidget.qml | Draggable desktop widget |
| `desktopWidgetSettings` | DesktopWidgetSettings.qml | Desktop widget settings |
| `launcherProvider` | LauncherProvider.qml | Launcher search provider |

## Component Patterns

### Main.qml — Shared State

```qml
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root
  property var pluginApi: null

  // Shared state accessible from other components via pluginApi.mainInstance
  property bool isActive: false

  // IPC handler for CLI control (qs ipc call plugin:my-plugin commandName)
  IpcHandler {
    target: "plugin:my-plugin"

    function toggle() {
      if (pluginApi) {
        pluginApi.withCurrentScreen(screen => {
          pluginApi.togglePanel(screen);
        });
      }
    }
  }
}
```

### BarWidget.qml

```qml
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  // Injected properties
  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  // Settings
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // Bar layout awareness
  readonly property string barPosition: Settings.getBarPositionForScreen(screen?.name)
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screen?.name)

  implicitWidth: isVertical ? capsuleHeight : contentWidth
  implicitHeight: isVertical ? contentHeight : capsuleHeight

  // Context menu (right-click)
  NPopupContextMenu {
    id: contextMenu
    model: [
      { "label": pluginApi?.tr("menu.settings"), "action": "settings", "icon": "settings" }
    ]
    onTriggered: action => {
      contextMenu.close();
      PanelService.closeContextMenu(screen);
      if (action === "settings") {
        BarService.openPluginSettings(screen, pluginApi.manifest);
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: mouse => {
      if (mouse.button === Qt.LeftButton) {
        if (pluginApi) pluginApi.togglePanel(root.screen, root);
      } else if (mouse.button === Qt.RightButton) {
        PanelService.showContextMenu(contextMenu, root, screen);
      }
    }
  }
}
```

### Panel.qml

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root
  property var pluginApi: null

  // Required for background rendering
  readonly property var geometryPlaceholder: panelContainer

  // Panel dimensions (always scale with uiScaleRatio)
  property real contentPreferredWidth: 400 * Style.uiScaleRatio
  property real contentPreferredHeight: 500 * Style.uiScaleRatio

  // Enable panel attach/detach UI
  readonly property bool allowAttach: true

  anchors.fill: parent

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginL

      // Panel content using N* widgets
    }
  }
}
```

### Settings.qml

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // Edit copies of settings (don't modify pluginSettings directly in bindings)
  property string editMessage: cfg.message ?? defaults.message ?? ""

  spacing: Style.marginL

  NTextInput {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.message.label")
    description: pluginApi?.tr("settings.message.desc")
    text: root.editMessage
    onTextChanged: root.editMessage = text
  }

  // Required — called by the shell when user saves
  function saveSettings() {
    if (!pluginApi) return;
    pluginApi.pluginSettings.message = root.editMessage;
    pluginApi.saveSettings();
  }
}
```

### ControlCenterWidget.qml

```qml
import Quickshell
import qs.Widgets

NIconButtonHot {
  property ShellScreen screen
  property var pluginApi: null

  icon: "my-icon"
  tooltipText: pluginApi?.tr("widget.tooltip")
  onClicked: {
    if (pluginApi) pluginApi.togglePanel(screen, this);
  }
}
```

## manifest.json

```json
{
  "id": "my-plugin",
  "name": "My Plugin",
  "version": "1.0.0",
  "minNoctaliaVersion": "4.4.1",
  "author": "Author Name",
  "license": "MIT",
  "repository": "https://github.com/noctalia-dev/noctalia-plugins",
  "description": "Concise description of what the plugin does",
  "tags": ["Bar", "Panel"],
  "entryPoints": {
    "barWidget": "BarWidget.qml",
    "panel": "Panel.qml",
    "settings": "Settings.qml"
  },
  "dependencies": {
    "plugins": []
  },
  "metadata": {
    "defaultSettings": {
      "message": "Hello",
      "iconColor": "none"
    }
  }
}
```

**Field rules:**
- `id` must match the folder name
- `version` starts at `1.0.0`; bump appropriately on updates
- `minNoctaliaVersion` — verify the features you use exist in that version
- `repository` — always `https://github.com/noctalia-dev/noctalia-plugins` for PRs to this repo
- `tags` — use only tags from [README.md](./README.md#tags); include compositor tags if compositor-specific
- `entryPoints` — only include the ones your plugin provides
- `metadata.defaultSettings` — must contain defaults for every setting your plugin uses

## Translations

Plugin translations live in `i18n/*.json` (one file per language):

```json
{
  "widget": {
    "tooltip": "My Widget"
  },
  "menu": {
    "settings": "Widget settings"
  },
  "settings": {
    "message": {
      "label": "Message",
      "desc": "Custom message to display"
    }
  }
}
```

Access via dot notation: `pluginApi?.tr("settings.message.label")`.
Do **not** add fallback text after `tr()` calls — the translation system handles missing keys.

## Code Style

- **Use Noctalia widgets** (`NButton`, `NLabel`, `NBox`, `NSlider`, etc.) instead of raw Qt types (`Text`, `Rectangle`, `Button`). This ensures correct theming.
- **Use `Style` constants** for margins, radii, colors: `Style.marginL`, `Style.radiusM`, `Color.mPrimary`
- **Use `Logger`** for logging (`Logger.i`, `Logger.d`, `Logger.w`, `Logger.e`), not `console.log`
- **Always null-coalesce** pluginApi access: `pluginApi?.tr(...)`, `pluginApi?.pluginSettings || ({})`
- **camelCase** for variables/functions, **PascalCase** for component files
- **No fallback values after `I18n.tr()` or `pluginApi?.tr()`** — the translation system returns the key on miss

## Common Imports

```qml
import QtQuick
import QtQuick.Layouts
import Quickshell           // ShellScreen, IpcHandler
import Quickshell.Io        // FileView, Process
import qs.Commons           // Settings, Style, Color, Logger, I18n, Icons
import qs.Services.UI       // PanelService, BarService
import qs.Widgets           // N* components
```

## Common AI Mistakes

These are the most frequent issues in AI-generated plugin PRs:

- **Hallucinated APIs** — inventing functions or properties that don't exist in Quickshell, Qt, or the plugin API. Always verify against official plugins before using any API.
- **Using raw Qt types** — `Text`, `Rectangle`, `Button` instead of `NLabel`, `NBox`, `NButton`. The N* widgets handle theming automatically.
- **Hardcoded strings** — all user-facing text must go through `pluginApi?.tr()` with translations in `i18n/`.
- **Wrong settings pattern** — modifying `pluginApi.pluginSettings` directly in bindings instead of using edit-copy properties and saving in `saveSettings()`.
- **Missing `saveSettings()` function** in Settings.qml — the shell calls this; without it, settings won't persist.
- **Incorrect manifest fields** — `id` not matching folder name, missing `defaultSettings` for settings the plugin uses, wrong `minNoctaliaVersion`.
- **Using `console.log`** instead of `Logger.i` / `Logger.d` / `Logger.w` / `Logger.e`.

## Performance

- **Avoid expensive property bindings** — complex calculations should be in functions, not inline bindings. Simple ternaries and property reads are fine.
- **Use `Loader`** for heavy content that isn't always visible — panels already do this, but apply it within your own components too.
- **Debounce rapid updates** with `Timer` — e.g. if reacting to slider changes that trigger expensive operations.
- **Prefer signals/bindings over polling** — don't use `Timer` to repeatedly check state when a signal or binding would work.

## Resources

- [Official Plugins](https://github.com/noctalia-dev/noctalia-plugins) — study `hello-world` and `timer` first
- [Plugin Documentation](https://docs.noctalia.dev/development/plugins/overview/)
- [Development Guidelines](https://docs.noctalia.dev/development/guideline/)
- [Noctalia Widgets](https://github.com/noctalia-dev/noctalia-shell/tree/main/Widgets) — all N* components

<!-- BACKLOG.MD MCP GUIDELINES START -->

<CRITICAL_INSTRUCTION>

## BACKLOG WORKFLOW INSTRUCTIONS

This project uses Backlog.md MCP for all task and project management activities.

**CRITICAL GUIDANCE**

- If your client supports MCP resources, read `backlog://workflow/overview` to understand when and how to use Backlog for this project.
- If your client only supports tools or the above request fails, call `backlog.get_backlog_instructions()` to load the tool-oriented overview. Use the `instruction` selector when you need `task-creation`, `task-execution`, or `task-finalization`.

- **First time working here?** Read the overview resource IMMEDIATELY to learn the workflow
- **Already familiar?** You should have the overview cached ("## Backlog.md Overview (MCP)")
- **When to read it**: BEFORE creating tasks, or when you're unsure whether to track work

These guides cover:
- Decision framework for when to create tasks
- Search-first workflow to avoid duplicates
- Links to detailed guides for task creation, execution, and finalization
- MCP tools reference

You MUST read the overview resource to understand the complete workflow. The information is NOT summarized here.

</CRITICAL_INSTRUCTION>

<!-- BACKLOG.MD MCP GUIDELINES END -->
