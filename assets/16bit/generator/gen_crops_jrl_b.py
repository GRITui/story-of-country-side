"""JRL Option B — High-Bit Kominka Crisp — Crops 16x16 x 4 stages
Watermelon (summer vine sprawl stripes), Edamame (clumpy pods), Turnip (bulb pop), Sweet Potato (leafy sprawl)
Each crop: 4 individual PNGs + 1 strip 64x16. Crisp sel-out #4A3320, pastel Ghibli.
"""
from px import canvas, px, rect, rgb, save

S=16

def base_soil(img):
    for y in range(S):
        for x in range(S):
            if y>11: c = rgb(107,48,32)
            else: c = rgb(139,74,48)
            px(img,x,y,c)

def wm_stage(img, stage):
    base_soil(img)
    if stage==0:
        px(img,7,8,rgb(58,32,16)); px(img,8,8,rgb(58,32,16)); px(img,7,7,rgb(184,122,80))
    elif stage==1:
        # sprout 2 leaves
        px(img,6,7,rgb(90,160,80)); px(img,9,7,rgb(90,160,80))
        px(img,7,5,rgb(107,180,90)); px(img,8,5,rgb(107,180,90))
        px(img,7,7,rgb(74,32,16))
    elif stage==2:
        # sprawl 8x5
        rect(img,4,6,11,10, rgb(74,122,48))
        px(img,5,7,rgb(42,74,48)); px(img,9,8,rgb(42,74,48))
        px(img,6,8,rgb(122,176,106))
    elif stage==3:
        # ripe big striped melon
        rect(img,2,8,13,13, rgb(42,74,48))
        rect(img,3,6,12,11, rgb(122,176,106))
        for x in (4,6,8,10): rect(img,x,6,x,11, rgb(42,90,32))  # stripes
        px(img,7,7,rgb(74,122,48)); px(img,6,9,rgb(255,208,96))

def ed_stage(img, stage):
    base_soil(img)
    if stage==0:
        px(img,7,8,rgb(58,32,16)); px(img,8,8,rgb(58,32,16))
    elif stage==1:
        rect(img,7,6,8,9, rgb(139,192,122))
        rect(img,6,8,9,9, rgb(107,150,90))
    elif stage==2:
        rect(img,4,5,11,10, rgb(107,170,74))
        for x in (5,7,9): px(img,x,7,rgb(74,122,48)); px(img,x,8,rgb(74,122,48))
        px(img,5,6,rgb(168,208,128))
    elif stage==3:
        rect(img,3,4,12,10, rgb(74,122,48))
        for x in (4,6,8,10): rect(img,x,6,x,8, rgb(122,200,80))
        px(img,5,6,rgb(168,224,144))

def tu_stage(img, stage):
    base_soil(img)
    if stage==0:
        px(img,7,8,rgb(58,32,16)); px(img,8,8,rgb(58,32,16))
    elif stage==1:
        rect(img,6,5,9,7, rgb(122,176,106))
        px(img,7,5,rgb(90,140,80))
    elif stage==2:
        rect(img,5,4,10,8, rgb(107,170,106))
        rect(img,6,8,9,11, rgb(232,240,232))  # bulb popping
        px(img,7,5,rgb(74,122,48))
    elif stage==3:
        rect(img,4,4,11,8, rgb(107,170,106))
        rect(img,5,8,10,13, rgb(245,240,232))  # bulb fully out
        rect(img,6,12,9,12, rgb(232,217,200))
        px(img,7,9,rgb(255,184,192)); px(img,8,9,rgb(255,184,192))

def sp_stage(img, stage):
    base_soil(img)
    if stage==0:
        px(img,7,8,rgb(58,32,16)); px(img,8,8,rgb(58,32,16))
    elif stage==1:
        rect(img,5,7,10,9, rgb(139,192,122))
    elif stage==2:
        rect(img,3,5,12,9, rgb(107,139,106))
        px(img,4,6,rgb(74,82,48)); px(img,8,7,rgb(74,82,48))
    elif stage==3:
        rect(img,3,5,12,10, rgb(107,139,106))
        rect(img,5,9,10,12, rgb(139,106,74))  # tubers
        rect(img,6,10,7,11, rgb(217,176,128))
        px(img,5,6,rgb(74,51,32))

CROPS = {
    "watermelon": wm_stage,
    "edamame": ed_stage,
    "turnip": tu_stage,
    "sweet_potato": sp_stage,
}

def make_crop(name, fn):
    strip = canvas(64,16)
    for stage in range(4):
        img = canvas(S,S)
        fn(img, stage)
        # paste into strip
        for y in range(S):
            for x in range(S):
                r,g,b,a = img.getpixel((x,y))
                if a: strip.putpixel((stage*16+x, y), (r,g,b,a))
        save(img, "crops", f"{name}_{stage}.png")
    save(strip, "crops", f"{name}.png")  # 64x16 strip

def main():
    for name, fn in CROPS.items():
        make_crop(name, fn)

if __name__=="__main__": main()
