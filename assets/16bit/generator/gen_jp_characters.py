"""JRL Option B — Player avatar + NPC Grandma Chiyo.

Player: `characters/player_jp.png` — 384x256 sheet, 24x32 cells,
16 cols (dirs Down,Up,Left,Right x 4 frames) x 8 rows:
  0 idle | 1 walk | 2 sit_engawa | 3 hoe_swing | 4 rice_plant
  5 bug_net | 6 fishing | 7 bow
Bottom-center anchor (feet y=31, cx=11.5), identical pivots across all
frames for AnimatedSprite2D. Variants via palette swap:
  player_jp_winter.png (hanten + knit cap), player_jp_yukata.png
  (festival yukata + red obi + asanoha dots).

NPC: `characters/npc_chiyo.png` — 384x64 (rows idle/walk, same grid),
grey bun, plum kimono, white kappogi apron, bamboo broom on idle.
Portraits `characters/portrait_chiyo_<expr>.png` 128x128 (4x nearest
upscale of 32x32 masters, also saved as *_32.png for the dialogue UI).
"""
import math

from PIL import Image

from px import canvas, ellipse, flip_h, out, px, rect, rgb
from jp_import import write_import, save_with_import

W, H = 24, 32
CX = 11  # center column (feet anchor x ~ 11.5)

SUMMER = dict(
    skin=rgb(0xF2, 0xC8, 0x94), skin_d=rgb(0xD9, 0xA0, 0x6B),
    hair=rgb(0x2A, 0x2A, 0x32),
    shirt=rgb(0x4A, 0x5A, 0x8A), shirt_d=rgb(0x3A, 0x44, 0x68),
    trim=rgb(0xF8, 0xF8, 0xF0),
    pants=rgb(0x5A, 0x64, 0x78), boots=rgb(0x3A, 0x3A, 0x42),
    hat=rgb(0xE8, 0xD0, 0x6A), hat_d=rgb(0xC4, 0xA8, 0x44), band=rgb(0xB0, 0x50, 0x3C),
    eye=rgb(0x2A, 0x2A, 0x32), mouth=rgb(0xA8, 0x5A, 0x4A), blush=(0xF0, 0xA8, 0x90, 190),
)
WINTER_MAP = {  # summer -> winter
    SUMMER["shirt"]: rgb(0xA8, 0x58, 0x38), SUMMER["shirt_d"]: rgb(0x7A, 0x3E, 0x28),
    SUMMER["trim"]: rgb(0xE8, 0xDC, 0xC0),
    SUMMER["pants"]: rgb(0x4A, 0x4A, 0x55),
    SUMMER["hat"]: rgb(0x6A, 0x4A, 0x5A), SUMMER["hat_d"]: rgb(0x52, 0x38, 0x46),
    SUMMER["band"]: rgb(0xE8, 0xDC, 0xC0),
}
YUKATA_MAP = {
    SUMMER["shirt"]: rgb(0x3A, 0x44, 0x68), SUMMER["shirt_d"]: rgb(0x2E, 0x36, 0x54),
    SUMMER["trim"]: rgb(0xD9, 0x4A, 0x4A),  # obi + collar -> festival red
    SUMMER["pants"]: rgb(0x3A, 0x44, 0x68),
    SUMMER["boots"]: rgb(0x8B, 0x6B, 0x4A),  # geta
    SUMMER["band"]: rgb(0xD9, 0x4A, 0x4A),
}


# ------------------------------------------------------------- pieces
def shadow(img):
    ellipse(img, CX, 30, 5, 1.6, (26, 26, 46, 90))


