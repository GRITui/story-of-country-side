"""JRL Option B — High-Bit Kominka Crisp — 16x16 orthogonal tiles
Replaces old 64x32 isometric diamonds. Palette = Ghibli pastel, sel-out #4A3320.
Generates 4 soil states, grass season LUT, water 4-frame, path/tatami.

Palette LUT (from Art Bible v1.0):
 Grass spring #E2F0C8 / summer #8BC07A / autumn #D9B066
 Soil until #C9A080, tilled #8B4A30, ridge #4A2010, highlight #B87A50, watered #2A1512 + sheen #6A8BBB, withered #8A7E6E crack #5A4A3A
 Wood #8B6A4A / tatami #E8D9B0 / shoji #F5F0E0 / sel-out #4A3320
 Water 10 shades: foam #E0F0F8, ripple #A0D0E0, base #7AAABB 70%, dark #2A4A5A
"""
from PIL import Image
from px import canvas, px, rect, rgb, save, OUTLINE

# JRL B palette — crisp sel-out not black
SEL = (74, 51, 32, 255)  # #4A3320
W = 16; H = 16

def soil_dry_until():
    img = canvas(W,H)
    for y in range(H):
        for x in range(W):
            # base terracotta with micro pebbles
            if (x+y)%5==0: c = rgb(160,120,96)  # pebble #A07860
            elif (x*3+y*2)%7==0: c = rgb(180,145,115)
            else: c = rgb(201,160,128)  # #C9A080
            px(img,x,y,c)
    # 1px sel-out border at bottom for tile separation (visual test: keep faint)
    for x in range(W): px(img,x,H-1, (74,51,32, 90))
    return img

def soil_tilled_dry():
    img = canvas(W,H)
    for y in range(H):
        for x in range(W):
            if y%4==2: c = rgb(74,32,16)  # ridge shadow #4A2010
            elif y%4==3: c = rgb(184,122,80)  # highlight #B87A50
            else: c = rgb(139,74,48)  # #8B4A30
            px(img,x,y,c)
    # extra ridge lines every 4
    for y in (4,8,12): 
        for x in range(W): px(img,x,y, rgb(74,32,16))
    return img

def soil_tilled_watered(phase=0):
    """4-frame sheen LUT: phase 0..3 scrolls blue sheen row"""
    img = canvas(W,H)
    for y in range(H):
        for x in range(W):
            if y%4==2: c = rgb(26,15,15)
            elif y%4==3: c = rgb(106,139,187)  # sheen line #6A8BBB
            else: c = rgb(42,21,18)  # #2A1512
            # add sheen scatter that moves with phase
            if y>9 and (x+phase)%3==0 and y%2==0:
                # blend sheen 35%
                c = (int(c[0]*0.65+106*0.35), int(c[1]*0.65+139*0.35), int(c[2]*0.65+187*0.35), 255)
            px(img,x,y,c)
    # animate highlight intensity
    if phase==1: 
        for x in range(W): px(img,x,11, rgb(120,150,195))
    elif phase==2:
        for x in range(W): px(img,x,11, rgb(135,165,205))
        for x in range(W): px(img,x,7, rgb(100,135,180))
    return img

def soil_withered():
    img = canvas(W,H)
    for y in range(H):
        for x in range(W):
            if x%4==0 or y%4==0: c = rgb(90,74,58)  # crack #5A4A3A
            elif (x+y)%4==0: c = rgb(122,110,94)  # mid
            else: c = rgb(138,126,110)  # #8A7E6E
            px(img,x,y,c)
    return img

def grass_spring():
    img = canvas(W,H)
    for y in range(H):
        for x in range(W):
            if y<3: c = rgb(168,200,144) if x%2==0 else rgb(139,74,48)  # fringe? no — keep simple
            else: c = rgb(226,240,200) if (x+y)%3==0 else rgb(168,200,144)
            px(img,x,y,c)
    # fringe top 3px
    for y in range(3):
        for x in range(W):
            px(img,x,y, rgb(139,192,122) if x%2==0 else rgb(107,139,106))
    for x in range(W): px(img,x,3, (74,51,32,200))
    return img

