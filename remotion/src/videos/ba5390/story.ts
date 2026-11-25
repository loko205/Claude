// BA 5390 short: shot table, cameras, kicks, lens blur. Frames at 30 fps, timed to voice/segments.json.
export const FPS = 30;
export const TOTAL = 1890;
export type V3 = [number, number, number];
export type Set = "hangar" | "sky" | "runway" | "cockpit" | "hospital";
export type Light = "day" | "night" | "indoor";

export const clamp01 = (x: number) => Math.max(0, Math.min(1, x));
export const smooth = (x: number) => { const u = clamp01(x); return u * u * (3 - 2 * u); };
export const ease = (x: number) => { const u = clamp01(x); return u < 0.5 ? 4 * u * u * u : 1 - (-2 * u + 2) ** 3 / 2; };
export const lin = (pts: [number, number][], x: number) => {
  if (x <= pts[0][0]) return pts[0][1];
  for (let i = 1; i < pts.length; i++) if (x <= pts[i][0]) {
    const [x0, y0] = pts[i - 1], [x1, y1] = pts[i];
    return y0 + ((y1 - y0) * (x - x0)) / (x1 - x0);
  }
  return pts[pts.length - 1][1];
};

export type ShotDef = { id: number; a: number; b: number; set: Set; light: Light };
export const SHOTS: ShotDef[] = [
  { id: 1, a: 0, b: 118, set: "hangar", light: "night" },      // hook: the mechanic picks bolts
  { id: 2, a: 118, b: 222, set: "sky", light: "day" },         // captain behind his windscreen
  { id: 3, a: 222, b: 398, set: "runway", light: "day" },      // June 1990, take-off from Birmingham
  { id: 4, a: 398, b: 458, set: "sky", light: "day" },         // 81 passengers, six crew: climbing
  { id: 5, a: 458, b: 509, set: "cockpit", light: "day" },     // thirteen minutes in ... BANG
  { id: 6, a: 509, b: 612, set: "sky", light: "day" },         // the windscreen blows out at 17,000 ft
  { id: 7, a: 612, b: 757, set: "cockpit", light: "day" },     // the air rushes out and takes the captain
  { id: 8, a: 757, b: 942, set: "cockpit", light: "day" },     // Nigel grabs his legs; 500 pounds
  { id: 9, a: 942, b: 1050, set: "cockpit", light: "day" },    // Nigel slides; more crew grab Nigel
  { id: 10, a: 1050, b: 1213, set: "sky", light: "day" },      // a plane is like a balloon
  { id: 11, a: 1213, b: 1378, set: "sky", light: "day" },      // ninety bolts, 84 too thin
  { id: 12, a: 1378, b: 1450, set: "hangar", light: "night" }, // picked by eye from a drawer
  { id: 13, a: 1450, b: 1595, set: "sky", light: "day" },      // the crew holds on; the engine
  { id: 14, a: 1595, b: 1692, set: "runway", light: "day" },   // lands in Southampton
  { id: 15, a: 1692, b: 1790, set: "hospital", light: "indoor" }, // frostbite, broken bones, alive
  { id: 16, a: 1790, b: TOTAL, set: "cockpit", light: "day" },  // five months later he was flying again
];
export const XFADE: Record<number, number> = { 3: 8, 15: 10, 16: 10 };
export const FLASH_AT = 222;
export const BANG = 493;          // "Bang!" — the windscreen goes
export const LIFT = 690;          // captain leaves the seat ("takes the captain with it")
export const OUT = 728;           // captain is out (legs left inside)
export const GRAB = 800;          // Nigel's hands close on the legs ("grabs his legs")
export const SLIDE = 950;         // Nigel starts to slide ("Nigel is sliding out too")
export const CREW = 1000;         // more crew grab Nigel
export const RED = 1290;          // the thin bolts turn red ("eighty-four were too thin")
export const CARD_IN = 1318;      // credit card insert
export const TOUCH = 1648;        // main wheels touch down at Southampton

export const shotAt = (f: number) => SHOTS.find((s) => f >= s.a && f < s.b) ?? SHOTS[SHOTS.length - 1];
export const layersAt = (f: number): { id: number; alpha: number }[] => {
  for (const s of SHOTS) {
    const x = XFADE[s.id];
    if (x && f >= s.a - x / 2 && f < s.a + x / 2) return [{ id: s.id - 1, alpha: 1 }, { id: s.id, alpha: (f - (s.a - x / 2) + 1) / (x + 1) }];
  }
  return [{ id: shotAt(f).id, alpha: 1 }];
};

