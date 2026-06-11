# Steal a Schnitzel 🥩

Ein virales Roblox-Game im „Steal a X"-Genre — komplett prozedural in Luau gebaut,
keine 3D-Assets nötig. Siehe [GAME_DESIGN.md](GAME_DESIGN.md) für die Genre-Recherche
und die Design-Entscheidungen.

## Gameplay-Loop

1. Charaktere (absurde Food-Tier-Hybride, 7 Rarity-Stufen bis **Secret**) spawnen auf
   einem Förderband in der Map-Mitte.
2. Kaufen per ProximityPrompt → Charakter steht in deiner Base und generiert Cash/Sekunde.
3. **Stehlen:** Charaktere aus fremden Bases klauen und nach Hause tragen (verlangsamt,
   bei Tod fällt die Beute zurück an den Besitzer).
4. **Base-Lock:** Schutzschild für 60 s (3 min Cooldown).
5. **Rebirth:** Reset gegen permanente +50 % Income pro Rebirth.
6. **Offline-Earnings:** 50 % des Income-Rates für bis zu 6 h Abwesenheit.

## Setup (Rojo + Roblox Studio)

1. [Rojo](https://rojo.space) installieren (CLI oder VS-Code-Extension) und das
   Rojo-Plugin in Roblox Studio.
2. In diesem Ordner: `rojo serve`
3. Neues Baseplate-Projekt in Studio öffnen, **vorhandenes Baseplate + SpawnLocation
   löschen** (die Map wird komplett vom Code gebaut), dann über das Rojo-Plugin verbinden.
4. Play drücken — fertig. Für DataStores im Studio-Test:
   Game Settings → Security → **Enable Studio Access to API Services**.

Alternativ einmalig bauen: `rojo build -o StealASchnitzel.rbxlx` und die Datei in Studio öffnen.

## Retention- & Social-Systeme

- **Mutationen:** Golden (5 %, 3x), Diamond (1 %, 8x), Rainbow (0,2 %, 25x, animierter
  Farbwechsel) — rollen unabhängig von der Rarity und machen fremde Basen zu Zielen.
- **Gold Rush:** Alle 18 Min serverweit 3x Luck für 2 Min (gemeinsamer Hype-Moment).
- **Schnitzel-Dex:** Sammel-Index (DEX-Button) mit Cash-Belohnung pro Erstfund.
- **Daily Streak:** Login-Bonus, skaliert bis Tag 7. **Startgeschenk** für neue Spieler.
- **Globales Leaderboard:** Reichste Spieler auf der Tafel an der Plaza (OrderedDataStore).
- **Multiplayer:** Alles ist server-authoritativ und automatisch für alle sichtbar —
  Basen, Pets, Diebe mit Beute überm Kopf, Schilde, Events.

## Monetarisierung einrichten (nach dem Publishen)

1. Creator Dashboard → dein Experience → **Monetization**:
   - 2 Gamepasses anlegen: „2x Cash" und „VIP" (Vorschlag: 199/149 Robux)
   - 3 Developer Products: Cash-Pakete klein/mittel/groß (49/199/899 Robux)
2. Die IDs in `src/shared/Config.luau` unter `Monetization` eintragen (statt 0).
3. Fertig — Server prüft Gamepasses bei der Income-Berechnung, `ProcessReceipt`
   schreibt Cash-Käufe gut, der Shop-Button blendet konfigurierte Artikel ein.

## Veröffentlichen

1. File → Publish to Roblox, Server-Größe **8** (= Anzahl der Plots).
2. Genre „Simulator" wählen, ein knalliges Icon/Thumbnail mit einem der Charaktere.
3. Nach dem ersten Update: Badges + tägliche Login-Belohnung ergänzen (siehe Roadmap
   in GAME_DESIGN.md).

## Designs & Map (daten-basiert + renderbar)

Charaktere wie Map sind reine Daten-Baupläne, die zur Laufzeit prozedural gebaut
werden — keine 3D-Assets nötig. Dieselben Daten lassen sich offline isometrisch
rendern, sodass jede Design-Änderung visuell verifizierbar ist:

- `src/shared/Designs.luau` → alle 21 Charaktere (einheitlicher Voxel-Stil, jede
  Figur mit eigener Silhouette und Signature-Features): [docs/characters.png](docs/characters.png)
- `src/shared/MapBlueprint.luau` → komplette Map (Förderband mit Portal-Bögen,
  8 Plots mit Pads/Schild/Lock-Podest/Eckpfeiler-Lampen, Steinwege, Spawn-Plaza,
  goldene Schnitzel-Statue, Bäume): [docs/map.png](docs/map.png)

Previews neu rendern (nach Änderungen):

```sh
luau tools/export_designs.luau > /tmp/designs.json
uv run --no-project --with pillow python tools/render_preview.py /tmp/designs.json docs/characters.png
luau tools/export_map.luau > /tmp/map.json
(cd tools && uv run --no-project --with pillow python render_map.py /tmp/map.json ../docs/map.png)
```

## Struktur

```
src/shared/   Config (Tuning), Characters (Rarities, Weighted Pick), Designs, MapBlueprint
src/server/   Map (instanziiert Blueprint + Lighting/Bloom), Plots, Conveyor, Steal,
              Economy, Data, Factory + Bootstrap
src/client/   HUD (Stats-Panel, Rebirth-Button, Steal-Banner, Notifications + SFX)
tools/        Export-Scripts (Luau CLI) + isometrische Preview-Renderer
```
