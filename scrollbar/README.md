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
- **Track line**: continuous line with a thumb for the visible region
- **Workspace indicator**: optional active-workspace label rendered outside the strip so it remains visible past the fade

## Settings

### Layout

### Slot Size & Spacing
*Size, spacing, and structural dimensions for each window slot.*

| Key | Label | Description | Condition |
|-----|-------|-------------|-----------|
| `showSlots` | Show slots | Render the window slot capsules and their contents. | |
| `widgetSizeMode` | Widget size mode | Choose whether the widget shrinks to content with a cap or keeps a fixed visible size. | |
| `fixedWidgetSize` | Fixed widget size | Visible size of the widget along the strip axis in pixels. Horizontal bars use width; vertical bars use height. | `widgetSizeMode = fixed` |
| `slotWidth` | Slot width | Fixed size for each window slot along the strip axis. | `showSlots` |
| `slotSpacingUnits` | Slot spacing | Gap between adjacent window slots. | `showSlots` |
| `slotCapsuleScale` | Capsule height scale | Scale the slot capsule height independently of the track line. | `showSlots` |
| `radiusScale` | Corner roundness | Scale the slot corner radius. | `showSlots` |
| `maxWidgetWidth` | Max widget width | Maximum percentage of the bar this strip may occupy in dynamic mode before clipping and fading. | `widgetSizeMode = dynamic` |

### Icons
*Application icon display and tinting.*

| Key | Label | Description | Condition |
|-----|-------|-------------|-----------|
| `showIcons` | Show icons | Display application icons inside each slot. | `showSlots` |
| `iconScale` | Icon scale | Scale the app icon inside each slot. | `showSlots` + `showIcons` |
| `iconTintColor` | Icon tint color | Apply a uniform color tint over all application icons. | `showSlots` + `showIcons` |
| `iconTintOpacity` | Icon tint opacity | Strength of the icon color tint. | `showSlots` + `showIcons` |

### Window Title
*Font and visibility for window titles inside slots.*

| Key | Label | Description | Condition |
|-----|-------|-------------|-----------|
| `showTitle` | Show titles | Display truncated window titles next to icons on horizontal bars. | `showSlots` |
| `titleFontFamily` | Title font family | Font family used for window titles. Leave empty for the system default. | `showSlots` + `showTitle` |
| `titleFontSize` | Title font size | Font size override for titles in points. Set to 0 to use the bar default. | `showSlots` + `showTitle` |
| `titleFontWeight` | Title font weight | Font weight for titles. | `showSlots` + `showTitle` |

### Workspace Indicator
*Show the active workspace outside the scrolling strip so it remains visible.*

| Key | Label | Description | Condition |
|-----|-------|-------------|-----------|
| `workspaceIndicatorEnabled` | Show workspace indicator | Render the active workspace label outside the strip. | |
| `workspaceIndicatorLabelMode` | Workspace label mode | Show workspace ID or name. | `workspaceIndicatorEnabled` |
| `workspaceIndicatorPosition` | Workspace indicator position | Place the indicator before or after the strip. | `workspaceIndicatorEnabled` |
| `workspaceIndicatorFontFamily` | Workspace font family | Font family for the workspace indicator. | `workspaceIndicatorEnabled` |
| `workspaceIndicatorFontSize` | Workspace font size | Font size override in points. Set to 0 to use the bar default. | `workspaceIndicatorEnabled` |
| `workspaceIndicatorSpacing` | Workspace spacing | Gap between the workspace indicator and the strip. | `workspaceIndicatorEnabled` |
| `workspaceIndicatorPadding` | Workspace padding | Outer padding around the combined indicator and strip layout. | `workspaceIndicatorEnabled` |

### Edge Overflow Cue
*How the widget marks hidden content at the leading and trailing edges.*

| Key | Label | Description | Condition |
|-----|-------|-------------|-----------|
| `edgeFadeEnabled` | Enable edge fade | Show a gradual fade at the edges when content overflows. | |
| `edgeFadeSize` | Fade size | Width of the gradual fade at the overflowing edges. | `edgeFadeEnabled` |
| `edgeFadeOpacity` | Fade opacity | Strength of the overflow fade into the widget background. | `edgeFadeEnabled` |

## Colors

### Widget Background
*Background fill for the entire widget strip.*

| Key | Label | Description | Condition |
|-----|-------|-------------|-----------|
| `backgroundColor` | Background color | Background fill color for the widget strip. | |
| `backgroundOpacity` | Background opacity | Opacity of the widget strip background. | |

### Active Window
*Colors and borders for the currently focused window.*

| Key | Label | Description | Condition |
|-----|-------|-------------|-----------|
| `showFocusedFill` | Show focused fill | Enable the background color on the focused slot. | `showSlots` |
| `focusedFillColor` | Focused fill color | Background color for the focused slot. | `showSlots` + `showFocusedFill` |
| `focusedFillOpacity` | Focused fill opacity | Strength of the focused slot background tint. | `showSlots` + `showFocusedFill` |
| `showFocusedBorder` | Show focused border | Draw a border around the focused slot. | `showSlots` |
| `focusedBorderColor` | Focused border color | Border color for the focused slot. | `showSlots` + `showFocusedBorder` |
| `focusedBorderOpacity` | Focused border opacity | Opacity of the focused slot border. | `showSlots` + `showFocusedBorder` |
| `focusedTextColor` | Focused text color | Text and icon color for the focused slot. | `showSlots` |

### Inactive Windows
*Appearance of idle, background window slots.*

