## Todo List (MeshcoreGRID)

- [x] Update map_painter.dart voor trails, skulls, distance, scaling, fading
- [-] Update instructions.md met gedetailleerde documentatie
- [ ] Integreer API-data: heading/turret_angle in wt_api_service.dart
- [ ] Render hull en turret met heading/turret_angle in map_painter.dart
- [ ] Toon dynamische afstand en status in map_painter.dart
- [ ] Log heading/turret_angle in SQLite trajectory history
- [ ] Voeg dashboardpaneel toe voor live state in main.dart
- [ ] Bewaar trails en death-skulls met nieuwe data
- [ ] Push alle wijzigingen naar GitHub

### Project Doelen & Architectuur

1. **API Koppeling:**
	- Hoofdbron: `/map_obj.json` (posities).
	- Secundair: `/state` (turret_angle) & `/indicators` (heading).

2. **Visuals (MapPainter):**
	- Iconen: Officiële NAVO/War Thunder symbolen (Switch-case op `unit['icon']`).
	- Dynamiek: Trajectlijnen (5 min fade) + Death Skulls (60 sec fade).
	- Schaling: Gebruik `effectiveScale` voor scherpte bij zoom.

3. **Data Opslag:**
	- Database: SQLite (sqflite).
	- Limiet: Max 20 matches per map OF 100MB totaal.
	- Doel: Toekomstige Heatmap generatie.

# 🛰️ War Thunder Tactical AI Overlay - Project Roadmap & Instructions

## 🎯 Project Goal
A modular Android application (Flutter) that visualizes live War Thunder telemetry. The primary focus is a high-precision tactical map overlay that stays 1:1 synchronized with the in-game minimap, followed by a Gemini-powered tactical AI advisor.

---

## 🛠️ Environment & Testing
- **Framework:** Flutter (Dart)
- **Target:** Android (Physical Device & Android Studio Emulator)
- **Networking:** - Physical Device: Access PC via Local IPv4 (e.g., `192.168.0.61`).
    - Emulator: Access PC via `10.0.2.2` or Local IPv4.
    - **Protocol:** HTTP (Cleartext) must be enabled in `AndroidManifest.xml`.

---


## 📍 PHASE 1: PRECISION MAP RENDERING (Current Priority)
The map and units must be 100% aligned. Do not proceed to AI features until this is pixel-perfect.

### 1. Data Acquisition
- **Endpoints:** Poll `http://[IP]:8111/state`, `/map_info.json`, and `/map_obj.json` every 500ms.
- **Map Image:** Fetch `http://[IP]:8111/map.img?gen=1`. Use a cache-buster timestamp to force refreshes.

### 2. Android Permissions & Networking
- In `android/app/src/main/AndroidManifest.xml`:
	- Add `<uses-permission android:name="android.permission.INTERNET" />` above the `<application>` tag.
	- Add `android:usesCleartextTraffic="true"` inside the `<application>` tag to allow HTTP traffic to your PC.

### 3. Coordinate Transformation (Projection Logic)
- **Input:** Use `map_max` from `/map_info.json` (typically `[4096, 4096]`).
- **Origin:** The in-game map uses the center as origin (0,0). The Flutter image uses the top-left as origin.
- **Projection Formula:**
	```dart
	// Convert in-game (center-origin) to image (top-left-origin)
	double xRatio = (ux + mapMaxX / 2) / mapMaxX;
	double yRatio = 1.0 - ((uy + mapMaxY / 2) / mapMaxY); // y-axis flip
	double drawX = dstRect.left + (xRatio * dstRect.width);
	double drawY = dstRect.top + (yRatio * dstRect.height);
	```
- **Aspect Ratio:** Always use the `dstRect` (the actual drawn map area) for all projections, not the full widget size.
- **Units:**
	- Render units with `_drawArrow(canvas, Offset(drawX, drawY), angle, color)`
	- Use `unit['angle']` for rotation.

### 4. Null Safety & Code Hygiene
- All usages of `apiService` in Dart use the `?` operator for null safety.
- `.withOpacity(...)` is used for alpha where needed; no analyzer warnings remain.

### 5. Interactive UI
- Uses `InteractiveViewer` for pan & zoom.
- Unit icons remain fixed in size and position relative to the map.

### 6. Deployment
- Build: `flutter build apk`
- Deploy: `flutter install` (device must be connected via USB or network ADB)

### 7. Troubleshooting
- If units are not aligned: check if the in-game coordinates are center-origin and apply the projection formula above.
- If the app cannot connect: ensure your device and PC are on the same network and HTTP is allowed in the manifest.

---

