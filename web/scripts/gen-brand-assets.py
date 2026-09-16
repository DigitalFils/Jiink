#!/usr/bin/env python3
"""Generate S8LL brand assets: app icons (PNG set) + Open Graph share card."""
from PIL import Image, ImageDraw, ImageFont

BG = (10, 10, 10)        # #0A0A0A
LIME = (193, 255, 61)    # #C1FF3D
WHITE = (255, 255, 255)
TXT2 = (161, 161, 170)   # secondary text
SURFACE = (28, 28, 32)   # #1C1C20
BORDER = (44, 44, 50)

BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
REG = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"

def rounded(draw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)

def icon(size: int, path: str, radius_ratio=0.22):
    """Rounded-square app icon: dark bg, lime S8LL wordmark, lime corner dot."""
    img = Image.new("RGB", (size, size), BG)
    d = ImageDraw.Draw(img)
    r = int(size * radius_ratio)
    rounded(d, [0, 0, size - 1, size - 1], r, BG, outline=(39, 39, 44), width=max(2, size // 128))
    # wordmark — use ~62% height
    fs = int(size * 0.62 / 0.72)  # DejaVu Bold cap-height approx
    font = ImageFont.truetype(BOLD, fs)
    text = "S8"
    bbox = d.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = (size - tw) / 2 - bbox[0]
    y = (size - th) / 2 - bbox[1]
    d.text((x, y), text, font=font, fill=LIME)
    # lime dot accent bottom-right of wordmark
    dot_r = max(2, size // 36)
    dx = x + tw + dot_r * 1.6
    dy = y + th - dot_r
    if dx + dot_r < size - r:  # keep inside rounded corner
        d.ellipse([dx - dot_r, dy - dot_r, dx + dot_r, dy + dot_r], fill=LIME)
    # subtle lime glow line at top
    d.rounded_rectangle([size * 0.3, size * 0.08, size * 0.7, size * 0.08 + max(2, size // 120)],
                        radius=max(1, size // 240), fill=(193, 255, 61, 200))
    img.save(path)
    print(f"icon {size} -> {path}")

def og(path="public/og-image.png"):
    """1200x630 Open Graph card."""
    W, H = 1200, 630
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)
    # subtle grid of surface tiles
    for gy in range(0, H, 130):
        for gx in range(0, W, 150):
            rounded(d, [gx + 6, gy + 6, gx + 144, gy + 124], 14, SURFACE)
    # left brand panel
    rounded(d, [48, 60, 760, 570], 28, (13, 13, 15), outline=BORDER, width=2)
    # wordmark
    f_big = ImageFont.truetype(BOLD, 128)
    d.text((88, 110), "S8LL", font=f_big, fill=LIME)
    d.ellipse([470, 218, 492, 240], fill=LIME)  # dot after wordmark
    f_sub = ImageFont.truetype(BOLD, 44)
    d.text((88, 272), "Ultimate Marketplace", font=f_sub, fill=WHITE)
    f_tag = ImageFont.truetype(REG, 26)
    d.text((88, 336), "Buy. Sell. Stream. Authenticate.", font=f_tag, fill=TXT2)
    # feature chips
    chips = ["LIVE shopping", "AR try-on", "Group buys", "AI assistant"]
    cx, cy = 88, 420
    for c in chips:
        fchip = ImageFont.truetype(BOLD, 22)
        bbox = d.textbbox((0, 0), c, font=fchip)
        cw = bbox[2] - bbox[0] + 44
        rounded(d, [cx, cy, cx + cw, cy + 52], 26, (193, 255, 61, 30), outline=(193, 255, 61), width=2)
        d.text((cx + 22, cy + 14), c, font=fchip, fill=LIME)
        cx += cw + 16
    # right side: mock product cards
    for i, (title, price) in enumerate([("Jordan 1 Retro", "£189"), ("NB 550", "£124"), ("Leica M6", "£940")]):
        y = 60 + i * 184
        rounded(d, [800, y, 1152, y + 160], 24, (16, 16, 18), outline=BORDER, width=2)
        rounded(d, [824, y + 24, 976, y + 136], 16, SURFACE)
        d.text((840, y + 66), "IMG", font=ImageFont.truetype(BOLD, 30), fill=(70, 70, 78))
        d.text((1000, y + 34), title, font=ImageFont.truetype(BOLD, 24), fill=WHITE)
        d.text((1000, y + 74), price, font=ImageFont.truetype(BOLD, 34), fill=LIME)
        # verified badge dot
        d.ellipse([1000, y + 124, 1016, y + 140], fill=LIME)
        d.text((1024, y + 118), "verified", font=ImageFont.truetype(REG, 20), fill=TXT2)
    # bottom strip
    rounded(d, [48, 596, 260, 626], 15, (193, 255, 61))
    d.text((60, 601), "s8ll.app", font=ImageFont.truetype(BOLD, 18), fill=BG)
    img.save(path)
    print(f"og card -> {path}")

if __name__ == "__main__":
    import os
    os.chdir("/home/z/my-project")
    icon(512, "public/icon-512.png")
    icon(192, "public/icon-192.png")
    icon(180, "public/apple-touch-icon.png")
    icon(32, "public/favicon-32.png")
    og()
