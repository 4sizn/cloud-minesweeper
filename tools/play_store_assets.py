"""Build the Google Play listing images from the App Store assets.

    python3 tools/play_store_assets.py path/to/NotoSansKR[wght].ttf

Noto Sans KR (OFL) is the font the App Store screenshots use; download it from
github.com/google/fonts/tree/main/ofl/notosanskr. Writes into playstore/.
"""

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

root = Path(__file__).resolve().parent.parent
out = root / "playstore"
font_path = sys.argv[1]

(out / "phone-ko").mkdir(parents=True, exist_ok=True)


def font(size, weight):
    f = ImageFont.truetype(font_path, size)
    f.set_variation_by_axes([weight])
    return f


# 512x512 icon, opaque, Play applies its own mask.
icon = Image.open(root / "assets/branding/app-icon.png").convert("RGB")
icon.resize((512, 512), Image.LANCZOS).save(out / "icon-512.png")

# Play caps phone screenshots at 2:1 and the App Store frames show an iPhone,
# so lay the raw captures out again: caption on top, the screen below it.
deck = json.loads((root / "tools/store-screenshots/app-store-screenshots.json").read_text())
ink, muted, accent = (24, 61, 98), (62, 94, 124), (40, 132, 196)
W, H = 1200, 2400
for n, slide in enumerate(deck["slidesByDevice"]["iphone"], 1):
    canvas = Image.new("RGB", (W, H))
    top, bottom = (154, 207, 237), (222, 238, 248)
    for y in range(H):
        t = y / (H - 1)
        ImageDraw.Draw(canvas).line([(0, y), (W, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(top, bottom)))
    draw = ImageDraw.Draw(canvas)
    draw.text((W // 2, 190), slide["label"]["ko"], font=font(46, 700), fill=accent, anchor="mm")
    draw.multiline_text((W // 2, 360), slide["headline"]["ko"], font=font(96, 900), fill=ink,
                        anchor="mm", align="center", spacing=18)
    screen = Image.open(root / "tools/store-screenshots/public" / slide["screenshot"].lstrip("/").replace("{locale}", "ko")).convert("RGB")
    sw = 900
    screen = screen.resize((sw, round(screen.height * sw / screen.width)), Image.LANCZOS)
    x, y = (W - sw) // 2, 560
    shade = Image.new("L", (W, H), 0)
    ImageDraw.Draw(shade).rounded_rectangle((x, y + 24, x + sw, y + screen.height + 24), radius=72, fill=90)
    canvas.paste((24, 61, 98), (0, 0), shade.filter(ImageFilter.GaussianBlur(30)))
    corners = Image.new("L", screen.size, 0)
    ImageDraw.Draw(corners).rounded_rectangle((0, 0, sw - 1, screen.height - 1), radius=72, fill=255)
    canvas.paste(screen, (x, y), corners)
    canvas.save(out / "phone-ko" / f"{n:02d}.png")

# 1024x500 feature graphic: the app's sky, the icon, and the store name.
sky = Image.open(root / "assets/sky.png").convert("RGB")
sw, sh = sky.size
crop_h = round(sw * 500 / 1024)
top = (sh - crop_h) // 2
graphic = sky.crop((0, top, sw, top + crop_h)).resize((1024, 500), Image.LANCZOS)

mask = Image.new("L", (240, 240), 0)
ImageDraw.Draw(mask).rounded_rectangle((0, 0, 239, 239), radius=54, fill=255)
shadow = Image.new("RGBA", (300, 300), (0, 0, 0, 0))
ImageDraw.Draw(shadow).rounded_rectangle((30, 38, 269, 277), radius=54, fill=(24, 61, 98, 70))
graphic.paste(shadow.filter(ImageFilter.GaussianBlur(14)), (70, 100), shadow.filter(ImageFilter.GaussianBlur(14)))
graphic.paste(icon.resize((240, 240), Image.LANCZOS), (100, 130), mask)


draw = ImageDraw.Draw(graphic)
draw.text((392, 158), "지뢰찾기:구름", font=font(76, 800), fill=ink)
draw.text((396, 268), "오늘 하늘을 오래 간직하는 법", font=font(34, 500), fill=muted)
graphic.save(out / "feature-graphic.png")