## 🧠 PHASE 2: MODULAR AI & LOGIC (Future)
- **Gemini Integration:** Analyze `/gamechat` and `/state

# War Thunder API Information (WTRTI)

## Overview
WTRTI (War Thunder Real-Time Indicators) is a HUD overlay and logging tool for War Thunder that uses the game's official telemetry API. It does **not** modify the game or its data, but reads telemetry data via HTTP endpoints exposed by the game client. This allows for real-time display and logging of various in-game parameters.

## API Endpoints
The War Thunder client exposes several HTTP endpoints on the local network (default port: 8111). These endpoints provide JSON data about the current game state, vehicle, map, and chat. The most relevant endpoints are:

- `http://[IP]:8111/state` — **Flight/vehicle state** (speed, altitude, engine, etc.)
- `http://[IP]:8111/indicators` — **Indicators** (heading, course, fuel, etc.)
- `http://[IP]:8111/map_obj.json` — **Map objects** (icons, positions, objectives, etc.)
- `http://[IP]:8111/gamechat` — **Game chat** (recent chat messages)
map image is here http://[IP]:8111/map.img?gen=1
## Example Data Fields

### `/state` (Flight/Vehicle State)
- `indicated_air_speed` — Airspeed (km/h)
- `vertical_speed` — Climb rate (m/s)
- `altitude` — Altitude (m)
- `fuel_mass` — Remaining fuel (kg)
- `engine_rpm` — Engine RPM
- `oil_temp` — Oil temperature (°C)
- `water_temp` — Water temperature (°C)
- `gear_down` — Landing gear status (bool)
- `flaps_down` — Flaps status (bool)
- `turret_angle` — Turret angle (deg)

### `/indicators` (Cockpit/Panel Indicators)
- `heading` — Compass heading (deg)
- `course` — Course (deg)
- `fuel` — Fuel (kg or %)
- `rpm` — Engine RPM
- `manifold_pressure` — Manifold pressure (mmHg)
- `oil_temp` — Oil temperature (°C)
- `water_temp` — Water temperature (°C)

### `/map_obj.json` (Map Objects)
- List of objects with fields like:
	- `type` — Object type (e.g., player, enemy, objective)
	- `icon` — Icon name
	- `pos` — Position (x, y, z)
	- `name` — Player or object name
	- `map_generation` — Map name/ID

### `/gamechat` (Game Chat)
- List of recent chat messages:
	- `msg` — Message text
	- `author` — Sender
	- `time` — Timestamp

## Notes
- Not all fields are available for every vehicle (e.g., some aircraft may not report `fuel` or `radio_altitude`).
- The API is only available if "Allow web UI" is enabled in War Thunder's custom settings (required for Test Flight/Custom Battles).
- Data is updated in real-time (typically every 100–500ms).
- The overlay and API are cross-platform (Windows, Linux, macOS).