def legs(img, pal, phase, bob=0, sit=False, bend=0, side=False):
    """phase 0..3 walk cycle; sit = dangling legs; bend shortens legs.
    side=True strides along x for left/right views."""
    p, b = pal["pants"], pal["boots"]
    if sit:
        rect(img, CX - 4, 22 + bob, CX + 4, 24 + bob, p)  # seat
        for dx in (-3, 2):  # dangling legs
            rect(img, CX + dx, 25 + bob, CX + dx + 1, 29, p)
            rect(img, CX + dx, 30, CX + dx + 1, 30, b)
        return
    top = 24 + bob + bend
    if side:
        if phase == 0:      # A fwd (down), B back (lifted)
            rect(img, CX - 5, top, CX - 3, 28, p); rect(img, CX - 5, 29, CX - 3, 30, b)
            rect(img, CX + 2, top, CX + 4, 27, p); rect(img, CX + 2, 28, CX + 4, 29, b)
        elif phase == 2:    # B fwd, A back
            rect(img, CX + 2, top, CX + 4, 28, p); rect(img, CX + 2, 29, CX + 4, 30, b)
            rect(img, CX - 5, top, CX - 3, 27, p); rect(img, CX - 5, 28, CX - 3, 29, b)
        else:               # passing
            rect(img, CX - 2, top, CX + 1, 28, p); rect(img, CX - 2, 29, CX + 1, 30, b)
        if bend:
            rect(img, CX - 3, 24 + bob, CX + 3, top, p)
        return
    if phase == 0:  # left fwd, right back
        rect(img, CX - 3, top, CX - 1, 28, p); rect(img, CX - 3, 29, CX - 1, 30, b)
        rect(img, CX + 1, top, CX + 3, 28, p); rect(img, CX + 1, 29 + 1, CX + 3, 30, b)
    elif phase == 2:  # right fwd, left back
        rect(img, CX + 1, top, CX + 3, 28, p); rect(img, CX + 1, 29, CX + 3, 30, b)
        rect(img, CX - 3, top, CX - 1, 28, p); rect(img, CX - 3, 29, CX - 1, 30 + 1, b)
        rect(img, CX - 3, 30, CX - 1, 30, b)
    else:  # neutral
        rect(img, CX - 3, top, CX - 1, 28, p); rect(img, CX - 3, 29, CX - 1, 30, b)
        rect(img, CX + 1, top, CX + 3, 28, p); rect(img, CX + 1, 29, CX + 3, 30, b)
    if bend:  # compress: cover gap left by lowered torso
        rect(img, CX - 3, 24 + bob, CX + 3, top, p)


def torso(img, pal, y0, xw=4, apron=None):
    rect(img, CX - xw, y0, CX + xw, y0 + 7, pal["shirt"])
    rect(img, CX - xw, y0 + 7, CX + xw, y0 + 7, pal["trim"])  # belt / obi line
    px(img, CX - xw, y0, pal["shirt_d"]); px(img, CX + xw, y0, pal["shirt_d"])
    if apron:
        rect(img, CX - 3, y0 + 2, CX + 3, y0 + 7, apron)
        px(img, CX - 2, y0 + 1, apron); px(img, CX + 2, y0 + 1, apron)


def arms(img, pal, pose, y0, bob=0):
    s, skin = pal["shirt"], pal["skin"]
    sd = pal["shirt_d"]
    def hand(x, y):
        px(img, x, y, skin); px(img, x + 1, y, skin)
    if pose == "down":
        for x in (CX - 5, CX + 4):
            rect(img, x, y0, x + 1, y0 + 6, s)
        hand(CX - 5, y0 + 7); hand(CX + 4, y0 + 7)
    elif pose == "swing_a":
        rect(img, CX - 5, y0 + 1, CX - 4, y0 + 7, s); hand(CX - 5, y0 + 8)
        rect(img, CX + 4, y0, CX + 5, y0 + 5, s); hand(CX + 4, y0 + 6)
    elif pose == "swing_b":
        rect(img, CX - 5, y0, CX - 4, y0 + 5, s); hand(CX - 5, y0 + 6)
        rect(img, CX + 4, y0 + 1, CX + 5, y0 + 7, s); hand(CX + 4, y0 + 8)
    elif pose == "up":  # raised (swing anticipation)
        for x in (CX - 6, CX + 4):
            rect(img, x, y0 - 4, x + 1, y0 + 2, s)
        hand(CX - 6, y0 - 5); hand(CX + 4, y0 - 5)
    elif pose == "forward":  # both hands front (plant / bow)
        rect(img, CX - 4, y0 + 2, CX - 3, y0 + 8, s); rect(img, CX + 2, y0 + 2, CX + 3, y0 + 8, s)
        hand(CX - 4, y0 + 9); hand(CX + 2, y0 + 9)
    elif pose == "hold_r":  # two-hand hold to the right (rod / net)
        rect(img, CX + 2, y0 + 1, CX + 6, y0 + 3, s)
        hand(CX + 6, y0 + 4); px(img, CX + 5, y0 + 4, skin)
        rect(img, CX - 5, y0, CX - 4, y0 + 6, sd); hand(CX - 5, y0 + 7)
    elif pose == "hold_both":  # centered grip (hoe mid-swing)
        rect(img, CX - 5, y0 + 1, CX - 4, y0 + 6, s)
        rect(img, CX + 3, y0 + 1, CX + 4, y0 + 6, s)
        hand(CX - 5, y0 + 7); hand(CX + 3, y0 + 7)


