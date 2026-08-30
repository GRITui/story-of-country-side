import os
from PIL import Image
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
problems = []
count = 0
for dirpath, _, files in os.walk(ROOT):
    if 'generator' in dirpath:
        continue
    for f in sorted(files):
        if not f.endswith('.png'):
            continue
        count += 1
        p = os.path.join(dirpath, f)
        im = Image.open(p).convert('RGBA')
        w, h = im.size
        alpha = im.getchannel('A')
        bbox = alpha.getbbox()
        if bbox is None:
            problems.append(f'{p}: EMPTY (no opaque pixels)')
            continue
        # non-empty opaque region must span reasonable area
        ax0, ay0, ax1, ay1 = bbox
        ow, oh = ax1 - ax0, ay1 - ay0
        if ow < 4 or oh < 4:
            problems.append(f'{p}: tiny opaque bbox {ow}x{oh}')
        rel = os.path.relpath(p, ROOT)
        print(f'{rel:40s} {w:3d}x{h:<3d} opaque_bbox=({ow}x{oh})')
print('\nTOTAL PNG:', count)
if problems:
    print('\nPROBLEMS:')
    for x in problems:
        print(' -', x)
    raise SystemExit(1)
print('OK: all PNGs valid, opaque, sized')
