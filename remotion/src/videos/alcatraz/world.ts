// Alcatraz world: the cellblock (cells, Frank's cell, utility corridor, pipes, raft deck), the bay (island, prison,
// towers, searchlights, water, city lights, raft, search boats) and a police desk. Shown one set at a time; update()
// poses everything for shot id at frame f.
import * as THREE from "three";
import { TONE, CHAR, twoTone, untone } from "../bridge/shade";
import { NOINK } from "../bridge/ink";
import { Pool, Actor, Fx, SU } from "../bridge/cast";
import { Pen, bodyFront, bodySide, fxBurst, fxPuff, fxNote, Expr } from "../bridge/toon";
import { cloudHD, ctex, rng } from "../bridge/paint";
import { FRANK, JOHN, CLARENCE, GUARD, COP } from "./outfits";
import * as D from "./chars";
import { POOLS, poolify, resetPools, pool } from "./pools";
import { FPS, SHOTS, SetName, camAt, smooth, clamp01, eout, B } from "./story";
void POOLS; void SU;

type C3 = [number, number, number];
type LP = { az: number; el: number; lit: C3; shade: C3; lift: C3; lambert: number; sideK: number; term: number; charTint: C3; charShade: number; charGrad: number; bodyGrad: number; sideTint: C3; sky: string[]; skyE: number[]; fog: string; near: number; far: number; sunI: number; sat: number };
const NIGHT_SKY = ["#1d2c5c", "#182552", "#131e46", "#0e1739", "#0a1029"];
const LIGHTS: Record<string, LP> = {
  night: { az: 50, el: 55, lit: [0.86, 0.88, 1.18], shade: [0.27, 0.27, 0.5], lift: [0.04, 0.04, 0.11], lambert: 0.4, sideK: 0.8, term: 0.25, charTint: [0.92, 0.92, 1.06], charShade: 0.8, charGrad: 0.12, bodyGrad: 0.25, sideTint: [0.78, 0.82, 1.0], sky: NIGHT_SKY, skyE: [0, 4, 10, 20, 45], fog: "#14204a", near: 30, far: 260, sunI: 2.6, sat: 1.15 },
  lamp: { az: 30, el: 50, lit: [0.66, 0.68, 1.02], shade: [0.2, 0.2, 0.42], lift: [0.03, 0.03, 0.1], lambert: 0.4, sideK: 0.8, term: 0.25, charTint: [0.85, 0.85, 1.02], charShade: 0.78, charGrad: 0.12, bodyGrad: 0.25, sideTint: [0.75, 0.8, 1.0], sky: NIGHT_SKY, skyE: [0, 4, 10, 20, 45], fog: "#14204a", near: 30, far: 260, sunI: 2.6, sat: 1.15 },
  dawn: { az: 70, el: 30, lit: [1.45, 1.2, 0.95], shade: [0.34, 0.33, 0.52], lift: [0.05, 0.06, 0.12], lambert: 0.35, sideK: 0.84, term: 0.2, charTint: [1.0, 0.92, 0.88], charShade: 0.84, charGrad: 0.08, bodyGrad: 0.2, sideTint: [0.9, 0.88, 0.98], sky: ["#f6c7a0", "#e8b9b0", "#b4b4d8", "#7d93cf", "#4f6cc0"], skyE: [0, 4, 10, 20, 45], fog: "#c8b8c8", near: 40, far: 400, sunI: 2.6, sat: 1.1 },
  day: { az: 60, el: 40, lit: [1.5, 1.45, 1.32], shade: [0.36, 0.36, 0.48], lift: [0.05, 0.06, 0.11], lambert: 0.35, sideK: 0.84, term: 0.2, charTint: [1.0, 0.96, 0.94], charShade: 0.86, charGrad: 0.07, bodyGrad: 0.2, sideTint: [0.92, 0.9, 0.96], sky: ["#d6e2ec", "#bcd0e6", "#94b4dc", "#6f97d0", "#4f7cc4"], skyE: [0, 4, 10, 20, 45], fog: "#c9d6e2", near: 60, far: 900, sunI: 2.6, sat: 1.05 },
  desk: { az: 40, el: 60, lit: [0.55, 0.6, 0.95], shade: [0.16, 0.16, 0.32], lift: [0.03, 0.03, 0.08], lambert: 0.4, sideK: 0.8, term: 0.25, charTint: [0.8, 0.8, 1.0], charShade: 0.8, charGrad: 0.1, bodyGrad: 0.2, sideTint: [0.8, 0.8, 1.0], sky: NIGHT_SKY, skyE: [0, 4, 10, 20, 45], fog: "#14204a", near: 30, far: 200, sunI: 2.6, sat: 1.1 },
};
const WARM = "#ffb45a", COOL = "#9fc4ff";

const V = (x: number, y: number, z: number) => new THREE.Vector3(x, y, z);
const mats = new Map<string, THREE.Material>();
const lam = (key: string, p: THREE.MeshLambertMaterialParameters) => {
  let m = mats.get(key);
  if (!m) { m = poolify(twoTone(new THREE.MeshLambertMaterial(p))); mats.set(key, m); }
  return m;
};
const col = (c: string) => lam("c" + c, { color: c });
const basic = (c: THREE.Color | string, k = 1) => { const m = new THREE.MeshBasicMaterial({ color: new THREE.Color(c).multiplyScalar(k) }); return m; };
const box = (w: number, h: number, d: number) => new THREE.BoxGeometry(w, h, d);
const mesh = (g: THREE.BufferGeometry, m: THREE.Material, parent: THREE.Object3D, x = 0, y = 0, z = 0, shadow = true) => {
  const o = new THREE.Mesh(g, m); o.position.set(x, y, z); o.castShadow = shadow; o.receiveShadow = true; parent.add(o); return o;
};
const tex = (key: string, w: number, h: number, draw: (g: CanvasRenderingContext2D, r: () => number) => void, rx = 1, ry = 1) => {
  const t = ctex(key, w, h, draw).clone(); t.wrapS = t.wrapT = THREE.RepeatWrapping; t.repeat.set(rx, ry); t.needsUpdate = true; return t;
};
const speckle = (g: CanvasRenderingContext2D, r: () => number, w: number, h: number, n: number, a: number, cs = ["0,0,0", "255,255,255"]) => {
  for (let i = 0; i < n; i++) { g.fillStyle = `rgba(${cs[i % cs.length]},${a * (0.4 + r() * 0.6)})`; const s = 2 + r() * 14; g.fillRect(r() * w, r() * h, s, s * (0.5 + r())); }
};

