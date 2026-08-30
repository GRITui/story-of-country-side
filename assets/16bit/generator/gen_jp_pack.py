"""JRL Option B — Japanese countryside pack: crops / tools / UI.

Crops: Rice (tanbo), Daikon, Nasu (eggplant) drawn fresh; Edamame and
Sweet Potato stage art reused from gen_crops_jrl_b.py output. Each crop
gets 4 growth-stage PNGs + 64x16 strip + 16x16 harvest icon, all merged
into one unified sheet `crops/crops_jp_sheet.png` (80x80, 5 rows x 5 cols,
row order: rice, daikon, nasu, edamame, sweet_potato; cols: stage 0-3,
harvest icon).

Tools: `items/tools_jp_sheet.png` (80x16): kuwa (hoe), kama (sickle),
bamboo watering can, bug net, bamboo fishing rod.

UI: `ui/ui_jp_sheet.png` (160x16): washi slot, hotbar slot, hotbar slot
selected, bento full/half/empty, sakura, ginkgo, momiji, snowflake.
Plus `ui/washi_panel.png` (48x48, 9-patch friendly).

Sel-out #4A3320, pastel Ghibli, 16x16 cells, transparent backgrounds.
"""
import os
import random

from PIL import Image

from px import canvas, ellipse, px, rect, rgb, save, out
from jp_import import write_import, save_with_import

S = 16
SEL = rgb(0x4A, 0x33, 0x20)  # sel-out


def base_soil(img):
    for y in range(S):
        for x in range(S):
            px(img, x, y, rgb(107, 48, 32) if y > 11 else rgb(139, 74, 48))


def base_paddy(img):
    """Flooded tanbo: muddy water with reflective sheen."""
    for y in range(S):
        for x in range(S):
            c = rgb(122, 152, 176)
            if y > 11:
                c = rgb(90, 122, 144)
            elif (x * 7 + y * 3) % 11 == 0:
                c = rgb(154, 176, 192)  # sky glint
            px(img, x, y, c)
    rect(img, 0, 13, 15, 15, rgb(107, 90, 72))  # mud bed


# ---------------------------------------------------------------- crops
def rice_stage(img, stage):
    base_paddy(img)
    g_d, g_m, g_l = rgb(58, 107, 42), rgb(90, 154, 58), rgb(123, 196, 90)
    gold_m, gold_l = rgb(217, 180, 74), rgb(240, 216, 96)
    if stage == 0:
        for cx in (4, 8, 12):
            px(img, cx, 8, g_m); px(img, cx - 1, 9, g_m); px(img, cx + 1, 9, g_l)
            px(img, cx, 10, g_d)
    elif stage == 1:
        for cx in (4, 8, 12):
            for dx, h in ((-1, 2), (0, 3), (1, 2)):
                for i in range(h):
                    px(img, cx + dx, 10 - i, g_m if dx else g_l)
            px(img, cx, 11, g_d)
    elif stage == 2:
        for cx in (3, 6, 9, 12):
            for i in range(7):
                px(img, cx, 11 - i, g_m)
            px(img, cx - 1, 8, g_l); px(img, cx + 1, 9, g_d)
            px(img, cx, 4, g_l)
    else:
        for cx in (3, 6, 9, 12):
            for i in range(6):
                px(img, cx, 11 - i, gold_m)
            # drooping seed head
            px(img, cx, 5, gold_l); px(img, cx + 1, 5, gold_l); px(img, cx + 1, 6, gold_m)
        px(img, 4, 10, g_d)  # stray green blade


