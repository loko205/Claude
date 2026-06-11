# Renders the museum relics and the shovel tiers from the exported game data.
# Usage: uv run --no-project --with pillow python tools/render_relics.py /tmp/cd_world.json out.png
import json
import sys

from PIL import Image, ImageDraw, ImageFilter

from iso import dot, draw_box, fit, font, project, shade, sort_key

RARITY_COLOR = {0: (255, 150, 220)}  # mythic; layer relics use white


def render_model(parts, cell, glow_alpha=70):
    img = Image.new("RGBA", cell, (0, 0, 0, 0))
    glow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    k, ox, oy, _ = fit(parts, cell[0], pad=26)
    k = min(k, 56)
    # re-center with clamped zoom
    from iso import RIGHT, UP, box_corner
    pts = []
    for part in parts:
        for sx in (-1, 1):
            for sy in (-1, 1):
                for sz in (-1, 1):
                    pts.append(box_corner(part["p"], part["s"], sx, sy, sz))
    xs = [dot(p, RIGHT) for p in pts]
    ys = [-dot(p, UP) for p in pts]
    ox = cell[0] / 2 - k * (max(xs) + min(xs)) / 2
    oy = cell[1] / 2 - k * (max(ys) + min(ys)) / 2
    for part in sorted(parts, key=sort_key):
        color = tuple(int(v) for v in part.get("c", (200, 200, 200)))
        alpha = int(255 * (1 - part.get("t", 0)))
        if part.get("m") == "Neon":
            x, y = project(part["p"], k, ox, oy)
            r = k * max(part["s"]) * 0.7
            ImageDraw.Draw(glow).ellipse([x - r, y - r, x + r, y + r], fill=shade(color, 1.1) + (60,))
            color = shade(color, 1.25)
        draw_box(img, part["p"], part["s"], color, alpha, k, ox, oy)
    out = Image.new("RGBA", cell, (0, 0, 0, 0))
    out.alpha_composite(glow.filter(ImageFilter.GaussianBlur(7)))
    out.alpha_composite(img)
    return out


def shovel_parts(color, neon):
    return [
        {"s": [0.4, 3.2, 0.4], "p": [0, 1.6, 0], "c": (120, 85, 55)},
        {"s": [1.1, 1.2, 0.25], "p": [0, -0.6 + 0.6, 0], "c": color, "m": "Neon" if neon else None},
        {"s": [0.7, 0.35, 0.3], "p": [0, 3.3, 0], "c": (120, 85, 55)},
    ]


def main():
    data = json.load(open(sys.argv[1]))
    out_path = sys.argv[2] if len(sys.argv) > 2 else "/tmp/cd_relics.png"
    cw, ch = 330, 300
    cols = 5
    rows = 2
    shovels = data["shovels"]
    W = cols * cw + 40
    H = 80 + rows * ch + 90 + 230
    img = Image.new("RGBA", (W, H), (24, 26, 34, 255))
    d = ImageDraw.Draw(img)
    d.text((W / 2, 16), "CORE DIGGERS — Museums-Relikte & Schaufeln (aus den Spieldaten)",
           font=font(26), fill=(255, 255, 255), anchor="ma")

    for idx, relic in enumerate(data["relics"]):
        row, col = idx // cols, idx % cols
        ox, oy = 20 + col * cw, 60 + row * ch
        sprite = render_model(data["relicDesigns"][relic["id"]], (cw, ch - 70))
        img.alpha_composite(sprite, (ox, oy))
        color = RARITY_COLOR.get(relic["layer"], (255, 255, 255))
        title = relic["name"]
        sub = ("Mythic — every layer" if relic["layer"] == 0 else f'Layer-Zone {relic["layer"]}') + f'  ·  ${int(relic["value"]):,}'.replace(",", ".")
        d.text((ox + cw / 2, oy + ch - 64), title, font=font(20), fill=color, anchor="ma")
        d.text((ox + cw / 2, oy + ch - 38), sub, font=font(15), fill=(190, 190, 200), anchor="ma")

    sy = 60 + rows * ch + 10
    d.text((W / 2, sy), "SCHAUFELN (Schaden · Luck · Preis)", font=font(22), fill=(120, 190, 255), anchor="ma")
    scw = W // len(shovels)
    for idx, shovel in enumerate(shovels):
        ox = idx * scw
        sprite = render_model(shovel_parts(tuple(shovel["color"]), shovel["id"] == "omega"), (scw, 150), 50)
        img.alpha_composite(sprite, (ox, sy + 30))
        d.text((ox + scw / 2, sy + 182), shovel["name"], font=font(15), fill=(255, 255, 255), anchor="ma")
        luck = f' · +{int(shovel["luck"] * 100)}%' if shovel["luck"] > 0 else ""
        d.text((ox + scw / 2, sy + 202), f'dmg {int(shovel["dmg"])}{luck} · ${int(shovel["price"]):,}'.replace(",", "."),
               font=font(13), fill=(170, 175, 190), anchor="ma")

    img.convert("RGB").save(out_path)
    print("saved", out_path)


if __name__ == "__main__":
    main()