def head(img, pal, direction, cy=9, blink=False, hat=True, bun=False, tilt=0):
    skin, skin_d, hair = pal["skin"], pal["skin_d"], pal["hair"]
    ellipse(img, CX + tilt, cy, 5, 5, skin)
    px(img, CX - 5 + tilt, cy + 1, skin_d); px(img, CX + 5 + tilt, cy + 1, skin_d)  # ears
    if not hat:
        ellipse(img, CX + tilt, cy - 2, 5, 3.5, hair)  # hair cap over crown
    if direction == "down":
        _face_front(img, pal, tilt, cy, blink)
        px(img, CX - 5 + tilt, cy + 3, hair); px(img, CX + 5 + tilt, cy + 3, hair)
        if not hat:
            rect(img, CX - 4 + tilt, cy - 4, CX + 4 + tilt, cy - 3, hair)  # fringe
    elif direction == "up":
        rect(img, CX - 4 + tilt, cy + 1, CX + 4 + tilt, cy + 5, hair)  # back of hair
        px(img, CX - 5 + tilt, cy + 3, hair); px(img, CX + 5 + tilt, cy + 3, hair)
    else:  # left (right = flipped later)
        _face_side(img, pal, tilt, cy, blink)
        rect(img, CX + 2 + tilt, cy - 1, CX + 5 + tilt, cy + 4, hair)  # back hair
    if bun:  # Chiyo's grey o-dango
        ellipse(img, CX + 4 + tilt, cy - 5, 2, 2, hair)
        px(img, CX + 4 + tilt, cy - 6, pal["trim"])
    if hat:
        _kasa(img, pal, direction, cy, tilt)


def _face_front(img, pal, tilt, cy, blink):
    eye, mouth, blush = pal["eye"], pal["mouth"], pal["blush"]
    for ex in (CX - 3, CX + 2):
        if blink:
            rect(img, ex + tilt, cy + 1, ex + 1 + tilt, cy + 1, eye)
        else:
            rect(img, ex + tilt, cy, ex + 1 + tilt, cy + 2, eye)
            px(img, ex + tilt, cy, rgb(0xF8, 0xF8, 0xF0))  # catchlight
    px(img, CX - 4 + tilt, cy + 3, blush); px(img, CX + 4 + tilt, cy + 3, blush)
    px(img, CX + tilt, cy + 4, mouth); px(img, CX + 1 + tilt, cy + 4, mouth)


def _face_side(img, pal, tilt, cy, blink):
    eye, mouth, blush = pal["eye"], pal["mouth"], pal["blush"]
    ex = CX - 4
    if blink:
        rect(img, ex + tilt, cy + 1, ex + 1 + tilt, cy + 1, eye)
    else:
        rect(img, ex + tilt, cy, ex + 1 + tilt, cy + 2, eye)
        px(img, ex + tilt, cy, rgb(0xF8, 0xF8, 0xF0))
    px(img, CX - 5 + tilt, cy + 2, pal["skin_d"])  # nose
    px(img, CX - 3 + tilt, cy + 4, mouth)
    px(img, CX - 2 + tilt, cy + 3, blush)


