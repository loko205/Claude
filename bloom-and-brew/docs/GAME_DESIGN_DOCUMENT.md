# Bloom & Brew — Game Design Document

## Elevator Pitch

Du bist ein Alchemist-Gärtner: Züchte magische Pflanzen, verarbeite ihre Wirkstoffe mit verschiedenen Maschinen (Trocknen, Mörsern, Pressen, Destillieren, Äther-Extraktion), braue daraus Zaubertränke mit verrückten Effekten, und verkaufe sie über ein wachsendes Netzwerk aus NPCs UND echten Spielern.

## Core Loop

```
Samen → Pflanzen & Pflegen → Ernten
    → VERARBEITEN (richtige Methode wählen!)
    → Extrakte gewinnen
    → Tränke brauen (Reinheit 0-100%)
    → Verkaufen / Selbst nutzen
    → Coins, Rep, seltene Rezepte, neue Samen
```

## Inspirationen

| Spiel | Übernommenes Element |
|-------|---------------------|
| Grow a Garden | Plot-System, Pflanzen-Pflege, Wachstumsphasen |
| Schedule 1 | Reinheits-System, "Dealing"-Mechanik (als Fantasy-Alchemie) |
| Hay Day | NPC-Kundenaufträge, Liefersystem |

---

## 1. Garten-System

### Plots
- Start: 1 Plot (3x3 = 9 Felder), max 6 Plots
- 4 Typen: Standard, Gewächshaus (+50% Speed), Mutations-Plot (+50% Mutation), Premium (+30% Wert)
- 4 Böden: Normal, Nährboden (+20% Growth), Mystisch (+15% Mutation), Golden (+30% Wert)

### Pflanzen (20+)
- 6 Raritäten: Common (60%) → Uncommon (25%) → Rare (10%) → Epic (4%) → Legendary (0.9%) → Mythic (0.1%)
- 6 Wachstumsphasen: Samen → Sprössling → Wachstum → Blüte → Ernte → Überreif
- 5 Qualitätsstufen: ★ Mäßig (1x) → ★★★★★ Meisterwerk (3x)
- 8 Traits: Leuchtend, Gigantisch, Schnellwachsend, Selbstgießend, Potent, Goldig, Unsterblich, Duftend

### Pflege
- Gießen: +50% Wachstumsgeschwindigkeit (30s Cooldown)
- Düngen: +1 Qualitätsstufe (kostet Coins)
- Beschneiden: +Mutationschance

---

## 2. Verarbeitungssystem (NEU)

Geerntete Pflanzen müssen erst VERARBEITET werden, bevor sie als Trank-Zutaten dienen.

### 5 Methoden

| Methode | Maschine | Kosten | Ab Level | Dauer | Output |
|---------|----------|--------|----------|-------|--------|
| Trocknen | Trockengestell | 50 | 1 | 60s | Getrocknete Kräuter |
| Mörsern | Steinmörser | 200 | 3 | 45s | Pulver/Sporen |
| Pressen | Pflanzenpresse | 500 | 8 | 30s | Öl/Saft/Nektar |
| Destillieren | Destille | 1500 | 15 | 90s | Destillat/Äther. Öl |
| Äther-Extraktion | Äther-Extraktor | 5000 | 25 | 120s | Magische Essenz |

### Pflanze → Methode Zuordnung

Jede Pflanze hat eine **primäre Methode** (100% Ausbeute) und ggf. eine **alternative** (reduziert). Falsche Methode = Pflanze zerstört!

- Mondkraut → Trocknen (Blätter trocknen)
- Flammenblatt → Pressen (Feueröl im Blatt)
- Nebelranke → Destillieren (flüchtige Essenz)
- Sternmoos → Mörsern (Sporen freisetzen)
- Galaxienblume → Äther-Extraktion (Sternenlicht ist nicht physisch)

### Maschinen-Upgrades (3 Stufen)
- Einfach: Basis
- Verbessert: +15% Potenz, -20% Dauer (3x Kosten)
- Meister: +30% Potenz, -40% Dauer, +1 Extrakt (8x Kosten)

### Ergebnis: Extrakte
Aus einer Pflanze wird ein Extrakt mit **Potenz** (abhängig von Pflanzenqualität × Methodeneffizienz × Maschinenlevel).

---

## 3. Brau-System

