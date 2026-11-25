// BA 5390 world: five small sets (hangar, sky, runway, cockpit, hospital) built at the origin and shown one at a
// time, a two-tone lit BAC One-Eleven style jet, flat lit character cards and effect cards. update(id, f, cam) poses
// everything for shot id at frame f (pure function of id + f).
import * as THREE from "three";
import { TONE, CHAR, twoTone, untone } from "../bridge/shade";
import { NOINK } from "../bridge/ink";
import { Pool, Actor, Fx, SU } from "../bridge/cast";
import { Pen, bodyFront, bodySide, fxBurst, fxPuff, fxStars, fxCreak, Expr } from "../bridge/toon";
import { cloudHD, ctex, rep, grassHD, rng } from "../bridge/paint";
import { CAPTAIN, FO, NIGEL, CREW2, CREW3, MECH } from "./outfits";
import * as D from "./chars";
import {
  FPS, SHOTS, ShotDef, camAt, smooth, clamp01, lin, BANG, LIFT, OUT, GRAB, SLIDE, CREW, RED, CARD_IN, TOUCH, planeX, planeY, planePitch,
} from "./story";

type C3 = [number, number, number];
type LightPreset = {
  az: number; el: number; lit: C3; shade: C3; lift: C3; lambert: number; sideK: number; term: number;
  charTint: C3; charShade: number; charGrad: number; bodyGrad: number; sideTint: C3;
  sky: string[]; skyE: number[]; fog: string; fogNear: number; fogFar: number; sunCol: string; sunI: number; sat: number;
};
const LIGHTS: Record<"day" | "night" | "indoor", LightPreset> = {
  day: {
    az: 70, el: 45, lit: [1.58, 1.5, 1.33], shade: [0.34, 0.33, 0.42], lift: [0.05, 0.06, 0.11], lambert: 0.35, sideK: 0.84, term: 0.2,
    charTint: [1.0, 0.95, 0.93], charShade: 0.86, charGrad: 0.07, bodyGrad: 0.2, sideTint: [0.92, 0.9, 0.96],
    sky: ["#c4daf2", "#a6c6ee", "#74a6e2", "#548fdc", "#3672cc"], skyE: [0, 3, 8, 16, 40],
    fog: "#c4daf2", fogNear: 60, fogFar: 2600, sunCol: "#fff3e0", sunI: 2.8, sat: 1.08,
  },
  night: {
    az: 40, el: 62, lit: [1.55, 1.25, 0.85], shade: [0.16, 0.17, 0.32], lift: [0.03, 0.04, 0.1], lambert: 0.4, sideK: 0.8, term: 0.25,
    charTint: [1.0, 0.86, 0.7], charShade: 0.8, charGrad: 0.1, bodyGrad: 0.25, sideTint: [0.8, 0.8, 0.95],
    sky: ["#1b2546", "#16203f", "#121a36", "#0e142c", "#0a0f22"], skyE: [0, 3, 8, 16, 40],
    fog: "#1a2240", fogNear: 25, fogFar: 140, sunCol: "#ffd9a0", sunI: 2.8, sat: 1.05,
  },
  indoor: {
    az: 55, el: 35, lit: [1.5, 1.45, 1.35], shade: [0.42, 0.42, 0.52], lift: [0.06, 0.07, 0.12], lambert: 0.3, sideK: 0.86, term: 0.2,
    charTint: [1.0, 0.97, 0.95], charShade: 0.9, charGrad: 0.06, bodyGrad: 0.18, sideTint: [0.93, 0.92, 0.97],
    sky: ["#c4daf2", "#a6c6ee", "#74a6e2", "#548fdc", "#3672cc"], skyE: [0, 3, 8, 16, 40],
    fog: "#c4daf2", fogNear: 60, fogFar: 2600, sunCol: "#fff6ea", sunI: 2.6, sat: 1.05,
  },
};

const V = (x: number, y: number, z: number) => new THREE.Vector3(x, y, z);
const mats = new Map<string, THREE.Material>();
const lam = (key: string, p: THREE.MeshLambertMaterialParameters) => {
  let m = mats.get(key) as THREE.MeshLambertMaterial | undefined;
  if (!m) { m = twoTone(new THREE.MeshLambertMaterial(p)); mats.set(key, m); }
  return m;
};
const col = (c: string) => lam("c" + c, { color: c });
const mesh = (g: THREE.BufferGeometry, m: THREE.Material, parent: THREE.Object3D, x = 0, y = 0, z = 0, shadow = true) => {
  const o = new THREE.Mesh(g, m); o.position.set(x, y, z); o.castShadow = shadow; o.receiveShadow = true; parent.add(o); return o;
};
const box = (w: number, h: number, d: number) => new THREE.BoxGeometry(w, h, d);

// ---------------- painted textures ----------------
const concrete = () => ctex("ba_concrete", 1024, 1024, (g, r) => {
  g.fillStyle = "#8d8f96"; g.fillRect(0, 0, 1024, 1024);
  for (let i = 0; i < 900; i++) { g.fillStyle = `rgba(${r() < 0.5 ? "60,60,70" : "200,200,210"},${0.05 + r() * 0.06})`; const s = 4 + r() * 30; g.fillRect(r() * 1024, r() * 1024, s, s); }
  g.strokeStyle = "rgba(40,40,50,0.6)"; g.lineWidth = 4; for (let k = 0; k <= 4; k++) { g.beginPath(); g.moveTo(k * 256, 0); g.lineTo(k * 256, 1024); g.moveTo(0, k * 256); g.lineTo(1024, k * 256); g.stroke(); }
  g.fillStyle = "#e3c23a"; g.fillRect(0, 600, 1024, 26);
});
const asphalt = () => ctex("ba_asphalt", 512, 2048, (g, r) => {
  g.fillStyle = "#4b4e57"; g.fillRect(0, 0, 512, 2048);
  for (let i = 0; i < 2500; i++) { g.fillStyle = `rgba(${r() < 0.5 ? "30,30,36" : "120,122,130"},${0.08 + r() * 0.1})`; const s = 2 + r() * 8; g.fillRect(r() * 512, r() * 2048, s, s); }
  g.fillStyle = "#f2f0e8"; for (let y = 0; y < 2048; y += 512) g.fillRect(244, y + 60, 24, 300);
  g.fillRect(14, 0, 14, 2048); g.fillRect(484, 0, 14, 2048);
});
const fields = () => ctex("ba_fields", 2048, 2048, (g, r) => {
  const cols = ["#7fae4e", "#9cc25a", "#6a9a45", "#b9c46a", "#c9b46a", "#88b860", "#5f8f3f", "#a8c870"];
  g.fillStyle = "#7fae4e"; g.fillRect(0, 0, 2048, 2048);
  for (let y = 0; y < 2048;) {
    const h = 90 + r() * 200;
    for (let x = 0; x < 2048;) { const w = 110 + r() * 260; g.fillStyle = cols[Math.floor(r() * cols.length)]; g.fillRect(x, y, w + 1, h + 1); g.fillStyle = "rgba(60,90,40,0.6)"; g.fillRect(x, y, w, 5); g.fillRect(x, y, 5, h); x += w; }
    y += h;
  }
  for (let i = 0; i < 260; i++) { g.fillStyle = "#3f6e33"; g.beginPath(); g.arc(r() * 2048, r() * 2048, 8 + r() * 16, 0, 7); g.fill(); }
  g.fillStyle = "#c8c3b8"; for (let i = 0; i < 40; i++) { const x = r() * 2048, y = r() * 2048; for (let k = 0; k < 12; k++) g.fillRect(x + r() * 60, y + r() * 60, 10, 8); }
});
const panelTex = () => ctex("ba_panel", 1024, 512, (g, r) => {
  g.fillStyle = "#2f3440"; g.fillRect(0, 0, 1024, 512);
  for (let i = 0; i < 26; i++) {
    const x = 60 + (i % 13) * 72, y = 110 + Math.floor(i / 13) * 150;
    g.fillStyle = "#111318"; g.beginPath(); g.arc(x, y, 30, 0, 7); g.fill();
    g.strokeStyle = "#c9ced6"; g.lineWidth = 4; g.stroke();
    g.strokeStyle = i % 5 === 0 ? "#ffb347" : "#f5f5f5"; g.lineWidth = 5; g.beginPath(); g.moveTo(x, y); const a = r() * 6.28; g.lineTo(x + 22 * Math.cos(a), y + 22 * Math.sin(a)); g.stroke();
  }
  for (let i = 0; i < 2; i++) { const x = 330 + i * 300; g.fillStyle = "#0a1a2c"; g.fillRect(x, 330, 120, 110); g.fillStyle = "#3aa1ff"; g.fillRect(x, 330, 120, 55); g.fillStyle = "#8a5a2a"; g.fillRect(x, 385, 120, 55); }
  for (let i = 0; i < 40; i++) { g.fillStyle = ["#e04a3a", "#3ad06a", "#ffd24a", "#cfd4dc"][i % 4]; g.fillRect(40 + r() * 940, 20 + r() * 40, 10, 10); }
});
const overheadTex = () => ctex("ba_overhead", 512, 512, (g, r) => {
  g.fillStyle = "#3a404c"; g.fillRect(0, 0, 512, 512);
  for (let i = 0; i < 70; i++) { g.fillStyle = ["#d8dce4", "#e04a3a", "#9aa1ad"][i % 3]; g.fillRect(20 + (i % 10) * 48, 30 + Math.floor(i / 10) * 66, 16, 26); }
});
const drawersTex = () => ctex("ba_drawers", 512, 512, (g) => {
  g.fillStyle = "#c23b32"; g.fillRect(0, 0, 512, 512);
  for (let i = 0; i < 8; i++) {
    const y = 14 + i * 62; g.fillStyle = "#d24a40"; g.fillRect(14, y, 484, 52);
    g.strokeStyle = "#5a1a18"; g.lineWidth = 5; g.strokeRect(14, y, 484, 52);
    g.fillStyle = "#e8e8e8"; g.fillRect(200, y + 18, 112, 14); g.strokeRect(200, y + 18, 112, 14);
  }
});
const hangarWall = () => ctex("ba_hwall", 1024, 512, (g, r) => {
  g.fillStyle = "#3b4256"; g.fillRect(0, 0, 1024, 512);
  for (let x = 0; x < 1024; x += 64) { g.fillStyle = x % 128 ? "#363c50" : "#40475c"; g.fillRect(x, 0, 60, 512); g.fillStyle = "rgba(20,22,35,0.7)"; g.fillRect(x + 60, 0, 4, 512); }
});
const hospWall = () => ctex("ba_hosp", 512, 512, (g) => {
  g.fillStyle = "#cfe5d6"; g.fillRect(0, 0, 512, 512); g.fillStyle = "#b9d4c3"; g.fillRect(0, 330, 512, 182); g.fillStyle = "#8fb3a0"; g.fillRect(0, 322, 512, 12);
});

