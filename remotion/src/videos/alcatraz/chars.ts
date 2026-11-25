// Prop and effect drawings for the Alcatraz short (flat ink cartoon, no text).
import { Pen, INK, mix } from "../bridge/toon";
type P2 = [number, number];

/** steel spoon, 160 x 420 canvas, bowl on top */
export const spoon = (p: Pen) => {
  p.poly([[70, 150], [90, 150], [96, 400], [64, 400]], "#c9ced6", 10);
  p.ell(80, 90, 46, 70, "#dfe3ea", 10);
  p.ell(70, 78, 14, 26, "#ffffff", 0);
};

/** home-made drill from a vacuum-cleaner motor, 420 x 260 canvas, bit pointing right */
export const drill = (p: Pen, t = 0) => {
  const j = Math.sin(t * 40) * 4;
  p.ell(150, 130 + j, 110, 90, "#8a9099", 12);
  for (let i = 0; i < 5; i++) p.stroke([[80 + i * 30, 70 + j], [80 + i * 30, 190 + j]], 8, "#5a606a");
  p.poly([[250, 112 + j], [300, 112 + j], [300, 148 + j], [250, 148 + j]], "#6a707a", 10);
  p.poly([[300, 122 + j], [400, 128 + j], [400, 132 + j], [300, 138 + j]], "#d8dce4", 8);
  p.stroke([[120, 200 + j], [70, 250], [20, 240]], 12, INK); // cord
};

/** accordion / concertina, 420 x 300 canvas; s = squeeze 0..1 */
export const accordion = (p: Pen, s = 0, small = false) => {
  const w = (small ? 120 : 170) - 60 * s, cx = 210, h = small ? 170 : 220, top = 150 - h / 2;
  p.poly([[cx - w - 60, top], [cx - w, top], [cx - w, top + h], [cx - w - 60, top + h]], "#b8342e", 12);
  p.poly([[cx + w, top], [cx + w + 60, top], [cx + w + 60, top + h], [cx + w, top + h]], "#b8342e", 12);
  const n = 7;
  for (let i = 0; i < n; i++) {
    const x0 = cx - w + (2 * w * i) / n, x1 = cx - w + (2 * w * (i + 1)) / n, xm = (x0 + x1) / 2;
    p.poly([[x0, top + 6], [xm, top - 4], [x1, top + 6], [x1, top + h - 6], [xm, top + h + 4], [x0, top + h - 6]], i % 2 ? "#f1efe6" : "#d9d4c8", 7);
  }
  for (let k = 0; k < 6; k++) p.dot(cx - w - 30, top + 30 + k * ((h - 60) / 5), 7, "#f1efe6");
};

/** desk calendar, 300 x 340 canvas, a page flying off with phase t (0..1) */
export const calendar = (p: Pen, t: number, seed = 0) => {
  p.poly([[30, 60], [270, 60], [270, 320], [30, 320]], "#fbfaf5", 12);
  p.poly([[30, 60], [270, 60], [270, 120], [30, 120]], "#d24a40", 12);
  for (let r = 0; r < 4; r++) for (let c = 0; c < 5; c++) p.dot(70 + c * 40, 160 + r * 40, 8, ((r * 5 + c + seed) % 7) === 0 ? "#d24a40" : "#9aa3b5");
  for (const x of [90, 210]) p.poly([[x - 8, 40], [x + 8, 40], [x + 8, 80], [x - 8, 80]], "#5a606a", 6);
  if (t > 0) {
    const a = t * 2.4, dx = t * 200, dy = -t * 160;
    p.g.save(); p.g.translate(150 + dx, 190 + dy); p.g.rotate(a); p.g.scale(1 - 0.5 * t, 1 - 0.5 * t);
    p.poly([[-120, -130], [120, -130], [120, 130], [-120, 130]], "#fbfaf5", 12);
    p.poly([[-120, -130], [120, -130], [120, -70], [-120, -70]], "#d24a40", 12);
    p.g.restore();
  }
};

