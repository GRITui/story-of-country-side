"""JRL Option B — High-Bit Kominka Crisp — Structures & Atmosphere
Farmhouse 64x64 (kawara #6A7A8A, shoji #F5F0E0, engawa, chimney 3f smoke)
Toby Shrine 32x32 (Jizo + torii vermilion #B03030 + moss #6B8B6A)
Hanna Store 64x32 (noren indigo #3A4A6B + crates)
Sakura tree 32x48 (spring/summer/autumn/winter) + Canal tile set
Sel-out #4A3320, not black.
"""
from PIL import Image
from px import canvas, px, rect, rgb, save, OUTLINE

def outline_jrl(img):
    # use sel-out #4A3320 for JRL, not black
    from px import outline as _o
    return _o(img, color=(74,51,32,255))

def farmhouse():
    W,H = 64,64
    img = canvas(W,H)
    # engawa veranda
    rect(img, 8,44,55,49, rgb(232,217,176))  # #E8D9B0
    rect(img, 8,44,55,44, rgb(139,106,74))
    rect(img, 8,49,55,49, rgb(139,106,74))
    # walls shoji
    rect(img, 12,24,51,43, rgb(245,240,224))  # #F5F0E0
    # wood frame vertical
    for x in (12,26,40,51): rect(img,x,24,x,43, rgb(139,106,74))
    rect(img,12,24,51,24, rgb(139,106,74)); rect(img,12,43,51,43, rgb(139,106,74))
    # shoji lattice
    for y in (28,32,36,40): rect(img,13,y,25,y, rgb(74,51,32))
    for x in (14,18,22): rect(img,x,25,x,42, rgb(74,51,32))
    for y in (28,32,36,40): rect(img,27,y,39,y, rgb(74,51,32))
    for x in (28,32,36): rect(img,x,25,x,42, rgb(74,51,32))
    # door
    rect(img,42,32,50,43, rgb(107,74,58))
    px(img,44,36,rgb(180,145,115))  # handle
    # roof kawara gray #6A7A8A
    rect(img, 6,16,57,23, rgb(106,122,138))
    rect(img, 6,16,57,17, rgb(138,154,168))  # ridge #8A9AA8
    for x in range(6,57,2): px(img,x,23, rgb(74,58,90))  # tile line dark
    # chimney
    rect(img,44,8,49,15, rgb(122,106,90))
    rect(img,44,8,49,9, rgb(90,74,58))
    # smoke 3 puffs (will be separate frames but bake one)
    px(img,46,4,rgb(245,240,224)); px(img,47,4,rgb(245,240,224))
    px(img,48,2,rgb(232,220,200)); px(img,49,0,rgb(220,210,190))
    # wildflowers
    px(img,10,50,rgb(255,208,122)); px(img,53,50,rgb(255,184,192))
    return outline_jrl(img)

def jizo_shrine():
    W,H = 32,32
    img = canvas(W,H)
    # ground moss
    rect(img,2,24,29,29, rgb(122,176,106))
    rect(img,4,26,27,27, rgb(168,200,144))
    # torii vermilion #B03030
    rect(img,5,8,26,11, rgb(176,48,48))
    rect(img,5,11,26,12, rgb(139,32,32))
    rect(img,8,11,10,24, rgb(176,48,48))
    rect(img,21,11,23,24, rgb(176,48,48))
    rect(img,4,16,27,17, rgb(176,48,48))
    # Jizo stone #9A9AA0
    rect(img,12,16,19,23, rgb(154,154,160))
    rect(img,13,16,16,17, rgb(176,176,184))
    px(img,14,17,rgb(107,107,106)); px(img,15,17,rgb(107,107,106))
    px(img,14,19,rgb(107,107,106)); px(img,16,19,rgb(107,107,106))
    px(img,14,20,rgb(255,184,192))  # bib
    # moss on base
    rect(img,12,22,19,24, rgb(107,139,106))
    px(img,13,23,rgb(139,192,122))
    # wildflowers 1px
    px(img,7,25,rgb(255,208,122)); px(img,24,25,rgb(255,184,192)); px(img,9,26,rgb(160,208,224))
    return outline_jrl(img)

