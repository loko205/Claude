# Pferderennen — Roblox Game Design Dokument

> Arbeitstitel: **Royal Turf** (Platzhalter)
> Genre: Spectator / Betting Simulation
> Plattform: Roblox (Luau)
> Stand: v0.1 — Design-Phase, noch kein Code

---

## 1. Vision & Pitch

Ein lebendiges Rennbahn-Erlebnis: Spieler betreten als Zuschauer eine Pferderennbahn,
studieren das Renn-Programm, platzieren Wetten auf Pferde und verfolgen das Rennen live
von der Tribüne. Der Nervenkitzel entsteht nicht durch eigenes Geschick im Steuern,
sondern durch **Analyse, Einsatz und das Mitfiebern** beim Ausgang.

**Kern-Fantasie:** „Ich habe das richtige Pferd erkannt und gewinne den Pool."

**Warum es funktioniert:**
- Niedrige Einstiegshürde — kein Skill im Bewegen nötig, jeder kann sofort mitspielen
- Soziales Mitfiebern — alle Spieler im Server schauen dasselbe Rennen
- Kurze Sessions (Rennen alle paar Minuten) → hohe Wiederholrate
- Sammel- & Progressions-Anreize über die Zeit

---

## 2. ⚠️ Compliance & Glücksspiel-Regeln (KRITISCH)

Roblox' Community Standards verbieten **simuliertes Echtgeld-Glücksspiel**. Das Design
MUSS folgende Regeln einhalten, sonst droht Game-Takedown / Account-Ban:

| Regel | Umsetzung |
|---|---|
| Keine Robux-Wetten | Gewettet wird **nur** mit In-Game-Währung „Coins" |
| Keine Auszahlung | Coins können **niemals** zurück in Robux getauscht werden |
| Robux nur für Komfort | Robux kauft Coins / Kosmetik / Boosts — nie „Wett-Guthaben mit Auszahlung" |
| Kein echtes Zufallsglücksspiel als Kauf | Lootboxen/Gambling-Käufe mit Robux vermeiden |
| Altersangemessen | Keine Casino-Ästhetik, die Minderjährige zum echten Glücksspiel anleitet |

**Faustregel:** Coins sind ein geschlossenes Spiel-Ökosystem. Geld fließt nur *rein*
(Robux → Coins), nie *raus*. Damit ist es kein Glücksspiel im rechtlichen Sinn, sondern
ein Skill-/Glücks-Spiel mit virtueller Punktewährung (vergleichbar mit vielen Casual-Games).

---

## 3. Core Gameplay Loop

```
        ┌─────────────────────────────────────────────────┐
        │                                                  │
        ▼                                                  │
  [WETTPHASE]  ──►  [RENNEN LÄUFT]  ──►  [AUSWERTUNG]  ──► [PAUSE]
   60–90 Sek         60–120 Sek          10 Sek          20 Sek
        │                                                  │
   Programm lesen   Live zuschauen     Pool-Auszahlung   nächstes
   Odds prüfen      Kommentar/Hype     Coins gutschreiben Rennen-Setup
   Coins setzen     keine Eingriffe    Statistik update
```

Ein voller Zyklus dauert ca. **3–4 Minuten**. Der Server fährt diese Phasen kontinuierlich
durch — wer joint, steigt in der laufenden Phase ein.

**Phasen im Detail:**

1. **Wettphase (Betting):** Renn-Programm wird angezeigt (Pferde, Stats, aktuelle Odds).
   Spieler wählen Pferd + Einsatz + Wettart. Live-Anzeige des Pools und sich ändernder Odds.
2. **Rennen (Racing):** Wetten gesperrt. Server simuliert das Rennen tick-basiert und
   broadcastet Positionen; Clients animieren die Pferde auf der Strecke. Kamera-Optionen.
3. **Auswertung (Settlement):** Zieleinlauf-Reihenfolge steht fest. Pool wird unter
   Gewinnern verteilt, Coins gutgeschrieben, Statistiken/Quests aktualisiert.
