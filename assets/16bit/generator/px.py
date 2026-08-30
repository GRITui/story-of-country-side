"""Shared pixel-art helpers for the Story of Countryside asset pipeline.

Every asset in assets/pixelart/ is generated deterministically by these
scripts (Python 3 + Pillow, no external downloads). Re-run any gen_*.py
to byte-reproduce its PNGs. All output is original work, dedicated CC0
(see assets/pixelart/LICENSE.txt).
"""
import os
import random

from PIL import Image

# assets/pixelart/ (this file lives in assets/pixelart/generator/)
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

TRANSPARENT = (0, 0, 0, 0)
OUTLINE = (26, 26, 46, 255)  # 16-bit SNES outline #1a1a2e

# Strict 16-bit SNES-ish master palette (15 + transparent), BGR555 feel, 4bpp
PALETTE_16 = [
    (248, 248, 240, 255),  # 0 white
    (26, 26, 46, 255),     # 1 outline/black
    (90, 154, 58, 255),    # 2 grass mid #5a9a3a
    (123, 196, 90, 255),   # 3 grass light #7bc45a
    (58, 107, 42, 255),    # 4 grass dark #3a6b2a
    (168, 224, 144, 255),  # 5 grass highlight #a8e090
    (154, 122, 74, 255),   # 6 dirt #9a7a4a
    (122, 90, 58, 255),    # 7 farmland #7a5a3a
    (74, 58, 42, 255),     # 8 wet/dark #4a3a2a
    (232, 220, 192, 255),  # 9 sand #e8dcc0
    (212, 196, 160, 255),  # 10 path #d4c4a0
    (58, 110, 165, 255),   # 11 water mid #3a6ea5
    (90, 142, 197, 255),   # 12 water light #5a8ec5
    (240, 216, 96, 255),   # 13 accent yellow #f0d860
    (217, 74, 74, 255),    # 14 accent red #d94a4a
    (74, 58, 70, 255),     # 15 mine rock shadow placeholder (used as secondary)
]
# Alternate extended 16 used via manual mapping for browns/blues beyond 15


def quantize_16bit(img):
    """Snap every opaque pixel to nearest PALETTE_16 entry (Euclidean RGB), preserve alpha."""
    # Keep transparent as-is
    img = img.copy()
    p = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = p[x, y]
            if a == 0:
                continue
            # nearest palette entry (ignore transparent entry)
            best = PALETTE_16[0]
            best_d = 1e9
            for pr, pg, pb, pa in PALETTE_16:
                dr = r - pr; dg = g - pg; db = b - pb
                d = dr*dr + dg*dg + db*db
                if d < best_d:
                    best_d = d; best = (pr, pg, pb, 255)
            p[x, y] = best
    return img


def canvas(w, h):
    return Image.new("RGBA", (w, h), TRANSPARENT)


def out(*parts):
    path = os.path.join(ROOT, *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    return path


def save(img, *parts):
    path = out(*parts)
    img.save(path)
    print("wrote", os.path.relpath(path, ROOT))
    return path


def rgb(r, g, b):
    return (r, g, b, 255)


def px(img, x, y, c):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((int(x), int(y)), c)


def rect(img, x0, y0, x1, y1, c):
    for y in range(int(y0), int(y1) + 1):
        for x in range(int(x0), int(x1) + 1):
            px(img, x, y, c)


def ellipse(img, cx, cy, rx, ry, c):
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            nx = (x + 0.5 - cx) / max(rx, 0.5)
            ny = (y + 0.5 - cy) / max(ry, 0.5)
            if nx * nx + ny * ny <= 1.0:
                px(img, x, y, c)


def scale_color(c, f):
    return (min(255, int(c[0] * f)), min(255, int(c[1] * f)),
            min(255, int(c[2] * f)), c[3] if len(c) > 3 else 255)


def outline(img, color=OUTLINE):
    """1px dark outline around opaque regions, composited behind the art."""
    alpha = img.split()[3].load()
    back = canvas(img.width, img.height)
    bp = back.load()
    for y in range(img.height):
        for x in range(img.width):
            if alpha[x, y] != 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < img.width and 0 <= ny < img.height and alpha[nx, ny] > 0:
                    bp[x, y] = color
                    break
    return Image.alpha_composite(back, img)


def shade_v(img, top=1.08, bottom=0.88, seed=0, speckle=0.0):
    """Vertical light gradient (upper-left light convention from
    scripts/world/procedural_tile_art.gd) + optional deterministic speckle."""
    rng = random.Random(seed)
    img = img.copy()
    p = img.load()
    for y in range(img.height):
        t = y / max(1, img.height - 1)
        f = top + (bottom - top) * t
        for x in range(img.width):
            r, g, b, a = p[x, y]
            if a == 0:
                continue
            fs = f * (1.0 + rng.uniform(-speckle, speckle)) if speckle else f
            p[x, y] = (min(255, int(r * fs)), min(255, int(g * fs)),
                       min(255, int(b * fs)), a)
    return img


def speckle_on(img, seed, strength=0.10):
    """Deterministic per-pixel brightness jitter, opaque pixels only."""
    rng = random.Random(seed)
    img = img.copy()
    p = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = p[x, y]
            if a == 0:
                continue
            f = 1.0 + rng.uniform(-strength, strength)
            p[x, y] = (min(255, int(r * f)), min(255, int(g * f)),
                       min(255, int(b * f)), a)
    return img


def flip_h(img):
    return img.transpose(Image.FLIP_LEFT_RIGHT)