### Labor
- Ab Level 3 (früh! Kern-Feature)
- 5 Kessel-Stufen: Holz → Kupfer → Silber → Gold → Obsidian
- Höherer Kessel = mehr Zutat-Slots, bessere Reinheit, schneller

### Tränke
14+ Rezepte in 4 Tiers:
- **Starter (Lv 3):** Sprungtrank, Glühtrank, Nebeltrank, Speedtrank
- **Fortgeschritten (Lv 8):** Unsichtbarkeitstrank, Flugessenz, Riesenwuchs, Magnetischer Trank
- **Selten (Lv 15):** Teleportations-Elixier, Zeittrank, Phönixträne, Chaostrank
- **Legendär (Lv 25):** Midas-Elixier, Allwissender Trank

### Reinheit (0-100%)
DAS Kern-Element (inspiriert von Schedule 1):
- Extrakt-Potenz (50%) + Kessel-Level (20%) + Minigame-Score (20%) + Potent-Trait (10%) ± 5% Zufall
- 6 Stufen: Verdünnt (0.3x) → Unrein (0.6x) → Standard (1x) → Rein (1.5x) → Kristallrein (2.5x) → Perfekt (5x, golden glowing!)

### Brau-Minigame (optional)
- Timing: Extrakte zum richtigen Zeitpunkt hinzufügen
- Temperatur: Slider in grüner Zone halten
- Rühren: Im Rhythmus rühren
- Perfektes Minigame = bis zu +20% Reinheit
- Auto-Brauen möglich (ohne Bonus)

---

## 4. NPC-Kunden

5 Typen mit eigener Persönlichkeit (Dialoge in Deutsch):

| Kunde | Ab Rep | Will | Timer |
|-------|--------|------|-------|
| Dorfbewohner | 0 | Common-Pflanzen/Starter-Tränke | 10min |
| Heiler | 100 | Spezifische Tränke, 50%+ Reinheit | 8min |
| Adeliger | 500 | Seltene Tränke, 70%+ Reinheit | 12min |
| Hexenmeister | 2000 | Epic+ Tränke, 85%+ Reinheit, mit Trait | 15min |
| Der Schatten | 10000 | Legendary-Trank, 95%+ Reinheit | 5min! |

---

## 5. Spieler-Interaktionen

### Direkthandel (Lv 5)
- Trade-Window, Anti-Scam (10s Countdown), Vertrauenssystem

### Schwarzes Brett (Lv 8)
- Marktplatz mit Angeboten, Geheime Angebote ab Rep 1000

### Trankstand (Lv 10)
- Eigener Stand vor dem Garten, Stammkunden-System, Dealer-Reputation

### Auktionshaus (Lv 15)
- Für Epic+ Items, 1h/6h/24h Auktionen, Sofortkauf

### Gilden (Lv 12)
- Gemeinsamer Garten, Gruppen-Brauen (+10% Reinheit), Gilden-Aufträge

### Trank-Duell (Lv 10)
- Fun-PvP: Wer hat den besseren Trank? Effekt-basierte Mini-Challenges

### Gartenbesuche (Lv 1)
- Gießhilfe (XP für beide), Gefällt mir, Gästebuch

---

## 6. Wirtschaft

### Währungen
- **Coins:** Hauptwährung (Verkauf, Aufträge, Handel)
- **Gems:** Premium (Daily, Achievements, Robux)
- **Essenz:** Nur durch Brauen (Kessel-Upgrades, Geheim-Rezepte)

### Dealer-Reputation (separates System!)
5 Ränge: Lehrling → Alchemist → Meisterbrauer → Legendärer Alchemist → Großmeister
Steigt durch Spieler-Verkäufe, hohe Reinheit, zufriedene Käufer.

### Monetarisierung (Fair, kein P2W)
6 Gamepasses (149-599 Robux): Quality-of-Life und Zeitersparnis.
Alle Inhalte erspielbar. Premium beschleunigt um 40-60%.

---

## 7. Technische Architektur

- **Strikte Server-Client-Trennung:** Alle Logik serverseitig
- **Anti-Exploit:** Server validiert jede Aktion, Rate-Limit (10 Req/s)
- **DataStore:** Komplettes Spieler-Profil mit Auto-Save (60s)
- **Rojo:** Externe Code-Synchronisation mit Roblox Studio
- **Ticks:** Pflanzen (1s), Brauen (5s), Verarbeitung (5s), Kunden (10s), Auktionen (30s)
