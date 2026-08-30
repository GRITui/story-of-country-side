"""Render illustrated 'game manual' scene cards from the pixel-art asset set.

Each card is 1280x720. Run:
    python3 marketing/presenter/make_frames.py
Outputs PNGs into marketing/presenter/frames/.
"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(os.path.dirname(
    os.path.dirname(os.path.abspath(__file__)))), 'assets', 'pixelart')
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'frames')

W, H = 1280, 720

CREAM = (244, 236, 214)
GREEN = (214, 232, 176)
INK = (46, 58, 34)
WOOD = (172, 122, 88)
BORDER = (120, 88, 50)
TOMATO = (214, 104, 66)
MUTED = (150, 130, 90)


def font(sz, bold=True):
    name = 'Arial Rounded Bold.ttf' if bold else 'Arial.ttf'
    for d in ('/System/Library/Fonts/Supplemental/', '/System/Library/Fonts/'):
        p = os.path.join(d, name)
        if os.path.exists(p):
            return ImageFont.truetype(p, sz)
    return ImageFont.load_default()


def load(parts):
    return Image.open(os.path.join(ROOT, *parts)).convert('RGBA')


def sq(path, dest, scale):
    """Load a sprite, crop to its opaque bbox, resize to fit dest*scale."""
    im = load(path)
    bbox = im.getbbox() or (0, 0, im.width, im.height)
    im = im.crop(bbox)
    im = im.resize((dest * scale, dest * scale), Image.NEAREST)
    return im


def canvas():
    img = Image.new('RGBA', (W, H), (244, 240, 224, 255))
    d = ImageDraw.Draw(img)
    for y in range(H):
        t = y / H
        r = int(CREAM[0] + (GREEN[0] - CREAM[0]) * t)
        g = int(CREAM[1] + (GREEN[1] - CREAM[1]) * t)
        b = int(CREAM[2] + (GREEN[2] - CREAM[2]) * t)
        d.line([(0, y), (W, y)], fill=(r, g, b))
    im = img
    return im, d


def card(d, x0, y0, x1, y1):
    d.rounded_rectangle([x0, y0, x1, y1], radius=16, fill=(255, 250, 244),
                        outline=BORDER, width=4)


def draw_pill(d, x, y, text):
    f = font(26)
    bbox = d.textbbox((0, 0), text, font=f)
    tw = bbox[2] - bbox[0]
    d.rounded_rectangle([x, y, x + tw + 26, y + 46], radius=22, fill=TOMATO)
    d.text((x + 13, y + 23), text, font=f, fill=(255, 255, 255), anchor='lm')


def header(d, step, title):
    d.text((36, 24), 'STORY OF THE COUNTRYSIDE  •  PLAYER MANUAL',
           font=font(26), fill=MUTED)
    x0 = 40
    if step:
        draw_pill(d, 36, 46, step)
        x0 = 36 + draw_pill_w(d, step) + 12
    d.text((x0, 70), title, font=font(52), fill=INK)


def draw_pill_w(d, text):
    f = font(26)
    bbox = d.textbbox((0, 0), text, font=f)
    tw = bbox[2] - bbox[0]
    return tw + 26


def footer(d):
    d.line([(40, H - 92), (W - 40, H - 92)], fill=WOOD, width=2)
    d.text((W - 40, H - 46), 'make your own story', font=font(20, bold=False),
           fill=MUTED, anchor='ra')


def paste(img, other, x, y, anchor='cc'):
    w, h = other.size
    if anchor == 'cc':
        x -= w // 2; y -= h // 2
    elif anchor == 'bc':
        x -= w // 2; y -= h
    img.alpha_composite(other, (int(x), int(y)))


def ground_strip():
    g = load(['tiles', 'grass.png'])
    row = Image.new('RGBA', (W, 64), (0, 0, 0, 0))
    x = 0
    while x < W:
        row.alpha_composite(g, (x, 0))
        x += 64
    return row


def write_scene(name, img):
    os.makedirs(OUT, exist_ok=True)
    img.convert('RGB').save(os.path.join(OUT, f'{name}.png'))
    print('wrote', name)


def show_grid(img, d, items, cx, cy, cols, box, labels=()):
    """Place a row/grid of (dest_px, scale, image) centered near (cx, cy)."""
    n = len(items)
    total = n * box + (n - 1) * 24
    x = cx - total // 2
    for i, (px, sc, im) in enumerate(items):
        im2 = im.resize((px * sc, px * sc), Image.NEAREST)
        paste(img, im2, x + box // 2, cy, 'cc')
        if labels and i < len(labels):
            d = ImageDraw.Draw(img)
            d.text((x + box // 2, cy + box // 2 + 18), labels[i],
                   font=font(18, bold=False), fill=INK, anchor='ma')
# ---------------------------------------------------------------- scenes

def make_title():
    img, d = canvas()
    card(d, 90, 60, W - 90, H - 60)
    d.text((W / 2, 130), 'STORY OF THE', font=font(84), fill=(90, 66, 40),
           anchor='mm')
    d.text((W / 2, 210), 'COUNTRYSIDE', font=font(120), fill=INK, anchor='mm')
    d.text((W / 2, 276), 'a cozy little player manual  •  ~4 min',
           font=font(28, bold=False), fill=INK, anchor='mm')
    house = sq(['props', 'farmhouse.png'], 96, 3)
    tree = sq(['props', 'tree.png'], 88, 3)
    crop = sq(['crops', 'pumpkin.png'], 110, 3)
    player = load(['characters', 'player.png']).crop((0, 0, 48, 40)) \
        .resize((132, 110), Image.NEAREST)
    paste(img, crop, W / 2 - 150, 520, 'bc')
    paste(img, house, W / 2, 560, 'bc')
    paste(img, tree, W / 2 + 170, 500, 'bc')
    paste(img, player, W / 2 + 40, 300, 'cc')
    img.alpha_composite(ground_strip(), (0, H - 64))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([W / 2 - 170, 560, W / 2 + 170, 650], radius=26,
                        fill=TOMATO)
    d.text((W / 2, 605), 'START READING', font=font(30), fill=(255, 255, 255),
           anchor='mm')
    footer(d)
    write_scene('step_00_title', img)


def toc():
    img, d = canvas()
    card(d, 90, 80, W - 90, H - 90)
    header(d, '01', 'What you will learn')
    rows = [
        ('Sun & time', 'a day in the valley'),
        ('Farming', 'till, plant, water, harvest, sell'),
        ('Animals', 'feed them, gather the goods'),
        ('The wilds', 'fishing, mining, foraging'),
        ('Friends & town', 'gifts, festivals, goals'),
    ]
    y = 205
    for title, sub in rows:
        d.rounded_rectangle([180, y, W - 180, y + 58], radius=12,
                            fill=(250, 245, 234), outline=WOOD, width=2)
        d.text((204, y + 16), title, font=font(24), fill=INK)
        d.text((W - 204, y + 16), sub, font=font(20, bold=False), fill=MUTED,
               anchor='ra')
        y += 70
    d.text((W / 2, 600), 'each section is a short, friendly step',
           font=font(22, bold=False), fill=INK, anchor='mm')
    footer(d)
    write_scene('step_01_toc', img)


def _moon():
    m = Image.new('RGBA', (16, 16), (0, 0, 0, 0))
    md = ImageDraw.Draw(m)
    md.ellipse([2, 2, 14, 14], fill=(240, 236, 180))
    md.ellipse([5, 2, 11, 10], fill=(180, 196, 210))
    return m


def day():
    img, d = canvas()
    card(d, 90, 80, W - 90, H - 90)
    header(d, '02', 'A day in the valley')
    steps = [
        ('sun', 'UP', 'wake to daylight'),
        ('clock', 'DO', 'work, fish, roam'),
        ('moon', 'REST', 'sleep to save'),
    ]
    x = W / 2 - 320
    for icon, big, sub in steps:
        d.rounded_rectangle([x, 180, x + 200, 420], radius=16,
                            fill=(250, 245, 234), outline=WOOD, width=2)
        ic = load(['ui', f'icon_{icon}.png']) if icon != 'moon' else _moon()
        paste(img, ic.resize((90, 90), Image.NEAREST), x + 100, 250)
        d.text((x + 100, 370), big, font=font(34), fill=INK, anchor='mm')
        d.text((x + 100, 405), sub, font=font(20, bold=False), fill=MUTED,
               anchor='mm')
        x += 320
    d.text((W / 2, 470), 'The clock runs from morning to night — spend it your way.',
           font=font(26, bold=False), fill=INK, anchor='mm')
    footer(d)
    write_scene('step_02_day', img)


def farm():
    img, d = canvas()
    card(d, 90, 80, W - 90, H - 90)
    header(d, '03', 'Farming')
    tiles = [('dirt', '1 TILL'), ('farmland', '2 PLANT'),
             ('farmland_watered', '3 WATER'), ('crop', '4 HARVEST')]
    x = W / 2 - 350
    for name, lab in tiles:
        d.rounded_rectangle([x, 200, x + 160, 330], radius=14, fill=GREEN,
                            outline=WOOD, width=2)
        if name == 'crop':
            c = load(['crops', 'corn.png']).crop((3 * 48, 0, 4 * 48, 48))
            c = c.resize((120, 120), Image.NEAREST)
            paste(img, c, x + 80, 250)
        else:
            t = load(['tiles', f'{name}.png']).resize((150, 75), Image.NEAREST)
            paste(img, t, x + 80, 240)
        d.text((x + 80, 350), lab, font=font(22), fill=INK, anchor='mm')
        x += 180
    d.text((W / 2, 460), 'sell your harvest for gold — then do it again, better',
           font=font(26, bold=False), fill=INK, anchor='mm')
    footer(d)
    write_scene('step_03_farm', img)
def crops():
    img, d = canvas()
    card(d, 90, 80, W - 90, H - 90)
    header(d, '04', 'Crops by season')
    crops = ['parsnip', 'cauliflower', 'tomato', 'melon', 'pumpkin', 'corn',
             'frost_kale']
    names = ['parsnip', 'cauliflower', 'tomato', 'melon', 'pumpkin', 'corn',
             'frost kale']
    box = 128
    x = W / 2 - (len(crops) * box + (len(crops) - 1) * 20) // 2
    for name, cn in zip(crops, names):
        c = load(['crops', f'{name}.png'])
        c = c.crop((3 * 48, 0, 3 * 48 + 48, 48)).resize((box, box), Image.NEAREST)
        d.rounded_rectangle([x + 4, 210, x + box - 4, 210 + box - 4], radius=16,
                            fill=(250, 245, 234), outline=WOOD, width=2)
        paste(img, c, x + box // 2, 210 + box // 2 - 8, 'cc')
        d.text((x + box // 2, 210 + box + 16), cn, font=font(20, bold=False),
               fill=INK, anchor='ma')
        x += box + 20
    d.text((W / 2, 560), 'Grow what the season loves — every crop has its own.',
           font=font(24, bold=False), fill=INK, anchor='mm')
    footer(d)
    write_scene('step_04_crops', img)


def animals():
    img, d = canvas()
    card(d, 90, 80, W - 90, H - 90)
    header(d, '05', 'Animals')
    animals = ['chicken', 'duck', 'cow', 'goat', 'sheep']
    n = len(animals)
    box = 140
    x = W / 2 - (n * box + (n - 1) * 24) // 2
    for a in animals:
        an = load(['animals', f'{a}.png'])
        an = an.crop((0, 0, 64, 32)).resize((box, 150), Image.NEAREST)
        d.rounded_rectangle([x + 4, 200, x + box - 4, 380], radius=18,
                            fill=(250, 245, 234), outline=WOOD, width=2)
        paste(img, an, x + box // 2, 285, 'cc')
        d.text((x + box // 2, 400), a, font=font(22, bold=False), fill=INK,
               anchor='ma')
        x += box + 24
    d.text((W / 2, 560), 'Feed them each day, then collect eggs, milk & wool.',
           font=font(26, bold=False), fill=INK, anchor='mm')
    footer(d)
    write_scene('step_05_animals', img)


def wildlife():
    img, d = canvas()
    card(d, 90, 80, W - 90, H - 90)
    header(d, '06', 'Beyond the farm')
    zones = [
        (['ui', 'icon_fishing.png'], 'FISHING', 'cast into any water'),
        (['items', 'icon_pickaxe.png'], 'MINING', 'crack rocks for ore & gems'),
        (['items', 'icon_wild_flower.png'], 'FORAGING', 'gather the four seasons'),
    ]
    x = W / 2 - 400
    for icparts, big, sub in zones:
        d.rounded_rectangle([x, 200, x + 240, 430], radius=24,
                            fill=(250, 245, 234), outline=WOOD, width=2)
        ic = load(icparts).resize((110, 110), Image.NEAREST)
        paste(img, ic, x + 120, 260)
        d.text((x + 120, 360), big, font=font(28), fill=INK, anchor='mm')
        d.text((x + 120, 398), sub, font=font(20, bold=False), fill=MUTED,
               anchor='ma')
        x += 260
    footer(d)
    write_scene('step_06_wildlife', img)


def friends():
    img, d = canvas()
    card(d, 90, 80, W - 90, H - 90)
    header(d, '07', 'Friends in the village')
    chars = ['colton', 'elena', 'marcus', 'priya', 'sana', 'tobias']
    box = 116
    x = W / 2 - (len(chars) * box + (len(chars) - 1) * 18) // 2
    for c in chars:
        p = load(['characters', f'portrait_{c}.png'])
        p = p.resize((box, box), Image.NEAREST)
        d.rounded_rectangle([x + 4, 210, x + box - 4, 210 + box - 4],
                            radius=90, fill=(244, 238, 220), outline=WOOD, width=2)
        paste(img, p, x + box // 2, 210 + box // 2, 'cc')
        d.text((x + box // 2, 210 + box + 22), c.capitalize(),
               font=font(20, bold=False), fill=INK, anchor='ma')
        x += box + 18
    d.text((W / 2, 560), 'Give gifts they love — bonds open festivals & goals',
           font=font(26, bold=False), fill=INK, anchor='mm')
    footer(d)
    write_scene('step_07_friends', img)


def shop():
    img, d = canvas()
    card(d, 90, 80, W - 90, H - 90)
    header(d, '08', 'Shop, tools & save')
    items = ['icon_hoe', 'icon_watering_can', 'icon_axe', 'icon_pickaxe',
             'icon_gold', 'icon_wood', 'icon_stone', 'icon_mushroom']
    box = 104
    x0 = W / 2 - (4 * box + 3 * 22) // 2
    y0 = 190
    for i, it in enumerate(items):
        col = i % 4
        row = i // 4
        xi = x0 + col * (box + 22)
        yi = y0 + row * (box + 22)
        d.rounded_rectangle([xi, yi, xi + box, yi + box], radius=14,
                            fill=(250, 245, 234), outline=WOOD, width=2)
        ic = load(['items', f'{it}.png']).resize((86, 86), Image.NEAREST)
        paste(img, ic, xi + box // 2, yi + box // 2, 'cc')
    d.text((W / 2, 470), 'Upgrade tools to reach further', font=font(26,
           bold=False), fill=INK, anchor='mm')
    d.text((W / 2, 520), 'and rest each night to save your story.',
           font=font(26, bold=False), fill=INK, anchor='mm')
    footer(d)
    write_scene('step_08_shop', img)


def outro():
    img, d = canvas()
    card(d, 90, 80, W - 90, H - 90)
    d.text((W / 2, 230), 'THANK YOU FOR PLAYING', font=font(72), fill=INK,
           anchor='mm')
    heart = load(['ui', 'icon_heart.png']).resize((96, 96), Image.NEAREST)
    crop = load(['crops', 'pumpkin.png']).crop((3 * 48, 0, 4 * 48, 48)).resize(
        (96, 96), Image.NEAREST)
    paste(img, heart, W / 2 - 110, 380)
    paste(img, crop, W / 2 + 110, 380)
    d.text((W / 2, 540), 'the town is yours to shape', font=font(30,
           bold=False), fill=INK, anchor='mm')
    footer(d)
    write_scene('step_09_outro', img)


SCENES = [make_title, toc, day, farm, crops, animals, wildlife, friends,
          shop, outro]


def main():
    for f in SCENES:
        f()


if __name__ == '__main__':
    main()