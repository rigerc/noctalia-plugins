# rigerc's noctalia-plugins

> 🤖 This is a vibe coded project built by Codex and me. Treat the code and behavior as experimental, and verify changes before relying on it.

  ## Taskbar 2
  
  A standalone taskbar bar widget ported from Noctalia Shell, with major improvements:
  
  **Stability**
  - Fixes unresponsiveness caused by rapidly updating window titles (stable window key tracking with structural/live data separation)
  - Debounced model refreshes that defer structural updates during hover, drag, and context menu interactions
  
  **Organization**
  - Per-app grouping with cycle-on-click or list-on-click, number badge or dot indicator
  - Workspace-based section grouping when showing all workspaces
  - Configurable workspace separators with labels (prefix/suffix), divider modes (line, custom character, custom icon), and show-for-first toggle
  
  **Focus Animation**
  - Directional focus-travel marker that slides between focused entries
  - 8 animation styles: soft-comet, twin-echo, dot-wake, shard-tail, ribbon-pop, spring-caravan, halo-slip, pebble-chain
  - Configurable delay, duration, intensity, scale, lead/glow/effect colors, blur, transparency, and vertical position
  - Live preview widget in settings
  
  **Visual Styling**
  - Per-state item colors (default, hovered, focused, inactive) for background, border, and text
  - Focus gradient wash, icon glow/lift/scale, hover item scaling
  - Configurable icon scale, hover icon multiplier, item spacing
  - Custom title font family, scale, and weight
  
  **Context Menu**
  - Right-click on pinned (non-running) apps to pin/unpin
  - "Close All" for grouped entries
  - Window list mode for grouped context menus
