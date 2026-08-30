"""Character sprites: player + 6 named NPCs.

Per character:
  characters/<name>.png          walk sheet, 48x120: 3 rows x 2 frames.
                                 Row 0 = facing down, row 1 = facing up,
                                 row 2 = facing side (flip horizontally at
                                 runtime for the opposite side). Frame size
                                 24x40, anchor = bottom-center (feet), per
                                 design/art/isometric-grid-spec.md section 4.
  characters/portrait_<name>.png 32x32 dialogue/relationship portrait.

Palettes reflect the cast archetypes established in
scripts/social/gift_preferences/*.tres (Colton = miner/blacksmith,
Sana = rancher, Tobias = treasure hunter, etc.).
"""
from px import quantize_16bit, canvas, px, rect, ellipse, save, outline, shade_v, rgb

FRAME_W, FRAME_H = 24, 40

CHARACTERS = {
    "player": dict(skin=rgb(242, 210, 172), hair=rgb(88, 54, 28),
                   shirt=rgb(72, 160, 72), pants=rgb(68, 92, 168),
                   style="short"),
    "colton": dict(skin=rgb(228, 190, 152), hair=rgb(48, 36, 30),
                   shirt=rgb(86, 86, 96), pants=rgb(112, 84, 52),
                   style="beard"),
    "elena": dict(skin=rgb(248, 218, 188), hair=rgb(232, 200, 92),
                  shirt=rgb(176, 132, 210), pants=rgb(176, 132, 210),
                  style="long", dress=True),
    "marcus": dict(skin=rgb(218, 172, 136), hair=rgb(178, 178, 184),
                   shirt=rgb(62, 132, 128), pants=rgb(96, 84, 68),
                   style="short"),
    "priya": dict(skin=rgb(178, 128, 92), hair=rgb(30, 22, 20),
                  shirt=rgb(214, 84, 56), pants=rgb(232, 184, 72),
                  style="long", dress=True),
    "sana": dict(skin=rgb(240, 202, 162), hair=rgb(158, 78, 38),
                 shirt=rgb(192, 58, 52), pants=rgb(78, 98, 164),
                 style="ponytail"),
    "tobias": dict(skin=rgb(234, 196, 156), hair=rgb(116, 86, 48),
                   shirt=rgb(206, 180, 108), pants=rgb(98, 86, 60),
                   style="hat"),
}


def draw_frame(p, direction, frame):
    img = canvas(FRAME_W, FRAME_H)
    cx = FRAME_W // 2
    # ground-contact shadow
    ellipse(img, cx, 38, 7, 2, (0, 0, 0, 70))
    # legs + boots (walk cycle: alternate stride)
    step = 1 if frame == 1 else -1
    for i, lx in enumerate((cx - 5, cx + 1)):
        s = step if i == 0 else -step
        if direction == "side":
            s = s * 2
        else:
            s = 0
        rect(img, lx + (s if frame == 1 else 0), 28, lx + 4, 35, p["pants"])
        rect(img, lx + (s if frame == 1 else 0), 36, lx + 4, 37, rgb(62, 48, 38))
    if p.get("dress"):  # skirt covers legs
        rect(img, cx - 6, 18, cx + 6, 33, p["shirt"])
        rect(img, cx - 7, 30, cx + 7, 33, p["shirt"])
    else:
        rect(img, cx - 6, 18, cx + 6, 28, p["shirt"])
    # arms
    arm_c = p["shirt"]
    rect(img, cx - 8, 19, cx - 7, 26, arm_c)
    rect(img, cx + 7, 19, cx + 8, 26, arm_c)
    rect(img, cx - 8, 27, cx - 7, 28, p["skin"])
    rect(img, cx + 7, 27, cx + 8, 28, p["skin"])
    # collar highlight
    rect(img, cx - 6, 18, cx + 6, 19, tuple(list(p["shirt"][:3])))
    # head
    rect(img, cx - 4, 7, cx + 5, 15, p["skin"])
    px(img, cx - 5, 10, p["skin"]); px(img, cx + 6, 10, p["skin"])  # ears
    # face
    if direction == "down":
        px(img, cx - 2, 11, rgb(40, 32, 28)); px(img, cx + 3, 11, rgb(40, 32, 28))
        px(img, cx, 14, rgb(196, 120, 96))
    elif direction == "side":
        px(img, cx + 2, 11, rgb(40, 32, 28)); px(img, cx + 3, 11, rgb(40, 32, 28))
        px(img, cx + 4, 13, p["skin"])  # nose hint
    # hair / hat
    h = p["hair"]
    st = p["style"]
    rect(img, cx - 5, 5, cx + 6, 8, h)
    if st in ("short", "beard"):
        rect(img, cx - 5, 8, cx - 4, 10, h); rect(img, cx + 6, 8, cx + 7, 10, h)
    if st in ("long", "ponytail"):
        rect(img, cx - 5, 8, cx - 4, 17, h); rect(img, cx + 6, 8, cx + 7, 17, h)
    if st == "ponytail":
        rect(img, cx + 6, 15, cx + 7, 20, h)
    if st == "beard":
        rect(img, cx - 4, 13, cx + 5, 15, h)
        px(img, cx, 14, rgb(196, 120, 96))
    if st == "hat":
        rect(img, cx - 6, 6, cx + 7, 7, rgb(128, 96, 52))   # brim
        rect(img, cx - 4, 3, cx + 5, 6, rgb(146, 110, 60))   # crown
        rect(img, cx - 4, 5, cx + 5, 5, rgb(96, 68, 36))     # band
    if direction == "up":  # back of head is all hair
        rect(img, cx - 5, 5, cx + 6, 13, h)
    # stronger top-light + subtle highlight pixel on hair
    img = shade_v(img, 1.14, 0.88, seed=7, speckle=0.0)
    # shirt highlight stripe
    px(img, cx - 2, 20, tuple(min(255, c + 28) for c in p["shirt"][:3]) + (255,))
    return outline(img)


def draw_portrait(p):
    img = canvas(32, 32)
    rect(img, 7, 26, 24, 31, p["shirt"])          # shoulders
    rect(img, 9, 7, 22, 26, p["skin"])            # head
    h = p["hair"]
    st = p["style"]
    rect(img, 8, 4, 23, 10, h)                    # hair cap
    if st in ("long", "ponytail"):
        rect(img, 7, 10, 9, 27, h); rect(img, 22, 10, 24, 27, h)
    if st == "beard":
        rect(img, 10, 21, 21, 26, h)
    if st == "hat":
        rect(img, 5, 8, 26, 10, rgb(128, 96, 52))
        rect(img, 9, 2, 22, 8, rgb(146, 110, 60))
    rect(img, 11, 15, 13, 17, rgb(40, 32, 28))    # eyes
    rect(img, 18, 15, 20, 17, rgb(40, 32, 28))
    rect(img, 13, 22, 18, 22, rgb(196, 120, 96))  # smile
    return outline(img)


def main():
    for name, palette in CHARACTERS.items():
        sheet = canvas(FRAME_W * 2, FRAME_H * 3)
        for row, direction in enumerate(("down", "up", "side")):
            for frame in (0, 1):
                sheet.paste(draw_frame(palette, direction, frame),
                            (frame * FRAME_W, row * FRAME_H))
        save(quantize_16bit(sheet), "characters", f"{name}.png")
        save(draw_portrait(palette), "characters", f"portrait_{name}.png")


if __name__ == "__main__":
    main()
