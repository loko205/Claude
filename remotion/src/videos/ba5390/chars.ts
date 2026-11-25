// Custom drawings for the BA 5390 short (our own cast + effect cards), on top of the bridge toon kit.
import { Pen, bodyFront, bodySide, INK, Expr, Outfit, mix } from "../bridge/toon";

type P2 = [number, number];

/** captain's legs, lying horizontally (hips at the right edge = the window, feet at the left) on a 1000 x 320 canvas.
 *  kick 0..1 animates a flutter; the design unit is the same as the body card (1 unit = SU m) */
export const legs = (p: Pen, o: Outfit, kick: number) => {
  const g = p.g, legCol = mix(o.pants, INK, 0.25);
  const k1 = Math.sin(kick * Math.PI * 2) * 18, k2 = Math.cos(kick * Math.PI * 2 + 1) * 18;
  const hipY = 150;
  // shirt tail + belt at the window end
  p.poly([[1000, hipY - 80], [900, hipY - 78], [892, hipY + 80], [1000, hipY + 82]], legCol, 12);
  p.poly([[905, hipY - 82], [880, hipY - 82], [872, hipY + 84], [897, hipY + 84]], INK, 0);
  for (const [i, k] of [[0, k1], [1, k2]] as [number, number][]) {
    const y0 = hipY + (i ? 40 : -40);
    const pts: P2[] = [[900, y0], [620, y0 + (i ? 30 : -10) + k * 0.4], [330, y0 + (i ? 20 : 6) + k]];
    // trouser leg: thick ink-rimmed band
    p.line(pts, legCol, 58);
    // shoe
    const [fx, fy] = pts[2];
    g.save();
    p.poly([[fx + 10, fy - 34], [fx - 70, fy - 40], [fx - 92, fy - 12], [fx - 80, fy + 30], [fx + 12, fy + 30]], INK, 0);
    p.poly([[fx - 66, fy - 30], [fx - 84, fy - 10], [fx - 74, fy + 14]], "#4a4458", 0);
    g.restore();
    // sock gap
    p.line([[fx + 22, fy - 2], [fx + 4, fy - 2]], "#e8e4dc", 50, false);
  }
};

/** upper body only (cut at the hips), for the captain outside the plane; arms per mode */
export const upper = (p: Pen, o: Outfit, expr: Expr, seed: number, cut = 700) => {
  const g = p.g;
  g.save(); g.beginPath(); g.rect(-50, -50, 700, cut + 50); g.clip();
  bodyFront(p, o, { mode: "fall", expr, seed });
  g.restore();
};

/** bold outward arrow on a 300 x 160 canvas (pointing right) */
export const arrow = (p: Pen, col = "#ff5a3c") => {
  p.poly([[20, 58], [180, 58], [180, 18], [282, 80], [180, 142], [180, 102], [20, 102]], col, 14);
};

/** a bolt on a 220 x 520 canvas: hex head on top, threaded shank; w = shank half-width in units */
export const bolt = (p: Pen, w: number, col = "#c9ced6", ring?: string) => {
  const cx = 110;
  if (ring) { p.g.globalAlpha = 0.9; p.ell(cx, 260, 104, 250, null, 0); p.g.globalAlpha = 1; }
  // shank
  p.poly([[cx - w, 120], [cx + w, 120], [cx + w, 470], [cx, 500], [cx - w, 470]], col, 10);
  for (let y = 150; y < 470; y += 22) p.stroke([[cx - w + 4, y], [cx + w - 4, y + 10]], 5, mix(col, INK, 0.45));
  // head
  p.poly([[cx - 80, 50], [cx + 80, 50], [cx + 92, 85], [cx + 80, 122], [cx - 80, 122], [cx - 92, 85]], col, 12);
  p.stroke([[cx - 70, 70], [cx + 60, 70]], 8, "#ffffff");
  if (ring) p.ell(cx, 260, 104, 250, null, 14);
  if (ring === "bad") { p.g.strokeStyle = ring; }
};

/** green ring / red ring markers drawn around a bolt card (300 x 600) */
export const ringMark = (p: Pen, col: string) => {
  p.g.lineWidth = 18; p.g.strokeStyle = col; p.g.beginPath(); p.g.ellipse(150, 300, 130, 270, 0, 0, Math.PI * 2); p.g.stroke();
};

