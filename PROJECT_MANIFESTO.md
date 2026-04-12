# Project: Modular AI Wingman (War Thunder)

## 🎯 Doelstelling
Een modulaire Android-applicatie die als 'Tactical Advisor' fungeert tijdens War Thunder Ground Realistic Battles. De app analyseert live game-data via de 8111-poort zonder de PC-processen te raken.

## 🏗️ Architectuur (Modulair)
- **Collector:** Haalt JSON op van localhost:8111.
- **Processor:** Verwerkt data (afstandsberekening, clock-positions).
- **Intelligence:** Externe AI-services (gratis tiers) voor flank-voorspellingen.
- **Output:** Canvas-overlay (kaart) + TTS (Text-to-Speech).

## 🚀 Roadmap & Status

### ✅ Fase 1: Connectiviteit — VOLTOOID
- [x] Flutter-omgeving in VS Code opzetten
- [x] HTTP-service bouwen voor `map_obj.json`, `/state`, `/indicators`
- [x] IP-configuratie UI via Settings dialog
- [x] Live Data Inspector (debug sheet)

### ✅ Fase 2: Visuele Basis — VOLTOOID
- [x] Pixel-perfect map rendering met grid overlay
- [x] Live markers met NATO-style iconen, kleuren, richtingspijlen
- [x] Afstandsberekening en -weergave voor alle units
- [x] Movement trails met fade (5 min history)
- [x] HUD- en gamechat-feeds direct onder de kaart
- [x] Chat-driven grid flash highlights
- [x] Follow-player centering mode
- [x] Viewport-pinned grid labels
- [x] Grid opacity slider
- [x] Unified solid grid (extended + playable area)

### ✅ Fase 3: Tactische Intelligentie — IN PROGRESS
- [x] **Proximity Alert System:**
    - Ding-geluid bij enemy entry in configureerbare radius (0–500 m)
    - TTS callout met clock-positie t.o.v. hull heading
    - Alleen ground units (tanks, SPAA, tank destroyers)
    - Enemy detectie op basis van rode kleur (RGB drempel) — geen false positives op friendlies
    - Eenmalig per unit entry; re-trigger bij re-entry
    - Proximity circle overlay op de kaart
    - Instelbare volumes (ding + TTS apart)
    - TTS taal- en stemkeuze met live preview
- [ ] 'Friendly Death' tracking en kill zone detectie
- [ ] Terrein-analyse (wegen vs. water)

### 🔮 Fase 4: AI Cloud Integratie — GEPLAND
- [ ] Koppeling met gratis AI-API (Groq / Gemini)
- [ ] "Predictive Flank" algoritme
- [ ] Tactisch advies op basis van unit-bewegingen

## 🛠️ Tech Stack
- **Taal:** Dart (Flutter)
- **IDE:** VS Code + GitHub Copilot
- **Audio:** audioplayers (ding sound)
- **TTS:** flutter_tts (voice callouts)
- **Data:** SharedPreferences, SQLite (sqflite)
- **Packages:** provider, http, wakelock_plus, uuid

## 📝 Belangrijke Informatie & API
- PC IP: Configureerbaar via app settings
- Map Scale Factor: Automatisch berekend per map via `map_info.json`
- TTS Stem: Pitch op 0.8 voor militaire radio-feel
- Coordinate system: Genormaliseerd 0.0–1.0, zie `COORDINATE_SYSTEM.md`

## 🧠 Intelligentie & Logica
- [x] Unit tracking met trail history (UnitHistoryProvider)
- [x] Clock-position berekening (atan2 relatief aan hull heading)
- [x] Enemy detectie via kleurvergelijking met speler
- [ ] ID-loze units koppelen op basis van nabijheid
- [ ] Hull heading + turret azimuth integratie
- [ ] Heatmap generatie uit historische data