def _kasa(img, pal, direction, cy, tilt):
    hat, hat_d, band = pal["hat"], pal["hat_d"], pal["band"]
    top = cy - 7 + tilt * 0  # hat follows head tilt only on x
    t = tilt
    rows = [(2, 2), (3, 4), (4, 5), (5, 6)]  # (dy above cy, half-width)
    for dy, hw in rows:
        y = cy - dy - 2
        rect(img, CX - hw + t, y, CX + hw + t, y, hat)
    brim_y = cy - 3
    if direction == "left":
        rect(img, CX - 7 + t, brim_y, CX + 5 + t, brim_y, hat)
        rect(img, CX - 7 + t, brim_y + 1, CX + 5 + t, brim_y + 1, hat_d)
    else:
        rect(img, CX - 6 + t, brim_y, CX + 6 + t, brim_y, hat)
        rect(img, CX - 6 + t, brim_y + 1, CX + 6 + t, brim_y + 1, hat_d)
    px(img, CX + t, cy - 9, hat_d)  # top knob
    rect(img, CX - 2 + t, cy - 5, CX + 2 + t, cy - 5, band)  # band


# ------------------------------------------------------------- tools
def tool_kuwa_px(img, frame, direction):
    """Hoe overlay per swing frame (down/up; side drawn by caller flip)."""
    wood, steel = rgb(0xC9, 0xB8, 0x96), rgb(0xB8, 0xB8, 0xC8)
    if frame == 0:      # anticipation: raised back-right
        pts = [(17, 12), (18, 11), (19, 10), (20, 9)]
        bl = [(20, 6), (21, 6), (20, 7), (21, 7), (22, 7)]
    elif frame == 1:    # high overhead
        pts = [(16, 8), (17, 7), (18, 6), (19, 5)]
        bl = [(19, 2), (20, 2), (19, 3), (20, 3), (21, 3)]
    elif frame == 2:    # impact: head in the soil in front
        pts = [(16, 20), (17, 22), (18, 24), (19, 26)]
        bl = [(18, 28), (19, 28), (20, 28), (19, 29), (20, 29)]
    else:               # recover
        pts = [(17, 16), (18, 17), (19, 18), (20, 19)]
        bl = [(20, 15), (21, 15), (21, 16), (22, 16), (20, 16)]
    for x, y in pts:
        px(img, x, y, wood)
    for x, y in bl:
        px(img, x, y, steel)


def tool_net_px(img, frame, direction):
    wood, hoop = rgb(0xC9, 0xB8, 0x96), rgb(0xA8, 0x98, 0x68)
    gauze = (248, 248, 240, 150)
    if frame == 0:
        pts = [(17, 20), (18, 18), (19, 16)]; c = (20, 13)
    elif frame == 1:
        pts = [(17, 16), (18, 13), (19, 10)]; c = (20, 7)
    elif frame == 2:    # full overhead sweep
        pts = [(14, 12), (12, 9), (10, 7)]; c = (8, 5)
    else:
        pts = [(17, 18), (18, 16), (19, 14)]; c = (20, 11)
    for x, y in pts:
        px(img, x, y, wood)
    ellipse(img, c[0], c[1], 3, 3, hoop)
    ellipse(img, c[0], c[1], 2, 2, gauze)


def tool_rod_px(img, frame, direction):
    wood, tip, line = rgb(0xC9, 0xB8, 0x96), rgb(0xA8, 0x98, 0x68), rgb(0xDC, 0xDC, 0xE6)
    if frame == 0:      # idle, tip down
        pts = [(17, 20), (18, 19), (19, 18), (20, 17), (21, 16)]
    elif frame == 1:    # cast back
        pts = [(15, 16), (13, 13), (11, 10), (9, 8)]
    elif frame == 2:    # line out
        pts = [(17, 19), (18, 17), (19, 15), (20, 13), (21, 11)]
        for y in range(12, 21):
            px(img, 23, y, line)
        px(img, 23, 21, rgb(0xD9, 0x4A, 0x4A)); px(img, 23, 22, rgb(0xF8, 0xF8, 0xF0))
    else:               # reel: rod bent
        pts = [(17, 19), (18, 16), (19, 14), (20, 13)]
        for y in range(14, 22):
            px(img, 21, y, line)
        px(img, 21, 22, rgb(0xD9, 0x4A, 0x4A))
    for i, (x, y) in enumerate(pts):
        px(img, x, y, tip if i > len(pts) - 3 else wood)


