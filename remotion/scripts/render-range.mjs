// usage: node scripts/render-range.mjs <comp> <out.mp4> <from> <to> [scale]
import { bundle } from "@remotion/bundler";
import { renderMedia, selectComposition } from "@remotion/renderer";
import path from "node:path";
const [comp, out, from, to, scale = "1"] = process.argv.slice(2);
const browserExecutable = process.env.CHROME || "/usr/bin/google-chrome";
const chromiumOptions = { gl: process.env.GL || "swangle" };
const inputProps = JSON.parse(process.env.PROPS || "{}");
const serveUrl = await bundle({ entryPoint: path.resolve("src/index.ts"), publicDir: path.resolve("public") });
const composition = await selectComposition({ serveUrl, id: comp, inputProps, browserExecutable, chromiumOptions });
const t0 = Date.now();
await renderMedia({ composition, serveUrl, inputProps, codec: "h264", crf: Number(process.env.CRF || 18), outputLocation: out, frameRange: [Number(from), Number(to)], scale: Number(scale),
  browserExecutable, chromiumOptions, concurrency: Number(process.env.CONC || 1), timeoutInMilliseconds: 300000, x264Preset: "veryfast",
  onProgress: ({ renderedFrames }) => { if (renderedFrames % 10 === 0) process.stdout.write(`\r${renderedFrames} ${((Date.now()-t0)/1000).toFixed(0)}s`); } });
console.log("\ndone", ((Date.now() - t0) / 1000).toFixed(1) + "s");
