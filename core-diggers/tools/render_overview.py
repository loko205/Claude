# Renders the sky island with a stepped cutaway exposing all layers, plus the
# camp deck — straight from the exported game data.
# Usage:
#   luau tools/export_world.luau > /tmp/cd_world.json
#   uv run --no-project --with pillow python tools/render_overview.py /tmp/cd_world.json out.png
import json
import random
import sys

from PIL import Image, ImageDraw, ImageFilter

from iso import DEPTH, dot, draw_box, fit, font, project, shade, sort_key

random.seed(7)


def main():
    data = json.load(open(sys.argv[1]))
    out_path = sys.argv[2] if len(sys.argv) > 2 else "/tmp/cd_overview.png"
    bs = data["blockSize"]
    sx, sz, depth = data["island"]["sizeX"], data["island"]["sizeZ"], data["island"]["depth"]

    layer_at = {}
    for layer in data["layers"]:
        for k in range(int(layer["from"]), int(layer["to"]) + 1):
            layer_at[k] = layer

    def pos(i, j, k):
        return ((i - (sx + 1) / 2) * bs, -(k - 0.5) * bs, (j - (sz + 1) / 2) * bs)

    # Stepped cutaway notches at the camera-facing corner (high i, low j).
    notches = [
        (17, 26, 1, 10, 12),   # i0, i1, j0, j1, down-to layer
        (21, 26, 1, 6, 24),
        (24, 26, 1, 3, 36),
    ]

    def cut_depth(i, j):
        d = 0
        for i0, i1, j0, j1, kd in notches:
            if i0 <= i <= i1 and j0 <= j <= j1:
                d = max(d, kd)
        return d

    cells = set()
    for i in range(1, sx + 1):  # top surface
        for j in range(1, sz + 1):
            cells.add((i, j, 1))
    for k in range(1, depth + 1):  # visible outer faces
        for i in range(1, sx + 1):
            cells.add((i, 1, k))
        for j in range(1, sz + 1):
            cells.add((sx, j, k))

    # Remove cut cells, then add the exposed inner walls/floors of each notch.
    cells = {(i, j, k) for (i, j, k) in cells if k > cut_depth(i, j)}
    for i0, i1, j0, j1, kd in notches:
        for k in range(1, kd + 1):
            for j in range(j0, j1 + 1):
                if k > cut_depth(i0 - 1, j):
                    cells.add((i0 - 1, j, k))  # wall toward -i
            for i in range(i0, i1 + 1):
                if k > cut_depth(i, j1 + 1):
                    cells.add((i, j1 + 1, k))  # wall toward +j
        for j in range(j0, j1 + 1):  # notch floor
            for i in range(i0, i1 + 1):
                if cut_depth(i, j) == kd and kd < depth:
                    cells.add((i, j, kd + 1))

    parts = []
    for (i, j, k) in cells:
        layer = layer_at[k]
        c = layer["color"]
        jit = random.randint(-7, 7)
        col = tuple(max(0, min(255, int(v + jit))) for v in c)
        spec = {"s": [bs, bs, bs], "p": list(pos(i, j, k)), "c": col}
        # mirror the in-game block specials so the preview matches gameplay
        r = random.random()
        if layer.get("hazard") and r < 0.05:
            spec["c"] = (255, 95, 30)
            spec["m"] = "Neon"
        elif r < 0.005:
            spec["c"] = (235, 185, 80)
        elif r < 0.075 and layer["ores"]:
            ore = random.choice(layer["ores"])
            oc = data["items"][ore["id"]]["color"]
            spec["c"] = tuple(int(cc * 0.35 + occ * 0.65) for cc, occ in zip(c, oc))
        parts.append(spec)

    # The core glows at the bottom of the deepest shaft (artistic stand-in for
    # the real one under the island center).
    parts.append({"s": [bs * 2, bs * 2, bs * 2], "p": list(pos(25, 2, depth)), "c": (255, 130, 40), "m": "Neon"})

    parts += data["camp"]

    width = 1700
    k_, ox, oy, height = fit(parts, width)
    img = Image.new("RGBA", (width, height + 40), (140, 185, 230, 255))
    glow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    for part in sorted(parts, key=sort_key):
        color = tuple(int(v) for v in part.get("c", (180, 180, 180)))
        alpha = int(255 * (1 - part.get("t", 0)))
        if part.get("m") == "Neon":
            x, y = project(part["p"], k_, ox, oy)
            r = k_ * min(max(part["s"]), 10) * 0.8
            ImageDraw.Draw(glow).ellipse([x - r, y - r, x + r, y + r], fill=shade(color, 1.1) + (70,))
            color = shade(color, 1.25)
        draw_box(img, part["p"], part["s"], color, alpha, k_, ox, oy)
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(8)))

    d = ImageDraw.Draw(img)
    d.text((width / 2, 14), "CORE DIGGERS — Insel-Querschnitt (aus World.luau gerendert)",
           font=font(24), fill=(255, 255, 255), anchor="ma")
    # Layer labels along the cut wall
    for layer in data["layers"]:
        mid_k = (layer["from"] + layer["to"]) / 2
        x, y = project(pos(27.6, 0, mid_k), k_, ox, oy)
        d.text((x + 8, y), f'{layer["name"]}  (Layer {layer["from"]}–{layer["to"]})',
               font=font(17), fill=(255, 255, 255), anchor="lm",
               stroke_width=2, stroke_fill=(30, 32, 40))
    x, y = project(pos(25, 2, depth), k_, ox, oy)
    d.text((x + 30, y + 10), "THE CORE", font=font(19), fill=(255, 170, 80), anchor="lm",
           stroke_width=2, stroke_fill=(30, 32, 40))

    img.convert("RGB").save(out_path)
    print("saved", out_path)


if __name__ == "__main__":
    main()