def daikon_stage(img, stage):
    base_soil(img)
    g_m, g_l, g_d = rgb(90, 154, 58), rgb(123, 196, 90), rgb(58, 107, 42)
    w, ws = rgb(240, 240, 232), rgb(208, 216, 200)
    if stage == 0:
        px(img, 7, 8, rgb(58, 32, 16)); px(img, 8, 8, rgb(58, 32, 16))
    elif stage == 1:
        px(img, 7, 6, g_l); px(img, 6, 7, g_m); px(img, 8, 7, g_m); px(img, 7, 8, g_d)
    elif stage == 2:
        rect(img, 5, 4, 10, 7, g_m)
        px(img, 6, 5, g_l); px(img, 9, 5, g_l); px(img, 5, 6, g_d); px(img, 10, 6, g_d)
        rect(img, 7, 8, 8, 10, w)  # shoulder peeking
    else:
        rect(img, 4, 3, 11, 7, g_m)
        px(img, 5, 4, g_l); px(img, 8, 3, g_l); px(img, 10, 4, g_l)
        px(img, 4, 5, g_d); px(img, 11, 5, g_d)
        rect(img, 6, 8, 9, 12, w)
        rect(img, 7, 13, 8, 14, w)
        px(img, 6, 10, ws); px(img, 9, 11, ws)


def nasu_stage(img, stage):
    base_soil(img)
    g_m, g_l, g_d = rgb(90, 154, 58), rgb(123, 196, 90), rgb(58, 107, 42)
    p, p_hi, cal = rgb(106, 58, 138), rgb(154, 106, 184), rgb(90, 154, 58)
    if stage == 0:
        px(img, 7, 8, rgb(58, 32, 16)); px(img, 8, 8, rgb(58, 32, 16))
    elif stage == 1:
        px(img, 7, 6, g_l); px(img, 6, 7, g_m); px(img, 9, 7, g_m); px(img, 7, 8, g_d)
        px(img, 8, 8, g_d)
    elif stage == 2:
        rect(img, 4, 4, 11, 10, g_m)
        px(img, 5, 5, g_l); px(img, 9, 6, g_l); px(img, 6, 8, g_d); px(img, 10, 9, g_d)
    else:
        rect(img, 3, 3, 12, 10, g_m)
        px(img, 4, 4, g_l); px(img, 8, 4, g_l); px(img, 11, 6, g_d)
        # two hanging fruit
        rect(img, 5, 8, 6, 11, p); px(img, 5, 8, p_hi); px(img, 6, 7, cal)
        rect(img, 9, 8, 10, 11, p); px(img, 9, 8, p_hi); px(img, 10, 7, cal)
        px(img, 7, 6, rgb(200, 160, 220))  # blossom


def _paste(dst, src, ox, oy):
    sp = src.load()
    for y in range(src.height):
        for x in range(src.width):
            r, g, b, a = sp[x, y]
            if a:
                dst.putpixel((ox + x, oy + y), (r, g, b, a))


def make_crop(name, fn, stage_imgs=None):
    """stage_imgs: reuse existing 16x16 stages instead of drawing."""
    if stage_imgs is None:
        stage_imgs = []
        for stage in range(4):
            img = canvas(S, S)
            fn(img, stage)
            stage_imgs.append(img)
            save_with_import(img, "crops", f"{name}_{stage}.png")
    strip = canvas(64, 16)
    for i, img in enumerate(stage_imgs):
        _paste(strip, img, i * 16, 0)
    save_with_import(strip, "crops", f"{name}.png")
    return stage_imgs


# ------------------------------------------------------- harvest icons
def icon_rice(img):
    stalk, head, tie = rgb(217, 180, 74), rgb(240, 216, 96), rgb(176, 80, 60)
    for i in range(9):  # upright stalks
        px(img, 7, 13 - i, stalk); px(img, 9, 13 - i, stalk)
        if i < 8:
            px(img, 5, 13 - i, stalk); px(img, 11, 13 - i, stalk)
    for x, y in ((5, 4), (7, 3), (9, 3), (11, 4), (6, 5), (10, 5), (8, 4)):
        px(img, x, y, head)
    rect(img, 6, 10, 10, 11, tie)  # binding band
    px(img, 6, 10, rgb(217, 122, 90))


