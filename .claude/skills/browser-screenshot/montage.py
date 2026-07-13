"""Compose labeled canvas thumbnails into contact sheets for fast skimming.

  python montage.py <shots_dir> <out_prefix> [cols] [per_sheet]

Reads every <shots_dir>/<label>.png, draws the label on each, and tiles them into
one or more <out_prefix>_N.png contact sheets.
"""
import sys, os, glob
from PIL import Image, ImageDraw

shots_dir = sys.argv[1]
out_prefix = sys.argv[2]
cols = int(sys.argv[3]) if len(sys.argv) > 3 else 6
per_sheet = int(sys.argv[4]) if len(sys.argv) > 4 else 24

paths = sorted(glob.glob(os.path.join(shots_dir, "*.png")))
paths = [p for p in paths if "_sheet" not in os.path.basename(p)]
CELL = 320  # thumb cell size
PAD = 6
BAR = 18


def make_thumb(p):
    im = Image.open(p).convert("RGB")
    im.thumbnail((CELL, CELL - BAR))
    cell = Image.new("RGB", (CELL, CELL), (18, 22, 30))
    x = (CELL - im.width) // 2
    y = BAR + (CELL - BAR - im.height) // 2
    cell.paste(im, (x, y))
    d = ImageDraw.Draw(cell)
    d.text((4, 3), os.path.splitext(os.path.basename(p))[0], fill=(180, 220, 255))
    return cell


sheets = 0
for start in range(0, len(paths), per_sheet):
    chunk = paths[start:start + per_sheet]
    rows = (len(chunk) + cols - 1) // cols
    W = cols * (CELL + PAD) + PAD
    H = rows * (CELL + PAD) + PAD
    sheet = Image.new("RGB", (W, H), (10, 12, 16))
    for i, p in enumerate(chunk):
        r, c = divmod(i, cols)
        sheet.paste(make_thumb(p), (PAD + c * (CELL + PAD), PAD + r * (CELL + PAD)))
    out = f"{out_prefix}_{sheets+1}.png"
    sheet.save(out)
    print("wrote", out, f"({len(chunk)} thumbs)")
    sheets += 1