def seedling_px(img, frame):
    if frame in (1, 2):  # seedling in hands while bent
        g = rgb(0x7B, 0xC4, 0x5A)
        px(img, CX - 3, 28, g); px(img, CX - 4, 27, g); px(img, CX - 2, 27, g)


# ------------------------------------------------------------- frames
def draw_frame(direction, action, frame, pal, hat=True, bun=False, apron=None, broom=False):
    img = canvas(W, H)
    shadow(img)
    bob = 0
    blink = False
    pose = "down"
    bend = 0
    sit = action == "sit"
    phase = 0
    tilt = 0
    if action == "idle":
        blink = frame == 3
        bob = -1 if frame in (1, 2) else 0
        pose = "down"
    elif action == "walk":
        phase = frame
        bob = -1 if frame in (1, 3) else 0
        pose = "swing_a" if frame == 0 else "swing_b" if frame == 2 else "down"
    elif action == "sit":
        tilt = (-1 if frame == 1 else 1 if frame == 3 else 0)
    elif action == "hoe":
        bend = (0, 0, 2, 1)[frame]
        pose = ("up", "up", "hold_both", "hold_both")[frame]
        bob = (0, -1, 1, 0)[frame]
    elif action == "plant":
        bend = (1, 3, 3, 1)[frame]
        pose = "forward"
        bob = (0, 1, 1, 0)[frame]
    elif action == "net":
        pose = ("hold_r", "up", "up", "hold_r")[frame]
        bob = (0, -1, -1, 0)[frame]
    elif action == "fish":
        pose = "hold_r"
        bob = (0, -1, 0, 0)[frame]
    elif action == "bow":
        bend = (0, 1, 3, 1)[frame]
        pose = "forward" if frame == 2 else "down"
    torso_y = 17 + bob + bend
    if sit:
        legs(img, pal, 0, sit=True)
        torso(img, pal, 15 + bob, apron=apron)
        arms(img, pal, "down", 16 + bob)
        head(img, pal, direction, cy=8 + bob, blink=blink, hat=hat, bun=bun, tilt=tilt)
    else:
        legs(img, pal, phase, bob=bob, bend=bend,
             side=(direction in ("left", "right") and action == "walk"))
        torso(img, pal, torso_y, apron=apron)
        arms(img, pal, pose, torso_y)
        head(img, pal, direction, cy=9 + bob + bend, blink=blink, hat=hat, bun=bun, tilt=tilt)
    if action == "hoe":
        tool_kuwa_px(img, frame, direction)
    elif action == "net":
        tool_net_px(img, frame, direction)
    elif action == "fish":
        tool_rod_px(img, frame, direction)
    elif action == "plant":
        seedling_px(img, frame)
    if broom and action == "idle":
        _broom_px(img)
    return img


def _broom_px(img):
    wood, bri = rgb(0xC9, 0xB8, 0x96), rgb(0xA8, 0x98, 0x68)
    for i in range(7):
        px(img, CX + 7, 17 + i, wood)
    px(img, CX + 7, 24, bri); px(img, CX + 6, 25, bri); px(img, CX + 8, 25, bri)
    px(img, CX + 6, 26, bri); px(img, CX + 7, 26, bri); px(img, CX + 8, 26, bri)
    px(img, CX + 5, 27, bri); px(img, CX + 6, 27, bri); px(img, CX + 7, 27, bri); px(img, CX + 8, 27, bri); px(img, CX + 9, 27, bri)


