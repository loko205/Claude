import React, { useEffect, useRef } from "react";
import { AbsoluteFill } from "remotion";
import { Pen, bodyFront, bodySide } from "../bridge/toon";
import { CAPTAIN, FO, NIGEL, MECH, CREW2 } from "./outfits";
import * as D from "./chars";
const items: [string, (p: Pen) => void][] = [
  ["cap", (p) => bodyFront(p, CAPTAIN, { mode: "stand", expr: "neutral" })],
  ["fo", (p) => bodyFront(p, FO, { mode: "sit", expr: "shock" })],
  ["nig", (p) => bodyFront(p, NIGEL, { mode: "stand", expr: "nervous", facing: 1 })],
  ["mech", (p) => bodyFront(p, MECH, { mode: "stand", expr: "stern", seed: 4 })],
  ["fall", (p) => bodyFront(p, CAPTAIN, { mode: "fall", expr: "dazed" })],
  ["side", (p) => bodySide(p, NIGEL, { mode: "push", pose: 1, expr: "shock" })],
  ["side2", (p) => bodySide(p, CREW2, { mode: "stand", expr: "pained" })],
  ["upper", (p) => D.upper(p, CAPTAIN, "dazed", 3, 720)],
  ["legs", (p) => D.legs(p, CAPTAIN, 0.3)],
];
export const Sheet: React.FC = () => {
  const refs = useRef<(HTMLCanvasElement | null)[]>([]);
  useEffect(() => { items.forEach(([, d], i) => { const c = refs.current[i]!; const g = c.getContext("2d")!; g.setTransform(0.45,0,0,0.45,0,0); d(new Pen(g)); }); }, []);
  return <AbsoluteFill style={{ background: "#cfe3f2", flexDirection: "row", flexWrap: "wrap" }}>
    {items.map(([k], i) => <canvas key={k} ref={(el) => { refs.current[i] = el; }} width={270} height={450} style={{ width: 270, height: 450 }} />)}
  </AbsoluteFill>;
};