## References
- [WTRTI GitHub](https://github.com/MeSoftHorny/WTRTI)
- [WTRTI Documentation](https://mesofthorny.github.io/WTRTI/)
- [WTRTI Features](https://github.com/MeSoftHorny/WTRTI/blob/main/docs/docs/features.md)
- [WTRTI Lua API](https://github.com/MeSoftHorny/WTRTI/blob/main/docs/docs/lua-api.md)
https://github.com/lucasvmx/WarThunder-localhost-documentation


### War Thunder API Unit Mapping (JSON)

Gebruik deze lijst voor de `switch-case` logica in de `MapPainter` en de `DatabaseHelper`.

| JSON `type`              | JSON `icon`       | Beschrijving                      | Visuele Prioriteit |
|:-------------------------|:------------------|:----------------------------------|:-------------------|
| `ground_model`           | `Player`          | Speler (Romp + Koepel/Loop)       | Hoog               |
| `ground_model`           | `HeavyTank`       | Zware Tank (Ruit-vorm)            | Hoog               |
| `ground_model`           | `MediumTank`      | Middelzware Tank (Vierkant)       | Medium             |
| `ground_model`           | `LightTank`       | Lichte Tank (Driehoek)            | Medium             |
| `ground_model`           | `TankDestroyer`   | Tankjager (Omgekeerde V)          | Hoog               |
| `ground_model`           | `SPAA`            | Luchtafweer (Bol met lijnen)      | Medium             |
| `capture_zone`           | `capture_zone`    | Cap Point (A, B, C)               | Hoog               |
| `airfield`               | `none`            | Vliegveld / Landingstrip          | Laag               |
| `respawn_base_tank`      | `none`            | Tank Spawn Locatie                | Laag               |
| `respawn_base_fighter`   | `none`            | Vliegtuig Spawn (Jager)           | Laag               |
| `respawn_base_bomber`    | `none`            | Vliegtuig Spawn (Bommenwerper)    | Laag               |
| `air`                    | `Fighter`         | Vliegtuig (Jager)                 | Medium             |
| `air`                    | `Bomber`          | Vliegtuig (Bommenwerper)          | Medium             |

**Opmerking voor Logica:**
- Als `icon == "none"`, gebruik dan het veld `type` om het symbool te bepalen.
- Gebruik het veld `color` (Hex) voor de team-kleur, behalve bij de `Player` (gebruik daar de unieke Player-kleur of Blauw).

### War Thunder Official Tactical Icons (APP-6 Derived)

Gebruik de volgende tekenregels in de `MapPainter` voor een authentieke weergave. Alle iconen hebben een zwarte omlijning (stroke) van 0.5px voor contrast.

| Unit `icon`       | Vorm Beschrijving                               | Render Logica (Flutter Path) |
|:------------------|:-----------------------------------------------|:-----------------------------|
| **MediumTank** | Standaard rechthoek/vierkant.                  | `canvas.drawRect`            |
| **HeavyTank** | Vierkant met dikke verticale lijn in het midden.| `drawRect` + `drawLine(centerTop, centerBottom)` |
| **LightTank** | Vierkant met één diagonale lijn.               | `drawRect` + `drawLine(bottomLeft, topRight)` |
| **TankDestroyer** | Omgekeerde driehoek (punt naar beneden).       | `Path` (TopLeft -> TopRight -> BottomCenter) |
| **SPAA** | Cirkel met twee 'antennes' aan de bovenkant.   | `drawCircle` + 2x `drawLine(top)` |
| **Fighter** | Gestroomlijnde 'V' (pijlpunt).                 | `Path` (Pijlpunt vorm)       |
| **Bomber** | Brede 'T' vorm (vliegtuig met spanwijdte).     | `Path` (T-vormig silhouet)   |
| **Player** | Romp (pijl) + Koepel (cirkel) + Loop (lijn).   | Samengestelde `Path` & `Circle` |
| **capture_zone** | Cirkel met de letter (A, B, C) in het midden.  | `drawCircle` + `TextPainter` |

**Specifieke Afmetingen:**
- Basis grootte: 4.0 - 5.0 pixels (bij 100% zoom).
- Stroke width: 0.5 - 1.0 pixels.
- Tekst grootte (afstand/zone): 8.0 pixels.

Implementeer de volledige "Tactical Suite" voor de War Thunder Overlay op basis van de volgende technische specificaties:

1. API INTEGRATIE (wt_api_service.dart):
   - Breid de service uit om gelijktijdig /map_obj.json, /state en /indicators te pollen (interval 500ms).
   - Koppel 'turret_angle' (/state) en 'heading' (/indicators) specifiek aan de unit met icon 'Player'.

2. UNIT PROJECTIE & KLEUREN (map_painter.dart):
   - Gebruik de "Perfect Alignment" formule voor x/y mapping:
     * xRatio = (unitX + mapMaxX / 2) / mapMaxX
     * yRatio = 1.0 - ((unitY + mapMaxY / 2) / mapMaxY)
     * Teken op: dstRect.left + (ratio * dstRect.width/height).
   - DYNAMISCHE KLEUREN: Haal de kleur direct uit unit['color'] via `Color(int.parse(unit['color'].replaceFirst('#', '0xff')))`.

3. ADVANCED RENDERING (APP-6 STANDAARD):
   - Implementeer een switch-case voor iconen:
     * 'Player': Blauwe pijl (hull heading) + Cirkel met lijn (turret direction).
     * 'HeavyTank': Vierkant met dikke verticale lijn in het midden.
     * 'MediumTank': Standaard vierkant.
     * 'LightTank': Vierkant met diagonale lijn (LB naar RO).
     * 'TankDestroyer': Omgekeerde driehoek (punt omlaag).
     * 'capture_zone': Cirkel met letter (A, B, C).
   - SCALING: Gebruik `effectiveScale = 1.0 / zoomScale` voor alle iconen, strokes (0.5px) en tekst (size 8).

4. TRAJECTEN & EFFECTEN:
   - TRAILS: Teken de afgelegde route van de laatste 5 minuten met een lineaire fade-out (opacity 1.0 naar 0.0).
   - DEATH SKULLS: Als een unit uit de JSON verdwijnt, toon een 'X' op de laatste locatie die in 60 seconden volledig uitfadet.
   - AFSTAND:
---

This file summarizes the War Thunder API endpoints and data fields as used by WTRTI for real-time HUD overlays and telemetry logging.