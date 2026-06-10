# Game Design — Steal a Schnitzel

## 1. Genre-Recherche (Stand Juni 2026)

**Entscheidung: „Steal a X"-Simulator** — aus diesen Gründen:

- **Steal a Brainrot** erreichte 25,8 Mio. gleichzeitige Spieler (Okt. 2025) — der
  höchste CCU-Wert der Videospielgeschichte — und über 60 Mrd. Visits.
- **Grow a Garden** bewies davor dieselbe Formel: simpler Loop + Offline-Progression.
- Simulatoren haben laut Genre-Analysen 2026 die breiteste Zielgruppe aller
  Roblox-Genres; „Brainrot"-Games sind der schnellste Viral-Pfad (sechsstellige
  Spielerzahlen in Tagen).
- Das Genre ist zu 100 % per Code umsetzbar (prozedurale Voxel-Charaktere,
  keine teuren 3D-Assets oder Animationen nötig) — perfekt für unseren Stack.

### Warum geht das Genre viral?

1. **Filmbare Emotionen:** Die Steal-Mechanik erzeugt Clips (Triumph & Wut), die auf
   TikTok/YouTube millionenfach geteilt werden — kostenloses Marketing.
2. **Sofort verständlicher Loop:** Kaufen → Einkommen → Größer kaufen. Kein Tutorial nötig.
3. **Rarity-FOMO:** Secret-Charaktere (0,5 % Chance) erzeugen Jagd-Verhalten und Status.
4. **Retention:** Offline-Earnings + Rebirth geben Gründe zum Wiederkommen.
5. **Mobile-first:** Alles läuft über ProximityPrompts — funktioniert auf jedem Budget-Handy
   (2026 die wichtigste Plattform-Anforderung).

### Eigene IP statt Brainrot-Memes

Die Original-Brainrot-Charaktere sind rechtlich heikel (KI-Memes Dritter). Wir nutzen
**eigene absurde Food-Tier-Hybride** („Schnitzel Cat", „Galactic Döner",
„THE FINAL BRATWURST") — gleicher Humor-Mechanismus, null IP-Risiko, und der
Deutsch-Food-Twist ist ein eigenes Meme-Potenzial.

## 2. Core Loop & Balancing

| Rarity | Gewicht | Preis (Basis) | Income/s (Basis) | Amortisation |
|---|---|---|---|---|
| Common | 50 % | 25 | 1 | 25 s |
| Uncommon | 25 % | 150 | 5 | 30 s |
| Rare | 12 % | 800 | 20 | 40 s |
| Epic | 7 % | 4.000 | 75 | ~53 s |
| Legendary | 4 % | 20.000 | 300 | ~67 s |
| Mythic | 1,5 % | 100.000 | 1.200 | ~83 s |
| Secret | 0,5 % | 750.000 | 7.500 | 100 s |

- Amortisationszeit steigt mit Rarity → seltene Charaktere sind langfristige Investments
  und damit **lohnende Steal-Ziele** (Konflikt by Design).
- Rebirth: 15.000 × 4^n, +50 % Income permanent → exponentielle Langzeit-Progression.
- 12 Slots pro Base → erzwingt Entscheidungen (Common rauswerfen? → künftiges Feature).

## 3. Anti-Frust-Mechaniken (wichtig für Retention)

- **Base-Lock:** 60 s Schild, 180 s Cooldown — Gegenspieler zur Steal-Mechanik.
- **Dieb ist verlangsamt** (WalkSpeed 12 statt 16) und markiert → Besitzer hat eine Chance.
- **Tod des Diebs** = Beute geht zurück an den Besitzer.
- **Steal-Cooldown 15 s** gegen Chain-Griefing.

## 4. Monetarisierungs-Roadmap (nach Launch)

1. Gamepass „2x Cash" und „Auto-Collect" (Aspiration statt Paywall — 2026-Trend).
2. Dev-Products: Cash-Pakete, „Sofort-Lock".
3. Cosmetics: Hüte/Auren für Charaktere (Status, handelbar-fähig).

## 5. Content-Roadmap (Viral-Hebel)

1. **Woche 1–2:** Neue Secret-Charaktere im Wochentakt (Patch-Notes = TikTok-Content).
2. **Events:** „2x Luck Weekend", Admin-Events zur Primetime (der nachweisliche
   Wachstumstreiber bei Steal a Brainrot / Grow a Garden).
3. **Trading** als großes Update sobald DAU stabil — verlängert Lifetime massiv.
4. Badges + Daily-Login-Streak.

## 6. Technische Notizen

- Alles server-authoritativ (Cash, Käufe, Steals) — keine Client-Trust-Pfade.
- DataStore mit Retry + „DataLoadFailed"-Guard (nie echte Daten mit Frischprofil
  überschreiben).
- Bekannte bewusste Vereinfachung: Verlässt der Besitzer das Spiel, während sein
  Charakter getragen wird, ist der Charakter aus seinem Save raus (er verlor ihn beim
  Steal). Stirbt der Dieb danach, verfällt die Beute.

## Quellen

- [NME: Steal A Brainrot is Roblox's latest viral hit](https://www.nme.com/news/gaming-news/steal-a-brainrot-is-robloxs-latest-viral-hit-grow-a-garden-3888650)
- [Wikipedia: Steal a Brainrot](https://en.wikipedia.org/wiki/Steal_a_Brainrot)
- [Outlook Respawn: Steal a Brainrot bricht CCU-Rekord](https://respawn.outlookindia.com/gaming/gaming-news/robloxs-steal-a-brainrot-breaks-all-time-player-record)
- [PC Gamer: Warum Steal a Brainrot so populär ist](https://www.pcgamer.com/games/sim/one-of-robloxs-biggest-experiences-right-now-is-a-bizarre-italian-brainrot-character-stealing-simulator-and-lord-help-me-i-now-understand-why-its-so-popular/)
- [KitsBlox: Popular Roblox Game Genres 2026](https://kitsblox.com/blog/popular-roblox-game-genres-2026)
- [StudioKrew: Top Roblox Games 2026](https://studiokrew.com/blog/top-games-on-roblox-and-analysis-2026/)
- [rbxrealm: Most popular Roblox games 2026](https://rbxrealm.com/en/the-most-popular-roblox-games-in-2026.html)
