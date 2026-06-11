# Shared isometric rendering primitives (same camera as the roblox-game tools).
from PIL import Image, ImageDraw, ImageFont

# Camera sees the +X, +Y and -Z faces.
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


def box_corner(c, s, sx, sy, sz):
    return (c[0] + sx * s[0] / 2, c[1] + sy * s[1] / 2, c[2] + sz * s[2] / 2)


def draw_poly(img, points, fill, alpha):
    if alpha >= 255:
        ImageDraw.Draw(img).polygon(points, fill=fill + (255,))
    else:
        layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
        ImageDraw.Draw(layer).polygon(points, fill=fill + (alpha,))
        img.alpha_composite(layer)


def draw_box(img, c, s, color, alpha, k, ox, oy):
    faces = [
        ([(-1, 1, -1), (1, 1, -1), (1, 1, 1), (-1, 1, 1)], 1.18),      # top (+y)
        ([(-1, 1, -1), (1, 1, -1), (1, -1, -1), (-1, -1, -1)], 0.95),  # front (-z)
        ([(1, 1, -1), (1, 1, 1), (1, -1, 1), (1, -1, -1)], 0.68),      # right (+x)
    ]
    for corners, light in faces:
        pts = [project(box_corner(c, s, *cs), k, ox, oy) for cs in corners]
        draw_poly(img, pts, shade(color, light), alpha)


def fit(parts_or_corners, width, pad=20, corners=False):
    pts = []
    if corners:
        pts = parts_or_corners
    else:
        for part in parts_or_corners:
            for sx in (-1, 1):
                for sy in (-1, 1):
                    for sz in (-1, 1):
                        pts.append(box_corner(part["p"], part["s"], sx, sy, sz))
    xs = [dot(p, RIGHT) for p in pts]
    ys = [-dot(p, UP) for p in pts]
    k = (width - 2 * pad) / (max(xs) - min(xs))
    height = int(k * (max(ys) - min(ys))) + 2 * pad
    ox = pad - k * min(xs)
    oy = pad - k * min(ys)
    return k, ox, oy, height


def sort_key(part):
    return (part["p"][1] - part["s"][1] / 2, dot(part["p"], DEPTH))
