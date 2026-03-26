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

## 🚀 Roadmap & Doelen
...
- [x] **Fase 2: Visuele Basis**
        - [x] Live Tactical Map module:
            - Pixel-perfect rendering van map en units.
            - Dynamische iconen, kleuren en richtingspijlen per unit.
            - Realtime koppeling met War Thunder API (`/map_obj.json`, `/state`, `/map_info.json`).
            - OverlayMenu en navigatie naar MapPage geïntegreerd.
        - [x] Alle buildfouten opgelost, project bouwt en draait stabiel.
- [x] **Fase 1: Connectiviteit**
    - [x] Flutter-omgeving opzetten.
    - [/] Floating Menu voor IP-configuratie (In progress).
    - [x] Live Data Inspector (In progress).
...

## 🔧 Componenten (Modulair)
- **OverlayManager:** Beheert de zwevende knop en menu's.
- **ConfigService:** Slaat het IP-adres lokaal op de telefoon op.
- **JSON-Formatter:** Vertaalt rauwe API-data naar een leesbare lijst voor de gebruiker.