def icon_daikon(img):
    w, ws, g_m, g_l = rgb(240, 240, 232), rgb(208, 216, 200), rgb(90, 154, 58), rgb(123, 196, 90)
    rect(img, 6, 6, 9, 12, w)
    rect(img, 7, 13, 8, 13, w)
    px(img, 7, 14, ws)
    px(img, 6, 8, ws); px(img, 9, 11, ws)
    px(img, 7, 5, g_m); px(img, 8, 4, g_l); px(img, 6, 4, g_m); px(img, 9, 3, g_l)
    px(img, 8, 3, g_m)


def icon_nasu(img):
    p, p_hi, cal, stem = rgb(106, 58, 138), rgb(154, 106, 184), rgb(90, 154, 58), rgb(58, 107, 42)
    ellipse(img, 8, 10, 4, 5, p)
    rect(img, 6, 5, 10, 7, cal)
    px(img, 8, 4, stem); px(img, 9, 3, stem)
    px(img, 6, 8, p_hi); px(img, 6, 9, p_hi); px(img, 7, 7, p_hi)


def icon_edamame(img):
    pod, pod_hi, stem = rgb(107, 170, 74), rgb(168, 224, 144), rgb(74, 122, 48)
    px(img, 8, 3, stem); px(img, 8, 4, stem)
    rect(img, 5, 5, 6, 9, pod); px(img, 5, 6, pod_hi); px(img, 6, 7, pod_hi)
    rect(img, 8, 6, 9, 10, pod); px(img, 8, 7, pod_hi); px(img, 9, 8, pod_hi)
    rect(img, 11, 5, 12, 9, pod); px(img, 11, 6, pod_hi)
    px(img, 7, 5, stem); px(img, 10, 5, stem); px(img, 6, 4, stem); px(img, 11, 4, stem)


def icon_sweet_potato(img):
    skin, skin_d, cut = rgb(160, 74, 90), rgb(122, 51, 64), rgb(240, 220, 160)
    ellipse(img, 8, 9, 5, 3, skin)
    px(img, 3, 9, skin_d); px(img, 4, 10, skin_d)
    px(img, 13, 9, cut); px(img, 12, 8, cut)  # cut tip shows flesh
    px(img, 6, 7, rgb(200, 120, 130)); px(img, 9, 8, rgb(200, 120, 130))  # highlights


# ---------------------------------------------------------------- tools
def tool_kuwa(img):
    """Japanese hoe: bamboo handle, perpendicular steel blade."""
    han, han_d, steel, edge = rgb(201, 184, 150), rgb(168, 152, 104), rgb(138, 138, 154), rgb(232, 232, 240)
    for i in range(11):  # diagonal handle
        px(img, 3 + i, 13 - i, han)
        px(img, 4 + i, 13 - i, han_d) if i % 3 == 0 else None
    px(img, 6, 10, han_d); px(img, 9, 7, han_d)  # node bands
    # blade at top, perpendicular
    rect(img, 11, 2, 15, 5, steel)
    rect(img, 11, 2, 15, 2, edge)


def tool_kama(img):
    """Sickle: short wood grip, crescent blade (ring-sector)."""
    import math
    han, han_d, steel, edge = rgb(139, 107, 74), rgb(107, 74, 42), rgb(184, 184, 200), rgb(248, 248, 240)
    rect(img, 3, 9, 4, 14, han)
    px(img, 3, 11, han_d); px(img, 4, 13, han_d)
    cx, cy = 9, 10
    for y in range(16):
        for x in range(16):
            dx, dy = x - cx, y - cy
            r = math.hypot(dx, dy)
            ang = math.degrees(math.atan2(dy, dx))
            if 4.0 <= r <= 6.2 and -175 <= ang <= -25:
                px(img, x, y, edge if r < 4.9 else steel)
    px(img, 4, 8, steel); px(img, 5, 8, steel)  # blade socket into grip


