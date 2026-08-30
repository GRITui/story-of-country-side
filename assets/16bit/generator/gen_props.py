"""Environment props & structures: trees, rocks, forage patches, and the
buildings FarmScene/RanchScene/ForageScene/MineScene would place (farmhouse,
barn, coop, well, fence, shipping bin, mine ladder, mining cart).

Each is a standalone Sprite2D asset - placed as fixed sprites (not TileMap
floor tiles) per the convention locked in squad-handshake-art.md. Sizes
are multiples of the 64x32 iso grid footprint so a building sits cleanly
over a tile group. Anchored bottom-center.
"""
from px import quantize_16bit, canvas, ellipse, outline, px, rect, rgb, save


def _tree_simple(seed_variant, trunk=(112, 82, 48), canopy=(84, 140, 62), w=48, h=60):
    img = canvas(w, h)
    cx = w // 2
    ellipse(img, cx, h - 2, 12, 3, (0, 0, 0, 72))
    # trunk with vertical highlight
    rect(img, cx - 3, h - 24, cx + 3, h - 2, trunk)
    rect(img, cx - 1, h - 24, cx, h - 2, (min(255, trunk[0]+22), min(255, trunk[1]+18), trunk[2]))
    rect(img, cx + 2, h - 24, cx + 3, h - 2, (max(0, trunk[0]-18), max(0, trunk[1]-14), max(0, trunk[2]-10)))
    # layered canopy: shadow base + main + highlight tufts
    shadow = (max(0, canopy[0]-28), max(0, canopy[1]-26), max(0, canopy[2]-18))
    highlight = (min(255, canopy[0]+32), min(255, canopy[1]+36), min(255, canopy[2]+26))
    ellipse(img, cx - 11, h - 26, 9, 7, shadow)
    ellipse(img, cx + 11, h - 26, 9, 7, shadow)
    ellipse(img, cx, h - 22, 9, 5, shadow)
    ellipse(img, cx - 11, h - 28, 8, 6, canopy)
    ellipse(img, cx + 11, h - 28, 8, 6, canopy)
    ellipse(img, cx, h - 36, 10, 9, canopy)
    ellipse(img, cx - 6, h - 30, 9, 6, canopy)
    ellipse(img, cx + 6, h - 30, 9, 6, canopy)
    ellipse(img, cx, h - 22, 8, 4, (70, 120, 54))
    # top highlight tufts
    ellipse(img, cx - 4, h - 38, 4, 3, highlight)
    ellipse(img, cx + 5, h - 32, 3, 2, highlight)
    if seed_variant:
        ellipse(img, cx + 4, h - 38, 4, 3, (110, 170, 76))
        # autumn speckle reds
        px(img, cx - 6, h - 30, rgb(196, 96, 48))
        px(img, cx + 7, h - 28, rgb(196, 96, 48))
    return outline(img)


def _pine(canopy=(52, 112, 88), trunk=(96, 68, 44), w=40, h=56):
    img = canvas(w, h)
    cx = w // 2
    ellipse(img, cx, h - 2, 8, 3, (0, 0, 0, 72))
    rect(img, cx - 2, h - 14, cx + 2, h - 2, trunk)
    rect(img, cx - 1, h - 14, cx, h - 2, (min(255, trunk[0]+20), min(255, trunk[1]+16), trunk[2]))
    for i in range(3):
        ty = h - 40 + i * 11
        tw = 10 + (2 - i) * 3
        # shadow layer slightly offset
        rect(img, cx - tw + 1, ty + 1, cx + tw + 1, ty + 9, (max(0, canopy[0]-20), max(0, canopy[1]-18), max(0, canopy[2]-14)))
        rect(img, cx - tw, ty, cx + tw, ty + 8, canopy)
        px(img, cx - tw + 2, ty + 2, (110, 160, 136))
        px(img, cx + tw - 3, ty + 4, (42, 92, 72))
    px(img, cx, h - 44, canopy)
    px(img, cx + 1, h - 44, (130, 180, 150))  # tip highlight
    return outline(img)


def _bush(canopy=(72, 138, 54), w=28, h=18):
    img = canvas(w, h)
    cx = w // 2
    ellipse(img, cx, h - 2, 9, 3, (0, 0, 0, 60))
    shadow = (max(0, canopy[0]-22), max(0, canopy[1]-20), max(0, canopy[2]-16))
    highlight = (min(255, canopy[0]+38), min(255, canopy[1]+32), min(255, canopy[2]+28))
    ellipse(img, cx - 6, h - 6, 6, 4, shadow)
    ellipse(img, cx + 6, h - 6, 6, 4, shadow)
    ellipse(img, cx, h - 9, 7, 5, shadow)
    ellipse(img, cx - 6, h - 7, 6, 4, canopy)
    ellipse(img, cx + 6, h - 7, 6, 4, canopy)
    ellipse(img, cx, h - 10, 7, 5, canopy)
    px(img, cx - 3, h - 6, highlight); px(img, cx + 3, h - 6, highlight)
    px(img, cx, h - 11, highlight)
    return outline(img)