// ---------------- textures ----------------
const floorT = () => tex("az_floor", 1024, 1024, (g, r) => {
  g.fillStyle = "#8c9890"; g.fillRect(0, 0, 1024, 1024); speckle(g, r, 1024, 1024, 1600, 0.08, ["40,50,45", "220,230,220"]);
  g.strokeStyle = "rgba(40,50,45,0.5)"; g.lineWidth = 3; for (let k = 0; k <= 4; k++) { g.beginPath(); g.moveTo(k * 256, 0); g.lineTo(k * 256, 1024); g.stroke(); }
  for (let i = 0; i < 30; i++) { g.fillStyle = "rgba(255,255,255,0.05)"; g.beginPath(); g.ellipse(r() * 1024, r() * 1024, 60 + r() * 120, 20 + r() * 40, r() * 3, 0, 7); g.fill(); }
}, 6, 6);
const cellWallT = () => tex("az_cellwall", 512, 512, (g, r) => {
  g.fillStyle = "#cfd8c4"; g.fillRect(0, 0, 512, 512);
  g.fillStyle = "#7fa38c"; g.fillRect(0, 300, 512, 212); g.fillStyle = "#5c806a"; g.fillRect(0, 294, 512, 10);
  speckle(g, r, 512, 512, 500, 0.07, ["60,70,60", "255,255,255"]);
  for (let i = 0; i < 8; i++) { g.strokeStyle = "rgba(60,60,50,0.25)"; g.lineWidth = 2; g.beginPath(); let x = r() * 512, y = r() * 300; g.moveTo(x, y); for (let k = 0; k < 6; k++) { x += (r() - 0.5) * 40; y += 10 + r() * 20; g.lineTo(x, y); } g.stroke(); }
});
const blockWallT = () => tex("az_blockwall", 512, 512, (g, r) => {
  g.fillStyle = "#b9c2b0"; g.fillRect(0, 0, 512, 512); speckle(g, r, 512, 512, 700, 0.08, ["60,70,60", "255,255,255"]);
  g.fillStyle = "#6f8f7a"; g.fillRect(0, 380, 512, 132);
}, 4, 1);
const utilT = () => tex("az_util", 512, 512, (g, r) => {
  g.fillStyle = "#6c6a62"; g.fillRect(0, 0, 512, 512); speckle(g, r, 512, 512, 1500, 0.14, ["30,28,24", "180,170,150"]);
  for (let i = 0; i < 14; i++) { g.fillStyle = `rgba(90,60,30,${0.1 + r() * 0.15})`; g.fillRect(r() * 512, 0, 6 + r() * 20, 512); }
}, 3, 2);
const blanketT = () => tex("az_blanket", 256, 256, (g) => {
  g.fillStyle = "#7a7f88"; g.fillRect(0, 0, 256, 256); g.fillStyle = "#5d626b"; for (let y = 0; y < 256; y += 64) g.fillRect(0, y + 20, 256, 12);
  g.fillStyle = "#a8acb4"; for (let y = 0; y < 256; y += 64) g.fillRect(0, y + 36, 256, 4);
});
const raftT = () => tex("az_raft", 512, 512, (g, r) => {
  g.fillStyle = "#e0b22c"; g.fillRect(0, 0, 512, 512);
  for (let i = 0; i < 26; i++) { g.fillStyle = ["#e8bf38", "#d6a524", "#f0c84a", "#c99a20"][i % 4]; const x = r() * 460, y = r() * 460; g.fillRect(x, y, 60 + r() * 90, 50 + r() * 80); }
  g.strokeStyle = "rgba(80,50,10,0.7)"; g.lineWidth = 4; g.setLineDash([10, 8]); for (let i = 0; i < 9; i++) { g.beginPath(); g.moveTo(0, i * 60 + r() * 20); g.lineTo(512, i * 60 + r() * 20); g.stroke(); }
  g.setLineDash([]);
});
const waterT = () => tex("az_water", 1024, 1024, (g, r) => {
  g.fillStyle = "#1a3a66"; g.fillRect(0, 0, 1024, 1024);
  for (let i = 0; i < 900; i++) { g.strokeStyle = `rgba(${r() < 0.5 ? "120,170,230" : "10,25,55"},${0.25 + r() * 0.3})`; g.lineWidth = 3; const x = r() * 1024, y = r() * 1024, l = 20 + r() * 60; g.beginPath(); g.moveTo(x, y); g.quadraticCurveTo(x + l / 2, y - 6, x + l, y); g.stroke(); }
}, 40, 40);
const rockT = () => tex("az_rock", 512, 512, (g, r) => {
  g.fillStyle = "#6a6458"; g.fillRect(0, 0, 512, 512); speckle(g, r, 512, 512, 1200, 0.2, ["30,28,24", "170,160,140"]);
  g.fillStyle = "rgba(70,110,60,0.5)"; for (let i = 0; i < 30; i++) { g.beginPath(); g.arc(r() * 512, r() * 200, 10 + r() * 30, 0, 7); g.fill(); }
}, 3, 3);
const prisonT = () => tex("az_prison", 1024, 512, (g, r) => {
  g.fillStyle = "#d8d4c4"; g.fillRect(0, 0, 1024, 512); speckle(g, r, 1024, 512, 1000, 0.08, ["70,70,60", "255,255,255"]);
  for (let row = 0; row < 3; row++) for (let i = 0; i < 18; i++) {
    const x = 30 + i * 55, y = 90 + row * 130; const lit = r() < 0.22;
    g.fillStyle = lit ? "#ffd27a" : "#2a3450"; g.fillRect(x, y, 30, 70);
    g.strokeStyle = "#1a1a1a"; g.lineWidth = 3; for (let k = 1; k < 4; k++) { g.beginPath(); g.moveTo(x + k * 7.5, y); g.lineTo(x + k * 7.5, y + 70); g.stroke(); }
  }
});
const cityT = () => tex("az_city", 1024, 256, (g, r) => {
  g.clearRect(0, 0, 1024, 256);
  for (let x = 0; x < 1024;) { const w = 20 + r() * 50, h = 40 + r() * 190; g.fillStyle = "#0f1730"; g.fillRect(x, 256 - h, w, h);
    for (let yy = 256 - h + 8; yy < 250; yy += 12) for (let xx = x + 4; xx < x + w - 4; xx += 9) if (r() < 0.35) { g.fillStyle = r() < 0.8 ? "#ffd98a" : "#bfe0ff"; g.fillRect(xx, yy, 4, 5); }
    x += w + 2; }
});
const woodT = () => tex("az_wood", 512, 512, (g, r) => {
  g.fillStyle = "#7a4a28"; g.fillRect(0, 0, 512, 512);
  for (let i = 0; i < 70; i++) { g.strokeStyle = `rgba(${r() < 0.5 ? "50,25,10" : "160,100,60"},0.35)`; g.lineWidth = 2 + r() * 3; g.beginPath(); const y = r() * 512; g.moveTo(0, y); g.bezierCurveTo(170, y + (r() - 0.5) * 30, 340, y + (r() - 0.5) * 30, 512, y + (r() - 0.5) * 20); g.stroke(); }
});
const letterT = () => tex("az_letter", 600, 800, (g, r) => D.letterTex(g, 600, 800, r));
const folderT = () => tex("az_folder", 512, 400, (g, r) => { g.fillStyle = "#d8b878"; g.fillRect(0, 0, 512, 400); speckle(g, r, 512, 400, 300, 0.06); g.fillStyle = "#fbf6e8"; g.fillRect(40, 60, 180, 40); g.fillStyle = "#c0392b"; g.fillRect(300, 250, 160, 70); g.fillStyle = "#d8b878"; g.fillRect(312, 262, 136, 46); });
const fileT = () => tex("az_files", 512, 512, (g, r) => { g.fillStyle = "#e9e2cf"; g.fillRect(0, 0, 512, 512); g.fillStyle = "#3a4a6a"; for (let y = 40; y < 480; y += 30) g.fillRect(40, y, 200 + r() * 220, 8); });
const panelT = () => tex("az_wpanel", 256, 256, (g) => {
  g.fillStyle = "#8a929c"; g.fillRect(0, 0, 256, 256);
  for (let y = 30; y < 240; y += 26) { g.fillStyle = "#1a1e26"; g.fillRect(24, y, 208, 12); g.fillStyle = "#b9c0c8"; g.fillRect(24, y + 12, 208, 3); }
  g.strokeStyle = "#4a525c"; g.lineWidth = 10; g.strokeRect(6, 6, 244, 244);
  for (const [x, y] of [[16, 16], [240, 16], [16, 240], [240, 240]]) { g.fillStyle = "#4a525c"; g.beginPath(); g.arc(x, y, 6, 0, 7); g.fill(); }
});

// ---------------- the world ----------------
export class World {
  root = new THREE.Group();
  private sets = {} as Record<SetName, THREE.Group>;
  private sun = new THREE.DirectionalLight("#ffffff", 2.6);
  private sky: THREE.Mesh; private skyMat: THREE.ShaderMaterial;
  private fog = new THREE.Fog("#14204a", 30, 260);
  private pool = new Pool();
  private actors: Actor[] = []; private fxs: Fx[] = []; private ai = 0; private fi = 0;
  // block
  private grille!: THREE.Mesh; private ventHole!: THREE.Mesh; private bedLump!: THREE.Mesh; private cellLamp!: THREE.Mesh;
  private sideWalls: THREE.Object3D[] = []; private frontBars: THREE.Object3D[] = []; private f = 0; private upperTier!: THREE.Group; private raft!: THREE.Mesh; private beam!: THREE.Mesh;
  // bay
  private searchBeams: THREE.Mesh[] = []; private bayRaft!: THREE.Group; private boats: THREE.Group[] = []; private stars!: THREE.Points; private moon!: THREE.Mesh;
  private water!: THREE.Mesh; private moonPath!: THREE.Mesh; private city!: THREE.Mesh;
  // desk
  private letter!: THREE.Mesh; private envelope!: THREE.Mesh; private folderTop!: THREE.Group; private deskLamp!: THREE.Mesh;

