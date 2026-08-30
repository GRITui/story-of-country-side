"""Item icons: 16x16 UI icons for every registered item_id plus tools/misc.

Matches registered content at seed time (crops, ores, fish, forageables,
animal products) plus tools and raw materials used by the tool/upgrade and
infrastructure systems.
"""
from px import quantize_16bit, canvas, ellipse, outline, px, rect, rgb, save
from math import pi, cos, sin


def _berry_icon():
    img = canvas(16, 16)
    rect(img, 3, 10, 8, 12, (76, 138, 50)); rect(img, 4, 8, 7, 10, (76, 138, 50))
    px(img, 7, 6, (196, 60, 60)); px(img, 5, 9, (206, 66, 66)); px(img, 3, 6, (196, 60, 60))
    px(img, 6, 7, (196, 60, 60))
    return outline(img)


def _flower_icon():
    img = canvas(16, 16)
    rect(img, 7, 9, 8, 14, (70, 140, 60))
    for i in range(5):
        a = i / 5 * 2 * pi
        c = (226, 178, 84) if i % 2 else (240, 224, 200)
        px(img, 8 + int(2.2 * cos(a)), 7 + int(2.2 * sin(a)), c)
    px(img, 8, 7, (230, 204, 84))
    return outline(img)


def _veg_icon(c, shape="root"):
    img = canvas(16, 16)
    rect(img, 6, 3, 9, 6, c)
    if shape == "root":
        rect(img, 6, 6, 9, 13, (226, 220, 200)); rect(img, 7, 13, 8, 15, (226, 220, 200))
    else:
        rect(img, 5, 6, 10, 10, (226, 220, 200))
    return outline(img)


def _mushroom_icon():
    img = canvas(16, 16)
    rect(img, 5, 8, 10, 9, (214, 178, 148))
    ellipse(img, 8, 6, 5, 3, (214, 92, 88))
    px(img, 6, 5, (240, 236, 226)); px(img, 10, 6, (240, 236, 226))
    return outline(img)


def _nut_icon():
    img = canvas(16, 16)
    ellipse(img, 8, 9, 4, 5, (206, 158, 94))
    rect(img, 7, 3, 8, 5, (120, 96, 52))
    return outline(img)


def _truffle_icon():
    img = canvas(16, 16)
    ellipse(img, 8, 9, 5, 4, (58, 50, 46))
    px(img, 6, 7, (36, 32, 30)); px(img, 10, 10, (36, 32, 30))
    return outline(img)


def _root_icon():
    img = canvas(16, 16)
    rect(img, 5, 6, 7, 14, (196, 176, 130))
    rect(img, 7, 3, 8, 6, (80, 150, 70))
    rect(img, 4, 12, 5, 13, (220, 208, 176)); rect(img, 8, 12, 9, 13, (220, 208, 176))
    return outline(img)


def _clover_icon():
    img = canvas(16, 16)
    for i in range(3):
        a = i / 3 * 2 * pi
        for k in range(3):
            a2 = a + k * 0.35
            px(img, 8 + int(2.6 * cos(a2)), 6 + int(2.6 * sin(a2)), (56, 150, 64))
    px(img, 8, 6, (66, 176, 72))
    rect(img, 7, 10, 8, 15, (56, 140, 60))
    return outline(img)


def _ore_icon(c, spark=(238, 238, 240)):
    img = canvas(16, 16)
    rect(img, 4, 6, 11, 13, (100, 94, 90))
    px(img, 6, 9, c); px(img, 9, 8, c); px(img, 7, 11, c)
    px(img, 5, 7, spark)
    return outline(img)


def _diamond_icon():
    img = canvas(16, 16)
    px(img, 8, 3, (200, 226, 244)); rect(img, 6, 4, 10, 5, (170, 210, 236))
    rect(img, 5, 6, 11, 10, (148, 196, 230)); rect(img, 6, 11, 10, 13, (170, 210, 236))
    px(img, 8, 12, (200, 226, 244))
    return outline(img, color=(60, 90, 120))


def _fish_icon(c, spots=()):
    img = canvas(16, 16)
    px(img, 5, 9, c); px(img, 6, 8, c); rect(img, 4, 9, 6, 11, c)
    rect(img, 7, 7, 11, 12, c)
    px(img, 12, 7, c); px(img, 12, 9, c); px(img, 13, 8, c)
    px(img, 5, 10, (30, 34, 40))
    for (sx, sy) in spots:
        px(img, sx, sy, (240, 240, 244))
    return outline(img)


def _egg_icon(color=(246, 238, 218), spot=(200, 160, 120)):
    img = canvas(16, 16)
    ellipse(img, 8, 10, 3, 5, color)
    px(img, 7, 7, spot)
    return outline(img)


def _milk_icon():
    img = canvas(16, 16)
    px(img, 6, 5, (120, 120, 128)); rect(img, 4, 6, 9, 13, (226, 230, 238))
    rect(img, 4, 6, 9, 8, (210, 218, 230))
    return outline(img)


