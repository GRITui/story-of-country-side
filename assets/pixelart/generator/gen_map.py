"""World map: a stylized 256x256 overview for the MapOverlay.

Not a 1:1 TileMap; a top-down-ish stylized regional map showing where the
world scenes (farm, ranch, forest, mine, town/water) sit, so the Frontend
MapOverlay can render it as a backdrop + point markers.
"""
from px import canvas, ellipse, px, rect, rgb, save, speckle_on, outline


def _region(img, cx, cy, w, h, seed, c):
    return speckle_on(Image)


def main():
    img = canvas(256, 256)
    # background water
    for y in range(256):
        for x in range(256):
            img.putpixel((x, y), (64, 118, 178))
    # speckled water
    import random
    rng = random.Random(11)
    for _ in range(300):
        x, y = rng.randrange(0, 256), rng.randrange(0, 256)
        p = img.getpixel((x, y))
        img.putpixel((x, y), (min(255, p[0] + 18), min(255, p[1] + 22), 178))

    # main landmass
    def land(x0, y0, x1, y1, c):
        for y in range(y0, y1):
            for x in range(x0, x1):
                if img.getpixel((x, y)) == (64, 118, 178):
                    img.putpixel((x, y), c)

    def patch(cx, cy, rx, ry, c):
        y0 = max(0, int(cy - ry)); y1 = min(256, int(cy + ry))
        x0 = max(0, int(cx - rx)); x1 = min(256, int(cx + rx))
        for y in range(y0, y1):
            for x in range(x0, x1):
                nx = (x + 0.5 - cx) / rx
                ny = (y + 0.5 - cy) / ry
                if nx * nx + ny * ny <= 1.0:
                    img.putpixel((x, y), c)

    patch(128, 120, 108, 84, (104, 160, 70))        # main island (farm + forest)
    patch(230, 60, 34, 26, (104, 160, 70))          # north island (mine)
    patch(230, 200, 30, 24, (104, 160, 70))         # east islet

    # fields around farm (bottom-center of the island)
    for (fx, fy, fw) in ((78, 120, 6), (96, 122, 6), (114, 120, 6), (86, 132, 6),
                         (104, 132, 6), (122, 132, 6)):
        for y in range(fy, fy + 4):
            for x in range(fx, fx + 4):
                img.putpixel((x, y), (178, 132, 70))

    # forest patch (upper right of island)
    for (tx, ty) in ((150, 60), (162, 70), (150, 74), (170, 84), (158, 90),
                     (146, 88), (176, 64), (160, 60)):
        for y in range(ty, ty + 4):
            for x in range(tx, tx + 4):
                img.putpixel((x, y), (52, 120, 66))

    # town center: small cluster
    for (bxx, byy, c) in [(60, 82, (196, 150, 96)), (66, 78, (176, 128, 84)),
                          (56, 74, (196, 150, 96))]:
        for y in range(byy, byy + 3):
            for x in range(bxx, bxx + 3):
                img.putpixel((x, y), c)

    # roads
    for y in range(60, 120):
        img.putpixel((128, y), (210, 190, 150)); img.putpixel((129, y), (210, 190, 150))
    for x in range(90, 140):
        img.putpixel((x, 104), (210, 190, 150)); img.putpixel((x, 105), (210, 190, 150))

    # mine marker on north island
    for y in range(50, 60):
        for x in range(224, 236):
            img.putpixel((x, y), (120, 118, 118))
    # lake north-west
    patch(40, 40, 14, 10, (96, 170, 200))

    # sprinkle small trees along the island middle
    import random
    rng = random.Random(5)
    for _ in range(40):
        x, y = rng.randrange(50, 205), rng.randrange(40, 165)
        if img.getpixel((x, y))[1] > 150:
            img.putpixel((x, y), (44, 116, 70))

    img = outline(img, color=(96, 60, 50))
    save(img, "map", "world_map.png")


if __name__ == "__main__":
    main()