export const soap = (p: Pen) => { p.poly([[40, 80], [260, 70], [270, 190], [30, 200]], "#f4ead2", 12); p.ell(120, 110, 40, 16, "#ffffff", 0); };
export const toothpaste = (p: Pen) => {
  p.poly([[30, 90], [230, 70], [250, 110], [230, 150], [30, 130]], "#e8f0fa", 12);
  p.poly([[230, 80], [280, 92], [280, 128], [230, 140]], "#3a7bd5", 10);
  p.stroke([[60, 110], [200, 102]], 14, "#d24a40");
};
export const tpRoll = (p: Pen) => { p.ell(150, 150, 110, 110, "#fbfaf5", 12); p.ell(150, 150, 36, 36, "#c9b48a", 10); };

/** dummy head; stage 0 = grey blob, 1 = painted, 2 = painted + hair (asleep face). 400 x 400 canvas */
export const dummyHead = (p: Pen, stage: number, hair = "#2e2018", broken = false) => {
  const skin = stage === 0 ? "#b9b4aa" : "#efc8a0";
  p.ell(200, 220, 130, 150, skin, 14);
  if (stage >= 1) {
    // closed sleeping eyes + nose + mouth
    p.stroke([[140, 220], [175, 230]], 9, INK); p.stroke([[225, 230], [260, 220]], 9, INK);
    if (!broken) p.poly([[195, 240], [215, 280], [190, 285]], mix(skin, INK, 0.15), 7);
    p.stroke([[180, 315], [222, 312]], 8, INK);
    p.ell(135, 270, 20, 12, "#f0a890", 0); p.ell(265, 270, 20, 12, "#f0a890", 0);
  }
  if (stage >= 2) {
    p.poly([[70, 200], [90, 110], [160, 66], [250, 66], [320, 110], [334, 200], [300, 150], [250, 130], [200, 150], [150, 128], [100, 150]], hair, 12);
  }
};

/** broken head pieces flying (t 0..1), 500 x 400 canvas */
export const headPieces = (p: Pen, t: number) => {
  const pcs: [number, number, number][] = [[-1, -0.6, 0], [1, -0.8, 1], [-0.4, -1.2, 2], [0.7, -0.3, 3], [0.1, -1.0, 4]];
  for (const [vx, vy, i] of pcs) {
    const x = 250 + vx * 230 * t, y = 300 + vy * 300 * t + 500 * t * t;
    p.g.save(); p.g.translate(x, y); p.g.rotate(t * 6 * (i % 2 ? 1 : -1));
    p.poly([[-30, -20], [26, -28], [34, 20], [-20, 30]], i === 4 ? "#2e2018" : "#efc8a0", 9);
    p.g.restore();
  }
};

/** flashlight, 260 x 120 canvas, lens to the right */
export const flashlight = (p: Pen) => {
  p.poly([[20, 40], [170, 40], [170, 80], [20, 80]], "#3a3f4a", 10);
  p.poly([[170, 26], [230, 18], [230, 102], [170, 94]], "#5a606a", 10);
  p.poly([[226, 26], [240, 26], [240, 94], [226, 94]], "#fff6c8", 8);
};

/** wooden paddle, 120 x 600 canvas */
export const paddle = (p: Pen) => {
  p.poly([[52, 20], [68, 20], [70, 380], [50, 380]], "#a8743a", 9);
  p.poly([[30, 380], [90, 380], [96, 560], [60, 590], [24, 560]], "#b98448", 11);
};

/** big question mark sign (a symbol, not text), 240 x 360 canvas */
export const question = (p: Pen) => {
  const g = p.g; g.lineCap = "round"; g.lineJoin = "round";
  const path = () => { g.beginPath(); g.moveTo(60, 110); g.bezierCurveTo(60, 20, 190, 20, 190, 110); g.bezierCurveTo(190, 170, 120, 170, 120, 240); };
  g.lineWidth = 64; g.strokeStyle = INK; path(); g.stroke();
  g.lineWidth = 36; g.strokeStyle = "#ffd24a"; path(); g.stroke();
  p.ell(120, 310, 30, 30, "#ffd24a", 14);
};

