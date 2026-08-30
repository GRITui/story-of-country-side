"""JRL Option B — Cozy Corner item icons (issue #190).

16x16 icons for the three cozy activities at launch (see
design/systems/cozy-activities-spec.md): matcha tea set (chawan bowl +
bamboo chasen whisk), ikebana (celadon vase, 2 stems, 1 blossom),
journal (washi-bound book + calligraphy brush). Merged strip
`items/cozy_sheet.png` (48x16, order: tea_set, ikebana, journal).

Sel-out #4A3320, pastel Ghibli, transparent backgrounds. Palette keyed
to jp-world-palette-lighting.md: matcha/spring greens, sakura blossom
pinks, washi paper, bamboo, winter-warm accent red for binding thread.
"""
from px import canvas, ellipse, px, rect, rgb
from jp_import import save_with_import

S = 16
SEL = rgb(0x4A, 0x33, 0x20)  # sel-out

# shared palette
BAMBOO, BAMBOO_D = rgb(201, 184, 150), rgb(168, 152, 104)
STEM, LEAF = rgb(58, 107, 42), rgb(90, 154, 58)
MATCHA, MATCHA_HI, MATCHA_DK = rgb(90, 154, 58), rgb(123, 196, 90), rgb(58, 107, 42)
BLOSSOM, BLOSSOM_D, CENTER = rgb(248, 200, 216), rgb(240, 160, 184), rgb(232, 120, 152)


def icon_tea_set(img):
    """Chawan (dark indigo raku) with matcha pool + chasen whisk."""
    bowl, bowl_hi, bowl_d = rgb(58, 58, 74), rgb(90, 98, 122), rgb(38, 38, 52)
    # whisk (chasen): handle up, tines splayed down onto the table
    rect(img, 12, 2, 13, 6, BAMBOO)
    px(img, 12, 2, BAMBOO_D)
    rect(img, 12, 3, 13, 3, BAMBOO_D)  # node band
    for x in range(10, 16):  # tine fan
        px(img, x, 7, BAMBOO)
    for x in (11, 12, 13, 14):
        for y in range(8, 12):
            px(img, x, y, BAMBOO)
    px(img, 10, 8, BAMBOO); px(img, 10, 9, BAMBOO)
    px(img, 15, 8, BAMBOO); px(img, 15, 9, BAMBOO)
    px(img, 11, 12, BAMBOO_D); px(img, 14, 12, BAMBOO_D)  # tine tips
    px(img, 12, 9, BAMBOO_D); px(img, 13, 9, BAMBOO_D)  # tine separation
    # bowl: rim + matcha pool, then body below
    ellipse(img, 5, 8, 4, 2, bowl_hi)
    ellipse(img, 5, 8, 3, 1, MATCHA)
    px(img, 4, 7, MATCHA_HI)  # froth glint
    rect(img, 2, 9, 8, 11, bowl)
    px(img, 2, 10, bowl_hi); px(img, 2, 11, bowl_hi)  # left light
    px(img, 8, 10, bowl_d); px(img, 8, 11, bowl_d)  # right shade
    rect(img, 4, 12, 6, 12, bowl_d)
    rect(img, 4, 13, 6, 13, bowl)  # foot ring
    px(img, 1, 9, SEL); px(img, 1, 10, SEL)  # sel-out left edge
    px(img, 9, 9, SEL); px(img, 9, 10, SEL)  # sel-out right edge


def icon_ikebana(img):
    """Celadon vase, tall blossoming stem + one leaning bare stem."""
    vase, vase_d, vase_hi = rgb(154, 196, 176), rgb(122, 160, 144), rgb(196, 224, 208)
    # tall stem with one sakura blossom
    for y in range(3, 8):
        px(img, 6, y, STEM)
    px(img, 6, 0, BLOSSOM_D)
    px(img, 5, 1, BLOSSOM); px(img, 7, 1, BLOSSOM); px(img, 6, 2, BLOSSOM)
    px(img, 6, 1, CENTER)
    px(img, 5, 4, LEAF)  # small leaf off the tall stem
    # leaning bare stem, up to the right
    for x, y in ((7, 6), (8, 6), (9, 5), (10, 4), (11, 3)):
        px(img, x, y, STEM)
    px(img, 9, 4, LEAF); px(img, 10, 5, LEAF)
    # vase: rim, neck, rounded body, foot
    rect(img, 5, 7, 8, 7, vase_hi)
    rect(img, 6, 8, 7, 8, vase)
    ellipse(img, 7, 11, 4, 3, vase)
    for y in range(9, 13):
        px(img, 10, y, vase_d)  # right shade
    px(img, 9, 13, vase_d)
    px(img, 5, 10, vase_hi); px(img, 5, 11, vase_hi)  # left light
    rect(img, 5, 14, 9, 14, vase_d)


def icon_journal(img):
    """Washi-bound book (thread stitching, title slip, hanko) + brush."""
    washi, washi_sh, edge = rgb(244, 238, 223), rgb(228, 218, 196), rgb(184, 168, 136)
    thread, slip, hanko = rgb(176, 48, 48), rgb(248, 248, 240), rgb(217, 74, 74)
    bristle = rgb(58, 42, 42)
    # book body with spine shading and corner edges
    rect(img, 2, 4, 10, 13, washi)
    for y in range(5, 13):
        px(img, 10, y, washi_sh)  # right shade
        px(img, 3, y, washi_sh)   # spine shade
    for x in range(3, 11):
        px(img, x, 13, washi_sh)  # bottom shade
    px(img, 2, 4, edge); px(img, 10, 4, edge)
    px(img, 2, 13, edge); px(img, 10, 13, edge)
    for y in (5, 7, 9, 11):  # stab-binding thread, red
        px(img, 2, y, thread)
    # title slip + hanko seal
    rect(img, 6, 6, 8, 10, slip)
    px(img, 7, 7, edge)
    px(img, 7, 9, hanko)
    # calligraphy brush resting diagonally across the top-right corner
    px(img, 13, 2, BAMBOO); px(img, 12, 3, BAMBOO)
    px(img, 11, 4, SEL)  # collar
    px(img, 10, 5, bristle); px(img, 10, 6, bristle)
    px(img, 9, 7, bristle)  # ink tip on the page


def _paste(dst, src, ox, oy):
    sp = src.load()
    for y in range(src.height):
        for x in range(src.width):
            r, g, b, a = sp[x, y]
            if a:
                dst.putpixel((ox + x, oy + y), (r, g, b, a))


def main():
    icons = [
        ("icon_tea_set", icon_tea_set),
        ("icon_ikebana", icon_ikebana),
        ("icon_journal", icon_journal),
    ]
    sheet = canvas(48, 16)
    for col, (name, fn) in enumerate(icons):
        img = canvas(S, S)
        fn(img)
        save_with_import(img, "items", f"{name}.png")
        _paste(sheet, img, col * 16, 0)
    save_with_import(sheet, "items", "cozy_sheet.png")


if __name__ == "__main__":
    main()
