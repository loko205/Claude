# Plan: "Claudia wird 50" — Geburtstagsvideo Generator

## Kontext
Eigenständiges Python-Skript innerhalb des bestehenden Repos, das ein Geburtstagsvideo
automatisch aus Fotos, Texten und Musik zusammenbaut. Das bestehende Trading-Bot-Projekt
wird NICHT verändert.

## Was kann Code leisten vs. was braucht externe Tools?

### Code kann:
- Zeitstrahl-Animation (Countdown 2026→1976) mit moviepy/Pillow rendern
- Fotos mit Ken-Burns-Effekt (Zoom/Pan) animieren
- Text-Overlays ("Ein kleines Mädchen mit grossen Träumen" etc.) einblenden
- Phasen zeitlich steuern (0:00-0:45 Rücklauf, 0:45-2:45 Vorwärts, 2:45-3:30 Finale)
- Versteckte Hinweise (Anker-Symbol, Texteinblender) als Overlays einbauen
- Audio-Track unterlegen und synchronisieren
- Finale Karten-Animation (Punkt wandert nach Hamburg) rendern
- Alles zu einem MP4 zusammenfügen

### Externe Tools nötig (NICHT automatisierbar):
- **Musik**: Suno AI — manuell generieren, als MP3 bereitstellen
- **Fotos**: Vom User bereitgestellt in einem Ordner
- **Optional**: Voiceover (ElevenLabs), spezielle Grafiken (Midjourney)

## Geplante Dateistruktur

```
video/                          # Neuer Ordner, komplett getrennt vom Trading Bot
├── generate_video.py           # Hauptskript (~300-400 Zeilen)
├── config.py                   # Video-Konfiguration (Timings, Texte, Pfade)
├── effects.py                  # Ken-Burns, Fade, Zoom-Effekte (~150 Zeilen)
├── timeline.py                 # Zeitstrahl-Animation (Countdown + Vorwärts) (~200 Zeilen)
├── overlays.py                 # Text-Overlays, versteckte Hinweise (~100 Zeilen)
├── map_animation.py            # Hamburg-Karten-Animation fürs Finale (~100 Zeilen)
├── requirements.txt            # moviepy, Pillow, numpy
├── assets/
│   ├── music/                  # Musik-Dateien (manuell von Suno)
│   │   └── .gitkeep
│   ├── photos/                 # Fotos nach Zeitraum sortiert
│   │   ├── 1976-1986/
│   │   ├── 1986-1996/
│   │   ├── 1996-2006/
│   │   ├── 2006-2016/
│   │   └── 2016-2026/
│   ├── overlays/               # Anker-Symbol, Reeperbahn-Schild etc.
│   │   └── .gitkeep
│   └── fonts/                  # Schriftarten
│       └── .gitkeep
├── output/                     # Generierte Videos
│   └── .gitkeep
└── tests/
    └── test_effects.py         # Tests für Effekt-Funktionen
```

## Abhängigkeiten (neu, NUR für video/)
- `moviepy` >= 2.0 — Video-Rendering, Compositing, Audio
- `Pillow` >= 10.0 — Bildbearbeitung, Text-Rendering
- `numpy` — Array-Ops für Effekte (kommt mit moviepy)

Installation: `uv add moviepy Pillow` (oder separates venv für video/)

## Schritt-für-Schritt-Plan

### Schritt 1: Projektstruktur anlegen
- `video/` Ordner mit allen Unterordnern erstellen
- `video/requirements.txt` schreiben
- **Dateien**: 1 neue Datei, ~10 Ordner
- **Risiko**: Gering — keine bestehenden Dateien betroffen

### Schritt 2: `video/config.py` — Konfiguration
- Alle Texte, Timings, Farben, Schriftgrößen als Konstanten
- Phasen-Definition (Start/Ende in Sekunden)
- Pfade zu Assets
- Versteckte Hinweise pro Phase
- **~60 Zeilen**

### Schritt 3: `video/effects.py` — Bild-Effekte
- `ken_burns_effect(image, duration, zoom_start, zoom_end)` — Zoom/Pan Animation
- `fade_in(clip, duration)` / `fade_out(clip, duration)`
- `slide_transition(clip_a, clip_b, duration)`
- `flash_image(image, flash_duration=0.3)` — für sublimale Foto-Einblendungen
- **~150 Zeilen**