  constructor() {
    const R = this.root;
    this.skyMat = new THREE.ShaderMaterial({
      uniforms: { c0: { value: new THREE.Color() }, c1: { value: new THREE.Color() }, c2: { value: new THREE.Color() }, c3: { value: new THREE.Color() }, c4: { value: new THREE.Color() }, e: { value: new THREE.Vector4() } },
      vertexShader: "varying vec3 vP; void main(){ vP = normalize(position); gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }",
      fragmentShader: `uniform vec3 c0, c1, c2, c3, c4; uniform vec4 e; varying vec3 vP;
        void main(){ float el = asin(clamp(normalize(vP).y, -1.0, 1.0));
          vec3 c = mix(c0, c1, smoothstep(0.0, e.x, el)); c = mix(c, c2, smoothstep(e.x, e.y, el)); c = mix(c, c3, smoothstep(e.y, e.z, el)); c = mix(c, c4, smoothstep(e.z, e.w, el));
          gl_FragColor = vec4(c, 1.0); }`,
      side: THREE.BackSide, depthWrite: false, fog: false,
    });
    this.sky = new THREE.Mesh(new THREE.SphereGeometry(2000, 48, 24), this.skyMat); this.sky.renderOrder = -2; this.sky.frustumCulled = false; this.sky.layers.set(NOINK); R.add(this.sky);
    this.sun.castShadow = true; this.sun.shadow.mapSize.set(2048, 2048); R.add(this.sun, this.sun.target);
    for (let i = 0; i < 12; i++) { const a = new Actor(R); poolify(a.mat, "card"); this.actors.push(a); }
    for (let i = 0; i < 36; i++) this.fxs.push(new Fx(R));
    this.buildBlock(); this.buildBay(); this.buildDesk();
  }

  // ================= CELLBLOCK =================
  private buildBlock() {
    const S = this.sets.block = new THREE.Group(); this.root.add(S);
    const fl = mesh(new THREE.PlaneGeometry(60, 40), lam("floor", { map: floorT() }), S, 0, 0, 0, false); fl.rotation.x = -Math.PI / 2;
    const cw = lam("cellwall", { map: cellWallT() }), bars = col("#3a4048"), barsLight = col("#59616c");
    const barG = new THREE.CylinderGeometry(0.018, 0.018, 2.4, 6);
    const cellSide = (sd: number, tier: number, i: number, detail: boolean, parent: THREE.Object3D) => {
      const cx = i * 1.6, y0 = tier * 2.7, zf = sd * 1.6, zb = sd * 4.3, zm = (zf + zb) / 2, d = Math.abs(zb - zf);
      // dividing wall (between this cell and the next, at cx + 0.8) and ceiling slab
      const div = mesh(box(0.14, 2.6, d), cw, parent, cx + 0.8, y0 + 1.3, zm); if (tier === 0 && sd < 0 && Math.abs(i) <= 2) this.sideWalls.push(div);
      mesh(box(1.6, 0.14, d + 0.2), col("#a9b19c"), parent, cx, y0 + 2.63, zm + sd * 0.1);
      // back wall (with the vent opening for the detailed cells)
      if (!detail) mesh(box(1.6, 2.6, 0.3), cw, parent, cx, y0 + 1.3, zb + sd * 0.15);
      else {
        // hole 0.46 x 0.4 centred at (cx+0.35, 0.25)
        const hx = cx + 0.35, hw = 0.46, hh = 0.42, zc = zb + sd * 0.15;
        mesh(box(1.6, 2.6 - hh - 0.04, 0.3), cw, parent, cx, (hh + 0.04) + (2.6 - hh - 0.04) / 2, zc);
        mesh(box(0.04, hh + 0.04, 0.3), cw, parent, cx - 0.8 + 0.02, (hh + 0.04) / 2, zc);
        const lw = hx - hw / 2 - (cx - 0.8); mesh(box(lw, hh + 0.04, 0.3), cw, parent, cx - 0.8 + lw / 2, (hh + 0.04) / 2, zc);
        const rw = cx + 0.8 - (hx + hw / 2); mesh(box(rw, hh + 0.04, 0.3), cw, parent, hx + hw / 2 + rw / 2, (hh + 0.04) / 2, zc);
        mesh(box(hw, 0.04, 0.3), cw, parent, hx, 0.02, zc);
        // furniture: bed, mattress, blanket, pillow, sink, toilet, shelf, little table, cup
        mesh(box(0.7, 0.08, 2.0), col("#4a4f58"), parent, cx - 0.42, 0.4, zm + sd * 0.25);
        for (const dz of [-0.9, 0.9]) mesh(box(0.06, 0.4, 0.06), col("#3a3f48"), parent, cx - 0.72, 0.2, zm + sd * 0.25 + dz);
        mesh(box(0.66, 0.1, 1.96), col("#d9d4c2"), parent, cx - 0.42, 0.49, zm + sd * 0.25);
        mesh(box(0.5, 0.12, 0.3), col("#f1efe6"), parent, cx - 0.42, 0.59, zb - sd * 0.35);
        mesh(box(0.72, 0.06, 1.3), lam("blanket", { map: blanketT() }), parent, cx - 0.42, 0.57, zm - sd * 0.05);
        mesh(box(0.44, 0.06, 0.34), col("#f1f0ea"), parent, hx, 0.84, zb - sd * 0.17);
        mesh(box(0.44, 0.12, 0.04), col("#f1f0ea"), parent, hx, 0.78, zb - sd * 0.32);
        mesh(box(0.36, 0.02, 0.24), col("#b9c2cc"), parent, hx, 0.875, zb - sd * 0.18, false);
        mesh(new THREE.CylinderGeometry(0.018, 0.018, 0.12, 8), col("#c9ced6"), parent, hx, 0.93, zb - sd * 0.04);
        const tap = mesh(new THREE.CylinderGeometry(0.014, 0.014, 0.1, 8), col("#c9ced6"), parent, hx, 0.98, zb - sd * 0.09); tap.rotation.x = Math.PI / 2;
        mesh(new THREE.CylinderGeometry(0.025, 0.025, 0.5, 8), col("#9aa1ad"), parent, hx + 0.12, 0.55, zb - sd * 0.04);
        mesh(new THREE.CylinderGeometry(0.18, 0.15, 0.42, 14), col("#e8e8e2"), parent, cx + 0.55, 0.21, zf + sd * 0.45);
        mesh(box(0.9, 0.04, 0.24), col("#7a5a3a"), parent, cx + 0.2, 1.6, zb - sd * 0.12);
        for (let k = 0; k < 4; k++) mesh(box(0.06, 0.2 + (k % 2) * 0.05, 0.15), col(["#c0392b", "#2c6fb0", "#3a8a50", "#d8a03a"][k]), parent, cx - 0.1 + k * 0.08, 1.72, zb - sd * 0.12);
      }
      // front bars + crossbars
      const fb: THREE.Object3D[] = [];
      for (let b = 0; b < 12; b++) { const o = mesh(barG, b % 2 ? bars : barsLight, parent, cx - 0.72 + b * 0.13, y0 + 1.2, zf, false); o.castShadow = true; fb.push(o); }
      for (const yy of [0.05, 1.0, 2.35]) fb.push(mesh(box(1.6, 0.06, 0.05), bars, parent, cx, y0 + yy, zf));
      if (detail) this.frontBars.push(...fb);
    };
    const cells = new THREE.Group(); S.add(cells);
    this.upperTier = new THREE.Group(); S.add(this.upperTier);
    for (const sd of [-1, 1]) for (let i = -7; i <= 7; i++) {
      cellSide(sd, 0, i, sd < 0 && Math.abs(i) <= 1, cells);
      cellSide(sd, 1, i, false, this.upperTier);
    }
    // catwalk on tier 2, railing, stairs; outer block walls, high windows, ceiling, hanging lamps
    for (const sd of [-1, 1]) {
      mesh(box(24, 0.1, 0.9), col("#5a616c"), this.upperTier, 0, 2.65, sd * 1.15);
      mesh(box(24, 0.05, 0.05), col("#3a4048"), this.upperTier, 0, 3.65, sd * 0.72);
      for (let i = -12; i <= 12; i++) mesh(box(0.04, 1.0, 0.04), col("#3a4048"), this.upperTier, i, 3.15, sd * 0.72, false);
      mesh(box(24, 6.2, 0.3), col("#a9b19c"), S, 0, 8.5, sd * 4.45);
    }
    const ceil = mesh(box(30, 0.3, 14), col("#3c4658"), S, 0, 11.6, 0, false); void ceil;
    for (let i = -3; i <= 3; i++) { const sk = mesh(box(2.2, 0.05, 1.6), basic("#3a5a9a", 1.2), S, i * 4, 11.43, 0, false); sk.layers.set(NOINK); }
    for (let i = -6; i <= 6; i++) {
      const x = i * 2.4; mesh(new THREE.CylinderGeometry(0.008, 0.008, 6.0, 4), col("#22252c"), S, x, 8.5, 0, false);
      const sh = mesh(new THREE.ConeGeometry(0.22, 0.18, 14, 1, true), col("#2f3a4a"), S, x, 5.45, 0, false); sh.rotation.x = Math.PI;
      const bulb = mesh(new THREE.SphereGeometry(0.07, 10, 8), basic(WARM, 3.5), S, x, 5.38, 0, false); bulb.layers.set(NOINK);
    }
    // utility corridor behind Frank's row: back side wall, pipes, valves, a bulb; pipes up to the top of the block
    mesh(box(14, 9, 0.3), lam("util", { map: utilT() }), S, 0, 4.5, -5.9);
    const pipeM = col("#7a5a46"), pipeM2 = col("#5e6670");
    for (const [x, rr, m] of [[-2.2, 0.06, pipeM], [-1.0, 0.045, pipeM2], [0.95, 0.07, pipeM], [1.3, 0.04, pipeM2], [2.6, 0.06, pipeM2]] as [number, number, THREE.Material][])
      mesh(new THREE.CylinderGeometry(rr, rr, 8.4, 10), m, S, x, 4.2, -5.6);
    for (const [y, rr] of [[1.6, 0.05], [2.4, 0.07], [5.2, 0.05]] as [number, number][]) { const p = mesh(new THREE.CylinderGeometry(rr, rr, 14, 10), pipeM2, S, 0, y, -5.65); p.rotation.z = Math.PI / 2; }
    for (const x of [-2.2, 0.95, 2.6]) mesh(new THREE.TorusGeometry(0.09, 0.025, 6, 12), col("#c0392b"), S, x, 1.2, -5.5);
    const ub = mesh(new THREE.SphereGeometry(0.06, 10, 8), basic(WARM, 3), S, 0.6, 2.2, -5.2, false); ub.layers.set(NOINK);
    // raft deck on top of the cell rows (y = 8.2): floor, junk, skylight
    const deck = mesh(box(8, 0.12, 4.2), col("#5c626c"), S, 0, 8.14, -2.6, false); void deck;
    for (let i = 0; i < 6; i++) mesh(box(0.4 + (i % 3) * 0.2, 0.3, 0.4), col(["#7a5a3a", "#5a616c", "#8a6a4a"][i % 3]), S, -3.4 + i * 1.3, 8.35, -4.2 + (i % 2) * 0.3);
    this.raft = mesh(box(2.0, 0.24, 1.0), lam("raft", { map: raftT() }), S, -0.1, 8.32, -2.4); this.raft.geometry.translate(0, 0.12, 0);
    // fake grille over Frank's vent; the vent hole from the utility side (dark); lamp in the cell; flashlight beam
    this.grille = mesh(box(0.44, 0.38, 0.02), lam("grille", { map: panelT() }), S, 0.35, 0.23, -4.29, false);
    this.ventHole = mesh(box(0.44, 0.4, 0.02), basic("#05070c"), S, 0.35, 0.23, -4.58, false); this.ventHole.layers.set(NOINK);
    this.bedLump = mesh(new THREE.SphereGeometry(0.3, 14, 10), lam("blanket", { map: blanketT() }), S, -0.42, 0.62, -3.15); this.bedLump.scale.set(1, 0.45, 2.2);
    this.cellLamp = mesh(new THREE.SphereGeometry(0.05, 10, 8), basic(WARM, 4), S, 0.55, 0.92, -2.7, false); this.cellLamp.layers.set(NOINK);
    const bg = new THREE.ConeGeometry(0.9, 4, 24, 1, true); bg.translate(0, -2, 0); bg.rotateX(-Math.PI / 2);
    this.beam = new THREE.Mesh(bg, new THREE.MeshBasicMaterial({ color: new THREE.Color(1.0, 0.9, 0.6), transparent: true, opacity: 0.16, blending: THREE.AdditiveBlending, depthWrite: false, side: THREE.DoubleSide }));
    this.beam.layers.set(NOINK); this.beam.visible = false; S.add(this.beam);
  }