// ---------------- the jet ----------------
const R0 = 1.72;
const PROFILE: [number, number][] = [[0.05, -14.2], [0.45, -13.8], [1.0, -12], [1.45, -10], [1.68, -7.5], [R0, -5], [R0, 9.4], [1.66, 10.9], [1.48, 12.2], [1.18, 13.2], [0.75, 13.95], [0.3, 14.35], [0.0, 14.45]];
export const radiusAt = (x: number) => { const p = PROFILE; for (let i = 1; i < p.length; i++) if (x <= p[i][1]) { const k = (x - p[i - 1][1]) / (p[i][1] - p[i - 1][1]); return p[i - 1][0] + (p[i][0] - p[i - 1][0]) * k; } return 0; };
/** a point on the skin: axial x, angle th from the top (+y) toward -z (th > 0 = captain's / left side) */
const skin = (x: number, th: number, out = 0) => { const r = radiusAt(x) + out; return V(x, r * Math.cos(th), -r * Math.sin(th)); };

type Plane = { g: THREE.Group; body: THREE.Group; paneL: THREE.Mesh; paneLFly: THREE.Mesh; gear: THREE.Group; bolts: THREE.InstancedMesh; boltMats: THREE.MeshLambertMaterial; interior: THREE.Group; hole: THREE.Mesh };
const skinPatch = (x0: number, x1: number, t0: number, t1: number, out: number, nx = 6, nt = 6) => {
  const pos: number[] = [], uv: number[] = [], idx: number[] = [];
  for (let i = 0; i <= nx; i++) for (let j = 0; j <= nt; j++) {
    const p = skin(x0 + ((x1 - x0) * i) / nx, t0 + ((t1 - t0) * j) / nt, out); pos.push(p.x, p.y, p.z); uv.push(i / nx, j / nt);
  }
  for (let i = 0; i < nx; i++) for (let j = 0; j < nt; j++) { const a = i * (nt + 1) + j, b = a + nt + 1; idx.push(a, b, a + 1, b, b + 1, a + 1); }
  const g = new THREE.BufferGeometry(); g.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3)); g.setAttribute("uv", new THREE.Float32BufferAttribute(uv, 2)); g.setIndex(idx); g.computeVertexNormals();
  return g;
};
const WS = { x0: 12.55, x1: 13.35, t0: 0.42, t1: 1.02 };
/** fuselage skin with the cockpit window openings cut out (fragment discard in local space), so the glass is see-through */
let FUS: THREE.MeshLambertMaterial | null = null;
const fuselageMat = () => {
  if (FUS) return FUS;
  const m = twoTone(new THREE.MeshLambertMaterial({ color: "#ffffff", vertexColors: true, side: THREE.DoubleSide }));
  const prev = m.onBeforeCompile;
  m.onBeforeCompile = (sh, r) => {
    prev.call(m, sh, r);
    sh.vertexShader = sh.vertexShader.replace("#include <common>", "#include <common>\nvarying vec3 vLoc;").replace("#include <begin_vertex>", "#include <begin_vertex>\nvLoc = position;");
    sh.fragmentShader = sh.fragmentShader.replace("#include <common>", "#include <common>\nvarying vec3 vLoc;")
      .replace("void main() {", `void main() {
        float th = abs(atan(vLoc.z, vLoc.y));
        if (vLoc.x > ${WS.x0.toFixed(3)} && vLoc.x < ${WS.x1.toFixed(3)} && th > ${WS.t0.toFixed(3)} && th < ${WS.t1.toFixed(3)}) discard;
        if (vLoc.x > 11.7 && vLoc.x < 12.45 && th > 0.6 && th < 1.15) discard;`);
  };
  m.customProgramCacheKey = () => "fusCut1";
  FUS = m; return m;
}; // captain's front windscreen panel (left); FO's mirrored
const buildPlane = (withInterior: boolean): Plane => {
  const g = new THREE.Group(), body = new THREE.Group(); g.add(body);
  // fuselage (lathe around +x) with livery by vertex colour: pearl top, red cheat line, midnight-blue belly
  const lg = new THREE.LatheGeometry(PROFILE.map(([r, y]) => new THREE.Vector2(r, y)), 64);
  lg.rotateZ(-Math.PI / 2);
  const pa = lg.attributes.position, cols: number[] = [], cTop = new THREE.Color("#eef0f3"), cRed = new THREE.Color("#c8202f"), cNavy = new THREE.Color("#1f2d5c"), cNose = new THREE.Color("#2a3346"), c = new THREE.Color();
  for (let i = 0; i < pa.count; i++) {
    const x = pa.getX(i), y = pa.getY(i), z = pa.getZ(i), r = Math.hypot(y, z) || 1, s = y / r;
    if (x > 14.05) c.copy(cNose); else if (s > 0.02) c.copy(cTop); else if (s > -0.14) c.copy(cRed); else c.copy(cNavy);
    if (x < -11.5 && s > 0.3) c.copy(cNavy);
    cols.push(c.r, c.g, c.b);
  }
  lg.setAttribute("color", new THREE.Float32BufferAttribute(cols, 3));
  const fus = mesh(lg, fuselageMat(), body);
  fus.name = "fuselage";
  // passenger windows
  const winG = box(0.05, 0.3, 0.22), winM = col("#202a3c");
  const wins = new THREE.InstancedMesh(winG, winM, 64); let n = 0; const m4 = new THREE.Matrix4(), q = new THREE.Quaternion();
  for (let i = 0; i < 32; i++) for (const sd of [1, -1]) {
    const x = -8.6 + i * 0.56, th = sd * 1.33, p = skin(x, th, 0.005);
    q.setFromEuler(new THREE.Euler(sd * (Math.PI / 2 - 1.33) * -1, sd * Math.PI / 2, 0, "YXZ"));
    m4.compose(p, q, V(1, 1, 1)); wins.setMatrixAt(n++, m4);
  }
  wins.instanceMatrix.needsUpdate = true; body.add(wins);
  // forward door outline (left)
  const door = mesh(skinPatch(9.6, 10.6, 0.95, 1.75, 0.006, 3, 4), col("#d9dce2"), body); door.castShadow = false;
  // cockpit glass: two front panels + two side windows per side
  const glass = new THREE.MeshLambertMaterial({ color: "#3d6a9e", transparent: true, opacity: 0.35, depthWrite: false });
  twoTone(glass);
  const frameM = col("#1c2230");
  const paneR = mesh(skinPatch(WS.x0, WS.x1, -WS.t1, -WS.t0, 0.012), glass, body); paneR.castShadow = false;
  const paneL = mesh(skinPatch(WS.x0, WS.x1, WS.t0, WS.t1, 0.012), glass, body); paneL.castShadow = false;
  for (const sd of [1, -1]) {
    const side = mesh(skinPatch(11.7, 12.45, sd * 0.6, sd * 1.15, 0.012, 4, 4), glass, body); side.castShadow = false;
    // frames (dark posts) around the panes
    void frameM;
  }
  // the hole left by the captain's panel (dark interior), shown after the bang
  const hole = mesh(skinPatch(WS.x0, WS.x1, WS.t0, WS.t1, -0.01), col("#141822"), body); hole.visible = false; hole.castShadow = false;
  // the flying panel (own mesh, centred at the origin of its group so it can tumble)
  const pg = skinPatch(WS.x0, WS.x1, WS.t0, WS.t1, 0.012); const ctr = new THREE.Vector3(); pg.computeBoundingBox(); pg.boundingBox!.getCenter(ctr); pg.translate(-ctr.x, -ctr.y, -ctr.z);
  const paneLFly = mesh(pg, glass, g); paneLFly.userData.home = ctr.clone(); paneLFly.visible = false;
  // bolts around the captain's panel (exterior heads)
  const boltMats = new THREE.MeshLambertMaterial({ color: "#c9ced6" }); twoTone(boltMats);
  const bolts = new THREE.InstancedMesh(new THREE.CylinderGeometry(0.018, 0.018, 0.012, 6), boltMats, 90);
  bolts.instanceColor = new THREE.InstancedBufferAttribute(new Float32Array(90 * 3).fill(1), 3);
  let bi = 0; const up = V(0, 1, 0);
  const ring: THREE.Vector3[] = [];
  for (let i = 0; i < 26; i++) ring.push(skin(WS.x0 + ((WS.x1 - WS.x0) * i) / 25, WS.t0 - 0.035, 0.02));
  for (let i = 0; i < 19; i++) ring.push(skin(WS.x1 + 0.03, WS.t0 + ((WS.t1 - WS.t0) * i) / 18, 0.02));
  for (let i = 0; i < 26; i++) ring.push(skin(WS.x1 - ((WS.x1 - WS.x0) * i) / 25, WS.t1 + 0.035, 0.02));
  for (let i = 0; i < 19; i++) ring.push(skin(WS.x0 - 0.03, WS.t1 - ((WS.t1 - WS.t0) * i) / 18, 0.02));
  for (const p of ring) { const nrm = V(0, p.y, p.z).normalize(); q.setFromUnitVectors(up, nrm); m4.compose(p, q, V(1, 1, 1)); bolts.setMatrixAt(bi++, m4); }
  bolts.instanceMatrix.needsUpdate = true; bolts.castShadow = false; body.add(bolts);
  // wings (low, swept), tailplane, fin
  const wingShape = new THREE.Shape(); wingShape.moveTo(3.2, 0); wingShape.lineTo(-3.0, 0); wingShape.lineTo(-6.6, 13.5); wingShape.lineTo(-4.6, 13.5); wingShape.closePath();
  for (const sd of [1, -1]) {
    const wg = new THREE.ExtrudeGeometry(wingShape, { depth: 0.22, bevelEnabled: false }); wg.rotateX(Math.PI / 2); if (sd < 0) wg.scale(1, 1, -1);
    const w = mesh(wg, col("#d9dde4"), body, 0, -0.95, 0); w.rotation.x = sd * 0.05;
    // engines on the rear fuselage
    const nac = mesh(new THREE.CylinderGeometry(0.62, 0.55, 4.6, 24), col("#e3e6eb"), body, -8.4, 0.75, sd * 2.55); nac.rotation.z = Math.PI / 2;
    const lip = mesh(new THREE.TorusGeometry(0.58, 0.07, 8, 24), col("#9aa1ad"), body, -6.1, 0.75, sd * 2.55); lip.rotation.y = Math.PI / 2;
    const fan = mesh(new THREE.CircleGeometry(0.56, 24), col("#22262f"), body, -6.08, 0.75, sd * 2.55); fan.rotation.y = Math.PI / 2;
    mesh(box(1.8, 0.18, 1.1), col("#c9ced6"), body, -8.4, 0.75, sd * 1.75);
    const tp = new THREE.Shape(); tp.moveTo(-11.6, 0); tp.lineTo(-14.0, 0); tp.lineTo(-15.4, 4.8); tp.lineTo(-14.2, 4.8); tp.closePath();
    const tg = new THREE.ExtrudeGeometry(tp, { depth: 0.12, bevelEnabled: false }); tg.rotateX(Math.PI / 2); if (sd < 0) tg.scale(1, 1, -1);
    mesh(tg, col("#d9dde4"), body, -0.9, 6.25, 0);
  }
  const fin = new THREE.Shape(); fin.moveTo(-10.6, 1.0); fin.lineTo(-14.2, 1.0); fin.lineTo(-15.6, 6.3); fin.lineTo(-13.4, 6.3); fin.closePath();
  const fg = new THREE.ExtrudeGeometry(fin, { depth: 0.24, bevelEnabled: false }); fg.translate(0, 0, -0.12);
  mesh(fg, col("#1f2d5c"), body);
  const finStripe = new THREE.Shape(); finStripe.moveTo(-12.0, 3.6); finStripe.lineTo(-13.6, 3.6); finStripe.lineTo(-14.1, 5.2); finStripe.lineTo(-12.6, 4.2); finStripe.closePath();
  const fsg = new THREE.ExtrudeGeometry(finStripe, { depth: 0.26, bevelEnabled: false }); fsg.translate(0, 0, -0.13);
  mesh(fsg, col("#c8202f"), body).castShadow = false;
  // landing gear
  const gear = new THREE.Group(); body.add(gear);
  const wheel = new THREE.CylinderGeometry(0.42, 0.42, 0.3, 18); wheel.rotateX(Math.PI / 2);
  for (const sd of [1, -1]) for (const dz of [-0.2, 0.2]) mesh(wheel, col("#22252c"), gear, -0.6, -2.18, sd * 2.4 + dz);
  for (const sd of [1, -1]) mesh(box(0.14, 1.3, 0.14), col("#9aa1ad"), gear, -0.6, -1.5, sd * 2.4);
  mesh(wheel, col("#22252c"), gear, 10.6, -2.18, 0); mesh(box(0.12, 1.1, 0.12), col("#9aa1ad"), gear, 10.6, -1.6, 0);
  // seen-through interior of the nose: dark cabin box + instrument glow
  const interior = new THREE.Group(); body.add(interior);
  if (withInterior) {
    const shell = mesh(new THREE.SphereGeometry(1.25, 24, 16), lam("noseIn", { color: "#3a4256", side: THREE.BackSide }), interior, 11.9, 0.35, 0, false); shell.scale.set(1.3, 1, 1.05);
    mesh(box(0.35, 0.3, 1.6), col("#2f3440"), interior, 12.7, 0.25, 0, false);
  }
  const curve = new THREE.CatmullRomCurve3([V(11.6, 2.2, -0.9), V(6, 4.2, -2.4), V(0, 3.4, -3.0), V(-5.6, 1.4, -2.7)]);
  const danger = new THREE.Mesh(new THREE.TubeGeometry(curve, 80, 0.16, 10), new THREE.MeshBasicMaterial({ color: new THREE.Color(1.4, 0.2, 0.15) }));
  const tipDir = curve.getTangent(1), tip = new THREE.Mesh(new THREE.ConeGeometry(0.5, 1.1, 16), danger.material);
  tip.position.copy(curve.getPoint(1)); tip.quaternion.setFromUnitVectors(V(0, 1, 0), tipDir); danger.add(tip);
  danger.visible = false; g.add(danger); g.userData.danger = danger;
  return { g, body, paneL, paneLFly, gear, bolts, boltMats, interior, hole };
};