/** noise lines (sound), 300 x 300 canvas; t animates */
export const noise = (p: Pen, t: number) => {
  for (let i = 0; i < 3; i++) {
    const r = 60 + i * 45 + (t * 40) % 45;
    p.g.lineWidth = 16; p.g.strokeStyle = INK; p.g.beginPath(); p.g.arc(60, 150, r, -0.6, 0.6); p.g.stroke();
    p.g.lineWidth = 8; p.g.strokeStyle = "#ffd24a"; p.g.beginPath(); p.g.arc(60, 150, r, -0.6, 0.6); p.g.stroke();
  }
};

/** dust puff for scraping, 300 x 300 canvas */
export const dust = (p: Pen, t: number) => {
  for (let i = 0; i < 6; i++) {
    const a = i * 1.1 + t, r = 20 + 90 * t;
    p.ell(150 + Math.cos(a) * r, 170 + Math.sin(a) * r * 0.6 - 30 * t, 26 * (1 - t) + 6, 22 * (1 - t) + 5, "#cfc6b4", 6);
  }
};

/** handwriting texture for the letter (scribbles, no readable text), canvas painter */
export const letterTex = (g: CanvasRenderingContext2D, w: number, h: number, r: () => number) => {
  g.fillStyle = "#fbf6e8"; g.fillRect(0, 0, w, h);
  g.strokeStyle = "#c8d4ea"; g.lineWidth = 2; for (let y = 120; y < h - 40; y += 46) { g.beginPath(); g.moveTo(40, y); g.lineTo(w - 40, y); g.stroke(); }
  g.strokeStyle = "#1f2a55"; g.lineWidth = 4; g.lineCap = "round";
  for (let y = 112, l = 0; y < h * 0.62; y += 46, l++) {
    let x = 60 + (l === 0 ? 0 : 0); const end = w - 70 - r() * 120;
    while (x < end) { const ww = 20 + r() * 50; g.beginPath(); g.moveTo(x, y); for (let k = 0; k <= 8; k++) g.lineTo(x + (ww * k) / 8, y - 6 - Math.sin(k * 2.3 + r() * 3) * 9); g.stroke(); x += ww + 14; }
  }
};

/** star sparkle, 200 x 200 */
export const sparkle = (p: Pen) => {
  p.poly([[100, 10], [120, 80], [190, 100], [120, 120], [100, 190], [80, 120], [10, 100], [80, 80]], "#fff3b0", 10);
};
export type { P2 };

// ---------- held props: drawn into the character canvas at the hand (hx, hy), size in head-units u ----------
type Draw = (p: Pen) => void;
const held = (draw: Draw, ax: number, ay: number, ch: number, sizeU: number, rot = 0) => (p: Pen, hx: number, hy: number, u: number) => {
  const s = (sizeU * u) / ch, g = p.g;
  g.save(); g.translate(hx, hy); g.rotate(rot); g.scale(s, s); g.translate(-ax, -ay); draw(p); g.restore();
};
export const H = {
  spoon: held(spoon, 80, 330, 420, 52, 0.25),
  spoonVent: held(spoon, 80, 330, 420, 52, 1.1),
  drill: (t: number) => held((p) => drill(p, t), 150, 200, 260, 34),
  accordion: (s: number, small = false) => held((p) => accordion(p, s, small), 360, 150, 300, small ? 44 : 48),
  flashlight: held(flashlight, 50, 60, 120, 13),
  soap: held(soap, 150, 190, 270, 34),
  paste: held(toothpaste, 90, 110, 220, 30, -0.3),
  roll: held(tpRoll, 150, 170, 300, 36),
  head: (stage: number) => held((p) => dummyHead(p, stage), 200, 340, 400, 64),
  paddle: (a: number) => held(paddle, 60, 280, 600, 80, a),
};
