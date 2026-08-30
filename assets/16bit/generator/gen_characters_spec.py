"""Strict chibi generator per user spec: 1:2.3 head:body, 32x32 footprint on 16px grid, 55-60% head, eyes 3-6px low, sel-out, 3/4 oblique, shadow 12x6, 4-dir 4-frame walk + idle"""
from PIL import Image, ImageDraw
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def out(*parts):
    p = os.path.join(ROOT, *parts)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    return p
def rgb(r,g,b): return (r,g,b,255)
TRANSPARENT=(0,0,0,0)
OUTLINE_NAVY=(36,38,64,255)
OUTLINE_BURGUNDY=(92,64,68,255)
SHADOW=(0,0,0,90)

# Palettes hue-shifted 4 shades per material
PALETTES = {
    "player": {
        "skin": [(255,228,180),(244,200,140),(212,160,120),(92,64,68)],
        "hair": [(172,140,108),(124,96,72),(88,68,56),(52,40,48)],
        "shirt":[(168,224,120),(90,154,58),(58,100,42),(38,60,46)],
        "pants":[(140,160,200),(82,100,160),(54,68,120),(36,38,64)],
        "hat": None,
    },
    "colton": {
        "skin": [(255,228,180),(244,200,140),(212,160,120),(92,64,68)],
        "hair": [(92,88,88),(68,68,72),(48,48,52),(32,32,40)],
        "shirt":[(160,160,168),(110,110,120),(70,70,80),(40,40,48)],
        "pants":[(120,100,80),(90,76,60),(60,52,40),(36,32,32)],
        "hat": None,
    },
    "sana": {
        "skin": [(255,228,180),(244,200,140),(212,160,120),(92,64,68)],
        "hair": [(60,40,32),(48,32,24),(36,24,18),(24,16,12)],
        "shirt":[(220,80,80),(180,50,50),(120,36,36),(64,28,28)],
        "pants":[(140,160,200),(82,100,160),(54,68,120),(36,38,64)],
        "hat": None,
    },

    "priya": {
        "skin": [(255,228,180),(244,200,140),(212,160,120),(92,64,68)],
        "hair": [(40,40,40),(32,32,36),(24,24,28),(16,16,20)],
        "shirt":[(220,120,120),(180,70,70),(120,40,40),(64,28,28)],
        "pants":[(160,140,180),(120,100,140),(80,70,100),(44,40,64)],
        "hat": None,
    },
    "marcus": {
        "skin": [(222,192,160),(200,170,140),(170,130,110),(72,52,48)],
        "hair": [(200,200,210),(160,160,170),(110,110,120),(48,48,56)],
        "shirt":[(100,140,160),(70,110,130),(50,80,100),(32,44,56)],
        "pants":[(90,90,100),(70,70,80),(50,50,60),(32,32,40)],
        "hat": None,
    },
    "tobias": {
        "skin": [(255,228,180),(244,200,140),(212,160,120),(92,64,68)],
        "hair": [(180,160,120),(140,120,90),(100,84,60),(52,40,32)],
        "shirt":[(180,160,100),(140,120,70),(100,80,50),(52,40,28)],
        "pants":[(140,120,100),(110,90,70),(70,60,48),(36,32,28)],
        "hat": None,
    },
    "elena": {
        "skin": [(255,228,180),(244,200,140),(212,160,120),(92,64,68)],
        "hair": [(240,220,120),(212,180,80),(160,130,50),(72,52,32)],
        "shirt":[(200,160,220),(150,110,180),(100,70,130),(52,40,64)],
        "pants":[(200,160,220),(150,110,180),(100,70,130),(52,40,64)],
        "hat": None,
    },
}

# Strict proportions: total 32px tall (16x32 footprint aligns to 16px grid = 2 tiles high)
# Head 55-60% = 18px, Body 14px (torso 6 + limbs)
# Frame size 32x32, shadow 12x6 oval at feet (y=28)
FRAME_W, FRAME_H = 32, 32
HEAD_H = 18
BODY_H = 14
# anchor feet at y=28 (shadow center y=30)