// ---------------- the world ----------------
type SetName = ShotDef["set"];
export class World {
  root = new THREE.Group();
  private sets = {} as Record<SetName, THREE.Group>;
  private sun = new THREE.DirectionalLight("#fff0d6", 2.6);
  private hemi = new THREE.HemisphereLight("#cfe6ff", "#6c5c8c", 0.6);
  private sky: THREE.Mesh; private skyMat: THREE.ShaderMaterial;
  private fog = new THREE.Fog("#c4daf2", 60, 2600);
  private pool = new Pool();
  private actors: Actor[] = []; private fxs: Fx[] = [];
  private ai = 0; private fi = 0;
  private air: Plane; private ground: Plane; private hangarPlane: Plane;
  private clouds: { m: THREE.Mesh; base: THREE.Vector3; w: number }[] = [];
  private fieldsMesh: THREE.Mesh;
  private ckRightWall: THREE.Object3D[] = []; private ckPaneL: THREE.Mesh; private ckHole: THREE.Mesh;
  private ckClouds: THREE.Mesh[] = [];
  private hospWin: THREE.Mesh;

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
    this.sky = new THREE.Mesh(new THREE.SphereGeometry(3000, 48, 24), this.skyMat);
    this.sky.renderOrder = -1; this.sky.frustumCulled = false; this.sky.layers.set(NOINK); R.add(this.sky);
    this.sun.castShadow = true; this.sun.shadow.mapSize.set(2048, 2048);
    R.add(this.sun, this.sun.target, this.hemi);
    for (let i = 0; i < 14; i++) { this.actors.push(new Actor(R)); }
    for (let i = 0; i < 40; i++) { this.fxs.push(new Fx(R)); }

