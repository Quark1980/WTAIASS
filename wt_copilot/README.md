
# MeshcoreGRID (WTAIASS) Visual System Overview

## Visual System & Screen Buildup

The MeshcoreGRID app (WTAIASS) uses a layered visual system to render tactical overlays, live units, and map data. The UI is built using Flutter's widget tree and leverages normalized coordinates for all overlays and tactical data.

### Layer Structure (from bottom to top):

1. **Map Image Layer**
	- Rendered by `MapDisplay` (`lib/ui/widgets/map_display.dart`).
	- Loads the minimap image from a URL and displays it using a `RawImage` widget.
	- Handles loading, error, and refresh states.

2. **Grid Overlay Layer**
	- Drawn by `MapPainter` (`lib/ui/widgets/map_painter.dart`).
	- Renders grid lines, labels, and grid cell info on top of the map image.
	- Uses map metadata (`map_max`, `map_min`, `grid_steps`) for grid calculation.

3. **Live Units & Tactical Objects Layer**
	- Also drawn by `MapPainter`.
	- Renders all live units, objectives, and tactical objects as icons or shapes.
	- Uses normalized coordinates, scaled to the map size.

4. **Historical Trails & Death Markers Layer**
	- Drawn by `MapOverlayTrails` (`lib/ui/widgets/map_overlay_trails.dart`).
	- Uses a `CustomPainter` to render:
	  - **Dotted trails:** Each unit's historical positions as small, zoom-scaled dots. The most recent dot can be rendered larger for emphasis.
	  - **Death markers:** Faded X markers at the last known position of destroyed units.
	- Trail buffer length is user-adjustable via the menu (see "Trail Buffer Settings").

5. **UI Controls & Menus Layer**
	- Includes the AppBar, filter menu, and the main menu (top right).
	- The menu provides access to connection settings, raw data debug, and trail buffer settings (slider dialog).

6. **Log Feed Layer**
	- `LogFeedBox` (`lib/ui/widgets/log_feed_box.dart`) displays the latest HUD and chat logs below the map.

### Widget/Layer Relationships

- The main map screen is a `Scaffold` with a column layout:
  - Top: Map area (with overlays and controls)
  - Bottom: Log feed
- The map area uses a `Stack` to layer the map image, overlays, and controls.
- Overlays always use normalized coordinates (0.0–1.0) for X/Y, converted to pixels at draw time.
- All overlays and live units are perfectly aligned at all zoom/pan levels using a shared transformation matrix.

### Customization & Performance

- The trail buffer (history length) is adjustable (5s–5min) via the menu.
- All overlay rendering is optimized for performance using `CustomPainter`.
- Layer order ensures overlays and markers are always visible above the map and units.

### References
- See `COORDINATE_SYSTEM.md` for coordinate and overlay implementation details.
- See `lib/ui/widgets/map_overlay_trails.dart` and `lib/ui/widgets/map_painter.dart` for painter logic.
- See `lib/ui/pages/map_page.dart` for screen and menu structure.

---
For Flutter development help, see the [Flutter documentation](https://docs.flutter.dev/).
