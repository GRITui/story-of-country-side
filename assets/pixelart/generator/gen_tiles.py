"""Ground tiles: 64x32 isometric diamonds per design/art/isometric-grid-spec.md.

Transparent outside the diamond footprint so Godot's TILE_LAYOUT_DIAMOND_DOWN
row-overlap renders correctly. Same upper-left light + edge-darken + speckle
convention as scripts/world/procedural_tile_art.gd, but with hand-authored
surface detail (furrows, pebbles, waves) on top.
"""
import random

from px import canvas, px, rect, save, rgb, speckle_on

TILE_W, TILE_H = 64, 32


def diamond(seed, base, light=0.20, edge=0.45):
    img = canvas(TILE_W, TILE_H)
    rng = random.Random(seed)
    p = img.load()
    for y in range(TILE_H):
        for x in range(TILE_W):
            nx = (x + 0.5) / TILE_W - 0.5
            ny = (y + 0.5) / TILE_H - 0.5
            d = abs(nx) + abs(ny)
            if d > 0.5:
                continue
            f = 1.0 + light * (-nx - ny)
            edge_dist = 0.5 - d
            if edge_dist < 0.07:
                f *= 1.0 - edge * (1.0 - edge_dist / 0.07)
            f *= 1.0 + rng.uniform(-0.06, 0.06)
            p[x, y] = (min(255, int(base[0] * f)), min(255, int(base[1] * f)),
                       min(255, int(base[2] * f)), 255)
    return img


def grass(seed=1):
    img = diamond(seed, rgb(96, 156, 70))
    rng = random.Random(seed + 100)
    for _ in range(26):  # grass blades: 2px darker strokes
        x, y = rng.randrange(6, TILE_W - 6), rng.randrange(6, TILE_H - 6)
        c = rgb(70, 124, 52) if rng.random() < 0.7 else rgb(120, 176, 88)
        px(img, x, y, c)
        px(img, x, y - 1, c)
    return speckle_on(img, seed + 200, 0.05)


def grass_clover(seed=2):
    img = grass(seed)
    rng = random.Random(seed + 300)
    for _ in range(8):
        x, y = rng.randrange(8, TILE_W - 8), rng.randrange(8, TILE_H - 8)
        c = rgb(58, 140, 78)
        px(img, x, y, c); px(img, x + 1, y, c)
        px(img, x, y + 1, c); px(img, x + 1, y + 1, c)
    return img


def dirt(seed=3):
    return speckle_on(diamond(seed, rgb(122, 90, 58)), seed + 200, 0.08)


def _furrows(img, seed, dark):
    """Diagonal furrow lines parallel to one diamond edge."""
    rng = random.Random(seed)
    for k in range(-2, 3):
        for x in range(TILE_W):
            y = TILE_H // 2 + (x - TILE_W // 2) // 2 + k * 6
            for dy in (0, 1):
                a = img.getpixel((x, min(TILE_H - 1, max(0, y + dy))))[3]
                if a > 0 and rng.random() < 0.85:
                    px(img, x, y + dy, dark)


def farmland(seed=4):
    img = diamond(seed, rgb(120, 84, 50))
    _furrows(img, seed, rgb(88, 60, 34))
    return speckle_on(img, seed + 200, 0.07)


def farmland_watered(seed=5):
    img = diamond(seed, rgb(74, 62, 52), light=0.12)
    _furrows(img, seed, rgb(52, 44, 38))
    return speckle_on(img, seed + 200, 0.05)


def path(seed=6):
    img = diamond(seed, rgb(186, 158, 108))
    rng = random.Random(seed + 400)
    for _ in range(12):  # embedded pebbles
        x, y = rng.randrange(8, TILE_W - 8), rng.randrange(8, TILE_H - 8)
        c = rgb(150, 126, 84) if rng.random() < 0.5 else rgb(206, 180, 132)
        px(img, x, y, c); px(img, x + 1, y, c)
    return speckle_on(img, seed + 200, 0.05)


def sand(seed=7):
    return speckle_on(diamond(seed, rgb(220, 200, 146)), seed + 200, 0.05)


def water(seed, phase):
    img = diamond(seed, rgb(62, 116, 176), light=0.16, edge=0.30)
    rng = random.Random(seed + 500)
    for _ in range(7):  # wave glints, shifted per animation phase
        x = rng.randrange(8, TILE_W - 16)
        y = rng.randrange(8, TILE_H - 8)
        for i in range(5):
            px(img, x + i + phase, y + (i % 2), rgb(150, 196, 230))
    return img


def mine_floor(seed=8):
    img = diamond(seed, rgb(56, 50, 46), light=0.14)
    rng = random.Random(seed + 600)
    for _ in range(10):  # cracks / pebbles
        x, y = rng.randrange(8, TILE_W - 8), rng.randrange(8, TILE_H - 8)
        px(img, x, y, rgb(40, 36, 33)); px(img, x + 1, y, rgb(40, 36, 33))
    return speckle_on(img, seed + 200, 0.07)


def mine_rock(seed=9):
    img = diamond(seed, rgb(98, 94, 90), light=0.22)
    rng = random.Random(seed + 700)
    for _ in range(6):  # lighter bump highlights
        x, y = rng.randrange(12, TILE_W - 12), rng.randrange(8, TILE_H - 10)
        px(img, x, y, rgb(132, 128, 122)); px(img, x + 1, y, rgb(120, 116, 110))
    return speckle_on(img, seed + 200, 0.06)


def snow(seed=10):
    img = diamond(seed, rgb(226, 234, 242), light=0.08, edge=0.25)
    rng = random.Random(seed + 800)
    for _ in range(6):
        x, y = rng.randrange(10, TILE_W - 10), rng.randrange(8, TILE_H - 8)
        px(img, x, y, rgb(196, 210, 226))
    return img


def wood_floor(seed=11):
    img = diamond(seed, rgb(146, 108, 66), light=0.14)
    for k in range(-2, 3):  # plank seams
        for x in range(TILE_W):
            y = TILE_H // 2 + (x - TILE_W // 2) // 2 + k * 6
            if 0 <= y < TILE_H and img.getpixel((x, y))[3] > 0:
                px(img, x, y, rgb(112, 80, 46))
    return speckle_on(img, seed + 200, 0.05)


def main():
    save(grass(), "tiles", "grass.png")
    save(grass_clover(), "tiles", "grass_clover.png")
    save(dirt(), "tiles", "dirt.png")
    save(farmland(), "tiles", "farmland.png")
    save(farmland_watered(), "tiles", "farmland_watered.png")
    save(path(), "tiles", "path.png")
    save(sand(), "tiles", "sand.png")
    save(water(12, 0), "tiles", "water_0.png")
    save(water(12, 1), "tiles", "water_1.png")
    save(mine_floor(), "tiles", "mine_floor.png")
    save(mine_rock(), "tiles", "mine_rock.png")
    save(snow(), "tiles", "snow.png")
    save(wood_floor(), "tiles", "wood_floor.png")


if __name__ == "__main__":
    main()