4. **Pause (Cooldown):** Kurze Verschnaufpause, Highlights/Leaderboard, Setup des nächsten
   Rennens (neue Pferd-Aufstellung).

---

## 4. Renn-Simulation — „so realistisch wie möglich"

### 4.1 Modell-Wahl: Stamina-/Pace-Simulation (empfohlen)

Echte Pferderennen werden weder durch reinen Zufall noch durch reine Physik bestimmt,
sondern durch das Zusammenspiel von **Tempo-Einteilung, Ausdauer, Form und Tagesglück**.
Deshalb empfehle ich ein **tick-basiertes Simulationsmodell** statt reinem RNG oder
Roblox-Physik:

- **Reines RNG** → unfair-wirkend, keine Strategie beim Wetten, langweilig.
- **Roblox-Physik** → schön anzusehen, aber schwer zu balancieren und serverlastig;
  Kollisionen/Ragdoll sehen bei „Rennen zuschauen" oft komisch aus.
- **Stamina-Sim (gewählt)** → deterministische, faire Simulation auf dem Server mit
  nachvollziehbaren Faktoren; Visualisierung läuft entkoppelt auf den Clients. Beste
  Balance aus Realismus, Performance und Wett-Strategie.

### 4.2 Pferd-Attribute (Stats)

Jedes Pferd hat verdeckte und sichtbare Attribute. Sichtbare helfen beim Wetten,
verdeckte sorgen für Spannung.

| Attribut | Sichtbar? | Wirkung |
|---|---|---|
| **Speed** (Topspeed) | ja | maximale Geschwindigkeit |
| **Stamina** (Ausdauer) | ja | wie lange Topspeed gehalten wird |
| **Acceleration** | ja | wie schnell auf Tempo |
| **Consistency** | teilweise | Streuung der Tagesform (niedrig = unberechenbar) |
| **Running Style** | ja | Front-Runner / Stalker / Closer (Tempo-Profil) |
| **Form** | als Trend (↑↓) | aktuelle Tagesform, schwankt pro Rennen |
| **Going Preference** | ja | bevorzugter Bodenzustand (trocken/nass) |
| **Luck Roll** | nein | einmaliger Zufallsfaktor pro Rennen |

### 4.3 Simulations-Algorithmus (Pseudo)

Das Rennen wird in diskreten Ticks simuliert (z. B. 10 Ticks/Sek). Jedes Pferd bewegt
sich entlang einer 1D-Distanz (0 → Renndistanz). Die Visualisierung mappt diese Distanz
auf den 3D-Track.

```lua
-- Server-seitig, deterministisch pro Rennen (seed gespeichert)
function simulateRace(horses, distance, going, seed)
    local rng = Random.new(seed)
    -- Tagesform & Luck einmalig würfeln
    for _, h in horses do
        h.formMod  = rollForm(h.consistency, rng)      -- z.B. 0.92..1.08
        h.goingMod = goingMatch(h.goingPref, going)     -- 0.95..1.05
        h.pace     = paceProfile(h.runningStyle)        -- Tempo-Kurve über Renndistanz
    end

    local positions = {}            -- horse -> zurückgelegte Distanz
    local stamina   = {}            -- horse -> Restausdauer
    local frames    = {}            -- pro Tick: Snapshot der Positionen (für Replay/Broadcast)

    while not allFinished(positions, distance) do
        for _, h in horses do
            local raceProgress = positions[h] / distance        -- 0..1
            local targetSpeed  = h.speed
                               * h.pace(raceProgress)            -- Tempo-Einteilung
                               * h.formMod * h.goingMod
                               * staminaFactor(stamina[h])       -- müde → langsamer
                               * (1 + rng:NextNumber(-0.03, 0.03)) -- Mikro-Rauschen/Tick

            positions[h] += targetSpeed * DT
            stamina[h]   -= staminaDrain(targetSpeed, h.stamina) * DT
        end
        frames[#frames+1] = snapshot(positions)
    end

    return rankByFinishTime(positions), frames   -- Ergebnis + Replay-Daten
end
```