    // ===== SKY set =====
    const sky = this.sets.sky = new THREE.Group(); R.add(sky);
    this.air = buildPlane(true); sky.add(this.air.g); this.air.gear.visible = false;
    const cm = [0, 1, 2, 3, 4, 5].map((k) => cloudHD(k + 11));
    const r = rng(77);
    for (let i = 0; i < 70; i++) {
      const m = new THREE.Mesh(new THREE.PlaneGeometry(1, 1), new THREE.MeshBasicMaterial({ map: cm[i % 6], color: new THREE.Color(1.08, 1.08, 1.08), transparent: true, depthWrite: false, fog: true }));
      m.layers.set(NOINK); sky.add(m);
      const below = i < 46;
      const base = V(-600 + r() * 1200, below ? -40 - r() * 160 : 30 + r() * 120, -700 + r() * 1400);
      if (i < 12) base.set(-120 + r() * 240, -14 - r() * 30, -90 + r() * 180); // near clouds for parallax
      this.clouds.push({ m, base, w: 40 + r() * 120 });
    }
    this.fieldsMesh = new THREE.Mesh(new THREE.PlaneGeometry(9000, 9000), lam("fields", { map: rep(fields(), 6, 6) }));
    this.fieldsMesh.rotation.x = -Math.PI / 2; this.fieldsMesh.position.y = -520; this.fieldsMesh.receiveShadow = false; sky.add(this.fieldsMesh);

    // ===== RUNWAY set =====
    const rw = this.sets.runway = new THREE.Group(); R.add(rw);
    const grassM = lam("grassRW", { map: rep(grassHD(), 160, 160) });
    const gr = mesh(new THREE.PlaneGeometry(3000, 3000), grassM, rw, 0, 0, 0, false); gr.rotation.x = -Math.PI / 2;
    const runway = mesh(new THREE.PlaneGeometry(1600, 45), lam("asph", { map: rep(asphalt(), 1, 1) }), rw, 300, 0.02, 0, false); runway.rotation.x = -Math.PI / 2;
    (runway.material as THREE.MeshLambertMaterial).map!.rotation = Math.PI / 2; (runway.material as THREE.MeshLambertMaterial).map!.repeat.set(0.25, 25);
    for (let i = 0; i < 24; i++) mesh(box(28 + r() * 40, 8 + r() * 14, 18 + r() * 20), col(["#cfc7b8", "#b9c3cf", "#d8d2c6", "#9aa7b8"][i % 4]), rw, -200 + i * 45 + r() * 20, 5, -150 - r() * 120);
    for (let i = 0; i < 60; i++) { const t = mesh(new THREE.SphereGeometry(4 + r() * 4, 12, 8), col(["#4f7f3a", "#5d8c42", "#466f34"][i % 3]), rw, -400 + r() * 1300, 4, -110 - r() * 300); t.scale.y = 0.85; }
    mesh(box(14, 22, 14), col("#d8d2c6"), rw, 140, 11, -90); mesh(box(18, 5, 18), col("#2f4a6a"), rw, 140, 24.5, -90);
    this.ground = buildPlane(false); rw.add(this.ground.g);

    // ===== HANGAR set (night) =====
    const hg = this.sets.hangar = new THREE.Group(); R.add(hg);
    const fl = mesh(new THREE.PlaneGeometry(80, 80), lam("conc", { map: rep(concrete(), 8, 8) }), hg, 0, 0, 0, false); fl.rotation.x = -Math.PI / 2;
    const wallM = lam("hwall", { map: rep(hangarWall(), 4, 1) });
    mesh(box(80, 16, 0.5), wallM, hg, 0, 8, -18); mesh(box(0.5, 16, 80), wallM, hg, -24, 8, 0); mesh(box(80, 0.5, 80), col("#262b3c"), hg, 0, 16, 0, false);
    for (let i = 0; i < 6; i++) { const l = mesh(box(3, 0.2, 0.6), new THREE.MeshBasicMaterial({ color: new THREE.Color(3, 2.6, 1.8) }), hg, -12 + i * 6, 15.6, -3, false); l.layers.set(NOINK); }
    this.hangarPlane = buildPlane(true); hg.add(this.hangarPlane.g);
    this.hangarPlane.g.position.set(-17.4, 2.6, -7.5); this.hangarPlane.g.rotation.y = 0.35;
    this.hangarPlane.paneL.visible = false; this.hangarPlane.hole.visible = true;
    // tool cabinet with an open drawer, a work lamp, the new windscreen panel on a stand
    const cab = mesh(box(1.1, 1.15, 0.55), lam("drawers", { map: drawersTex() }), hg, -0.55, 0.575, -0.6);
    mesh(box(1.14, 0.06, 0.6), col("#3a3f4a"), hg, -0.55, 1.18, -0.6);
    const dr = mesh(box(0.9, 0.12, 0.45), col("#d24a40"), hg, -0.55, 0.98, -0.18);
    mesh(box(0.84, 0.02, 0.4), col("#2b2e36"), hg, -0.55, 1.045, -0.18, false);
    const bm = new THREE.InstancedMesh(new THREE.CylinderGeometry(0.012, 0.012, 0.09, 6), col("#c9ced6"), 40); const m4 = new THREE.Matrix4(), q = new THREE.Quaternion();
    for (let i = 0; i < 40; i++) { q.setFromEuler(new THREE.Euler(Math.PI / 2, (i * 2.3) % 3.1, 0)); m4.compose(V(-0.9 + (i % 10) * 0.075, 1.07, -0.32 + Math.floor(i / 10) * 0.09), q, V(1, 1, 1)); bm.setMatrixAt(i, m4); }
    hg.add(bm); void cab; void dr;
    const stand = mesh(box(0.08, 1.0, 0.08), col("#3a3f4a"), hg, 1.6, 0.5, -1.6); void stand;
    const glassStand = new THREE.Mesh(box(0.9, 0.7, 0.03), lam("glassStand", { color: "#7fa6d6", transparent: true, opacity: 0.55 }));
    glassStand.position.set(1.6, 1.25, -1.6); glassStand.rotation.set(-0.2, 0.4, 0); hg.add(glassStand);
    const lamp = mesh(new THREE.ConeGeometry(0.22, 0.3, 16, 1, true), col("#e3b23c"), hg, 0.1, 2.6, -0.4); lamp.rotation.x = Math.PI;
    const bulb = mesh(new THREE.SphereGeometry(0.1, 12, 8), new THREE.MeshBasicMaterial({ color: new THREE.Color(6, 5, 3.5) }), hg, 0.1, 2.48, -0.4, false); bulb.layers.set(NOINK);
    mesh(box(0.04, 2.6, 0.04), col("#3a3f4a"), hg, 0.1, 1.3, -0.75);
    // a ladder by the nose
    for (const dz of [-0.25, 0.25]) mesh(box(0.06, 3.2, 0.06), col("#e3b23c"), hg, -3.6, 1.6, -3.0 + dz);
    for (let i = 0; i < 8; i++) mesh(box(0.05, 0.05, 0.5), col("#e3b23c"), hg, -3.6, 0.3 + i * 0.38, -3.0);