/** generic bank card (no logos, no text) on a 540 x 340 canvas */
export const creditCard = (p: Pen) => {
  const g = p.g;
  g.save();
  g.beginPath(); g.roundRect(20, 20, 500, 300, 34);
  const gr = g.createLinearGradient(20, 20, 520, 320); gr.addColorStop(0, "#3d6fd8"); gr.addColorStop(1, "#7a4fd0");
  g.fillStyle = gr; g.fill(); g.lineWidth = 14; g.strokeStyle = INK; g.stroke();
  g.beginPath(); g.roundRect(70, 110, 90, 70, 12); g.fillStyle = "#e8c45a"; g.fill(); g.lineWidth = 8; g.stroke();
  g.fillStyle = "rgba(255,255,255,0.75)";
  for (let i = 0; i < 4; i++) { g.beginPath(); g.roundRect(70 + i * 105, 220, 80, 22, 10); g.fill(); }
  g.restore();
};

/** the same card seen edge-on (a thin bar) on a 540 x 120 canvas, with two ink calipers marking its thickness */
export const cardEdge = (p: Pen) => {
  p.poly([[30, 52], [510, 52], [510, 68], [30, 68]], "#5a5fd4", 8);
};

/** sheet of paper (flight papers) on a 200 x 260 canvas */
export const paper = (p: Pen, seed: number) => {
  p.poly([[20, 20], [170, 12], [182, 240], [28, 248]], "#fbfaf5", 9);
  for (let i = 0; i < 6; i++) p.stroke([[42, 60 + i * 28], [150 - ((seed * 7 + i * 13) % 40), 58 + i * 28]], 6, "#9aa3b5");
};

/** pilot cap flying off (side) on a 300 x 200 canvas */
export const capFx = (p: Pen) => {
  p.poly([[40, 120], [60, 60], [150, 36], [250, 60], [262, 120]], "#1e2b52", 12);
  p.poly([[30, 120], [272, 120], [290, 150], [180, 160], [20, 145]], INK, 0);
  p.stroke([[70, 108], [240, 108]], 12, "#e8c45a");
};

/** wind streaks on a 600 x 300 canvas */
export const wind = (p: Pen, t: number) => {
  const g = p.g;
  g.globalAlpha = 0.85;
  for (let i = 0; i < 6; i++) {
    const y = 30 + i * 45, x0 = ((t * 900 + i * 137) % 700) - 200;
    p.line([[x0, y], [x0 + 220, y + 6]], "#ffffff", 10, false);
  }
  g.globalAlpha = 1;
};

/** mist puff (soft) on a 512 x 512 canvas */
export const mist = (p: Pen, a: number) => {
  const g = p.g, gr = g.createRadialGradient(256, 256, 10, 256, 256, 250);
  gr.addColorStop(0, `rgba(255,255,255,${0.9 * a})`); gr.addColorStop(1, "rgba(255,255,255,0)");
  g.fillStyle = gr; g.fillRect(0, 0, 512, 512);
};

/** dashed curved danger path on a 800 x 400 canvas (from left-top to right-bottom) */
export const dangerPath = (p: Pen, t: number) => {
  const g = p.g;
  g.setLineDash([46, 30]); g.lineDashOffset = -t * 300; g.lineCap = "round";
  g.lineWidth = 26; g.strokeStyle = INK; g.beginPath(); g.moveTo(40, 60); g.quadraticCurveTo(420, 20, 700, 300); g.stroke();
  g.lineWidth = 14; g.strokeStyle = "#ff4b3a"; g.beginPath(); g.moveTo(40, 60); g.quadraticCurveTo(420, 20, 700, 300); g.stroke();
  g.setLineDash([]);
  p.poly([[700, 300], [640, 250], [740, 230]], "#ff4b3a", 12);
};

/** head bandage + arm sling over a sitting front body (call after bodyFront on the same canvas) */
export const bandages = (p: Pen) => {
  p.poly([[186, 488], [414, 488], [416, 528], [184, 528]], "#ffffff", 9);
  p.poly([[390, 478], [430, 466], [436, 506]], "#ffffff", 8);
};

/** frost sparkle on a 200 x 200 canvas */
export const frost = (p: Pen) => {
  const c = 100;
  for (let i = 0; i < 3; i++) { const a = (i * Math.PI) / 3; p.line([[c - 80 * Math.cos(a), c - 80 * Math.sin(a)], [c + 80 * Math.cos(a), c + 80 * Math.sin(a)]], "#dff4ff", 16); }
  p.dot(c, c, 18, "#ffffff");
};

/** heavy weight (kettlebell, no text) on a 300 x 320 canvas */
export const weight = (p: Pen) => {
  p.g.lineWidth = 34; p.g.strokeStyle = INK; p.g.beginPath(); p.g.arc(150, 110, 70, Math.PI, 0); p.g.stroke();
  p.g.lineWidth = 18; p.g.strokeStyle = "#4a4f5c"; p.g.beginPath(); p.g.arc(150, 110, 70, Math.PI, 0); p.g.stroke();
  p.ell(150, 210, 120, 100, "#4a4f5c", 14);
  p.ell(110, 180, 30, 20, "#6c7282", 0);
};

export { bodyFront, bodySide };
