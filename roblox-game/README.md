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

## Veröffentlichen

1. File → Publish to Roblox, Server-Größe **8** (= Anzahl der Plots).
2. Genre „Simulator" wählen, ein knalliges Icon/Thumbnail mit einem der Charaktere.
3. Nach dem ersten Update: Badges + tägliche Login-Belohnung ergänzen (siehe Roadmap
   in GAME_DESIGN.md).

## Struktur

```
src/shared/   Config (Tuning) + Characters (Definitionen, Rarities, Weighted Pick)
src/server/   Map, Plots, Conveyor, Steal, Economy, Data, Factory + Bootstrap
src/client/   HUD (Cash, Income, Rebirth-Button, Steal-Banner, Notifications)
```