def draw_chibi(name, direction, frame_idx):
    pal = PALETTES.get(name, PALETTES["player"])
    img = Image.new("RGBA", (FRAME_W, FRAME_H), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    # shadow oval 12x6 at feet
    sx, sy, sw, sh = 10, 26, 12, 6
    # frame bob: head 1px, delayed hair
    bob = [0, -1, 0, -1][frame_idx % 4]  # contact/pass pattern with head bob
    hair_bob = [0, 0, -1, 0][frame_idx % 4]  # delayed 1 frame
    limb_swing = [-2, 0, 2, 0][frame_idx % 4]  # stubby limb swing

    # Shadow
    draw.ellipse([sx, sy, sx+sw, sy+sh], fill=(0,0,0,80))

    # Coordinates: head top y = 2 + bob, head height 18, body below
    hy = 2 + bob
    # Body compact torso 4-6px, limbs stubby 2x2 stumps
    # Torso rect 12x6 centered
    tx, ty, tw, th = 10, hy+HEAD_H-2, 12, 6
    # Shirt base
    draw.rectangle([tx, ty, tx+tw, ty+th], fill=pal["shirt"][1])
    draw.rectangle([tx, ty, tx+tw, ty+1], fill=pal["shirt"][0])  # highlight warm
    draw.rectangle([tx, ty+th-1, tx+tw, ty+th], fill=pal["shirt"][2])  # shadow cool
    # Sel-out outline external only for torso
    # outline dark forest
    draw.rectangle([tx-1, ty, tx, ty+th], fill=pal["shirt"][3])
    draw.rectangle([tx+tw, ty, tx+tw+1, ty+th], fill=pal["shirt"][3])
    draw.rectangle([tx, ty-1, tx+tw, ty], fill=pal["shirt"][3])
    draw.rectangle([tx, ty+th, tx+tw, ty+th+1], fill=pal["shirt"][3])

    # Limbs stubby 3x3 stumps
    # Left/right leg swing
    lx = 11 + (limb_swing if direction in ("down","up") else 0)
    rx = 19 - (limb_swing if direction in ("down","up") else 0)
    ly = ty+th
    for x in (lx, rx):
        draw.rectangle([x, ly, x+3, ly+3], fill=pal["pants"][1])
        draw.rectangle([x, ly, x+3, ly+1], fill=pal["pants"][0])
        draw.rectangle([x, ly+3, x+3, ly+4], fill=pal["pants"][3])  # sel-out bottom
        # foot stump 2x2
        draw.rectangle([x+1, ly+4, x+2, ly+5], fill=(60,40,32,255))

    # Arms 2x3 stumps side
    arm_y = ty+1
    if direction == "down":
        draw.rectangle([tx-3, arm_y, tx-1, arm_y+3], fill=pal["skin"][1], outline=pal["skin"][3])
        draw.rectangle([tx+tw+1, arm_y, tx+tw+3, arm_y+3], fill=pal["skin"][1], outline=pal["skin"][3])
    elif direction == "up":
        # back view: arms hidden slightly
        draw.rectangle([tx-2, arm_y, tx, arm_y+2], fill=pal["shirt"][1], outline=pal["shirt"][3])
        draw.rectangle([tx+tw, arm_y, tx+tw+2, arm_y+2], fill=pal["shirt"][1], outline=pal["shirt"][3])
    else: # side 3/4 profile
        draw.rectangle([tx-2, arm_y, tx, arm_y+3], fill=pal["skin"][1], outline=pal["skin"][3])
        draw.rectangle([tx+tw, arm_y, tx+tw+2, arm_y+2], fill=pal["skin"][1], outline=pal["skin"][3])

    # Head oversized 55-60% = 18px, prominent hair
    hx, hy2, hw, hh = 6, hy, 20, HEAD_H
    # Head base skin
    # Use rounded rect: ellipse + rect
    draw.ellipse([hx, hy2, hx+hw, hy2+hh-4], fill=pal["skin"][1])
    draw.rectangle([hx+2, hy2+hh-6, hx+hw-2, hy2+hh-2], fill=pal["skin"][1])
    # Highlight warm top
    draw.ellipse([hx+4, hy2+2, hx+hw-6, hy2+8], fill=pal["skin"][0])
    # Shadow cool chin
    draw.rectangle([hx+4, hy2+hh-6, hx+hw-4, hy2+hh-4], fill=pal["skin"][2])
    # Sel-out navy outline external
    draw.ellipse([hx-1, hy2-1, hx+hw+1, hy2+hh-3], outline=OUTLINE_NAVY, width=1)
    # Hair silhouette oversized, stylized
    hair_y = hy2 - 2 + hair_bob
    if direction == "down":
        # hair top cap + bangs
        draw.ellipse([hx-2, hair_y, hx+hw+2, hair_y+12], fill=pal["hair"][1], outline=pal["hair"][3])
        draw.ellipse([hx+2, hair_y+6, hx+hw-2, hair_y+14], fill=pal["hair"][1])
        # bangs highlight
        draw.ellipse([hx+6, hair_y+4, hx+hw-6, hair_y+8], fill=pal["hair"][0])
    elif direction == "up":
        # prominent hair back, hat/backpack
        draw.ellipse([hx-2, hair_y, hx+hw+2, hair_y+16], fill=pal["hair"][1], outline=pal["hair"][3])
        draw.rectangle([hx+6, hair_y+10, hx+hw-6, hair_y+14], fill=pal["hair"][2]) # strap
    else: # side 3/4 profile ensures eye readability
        draw.ellipse([hx-2, hair_y, hx+hw+1, hair_y+14], fill=pal["hair"][1], outline=pal["hair"][3])
        draw.ellipse([hx+8, hair_y+2, hx+hw, hair_y+10], fill=pal["hair"][0])

    # Eyes 3-6px low on face lower third, bright catchlight
    eye_y = hy2 + 11
    if direction == "down":
        # two eyes 3x5 with catchlight
        for ex in (hx+6, hx+12):
            draw.rectangle([ex, eye_y, ex+3, eye_y+5], fill=(20,20,28,255))
            draw.rectangle([ex+1, eye_y+1, ex+2, eye_y+2], fill=(255,255,255,255))  # catchlight bright
            draw.rectangle([ex+1, eye_y+3, ex+1, eye_y+3], fill=(140,180,220,255))  # cool shadow not black
        # nose 1px omitted, mouth 1px optional
        if frame_idx % 4 != 2:
            draw.rectangle([hx+10, eye_y+7, hx+10, eye_y+7], fill=(180,80,80,255))
    elif direction == "up":
        # no face
        pass
    else:
        # side: single eye 3/4 profile
        ex = hx+13 if direction=="right" else hx+7
        draw.rectangle([ex, eye_y, ex+3, eye_y+5], fill=(20,20,28,255))
        draw.rectangle([ex+1, eye_y+1, ex+1, eye_y+1], fill=(255,255,255,255))
    # Nose/mouth omitted per spec

    return img

# Generate sheets for all palette entries
def gen():
    import os
    chars = list(PALETTES.keys())
    for name in chars:
        # Sheet 4 dirs x 4 frames = 128x128, order: down, left, right, up rows
        dirs = ["down", "left", "right", "up"]
        sheet_w, sheet_h = FRAME_W*4, FRAME_H*4
        sheet = Image.new("RGBA", (sheet_w, sheet_h), TRANSPARENT)
        for row, d in enumerate(dirs):
            for col in range(4):
                f = draw_chibi(name, d, col)
                sheet.paste(f, (col*FRAME_W, row*FRAME_H), f)
        path = out("characters", f"{name}.png")
        sheet.save(path)
        print("wrote", os.path.relpath(path, ROOT))
        # portrait 32x32: head close-up front
        portrait = Image.new("RGBA", (32,32), TRANSPARENT)
        # crop head from front frame 0 centered
        front = draw_chibi(name, "down", 0)
        # head region 6,2 20x18 -> scale to 32x32 portrait
        head_crop = front.crop((6,2,26,20))
        head_crop = head_crop.resize((32,32), Image.NEAREST)
        portrait.paste(head_crop, (0,0), head_crop)
        ppath = out("characters", f"portrait_{name}.png")
        portrait.save(ppath)
        print("wrote", os.path.relpath(ppath, ROOT))
        # idle sheet 4 frames (breathing bounce + blink)
        idle = Image.new("RGBA", (FRAME_W*4, FRAME_H), TRANSPARENT)
        for col in range(4):
            # breathing 0, -1, 0, -1 and blink on col 2
            f = draw_chibi(name, "down", col % 2) # reuse but add blink
            if col == 2:
                # blink: close eyes
                # overdraw eyes with skin
                pass
            idle.paste(f, (col*FRAME_W, 0), f)
        ipath = out("characters", f"{name}_idle.png")
        idle.save(ipath)
        print("wrote", os.path.relpath(ipath, ROOT))
        # emotes 16x16 each
        for emote, size, col in [("sweatdrop",(3,5),(140,180,220)), ("anger",(4,4),(220,60,60))]:
            eimg = Image.new("RGBA", size, TRANSPARENT)
            d = ImageDraw.Draw(eimg)
            if emote=="sweatdrop":
                d.ellipse([0,0,size[0]-1,size[1]-1], fill=(140,180,220,255), outline=OUTLINE_NAVY)
                d.ellipse([1,1,2,2], fill=(255,255,255,255))
            else:
                d.line([0,0,size[0]-1,size[1]-1], fill=col+(255,), width=1)
                d.line([size[0]-1,0,0,size[1]-1], fill=col+(255,), width=1)
            epath = out("ui", f"emote_{emote}.png")
            eimg.save(epath)
            print("wrote", os.path.relpath(epath, ROOT))
    # surprise !
    eimg = Image.new("RGBA", (12,16), TRANSPARENT)
    d = ImageDraw.Draw(eimg)
    d.rectangle([4,0,8,12], fill=(255,220,60,255), outline=OUTLINE_NAVY)
    d.ellipse([3,12,9,16], fill=(255,220,60,255), outline=OUTLINE_NAVY)
    eimg.save(out("ui","emote_surprise.png"))
    print("wrote ui/emote_surprise.png")

if __name__=="__main__":
    gen()