def tool_watering_can(img):
    """Bamboo watering can (joro): canister, spout, rope handle, drops."""
    body, node, rope, drop = rgb(201, 184, 150), rgb(168, 152, 104), rgb(139, 107, 74), rgb(122, 184, 224)
    rect(img, 3, 7, 9, 13, body)
    rect(img, 3, 7, 9, 7, rgb(220, 205, 170))
    px(img, 5, 8, node); px(img, 5, 13, node); px(img, 7, 10, node)  # bamboo nodes
    for i in range(4):
        px(img, 10 + i, 8 - i, body)  # spout up-right
    px(img, 13, 4, node)
    px(img, 13, 5, drop); px(img, 14, 6, drop)
    for x, y in ((4, 5), (5, 4), (7, 4), (8, 5)):  # rope arc
        px(img, x, y, rope)
    px(img, 4, 6, rope); px(img, 8, 6, rope)


def tool_bug_net(img):
    """Bamboo handle + hoop + gauze net."""
    han, hoop, gauze = rgb(201, 184, 150), rgb(168, 152, 104), (248, 248, 240, 150)
    for i in range(9):
        px(img, 2 + i, 14 - i, han)
    ellipse(img, 11, 5, 4, 4, hoop)
    ellipse(img, 11, 5, 3, 3, gauze)
    px(img, 11, 3, (248, 248, 240, 200)); px(img, 11, 7, (248, 248, 240, 200))
    px(img, 9, 5, (248, 248, 240, 200)); px(img, 13, 5, (248, 248, 240, 200))
    px(img, 8, 8, hoop)


def tool_fishing_rod(img):
    """Bamboo rod, line, red-white float, hook."""
    rod, rod_tip, line, red, white = rgb(201, 184, 150), rgb(168, 152, 104), rgb(220, 220, 230), rgb(217, 74, 74), rgb(248, 248, 240)
    for i in range(11):
        px(img, 2 + i, 14 - i, rod if i < 7 else rod_tip)
    for i, y in enumerate(range(3, 9)):  # line drops from tip
        px(img, 13, y, line)
    px(img, 13, 9, red); px(img, 13, 10, white)  # float
    px(img, 13, 12, rgb(90, 90, 110)); px(img, 14, 13, rgb(90, 90, 110))  # hook


# ------------------------------------------------------------------- ui
def ui_washi_slot(img):
    paper, edge, fiber, corner = rgb(244, 238, 223), rgb(184, 168, 136), rgb(228, 218, 196), rgb(139, 111, 71)
    rect(img, 0, 0, 15, 15, paper)
    for i in range(16):
        px(img, i, 0, edge); px(img, i, 15, edge); px(img, 0, i, edge); px(img, 15, i, edge)
    for cx, cy in ((1, 1), (14, 1), (1, 14), (14, 14)):
        px(img, cx, cy, corner)
    rng = random.Random(7)
    for _ in range(14):
        px(img, rng.randint(2, 13), rng.randint(2, 13), fiber)


def _bamboo_slot(img, selected):
    wood, dark, hi = rgb(201, 184, 150), rgb(139, 111, 71), rgb(220, 205, 170)
    rect(img, 0, 0, 15, 15, wood)
    for i in range(16):
        px(img, i, 0, dark); px(img, i, 15, dark); px(img, 0, i, dark); px(img, 15, i, dark)
    px(img, 4, 1, dark); px(img, 4, 14, dark)  # node stripe
    for y in range(2, 14):
        px(img, 4, y, rgb(168, 152, 104))
    px(img, 2, 2, hi); px(img, 6, 2, hi)
    if selected:
        glow = rgb(240, 216, 96)
        for i in range(16):
            px(img, i, 0, glow); px(img, i, 15, glow); px(img, 0, i, glow); px(img, 15, i, glow)


def ui_hotbar_slot(img):
    _bamboo_slot(img, False)


def ui_hotbar_slot_sel(img):
    _bamboo_slot(img, True)


