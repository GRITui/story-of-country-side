"""UI icons for the HUD / overlays (16x16): heart(s), coin, stamina bolt,
clock/time, food bowl (ranch), gift box (relationships), bundle box
(community goal), festival flag, temp/weather, fishing, notes/journal.
"""
from px import canvas, ellipse, px, rect, rgb, save, outline


def _heart(full=True):
    img = canvas(16, 16)
    c = (226, 66, 66) if full else (150, 150, 156)
    px(img, 5, 5, c); px(img, 6, 4, c); px(img, 7, 4, c); px(img, 8, 4, c)
    px(img, 9, 4, c); px(img, 10, 5, c); px(img, 5, 6, c); px(img, 10, 6, c)
    px(img, 4, 6, c); px(img, 5, 7, c); px(img, 6, 8, c); px(img, 7, 9, c)
    px(img, 8, 9, c); px(img, 9, 8, c); px(img, 10, 7, c); px(img, 11, 6, c)
    px(img, 7, 10, c)
    if full:
        px(img, 7, 5, (250, 200, 200))
    return outline(img)


def _heart_empty():
    img = canvas(16, 16)
    c = (168, 168, 174)
    for (x, y) in ((5,5),(6,4),(7,4),(8,4),(9,4),(10,5),(5,6),(10,6),(4,6),(5,7),(6,8),(7,9),(8,9),(9,8),(10,7),(11,6)):
        px(img, x, y, c)
    return outline(img)


def _coin():
    img = canvas(16, 16)
    ellipse(img, 8, 8, 5, 5, (230, 184, 66))
    ellipse(img, 8, 8, 4, 4, (250, 210, 120))
    px(img, 8, 7, (240, 224, 160))
    return outline(img, color=(160, 116, 34))


def _bolt():
    img = canvas(16, 16)
    c = (230, 200, 60)
    px(img, 8, 3, c); px(img, 7, 4, c); px(img, 6, 5, c)
    rect(img, 5, 6, 9, 8, c); rect(img, 7, 8, 11, 10, c)
    rect(img, 9, 10, 12, 12, c); px(img, 8, 12, c)
    return outline(img)


def _clock():
    img = canvas(16, 16)
    ellipse(img, 8, 8, 6, 6, (240, 222, 200))
    rect(img, 7, 3, 9, 5, (220, 200, 180))
    rect(img, 7, 2, 9, 3, (150, 110, 70))
    rect(img, 8, 8, 8, 5, (70, 60, 50))
    rect(img, 8, 7, 11, 8, (70, 60, 50))
    return outline(img)


def _food_bowl():
    img = canvas(16, 16)
    ellipse(img, 8, 10, 6, 3, (150, 110, 70))
    ellipse(img, 8, 9, 6, 2, (210, 180, 110))
    px(img, 6, 7, (206, 162, 62)); px(img, 8, 8, (206, 162, 62)); px(img, 10, 7, (206, 162, 62))
    return outline(img)


def _gift():
    img = canvas(16, 16)
    rect(img, 3, 6, 13, 13, (206, 90, 80))
    rect(img, 2, 3, 14, 6, (230, 150, 90))
    rect(img, 7, 3, 9, 13, (226, 126, 96))
    px(img, 3, 2, (150, 200, 150)); rect(img, 2, 1, 5, 2, (120, 190, 130))
    px(img, 11, 2, (150, 200, 150)); rect(img, 11, 1, 14, 2, (120, 190, 130))
    return outline(img)


def _bundle():
    img = canvas(16, 16)
    px(img, 8, 3, (120, 180, 90))
    rect(img, 6, 4, 10, 5, (150, 210, 110))
    rect(img, 5, 5, 11, 10, (96, 160, 70))
    rect(img, 5, 10, 11, 11, (80, 140, 60))
    px(img, 5, 3, (120, 180, 90)); px(img, 11, 3, (120, 180, 90))
    return outline(img)


def _flag():
    img = canvas(16, 16)
    rect(img, 4, 2, 4, 14, (110, 100, 90))
    rect(img, 5, 2, 11, 7, (226, 90, 80))
    px(img, 5, 5, (250, 200, 160))
    rect(img, 3, 11, 13, 12, (140, 92, 56))
    return outline(img)


def _sun():
    img = canvas(16, 16)
    c = (250, 210, 90)
    px(img, 8, 8, c); px(img, 6, 6, c); px(img, 7, 6, c); px(img, 8, 6, c); px(img, 9, 6, c); px(img, 10, 6, c)
    px(img, 6, 7, c); px(img, 9, 7, c); px(img, 5, 8, c); px(img, 9, 8, c); px(img, 6, 9, c); px(img, 8, 9, c); px(img, 8, 10, c)
    px(img, 4, 4, c); px(img, 12, 4, c); px(img, 4, 12, c); px(img, 12, 12, c)
    return outline(img, color=(200, 150, 40))


def _rain():
    img = canvas(16, 16)
    c = (110, 150, 210)
    px(img, 5, 3, (180, 200, 230)); px(img, 7, 4, (180, 200, 230)); px(img, 9, 3, (180, 200, 230))
    rect(img, 4, 4, 11, 9, c)
    px(img, 3, 8, c); px(img, 12, 9, c); px(img, 4, 9, c)
    return outline(img)


def _fishing():
    img = canvas(16, 16)
    px(img, 4, 2, (180, 184, 190)); rect(img, 4, 2, 5, 3, (180, 184, 190))
    P = [(6,4),(7,6),(9,9),(11,12)]
    for i in range(len(P)-1):
        x1,y1 = P[i]; x2,y2=P[i+1]
        px(img, x1, y1, (180, 184, 190)); px(img, x2, y2, (180, 184, 190))
    ellipse(img, 12, 12, 2, 2, (120, 140, 200))
    return outline(img)


def _journal():
    img = canvas(16, 16)
    rect(img, 4, 2, 12, 14, (240, 240, 244))
    rect(img, 3, 2, 4, 14, (180, 60, 50))
    px(img, 6, 5, (150, 180, 210)); rect(img, 6, 4, 10, 5, (150, 180, 210))
    px(img, 6, 8, (150, 180, 210)); rect(img, 6, 7, 9, 8, (150, 180, 210))
    return outline(img)


# (the _gift/_sun definitions above are the real ones; nothing below breaks them)

UI = {
    "heart": _heart,
    "heart_empty": _heart_empty,
    "coin": _coin,
    "bolt": _bolt,
    "clock": _clock,
    "bowl": _food_bowl,
    "gift": _gift,
    "bundle": _bundle,
    "flag": _flag,
    "sun": _sun,
    "rain": _rain,
    "fishing": _fishing,
    "journal": _journal,
}


def main():
    for name, gen in UI.items():
        save(gen(), "ui", f"icon_{name}.png")


if __name__ == "__main__":
    main()
