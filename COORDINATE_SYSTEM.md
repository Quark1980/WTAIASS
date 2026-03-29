
# WTAIASS Map Coordinate System

## Overview
WTAIASS uses a normalized coordinate system for all map overlays, unit positions, and tactical data. All positions are represented as relative coordinates in the range **0.0 to 1.0** for both X and Y axes, regardless of the actual map pixel size or world units. This ensures overlays and logic are resolution- and map-size independent.

## Coordinate System Details
- **Origin (0,0):** Bottom-left corner of the map.
- **X axis:** Increases to the right (0.0 = left edge, 1.0 = right edge).
- **Y axis:** Increases upwards (0.0 = bottom edge, 1.0 = top edge).
- **All live data, historical buffers, and overlays use this normalized system.**

## Rendering to Screen
**[2026-03-29: Status Update]**
  - Overlay and live unit layers use the same projection logic: `pixelX = normalizedX * mapPixelWidth`, `pixelY = normalizedY * mapPixelHeight` (top-left origin).
  - All overlay elements (trails, deaths) scale with zoom using `1/zoomScale`.
  - Overlay is currently drawn above the map and live units for visibility.
  - Death markers are intended to use the tracked unit color and match the live icon size, but are not yet visible (see TODO).
  - All overlays use the same transformation matrix as the map for pan/zoom, but a bug remains: the overlay layer shifts vertically when zooming (see TODO).

**Known Issues (2026-03-29):**
- [ ] Overlay layer shifts vertically when zooming (matrix or projection bug).
- [ ] Trail dots are not in team color (currently grey).
- [ ] Death markers are not visible.
- [ ] Debug/pink dot should be removed.

**Next Steps:**
1. Fix overlay zoom/pan alignment bug.
2. Ensure trail dots use correct team color.
3. Remove debug dot from overlay.
4. Fix death marker rendering and color.

-- When drawing on the minimap or any overlay, convert normalized coordinates to pixel positions:
  - `pixelX = normalizedX * mapPixelWidth`
  - `pixelY = normalizedY * mapPixelHeight` (Y=0 is top)
-- Always use the map's current pixel width/height for conversion.
-- If the map is letterboxed or padded, apply the same transformation as the main map image.

## Overlay Implementation Guidelines
- **All overlays must accept and operate on normalized coordinates.**
- Do not use absolute pixel or world coordinates in overlay logic.
- Only convert to pixel positions in the final drawing step (e.g., in the CustomPainter's `paint()` method).
- When adding new overlays:
  1. Accept normalized coordinates as input.
  2. Use the map's pixel size for conversion in the painter.
  3. Apply any map transforms (zoom, pan, rotation) consistently.
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

---
**2026-03-29: Tactical overlay and live unit rendering are now fully aligned. Overlay elements scale and move perfectly with pan/zoom, and layer order is correct. See git history for details.**

---
*This document is a reference for all future overlay and tactical UI development in WTAIASS.*