// ---------------- cameras ----------------
export type Cam = { pos: V3; look: V3; fov: number; roll: number };
type Key = { f: number; dur?: number; cut?: boolean; c: Cam | ((f: number) => Cam) };
const C = (pos: V3, look: V3, fov = 40, roll = 0): Cam => ({ pos, look, fov, roll });
const L3 = (a: V3, b: V3, k: number): V3 => [a[0] + (b[0] - a[0]) * k, a[1] + (b[1] - a[1]) * k, a[2] + (b[2] - a[2]) * k];
const mixCam = (a: Cam, b: Cam, k: number): Cam => ({ pos: L3(a.pos, b.pos, k), look: L3(a.look, b.look, k), fov: a.fov + (b.fov - a.fov) * k, roll: a.roll + (b.roll - a.roll) * k });
/** slow continuous push: move pos toward look by `amt` (fraction) across the shot */
const push = (c: Cam, a: number, b: number, amt: number) => (f: number): Cam => {
  const k = amt * clamp01((f - a) / (b - a));
  return { ...c, pos: L3(c.pos, c.look, k) };
};
const at = (c: Cam | ((f: number) => Cam), f: number) => (typeof c === "function" ? c(f) : c);
const run = (keys: Key[], f: number): Cam => {
  let cur = at(keys[0].c, f);
  for (let i = 1; i < keys.length; i++) {
    const k = keys[i];
    if (f < k.f) break;
    const nxt = at(k.c, f);
    if (k.cut) { cur = nxt; continue; }
    cur = mixCam(cur, nxt, ease((f - k.f) / (k.dur ?? 24)));
  }
  return cur;
};

// plane (sky set): nose at +x (x = 14), captain's (left) windscreen on the -z side, fuselage axis y = 0.
// cockpit set: same orientation, floor y = 0, pilots at x = 0, captain z = -0.5, FO z = +0.5, windscreen at x ~ 1.55.
export const CAMS: Record<number, Key[]> = {
  1: [
    { f: 0, c: push(C([4.2, 1.7, 5.6], [0.4, 1.25, 0.2], 38), 0, 118, 0.28) },
  ],
  2: [
    { f: 118, c: push(C([15.4, 2.3, -4.0], [12.2, 0.95, -0.4], 36), 118, 222, 0.3) },
  ],
  3: [
    { f: 222, c: (f) => { const x = planeX(f); return C([x + 34, 3.5, 30], [x + 4, 3.0 + 0.6 * planeY(f), 0], 38); } },
  ],
  4: [
    { f: 398, c: push(C([36, 5, -30], [2, 0, 0], 40), 398, 458, 0.12) },
  ],
  5: [
    { f: 458, c: C([1.36, 1.5, 0.0], [-0.8, 0.98, 0.0], 72) },
  ],
  6: [
    { f: 509, c: push(C([18.5, 3.4, -8.5], [11.5, 0.8, -0.8], 40), 509, 612, 0.12) },
  ],
  7: [
    { f: 612, c: C([1.36, 1.5, 0.0], [-0.8, 0.98, 0.0], 72) },
    { f: 672, cut: true, c: C([-1.05, 1.9, 0.8], [1.35, 1.3, -0.45], 58) },
  ],
  8: [
    { f: 757, c: C([0.35, 1.3, 3.6], [0.4, 1.1, -0.3], 50) },
    { f: 845, dur: 30, c: C([0.5, 1.35, 2.9], [0.45, 1.15, -0.3], 50) },
  ],
  9: [
    { f: 942, c: C([0.3, 1.3, 3.6], [0.35, 1.12, -0.3], 52) },
    { f: 990, dur: 24, c: C([-0.2, 1.35, 4.5], [0.05, 1.08, -0.3], 54) },
  ],
  10: [
    { f: 1050, c: C([2, 2, -40], [0, 0, 0], 42) },
    { f: 1080, dur: 120, c: C([0, 3, -33], [0, 0, 0], 44) },
  ],
  11: [
    { f: 1213, c: push(C([14.8, 3.0, -3.5], [12.9, 1.0, -0.85], 36), 1213, 1300, 0.25) },
  ],
  12: [
    { f: 1378, c: push(C([1.8, 1.65, 2.4], [0.5, 1.35, 0.15], 34), 1378, 1450, 0.2) },
  ],
  13: [
    { f: 1450, c: C([16.2, 3.6, -4.8], [11.7, 1.75, -0.7], 40) },
    { f: 1515, dur: 40, c: C([26, 14, -15], [2.5, 1.0, -1.2], 44) },
  ],
  14: [
    { f: 1595, c: (f) => { const x = planeX(f); return C([x + 34, 3.0, 30], [x + 4, 2.6 + 0.6 * planeY(f), 0], 38); } },
  ],
  15: [
    { f: 1692, c: push(C([0, 1.35, 3.2], [0, 1.0, 0], 40), 1692, 1790, 0.2) },
  ],
  16: [
    { f: 1790, c: push(C([1.36, 1.5, 0.0], [-0.8, 0.98, 0.0], 72), 1790, 1890, 0.12) },
  ],
};

