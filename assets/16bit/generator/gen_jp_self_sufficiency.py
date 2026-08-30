"""JRL self-sufficiency items (issue #187): salt / miso / tofu chain icons.

Seven 16x16 harvest/craft icons for the self-sufficiency loops spec'd in
`design/systems/self-sufficiency-spec.md`:

  salt     — white salt mound in a wooden drying tray
  miso     — brown paste crock, cream cloth lid, red tie string
  tofu     — pale pressed block, water sheen at the base
  koji     — cream rice bed with white mold-fuzz clumps
  soybean  — tan beans heaped in a woven bamboo basket
  seaweed  — tied bundle of dark kombu strips
  nigari   — small amber bittern bottle

Saved individually to `items/icon_<name>.png` and combined into
`items/self_sufficiency_sheet.png` (7 x 16 = 112x16, order as above).

Sel-out #4A3320, pastel Ghibli, 16x16 cells, transparent backgrounds.
"""
from px import canvas, ellipse, px, rect, rgb
from jp_import import save_with_import

S = 16
SEL = rgb(0x4A, 0x33, 0x20)  # sel-out


def icon_salt(img):
    w, w_hi, w_sh = rgb(248, 248, 240), rgb(252, 252, 248), rgb(224, 228, 236)
    wood, wood_d = rgb(201, 164, 108), rgb(139, 111, 71)
    # mound: tall white pyramid, clearly taller than koji's flat bed
    rect(img, 7, 5, 8, 5, w)
    rect(img, 6, 6, 9, 6, w)
    rect(img, 5, 7, 10, 7, w)
    rect(img, 4, 8, 11, 8, w)
    rect(img, 4, 9, 11, 9, w)
    px(img, 6, 7, w_hi); px(img, 7, 6, w_hi)      # top-left light
    px(img, 4, 9, w_sh); px(img, 11, 9, w_sh)      # base shade
    px(img, 10, 8, w_sh)
    # wooden tray
    rect(img, 2, 10, 13, 10, wood)
    px(img, 2, 10, wood_d); px(img, 13, 10, wood_d)  # rim end caps
    rect(img, 3, 11, 12, 12, rgb(184, 148, 100))
    rect(img, 4, 13, 11, 13, wood_d)
    px(img, 4, 13, SEL); px(img, 11, 13, SEL)


def icon_miso(img):
    cloth, cloth_d = rgb(240, 230, 208), rgb(214, 198, 168)
    tie = rgb(217, 74, 74)
    body, body_d, body_hi = rgb(139, 94, 58), rgb(107, 70, 42), rgb(168, 122, 74)
    # cloth lid dome, overhangs the crock body
    ellipse(img, 8, 5, 5, 3, cloth)
    rect(img, 3, 7, 12, 7, cloth_d)                # cloth bottom edge
    rect(img, 3, 8, 12, 8, tie)                    # red tie string
    px(img, 12, 9, tie)                            # dangling knot
    # crock body (narrower than lid)
    rect(img, 4, 9, 11, 13, body)
    rect(img, 4, 9, 4, 13, body_d); rect(img, 11, 9, 11, 13, body_d)
    rect(img, 4, 14, 11, 14, body_d)
    px(img, 4, 14, SEL); px(img, 11, 14, SEL)
    px(img, 6, 10, body_hi); px(img, 6, 11, body_hi)  # side highlight
    px(img, 5, 4, rgb(248, 240, 224))              # cloth top-left light


def icon_tofu(img):
    top, front, shade = rgb(250, 250, 242), rgb(238, 234, 220), rgb(220, 214, 194)
    water = rgb(170, 205, 225)
    # block: lighter top face, cream front face, visible left edge
    rect(img, 5, 5, 11, 6, top)
    rect(img, 5, 7, 11, 12, front)
    rect(img, 5, 7, 5, 12, shade)                  # left edge
    rect(img, 5, 12, 11, 12, rgb(228, 222, 202))   # base
    px(img, 11, 7, rgb(226, 221, 205))             # top-right corner shade
    px(img, 6, 8, rgb(248, 248, 240)); px(img, 7, 9, rgb(248, 248, 240))  # sheen
    # water line pooling at the base + a drip on the right face
    for x in (4, 6, 8, 10, 12):
        px(img, x, 13, water)
    px(img, 12, 11, water)