ACTIONS = ["idle", "walk", "sit", "hoe", "plant", "net", "fish", "bow"]
DIRS = ["down", "up", "left", "right"]


def build_sheet(pal, rows, hat=True, bun=False, apron=None, broom=False):
    sheet = canvas(W * 16, H * len(rows))
    for r, action in enumerate(rows):
        for d, direction in enumerate(DIRS):
            for f in range(4):
                img = draw_frame(direction, action, f, pal, hat=hat, bun=bun, apron=apron, broom=broom)
                if direction == "right":
                    left_img = draw_frame("left", action, f, pal, hat=hat, bun=bun, apron=apron, broom=broom)
                    img = flip_h(left_img)
                for y in range(H):
                    for x in range(W):
                        c = img.getpixel((x, y))
                        if c[3]:
                            sheet.putpixel(((d * 4 + f) * W + x, r * H + y), c)
    return sheet


def recolor(sheet, mapping, dots=False):
    img = sheet.copy()
    p = img.load()
    for y in range(img.height):
        for x in range(img.width):
            c = p[x, y]
            if c[3] == 0:
                continue
            key = (c[0], c[1], c[2], 255)
            if key in mapping:
                p[x, y] = mapping[key]
    if dots:  # asanoha-ish white speckle on yukata cloth
        cloth = (YUKATA_MAP[SUMMER["shirt"]][:3], YUKATA_MAP[SUMMER["pants"]][:3])
        for y in range(img.height):
            for x in range(img.width):
                c = p[x, y]
                if c[3] and c[:3] in cloth and (x + 2 * y) % 7 == 0:
                    p[x, y] = rgb(0xF8, 0xF8, 0xF0)
    return img


# ------------------------------------------------------------- portraits
def draw_chiyo_portrait(expr):
    """32x32 bust master; expressions via eyes/brows/mouth."""
    img = canvas(32, 32)
    skin, skin_d = rgb(0xF2, 0xC8, 0x94), rgb(0xD9, 0xA0, 0x6B)
    hair, hair_d = rgb(0xC8, 0xC0, 0xC0), rgb(0x8A, 0x80, 0x90)
    kim, apron = rgb(0x7A, 0x6A, 0x8A), rgb(0xF0, 0xEB, 0xDD)
    eye, mouth, blush = rgb(0x2A, 0x2A, 0x32), rgb(0xA8, 0x5A, 0x4A), (0xF0, 0xA8, 0x90, 190)
    # shoulders / kimono + kappogi apron
    ellipse(img, 16, 34, 13, 9, kim)
    rect(img, 11, 26, 20, 31, apron)
    px(img, 12, 25, apron); px(img, 19, 25, apron)
    rect(img, 13, 24, 18, 25, rgb(0xE0, 0xD8, 0xC8))
    # head
    ellipse(img, 16, 14, 9, 10, skin)
    px(img, 7, 15, skin_d); px(img, 25, 15, skin_d)  # ears
    # grey hair: swept back + bun
    ellipse(img, 16, 8, 9, 5, hair)
    rect(img, 8, 8, 9, 14, hair); rect(img, 23, 8, 24, 14, hair)
    ellipse(img, 24, 4, 3, 3, hair)
    px(img, 24, 3, hair_d); px(img, 10, 9, hair_d)
    px(img, 16, 6, hair_d)  # part line
    # wrinkles (kind)
    px(img, 10, 19, skin_d); px(img, 22, 19, skin_d)
    cx = 16
    if expr == "gentle_smile":
        for ex in (11, 19):
            px(img, ex, 14, eye); px(img, ex + 1, 13, eye); px(img, ex + 2, 14, eye)  # soft arc
        _smile(img, cx, 21, mouth)
        px(img, 9, 18, blush); px(img, 22, 18, blush)
    elif expr == "chuckling":
        for ex in (11, 19):  # ^ ^ closed happy eyes
            px(img, ex, 14, eye); px(img, ex + 1, 13, eye); px(img, ex + 2, 14, eye)
        ellipse(img, cx, 21, 2, 2, mouth)  # open laugh
        px(img, cx, 22, rgb(0xE8, 0x8A, 0x7A))
        px(img, 9, 18, blush); px(img, 22, 18, blush)
        px(img, 8, 17, blush); px(img, 23, 17, blush)
    elif expr == "nostalgic":
        for ex in (11, 19):  # gentle distant gaze, looking up-left
            px(img, ex, 13, eye); px(img, ex + 1, 13, eye)
            px(img, ex, 14, eye)
            px(img, ex, 13, rgb(0xF8, 0xF8, 0xF0))  # catchlight
        px(img, 10, 10, skin_d); px(img, 11, 10, skin_d)  # soft high brows
        px(img, 20, 10, skin_d); px(img, 21, 10, skin_d)
        px(img, cx - 1, 21, mouth); px(img, cx, 21, mouth)  # small faraway smile
        px(img, 9, 18, blush)
    elif expr == "surprised":
        for ex in (11, 19):
            rect(img, ex, 12, ex + 2, 15, rgb(0xF8, 0xF8, 0xF0))
            rect(img, ex, 13, ex + 1, 14, eye)
        px(img, 10, 10, skin_d); px(img, 21, 10, skin_d)  # brows way up
        ellipse(img, cx, 21, 1.6, 2, mouth)  # small o
    elif expr == "concerned":
        for ex in (11, 19):
            rect(img, ex, 14, ex + 2, 15, eye)
            px(img, ex + 1, 14, rgb(0xF8, 0xF8, 0xF0))
        px(img, 10, 12, skin_d); px(img, 11, 13, skin_d)  # brows angled in/down
        px(img, 21, 12, skin_d); px(img, 20, 13, skin_d)
        px(img, cx - 1, 22, mouth); px(img, cx, 21, mouth); px(img, cx + 1, 22, mouth)  # small frown
        px(img, 26, 12, rgb(0x7A, 0xB8, 0xE0)); px(img, 26, 13, rgb(0x7A, 0xB8, 0xE0))  # sweat drop
    return img


