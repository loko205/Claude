# Isometric overview of the whole map, rendered from MapBlueprint data.
# Usage:
#   luau tools/export_map.luau > /tmp/map.json
#   uv run --no-project --with pillow python tools/render_map.py /tmp/map.json out.png
import json
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

from render_preview import DEPTH, RIGHT, UP, box_corner, dot, draw_box, font, project, shade


def main():
    data = json.load(open(sys.argv[1]))
    out_path = sys.argv[2] if len(sys.argv) > 2 else "/tmp/map_preview.png"
    parts = data["parts"]

    pts = []
    for part in parts:
        for sx in (-1, 1):
            for sy in (-1, 1):
                for sz in (-1, 1):
                    pts.append(box_corner(part["p"], part["s"], sx, sy, sz))
    xs = [dot(p, RIGHT) for p in pts]
    ys = [-dot(p, UP) for p in pts]
    width = 1800
    k = (width - 60) / (max(xs) - min(xs))
    height = int(k * (max(ys) - min(ys))) + 120
    ox = 30 - k * min(xs)
    oy = 60 - k * min(ys)

    img = Image.new("RGBA", (width, height), (24, 26, 34, 255))
    glow = Image.new("RGBA", img.size, (0, 0, 0, 0))

    # Sort by bottom height first so the huge ground slab never overdraws
    # buildings standing on it, then by camera depth.
    for part in sorted(parts, key=lambda q: (q["p"][1] - q["s"][1] / 2, dot(q["p"], DEPTH))):
        color = tuple(int(v) for v in part.get("c", (180, 180, 180)))
        alpha = int(255 * (1 - part.get("t", 0)))
        if part.get("m") == "Neon":
            x, y = project(part["p"], k, ox, oy)
            r = k * min(max(part["s"]), 10) * 0.7
            ImageDraw.Draw(glow).ellipse([x - r, y - r, x + r, y + r], fill=shade(color, 1.1) + (60,))
            color = shade(color, 1.25)
        draw_box(img, part["p"], part["s"], color, alpha, k, ox, oy)

    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(7)))
    draw = ImageDraw.Draw(img)
    draw.text((width / 2, 16), "STEAL A SCHNITZEL — Map-Übersicht (aus MapBlueprint.luau gerendert)",
              font=font(24), fill=(255, 255, 255), anchor="ma")
    img.convert("RGB").save(out_path)
    print("saved", out_path)


if __name__ == "__main__":
    main()
