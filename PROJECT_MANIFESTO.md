# Project: Modular AI Wingman (War Thunder)

## 🎯 Doelstelling
Een modulaire Android-applicatie die als 'Tactical Advisor' fungeert tijdens War Thunder Ground Realistic Battles. De app analyseert live game-data via de 8111-poort zonder de PC-processen te raken.

## 🏗️ Architectuur (Modulair)
- **Collector:** Haalt JSON op van localhost:8111.
- **Processor:** Verwerkt data (afstandsberekening, clock-positions).
- **Intelligence:** Externe AI-services (gratis tiers) voor flank-voorspellingen.
- **Output:** Canvas-overlay (kaart) + TTS (Text-to-Speech).

## 🚀 Roadmap & Doelen
- [ ] **Fase 1: Connectiviteit**
    - [ ] Flutter-omgeving in VS Code opzetten.
    - [ ] HTTP-service bouwen voor `map_obj.json`.
    - [ ] IP-configuratie UI maken.
- [ ] **Fase 2: Visuele Basis**
    - [ ] Statische kaart (`map.pge`) laden in Stack.
    - [ ] Live markers tekenen voor speler en teamleden.
- [ ] **Fase 3: Tactische Intelligentie**
    - [ ] Logica voor 'Friendly Death' tracking.
    - [ ] TTS-integratie voor nabijheidswaarschuwingen.
    - [ ] Terrein-analyse (wegen vs. water).
- [ ] **Fase 4: AI Cloud Integratie**
    - [ ] Koppeling met gratis AI-API (bijv. Groq of Gemini).
    - [ ] "Predictive Flank" algoritme.

## 📝 Belangrijke Informatie & API Logs
- PC IP: `[Vul hier je IP in]`
- Map Scale Factor: Moet worden berekend per map via `map_info.json`.
- TTS Stem: Pitch op 0.8 voor militaire radio-feel.

## 🛠️ Tech Stack
- **Taal:** Dart (Flutter)
- **IDE:** VS Code
- **AI Tools:** [Naam van je gekozen gratis service]

## 🚀 Roadmap & Doelen (Update 2026)

- [x] **Fase 2: Visuele Basis**
    - [x] Live Tactical Map module:
        - Pixel-perfect rendering van map en units.
        - Dynamische iconen, kleuren, richtingspijlen per unit.
        - Grid overlay exact geschaald naar in-game minimap.
        - Afstand tot speler zichtbaar boven elke unit.
        - Realtime koppeling met War Thunder API (`/map_obj.json`, `/state`, `/map_info.json`).
        - OverlayMenu en navigatie naar MapPage geïntegreerd.
        - Live HUD- en gamechat-feeds direct onder de kaart, real-time zichtbaar.
    - [x] Alle buildfouten opgelost, project bouwt en draait stabiel.
- [x] **Fase 1: Connectiviteit**
    - [x] Flutter-omgeving opzetten.
    - [/] Floating Menu voor IP-configuratie (In progress).
    - [x] Live Data Inspector (In progress).

## ✅ Status
- Kaart, grid, unit-tracking, afstandsweergave en live feeds werken stabiel.
- Provider-architectuur voor robuuste, real-time updates.
- Zie README.md en instructions.md voor details en implementatie.

## 🔧 Componenten (Modulair)
- **OverlayManager:** Beheert de zwevende knop en menu's.
- **ConfigService:** Slaat het IP-adres lokaal op de telefoon op.
- **JSON-Formatter:** Vertaalt rauwe API-data naar een leesbare lijst voor de gebruiker.

## 🛠️ Debug Log
- [x] **Feature: Constant Icon Scaling**
    - Probleem: Icons worden te groot bij inzoomen.
    - Oplossing: Inverse scaling toegepast in CustomPainter via TransformationController.
    - Status: Werkend.

    ## 🧠 Intelligentie & Logica
- [ ] **Unit Tracking (Spatial)**
    - [ ] ID-loze units koppelen op basis van nabijheid.
    - [ ] 'Lost Unit' detectie voor Kill Zones.
- [ ] **Advanced Orientation**
    - [ ] Hull heading berekening voor AI-units.
    - [ ] Turret azimuth integratie voor de Speler (uit /indicators).