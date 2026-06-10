# Isometric preview of all characters, rendered from the actual game data.
# Usage:
#   luau tools/export_designs.luau > /tmp/designs.json
#   uv run --no-project --with pillow python tools/render_preview.py /tmp/designs.json out.png
import json
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

# Mirrors Characters.luau: id -> (display name, rarity, base color, income/s)
CHARS = [
    ("schnitzel_cat", "Schnitzel Cat", "Common", (222, 184, 135), 1),
    ("toast_goblin", "Toast Goblin", "Common", (210, 160, 90), 1),
    ("pickle_pigeon", "Pickle Pigeon", "Common", (120, 160, 80), 1),
    ("bratwurst_dog", "Bratwurst Dog", "Uncommon", (180, 100, 70), 5),
    ("disco_pickle", "Disco Pickle", "Uncommon", (90, 200, 120), 6),
    ("waffle_wolf", "Waffle Wolf", "Uncommon", (230, 190, 110), 7),
    ("banana_shark", "Banana Shark", "Rare", (250, 220, 80), 20),
    ("sushi_raccoon", "Sushi Raccoon", "Rare", (200, 200, 210), 24),
    ("pretzel_snake", "Pretzel Snake", "Rare", (160, 110, 60), 30),
    ("kebab_capybara", "Kebab Capybara", "Epic", (170, 120, 80), 75),
    ("lasagna_llama", "Lasagna Llama", "Epic", (220, 140, 90), 90),
    ("toaster_duck", "Toaster Duck", "Epic", (240, 230, 140), 112),
    ("donut_dragon", "Donut Dragon", "Legendary", (255, 150, 180), 300),
    ("espresso_gorilla", "Espresso Gorilla", "Legendary", (90, 60, 40), 360),
    ("nuclear_currywurst", "Nuclear Currywurst", "Legendary", (255, 120, 30), 450),
    ("quantum_pretzel", "Quantum Pretzel", "Mythic", (120, 220, 255), 1200),
    ("galactic_doener", "Galactic Döner", "Mythic", (150, 80, 255), 1560),
    ("sigma_strudel", "Sigma Strudel", "Mythic", (255, 215, 120), 1920),
    ("void_schnitzel", "Void Schnitzel", "Secret", (30, 30, 40), 7500),
    ("omega_meatball", "Omega Meatball", "Secret", (80, 20, 20), 11250),
    ("the_final_bratwurst", "THE FINAL BRATWURST", "Secret", (255, 0, 100), 18750),
]
RARITY_COLORS = {
    "Common": (190, 190, 190), "Uncommon": (105, 220, 105), "Rare": (90, 160, 255),
    "Epic": (180, 110, 255), "Legendary": (255, 186, 30), "Mythic": (255, 90, 90),
    "Secret": (230, 230, 245),
}

# Camera sees the +X, +Y and -Z faces (-Z is the characters' front).
RIGHT = (0.707, 0.0, 0.707)
UP = (-0.362, 0.857, 0.362)
DEPTH = (0.6, 0.5, -0.6)


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def project(p, k, ox, oy):
    return (ox + k * dot(p, RIGHT), oy - k * dot(p, UP))


def shade(color, factor):
    return tuple(max(0, min(255, int(v * factor))) for v in color)


def font(size):
    try:
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", size)
    except OSError:
        return ImageFont.load_default()


def draw_poly(img, points, fill, alpha):
    if alpha >= 255:
        ImageDraw.Draw(img).polygon(points, fill=fill + (255,))
    else:
        layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
        ImageDraw.Draw(layer).polygon(points, fill=fill + (alpha,))
        img.alpha_composite(layer)


def box_corner(c, s, sx, sy, sz):
    return (c[0] + sx * s[0] / 2, c[1] + sy * s[1] / 2, c[2] + sz * s[2] / 2)


def draw_box(img, c, s, color, alpha, k, ox, oy):
    faces = [
        ([(-1, 1, -1), (1, 1, -1), (1, 1, 1), (-1, 1, 1)], 1.18),   # top (+y)
        ([(-1, 1, -1), (1, 1, -1), (1, -1, -1), (-1, -1, -1)], 0.95),  # front (-z)
        ([(1, 1, -1), (1, 1, 1), (1, -1, 1), (1, -1, -1)], 0.68),   # right (+x)
    ]
    for corners, light in faces:
        pts = [project(box_corner(c, s, *cs), k, ox, oy) for cs in corners]
        draw_poly(img, pts, shade(color, light), alpha)


