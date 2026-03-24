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

### 2. Coordinate Transformation (The Math)
- **Input:** Use `map_min` and `map_max` from `/map_info.json`.
- **Projection:** Translate normalized API coordinates (0.0 - 1.0) to local image pixels.
- **Aspect Ratio:** Account for `BoxFit.contain` letterboxing. Mapping must be relative to the *image boundaries*, not the screen boundaries.
- **Units:** Render the following icons:
    - **Player:** White arrow (using `state['direction']` for rotation).
    - **Friendlies:** Blue icons.
    - **Enemies:** Red icons.

### 3. Interactive UI
- Use `InteractiveViewer` for Pan & Zoom.
- Ensure unit icons stay at a fixed visual size (don't grow huge when zooming in) but remain fixed to their geographical coordinate on the map.

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

---
This file summarizes the War Thunder API endpoints and data fields as used by WTRTI for real-time HUD overlays and telemetry logging.