def _bento(img, fill):
    """fill: 'full' | 'half' | 'empty' — 16x16 stamina bento."""
    lacq, rim, rice, nori, ume, side = rgb(58, 42, 42), rgb(176, 48, 48), rgb(248, 248, 240), rgb(42, 58, 42), rgb(217, 74, 74), rgb(123, 196, 90)
    rect(img, 1, 3, 14, 14, lacq)
    rect(img, 1, 3, 14, 4, rim)
    for i in range(1, 15):
        px(img, i, 3, rim)
    px(img, 1, 3, rim); px(img, 14, 3, rim)
    px(img, 7, 5, rim)  # divider top
    for y in range(5, 14):
        px(img, 7, y, rgb(90, 60, 60))  # divider
    if fill in ("full", "half"):
        ellipse(img, 4, 9, 2, 3, rice)
        px(img, 4, 8, nori); px(img, 4, 9, ume) if fill == "full" else px(img, 3, 8, nori)
    else:
        rect(img, 3, 7, 5, 11, rgb(74, 58, 42))  # empty compartment wood
    if fill == "full":
        ellipse(img, 11, 9, 2, 3, rice)
        px(img, 11, 8, ume)
        px(img, 10, 11, side); px(img, 12, 11, side)
    elif fill == "half":
        rect(img, 9, 7, 13, 11, rgb(74, 58, 42))
    else:
        rect(img, 9, 7, 13, 11, rgb(74, 58, 42))
    if fill == "empty":
        px(img, 3, 6, rgb(139, 107, 74)); px(img, 11, 6, rgb(139, 107, 74))


def ui_season_sakura(img):
    pet, pet_d, ctr = rgb(248, 200, 216), rgb(240, 160, 184), rgb(232, 120, 152)
    ellipse(img, 8, 4, 2, 2, pet); ellipse(img, 4, 7, 2, 2, pet)
    ellipse(img, 12, 7, 2, 2, pet); ellipse(img, 6, 11, 2, 2, pet); ellipse(img, 10, 11, 2, 2, pet)
    px(img, 8, 8, ctr); px(img, 7, 7, pet_d); px(img, 9, 9, pet_d)
    px(img, 8, 13, rgb(139, 107, 74))  # stem


def ui_season_ginkgo(img):
    leaf, leaf_d, stem = rgb(240, 216, 96), rgb(217, 180, 74), rgb(184, 148, 58)
    for y in range(3, 10):
        spread = (y - 2)
        rect(img, 8 - spread, y, 7 + spread, y, leaf)
    px(img, 8, 3, leaf); px(img, 8, 4, leaf_d)  # notch hint
    for x in range(3, 13):
        px(img, x, 9, leaf_d) if abs(x - 8) > 2 else None
    px(img, 8, 10, stem); px(img, 8, 11, stem); px(img, 8, 12, stem)


def ui_season_momiji(img):
    leaf, leaf_d, stem = rgb(217, 90, 58), rgb(176, 56, 40), rgb(139, 74, 48)
    lobes = [(8, 3), (5, 5), (11, 5), (4, 9), (12, 9), (6, 11), (10, 11)]
    for x, y in lobes:
        px(img, x, y, leaf)
        px(img, x, y - 1, leaf) if y > 3 else None
    rect(img, 6, 6, 10, 10, leaf)
    px(img, 5, 7, leaf_d); px(img, 11, 8, leaf_d); px(img, 8, 10, leaf_d)
    px(img, 8, 12, stem); px(img, 8, 13, stem)


def ui_season_snow(img):
    flake, shade = rgb(232, 240, 248), rgb(192, 208, 232)
    px(img, 8, 4, flake); px(img, 8, 12, shade)
    px(img, 4, 8, flake); px(img, 12, 8, flake)
    for dx, dy in ((2, 2), (-2, 2), (2, -2), (-2, -2)):
        px(img, 8 + dx, 8 + dy, flake)
    ellipse(img, 8, 8, 2, 2, flake)
    px(img, 8, 8, rgb(248, 248, 255))