def _rock(w=28, h=18, c1=(138, 134, 128), c2=(100, 96, 92)):
    img = canvas(w, h)
    cx = w // 2
    ellipse(img, cx, h - 1, 9, 3, (0, 0, 0, 60))
    rect(img, cx - 8, h - 10, cx + 8, h - 3, c1)
    rect(img, cx - 6, h - 13, cx + 4, h - 9, c1)
    px(img, cx - 4, h - 9, (170, 166, 160))
    px(img, cx + 3, h - 6, (116, 112, 108))
    # dark underside
    rect(img, cx - 8, h - 4, cx + 8, h - 3, (max(0, c1[0]-30), max(0, c1[1]-30), max(0, c1[2]-28)))
    return outline(img)


def _fruit_tree():  # apple-ish tree, distinct from plain trees
    img = canvas(48, 60)
    cx = 24
    ellipse(img, cx, 58, 12, 3, (0, 0, 0, 70))
    rect(img, cx - 3, 36, cx + 3, 58, (112, 82, 48))
    rect(img, cx - 1, 36, cx, 58, (134, 102, 64))
    shadow = (62, 118, 50)
    highlight = (116, 172, 84)
    ellipse(img, cx - 11, 32, 8, 6, shadow)
    ellipse(img, cx + 11, 32, 8, 6, shadow)
    ellipse(img, cx, 24, 10, 9, shadow)
    ellipse(img, cx - 11, 31, 8, 6, (82, 148, 66))
    ellipse(img, cx + 11, 31, 8, 6, (82, 148, 66))
    ellipse(img, cx, 23, 10, 9, (82, 148, 66))
    ellipse(img, cx - 4, 20, 4, 3, highlight)
    for (bx, by) in ((20, 28), (27, 25), (22, 20), (28, 29), (18, 22)):
        ellipse(img, bx, by, 2, 2, (214, 82, 66))
        px(img, bx, by - 1, (238, 150, 130))  # fruit highlight
    return outline(img)


# ---------- buildings ----------