| Key | Label | Description | Condition |
|-----|-------|-------------|-----------|
| `inactiveOpacity` | Inactive opacity | How faint unfocused slots appear relative to the focused slot. | `showSlots` |
| `showUnfocusedFill` | Show unfocused fill | Enable the background color on unfocused slots. | `showSlots` |
| `unfocusedFillColor` | Unfocused fill color | Background color for unfocused slots. | `showSlots` + `showUnfocusedFill` |
| `unfocusedFillOpacity` | Unfocused fill opacity | Background visibility for unfocused slots. | `showSlots` + `showUnfocusedFill` |
| `showUnfocusedBorder` | Show unfocused border | Draw a border around idle unfocused slots. | `showSlots` |
| `unfocusedBorderColor` | Unfocused border color | Border color for unfocused slots. | `showSlots` + `showUnfocusedBorder` |
| `unfocusedBorderOpacity` | Unfocused border opacity | Border visibility for unfocused slots. | `showSlots` + `showUnfocusedBorder` |
| `unfocusedTextColor` | Unfocused text color | Text and icon color for unfocused slots. | `showSlots` |

### Hovered Window
*Colors, borders, and animation when hovering a slot.*

| Key | Label | Description | Condition |
|-----|-------|-------------|-----------|
| `hoverFillColor` | Hover fill color | Background tint used when hovering an unfocused slot. | `showSlots` |
| `hoverFillOpacity` | Hover fill opacity | Strength of the hover background tint. | `showSlots` |
| `showHoverBorder` | Show hover border | Draw a border around hovered unfocused slots. | `showSlots` |
| `hoverBorderColor` | Hover border color | Border color used when hovering an unfocused slot. | `showSlots` + `showHoverBorder` |
| `hoverBorderOpacity` | Hover border opacity | Opacity of the hover slot border. | `showSlots` + `showHoverBorder` |
| `hoverTextColor` | Hover text color | Text and fallback glyph color used on hovered slots. | `showSlots` |
| `hoverScalePercent` | Hover scale | How much the slot grows while hovered. | `showSlots` |
| `hoverTransitionDurationMs` | Hover transition duration | Animation duration for hover scale and color changes. | `showSlots` |

### Workspace Indicator
*Color styling for the external workspace label.*

| Key | Label | Description | Condition |
|-----|-------|-------------|-----------|
| `workspaceIndicatorTextColor` | Workspace text color | Color used for the workspace indicator text. | `workspaceIndicatorEnabled` |
| `workspaceIndicatorOpacity` | Workspace text opacity | Opacity used for the workspace indicator text. | `workspaceIndicatorEnabled` |

### Track & Focus Indicator
*The position track and focused-slot indicator line.*

| Key | Label | Description | Condition |
|-----|-------|-------------|-----------|
| `showTrackLine` | Show track line | Render the passive position track and thumb behind the strip. | |
| `trackLinePosition` | Track line position | Place the track at top, center, or bottom (horizontal) / left, center, or right (vertical). | `showTrackLine` |
| `trackLineThickness` | Track line thickness | Thickness of the passive track line and scrollbar thumb in pixels. | `showTrackLine` |
| `trackOpacity` | Track opacity | Opacity used by the passive track line. | `showTrackLine` |
| `trackThumbColor` | Track thumb color | Color of the position indicator thumb on the scrollbar track. | `showTrackLine` |
| `showFocusLine` | Show focus line | Draw a thin indicator line on the track marking the focused slot position. | `showTrackLine` |
| `focusLineColor` | Focus line color | Color of the focus indicator line on the track. | `showTrackLine` + `showFocusLine` |
| `focusLineOpacity` | Focus line opacity | Opacity of the focus indicator line. | `showTrackLine` + `showFocusLine` |
| `focusLineThickness` | Focus line thickness | Thickness of the focus indicator line in pixels. | `showTrackLine` + `showFocusLine` |
| `focusLineAnimationMs` | Focus line animation | Duration of the focus indicator position and size animations. | `showTrackLine` + `showFocusLine` |

## Behavior

### Window Filtering
*Control which windows appear in the strip.*

| Key | Label | Description | Condition |
|-----|-------|-------------|-----------|
| `onlySameOutput` | Only same monitor | Only include windows belonging to the monitor hosting this widget. | |
| `onlyActiveWorkspaces` | Only active workspaces | Limit the strip to windows from currently active workspaces. | |

### Interaction
*Mouse and drag behavior for window slots.*

| Key | Label | Description | Condition |
|-----|-------|-------------|-----------|
| `enableReorder` | Enable drag reorder | Allow drag-to-reorder on compositors that expose safe live reorder support. | |
| `enableScrollWheel` | Scroll wheel panning | Use the mouse wheel to pan the strip. Scrolls back to the focused window on cursor leave. | |

### Auto-Scroll
*How the strip reacts when focus changes.*

| Key | Label | Description | Condition |
|-----|-------|-------------|-----------|
| `centerFocusedWindow` | Center focused window | Auto-scroll the strip to keep the focused window centered. | |
| `centerAnimationMs` | Center animation | Duration of the smooth scroll animation when centering. | `centerFocusedWindow` |

### Workspace Change Animation
*Animate the whole widget when the active workspace changes.*

| Key | Label | Description | Condition |
|-----|-------|-------------|-----------|
| `workspaceAnimationEnabled` | Animate on workspace changes | Slide the whole widget when the active workspace changes. | |
| `workspaceAnimationAxis` | Workspace animation axis | Whether the animation slides horizontally or vertically. | `workspaceAnimationEnabled` |

### Advanced
*Diagnostic options for troubleshooting.*

| Key | Label | Description | Condition |
|-----|-------|-------------|-----------|
| `debugLogging` | Debug logging | Write model refresh, focus, and interaction details to the shell log. | |

## Requirements

- Noctalia Shell **4.6.6** or later
- **Hyprland** or **Niri** (for live reorder support)