  // ================= BAY =================
  private buildBay() {
    const S = this.sets.bay = new THREE.Group(); this.root.add(S);
    this.water = mesh(new THREE.PlaneGeometry(4000, 4000), lam("water", { map: waterT(), color: "#ffffff" }), S, 0, 0, 0, false); this.water.rotation.x = -Math.PI / 2;
    const rm = lam("rock", { map: rockT() }), r = rng(5);
    // island: rocky base + terraces, prison building on top, lighthouse, guard tower, water tower
    for (let i = 0; i < 40; i++) { const g = new THREE.DodecahedronGeometry(3 + r() * 6, 0); const m = mesh(g, rm, S, -30 + r() * 60, 1 + r() * 4, -18 + r() * 36); m.scale.y = 0.6 + r() * 0.6; m.rotation.set(r() * 3, r() * 3, r() * 3); }
    mesh(box(56, 8, 34), rm, S, 0, 4, 0);
    mesh(box(44, 4, 26), col("#7a8a5a"), S, 0, 9.5, 0);
    const pm = lam("prison", { map: prisonT() });
    mesh(box(34, 12, 14), [col("#d8d4c4"), col("#d8d4c4"), col("#6a6a70"), col("#d8d4c4"), pm, pm] as any, S, 0, 17.5, 0);
    mesh(box(34.6, 0.6, 14.6), col("#8a8a88"), S, 0, 23.8, 0);
    const lh = mesh(new THREE.CylinderGeometry(1.0, 1.3, 16, 12), col("#e8e4d8"), S, 21, 19.5, 6); void lh;
    mesh(new THREE.CylinderGeometry(1.5, 1.5, 1.6, 12), col("#2a3040"), S, 21, 28.3, 6);
    const lamp1 = mesh(new THREE.SphereGeometry(0.9, 12, 8), basic("#fff2c0", 5), S, 21, 28.3, 6, false); lamp1.layers.set(NOINK);
    mesh(box(3, 8, 3), col("#6a5a4a"), S, -24, 15, 10); mesh(box(4.5, 2.6, 4.5), col("#3a3f48"), S, -24, 20.3, 10); mesh(box(5, 0.4, 5), col("#2a2f38"), S, -24, 21.8, 10);
    const lamp2 = mesh(new THREE.SphereGeometry(0.6, 10, 8), basic("#fff2c0", 5), S, -24, 20.5, 12.3, false); lamp2.layers.set(NOINK);
    mesh(new THREE.CylinderGeometry(2.4, 2.4, 4, 14), col("#b8b4a8"), S, -12, 27, -4); for (const [dx, dz] of [[-1.6, -1.6], [1.6, -1.6], [-1.6, 1.6], [1.6, 1.6]]) mesh(box(0.25, 6, 0.25), col("#6a6a70"), S, -12 + dx, 22, -4 + dz);
    // searchlight beams (lighthouse + tower)
    for (const [x, y, z, len] of [[21, 28.3, 6, 160], [-24, 20.5, 12.3, 120]] as [number, number, number, number][]) {
      const g = new THREE.ConeGeometry(len * 0.09, len, 24, 1, true); g.translate(0, -len / 2, 0); g.rotateX(-Math.PI / 2);
      const b = new THREE.Mesh(g, new THREE.MeshBasicMaterial({ color: new THREE.Color(1, 0.95, 0.75), transparent: true, opacity: 0.12, blending: THREE.AdditiveBlending, depthWrite: false, side: THREE.DoubleSide, fog: false }));
      b.position.set(x, y, z); b.layers.set(NOINK); S.add(b); this.searchBeams.push(b);
    }
    // city on the far shore + bridge-ish lights
    const city = new THREE.Mesh(new THREE.PlaneGeometry(900, 220), new THREE.MeshBasicMaterial({ map: cityT(), transparent: true, fog: false, color: new THREE.Color(1.3, 1.3, 1.3) }));
    city.position.set(380, 70, -500); city.lookAt(0, 70, 0); city.layers.set(NOINK); S.add(city); this.city = city;
    // moon + reflection + stars
    this.moon = mesh(new THREE.CircleGeometry(26, 32), basic("#fff4d8", 2.2), S, 300, 300, -900, false); this.moon.lookAt(0, 0, 0); this.moon.layers.set(NOINK);
    (this.moon.material as THREE.MeshBasicMaterial).fog = false;
    this.moonPath = new THREE.Mesh(new THREE.PlaneGeometry(30, 900), new THREE.MeshBasicMaterial({ color: new THREE.Color(1, 0.95, 0.8), transparent: true, opacity: 0.18, blending: THREE.AdditiveBlending, depthWrite: false, fog: false }));
    this.moonPath.rotation.x = -Math.PI / 2; this.moonPath.layers.set(NOINK); S.add(this.moonPath);
    const sp: number[] = []; for (let i = 0; i < 700; i++) { const a = r() * 6.28, e = 0.15 + r() * 1.3; sp.push(1500 * Math.cos(e) * Math.cos(a), 1500 * Math.sin(e), 1500 * Math.cos(e) * Math.sin(a)); }
    const sg = new THREE.BufferGeometry(); sg.setAttribute("position", new THREE.Float32BufferAttribute(sp, 3));
    this.stars = new THREE.Points(sg, new THREE.PointsMaterial({ color: new THREE.Color(1.6, 1.6, 1.8), size: 2.2, sizeAttenuation: false, fog: false })); this.stars.layers.set(NOINK); S.add(this.stars);
    // raft with three men (cards posed per frame), paddles are fx
    this.bayRaft = new THREE.Group(); S.add(this.bayRaft);
    mesh(box(4.2, 0.4, 1.8), lam("raft", { map: raftT() }), this.bayRaft, 0, 0.2, 0);
    // search boats
    for (let i = 0; i < 3; i++) {
      const b = new THREE.Group(); S.add(b); this.boats.push(b);
      mesh(box(7, 1.4, 2.6), col("#f1efe6"), b, 0, 0.7, 0); mesh(box(2.6, 1.6, 2.0), col(i === 0 ? "#c0392b" : "#2c5aa0"), b, -0.8, 2.1, 0);
      mesh(box(7.1, 0.3, 2.7), col(i === 0 ? "#c0392b" : "#2c5aa0"), b, 0, 0.45, 0);
    }
  }