def grass_summer():
    img = canvas(W,H)
    for y in range(H):
        for x in range(W):
            if y<2: c = rgb(160,240,160) if x%2 else rgb(80,160,48)
            elif y==2: c = rgb(74,51,32)
            else: c = rgb(107,139,106) if (x+y)%4==0 else rgb(42,74,48)
            px(img,x,y,c)
    return img

def grass_autumn():
    img = canvas(W,H)
    for y in range(H):
        for x in range(W):
            if y<3: c = rgb(217,176,102) if x%2==0 else rgb(232,176,64)
            else: c = rgb(201,160,100) if (x+y)%5==0 else rgb(139,120,70)
            px(img,x,y,c)
    for x in range(W): px(img,x,3, (74,51,32,180))
    return img

def water(phase=0):
    img = canvas(W,H)
    for y in range(H):
        for x in range(W):
            if (x+phase)%4<2 and y%3==1: c = rgb(160,208,224)  # ripple #A0D0E0
            elif (x*y+phase)%9==0: c = rgb(224,240,248)  # foam #E0F0F8
            elif y>10: c = rgb(58,90,110)  # deep
            else: c = rgb(122,170,187)  # base #7AAABB
            px(img,x,y,c)
    # wooden canal edge top/bottom 1px
    for x in range(W): px(img,x,0, rgb(139,106,74)); px(img,x,H-1, rgb(139,106,74))
    return img

def wood_floor():
    img = canvas(W,H)
    for y in range(H):
        for x in range(W):
            if x%4==0: c = rgb(90,58,40)  # seam #5A3A28
            elif x%4==1: c = rgb(217,184,154)  # highlight #D9B89A
            else: c = rgb(139,106,74)  # #8B6A4A
            if y%6==0: c = rgb(107,74,58)
            px(img,x,y,c)
    return img

def tatami():
    img = canvas(W,H)
    for y in range(H):
        for x in range(W):
            if x==0 or y==0 or x==15 or y==15: c = rgb(139,106,74)  # border wood
            elif x%8==0 or y%8==0: c = rgb(201,184,149)  # stitch #C9B895
            elif (x+y)%7==0: c = rgb(217,201,160)  # highlight
            else: c = rgb(232,217,176)  # #E8D9B0 straw
            px(img,x,y,c)
    return img

def main():
    save(soil_dry_until(), "tiles", "soil_dry_until.png")
    save(soil_tilled_dry(), "tiles", "soil_tilled_dry.png")
    for f in range(4):
        save(soil_tilled_watered(f), "tiles", f"soil_tilled_watered_{f}.png")
    save(soil_tilled_watered(2), "tiles", "soil_tilled_watered.png")  # default frame
    save(soil_withered(), "tiles", "soil_withered.png")
    save(grass_spring(), "tiles", "grass_spring.png")
    save(grass_summer(), "tiles", "grass_summer.png")
    save(grass_autumn(), "tiles", "grass_autumn.png")
    save(grass_summer(), "tiles", "grass.png")  # alias
    for f in range(4):
        save(water(f), "tiles", f"water_{f}.png")
    save(water(0), "tiles", "water.png")
    save(wood_floor(), "tiles", "wood_floor.png")
    save(tatami(), "tiles", "tatami.png")
    # palette LUT 32x32 for season shader
    lut = canvas(32,32)
    for y in range(32):
        for x in range(32):
            # encode grass/soil/water wood autumn as swatches
            pass
    # palette preview 10x1
    pal = canvas(160,16)
    cols = [(226,240,200,255),(168,200,144,255),(139,192,122,255),(201,160,128,255),(139,74,48,255),(42,21,18,255),(106,139,187,255),(138,126,110,255),(122,170,187,255),(139,106,74,255)]
    for i,c in enumerate(cols):
        for y in range(16):
            for x in range(16):
                px(pal, i*16+x, y, c)
    save(pal, "tiles", "palette_jrl_b.png")

if __name__=="__main__": main()