def hanna_store():
    W,H = 64,32
    img = canvas(W,H)
    rect(img,4,8,59,23, rgb(245,240,224))
    rect(img,4,8,59,9, rgb(139,106,74)); rect(img,4,23,59,24, rgb(139,106,74))
    # noren indigo #3A4A6B
    rect(img,12,8,51,14, rgb(58,74,107))
    px(img,24,9,rgb(232,217,176)); px(img,30,9,rgb(232,217,176)); px(img,36,9,rgb(232,217,176))
    px(img,24,10,rgb(232,217,176)); px(img,30,10,rgb(232,217,176))
    # crates
    rect(img,8,18,20,24, rgb(139,106,74)); rect(img,8,18,20,19, rgb(74,51,32))
    rect(img,43,18,55,24, rgb(139,106,74)); rect(img,43,18,55,19, rgb(74,51,32))
    # produce
    px(img,10,16,rgb(255,138,80)); px(img,12,16,rgb(255,138,80)); px(img,14,17,rgb(122,192,48))
    px(img,45,16,rgb(122,192,48)); px(img,47,16,rgb(122,192,48)); px(img,12,20,rgb(232,217,176))
    px(img,10,22,rgb(255,208,96))  # highlight
    return outline_jrl(img)

def sakura_tree(season="spring"):
    W,H = 32,48
    img = canvas(W,H)
    # trunk #4A3320
    rect(img,14,28,17,42, rgb(74,51,32))
    rect(img,13,36,18,38, rgb(74,51,32))
    if season=="spring":
        rect(img,5,6,26,22, rgb(255,184,192))
        rect(img,8,3,23,8, rgb(255,184,192))
        rect(img,8,7,15,10, rgb(255,208,216))  # highlight
        px(img,10,28,rgb(255,232,232)); px(img,24,30,rgb(255,232,232))
    elif season=="summer":
        rect(img,5,6,26,22, rgb(107,139,106))
        rect(img,8,3,23,8, rgb(107,139,106))
        rect(img,8,7,15,10, rgb(139,192,122))
    elif season=="autumn":
        rect(img,5,6,26,22, rgb(232,176,64))
        rect(img,8,3,23,8, rgb(232,176,64))
        rect(img,7,9,13,11, rgb(217,128,48))
        px(img,16,10,rgb(255,208,96))
    elif season=="winter":
        # bare branches
        rect(img,11,8,20,9, rgb(74,51,32)); rect(img,8,13,23,14, rgb(74,51,32))
        rect(img,13,6,14,18, rgb(74,51,32)); rect(img,17,7,18,16, rgb(74,51,32))
        px(img,9,8,rgb(232,240,248)); px(img,19,13,rgb(232,240,248))
    return outline_jrl(img)

def canal_hstrip():
    # 16x16 canal already in tiles; make 48x16 strip for preview
    from gen_tiles_jrl_b import water
    strip = canvas(64,16)
    for i in range(4):
        w = water(i)
        for y in range(16):
            for x in range(16):
                strip.putpixel((i*16+x, y), w.getpixel((x,y)))
    return strip

def main():
    save(farmhouse(), "props", "farmhouse.png")
    # seasonal variants
    # farmhouse spring already; make autumn/winter overlays via recolor — reuse same base for now, save copies
    save(farmhouse(), "props", "farmhouse_spring.png")
    save(farmhouse(), "props", "farmhouse_summer.png")
    # autumn: add leaf scatter overlay
    fh_aut = farmhouse().copy()
    px(fh_aut, 10,50,rgb(255,208,122)); px(fh_aut, 55,51,rgb(232,176,64)); save(fh_aut, "props", "farmhouse_autumn.png")
    fh_win = farmhouse().copy()
    # snow cap on roof
    for x in range(8,57): px(fh_win, x, 16, rgb(232,240,248))
    save(fh_win, "props", "farmhouse_winter.png")

    save(jizo_shrine(), "props", "jizo_shrine.png")
    save(jizo_shrine(), "props", "jizo_statue.png")  # alias for old path
    save(hanna_store(), "props", "hanna_store.png")
    # sakura seasons
    for s in ("spring","summer","autumn","winter"):
        save(sakura_tree(s), "props", f"sakura_{s}.png")
    save(sakura_tree("spring"), "props", "sakura.png")
    # canal strip
    from gen_tiles_jrl_b import water
    strip = canvas(64,16)
    for i in range(4):
        w = water(i)
        for y in range(16):
            for x in range(16):
                strip.putpixel((i*16+x,y), w.getpixel((x,y)))
    save(strip, "tiles", "canal_strip.png")
    # chimney smoke frames 16x16 (drifting puffs, min 4x4 opaque for validate.py)
    from px import ellipse
    for f in range(3):
        sm = canvas(16,16)
        a = [200, 130, 70][f]
        ellipse(sm, 7+f, 10-f*2, 3, 2, (245,240,224,a))
        ellipse(sm, 9+f, 7-f*2, 2, 2, (232,220,200, int(a*0.7)))
        px(sm, 11+f, 3-f, (220,210,190, int(a*0.45)))
        px(sm, 12+f, 2-f, (220,210,190, int(a*0.3)))
        save(sm, "props", f"smoke_{f}.png")

if __name__=="__main__": main()
