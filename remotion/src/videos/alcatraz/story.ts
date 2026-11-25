// Alcatraz short: shots, cameras, beats. 30 fps, timed to /home/claude/alcatraz/voice/words.json.
export const FPS = 30;
export const TOTAL = 1880;
export type V3 = [number, number, number];
export type SetName = "block" | "bay" | "desk";
export type Light = "dawn" | "night" | "lamp" | "day" | "desk";

export const clamp01 = (x: number) => Math.max(0, Math.min(1, x));
export const smooth = (x: number) => { const u = clamp01(x); return u * u * (3 - 2 * u); };
/** ease-out (the reference's camera bursts: fastest at the start, settling over the move) */
export const eout = (x: number) => { const u = clamp01(x); return 1 - (1 - u) ** 3; };
export const ease = (x: number) => { const u = clamp01(x); return u < 0.5 ? 4 * u * u * u : 1 - (-2 * u + 2) ** 3 / 2; };

export type ShotDef = { id: number; a: number; b: number; set: SetName; light: Light };
export const SHOTS: ShotDef[] = [
  { id: 1, a: 0, b: 136, set: "block", light: "dawn" },     // hook: guard pokes the head, it falls and smashes
  { id: 2, a: 136, b: 255, set: "block", light: "night" },  // Alcatraz, escape-proof (cellblock)
  { id: 3, a: 255, b: 342, set: "bay", light: "night" },    // freezing water, guards on every tower
  { id: 4, a: 342, b: 932, set: "block", light: "night" },  // Frank's plan, spoons, scraping, drill, accordion, wait...
  { id: 5, a: 932, b: 1216, set: "block", light: "lamp" },  // you see: the fake heads; asleep in the dark
  { id: 6, a: 1216, b: 1341, set: "block", light: "night" },// raincoat raft on top of the cellblock
  { id: 7, a: 1341, b: 1462, set: "block", light: "night" },// June 11, 10 PM: through the holes, up the pipes
  { id: 8, a: 1462, b: 1536, set: "bay", light: "night" },  // down to the water, paddle into the dark
  { id: 9, a: 1536, b: 1594, set: "block", light: "dawn" }, // next morning, the guard pokes the head
  { id: 10, a: 1594, b: 1690, set: "bay", light: "day" },   // the FBI searches for seventeen years
  { id: 11, a: 1690, b: TOTAL, set: "desk", light: "desk" },// 2013 letter; the case? still open
];
export const XFADE = 8;
export const shotAt = (f: number) => SHOTS.find((s) => f >= s.a && f < s.b) ?? SHOTS[SHOTS.length - 1];
export const layersAt = (f: number): { id: number; alpha: number }[] => {
  for (const s of SHOTS) {
    if (s.id > 1 && f >= s.a - XFADE / 2 && f < s.a + XFADE / 2) return [{ id: s.id - 1, alpha: 1 }, { id: s.id, alpha: (f - (s.a - XFADE / 2) + 1) / (XFADE + 1) }];
  }
  return [{ id: shotAt(f).id, alpha: 1 }];
};

// beats (frames)
export const B = {
  poke: 40, fall: 80, smash: 101,
  spoon: 405, scrape: 449, others: 515, hundred: 600,
  drill: 676, loud: 742, accordion: 775, wait: 861, bedEmpty: 895,
  soap: 985, paste: 995, roll: 1015, blob: 1028, paint: 1045, hair: 1096, dark: 1150,
  raft0: 1240, pump: 1282,
  squeeze: 1388, climb: 1420, launch: 1470, paddle: 1498,
  poke2: 1560, fall2: 1572, smash2: 1588,
  letter: 1705, unfold: 1736, open: 1850,
};

// ---------------- cameras ----------------
export type Cam = { pos: V3; look: V3; fov: number; roll: number };
type Key = { f: number; dur?: number; cut?: boolean; e?: "out" | "io"; c: Cam };
const C = (pos: V3, look: V3, fov = 40, roll = 0): Cam => ({ pos, look, fov, roll });
const L3 = (a: V3, b: V3, k: number): V3 => [a[0] + (b[0] - a[0]) * k, a[1] + (b[1] - a[1]) * k, a[2] + (b[2] - a[2]) * k];
const mixCam = (a: Cam, b: Cam, k: number): Cam => ({ pos: L3(a.pos, b.pos, k), look: L3(a.look, b.look, k), fov: a.fov + (b.fov - a.fov) * k, roll: a.roll + (b.roll - a.roll) * k });
const run = (keys: Key[], f: number): Cam => {
  let cur = keys[0].c;
  for (let i = 1; i < keys.length; i++) {
    const k = keys[i];
    if (f < k.f) break;
    if (k.cut) { cur = k.c; continue; }
    const u = (f - k.f) / (k.dur ?? 24);
    cur = mixCam(cur, k.c, k.e === "io" ? ease(u) : eout(u));
  }
  return cur;
};

