# Asset Pipeline — Bloom & Brew

## Kontext

Die Pflanzen-Icons und 3D-Texturen für Bloom & Brew sollen professionell aussehen,
vergleichbar mit dem Stil von "Grow a Garden" auf Roblox. Reine SVG-Vektorgrafiken
haben sich als unzureichend erwiesen — zu flach, zu amateurhaft.

## Ziel

Professionelle Game-Assets (Icons, 3D-Modelle, Texturen) erstellen, die direkt
in Roblox Studio verwendbar sind. Der Stil sollte sich an erfolgreichen Roblox-Spielen
wie "Grow a Garden" orientieren: 3D-Optik, Cartoon-Shading, Tiefe, Beleuchtung.

## Mögliche Ansätze

### Blender Headless Pipeline
Blender kann ohne GUI über die Kommandozeile gesteuert werden (`blender -b -P script.py`).
Damit lassen sich 3D-Modelle prozedural per Python generieren, texturieren und rendern.

- **Vorteile:** Volle Kontrolle, konsistenter Stil, automatisierbar
- **Nachteile:** Komplex, Blender muss installiert sein, Lernkurve
- **Export-Formate:** OBJ, FBX → kompatibel mit Roblox

### Roblox Open Cloud API
Über die Open Cloud API können Assets (Bilder, Modelle, Audio) programmatisch
zu Roblox hochgeladen werden. Benötigt einen API-Key aus dem Creator Dashboard.

- Python-Library: `rblx-open-cloud` (`pip install rblx-open-cloud~=2.0`)
- Alternative: `assetup` (Node.js CLI für Bulk-Uploads)

### Tarmac (Rojo-Ökosystem)
CLI-Tool das lokale Assets erkennt, zu Roblox hochlädt und Asset-IDs zurückgibt.
Konfiguration über `tarmac.toml`. Gut integriert mit Rojo-Projekten.

### Prozedurale Generierung in Roblox selbst
Es gibt Lua-basierte Ansätze für prozedurale Vegetation direkt in Roblox
(z.B. Branch-Segment-basierte Baumgenerierung). Könnte für bestimmte
Pflanzentypen sinnvoll sein.

## Bekannte Einschränkungen

- Rojo kann keine MeshParts mit Custom-Mesh-Content erstellen (offiziell "wontfix")
- OBJ→.mesh Konvertierung muss über Roblox's Upload-Prozess laufen
- EditableMesh ist auf Runtime-Kosmetik beschränkt
- Das Roblox Blender-Plugin braucht GUI-Interaktion — für Automation stattdessen CLI-Export + Tarmac/API nutzen

## Voraussetzungen

- Blender (für 3D-Generierung)
- Roblox Open Cloud API-Key (für Asset-Upload)
- Rojo + Tarmac (optional, für Projekt-Sync)

## Referenzen

- [Roblox Open Cloud API](https://create.roblox.com/docs/cloud)
- [Tarmac CLI](https://github.com/rojo-rbx/tarmac)
- [Rojo](https://rojo.space/docs/v7/)
- [rblx-open-cloud Python](https://github.com/treeben77/rblx-open-cloud)
- [Roblox Blender Plugin](https://github.com/Roblox/roblox-blender-plugin)
- [Roblox File Format Library (C#)](https://github.com/MaximumADHD/Roblox-File-Format)

## Hinweis

Dieses Dokument beschreibt recherchierte Möglichkeiten, keinen festen Plan.
Die tatsächliche Umsetzung sollte situativ entschieden werden — je nachdem was
auf dem Zielsystem verfügbar ist, was funktioniert und was die besten Ergebnisse
liefert. Qualität geht vor Prozess.