**Wichtig:**
- Simulation läuft **vollständig auf dem Server** → kein Client kann den Ausgang manipulieren.
- Server broadcastet die `frames` (oder nur periodische Positions-Updates + Interpolation auf
  Clients), damit alle Spieler synchron dasselbe Rennen sehen.
- Der `seed` wird gespeichert → Rennen ist reproduzierbar (Anti-Cheat, Replays, Debugging).

### 4.4 Odds-Berechnung

Da wir Pari-Mutuel nutzen (siehe §5), ergeben sich die **Auszahlungs-Odds aus dem Pool**,
nicht aus den Stats. Aber wir zeigen zusätzlich **„Morning Line"-Schätz-Odds** vor der
Wettphase, die aus den Pferd-Stats errechnet werden (Win-Wahrscheinlichkeit via vielen
Monte-Carlo-Simulationsdurchläufen oder einer Stat-Heuristik). Diese helfen neuen Spielern.

---

## 5. Wett-System — Pari-Mutuel / Tote

### 5.1 Prinzip

Alle Einsätze einer Wettart fließen in einen gemeinsamen **Pool**. Nach dem Rennen wird
der Pool (abzüglich „Takeout", siehe unten) unter den Gewinnern **proportional zum Einsatz**
verteilt. Das ist exakt das System echter Rennbahnen (Totalisator).

```
Auszahlung pro Spieler = (eigener Einsatz / Summe Gewinner-Einsätze) × (Pool × (1 − Takeout))
```

**Beispiel (Win-Pool):**
- Pool gesamt: 1000 Coins, Takeout 10% → ausschüttbar 900 Coins
- Pferd #3 gewinnt. Auf #3 wurden gesamt 200 Coins gesetzt.
- Spieler A hatte 50 Coins auf #3 → A bekommt (50/200) × 900 = **225 Coins**.

### 5.2 Wettarten (gestaffelt freischaltbar)

| Wettart | Beschreibung | Schwierigkeit |
|---|---|---|
| **Win** | Pferd gewinnt (Platz 1) | Einsteiger |
| **Place** | Pferd unter den ersten 2–3 | Einsteiger |
| **Show** | Pferd unter den ersten 3 | Einsteiger |
| **Exacta** | Platz 1+2 in exakter Reihenfolge | Fortgeschritten |
| **Quinella** | Platz 1+2 in beliebiger Reihenfolge | Fortgeschritten |
| **Trifecta** | Platz 1+2+3 exakt | Experte (hohe Auszahlung) |

→ Jede Wettart hat ihren **eigenen Pool**. Start mit Win/Place/Show, Rest später freischalten.

### 5.3 Takeout (Coin-Sink)

Der „Takeout" (z. B. 10–15%) wird vom Pool einbehalten und **aus dem Spiel entfernt**.
Das ist essenziell als **Coin-Sink** gegen Inflation der Wirtschaft (sonst wächst die
Coin-Menge unkontrolliert). Optional: ein Teil des Takeout fließt in einen wachsenden
„Jackpot" für eine spezielle Wettart → Hype.

### 5.4 Single-Player-Fallback

Pari-Mutuel braucht eigentlich mehrere Wettende. Für leere/kleine Server:
- **NPC-Liquidität:** Der Server fügt simulierte NPC-Einsätze hinzu (orientiert an den
  Morning-Line-Odds), damit auch ein einzelner Spieler vernünftige Auszahlungen bekommt.
- Alternativ in sehr leeren Servern automatisch auf **Fixed-Odds** umschalten (Odds aus Stats).

---

## 6. Pferd- & Progressions-Systeme

Damit langfristig Bindung entsteht, mehr als nur Wetten:

- **Stallbesitz (Stretch Goal):** Spieler können später eigene Pferde kaufen/züchten,
  trainieren und in Rennen schicken (Preisgeld statt/zusätzlich zu Wetten).
- **Pferd-Statistiken:** Jedes NPC-Pferd hat eine Historie (letzte Platzierungen, „Form"),
  einsehbar im Programm → belohnt aufmerksame Spieler.
- **Spieler-Level & Rang:** XP fürs Teilnehmen und Gewinnen, schaltet Wettarten/Tribünen-
  Bereiche/Kosmetik frei.
- **Daily Login / Quests:** „Gewinne 3 Win-Wetten", „Setze auf einen Außenseiter (Odds > 10:1)".
- **Leaderboards:** Größter Einzelgewinn, höchste Coin-Bilanz (saisonal zurückgesetzt).

---

## 7. UI / UX

**Haupt-Screens:**
1. **Renn-Programm (Race Card):** Liste der Pferde mit Nummer, Name, Stats-Balken,
   Form-Trend, Morning-Line-Odds, Jockey-Farben.
2. **Wett-Slip:** Wettart wählen → Pferd(e) wählen → Einsatz (Schnellwahl-Chips: 10/50/100/Max)
   → Bestätigen. Anzeige des potenziellen Gewinns (geschätzt, da Pool sich ändert).
3. **Live-Pool-Anzeige:** Wie viel auf welches Pferd, sich aktualisierende Odds, Countdown.
4. **Renn-Ansicht:** Kameramodi (Tribüne / Verfolger-Cam / Zieleinlauf-Cam), Live-Positionen,
   Kommentator-Text/Sound, Mini-Map mit Position auf der Strecke.
5. **Ergebnis & Auszahlung:** Photo-Finish-Reihenfolge, eigene Auszahlung hervorgehoben,
   Coin-Animation.

**Stil:** Hell, freundlich, „königliche Rennbahn", KEINE Casino-Neon-Ästhetik (Compliance §2).

---

## 8. Technische Architektur (Roblox / Luau)

### 8.1 Client-Server-Modell

> **Goldene Regel:** Geld, Wetten und Renn-Ausgang sind **server-autoritativ**. Der Client
> zeigt nur an und sendet Wett-Anfragen. Niemals dem Client trauen.

```
ServerScriptService/
  RaceController       -- State Machine: Betting → Racing → Settlement → Cooldown
  RaceSimulator        -- §4.3 Simulation, erzeugt Ergebnis + Replay-Frames
  BettingService       -- nimmt Wetten an, validiert, verwaltet Pools
  PayoutService        -- §5.1 Pari-Mutuel Auszahlung + Takeout
  EconomyService       -- Coins-Saldo, Transaktionen (autoritativ)
  DataService          -- DataStore: Saldo, Stats, Quests (mit Retry/Session-Lock)
  HorseService         -- generiert Pferd-Aufstellungen + Stats pro Rennen

ReplicatedStorage/
  Remotes/             -- RemoteEvents/Functions (PlaceBet, RaceUpdate, RaceResult, ...)
  Shared/              -- Konstanten, Typen (Luau types), Odds-Heuristik (read-only Anzeige)

StarterPlayerScripts/
  BettingUI            -- Wett-Slip, Programm, Pool-Anzeige
  RaceRenderer         -- empfängt Positions-Updates, interpoliert Pferde-Bewegung
  CameraController     -- Kameramodi
```

### 8.2 Netzwerk

- **PlaceBet** (Client→Server, RemoteFunction): validiert Phase, Saldo, Einsatzgrenzen;
  bucht Coins, fügt zum Pool hinzu, gibt Bestätigung zurück.
- **RaceUpdate** (Server→alle Clients, RemoteEvent): periodische Positions-Snapshots
  (z. B. 10/s) → Clients interpolieren für flüssige Bewegung (Bandbreite sparen).
- **RaceResult** (Server→alle): finale Reihenfolge + Auszahlungen.
- **OddsUpdate** (Server→alle): aktualisierte Pool-Odds während Wettphase.

### 8.3 Datenpersistenz (DataStore)

- Gespeichert: Coin-Saldo, Level/XP, Statistiken, Quest-Fortschritt, Kosmetik.
- **Session-Locking** gegen Item-/Coin-Duplikation bei mehreren Servern.
- **Retry mit Backoff** bei DataStore-Fehlern; bei Fehlschlag Spieler nicht weiterspielen
  lassen, der echtes Coins-Risiko hätte (Datenverlust-Schutz).
- Empfehlung: bewährte Lib wie **ProfileService / ProfileStore** statt rohes DataStore-API.

### 8.4 Anti-Cheat / Fairness

- Renn-Ergebnis NUR server-seitig, Client bekommt es erst zur Settlement-Phase final.
- Wett-Annahme nur während Betting-Phase, server-validierter Timestamp.
- Alle Coin-Transaktionen server-autoritativ + geloggt.
- Einsatzgrenzen (min/max) gegen Pool-Manipulation.

---

## 9. Monetarisierung (ToS-konform, siehe §2)

| Produkt | Typ | Beschreibung |
|---|---|---|
| Coin-Pakete | Developer Product (Robux) | Coins kaufen — Komfort, KEINE Auszahlung möglich |
| Game Pass: VIP-Tribüne | Game Pass | exklusive Kamera, Lounge, Coin-Bonus beim Login |
| Kosmetik | Developer Product / Pass | Jockey-Outfits, Pferd-Skins, Tribünen-Emotes |
| Daily Coin Boost | Game Pass | x1.5 auf tägliche Login-Coins |

**Nicht erlaubt:** Robux direkt als Wetteinsatz; Coins → Robux/Echtgeld zurücktauschen.

---

## 10. Roadmap / Milestones

### M0 — Prototyp (intern, kein Release)
- 1 gerade Strecke, 4 Pferde, RNG-light Simulation
- State Machine (Betting/Racing/Settlement)
- Nur Win-Wette, Single-Player mit NPC-Liquidität
- Coins ohne Persistenz (Memory)
- **Ziel:** Loop fühlt sich gut an?

### M1 — Spielbarer Kern (Closed Test)
- Stamina-Sim (§4.3) mit echten Stats + Running Styles
- Pari-Mutuel Pools, Win/Place/Show
- DataStore-Persistenz (ProfileStore)
- Basis-UI (Programm, Wett-Slip, Ergebnis)
- Server-autoritativ + Anti-Cheat-Grundlagen

### M2 — Content & Retention
- Mehrere Strecken & Distanzen, Bodenzustände
- Exacta/Quinella/Trifecta
- Level/XP, Daily Quests, Leaderboards
- Kamera-Modi, Kommentator, Photo-Finish
- Monetarisierung (Coin-Pakete, VIP)

### M3 — Tiefe (Live)
- Stallbesitz: eigene Pferde kaufen/trainieren/züchten
- Saisons & Turniere, Jackpot-Pool
- Soziales: Freunde-Tipps, Wett-Historie teilen

---

## 11. Offene Fragen / Risiken

- **Compliance laufend prüfen:** Roblox-Policy zu „simuliertem Glücksspiel" kann sich ändern
  — Coin-Ökonomie als geschlossenes System halten, keine Auszahlung.
- **Bandbreite:** Positions-Updates für viele Pferde × viele Spieler — Interpolation +
  Update-Rate tunen.
- **Balancing:** Stat-Verteilung & Takeout so wählen, dass Außenseiter-Siege spannend,
  aber Favoriten meist (nicht immer) gewinnen → fühlt sich „echt" an.
- **Leere Server:** NPC-Liquiditäts-Modell muss faire Odds liefern, ohne ausbeutbar zu sein.
- **Name/Branding:** „Royal Turf" ist Platzhalter — finalen Namen + Marken-Check klären.

---

## 12. Nächster Schritt

Vorschlag: Mit **M0-Prototyp** starten. Konkret als erstes Code-Paket:
1. `RaceController` State Machine (Phasen + Timer)
2. `RaceSimulator` (vereinfachte Stamina-Sim)
3. `BettingService` + `EconomyService` (Memory-Coins, Win-Wette)
4. Minimal-UI zum Wetten + simple Pferde-Visualisierung (Parts gleiten über Track)

→ Sag Bescheid, wenn ich mit M0 in Luau anfangen soll, dann erstelle ich dafür einen Plan.