# ---------------------------------------------------------------- main
def main():
    # --- crops: new three drawn here; edamame/sweet_potato reused
    sheets = {}
    sheets["rice"] = make_crop("rice", rice_stage)
    sheets["daikon"] = make_crop("daikon", daikon_stage)
    sheets["nasu"] = make_crop("nasu", nasu_stage)
    for reuse in ("edamame", "sweet_potato"):
        imgs = []
        for stage in range(4):
            p = out("crops", f"{reuse}_{stage}.png")
            imgs.append(Image.open(p).convert("RGBA"))
        sheets[reuse] = imgs

    # harvest icons
    icons = {
        "rice": icon_rice,
        "daikon": icon_daikon,
        "nasu": icon_nasu,
        "edamame": icon_edamame,
        "sweet_potato": icon_sweet_potato,
    }
    icon_imgs = {}
    for name, fn in icons.items():
        img = canvas(S, S)
        fn(img)
        icon_imgs[name] = img
        save_with_import(img, "items", f"icon_{name}.png")

    # unified crops sheet 80x80
    sheet = canvas(80, 80)
    for row, name in enumerate(("rice", "daikon", "nasu", "edamame", "sweet_potato")):
        for col in range(4):
            _paste(sheet, sheets[name][col], col * 16, row * 16)
        _paste(sheet, icon_imgs[name], 4 * 16, row * 16)
    save_with_import(sheet, "crops", "crops_jp_sheet.png")

    # --- tools sheet 80x16
    tools = [
        ("icon_kuwa", tool_kuwa),
        ("icon_kama", tool_kama),
        ("icon_bamboo_watering_can", tool_watering_can),
        ("icon_bug_net", tool_bug_net),
        ("icon_bamboo_fishing_rod", tool_fishing_rod),
    ]
    tsheet = canvas(80, 16)
    for col, (name, fn) in enumerate(tools):
        img = canvas(S, S)
        fn(img)
        save_with_import(img, "items", f"{name}.png")
        _paste(tsheet, img, col * 16, 0)
    save_with_import(tsheet, "items", "tools_jp_sheet.png")

    # --- UI sheet 160x16 + washi panel
    ui = [
        ("ui_washi_slot", ui_washi_slot),
        ("ui_hotbar_slot", ui_hotbar_slot),
        ("ui_hotbar_slot_sel", ui_hotbar_slot_sel),
        ("ui_bento_full", lambda i: _bento(i, "full")),
        ("ui_bento_half", lambda i: _bento(i, "half")),
        ("ui_bento_empty", lambda i: _bento(i, "empty")),
        ("ui_season_sakura", ui_season_sakura),
        ("ui_season_ginkgo", ui_season_ginkgo),
        ("ui_season_momiji", ui_season_momiji),
        ("ui_season_snow", ui_season_snow),
    ]
    usheet = canvas(160, 16)
    for col, (name, fn) in enumerate(ui):
        img = canvas(S, S)
        fn(img)
        save_with_import(img, "ui", f"{name}.png")
        _paste(usheet, img, col * 16, 0)
    save_with_import(usheet, "ui", "ui_jp_sheet.png")

    # washi panel 48x48 (9-patch: 16px thirds)
    panel = canvas(48, 48)
    paper, edge, fiber, corner = rgb(244, 238, 223), rgb(184, 168, 136), rgb(228, 218, 196), rgb(139, 111, 71)
    rect(panel, 0, 0, 47, 47, paper)
    for i in range(48):
        px(panel, i, 0, edge); px(panel, i, 47, edge); px(panel, 0, i, edge); px(panel, 47, i, edge)
    for cx, cy in ((1, 1), (46, 1), (1, 46), (46, 46)):
        px(panel, cx, cy, corner)
    rng = random.Random(21)
    for _ in range(90):
        px(panel, rng.randint(2, 45), rng.randint(2, 45), fiber)
    save_with_import(panel, "ui", "washi_panel.png")


if __name__ == "__main__":
    main()