    // ===== COCKPIT set =====
    const ck = this.sets.cockpit = new THREE.Group(); R.add(ck);
    const ckFloor = mesh(box(4.2, 0.1, 2.8), col("#3a3f4a"), ck, -0.3, -0.05, 0, false); void ckFloor;
    const under = mesh(new THREE.PlaneGeometry(40, 40), col("#2a2f3a"), ck, 0, -0.12, 0, false); under.rotation.x = -Math.PI / 2;
    const wallC = col("#c9cdd6"), trim = col("#8f96a3");
    mesh(box(4.2, 2.1, 0.1), wallC, ck, -0.3, 1.05, -1.35); // captain's side wall
    const rwall = mesh(box(4.2, 2.1, 0.1), wallC, ck, -0.3, 1.05, 1.35); this.ckRightWall.push(rwall);
    mesh(box(4.2, 0.12, 2.8), col("#b8bdc8"), ck, -0.3, 2.06, 0, false);
    mesh(box(0.1, 2.1, 0.9), wallC, ck, -2.4, 1.05, -0.95); mesh(box(0.1, 2.1, 0.9), wallC, ck, -2.4, 1.05, 0.95); // back wall with a door gap
    mesh(box(0.1, 0.25, 1.0), wallC, ck, -2.4, 1.95, 0);
    mesh(box(3.0, 2.1, 1.0), lam("corr", { color: "#59606e", side: THREE.BackSide }), ck, -3.95, 1.05, 0, false);
    // instrument panel + glareshield + pedestal
    const panel = mesh(box(0.3, 0.62, 2.3), lam("panel", { color: "#ffffff", map: panelTex() }), ck, 0.95, 0.76, 0);
    void panel;
    mesh(box(0.42, 0.08, 2.4), col("#22252c"), ck, 0.98, 1.1, 0);
    mesh(box(0.6, 0.62, 0.2), col("#353a46"), ck, 0.35, 0.31, 0);
    for (const dz of [-0.07, 0.07]) mesh(box(0.05, 0.22, 0.04), col("#cfd4dc"), ck, 0.45, 0.72, dz);
    // overhead panel
    const ov = mesh(box(0.9, 0.12, 1.2), lam("overhead", { color: "#ffffff", map: overheadTex() }), ck, 0.75, 1.95, 0, false); ov.rotation.z = -0.25; this.ckRightWall.push(ov);
    // seats
    for (const dz of [-0.4, 0.4]) {
      const seat = [mesh(box(0.5, 0.12, 0.48), col("#5a4a3a"), ck, -0.2, 0.48, dz), mesh(box(0.12, 0.95, 0.5), col("#5a4a3a"), ck, -0.52, 1.0, dz),
        mesh(box(0.08, 0.5, 0.06), col("#3a3f4a"), ck, -0.2, 0.22, dz)];
      for (const sx of [-1, 1]) seat.push(mesh(box(0.36, 0.06, 0.06), col("#6a5a4a"), ck, -0.2, 0.75, dz + sx * 0.27));
      if (dz > 0) this.ckRightWall.push(...seat);
    }
    // windscreen: frame posts and the four panes
    const frameC = col("#2a2f3a");
    const front = (z0: number, z1: number) => { const gq = new THREE.PlaneGeometry(Math.abs(z1 - z0), 0.62); gq.rotateY(-Math.PI / 2); gq.rotateZ(0.5); return gq; };
    const ckGlass = new THREE.MeshLambertMaterial({ color: "#a8c8ea", transparent: true, opacity: 0.18, depthWrite: false, side: THREE.DoubleSide }); twoTone(ckGlass);
    this.ckPaneL = mesh(front(-1.0, -0.06), ckGlass, ck, 1.42, 1.42, -0.53, false);
    mesh(front(0.06, 1.0), ckGlass, ck, 1.42, 1.42, 0.53, false).castShadow = false;
    this.ckHole = mesh(front(-1.0, -0.06), new THREE.MeshBasicMaterial({ visible: false }), ck, 1.42, 1.42, -0.53, false);
    for (const dz of [-1.08, 0, 1.08]) { const p = mesh(box(0.07, 0.7, 0.08), frameC, ck, 1.42, 1.42, dz); p.rotation.z = 0.5; }
    mesh(box(0.1, 0.08, 2.3), frameC, ck, 1.56, 1.13, 0); mesh(box(0.1, 0.08, 2.3), frameC, ck, 1.27, 1.7, 0);
    for (const sd of [-1, 1]) { const sw = mesh(box(0.9, 0.5, 0.04), ckGlass, ck, 0.7, 1.45, sd * 1.3, false); sw.castShadow = false; if (sd > 0) this.ckRightWall.push(sw); }
    mesh(box(0.3, 2.1, 0.1), trim, ck, 1.6, 1.05, -1.3);
    this.ckRightWall.push(mesh(box(0.3, 2.1, 0.1), trim, ck, 1.6, 1.05, 1.3));
    mesh(box(0.2, 0.9, 2.6), col("#c9cdd6"), ck, 1.55, 0.45, 0);
    // clouds outside the cockpit (seen through the glass), streaming back
    for (let i = 0; i < 10; i++) {
      const m = new THREE.Mesh(new THREE.PlaneGeometry(1, 1), new THREE.MeshBasicMaterial({ map: cm[i % 6], color: new THREE.Color(1.1, 1.1, 1.1), transparent: true, depthWrite: false, fog: false }));
      m.layers.set(NOINK); ck.add(m); this.ckClouds.push(m);
    }

