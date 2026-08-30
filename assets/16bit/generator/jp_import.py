"""Godot .import sidecar writer for generated PNGs.

Replicates the engine-written format used across assets/16bit/:
dest hash = md5("res://" + repo-relative path), uid = random uid:// token
(unique against every *.import already in the repo).
"""
import hashlib
import os
import random
import re
import string

from px import ROOT

ASSETS_ROOT = os.path.dirname(ROOT)  # assets/

TEMPLATE = """[remap]

importer="texture"
type="CompressedTexture2D"
uid="{uid}"
path="res://.godot/imported/{name}-{md5}.ctex"
metadata={{
"vram_texture": false
}}

[deps]

source_file="res://{rel}"
dest_files=["res://.godot/imported/{name}-{md5}.ctex"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
"""


def _existing_uids():
    uids = set()
    for dirpath, _, files in os.walk(ASSETS_ROOT):
        for f in files:
            if not f.endswith(".import"):
                continue
            try:
                with open(os.path.join(dirpath, f)) as fh:
                    m = re.search(r'uid="(uid://[^"]+)"', fh.read())
                    if m:
                        uids.add(m.group(1))
            except OSError:
                pass
    return uids


_USED = _existing_uids()
_RNG = random.Random(0xC0FFEE)


def _new_uid():
    alphabet = string.ascii_lowercase + string.digits
    while True:
        uid = "uid://" + "".join(_RNG.choice(alphabet) for _ in range(13))
        if uid not in _USED:
            _USED.add(uid)
            return uid


def write_import(png_abs_path):
    """Write <name>.png.import next to the PNG; returns the import path."""
    rel = os.path.relpath(png_abs_path, os.path.dirname(ASSETS_ROOT))
    rel = rel.replace(os.sep, "/")
    md5 = hashlib.md5(("res://" + rel).encode()).hexdigest()
    name = os.path.basename(png_abs_path)
    text = TEMPLATE.format(uid=_new_uid(), name=name, md5=md5, rel=rel)
    import_path = png_abs_path + ".import"
    with open(import_path, "w") as fh:
        fh.write(text)
    return import_path


def save_with_import(img, *parts):
    """px.save + .import sidecar in one call."""
    from px import save
    path = save(img, *parts)
    write_import(path)
    return path