// runway plane motion (x of the plane's centre along the runway, metres)
export const planeX = (f: number) => {
  if (f < 1000) { // take-off roll, shot 3 (222..398): accelerating along +x
    const t = (f - 222) / FPS;
    return -40 + 18 * t + 2.2 * t * t;
  }
  const t = (f - TOUCH) / FPS; // landing, shot 14: decelerating through touchdown
  return t < 0 ? 62 * t : 62 * t - 9 * t * t;
};
export const planeY = (f: number) => {
  if (f < 1000) { const t = (f - 330) / FPS; return t < 0 ? 0 : 1.2 * t * t + 2 * t; }
  const t = (f - TOUCH) / FPS; return t < 0 ? -t * 3.4 : 0;
};
export const planePitch = (f: number) => {
  if (f < 1000) return lin([[310, 0], [340, 0.17], [398, 0.2]], f);
  return lin([[1595, 0.05], [TOUCH - 10, 0.09], [TOUCH, 0.08], [TOUCH + 25, 0]], f);
};

const KICKS: [number, number][] = [[BANG, 1.8], [BANG + 8, 0.8], [GRAB, 0.5], [TOUCH, 0.6]];
export const kickAt = (f: number) => {
  let a = 0;
  for (const [f0, g] of KICKS) {
    const n = f - f0;
    if (n >= 0 && n < 7) a += g * (n % 2 ? -1 : 1) * (1 - n / 7) ** 1.5;
  }
  return a;
};
/** air buffeting in the cockpit after the bang (small, continuous) */
const buffet = (f: number, id: number) => (id >= 7 && id <= 9 ? 0.35 * Math.sin(f * 1.7) * Math.sin(f * 0.53) : 0);
export const camAt = (id: number, f: number): Cam => {
  const c = run(CAMS[id], f), a = kickAt(f) + buffet(f, id);
  if (!a) return c;
  const d: V3 = [c.look[0] - c.pos[0], c.look[1] - c.pos[1], c.look[2] - c.pos[2]];
  const Ld = Math.hypot(...d), h = Math.hypot(d[0], d[2]) || 1;
  const m = (3 / 640) * Math.tan((c.fov * Math.PI) / 360) * Ld * a;
  return { ...c, look: [c.look[0] - (d[2] / h) * m, c.look[1] + 0.6 * m, c.look[2] + (d[0] / h) * m], roll: c.roll + a * 0.004 };
};

// ---------------- lens ----------------
export type Dof = { f: number; dur?: number; cInf: number; focus?: (f: number) => V3 };
export const DOF: Dof[] = [
  { f: 0, cInf: 10 },            // hangar: mechanic sharp, hangar soft
  { f: 118, cInf: 0 },
  { f: 1378, cInf: 10 },         // hangar callback
  { f: 1450, cInf: 0 },
  { f: 1692, cInf: 8 },          // hospital
  { f: 1790, cInf: 0 },
];
export const dofAt = (f: number) => {
  let i = 0; while (i + 1 < DOF.length && f >= DOF[i + 1].f) i++;
  const d = DOF[i], p = DOF[Math.max(0, i - 1)];
  const k = d.dur ? Math.min(1, (f - d.f) / d.dur) : 1;
  return { cInf: p.cInf + (d.cInf - p.cInf) * k, focus: d.focus };
};
