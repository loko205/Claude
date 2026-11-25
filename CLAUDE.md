# Faceless Files – animated story shorts (handoff from a claude.ai chat)

Owner: Thomas, YouTube channel "Faceless Files" (@facelessfilestv). Talk to him in **German**, short and direct, honest
about weaknesses. He wants you to make working decisions yourself instead of asking at every step.
Requirement: **everything free** (no Higgsfield, no paid APIs). Videos are in **English** (international audience).

## Goal
Vertical 55–70 s animated story shorts in the style of the channel **Ricks Clips (@RicksClips3000)**, built with the
free skill https://github.com/mromidev/claude-animated-shorts (Remotion + three.js, 2D ink characters in 3D sets).
Installed in `.claude/skills/animated-shorts` – read its SKILL.md and references/STYLE_BIBLE.md before building.
The skill says "no captions" – Thomas's rule overrides that: we DO want 1–2-word captions.

## What Ricks Clips does (researched; titles + views as of 8 Nov 2026)
Top: The Ancient Jar That Warned an Empire (33M) · Why Perfect Railroads Don't Work (27M) · The Job Nobody Wants in
Japan (17M) · Why Sailors Carried Storm Oil (15M) · What the Grave Bell Really Meant (12M) · Levels of Pirate
Cannonballs · Why the Second Draw Always Wins · The Burglar Who Only Moved Furniture · Why Cashiers Keep Winning The
Lottery · The Pink Prison Cell Experiment · He Could Spot Winning Tickets Just by Looking · How a Mirror Rigged a Horse
Race · This Shape Saved Roller Coasters · The Town Built Around a Button.
=> Little-known curiosities: clever old inventions/customs explained, money loopholes/tricks. NOT famous events.
**Full measured analysis of 13 top shorts (transcripts, mocker lines, captions, pacing): research/ANALYSIS.md.
Read it before scripting.**

Story formula (~220 words, told like a kid explaining to a friend, no dates/titles, max one name):
1. Hook 0–3 s: 9–14 words, something strange someone did, reason hidden.
2. Setup: who, where, one exact number, stakes.
3. A **mocker** laughs at the hero (one sarcastic line). Hero stays calm, doesn't explain.
4. Escalation x3, mocker gets cockier.
5. "You see," – the trick explained once, via something the viewer has done.
6. Payoff lands on the mocker; final line = biggest reveal, no moral.
Visuals: low wide gliding camera, few hard cuts, purple-blue shadows (never black).
**Captions: 1–2 words at a time, bold white, dark outline – we have NOT built these yet, add them.**

## What was made so far (both underperformed)
- BA 5390 (pilot sucked out of the cockpit, 1990) and Alcatraz escape (1962). Lesson: famous events, dates, several
  names, no mocker, no captions = wrong format.
- Next topic ideas that fit: cobra effect (bounty on dead cobras -> people breed cobras), retired couple who beat a
  lottery with math, how engineers stopped the Leaning Tower of Pisa by removing soil.

## Pipeline notes (learned the hard way)
- Voice: Kokoro TTS (free, local): `pip install kokoro-onnx soundfile`, model files from
  github.com/thewh1teagle/kokoro-onnx releases (kokoro-v1.0.onnx, voices-v1.0.bin). Thomas chose voice **am_puck**,
  speed ~1.15–1.17, minimal pauses (~3.6 words/s). See voice/*.py.
- Audio: synthesized SFX + music + mix in audio/*.py (numpy/scipy). Target about -14 LUFS, music ~9 dB under voice.
- Remotion project in remotion/. Compositions in src/Root.tsx; shorts in src/videos/<name>/ (story.ts = shots/cameras/
  beats, world.ts = sets/characters, chars.ts = prop drawings, Short.tsx = render + post).
- In the previous (GPU-less) environment `@react-three/postprocessing`'s EffectComposer rendered blank; Short.tsx uses
  a plain `postprocessing` EffectComposer driven from useFrame instead. Lens blur is expensive: keep it to close-ups.
- toon.ts (bridge kit) was extended with prop `["custom", k, (p, hx, hy, u) => void]` so tools are drawn INTO the
  character's hand (incl. sit mode). Use this for anything a character holds – never float props next to them.
- Bugs Thomas spotted: camera placed inside a wall (ink draws a black line), characters clipping into furniture
  (mattress), heads cut off at frame edge, props not in hands, unreadable props (sink/vent). QA every shot at full
  size, frame by frame – not tiny contact sheets.

## Useful here (local machine has internet)
- Watch/analyze YouTube videos: install the `/watch` skill (github.com/bradautomates/claude-video) or
  mcp-video-analyzer. Use it to study Ricks Clips shorts (pacing, captions, mocker lines) before scripting.

## Running from the phone (Claude Code cloud sessions)
- This repo is used from the Code tab of the Claude app. The cloud VM (Ubuntu, 4 vCPU, 16 GB RAM, no GPU) clones the
  repo fresh each session: run `bash setup.sh` (npm install, Kokoro deps + model, model symlinks) before rendering.
  Remotion can't download its Chrome here (remotion.media blocked); remotion.config.ts + scripts use the preinstalled
  Playwright headless shell automatically. Keep renders in background chunks (commands time out after ~10 min foreground).
- Environment network access must be **Full** (or Custom incl. github.com release assets, YouTube, Google APIs).
- Push finished MP4s/stills to a `renders/` branch or send them so Thomas can open them on the phone.
- Video analysis: the `watch` skill is committed in `.claude/skills/watch` (from bradautomates/claude-video, MIT).
  Use engine **gemini** with a free key from aistudio.google.com/apikey (YouTube download from cloud IPs often fails).
  Never commit the key; it lives in ~/.config/watch/.env or as an environment variable GEMINI_API_KEY.