def _build_cube(w, h, color, roof, door_pos=None, accent=None):
    img = canvas(w, h)
    # lit left face + shaded right face (iso convention)
    left = color
    right = (max(0, color[0] - 26), max(0, color[1] - 26), max(0, color[2] - 26))
    top = (min(255, color[0] + 30), min(255, color[1] + 30), min(255, color[2] + 30))
    bw = int(w * 0.56)
    bh = int(h * 0.42)
    bx = (w - bw) // 2
    by = h - bh - 6
    # front faces
    for yy in range(by, by + bh):
        for xx in range(bx, bx + bw):
            img.putpixel((xx, yy), left if xx < bx + bw // 2 else right)
    # roof (upper-left lit)
    roof_y = by
    for i in range(0, bw // 2 + 1):
        c = left if i == 0 else roof
        rect(img, bx + i, roof_y + i, bx + bw - i, roof_y + i, c)
    # door shadow hint
    if door_pos:
        rect(img, bx + door_pos[0], by + bh - 10, bx + door_pos[0] + 8, by + bh - 1, (60, 52, 44))
    return outline(img)


def _farmhouse():
    img = canvas(96, 72)
    # base
    wall = (196, 150, 96)
    for yy in range(34, 70):
        for xx in range(10, 90):
            img.putpixel((xx, yy), wall if xx < 50 else (168, 128, 84))
    # roof
    for i in range(0, 41):
        rect(img, 10 + i, 34 - i, 89 - i, 34 - i, (156, 56, 52))
    # chimney
    rect(img, 60, 6, 68, 26, (124, 96, 66))
    px(img, 62, 4, (150, 122, 90)); px(img, 66, 4, (150, 122, 90))
    # door
    rect(img, 40, 56, 52, 69, (82, 60, 42))
    # window
    rect(img, 22, 46, 30, 54, (150, 190, 210))
    rect(img, 62, 46, 70, 54, (150, 190, 210))
    ellipse(img, 48, 70, 26, 4, (0, 0, 0, 70))
    return outline(img)


def _barn():
    img = canvas(96, 70)
    for yy in range(40, 68):
        for xx in range(8, 88):
            img.putpixel((xx, yy), (168, 52, 50) if xx < 48 else (140, 42, 42))
    for i in range(0, 33):
        rect(img, 8 + i, 40 - i // 2, 87 - i, 40 - i // 2, (96, 92, 96))
    rect(img, 40, 58, 50, 68, (74, 48, 36))
    rect(img, 24, 50, 32, 58, (200, 192, 176))
    ellipse(img, 48, 68, 30, 4, (0, 0, 0, 70))
    return outline(img)


def _coop():
    img = canvas(56, 44)
    for yy in range(26, 42):
        for xx in range(8, 48):
            img.putpixel((xx, yy), (210, 196, 168) if xx < 28 else (184, 170, 146))
    for i in range(0, 14):
        rect(img, 8 + i, 26 - i, 47 - i, 26 - i, (172, 92, 56))
    rect(img, 22, 36, 30, 42, (92, 66, 44))
    ellipse(img, 28, 42, 16, 3, (0, 0, 0, 60))
    return outline(img)


def _well():
    img = canvas(40, 40)
    ellipse(img, 20, 37, 13, 4, (0, 0, 0, 60))
    rect(img, 12, 18, 28, 34, (150, 148, 148))
    rect(img, 12, 16, 16, 20, (150, 148, 148)); rect(img, 24, 16, 28, 20, (150, 148, 148))
    rect(img, 11, 18, 29, 22, (120, 118, 118))
    rect(img, 8, 20, 12, 34, (110, 92, 62))   # posts
    rect(img, 28, 20, 32, 34, (110, 92, 62))
    rect(img, 8, 14, 32, 16, (110, 92, 62))   # roof beam
    rect(img, 20, 30, 24, 33, (70, 70, 74))   # bucket
    return outline(img)


def _fence(horizontal=True):
    wood = (146, 108, 62)
    if horizontal:
        img = canvas(48, 20)
        rect(img, 0, 6, 47, 9, wood)
        rect(img, 0, 12, 47, 15, wood)
        for px_ in (4, 22, 40):
            rect(img, px_, 2, px_ + 4, 18, wood)
    else:
        img = canvas(16, 44)
        rect(img, 3, 0, 12, 43, wood)
        rect(img, 0, 8, 15, 12, wood)
        rect(img, 0, 18, 15, 22, wood)
    return outline(img)


def _shipping_bin():
    img = canvas(40, 36)
    rect(img, 10, 16, 32, 32, (150, 100, 56))   # crate body
    rect(img, 8, 10, 34, 16, (176, 120, 66))    # lid
    rect(img, 12, 8, 30, 10, (150, 100, 56))
    rect(img, 14, 20, 16, 26, (120, 80, 44))    # slats
    rect(img, 20, 20, 22, 26, (120, 80, 44))
    rect(img, 26, 20, 28, 26, (120, 80, 44))
    ellipse(img, 20, 32, 14, 3, (0, 0, 0, 60))
    return outline(img)


def _ladder():
    img = canvas(28, 44)
    wood = (156, 118, 70)
    rect(img, 8, 0, 10, 43, wood); rect(img, 18, 0, 20, 43, wood)
    for y in range(4, 42, 6):
        rect(img, 9, y, 19, y + 2, wood)
    return outline(img)


def _mine_cart():
    img = canvas(48, 34)
    rect(img, 12, 16, 38, 28, (120, 74, 50))    # cart body
    rect(img, 10, 14, 40, 17, (140, 88, 58))    # top lip
    ellipse(img, 20, 32, 5, 5, (70, 66, 62))    # wheels
    ellipse(img, 32, 32, 5, 5, (70, 66, 62))
    px(img, 17, 20, (214, 178, 100))            # ore inside
    px(img, 21, 19, (214, 178, 100)); px(img, 26, 21, (214, 178, 100))
    ellipse(img, 24, 30, 16, 3, (0, 0, 0, 60))
    return outline(img)


PROPS = {
    "tree": lambda: _tree_simple(False),
    "tree_2": lambda: _tree_simple(True, canopy=(150, 120, 60)),   # autumn
    "pine": _pine,
    "fruit_tree": _fruit_tree,
    "bush": _bush,
    "rock": _rock,
    "rock_large": lambda: _rock(40, 26, (140, 138, 134), (108, 106, 104)),
    "farmhouse": _farmhouse,
    "barn": _barn,
    "coop": _coop,
    "well": _well,
    "fence_h": lambda: _fence(True),
    "fence_v": lambda: _fence(False),
    "shipping_bin": _shipping_bin,
    "ladder": _ladder,
    "mine_cart": _mine_cart,
}


def main():
    for name, gen in PROPS.items():
        save(gen(), "props", f"{name}.png")


if __name__ == "__main__":
    main()