  // ================= DESK =================
  private buildDesk() {
    const S = this.sets.desk = new THREE.Group(); this.root.add(S);
    mesh(box(1.8, 0.06, 1.0), lam("wood", { map: woodT() }), S, 0, 0.72, -0.1);
    for (const [dx, dz] of [[-0.85, -0.55], [0.85, -0.55], [-0.85, 0.35], [0.85, 0.35]]) mesh(box(0.06, 0.72, 0.06), col("#5a3820"), S, dx, 0.36, -0.1 + dz);
    const fl = mesh(new THREE.PlaneGeometry(12, 12), col("#3a3530"), S, 0, 0, 0, false); fl.rotation.x = -Math.PI / 2;
    mesh(box(8, 4, 0.2), col("#5a6a78"), S, 0, 2, -1.2);
    const win = mesh(box(1.4, 1.0, 0.05), basic("#16234a", 1.0), S, -0.6, 1.7, -1.08, false); win.layers.set(NOINK); void win;
    for (const dx of [-1.3, -0.6, 0.1]) mesh(box(0.05, 1.05, 0.08), col("#2a2f38"), S, dx, 1.7, -1.05);
    // lamp, files, mug, phone
    mesh(new THREE.CylinderGeometry(0.08, 0.1, 0.03, 16), col("#2a5a3a"), S, 0.55, 0.765, -0.35);
    const arm = mesh(new THREE.CylinderGeometry(0.012, 0.012, 0.42, 8), col("#2a5a3a"), S, 0.55, 0.97, -0.35); void arm;
    const sh = mesh(new THREE.ConeGeometry(0.13, 0.12, 16, 1, true), col("#2a6a44"), S, 0.48, 1.18, -0.3); sh.rotation.z = 0.5;
    this.deskLamp = mesh(new THREE.SphereGeometry(0.04, 10, 8), basic(WARM, 4), S, 0.46, 1.14, -0.28, false); this.deskLamp.layers.set(NOINK);
    for (let i = 0; i < 4; i++) { const f = mesh(box(0.34, 0.03, 0.26), lam("files", { map: fileT() }), S, -0.6 + (i % 2) * 0.03, 0.765 + i * 0.03, -0.4 + (i % 2) * 0.02); f.rotation.y = 0.1 * (i - 2); }
    mesh(new THREE.CylinderGeometry(0.045, 0.04, 0.1, 14), col("#c0392b"), S, 0.6, 0.8, 0.05);
    // letter + envelope (animated), case folder (lid opens)
    this.envelope = mesh(box(0.24, 0.006, 0.15), col("#f1e6c8"), S, 0, 0.76, 0.1);
    this.letter = mesh(new THREE.PlaneGeometry(0.24, 0.32), lam("letter", { map: letterT() }), S, 0, 0.756, 0); this.letter.rotation.x = -Math.PI / 2;
    const fm = lam("folder", { map: folderT() });
    mesh(box(0.34, 0.01, 0.26), fm, S, 0.3, 0.756, -0.05);
    this.folderTop = new THREE.Group(); this.folderTop.position.set(0.13, 0.765, -0.05); S.add(this.folderTop);
    mesh(box(0.34, 0.01, 0.26), fm, this.folderTop, 0.17, 0, 0);
    for (let i = 0; i < 3; i++) mesh(box(0.3, 0.003, 0.22), col("#f4f0e4"), S, 0.3, 0.763 + i * 0.002, -0.05);
  }

  // ---------------- helpers ----------------
  private actor(key: string, k: number, draw: (p: Pen) => void, pos: THREE.Vector3, cam: THREE.PerspectiveCamera, o: { roll?: number; mirror?: boolean; scale?: number } = {}) {
    const a = this.actors[this.ai++]; if (!a) return;
    a.r = this.pool.req(key, Math.round(600 * k), Math.round(1000 * k), k, draw);
    const m = a.mesh; m.visible = true; m.position.copy(pos);
    m.rotation.set(0, Math.atan2(cam.position.x - pos.x, cam.position.z - pos.z), 0);
    if (o.roll) m.rotateZ(o.roll);
    const s = o.scale ?? 1, h = key.length * 1.7 + this.ai * 2.3, br = 1 + 0.012 * Math.sin(this.f * 0.21 + h);
    m.scale.set(o.mirror ? -s : s, s * br, s);
    m.rotateZ(0.018 * Math.sin(this.f * 0.13 + h));
  }
  private fx(key: string, cw: number, ch: number, draw: (p: Pen) => void, pos: THREE.Vector3, w: number, h: number, cam: THREE.PerspectiveCamera, o: { rot?: number; soft?: boolean; k?: number; flat?: boolean } = {}) {
    const x = this.fxs[this.fi++]; if (!x) return;
    const k = o.k ?? 1;
    x.r = this.pool.req("fx|" + key, Math.round(cw * k), Math.round(ch * k), k, draw);
    x.use(!!o.soft);
    const m = x.mesh; m.visible = true; m.position.copy(pos); m.scale.set(w, h, 1);
    if (o.flat) { m.rotation.set(-Math.PI / 2, 0, o.rot ?? 0); } else { m.quaternion.copy(cam.quaternion); if (o.rot) m.rotateZ(o.rot); }
  }
  /** a point offset in camera space from `p` (right, up, toward camera) */
  private cs(cam: THREE.PerspectiveCamera, p: THREE.Vector3, r: number, u: number, t = 0) {
    const R = new THREE.Vector3().setFromMatrixColumn(cam.matrixWorld, 0), U = new THREE.Vector3().setFromMatrixColumn(cam.matrixWorld, 1), T = new THREE.Vector3().subVectors(cam.position, p).normalize();
    return p.clone().addScaledVector(R, r).addScaledVector(U, u).addScaledVector(T, t);
  }

