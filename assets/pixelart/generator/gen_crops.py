"""Game crops: 7 crops x 4 growth stages, bottom-center anchored.

The exact registered crop ids at seed time:
  parsnip, cauliflower, tomato, melon, pumpkin, corn, frost_kale
Each output is a single horizontal strip of 4 stage frames (48x48 each);
a per-plot sprite group positions a stage-frame's feet on the tile's
bottom-center per design/art/isometric-grid-spec.md section 4.
"""
from PIL import Image

from px import canvas, ellipse, outline, px, rect, rgb, save

S = 48


def leaf(img, x, y, c, dirn=1):
    px(img, x, y, c); px(img, x + dirn, y - 1, c); px(img, x + dirn, y, c)


def stalk(img, x, top, bot, c):
    rect(img, x - 1, top, x + 1, bot, c)


CROPS = {
    "parsnip": ((240, 230, 186), (200, 176, 120), (196, 156, 96)),
    "cauliflower": ((232, 226, 200), (208, 224, 168), (192, 170, 120)),
    "tomato": ((96, 166, 64), (206, 74, 58), (76, 138, 50)),
    "melon": ((116, 178, 72), (150, 196, 92), (212, 150, 74)),
    "pumpkin": ((186, 122, 44), (214, 150, 66), (96, 156, 60)),
    "corn": ((138, 176, 70), (208, 186, 92), (140, 106, 50)),
    "frost_kale": ((96, 140, 150), (150, 190, 190), (66, 120, 132)),
}


def stage_sprite(rgb_leaf, rgb_fruit, rgb_stem, stage, kind):
    img = canvas(S, S)
    cx, base = S // 2, S - 1
    if stage == 0:
        stalk(img, cx, base - 4, base, rgb_stem)
        leaf(img, cx - 2, base - 5, rgb_leaf, -1)
        leaf(img, cx + 2, base - 5, rgb_leaf, 1)
    elif stage == 1:
        stalk(img, cx, base - 8, base, rgb_stem)
        for dx in (-4, -2, 0, 2, 4):
            leaf(img, cx + dx, base - 7 - (3 - abs(dx) // 2), rgb_leaf,
                 1 if dx >= 0 else -1)
    elif stage == 2:
        stalk(img, cx, base - 11, base, rgb_stem)
        for dx in (-6, -3, 0, 3, 6):
            leaf(img, cx + dx, base - 9 - (3 - abs(dx) // 2), rgb_leaf,
                 1 if dx >= 0 else -1)
        leaf(img, cx, base - 13, rgb_leaf, 1)
    else:
        if kind == "climber":
            stalk(img, cx, base - 18, base, rgb_stem)
            for dy in (4, 9):
                rect(img, cx - 3, base - dy - 3, cx - 1, base - dy, rgb_leaf)
                rect(img, cx - 4, base - dy - 2, cx - 2, base - dy - 1,
                     (224, 196, 96))
            for dx in (-3, -1, 1, 3):
                leaf(img, cx + dx, base - 9 - (2 - abs(dx) // 2), rgb_leaf,
                     1 if dx >= 0 else -1)
        else:
            for dx in (-6, -3, 3, 6):
                leaf(img, cx + dx, base - 9 - (3 - abs(dx) // 2), rgb_leaf,
                     1 if dx >= 0 else -1)
            rect(img, cx - 5, base - 6, cx - 3, base - 4, rgb_fruit)
            rect(img, cx - 1, base - 5, cx + 1, base - 4, rgb_fruit)
            rect(img, cx + 2, base - 7, cx + 4, base - 5, rgb_fruit)
    ellipse(img, cx, base - 2, 7, 2, (0, 0, 0, 66))
    return outline(img)


def main():
    kinds = {
        "parsnip": "bushy", "cauliflower": "bushy", "tomato": "bushy",
        "melon": "bushy", "pumpkin": "bushy", "corn": "climber",
        "frost_kale": "bushy",
    }
    for crop, (leafc, fruitc, stemc) in CROPS.items():
        sheet = canvas(S * 4, S)
        for stage in range(4):
            sheet.paste(stage_sprite(leafc, fruitc, stemc, stage, kinds[crop]),
                        (stage * S, 0))
        save(sheet, "crops", f"{crop}.png")


if __name__ == "__main__":
    main()
