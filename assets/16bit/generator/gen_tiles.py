"""Ground tiles: 64x32 isometric diamonds per design/art/isometric-grid-spec.md.

Transparent outside the diamond footprint so Godot's TILE_LAYOUT_DIAMOND_DOWN
row-overlap renders correctly. Same upper-left light + edge-darken + speckle
convention as scripts/world/procedural_tile_art.gd, but with hand-authored
surface detail (furrows, pebbles, waves) on top.
"""
import random

from px import quantize_16bit, canvas, px, rect, save, rgb, speckle_on

TILE_W, TILE_H = 64, 32


def diamond(seed, base, light=0.24, edge=0.52):
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
    # More saturated Stardew-like spring green; higher blade contrast
    img = diamond(seed, rgb(78, 176, 56))
    rng = random.Random(seed + 100)
    for _ in range(30):  # grass blades / tufts
        x, y = rng.randrange(6, TILE_W - 6), rng.randrange(6, TILE_H - 6)
        # 60% dark tuft, 25% bright highlight, 15% tiny yellow flower
        r = rng.random()
        if r < 0.60:
            c = rgb(52, 138, 38)
        elif r < 0.85:
            c = rgb(148, 206, 92)
        else:
            c = rgb(240, 236, 96)
        px(img, x, y, c)
        px(img, x, y - 1, c)
        if r >= 0.85:
            px(img, x + 1, y, c)
    # extra speckle for micro-texture
    return speckle_on(img, seed + 200, 0.06)


def grass_clover(seed=2):
    img = grass(seed)
    rng = random.Random(seed + 300)
    for _ in range(10):
        x, y = rng.randrange(8, TILE_W - 8), rng.randrange(8, TILE_H - 8)
        c = rgb(52, 148, 74)
        px(img, x, y, c); px(img, x + 1, y, c)
        px(img, x, y + 1, c); px(img, x + 1, y + 1, c)
        # tiny white clover dot
        if rng.random() < 0.35:
            px(img, x + 1, y + 1, rgb(236, 240, 228))
    return img


def dirt(seed=3):
    return speckle_on(diamond(seed, rgb(138, 96, 58)), seed + 200, 0.08)


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
    img = diamond(seed, rgb(148, 94, 52))
    _furrows(img, seed, rgb(92, 60, 30))
    # a few pebble highlights for texture
    rng = random.Random(seed + 250)
    for _ in range(5):
        x, y = rng.randrange(10, TILE_W - 10), rng.randrange(10, TILE_H - 10)
        px(img, x, y, rgb(168, 118, 72))
    return speckle_on(img, seed + 200, 0.07)


def farmland_watered(seed=5):
    img = diamond(seed, rgb(62, 48, 38), light=0.14)
    _furrows(img, seed, rgb(44, 36, 30))
    # water sheen: 2-3 glossy pixels near furrow bottom
    rng = random.Random(seed + 260)
    for _ in range(4):
        x, y = rng.randrange(10, TILE_W - 10), rng.randrange(10, TILE_H - 10)
        px(img, x, y, rgb(86, 72, 62))
        px(img, x + 1, y, rgb(98, 84, 72))
    return speckle_on(img, seed + 200, 0.05)


def path(seed=6):
    img = diamond(seed, rgb(198, 168, 116))
    rng = random.Random(seed + 400)
    for _ in range(14):  # embedded pebbles with shadow/highlight pair
        x, y = rng.randrange(8, TILE_W - 8), rng.randrange(8, TILE_H - 8)
        dark = rgb(160, 134, 90)
        light = rgb(218, 192, 142)
        c = dark if rng.random() < 0.5 else light
        px(img, x, y, c); px(img, x + 1, y, c)
        # tiny shadow under pebble
        px(img, x, y + 1, rgb(150, 124, 84))
    return speckle_on(img, seed + 200, 0.05)


def sand(seed=7):
    img = speckle_on(diamond(seed, rgb(228, 214, 156)), seed + 200, 0.05)
    rng = random.Random(seed + 310)
    for _ in range(5):
        x, y = rng.randrange(10, TILE_W - 10), rng.randrange(10, TILE_H - 10)
        px(img, x, y, rgb(244, 230, 176))
        px(img, x + 1, y, rgb(210, 194, 136))
    return img


def water(seed, phase):
    img = diamond(seed, rgb(58, 122, 184), light=0.18, edge=0.32)
    rng = random.Random(seed + 500)
    for _ in range(8):  # wave glints, shifted per animation phase
        x = rng.randrange(8, TILE_W - 16)
        y = rng.randrange(8, TILE_H - 8)
        for i in range(5):
            px(img, x + i + phase, y + (i % 2), rgb(170, 214, 240))
        # deeper wave shadow under glint
        for i in range(3):
            px(img, x + i + phase, y + 2, rgb(40, 90, 144))
    return img


def mine_floor(seed=8):
    img = diamond(seed, rgb(64, 58, 54), light=0.16)
    rng = random.Random(seed + 600)
    for _ in range(12):  # cracks / pebbles with highlight edge
        x, y = rng.randrange(8, TILE_W - 8), rng.randrange(8, TILE_H - 8)
        px(img, x, y, rgb(42, 38, 34)); px(img, x + 1, y, rgb(42, 38, 34))
        px(img, x, y + 1, rgb(78, 72, 68))
    return speckle_on(img, seed + 200, 0.07)


def mine_rock(seed=9):
    img = diamond(seed, rgb(108, 104, 99), light=0.24)
    rng = random.Random(seed + 700)
    for _ in range(7):  # lighter bump highlights + shadow
        x, y = rng.randrange(12, TILE_W - 12), rng.randrange(8, TILE_H - 10)
        px(img, x, y, rgb(148, 144, 138)); px(img, x + 1, y, rgb(136, 132, 126))
        px(img, x, y + 1, rgb(82, 78, 74))
    return speckle_on(img, seed + 200, 0.06)


def snow(seed=10):
    img = diamond(seed, rgb(232, 240, 248), light=0.10, edge=0.28)
    rng = random.Random(seed + 800)
    for _ in range(7):
        x, y = rng.randrange(10, TILE_W - 10), rng.randrange(8, TILE_H - 8)
        px(img, x, y, rgb(200, 214, 232))
        px(img, x + 1, y, rgb(212, 224, 238))
    # soft blue ambient shadow in corner
    for x in range(6, 14):
        for y in range(18, 24):
            if img.getpixel((x, y))[3] > 0:
                px(img, x, y, rgb(210, 222, 238))
    return img


def wood_floor(seed=11):
    img = diamond(seed, rgb(168, 124, 74), light=0.16)
    for k in range(-2, 3):  # plank seams + grain highlight
        for x in range(TILE_W):
            y = TILE_H // 2 + (x - TILE_W // 2) // 2 + k * 6
            if 0 <= y < TILE_H and img.getpixel((x, y))[3] > 0:
                px(img, x, y, rgb(120, 86, 48))
                if x % 8 == 0:
                    px(img, x, y - 1, rgb(188, 146, 88))
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