  update(id: number, f: number, cam: THREE.PerspectiveCamera, scene: THREE.Scene) {
    const s = SHOTS[id - 1], L = LIGHTS[s.light];
    const c = camAt(id, f);
    cam.position.set(...c.pos); cam.up.set(0, 1, 0); cam.lookAt(...c.look); cam.rotateZ(c.roll);
    cam.fov = c.fov; cam.near = 0.03; cam.far = 4000; cam.updateProjectionMatrix(); cam.updateMatrixWorld(); cam.layers.enable(NOINK);
    const focus = V(...c.look), dist = cam.position.distanceTo(focus);
    for (const k of Object.keys(this.sets) as SetName[]) this.sets[k].visible = k === s.set;
    // light: frozen per shot, camera relative
    const c0 = camAt(id, s.a), fw = V(c0.look[0] - c0.pos[0], 0, c0.look[2] - c0.pos[2]).normalize(), right = V(-fw.z, 0, fw.x);
    const az = THREE.MathUtils.degToRad(L.az), el = THREE.MathUtils.degToRad(L.el);
    const sunDir = fw.clone().multiplyScalar(Math.cos(az) * Math.cos(el)).addScaledVector(right, Math.sin(az) * Math.cos(el)).add(V(0, Math.sin(el), 0)).normalize();
    this.sun.intensity = L.sunI;
    const Rr = THREE.MathUtils.clamp(dist * 1.3 + 3, 4, 70);
    this.sun.position.copy(focus).addScaledVector(sunDir, 200); this.sun.target.position.copy(focus);
    const sc = this.sun.shadow.camera; sc.left = -Rr; sc.right = Rr; sc.top = Rr; sc.bottom = -Rr; sc.near = 100; sc.far = 320; sc.updateProjectionMatrix();
    this.sun.shadow.bias = -0.0004; this.sun.shadow.normalBias = 0.02 * (Rr / 10);
    TONE.uLitCol.value.set(...L.lit); TONE.uShadeCol.value.set(...L.shade); TONE.uShadeLift.value.set(...L.lift);
    TONE.uLambert.value = L.lambert; TONE.uSideK.value = L.sideK; TONE.uTerm.value = L.term; TONE.uBounce.value.set(0, 0, 0); TONE.uSat.value = L.sat;
    CHAR.uCharTint.value.set(...L.charTint); CHAR.uCharShade.value = L.charShade; CHAR.uGrad.value = L.charGrad; CHAR.uBodyGrad.value = L.bodyGrad; CHAR.uSideTint.value.set(...L.sideTint);
    const su = this.skyMat.uniforms; L.sky.forEach((h, i) => untone(h, su["c" + i].value));
    const e = L.skyE.map((d) => THREE.MathUtils.degToRad(d)); su.e.value.set(e[1], e[2], e[3], e[4]);
    this.sky.position.copy(cam.position);
    untone(L.fog, this.fog.color); this.fog.near = L.near; this.fog.far = L.far; scene.fog = this.fog; scene.background = null;
    resetPools(); this.f = f;
    this.ai = 0; this.fi = 0;
    for (const a of this.actors) a.mesh.visible = false;
    for (const x of this.fxs) x.mesh.visible = false;
    if (s.set === "block") this.poseBlock(id, f, cam);
    else if (s.set === "bay") this.poseBay(id, f, cam);
    else this.poseDesk(id, f, cam);
    this.pool.flush();
    for (const a of this.actors) if (a.mesh.visible) a.bind();
    for (const x of this.fxs) if (x.mesh.visible) x.bind();
    return focus;
  }

