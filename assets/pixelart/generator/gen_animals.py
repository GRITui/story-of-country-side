"""Animals: chicken, duck, cow, goat, sheep.

Each output is a 96x32 strip = 3 bob frames, facing right (flip at runtime
for left). Anchored bottom-center. Matches species ids in
scripts/autoload/animal_manager.gd.
"""
from px import canvas, ellipse, outline, px, rect, rgb, save

S = 32
GROUND = 29


def frame(func, bob):
    img = canvas(S, S)
    ellipse(img, S // 2, GROUND + 2, 8, 2, (0, 0, 0, 66))
    func(img, bob)
    return outline(img)


def _chicken(img, bob):
    c = rgb(242, 240, 228)
    yoff = bob
    # body with subtle shadow underlayer
    rect(img, 10, GROUND - 5 + yoff, 22, GROUND - 1 + yoff, c)
    rect(img, 11, GROUND - 8 + yoff, 21, GROUND - 5 + yoff, c)
    px(img, 11, GROUND - 2 + yoff, (216, 214, 200))  # belly shadow
    px(img, 8, GROUND - 4 + yoff, (40, 40, 44))
    px(img, 9, GROUND - 5 + yoff, (40, 40, 44))
    rect(img, 14, GROUND - 13 + yoff, 17, GROUND - 8 + yoff, c)
    px(img, 15, GROUND - 17 + yoff, (232, 60, 60))
    px(img, 16, GROUND - 15 + yoff, (232, 60, 60))
    px(img, 17, GROUND - 10 + yoff, (240, 150, 60))
    px(img, 17, GROUND - 13 + yoff, (22, 18, 16))
    px(img, 17, GROUND - 14 + yoff, (255, 255, 255))  # eye highlight
    px(img, 14, GROUND - 2 + yoff, (240, 150, 60))
    px(img, 19, GROUND - 2 + yoff, (240, 150, 60))


def _duck(img, bob):
    c = rgb(226, 224, 208)
    yoff = bob
    ellipse(img, 15, GROUND - 2 + yoff, 7, 4, c)
    px(img, 12, GROUND - 3 + yoff, (150, 174, 66))
    ellipse(img, 22, GROUND - 7 + yoff, 3, 3, rgb(150, 178, 118))
    px(img, 24, GROUND - 8 + yoff, (240, 150, 60))
    px(img, 23, GROUND - 7 + yoff, (20, 20, 20))
    px(img, 13, GROUND - 1 + yoff, (240, 170, 80))
    px(img, 17, GROUND - 1 + yoff, (240, 170, 80))


def _cow(img, bob):
    c = rgb(242, 236, 230)
    for lx in (10, 15, 20):
        rect(img, lx, GROUND - 4 + bob, lx + 1, GROUND + bob, (62, 48, 40))
        px(img, lx, GROUND - 5 + bob, (90, 70, 60))  # leg highlight
    rect(img, 10, GROUND - 11 + bob, 23, GROUND - 3 + bob, c)
    px(img, 17, GROUND - 6 + bob, (222, 214, 208))
    # distinct black spots for Stardew-like Holstein read
    rect(img, 13, GROUND - 10 + bob, 15, GROUND - 8 + bob, (48, 42, 40))
    rect(img, 19, GROUND - 9 + bob, 21, GROUND - 7 + bob, (48, 42, 40))
    rect(img, 23, GROUND - 10 + bob, 28, GROUND - 5 + bob, c)
    rect(img, 27, GROUND - 14 + bob, 30, GROUND - 8 + bob, c)
    px(img, 30, GROUND - 10 + bob, (250, 214, 200))
    px(img, 29, GROUND - 9 + bob, (20, 16, 14))
    px(img, 30, GROUND - 9 + bob, (255, 255, 255))  # eye glint
    px(img, 9, GROUND - 10 + bob, (48, 42, 40))  # tail tip dark
    px(img, 29, GROUND - 15 + bob, (210, 210, 214))


def _goat(img, bob):
    c = rgb(206, 196, 182)
    for lx in (11, 15, 19):
        rect(img, lx, GROUND - 3 + bob, lx + 1, GROUND + bob, (60, 50, 42))
    rect(img, 10, GROUND - 10 + bob, 21, GROUND - 3 + bob, c)
    px(img, 8, GROUND - 8 + bob, c)
    rect(img, 21, GROUND - 9 + bob, 25, GROUND - 4 + bob, c)
    rect(img, 24, GROUND - 6 + bob, 25, GROUND - 8 + bob, c)
    rect(img, 24, GROUND - 13 + bob, 26, GROUND - 8 + bob, c)
    px(img, 26, GROUND - 10 + bob, (196, 196, 202))
    px(img, 25, GROUND - 11 + bob, (20, 20, 20))
    px(img, 24, GROUND - 14 + bob, (214, 200, 182))


def _sheep(img, bob):
    body = rgb(242, 242, 246)
    wool = rgb(212, 212, 222)
    for lx in (11, 15, 19):
        rect(img, lx, GROUND - 3 + bob, lx + 1, GROUND + bob, (58, 48, 40))
    rect(img, 10, GROUND - 10 + bob, 22, GROUND - 3 + bob, body)
    # wool clumps with highlight/shadow for volume
    for (wx, wy) in ((12, GROUND - 9 + bob), (16, GROUND - 9 + bob), (20, GROUND - 9 + bob), (14, GROUND - 6 + bob), (18, GROUND - 6 + bob)):
        px(img, wx, wy, wool)
        px(img, wx + 1, wy, (255, 255, 255))
        px(img, wx, wy + 1, (190, 190, 200))
    rect(img, 22, GROUND - 9 + bob, 25, GROUND - 4 + bob, (212, 184, 162))
    rect(img, 24, GROUND - 12 + bob, 26, GROUND - 8 + bob, (212, 184, 162))
    px(img, 25, GROUND - 10 + bob, (20, 20, 20))
    px(img, 26, GROUND - 11 + bob, (255, 255, 255))
    px(img, 9, GROUND - 8 + bob, (90, 90, 96))


DRAW = {
    "chicken": _chicken,
    "duck": _duck,
    "cow": _cow,
    "goat": _goat,
    "sheep": _sheep,
}


def main():
    bob = (0, -1, 0)
    for name, func in DRAW.items():
        sheet = canvas(S * 3, S)
        for f_i in range(3):
            sheet.paste(frame(func, bob[f_i]), (f_i * S, 0))
        save(sheet, "animals", f"{name}.png")


if __name__ == "__main__":
    main()