def icon_koji(img):
    bed, bed_d = rgb(232, 220, 192), rgb(208, 194, 160)
    grain, fuzz, fuzz_sh = rgb(248, 248, 240), rgb(250, 250, 246), rgb(238, 238, 232)
    # small fluffy mold clumps (satellite dots, not solid blobs)
    px(img, 5, 8, fuzz); px(img, 4, 7, fuzz); px(img, 6, 7, fuzz); px(img, 5, 7, fuzz_sh)
    px(img, 9, 7, fuzz); px(img, 10, 7, fuzz); px(img, 9, 6, fuzz); px(img, 10, 6, fuzz_sh)
    px(img, 12, 9, fuzz)
    px(img, 7, 4, fuzz); px(img, 11, 5, fuzz)      # stray spores
    # low, wide rice bed, visibly grainy (flat silhouette vs. salt's pyramid)
    rect(img, 4, 10, 11, 10, bed)
    rect(img, 3, 11, 12, 12, bed)
    rect(img, 3, 13, 12, 13, bed_d)
    for x, y in ((4, 10), (6, 10), (8, 10), (10, 10),
                 (5, 11), (7, 12), (9, 11), (11, 12), (6, 13), (10, 13)):
        px(img, x, y, grain)                       # visible rice grains
    px(img, 3, 13, SEL); px(img, 12, 13, SEL)


def icon_soybean(img):
    bean, bean_hi, bean_d = rgb(216, 186, 128), rgb(232, 206, 152), rgb(190, 158, 104)
    bask, bask_l, bask_d = rgb(201, 164, 108), rgb(220, 186, 132), rgb(168, 132, 84)
    # heaped beans
    ellipse(img, 8, 7, 4.5, 2.5, bean)
    px(img, 6, 6, bean_hi); px(img, 9, 5, bean_hi); px(img, 10, 8, bean_hi)
    px(img, 5, 8, bean_d); px(img, 11, 7, bean_d)
    # woven bamboo basket (rim covers the heap bottom)
    rect(img, 3, 9, 12, 9, bask_l)
    rect(img, 3, 10, 12, 10, bask)
    rect(img, 4, 11, 11, 13, rgb(190, 152, 96))
    for x in (6, 9):
        for y in (11, 12):
            px(img, x, y, bask_d)                  # weave verticals
    rect(img, 4, 13, 11, 13, rgb(160, 124, 76))
    px(img, 4, 13, SEL); px(img, 11, 13, SEL)


def icon_seaweed(img):
    dark, mid, bloom = rgb(46, 66, 50), rgb(58, 84, 60), rgb(196, 208, 192)
    straw, straw_d = rgb(217, 180, 74), rgb(184, 148, 58)
    # three kombu strips, staggered heights, slight wave
    rect(img, 4, 3, 5, 13, dark)
    rect(img, 7, 2, 8, 13, dark)
    rect(img, 10, 4, 11, 13, dark)
    px(img, 4, 6, mid); px(img, 8, 10, mid); px(img, 11, 7, mid)  # wave kinks
    for x in (5, 8, 11):
        rect(img, x, 3, x, 13, mid) if x != 8 else rect(img, x, 2, x, 13, mid)
    px(img, 4, 5, bloom); px(img, 8, 4, bloom); px(img, 10, 9, bloom)  # salt bloom
    # straw tie band
    rect(img, 3, 8, 12, 8, straw)
    rect(img, 3, 9, 12, 9, straw)
    px(img, 12, 9, straw_d); px(img, 12, 10, straw_d)  # knot tail
    px(img, 3, 13, SEL); px(img, 11, 13, SEL)


def icon_nigari(img):
    cork, glass, amber, amber_d = rgb(201, 184, 150), rgb(232, 200, 140), rgb(212, 168, 96), rgb(184, 132, 64)
    hi = rgb(248, 240, 220)
    rect(img, 7, 2, 8, 3, cork)
    px(img, 7, 2, rgb(168, 152, 104))              # cork shade
    rect(img, 7, 4, 8, 5, glass)                   # neck
    px(img, 6, 6, glass); px(img, 9, 6, glass)     # shoulders
    rect(img, 5, 7, 10, 13, amber)
    rect(img, 5, 10, 10, 13, amber_d)              # settled liquid
    rect(img, 6, 8, 6, 12, hi)                     # glass highlight
    rect(img, 5, 13, 10, 13, rgb(168, 122, 58))    # base
    px(img, 5, 13, SEL); px(img, 10, 13, SEL)


def _paste(dst, src, ox, oy):
    sp = src.load()
    for y in range(src.height):
        for x in range(src.width):
            r, g, b, a = sp[x, y]
            if a:
                dst.putpixel((ox + x, oy + y), (r, g, b, a))


def main():
    icons = [
        ("icon_salt", icon_salt),
        ("icon_miso", icon_miso),
        ("icon_tofu", icon_tofu),
        ("icon_koji", icon_koji),
        ("icon_soybean", icon_soybean),
        ("icon_seaweed", icon_seaweed),
        ("icon_nigari", icon_nigari),
    ]
    sheet = canvas(S * len(icons), S)
    for col, (name, fn) in enumerate(icons):
        img = canvas(S, S)
        fn(img)
        save_with_import(img, "items", f"{name}.png")
        _paste(sheet, img, col * S, 0)
    save_with_import(sheet, "items", "self_sufficiency_sheet.png")


if __name__ == "__main__":
    main()