### Schritt 4: `video/timeline.py` — Zeitstrahl-Animation
- `render_countdown(start_year=2026, end_year=1976, duration=45)` — Phase 1
  - Weisse Zahlen auf schwarz, beschleunigend
  - Flash-Fotos bei bestimmten Jahren einblenden
  - Endet mit "27. November 1976 — Hier beginnt deine Geschichte"
- `render_forward_timeline(phases, photos)` — Phase 2
  - Pro Phase: Jahreszahl-Titel → Foto-Slideshow → Text-Overlay
  - Versteckte Hinweise als Semi-transparente Overlays
- **~200 Zeilen**

### Schritt 5: `video/overlays.py` — Text & Hinweise
- `render_text(text, font_size, color, position, duration)`
- `render_hidden_hint(hint_type, position, opacity=0.3)`
  - Anker-Symbol (Pillow-gezeichnet oder Asset)
  - "Reeperbahn" Strassenschild
  - "Dein nächstes Abenteuer wartet im Norden…" klein unten
  - H-A-M-B-U-R-G Buchstaben
- `render_golden_50()` — Grosser goldener "50!" Text
- **~100 Zeilen**

### Schritt 6: `video/map_animation.py` — Karten-Finale
- Einfache 2D-Karte von Deutschland (Pillow-gezeichnet)
- Animierter Punkt wandert vom Wohnort nach Hamburg
- Text: "Pack deine Koffer — wir fahren nach Hamburg!"
- **~100 Zeilen**

### Schritt 7: `video/generate_video.py` — Hauptskript
- Liest Config
- Scannt Foto-Ordner
- Ruft Phase 1 (Countdown), Phase 2 (Vorwärts), Phase 3 (Finale) auf
- Fügt Audio hinzu
- Rendert finales MP4
- CLI: `python video/generate_video.py [--preview] [--phase 1|2|3]`
  - `--preview` für schnelle Vorschau (niedrige Auflösung)
  - `--phase` zum Testen einzelner Phasen
- **~300-400 Zeilen**

### Schritt 8: Tests
- `test_effects.py` — Ken-Burns produziert korrektes Format, Fade funktioniert
- Einfache Smoke-Tests mit Dummy-Bildern
- **~50 Zeilen**

### Schritt 9: .gitignore erweitern
- `video/output/` — generierte Videos nicht committen
- `video/assets/photos/` — persönliche Fotos nicht committen
- `video/assets/music/` — Musik-Dateien nicht committen

## Umfang
- **Neue Dateien**: 7 Python-Dateien + 1 requirements.txt + 1 test
- **Geschätzte Zeilen**: ~1000-1100 Zeilen Code
- **Bestehende Änderungen**: nur `.gitignore` (2-3 Zeilen)
- **Keine Änderung** am Trading Bot Code

## Risiken & Edge Cases

| Risiko | Mitigation |
|--------|-----------|
| moviepy Rendering langsam | `--preview` Flag für niedrige Auflösung |
| Fotos haben verschiedene Formate/Größen | Auto-Resize + Crop auf 1920x1080 |
| Keine Fotos in einem Zeitraum | Graceful Skip mit Warnung, Fallback-Bild |
| Musik kürzer/länger als Video | Auto-Loop oder Fade-Out am Ende |
| Schriftarten nicht vorhanden | Fallback auf system-default Font |
| moviepy v2 API-Änderungen | Explizite Version pinnen in requirements |
| Große Foto-Dateien → RAM-Probleme | Fotos on-the-fly laden und freigeben |

## Offene Fragen an dich
1. **Wohnort** für die Karten-Animation — von wo soll der Punkt nach Hamburg wandern?
2. **Video-Auflösung** — 1080p (1920x1080) oder 4K?
3. **Soll das video/ Verzeichnis ein eigenes venv bekommen** oder die Dependencies zum bestehenden pyproject.toml?
4. **Hast du schon Fotos sortiert** oder soll das Skript auch unsortierte Fotos verarbeiten können?