  // ================= pose: CELLBLOCK =================
  private poseBlock(id: number, f: number, cam: THREE.PerspectiveCamera) {
    const night = id !== 1 && id !== 9;
    // hanging lamp pools along the corridor + the cell's own light
    for (let i = -1; i <= 1; i++) pool(i * 2.4, 0.5, 0.0, 3.4, WARM, night ? 0.9 : 0.3);
    if (night && id !== 5 && id !== 6) pool(0.0, 2.2, -2.6, 2.6, WARM, 0.5);
    if (!night) pool(0.0, 2.0, -1.0, 4.0, "#ffd0a0", 0.25);
    this.beam.visible = false; this.cellLamp.visible = false;
    const inCell = (cx: number, z: number) => V(cx, 0, z);
    for (const w of this.sideWalls) w.visible = !(id === 4 && f >= B.others - 10 && f < 668);
    for (const b of this.frontBars) b.visible = !(id === 4 && f >= B.others + 4 && f < B.hundred + 10);
    this.grille.visible = !(id === 7 && f >= B.squeeze - 10);
    this.ventHole.visible = id === 7;
    this.bedLump.visible = id === 1 || id === 9 || (id === 5 && f >= B.dark - 4) || (id === 7) || (id === 4 && f >= B.wait);
    this.raft.visible = id === 6;
    this.upperTier.visible = true;
    const headOnPillow = V(-0.42, 0.8, -3.82);
    if (id === 1 || id === 9) {
      // morning: the guard pokes the "sleeping" head; it rolls off and smashes on the floor
      const P = id === 1 ? { poke: B.poke, fall: B.fall, smash: B.smash } : { poke: B.poke2, fall: B.fall2, smash: B.smash2 };
      const reach = smooth((f - (P.poke - 14)) / 14);
      const gExpr: Expr = f < P.fall ? "neutral" : "shock";
      this.actor("guard_side" + gExpr + (reach > 0.99 ? "r" : "a"), 0.9, (p) => bodySide(p, GUARD, { mode: "push", pose: reach, expr: gExpr, seed: 2 }), V(0.42, 0, -3.15), cam, { mirror: true });
      if (f < P.smash) {
        const u = clamp01((f - P.fall) / (P.smash - P.fall));
        const pos = headOnPillow.clone().add(V(0.42 * u, 0.12 * Math.sin(u * Math.PI) - 0.6 * u * u, 0.5 * u));
        const nudge = f >= P.poke && f < P.fall ? 0.12 * Math.sin((f - P.poke) * 0.9) : 0;
        this.fx("head2", 400, 400, (p) => D.dummyHead(p, 2), pos, 0.3, 0.3, cam, { rot: nudge + u * 3.2 });
      } else {
        const u = clamp01((f - P.smash) / 18);
        this.fx("pieces" + Math.floor(u * 9), 500, 400, (p) => D.headPieces(p, Math.floor(u * 9) / 9), V(0.0, 0.18, -3.45), 0.8, 0.64, cam);
        if (u < 1) this.fx("puff" + Math.floor(u * 6), 300, 300, (p) => fxPuff(p, Math.floor(u * 6) / 6), V(0.0, 0.15, -3.45), 0.5, 0.5, cam, { soft: true });
      }
      return;
    }
    if (id === 2) {
      // night block: a guard strolls far down the corridor, a couple of inmates behind bars
      const gx = 5 - (f - 136) * 0.02;
      this.actor("guard_stroll" + Math.floor((f / 4) % 8), 0.6, (p) => bodyFront(p, GUARD, { mode: "stroll", phase: ((f / 4) % 8) / 8, expr: "stern", seed: 2 }), V(gx, 0, 0.3), cam);
      pool(gx, 1.0, 0.3, 2.0, WARM, 0.25);
      this.actor("inm_a", 0.6, (p) => bodyFront(p, JOHN, { mode: "stand", expr: "stern", seed: 6 }), V(-1.6, 0, -2.3), cam);
      this.actor("inm_b", 0.6, (p) => bodyFront(p, CLARENCE, { mode: "stand", expr: "neutral", seed: 7 }), V(3.2, 0, 2.3), cam);
      return;
    }
    if (id === 4) {
      // Frank's plan (stand with spoon) -> scraping at the vents (three cells) -> drill -> guard -> accordion -> empty bed?
      if (f < B.scrape) {
        const ex: Expr = f > 380 ? "grin" : "stern";
        const sp = f > B.spoon - 8;
        this.actor("frank_st" + ex + (sp ? "sp" : ""), 0.9, (p) => bodyFront(p, FRANK, { mode: "stand", expr: ex, seed: 1, prop: sp ? ["custom", 0.1, D.H.spoon] : null }), inCell(0.05, -3.1), cam);
        pool(0.1, 1.2, -2.6, 1.6, COOL, 0.25);
        return;
      }
      if (f < B.drill - 8 || (f >= 668 && f < B.loud)) {
        // scraping (or drilling) at the vent: three cells
        const drilling = f >= 668;
        const people: [number, typeof FRANK, number][] = [[0, FRANK, 1], [-1.6, JOHN, 6], [1.6, CLARENCE, 7]];
        for (const [cx, o, seed] of people) {
          const showAll = f >= B.others - 10 && !drilling;
          if (cx !== 0 && !showAll) continue;
          const ex: Expr = f > B.hundred - 10 && f < 668 && cx === 0 ? "nervous" : "stern";
          const k = 0.62 + 0.12 * Math.sin(f * (drilling ? 2.4 : 0.9) + seed), kq = Math.round(k * 10) / 10;
          const tool: any = drilling && cx === 0 ? ["custom", 0.75, D.H.drill(f % 2 ? 0.05 : 0)] : ["custom", kq, D.H.spoonVent];
          this.actor("sc" + seed + ex + (drilling ? "d" + (f % 2) : "s" + kq), 0.9, (p) => bodyFront(p, o, { mode: "sit", expr: ex, seed, prop: tool }), inCell(cx - 0.05, -3.55), cam);
          const vent = V(cx + 0.35, 0.25, -4.25);
          if (drilling && cx === 0) this.fx("noise" + Math.floor((f % 9) / 3), 300, 300, (p) => D.noise(p, (f % 9) / 9), this.cs(cam, vent, 0.1, 0.25, 0.25), 0.4, 0.4, cam);
          const dt = ((f + seed * 7) % 24) / 24;
          this.fx("dust" + Math.floor(dt * 6), 300, 300, (p) => D.dust(p, Math.floor(dt * 6) / 6), this.cs(cam, vent, 0.05, 0.0, 0.12), 0.25, 0.25, cam, { soft: false });
          pool(cx, 1.2, -3.3, 1.8, WARM, showAll ? 0.9 : 0.35);
        }
        if (f > B.hundred - 10 && f < 668) {
          const u = ((f - B.hundred) % 8) / 8;
          const fwd = new THREE.Vector3(); cam.getWorldDirection(fwd); this.fx("cal" + Math.floor(u * 4), 300, 340, (p) => D.calendar(p, Math.floor(u * 4) / 4, Math.floor(f / 8)), this.cs(cam, cam.position.clone().addScaledVector(fwd, 0.8), 0.07, 0.17, 0), 0.15, 0.17, cam);
        }
        return;
      }
      // guard in the corridor turns at the noise; then Frank plays the accordion; then the bed check
      const gExpr: Expr = f < B.accordion ? "shock" : f < B.wait ? "smile_closed" : "stern";
      const gpos = f < B.wait ? V(4.6, 0, 0.7) : V(-0.45 - (f - B.wait) * 0.002, 0, -1.05);
      const fl = f >= B.wait;
      this.actor("guard_c" + gExpr + (fl ? "fl" : ""), 0.9, (p) => bodyFront(p, GUARD, { mode: "stand", expr: gExpr, seed: 2, look: f < B.accordion ? -0.7 : 0, prop: fl ? ["custom", 0.85, D.H.flashlight] : null }), gpos, cam);
      pool(gpos.x, 1.2, gpos.z, 1.8, WARM, 0.35);
      if (f >= B.loud && f < B.accordion) this.fx("q_noise" + Math.floor((f % 9) / 3), 300, 300, (p) => D.noise(p, (f % 9) / 9), V(1.4, 0.9, -1.2), 0.6, 0.6, cam, { rot: Math.PI });
      if (f >= B.accordion - 6 && f < B.wait) {
        const sq = 0.5 + 0.5 * Math.sin(f * 0.25);
        const sqq = Math.floor(sq * 4) / 4;
        this.actor("frank_acc" + sqq, 0.9, (p) => bodyFront(p, FRANK, { mode: "stand", expr: "smile_closed", seed: 1, prop: ["custom", 0.95, D.H.accordion(sqq)] }), inCell(0.1, -2.1), cam);
        for (let i = 0; i < 3; i++) { const t = ((f * 0.03 + i / 3) % 1); this.fx("note" + i, 200, 300, (p) => fxNote(p, i % 2, "#ffd24a"), this.cs(cam, V(0.1, 1.5, -2.1), -0.3 + i * 0.3 + t * 0.2, t * 0.6, 0.2), 0.12, 0.18, cam, { rot: Math.sin(f * 0.1 + i) * 0.3 }); }
        // the drilling neighbour, hidden by the music
        this.actor("john_sit", 0.9, (p) => bodyFront(p, JOHN, { mode: "sit", expr: "stern", seed: 6 }), inCell(-1.75, -3.75), cam);
        pool(0.1, 1.2, -2.0, 1.8, WARM, 0.5);
      }
      if (f >= B.wait) {
        // flashlight sweeps the bed... Frank isn't in it (he is in the utility corridor)
        const a = -0.7 + smooth((f - B.wait) / 30) * 0.55;
        this.beam.visible = true; this.beam.position.set(gpos.x + 0.15, 1.15, gpos.z - 0.2);
        this.beam.lookAt(-0.42 + Math.sin(f * 0.05) * 0.2, 0.55, -3.3); void a;
        pool(-0.42 + Math.sin(f * 0.05) * 0.2, 0.55, -3.3, 0.9, "#fff0c0", 1.2);
        if (f > B.bedEmpty) { const u = eout((f - B.bedEmpty) / 8); this.fx("q", 240, 360, (p) => D.question(p), V(-0.45, 1.98, -1.05), 0.26 * u + 0.001, 0.39 * u + 0.001, cam); }
      }
      return;
    }
    if (id === 5) {
      // You see: soap + toothpaste + toilet paper -> blob -> painted -> hair; then lights out, the bed looks occupied
      if (f < B.dark) {
        pool(0.55, 0.95, -2.7, 1.7, WARM, 0.9);
        // Frank sits on the edge of the bed (hips on the mattress, legs in front of it) and holds each ingredient,
        // then the head he is making
        let held: any = null, key = "none";
        if (f >= B.soap && f < B.paste) { held = D.H.soap; key = "soap"; }
        else if (f >= B.paste && f < B.roll) { held = D.H.paste; key = "paste"; }
        else if (f >= B.roll && f < B.blob) { held = D.H.roll; key = "roll"; }
        else if (f >= B.blob) { const st = f < B.paint ? 0 : f < B.hair ? 1 : 2; held = D.H.head(st); key = "head" + st; }
        const ex: Expr = f < B.hair ? "stern" : "grin";
        this.actor("frank_sit5" + ex + key, 0.9, (p) => bodyFront(p, FRANK, { mode: "sit", expr: ex, seed: 1, prop: held ? ["custom", 0.55, held] : null }), V(-0.12, 0.47, -3.2), cam);
        for (const t0 of [B.soap, B.paste, B.roll, B.blob, B.paint, B.hair]) if (f >= t0 && f < t0 + 10) this.fx("spark" + t0, 500, 500, (p) => fxBurst(p, (f - t0) / 10), this.cs(cam, V(-0.12, 1.05, -3.2), 0.33, 0.0, 0.2), 0.35, 0.35, cam);
      } else {
        // dark: the dummy head on the pillow, the flashlight sweeps over it; the guard is satisfied
        this.fx("head2", 400, 400, (p) => D.dummyHead(p, 2), headOnPillow, 0.3, 0.3, cam);
        const gpos = V(-0.1, 0, -1.0);
        this.actor("guard_n", 0.9, (p) => bodyFront(p, GUARD, { mode: "stand", expr: f > 1185 ? "smile_closed" : "stern", seed: 2 }), gpos, cam);
        this.beam.visible = true; this.beam.position.set(0.05, 1.15, -1.1); this.beam.lookAt(-0.42, 0.6, -3.8);
        pool(-0.42, 0.7, -3.85, 0.8, "#fff0c0", 2.0);
        if (f > 1190) for (let i = 0; i < 3; i++) { const t = ((f - 1190) / 20 + i / 3) % 1; this.fx("z" + i, 200, 300, (p) => fxNote(p, 2, "#9fc4ff"), headOnPillow.clone().add(V(0.1 + t * 0.15, 0.2 + t * 0.4, 0)), 0.08, 0.12, cam); }
      }
      return;
    }
    if (id === 6) {
      // raincoat raft on the deck above the cells, inflated with a tiny accordion
      pool(0, 9.0, -2.4, 3.5, COOL, 0.6); pool(-1.4, 8.6, -2.0, 1.5, WARM, 0.4);
      const inf = 0.25 + 0.75 * smooth((f - B.pump) / 50);
      this.raft.scale.set(1, inf, 1);
      this.actor("john_raft", 0.8, (p) => bodyFront(p, JOHN, { mode: "stand", expr: "grin", seed: 6 }), V(-1.45, 8.2, -2.7), cam);
      this.actor("frank_raft", 0.8, (p) => bodyFront(p, FRANK, { mode: "stand", expr: "stern", seed: 1 }), V(0.1, 8.2, -3.4), cam);
      const sq = f >= B.pump - 6 ? Math.floor((0.5 + 0.5 * Math.sin(f * 0.5)) * 4) / 4 : -1;
      this.actor("clar_raft" + sq, 0.8, (p) => bodyFront(p, CLARENCE, { mode: "sit", expr: "nervous", seed: 7, prop: sq >= 0 ? ["custom", 0.7, D.H.accordion(sq, true)] : null }), V(1.35, 8.25, -2.4), cam);

      for (let i = 0; i < 4; i++) if (f < B.pump) this.fx("rc" + i, 200, 200, (p) => D.sparkle(p), V(-0.9 + i * 0.6, 8.5, -2.4), 0.06, 0.06, cam);
      return;
    }
    if (id === 7) {
      // June 11, 10 PM: the dummy is in the bed; through the vent into the utility corridor; up the pipes
      this.fx("head2", 400, 400, (p) => D.dummyHead(p, 2), headOnPillow, 0.3, 0.3, cam);
      pool(0.6, 2.2, -5.2, 2.6, WARM, 0.6);
      const men: [typeof FRANK, number, number][] = [[FRANK, 1, 0], [JOHN, 6, 10], [CLARENCE, 7, 20]];
      for (const [o, seed, d] of men) {
        const t = f - d;
        if (t < B.squeeze - 30 || f < 1386) continue;
        const out = smooth((t - (B.squeeze - 30)) / 26);          // through the hole (z -4.0 -> -5.0)
        const up = clamp01((t - B.climb) / 50);                    // climbing the pipe
        const x = 0.35 + (seed === 1 ? 0.6 : seed === 6 ? 0.0 : 1.0) * smooth((t - B.squeeze) / 20);
        const pos = V(x, -0.9 * (1 - out) + up * 6.5, -4.0 - out * 1.15);
        const climbing = up > 0;
        this.actor("esc" + seed + (climbing ? "c" : "s"), 0.9, (p) => bodyFront(p, o, { mode: climbing ? "fall" : "stand", expr: climbing ? "stern" : "nervous", seed }), pos, cam, { scale: 0.95 });
      }
      return;
    }
  }