def _smile(img, cx, y, c):
    px(img, cx - 2, y - 1, c); px(img, cx - 1, y, c); px(img, cx, y, c)
    px(img, cx + 1, y, c); px(img, cx + 2, y - 1, c)


# ---------------------------------------------------------------- main
def main():
    # --- player sheets
    sheet = build_sheet(SUMMER, ACTIONS)
    save_with_import(sheet, "characters", "player_jp.png")
    save_with_import(recolor(sheet, WINTER_MAP), "characters", "player_jp_winter.png")
    save_with_import(recolor(sheet, YUKATA_MAP, dots=True), "characters", "player_jp_yukata.png")

    # --- Grandma Chiyo world sprite (idle + walk rows)
    chiyo_pal = dict(
        SUMMER,
        skin=rgb(0xF2, 0xC8, 0x94), skin_d=rgb(0xD9, 0xA0, 0x6B),
        hair=rgb(0xC8, 0xC0, 0xC0),
        shirt=rgb(0x7A, 0x6A, 0x8A), shirt_d=rgb(0x5E, 0x50, 0x6E),
        trim=rgb(0xE0, 0xD8, 0xC8),
        pants=rgb(0x4A, 0x42, 0x52), boots=rgb(0x3A, 0x3A, 0x42),
    )
    chiyo = build_sheet(chiyo_pal, ["idle", "walk"], hat=False, bun=True,
                        apron=rgb(0xF0, 0xEB, 0xDD), broom=True)
    save_with_import(chiyo, "characters", "npc_chiyo.png")

    # --- portraits: 32 master -> 128 (4x nearest)
    for expr in ("gentle_smile", "chuckling", "nostalgic", "surprised", "concerned"):
        master = draw_chiyo_portrait(expr)
        save_with_import(master, "characters", f"portrait_chiyo_{expr}_32.png")
        big = master.resize((128, 128), Image.NEAREST)
        save_with_import(big, "characters", f"portrait_chiyo_{expr}.png")


if __name__ == "__main__":
    main()