def draw_ball(img, c, s, color, alpha, k, ox, oy):
    x, y = project(c, k, ox, oy)
    r = k * s[0] / 2
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse([x - r, y - r, x + r, y + r], fill=shade(color, 0.8) + (alpha,))
    d.ellipse([x - r, y - r, x + r * 0.55, y + r * 0.55], fill=shade(color, 1.1) + (alpha,))
    d.ellipse([x - r * 0.75, y - r * 0.75, x - r * 0.05, y - r * 0.05],
              fill=shade(color, 1.3) + (alpha,))
    img.alpha_composite(layer)


def render_character(designs, char_id, base_color, cell):
    parts = designs[char_id]
    img = Image.new("RGBA", cell, (0, 0, 0, 0))
    glow = Image.new("RGBA", cell, (0, 0, 0, 0))

    # Fit the character into the cell.
    pts = []
    for part in parts:
        c, s = part["p"], part["s"]
        for sx in (-1, 1):
            for sy in (-1, 1):
                for sz in (-1, 1):
                    pts.append(box_corner(c, s, sx, sy, sz))
    xs = [dot(p, RIGHT) for p in pts]
    ys = [-dot(p, UP) for p in pts]
    spanx, spany = max(xs) - min(xs), max(ys) - min(ys)
    k = min((cell[0] - 30) / spanx, (cell[1] - 30) / spany, 34)
    ox = cell[0] / 2 - k * (max(xs) + min(xs)) / 2
    oy = cell[1] / 2 + (-k) * -(max(ys) + min(ys)) / 2

    # Ground shadow.
    bottom = min(p[1] for p in pts)
    gx, gy = project((0, bottom, 0), k, ox, oy)
    sh = ImageDraw.Draw(img)
    sh.ellipse([gx - k * 1.6, gy - k * 0.45, gx + k * 1.6, gy + k * 0.45], fill=(0, 0, 0, 70))

    for part in sorted(parts, key=lambda q: (dot(q["p"], DEPTH), q["p"][1])):
        color = tuple(int(v) for v in part.get("c", base_color))
        alpha = int(255 * (1 - part.get("t", 0)))
        neon = part.get("m") == "Neon"
        target = img
        if neon:
            x, y = project(part["p"], k, ox, oy)
            r = k * max(part["s"]) * 0.65
            gd = ImageDraw.Draw(glow)
            gd.ellipse([x - r, y - r, x + r, y + r], fill=shade(color, 1.1) + (55,))
            color = shade(color, 1.25)
        if part.get("b"):
            draw_ball(target, part["p"], part["s"], color, alpha, k, ox, oy)
        else:
            draw_box(target, part["p"], part["s"], color, alpha, k, ox, oy)

    out = Image.new("RGBA", cell, (0, 0, 0, 0))
    out.alpha_composite(glow.filter(ImageFilter.GaussianBlur(9)))
    out.alpha_composite(img)
    return out


def main():
    designs = json.load(open(sys.argv[1]))
    out_path = sys.argv[2] if len(sys.argv) > 2 else "/tmp/preview.png"
    cw, ch = 380, 360
    cols, rows = 3, 7
    img = Image.new("RGBA", (cols * cw + 40, rows * ch + 110), (24, 26, 34, 255))
    draw = ImageDraw.Draw(img)
    draw.text((img.width / 2, 20), "STEAL A SCHNITZEL — Charakter-Designs (aus Designs.luau gerendert)",
              font=font(26), fill=(255, 255, 255), anchor="ma")

    for i, (cid, name, rarity, color, income) in enumerate(CHARS):
        row, col = i // 3, i % 3
        ox, oy = 20 + col * cw, 80 + row * ch
        sprite = render_character(designs, cid, color, (cw, ch - 86))
        img.alpha_composite(sprite, (ox, oy))
        rc = RARITY_COLORS[rarity]
        cx = ox + cw / 2
        draw.text((cx, oy + ch - 80), name, font=font(21), fill=rc, anchor="ma")
        draw.text((cx, oy + ch - 54), f"${income:,}/s".replace(",", "."), font=font(16),
                  fill=(255, 255, 255), anchor="ma")
        draw.text((cx, oy + ch - 33), rarity, font=font(14), fill=shade(rc, 0.75), anchor="ma")

    for row in range(1, rows):
        draw.line([(20, 80 + row * ch), (img.width - 20, 80 + row * ch)], fill=(58, 62, 78))

    img.convert("RGB").save(out_path)
    print("saved", out_path)


if __name__ == "__main__":
    main()