  // ================= pose: BAY =================
  private poseBay(id: number, f: number, cam: THREE.PerspectiveCamera) {
    const day = id === 10, t = f / FPS;
    this.stars.visible = !day; this.moon.visible = !day; this.city.visible = !day; this.moonPath.visible = !day;
    this.moonPath.position.set(cam.position.x + 160, 0.05, cam.position.z - 420); this.moonPath.lookAt(this.moonPath.position.x, 10, this.moonPath.position.z); this.moonPath.rotation.x = -Math.PI / 2;
    this.searchBeams.forEach((b, i) => {
      b.visible = !day;
      const a = t * (i ? 0.5 : 0.35) + i * 2.0;
      b.lookAt(b.position.x + Math.cos(a) * 100, 0, b.position.z + Math.sin(a) * 100);
      if (!day) pool(b.position.x + Math.cos(a) * 60, 0, b.position.z + Math.sin(a) * 60, 14, "#fff0c0", 0.8);
    });
    if (!day) { pool(21, 28, 6, 8, "#fff0c0", 1.0); pool(-24, 20, 12, 6, "#fff0c0", 0.8); }
    this.bayRaft.visible = id === 8;
    this.boats.forEach((b, i) => { b.visible = day; b.position.set(-14 + i * 16 + Math.sin(t * 0.3 + i) * 3, 0, 42 - i * 6 + t * (i % 2 ? 2 : -2)); b.rotation.y = 0.4 + i; if (day) pool(b.position.x, 1, b.position.z, 4, "#ffffff", 0.0); });
    (this.water.material as any).map.offset.set(t * 0.004, t * 0.002);
    if (id === 8) {
      // down at the shore, the raft launches and paddles off into the dark
      const k = smooth((f - B.launch) / 60), x = 34 + k * 14, z = -2 - k * 6;
      this.bayRaft.position.set(x, 0.05 + 0.08 * Math.sin(t * 3), z); this.bayRaft.rotation.set(0.03 * Math.sin(t * 2), -0.5, 0.03 * Math.cos(t * 2.3));
      const men: [typeof FRANK, number, number][] = [[FRANK, 1, 1.2], [JOHN, 6, 0], [CLARENCE, 7, -1.2]];
      for (const [o, seed, dx] of men) {
        const pos = this.bayRaft.localToWorld(V(dx, -0.15, 0));
        const pad = f > B.paddle - 10, st = Math.round((0.5 + 0.5 * Math.sin(t * 4 + seed)) * 4) / 4;
        this.actor("raft" + seed + (pad ? "p" + st : ""), 0.7, (p) => bodyFront(p, o, { mode: "sit", expr: f > B.paddle ? "stern" : "nervous", seed, prop: pad ? ["custom", 0.4 + 0.4 * st, D.H.paddle(0.5 - 0.6 * st)] : null }), pos, cam);
      }
      pool(x, 1, z, 4, COOL, 0.4);
      // darkness creeps in as they paddle away
      this.fog.far = 260 - 200 * smooth((f - 1500) / 36); this.fog.near = 10;
    }
    if (id === 10) {
      for (let i = 0; i < 3; i++) { const u = ((f * 0.35 + i * 4) % 12) / 12; const fwd = new THREE.Vector3(); cam.getWorldDirection(fwd); const base = cam.position.clone().addScaledVector(fwd, 12); this.fx("calb" + Math.floor(u * 4), 300, 340, (p) => D.calendar(p, Math.floor(u * 4) / 4, i), this.cs(cam, base, -1.6 + i * 1.6, 3.2 - (i % 2) * 0.6, 0), 1.3, 1.47, cam, { rot: (i - 1) * 0.15 }); }
    }
    void cam;
  }

  // ================= pose: DESK =================
  private poseDesk(id: number, f: number, cam: THREE.PerspectiveCamera) {
    pool(0.3, 0.8, -0.1, 0.9, WARM, 1.1);
    const u = eout((f - B.letter) / 16);
    this.envelope.position.set(-0.05 + 0.3 * (1 - u), 0.76, 0.18 - 0.1 * u); this.envelope.rotation.y = 0.3 * (1 - u) - 0.2;
    const open = smooth((f - B.unfold) / 18);
    this.letter.visible = f >= B.unfold - 2; this.letter.scale.set(1, Math.max(0.01, open), 1); this.letter.position.set(-0.12, 0.758, -0.02 + 0.16 * (1 - open) * 0.5);
    // the case folder opens on "Still open"
    const o = smooth((f - B.open) / 12);
    this.folderTop.rotation.z = o * 2.6;
    // a cop's hand? keep it simple: the officer stands behind the desk (soft)
    this.actor("cop", 0.8, (p) => bodyFront(p, COP, { mode: "stand", expr: f < 1765 ? "neutral" : "shock", seed: 3 }), V(-0.2, 0, -0.75), cam, { scale: 1.0 });
    void id;
  }
}