def _wool_icon():
    img = canvas(16, 16)
    for (x, y) in ((5, 7), (9, 5), (6, 11), (10, 11), (8, 8), (12, 7)):
        px(img, x, y, (222, 224, 232)); px(img, x + 1, y, (222, 224, 232))
        px(img, x, y + 1, (222, 224, 232))
    return outline(img)


def _tool_icon(pick_name):
    img = canvas(16, 16)
    if pick_name == "hoe":
        rect(img, 3, 3, 12, 4, (140, 92, 52)); rect(img, 5, 4, 5, 12, (150, 110, 70))
    elif pick_name == "watering_can":
        rect(img, 5, 4, 11, 9, (120, 170, 190)); rect(img, 3, 9, 11, 10, (120, 170, 190))
        px(img, 10, 6, (200, 226, 240)); px(img, 12, 4, (200, 226, 240))
    elif pick_name == "axe":
        rect(img, 6, 4, 6, 12, (150, 110, 70)); px(img, 5, 5, (180, 184, 188))
        px(img, 4, 4, (180, 184, 188)); rect(img, 5, 3, 7, 5, (180, 184, 188))
    else:  # pickaxe
        rect(img, 5, 3, 5, 12, (150, 110, 70))
        px(img, 4, 4, (196, 200, 206)); px(img, 6, 4, (196, 200, 206)); px(img, 3, 5, (196, 200, 206))
    return outline(img)


def _stone_icon():
    img = canvas(16, 16)
    rect(img, 5, 6, 11, 12, (150, 150, 156))
    px(img, 7, 8, (176, 176, 182)); px(img, 8, 11, (128, 128, 134))
    return outline(img)


def _coal_icon():
    img = canvas(16, 16)
    rect(img, 5, 6, 11, 12, (48, 48, 54))
    px(img, 7, 8, (80, 80, 88))
    return outline(img)


def _wood_icon():
    img = canvas(16, 16)
    rect(img, 6, 3, 9, 12, (150, 108, 62))
    ellipse(img, 7, 3, 2, 2, (166, 124, 74)); ellipse(img, 8, 11, 2, 2, (166, 124, 74))
    return outline(img)


def _gold_icon():
    img = canvas(16, 16)
    rect(img, 5, 9, 11, 11, (214, 170, 60)); rect(img, 6, 11, 10, 12, (196, 154, 52))
    px(img, 5, 9, (226, 182, 62))
    return outline(img, color=(150, 112, 30))


GENERATORS = {
    "parsnip": lambda: _veg_icon((240, 226, 178), "root"),
    "cauliflower": lambda: _veg_icon((222, 228, 200), "bush"),
    "tomato": lambda: _berry_icon(),
    "melon": lambda: _veg_icon((150, 196, 92), "bush"),
    "pumpkin": lambda: _veg_icon((214, 150, 66), "bush"),
    "corn": lambda: _veg_icon((208, 186, 92), "bush"),
    "frost_kale": lambda: _veg_icon((150, 190, 190), "bush"),
    "copper_ore": lambda: _ore_icon((206, 140, 84)),
    "iron_ore": lambda: _ore_icon((150, 110, 70)),
    "gold_ore": lambda: _ore_icon((226, 182, 62)),
    "diamond": _diamond_icon,
    "carp": lambda: _fish_icon((150, 160, 120)),
    "trout": lambda: _fish_icon((120, 150, 200)),
    "salmon": lambda: _fish_icon((226, 130, 110)),
    "tuna": lambda: _fish_icon((90, 110, 150)),
    "bream": lambda: _fish_icon((176, 150, 96)),
    "bass": lambda: _fish_icon((96, 150, 92)),
    "sardine": lambda: _fish_icon((176, 178, 190), [(9, 9)]),
    "wild_berries": _berry_icon,
    "wild_flower": _flower_icon,
    "spring_onion": lambda: _veg_icon((120, 170, 90), "root"),
    "sweet_pea": _flower_icon,
    "mushroom": _mushroom_icon,
    "hazelnut": _nut_icon,
    "snow_truffle": _truffle_icon,
    "winter_root": _root_icon,
    "four_leaf_clover": _clover_icon,
    "egg": lambda: _egg_icon(),
    "duck_egg": lambda: _egg_icon((210, 214, 226), (140, 190, 160)),
    "milk": _milk_icon,
    "goat_milk": lambda: _milk_icon(),
    "wool": _wool_icon,
    "hoe": lambda: _tool_icon("hoe"),
    "watering_can": lambda: _tool_icon("watering_can"),
    "axe": lambda: _tool_icon("axe"),
    "pickaxe": lambda: _tool_icon("pickaxe"),
    "stone": _stone_icon,
    "coal": _coal_icon,
    "wood": _wood_icon,
    "gold": _gold_icon,
}


def main():
    for name, gen in sorted(GENERATORS.items()):
        save(gen(), "items", f"icon_{name}.png")


if __name__ == "__main__":
    main()
