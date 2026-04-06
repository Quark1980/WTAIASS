
# WTAIASS Map Coordinate System

## Overview
WTAIASS uses a normalized coordinate system for all map overlays, unit positions, and tactical data. All positions are represented as relative coordinates in the range **0.0 to 1.0** for both X and Y axes, regardless of the actual map pixel size or world units. This ensures overlays and logic are resolution- and map-size independent.

## Coordinate System Details
- **Origin (0,0):** Bottom-left corner of the map.
- **X axis:** Increases to the right (0.0 = left edge, 1.0 = right edge).
- **Y axis:** Increases upwards (0.0 = bottom edge, 1.0 = top edge).
- **All live data, historical buffers, and overlays use this normalized system.**

## Rendering to Screen
**[2026-04-06: Status Update]**
  - Overlay and live unit layers use a shared transformation model for zoom and pan so rendered positions stay aligned.
  - Grid registration now uses shared geometry based on `map_min`, `map_max`, `grid_steps`, and `grid_zero`.
  - This fixes maps where the playable grid is inset or offset relative to the image edges.
  - The base grid renderer and the chat-driven flash overlay both use the same geometry source, preventing cell mismatch.
  - Grid labels are rendered in a viewport-level overlay so row letters and column numbers stay visible while zooming.
  - Cosmetic dashed grid lines extend beyond the real grid to fill empty map space more cleanly.
  - Overlay elements that should stay visually stable on screen use inverse zoom scaling instead of growing with zoom.



**Known Issues (2026-04-06):**
- [x] Overlay layer shifts vertically when zooming (matrix or projection bug). **[FIXED]**
- [x] Grid flash can highlight the wrong square on maps with an offset grid origin. **[FIXED]**
- [x] Grid labels disappear off-screen during zoom and pan. **[FIXED]**
- [x] Empty areas outside the playable grid look unfinished at high zoom. **[FIXED]**
- [ ] Continue auditing all tactical visuals to ensure each one uses the intended zoom-scaling rule.


**Next Steps:**
1. Continue the zoom-scaling audit for all tactical visuals.
2. Keep shared grid geometry as the single source of truth for any future grid-dependent overlay.

-- When drawing on the minimap or any overlay, convert normalized coordinates to pixel positions:
  - `pixelX = normalizedX * mapPixelWidth`
  - `pixelY = normalizedY * mapPixelHeight` (Y=0 is top)
-- Always use the map's current pixel width/height for conversion.
-- If the map is letterboxed or padded, apply the same transformation as the main map image.
-- For grid-based rendering, do not assume the first grid cell starts at the image edge. Use shared grid geometry built from `grid_zero`, `map_min`, `map_max`, and `grid_steps`.

## Overlay Implementation Guidelines
- **All overlays must accept and operate on normalized coordinates.**
- Do not use absolute pixel or world coordinates in overlay logic.
- Only convert to pixel positions in the final drawing step (e.g., in the CustomPainter's `paint()` method).
- Grid overlays must use the shared grid-geometry helper so the main grid, flash overlay, and any future grid-dependent visuals stay aligned.
- When adding new overlays:
  1. Accept normalized coordinates as input.
  2. Use the map's pixel size for conversion in the painter.
  3. Apply any map transforms (zoom, pan, rotation) consistently.
- If labels must remain visible while zooming, render them in a viewport-level overlay instead of inside the transformed map painter.
- If a visual element should keep a constant on-screen size, apply inverse zoom scaling exactly once.
- For historical trails, death markers, or tactical overlays, store and process all data in normalized form.

## Example: Drawing a Dot Overlay
```dart
// Given normalized coordinates (x, y) and map size (width, height):
final double pixelX = x * width;
final double pixelY = y * height; // Y=0 is top
canvas.drawCircle(Offset(pixelX, pixelY), radius, paint);
```

## Rationale
- **Consistency:** All map logic and overlays work the same way, regardless of map size or resolution.
- **Scalability:** Supports any map, including future larger or non-square maps.
- **Simplicity:** Overlay code is easier to maintain and extend.


## See Also
- `lib/services/wt_api_service.dart` (buffer logic)
- `lib/ui/widgets/map_overlay_trails.dart` (overlay painter, tactical overlay)
- `lib/ui/widgets/map_painter.dart` (main map rendering, live units)
- `lib/ui/widgets/map_grid_geometry.dart` (shared grid registration)
- `lib/ui/widgets/map_grid_flash_overlay.dart` (chat-driven grid flash)
- `lib/ui/widgets/map_viewport_grid_labels_overlay.dart` (viewport-pinned labels)

---
**2026-03-29: Tactical overlay and live unit rendering are now fully aligned. Overlay elements scale and move perfectly with pan/zoom, and layer order is correct. See git history for details.**

---
*This document is a reference for all future overlay and tactical UI development in WTAIASS.*
