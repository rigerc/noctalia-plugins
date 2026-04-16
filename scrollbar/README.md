# Scrollbar

A scrolling window taskbar for [Noctalia Shell](https://github.com/noctalia-dev/noctalia-shell). Shows one focused slot at a time, auto-scrolls to keep it centered, and uses edge fades instead of scrollbars.

## Interactions

| Input | Action |
|---|---|
| **Left-click** | Focus window |
| **Middle-click** | Close window |
| **Drag** | Reorder windows in the strip |
| **Hover** | Full title tooltip |
| **Right-click** | Plugin settings |

The bar is not manually scrollable — it only moves when focus changes, so its position always reflects where you are.

## Visual Design

- **Focused slot**: filled accent background with icon + title
- **Unfocused slots**: dim outlines, subordinate but countable
- **Edge fades**: gradient masks at both ends signal overflow — a hard edge means you're at the boundary
- **Track line**: thin accent bar showing your global position in the strip
- **Workspace indicator**: optional active-workspace label rendered outside the strip so it remains visible past the fade

## Settings

### Behavior

| Setting | Default | Description |
|---|---|---|
| Same output only | On | Only show windows on the current monitor |
| Active workspaces only | On | Only show windows on active workspaces |
| Enable reorder | On | Allow drag-to-reorder (Hyprland & Niri) |
| Animate on workspace changes | Off | Slide the whole widget when the active workspace changes |
| Debug logging | Off | Verbose log output |

### Layout

| Setting | Default | Description |
|---|---|---|
| Max widget width | 40% | Maximum bar space the widget can occupy |
| Slot width | 112 px | Fixed width per window slot |
| Show title | On | Display window title in each slot |
| Show workspace indicator | Off | Display the current workspace ID or name outside the strip |
| Icon scale | 80% | App icon size relative to capsule |
| Edge fade size | 18 px | Width of the gradient overflow fade |
| Slot spacing | 1 unit | Gap between slots |
| Track line | On | Show position indicator |

### Style

| Setting | Default | Description |
|---|---|---|
| Accent color | Primary | Focused slot fill color |
| Hover fill/border/text | hover / outline / on-hover | Hover state colors |
| Corner radius scale | 100% | Slot corner rounding |
| Hover scale | 2.5% | Size bump on hover |
| Hover transition | 120 ms | Hover animation speed |
| Focused fill opacity | 92% | Focused slot background |
| Unfocused fill opacity | 8% | Inactive slot background |
| Unfocused border opacity | 45% | Inactive slot border |
| Inactive opacity | 45% | Overall dimming for unfocused slots |
| Track opacity | 35% | Position track visibility |
| Focused top line | On | Accent marker above the focused slot |
| Workspace text color | Primary | Color of the external workspace label |

## Requirements

- Noctalia Shell **4.6.6** or later
- **Hyprland** or **Niri** (for live reorder support)