    // ===== HOSPITAL set =====
    const hs = this.sets.hospital = new THREE.Group(); R.add(hs);
    const hf = mesh(new THREE.PlaneGeometry(12, 12), col("#d9d4c8"), hs, 0, 0, 0, false); hf.rotation.x = -Math.PI / 2;
    mesh(box(12, 3.2, 0.2), lam("hosp", { map: rep(hospWall(), 3, 1) }), hs, 0, 1.6, -1.4);
    this.hospWin = mesh(box(1.4, 1.0, 0.05), new THREE.MeshBasicMaterial({ color: new THREE.Color(0.75, 0.9, 1.25) }), hs, -1.1, 1.9, -1.28, false);
    this.hospWin.layers.set(NOINK);
    for (const dx of [-0.73, 0.73]) mesh(box(0.08, 1.12, 0.1), col("#f4f4f4"), hs, -1.1 + dx, 1.9, -1.25);
    mesh(box(1.56, 0.08, 0.1), col("#f4f4f4"), hs, -1.1, 2.44, -1.25); mesh(box(1.56, 0.08, 0.1), col("#f4f4f4"), hs, -1.1, 1.36, -1.25);
    // bed: frame, mattress, blanket over the legs, pillow
    mesh(box(1.1, 0.5, 2.1), col("#f2f2f2"), hs, 0, 0.25, -0.2);
    mesh(box(1.12, 0.9, 0.08), col("#c9ced6"), hs, 0, 0.75, -1.25);
    mesh(box(1.12, 0.25, 1.3), col("#6c98c8"), hs, 0, 0.62, 0.25); // blanket
    mesh(box(0.7, 0.18, 0.4), col("#ffffff"), hs, 0, 0.62, -0.95);
    mesh(box(0.5, 0.65, 0.45), col("#d9dce2"), hs, 0.95, 0.33, -0.7); // bedside table
    const flowers = mesh(new THREE.SphereGeometry(0.13, 12, 8), col("#e25a7a"), hs, 0.95, 0.85, -0.7); void flowers;
    mesh(new THREE.CylinderGeometry(0.06, 0.05, 0.18, 12), col("#7fa6d6"), hs, 0.95, 0.72, -0.7);
  }

  // ---------------- per-frame helpers ----------------
  private actor(key: string, k: number, draw: (p: Pen) => void, pos: THREE.Vector3, cam: THREE.PerspectiveCamera, o: { roll?: number; mirror?: boolean; scale?: number; face?: THREE.Vector3; flatUp?: boolean } = {}) {
    const a = this.actors[this.ai++]; if (!a) return;
    a.r = this.pool.req(key, Math.round(600 * k), Math.round(1000 * k), k, draw);
    const m = a.mesh; m.visible = true; m.position.copy(pos);
    const t = o.face ?? cam.position;
    m.rotation.set(0, Math.atan2(t.x - pos.x, t.z - pos.z), 0);
    if (o.roll) m.rotateZ(o.roll);
    const s = o.scale ?? 1; m.scale.set(o.mirror ? -s : s, s, s);
  }
  private fx(key: string, cw: number, ch: number, draw: (p: Pen) => void, pos: THREE.Vector3, w: number, h: number, cam: THREE.PerspectiveCamera, o: { rot?: number; soft?: boolean; face?: THREE.Vector3; k?: number } = {}) {
    const x = this.fxs[this.fi++]; if (!x) return;
    const k = o.k ?? 1;
    x.r = this.pool.req("fx|" + key, Math.round(cw * k), Math.round(ch * k), k, draw);
    x.use(!!o.soft);
    const m = x.mesh; m.visible = true; m.position.copy(pos); m.scale.set(w, h, 1);
    m.quaternion.copy(cam.quaternion); if (o.rot) m.rotateZ(o.rot);
  }

  update(id: number, f: number, cam: THREE.PerspectiveCamera, scene: THREE.Scene) {
    const s = SHOTS[id - 1], L = LIGHTS[s.light];
    const c = camAt(id, f);
    cam.position.set(...c.pos); cam.up.set(0, 1, 0); cam.lookAt(...c.look); cam.rotateZ(c.roll);
    cam.fov = c.fov; cam.near = 0.05; cam.far = 6000; cam.updateProjectionMatrix(); cam.updateMatrixWorld();
    cam.layers.enable(NOINK);
    const focus = V(...c.look), dist = cam.position.distanceTo(focus);
    for (const k of Object.keys(this.sets) as SetName[]) this.sets[k].visible = k === s.set;
    // ---- light: sun camera-relative (az from the shot's first camera forward), frozen per shot ----
    const c0 = camAt(id, s.a), fw = V(c0.look[0] - c0.pos[0], 0, c0.look[2] - c0.pos[2]).normalize();
    const az = THREE.MathUtils.degToRad(L.az), el = THREE.MathUtils.degToRad(L.el);
    const right = V(-fw.z, 0, fw.x);
    const sunDir = fw.clone().multiplyScalar(Math.cos(az) * Math.cos(el)).addScaledVector(right, Math.sin(az) * Math.cos(el)).add(V(0, Math.sin(el), 0)).normalize();
    this.sun.color.set(L.sunCol); this.sun.intensity = L.sunI;
    const Rr = THREE.MathUtils.clamp(dist * 1.2 + 4, 4, 60);
    this.sun.position.copy(focus).addScaledVector(sunDir, 200); this.sun.target.position.copy(focus);
    const sc = this.sun.shadow.camera; sc.left = -Rr; sc.right = Rr; sc.top = Rr; sc.bottom = -Rr; sc.near = 100; sc.far = 320; sc.updateProjectionMatrix();
    this.sun.shadow.bias = -0.0004; this.sun.shadow.normalBias = 0.02 * (Rr / 12);
    TONE.uLitCol.value.set(...L.lit); TONE.uShadeCol.value.set(...L.shade); TONE.uShadeLift.value.set(...L.lift);
    TONE.uLambert.value = L.lambert; TONE.uSideK.value = L.sideK; TONE.uTerm.value = L.term; TONE.uBounce.value.set(0, 0, 0); TONE.uSat.value = L.sat;
    CHAR.uCharTint.value.set(...L.charTint); CHAR.uCharShade.value = L.charShade; CHAR.uGrad.value = L.charGrad; CHAR.uBodyGrad.value = L.bodyGrad; CHAR.uSideTint.value.set(...L.sideTint);
    const su = this.skyMat.uniforms; L.sky.forEach((h, i) => untone(h, su["c" + i].value));
    const e = L.skyE.map((d) => THREE.MathUtils.degToRad(d)); su.e.value.set(e[1], e[2], e[3], e[4]);
    this.sky.position.copy(cam.position);
    untone(L.fog, this.fog.color); this.fog.near = L.fogNear; this.fog.far = L.fogFar; scene.fog = this.fog; scene.background = null;
    this.hemi.intensity = 0.4;
    // ---- reset cards ----
    this.ai = 0; this.fi = 0;
    for (const a of this.actors) a.mesh.visible = false;
    for (const x of this.fxs) x.mesh.visible = false;
    // ---- per set ----
    if (s.set === "sky") this.poseSky(id, f, cam);
    else if (s.set === "runway") this.poseRunway(id, f, cam);
    else if (s.set === "hangar") this.poseHangar(id, f, cam);
    else if (s.set === "cockpit") this.poseCockpit(id, f, cam);
    else this.poseHospital(id, f, cam);
    this.pool.flush();
    for (const a of this.actors) if (a.mesh.visible) a.bind();
    for (const x of this.fxs) if (x.mesh.visible) x.bind();
    return focus;
  }

  // ======== SKY ========
  private poseSky(id: number, f: number, cam: THREE.PerspectiveCamera) {
    const P = this.air, t = f / FPS;
    (P.g.userData.danger as THREE.Mesh).visible = false;
    // gentle flight motion
    P.g.position.set(0, 0.25 * Math.sin(t * 0.9), 0); P.g.rotation.set(0.04 * Math.sin(t * 0.6), 0, (id === 4 ? 0.12 : 0.02) + 0.01 * Math.sin(t * 0.7));
    P.body.scale.set(1, 1, 1);
    // clouds stream backwards (plane flies +x at ~110 m/s -> scaled for the eye)
    const speed = id === 4 ? 40 : 60;
    for (const cl of this.clouds) {
      let x = cl.base.x - speed * t; x = ((x + 700) % 1400 + 1400) % 1400 - 700;
      cl.m.position.set(x, cl.base.y + (id === 4 ? 30 : 0), cl.base.z); cl.m.scale.set(cl.w, cl.w / 2, 1);
      cl.m.lookAt(cam.position.x, cl.m.position.y, cam.position.z);
    }
    const blown = f >= BANG;
    P.paneL.visible = !blown; P.hole.visible = blown;
    P.bolts.visible = id === 11 || (id === 2 && false);
    P.paneLFly.visible = false;
    const wsCtr = P.paneLFly.userData.home as THREE.Vector3;
    const seatCap = V(12.05, 0.12, -0.45);
    if (id === 2 || id === 4) {
      // captain + FO behind the glass, seen through the windscreen
      this.actor("cap_sit", 0.7, (p) => bodyFront(p, CAPTAIN_CAP, { mode: "sit", expr: id === 2 && f > 175 ? "smile_closed" : "neutral", seed: 3 }), P.g.localToWorld(seatCap.clone()), cam, { scale: 0.9 });
      this.actor("fo_sit", 0.6, (p) => bodyFront(p, FO, { mode: "sit", expr: "neutral", seed: 5 }), P.g.localToWorld(V(12.05, 0.12, 0.45)), cam, { scale: 0.9 });
    }
    if (id === 6) {
      // the panel tumbles off backwards, bolts scatter, captain shocked behind the hole
      const u = (f - BANG) / FPS;
      const fly = P.paneLFly; fly.visible = true;
      fly.position.copy(wsCtr).add(V(-34 * u * u - 2 * u, 3.2 * u - 2 * u * u, -2.4 * u));
      fly.rotation.set(u * 7, u * 3, u * 5);
      for (let i = 0; i < 8; i++) {
        const k = i / 8, a = k * 6.28;
        this.fx("bolt" + (i % 2), 220, 520, (p) => D.bolt(p, 32), P.g.localToWorld(wsCtr.clone().add(V(-30 * u * u - (1 + k) * u, (Math.sin(a) * 1.2 + 1) * u, -(1.2 + Math.cos(a)) * u))), 0.12, 0.28, cam, { rot: u * 9 + i });
      }
      this.actor("cap_shock", 0.7, (p) => bodyFront(p, CAPTAIN, { mode: "sit", expr: "shock", seed: 3 }), P.g.localToWorld(seatCap.clone()), cam, { scale: 0.9 });
      this.fx("mist", 512, 512, (p) => D.mist(p, 1), P.g.localToWorld(wsCtr.clone().add(V(-1.5, 0.4, -0.5))), 4 * clamp01(u * 3), 4 * clamp01(u * 3), cam, { soft: true });
      for (let i = 0; i < 3; i++) this.fx("wind" + i, 600, 300, (p) => D.wind(p, (f / 30 + i * 0.3) % 1), P.g.localToWorld(V(9 - i * 3, 2.2 + i * 0.6, -2.2)), 4, 2, cam, { soft: false });
    }
    if (id === 10) {
      // a plane is a balloon: pressure arrows push out, the fuselage breathes
      const k = smooth((f - 1100) / 40), puls = 1 + 0.03 * k * (0.5 + 0.5 * Math.sin((f - 1100) * 0.25));
      P.body.scale.set(1, puls, puls);
      const n = 10;
      for (let i = 0; i < n; i++) {
        const x = -9 + (i % 5) * 4.6, up = i < 5;
        const pos = P.g.localToWorld(V(x, up ? 2.6 + 0.6 * k : -2.6 - 0.6 * k, -0.6));
        this.fx("arrow", 300, 160, (p) => D.arrow(p), pos, 1.8 * k + 0.01, 0.96 * k + 0.01, cam, { rot: up ? Math.PI / 2 : -Math.PI / 2 });
      }
      for (const dx of [-1, 1]) this.fx("arrow", 300, 160, (p) => D.arrow(p), P.g.localToWorld(V(dx > 0 ? 16.4 + 0.5 * k : -16.8 - 0.5 * k, 0.6, -0.6)), 1.8 * k + 0.01, 0.96 * k + 0.01, cam, { rot: dx > 0 ? 0 : Math.PI });
    }
    if (id === 11) {
      // close-up of the (intact) panel and its bolts; 84 of 90 turn red; then the comparison inserts
      P.paneL.visible = true; P.hole.visible = false;
      const red = smooth((f - RED) / 10), pulse = 0.5 + 0.5 * Math.sin(f * 0.5);
      const cRed = new THREE.Color(1.0, 0.18 + 0.1 * pulse, 0.12), cOk = new THREE.Color(1, 1, 1), cc = new THREE.Color();
      const good = new Set([3, 30, 47, 58, 71, 86]);
      for (let i = 0; i < 90; i++) { cc.copy(cOk); if (!good.has(i)) cc.lerp(cRed, red); P.bolts.setColorAt(i, cc); }
      P.bolts.instanceColor!.needsUpdate = true;
      if (f >= CARD_IN) {
        const u = smooth((f - CARD_IN) / 12);
        const rgt = new THREE.Vector3().setFromMatrixColumn(cam.matrixWorld, 0), upv = new THREE.Vector3().setFromMatrixColumn(cam.matrixWorld, 1), fwd = new THREE.Vector3().setFromMatrixColumn(cam.matrixWorld, 2).negate();
        const p0 = cam.position.clone().addScaledVector(fwd, 0.6).addScaledVector(upv, -0.1).addScaledVector(rgt, 0.5 * (1 - u));
        this.fx("bolt_ok", 220, 520, (p) => { D.bolt(p, 40); }, p0.clone().addScaledVector(rgt, -0.1), 0.09, 0.21, cam);
        this.fx("bolt_bad", 220, 520, (p) => { D.bolt(p, 30, "#f0b0a8"); }, p0.clone().addScaledVector(rgt, 0.0), 0.09, 0.21, cam);
        if (f >= CARD_IN + 20) { const v = smooth((f - CARD_IN - 20) / 14); this.fx("card", 540, 340, (p) => D.creditCard(p), p0.clone().addScaledVector(rgt, 0.12).addScaledVector(upv, -0.02 - 0.35 * (1 - v)), 0.14, 0.088, cam, { rot: -0.25 * v }); }
      }
    }
    if (id === 13) {
      // captain outside, bent back over the nose, held by the legs inside; wind
      P.paneL.visible = false; P.hole.visible = true;
      const flap = Math.sin(f * 0.9) * 0.08;
      const pos = P.g.localToWorld(skin(11.85, 0.45, 0.42));
      this.fx("cap_out", 600, 1000, (p) => D.upper(p, CAPTAIN, "dazed", 3, 720), pos, 600 * SU * 1.3, 1000 * SU * 1.3, cam, { rot: -1.35 + flap, k: 0.9 });
      for (let i = 0; i < 3; i++) this.fx("wind" + i, 600, 300, (p) => D.wind(p, (f / 30 + i * 0.3) % 1), P.g.localToWorld(V(12.8 - i * 1.6, 1.7 + i * 0.35, -1.6)), 2.4, 1.2, cam);
      const dg = P.g.userData.danger as THREE.Mesh;
      dg.visible = f > 1540;
      if (dg.visible) { const u = smooth((f - 1540) / 22); (dg.geometry as THREE.BufferGeometry).setDrawRange(0, Math.floor(u * (dg.geometry.index!.count / 3)) * 3); dg.children[0].visible = u > 0.97; }
    }
  }

  // ======== RUNWAY ========
  private poseRunway(id: number, f: number, cam: THREE.PerspectiveCamera) {
    const P = this.ground;
    P.gear.visible = true;
    const x = planeX(f), y = planeY(f), pitch = planePitch(f);
    P.g.position.set(x, 2.6 + y, 0); P.g.rotation.set(0, 0, pitch);
    P.paneL.visible = id === 3; P.hole.visible = id === 14;
    if (id === 14 && f >= TOUCH && f < TOUCH + 24) {
      const u = (f - TOUCH) / 24;
      for (const sd of [1, -1]) this.fx("puff", 300, 300, (p) => fxPuff(p, u), V(x - 0.6 - 6 * u, 0.6 + u, sd * 2.4), 2.5 + 2 * u, 2.5 + 2 * u, cam, { soft: true });
    }
    void cam;
  }

  // ======== HANGAR ========
  private poseHangar(id: number, f: number, cam: THREE.PerspectiveCamera) {
    const look = id === 12 ? Math.sin(f * 0.15) : 0;
    const expr: Expr = id === 1 ? (f > 70 ? "smile_closed" : "neutral") : "nervous";
    this.actor("mech" + expr, 0.9, (p) => bodyFront(p, MECH, { mode: "stand", expr, seed: 4, look }), V(0.4, 0, 0.2), cam, { scale: 0.95 });
    // the bolts in his hand (held up to compare)
    const hand = V(0.4, 1.12, 0.32).addScaledVector(new THREE.Vector3().subVectors(cam.position, V(0.4, 1.12, 0.32)).normalize(), 0.18);
    const rgt = new THREE.Vector3().setFromMatrixColumn(cam.matrixWorld, 0);
    if (id === 1) this.fx("bolt_h", 220, 520, (p) => D.bolt(p, 30), hand.clone().addScaledVector(rgt, 0.3).add(V(0, -0.2, 0)), 0.1, 0.24, cam, { rot: -0.3 });
    else {
      const sway = Math.sin(f * 0.18) * 0.02;
      this.fx("bolt_h", 220, 520, (p) => D.bolt(p, 36), hand.clone().addScaledVector(rgt, -0.34 + sway).add(V(0, 0.05, 0)), 0.1, 0.24, cam, { rot: 0.15 });
      this.fx("bolt_h2", 220, 520, (p) => D.bolt(p, 30), hand.clone().addScaledVector(rgt, 0.34 - sway).add(V(0, 0.05, 0)), 0.1, 0.24, cam, { rot: -0.15 });
    }
  }

  // ======== COCKPIT ========
  private poseCockpit(id: number, f: number, cam: THREE.PerspectiveCamera) {
    const blown = f >= BANG && id !== 16;
    this.ckPaneL.visible = !blown;
    const side = id === 8 || id === 9;
    for (const o of this.ckRightWall) o.visible = !side;
    // clouds beyond the windscreen
    for (let i = 0; i < this.ckClouds.length; i++) {
      const m = this.ckClouds[i], ph = ((f * 0.9 + i * 37) % 120) / 120;
      m.position.set(60 - ph * 140, -8 - (i % 4) * 7 + (i % 3) * 5, -40 + (i * 23) % 80); m.scale.set(30 + (i % 3) * 15, 15 + (i % 3) * 7, 1);
      m.lookAt(cam.position.x, m.position.y, cam.position.z);
    }
    const seatC = V(-0.18, 0.3, -0.4), seatF = V(-0.18, 0.3, 0.4);
    // FO: flies the plane (hidden in the side cutaway shots)
    if (!side) {
      const foExpr: Expr = id === 16 ? "nervous" : f < BANG ? "neutral" : "shock";
      this.actor("fo" + foExpr, 0.85, (p) => bodyFront(p, FO, { mode: "sit", expr: foExpr, seed: 5, look: id === 16 ? -0.6 : 0 }), seatF, cam);
    }
    if (id === 5) {
      const expr: Expr = f > 482 ? "nervous" : "smile_closed";
      this.actor("cap" + expr, 0.85, (p) => bodyFront(p, CAPTAIN, { mode: "sit", expr, seed: 3 }), seatC, cam);
      if (f > 476 && f < BANG) this.fx("creak", 300, 300, (p) => fxCreak(p, (f % 6) / 6), V(1.4, 1.45, -0.55), 0.35, 0.35, cam);
      if (f >= BANG) { const u = (f - BANG) / 16; this.fx("mistC", 512, 512, (p) => D.mist(p, 0.8), V(0.6, 1.3, -0.3), 2.4 * smooth(u), 2.4 * smooth(u), cam, { soft: true }); }
    }
    if (id === 7) {
      // papers rush to the hole; the captain lifts out of his seat and is gone through the window
      for (let i = 0; i < 7; i++) {
        const ph = (((f - 612) * 0.04 + i * 0.37) % 1);
        const p0 = V(-1.6 + i * 0.1, 0.9 + (i % 3) * 0.25, 0.4 - (i % 4) * 0.25), p1 = V(1.45, 1.45, -0.55);
        const pp = p0.clone().lerp(p1, ph * ph);
        this.fx("paper" + (i % 3), 200, 260, (p) => D.paper(p, i), pp, 0.2, 0.26, cam, { rot: ph * 9 + i });
      }
      const u = clamp01((f - LIFT) / (OUT - LIFT));
      if (f < OUT) {
        const pos = seatC.clone().lerp(V(1.35, 1.25, -0.6), u * u);
        const expr: Expr = f < LIFT - 20 ? "shock" : "pained";
        this.actor("cap7" + (u > 0 ? "fall" : "sit") + expr, 0.85, (p) => bodyFront(p, CAPTAIN, { mode: u > 0 ? "fall" : "sit", expr, seed: 3 }), pos, cam, { roll: -u * 1.4 });
        if (f > LIFT) this.fx("capfly", 300, 200, (p) => D.capFx(p), V(0.4 + u * 1.1, 1.5 + u * 0.4, -0.5), 0.3, 0.2, cam, { rot: u * 6 });
      }
      if (f < 650) { const m = 1 - smooth((f - 612) / 38); this.fx("mistC", 512, 512, (p) => D.mist(p, 0.8), V(0.6, 1.3, -0.3), 2.4 * m + 0.01, 2.4 * m + 0.01, cam, { soft: true }); }
    }
    if (side) {
      // cutaway seen from the FO's side: legs from the window, Nigel holds them, more crew hold Nigel
      const sl = id === 9 ? smooth((f - SLIDE) / 40) * 0.35 : 0;
      const kick = (f % 20) / 20;
      const legsPos = V(0.6 + sl * 0.4, 1.22, -0.3);
      // legs card (1000 x 320 canvas): hips at the window (right end), feet down-left in Nigel's hands
      this.fx("legs" + Math.floor(kick * 6), 1000, 320, (p) => D.legs(p, CAPTAIN, Math.floor(kick * 6) / 6), legsPos, 1.45, 0.46, cam, { rot: 0.33 });
      const grab = smooth((f - (GRAB - 40)) / 40);
      const nx = id === 8 ? -1.6 + grab * 1.15 : -0.45 + sl;
      const nExpr: Expr = id === 8 ? (f < GRAB ? "shock" : "pained") : "pained";
      this.actor("nig" + nExpr + (grab > 0.99 ? "h" : "r"), 0.85, (p) => bodySide(p, NIGEL, { mode: "push", pose: grab, expr: nExpr, seed: 8 }), V(nx, 0, 0.0), cam, { roll: id === 9 ? -sl * 0.5 : 0 });
      if (id === 8 && f > 860) {
        const u = smooth((f - 860) / 14);
        this.fx("weight", 300, 320, (p) => D.weight(p), V(0.5, 1.72 - 0.08 * u, -0.3), 0.3 * u + 0.01, 0.32 * u + 0.01, cam);
      }
      if (id === 9 && f >= CREW - 20) {
        const u = smooth((f - (CREW - 20)) / 25);
        this.actor("crew2", 0.8, (p) => bodySide(p, CREW2, { mode: "push", pose: u, expr: "pained", seed: 9 }), V(nx - 0.5 - (1 - u) * 0.8, 0, 0.12), cam);
        this.actor("crew3", 0.8, (p) => bodySide(p, CREW3, { mode: "push", pose: u, expr: "nervous", seed: 10 }), V(nx - 1.0 - (1 - u) * 1.2, 0, 0.24), cam);
      }
      for (let i = 0; i < 2; i++) this.fx("windc" + i, 600, 300, (p) => D.wind(p, (f / 30 + i * 0.5) % 1), V(0.2 - i * 0.7, 1.6 + i * 0.25, -0.6), 1.2, 0.6, cam);
    }
    if (id === 16) {
      this.actor("cap16", 0.85, (p) => bodyFront(p, CAPTAIN_CAP, { mode: "sit", expr: f > 1830 ? "grin" : "smile_closed", seed: 3, wave: f > 1830 ? 0.5 + 0.5 * Math.sin(f * 0.35) : undefined }), seatC, cam);
    }
  }

  // ======== HOSPITAL ========
  private poseHospital(_id: number, f: number, cam: THREE.PerspectiveCamera) {
    const expr: Expr = f < 1735 ? "dazed" : f < 1760 ? "pained" : "relief";
    this.actor("hosp" + expr, 0.9, (p) => { bodyFront(p, CAPTAIN, { mode: "sit", expr, seed: 3 }); D.bandages(p); }, V(0, 0.42, -0.45), cam);
    if (f > 1735 && f < 1765) for (let i = 0; i < 3; i++) this.fx("frost", 200, 200, (p) => D.frost(p), V(-0.25 + i * 0.25, 1.55 + (i % 2) * 0.1, -0.3), 0.12, 0.12, cam, { rot: f * 0.05 + i });
    if (f < 1730) this.fx("stars", 420, 210, (p) => fxStars(p, (f % 30) / 30), V(0, 1.72, -0.4), 0.5, 0.25, cam);
  }
}

const CAPTAIN_CAP = { ...CAPTAIN, hat: "cap", cap: "#1e2b52" };
void SU; void lin;
