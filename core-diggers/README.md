# Core Diggers ⛏️

Zweites Spiel im Repo (eigenständig, neben `roblox-game/`): ein **Koop-Digging-Game**
im aktuell trendenden Mining-Genre (Prospecting!, Dig It!) — mit eigener Formel:
Ein ganzer Server gräbt **gemeinsam eine schwebende Himmelsinsel** aus, Schicht für
Schicht, bis zum glühenden **KERN**.

## Gameplay-Loop

1. **Graben:** Blöcke anklicken (ClickDetector, mobile-tauglich). 7 Schichten von
   Topsoil bis Void-Basalt — tiefer = härter (HP) und wertvoller.
2. **Looten:** Jeder Block droppt Material + Chance auf Erze (14 Sorten, bis Void Pearl
   $30K). 2 % **Shiny**-Varianten (5x Wert). Rucksack hat Kapazität.
3. **Verkaufen** am Stand im Camp → **bessere Schaufel** (8 Stufen bis OMEGA DRILL)
   und **größerer Rucksack** (6 Stufen) → tiefer graben.
4. **Relikte** (10 Stück, schichtgebunden + 3 Mythics): ins **Museum spenden**
   (Pedestal mit deinem Namen, serverweit sichtbar, permanent +3 % Verkaufswert) —
   oder für Sofort-Cash verkaufen. Echte Entscheidung.
5. **DER KERN** (Layer 36): knacken = **Prestige** (+50 % Verkaufswert für immer,
   serverweite Ansage), Kern respawnt für die Nächsten.
6. **Block-Specials** (beim Spawnen gerollt): sichtbare **Erz-Adern** (~7 %, getönt,
   garantiert 2–4 Erze), goldene **Schatzblöcke** (Cash-Burst) und **Lava-Blöcke**
   in Magma/Void (35 Schaden bei Berührung — Tiefe ist Gefahr).
7. **Meteor-Events** alle 12 Min: glühender Erz-Cluster schlägt auf der Oberfläche ein.
8. **3 Daily Contracts** (QUESTS-Button): „Brich 150 Blöcke", „Sammle 5 Gold",
   „Erreiche Layer 22" … — Auto-Belohnung bei Abschluss, täglich neu.
9. Schicht-Meilensteine („You reached Ice Crust!"), Daily-Streak-Bonus, globales
   **„Deepest Diggers"-Leaderboard** (OrderedDataStore).

## Warum dieses Genre hält (Retention-Logik)

- **„Eine Schicht noch"**: Tiefe ist sichtbarer Fortschritt — der Minecraft-Sog.
- **Klare Upgrade-Treppe**: Jede Schaufel/jeder Rucksack ist in Reichweite und
  verändert das Spielgefühl sofort.
- **Koop statt PvP**: Server graben gemeinsam Tunnel — sozial, ohne Frust
  (bewusst das Gegenteil von Steal a Schnitzel).
- **Sammeln + Status**: Museum mit Namensschildern, Shinys, Mythic-Relikte mit
  Server-Announcement, Tiefen-Leaderboard.

## Setup (Rojo + Roblox Studio)

1. In diesem Ordner: `rojo serve`, in Studio verbinden (Baseplate + SpawnLocation
   vorher löschen — Welt kommt komplett aus Code), Play.
2. DataStores im Studio: Game Settings → Security → Enable Studio Access to API Services.
3. Publish: Server-Größe 10–12, Genre „Simulator/Mining".

## Monetarisierung (IDs nach dem Publishen in `World.Monetization` eintragen)

- Gamepasses: **2x Cash**, **VIP** (+10 % Luck, +50 Rucksack), **Portable Seller**
  (überall verkaufen — der stärkste QoL-Pass im Genre)
- Dev-Products: 3 Cash-Pakete. Alles über `ProcessReceipt` serverseitig.

## Previews (aus den echten Spieldaten gerendert)

- [docs/island.png](docs/island.png) — Insel-Querschnitt mit allen Schichten + Camp
- [docs/relics.png](docs/relics.png) — Museums-Relikte & Schaufel-Stufen

Neu rendern: `luau tools/export_world.luau > /tmp/cd_world.json`, dann
`cd tools && uv run --no-project --with pillow python render_overview.py /tmp/cd_world.json ../docs/island.png`
(analog `render_relics.py`).

## Struktur

```
src/shared/   World (alle Daten: Schichten, Erze, Relikte, Schaufeln, Tuning),
              CampBlueprint, RelicDesigns
src/server/   Terrain (Voxel-Insel, Mining, Kern, Meteore), Camp, Inventory,
              Tools, Museum, Shop-Handling in init, Economy, Data, Monetize, Leaderboard
src/client/   HUD (Cash/Bag/Depth/Prestige), Shop- & Museums-UI, Buttons, SFX
tools/        Export (Luau CLI) + Iso-Renderer für die Previews
```