// Frank's cell: x in [-0.8, 0.8], front bars z = -1.6, back wall z = -4.3; bed along x = -0.45; vent at (0.35, 0.25, -4.3)
// utility corridor behind: z in [-4.6, -5.8]; top of the cellblock (raft deck) y = 8.2
export const CAMS: Record<number, Key[]> = {
  1: [
    { f: 0, c: C([0.15, 1.6, -1.7], [0.05, 0.95, -3.5], 64) },
    { f: 30, dur: 60, e: "io", c: C([0.12, 1.55, -1.75], [0.0, 0.9, -3.5], 60) },
    { f: 82, dur: 12, c: C([0.1, 1.45, -1.7], [-0.05, 0.7, -3.5], 62, 0.06) },
  ],
  2: [
    { f: 136, c: C([0.3, 1.5, -1.0], [0.0, 1.0, -3.0], 44) },
    { f: 140, dur: 90, e: "io", c: C([-5.5, 2.4, 0.7], [4.0, 1.3, -0.8], 50) },
  ],
  3: [
    { f: 255, c: C([-95, 4, 75], [0, 16, 0], 34) },
    { f: 258, dur: 84, e: "io", c: C([-82, 5, 64], [0, 15, 0], 34) },
  ],
  4: [
    { f: 342, c: C([0.55, 1.5, -1.75], [0.05, 1.25, -3.1], 44) },
    { f: 400, dur: 14, c: C([0.5, 1.55, -1.72], [0.1, 1.22, -3.1], 50) },                   // push on "Spoons"
    { f: 449, dur: 16, c: C([0.55, 1.05, -2.2], [0.15, 0.45, -3.95], 56) },                  // down to the vent
    { f: 515, dur: 30, c: C([0.0, 2.4, 1.6], [0.0, 0.55, -3.4], 64) },                    // three cells in a row
    { f: 600, dur: 24, c: C([0.55, 1.05, -2.2], [0.15, 0.45, -3.95], 56) },
    { f: 734, dur: 9, c: C([1.5, 1.5, 1.2], [6.0, 1.4, 0.2], 44, -0.04) },                  // whip to the guard
    { f: 760, dur: 18, c: C([0.65, 1.45, 0.4], [0.1, 1.25, -2.1], 42) },                    // accordion through the bars
    { f: 861, dur: 12, c: C([0.55, 1.5, 1.0], [-0.6, 0.95, -2.6], 58, 0.1) },               // wait: dutch
  ],
  5: [
    { f: 932, c: C([0.55, 1.4, -1.7], [0.05, 0.95, -3.15], 62) },
    { f: 1000, dur: 40, e: "io", c: C([0.5, 1.35, -1.8], [0.05, 0.95, -3.15], 58) },
    { f: 1146, dur: 18, c: C([0.9, 1.5, 0.7], [-0.3, 0.8, -3.2], 50) },
  ],
  6: [
    { f: 1216, c: C([3.4, 10.1, -0.1], [0.4, 8.6, -2.6], 56) },
    { f: 1220, dur: 120, e: "io", c: C([3.0, 9.9, -0.4], [0.4, 8.6, -2.6], 54) },
  ],
  7: [
    { f: 1341, c: C([0.6, 1.1, -1.85], [0.1, 0.55, -4.1], 50) },
    { f: 1380, dur: 16, c: C([3.3, 1.3, -5.35], [0.6, 0.85, -5.0], 56) },
    { f: 1418, dur: 40, e: "io", c: C([3.3, 2.4, -5.35], [0.8, 5.2, -5.1], 58, -0.04) },
  ],
  8: [
    { f: 1462, c: C([32, 1.5, 3], [36.5, 0.9, -3.2], 44) },
    { f: 1490, dur: 46, e: "io", c: C([34, 1.4, 2], [46, 0.7, -8], 40) },
  ],
  9: [
    { f: 1536, c: C([0.12, 1.55, -1.75], [0.0, 0.9, -3.5], 60) },
    { f: 1572, dur: 12, c: C([0.1, 1.45, -1.7], [-0.05, 0.7, -3.5], 62, 0.06) },
  ],
  10: [
    { f: 1594, c: C([-40, 26, 90], [6, 2, 20], 44) },
    { f: 1597, dur: 93, e: "io", c: C([-30, 22, 80], [8, 2, 20], 42) },
  ],
  11: [
    { f: 1690, c: C([0.1, 1.6, 1.3], [-0.1, 1.2, -0.5], 54) },
    { f: 1720, dur: 40, e: "io", c: C([0.0, 1.3, 0.45], [-0.08, 0.76, -0.05], 40) },
    { f: 1822, dur: 18, c: C([0.42, 1.35, 0.6], [0.3, 0.77, -0.08], 44) },
  ],
};

const KICKS: [number, number][] = [[B.smash, 1.4], [B.smash2, 1.4], [B.drill + 4, 0.4], [B.open, 0.5]];
export const kickAt = (f: number) => {
  let a = 0;
  for (const [f0, g] of KICKS) { const n = f - f0; if (n >= 0 && n < 7) a += g * (n % 2 ? -1 : 1) * (1 - n / 7) ** 1.5; }
  return a;
};
const shake = (f: number) => (f >= B.drill && f < 732 ? 0.5 * Math.sin(f * 2.1) : 0);
export const camAt = (id: number, f: number): Cam => {
  const c = run(CAMS[id], f), a = kickAt(f) + shake(f);
  if (!a) return c;
  const d: V3 = [c.look[0] - c.pos[0], c.look[1] - c.pos[1], c.look[2] - c.pos[2]];
  const Ld = Math.hypot(...d), h = Math.hypot(d[0], d[2]) || 1;
  const m = (3 / 640) * Math.tan((c.fov * Math.PI) / 360) * Ld * a;
  return { ...c, look: [c.look[0] - (d[2] / h) * m, c.look[1] + 0.6 * m, c.look[2] + (d[0] / h) * m], roll: c.roll + a * 0.004 };
};

// lens blur: close-ups with soft backgrounds (the reference's look), off for wides (also saves render time)
export const dofAt = (id: number) => ({ 1: 10, 5: 10, 9: 10, 11: 9 } as Record<number, number>)[id] ?? 0;
