# WTAIASS — War Thunder AI Assistant

> A modular Flutter tactical overlay for War Thunder Ground Realistic Battles.
> Connects to the in-game HTTP API (`localhost:8111`) and renders a live tactical map with real-time unit tracking, proximity alerts, and voice callouts — all on your phone.

---

## Features

### Live Tactical Map
- Pixel-perfect map rendering synced with the in-game minimap
- NATO-style tactical icons for all unit types (tanks, SPAA, aircraft, zones)
- Team-colored units with direction arrows
- Real-time distance labels from player to every visible unit
- Fading movement trails (5-minute history)
- Grid overlay matching in-game coordinates (A–H / 1–5 style)
- Adjustable grid opacity
- Pan & zoom with `InteractiveViewer`

### Proximity Alert System
- Configurable detection radius (0–500 m, 0 = off)
- Yellow circle overlay on the map showing the alert radius
- **Ding** sound when a new enemy ground unit enters the radius
- **TTS voice callout**: *"enemy spotted, 2 o'clock"* — relative to hull heading
- Each enemy is called out **once** on entry; re-triggers if they leave and return
- Enemy detection by color (red-dominant RGB) — never triggers on friendlies or player
- Ground units only (tanks, SPAA, tank destroyers) — ignores aircraft
- Adjustable ding volume, voice volume, and circle opacity
- Selectable TTS language and voice with live preview

### Live Feeds
- HUD messages and game chat displayed in real time below the map
- Chat-driven grid flash highlights for coordinates mentioned in chat
- Configurable flash duration

### Map Intelligence
- Follow-player centering mode (keeps your tank centered on screen)
- Viewport-aware grid labels that stay pinned while panning
- Extended grid drawn beyond the playable area for orientation

### Settings (Hamburger Menu)

| Setting              | Description                                              |
|----------------------|----------------------------------------------------------|
| Connection Settings  | PC IP address                                            |
| Trail Buffer         | Trail history duration                                   |
| Grid Flash Duration  | How long chat-triggered grid highlights stay visible     |
| Grid Opacity         | Transparency of all grid lines                           |
| Proximity Alert      | Radius, volumes, circle opacity, TTS voice & language    |
| Follow Player        | Auto-center the map on your vehicle                      |
| Raw Data Debug       | Inspect live API data                                    |

---

## Getting Started

### Prerequisites
- War Thunder running with HTTP API enabled (port `8111`)
- Android device on the same network as your PC
- Flutter SDK installed

### Build & Run

```sh
flutter run -d <device_id>
```

Or build an APK:

```sh
flutter build apk
```

### Configuration
1. Open the app and tap the **☰ menu** → **Connection Settings**
2. Enter your PC's local IP address (e.g. `192.168.0.61`)
3. The app will start polling data immediately

---

## Architecture

```
lib/
├── main.dart                          # App entry, MultiProvider setup
├── services/
│   ├── game_data_service.dart         # API polling, map data
│   ├── wt_api_service.dart            # Chat, HUD, state polling
│   ├── proximity_alert_service.dart   # Ding + TTS proximity module
│   └── database_helper.dart           # SQLite logging
├── logic/
│   └── tracker_service.dart           # Unit tracking & trail history
├── models/
│   ├── map_object.dart                # MapObject model
│   └── tracked_unit.dart              # TrackedUnit with trail points
├── ui/
│   ├── pages/
│   │   └── map_page.dart              # Main tactical map screen
│   └── widgets/
│       ├── map_painter.dart           # CustomPainter: icons, grid, circle
│       ├── map_grid_geometry.dart      # Grid math & alignment
│       ├── map_display.dart           # Map image widget
│       ├── map_overlay_trails.dart    # Movement trail overlay
│       ├── map_grid_flash_overlay.dart # Chat-triggered grid highlights
│       ├── map_viewport_grid_labels_overlay.dart
│       ├── log_feed_box.dart          # HUD/chat feed widget
│       ├── settings_proximity_alert_dialog.dart
│       ├── settings_grid_opacity_dialog.dart
│       ├── settings_grid_flash_duration_dialog.dart
│       └── settings_trail_buffer_dialog.dart
```

---

## Changelog

### 2026-04-12
- Fix: proximity alerts now only trigger on enemy units (red color), never on friendlies or player.
- Enemy detection uses RGB threshold (R > 180, G < 100, B < 100) instead of color comparison with player.

### 2026-04-07
- **Proximity Alert System**: ding sound + TTS clock-position callouts when enemy ground units enter a configurable radius around the player.
- Proximity circle overlay on the map with adjustable opacity.
- TTS voice and language selection with live preview.
- Alerts trigger once per unit entry; re-trigger on re-entry.
- Unified solid grid lines (extended grid matches main grid style).
- Grid opacity slider in settings.
- `effectiveZoom` guard to prevent division-by-zero crashes.

### 2026-04-06
- Chat-driven grid flash highlights for coordinates mentioned in live chat.
- Configurable grid flash duration.
- Unified grid registration with shared geometry using `grid_zero`.
- Viewport-pinned grid labels and extended cosmetic grid.
- Persistent follow-player centering mode.
- Normalized tactical marker sizing during zoom.

### 2026-03-30
- Trail dots use real unit colors, 50% larger, no outline.
- Unified shared transformation matrix for zoom/pan across all overlays.

---

## License
MIT
