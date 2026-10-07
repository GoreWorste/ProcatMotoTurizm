"""Схема связей для отчёта."""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parents[1] / "screenshots_report" / "pr3" / "ui" / "00_schema_relations.png"
OUT.parent.mkdir(parents=True, exist_ok=True)

W, H = 1100, 520
img = Image.new("RGB", (W, H), (255, 255, 255))
draw = ImageDraw.Draw(img)
try:
    font = ImageFont.truetype("arial.ttf", 16)
    title = ImageFont.truetype("arial.ttf", 20)
except OSError:
    font = ImageFont.load_default()
    title = font

draw.text((20, 15), "Логическая схема связей (ПР3)", fill=(0, 0, 0), font=title)

boxes = {
    "Client": (40, 80, 220, 160),
    "RentalCard": (40, 200, 220, 280),
    "Equipment": (400, 80, 620, 200),
    "Category": (720, 60, 900, 130),
    "Brand": (720, 150, 900, 220),
    "Tag": (720, 240, 900, 310),
}

for name, (x1, y1, x2, y2) in boxes.items():
    draw.rectangle((x1, y1, x2, y2), outline=(0, 100, 180), width=2)
    draw.text((x1 + 12, y1 + 20), name, fill=(0, 0, 0), font=font)

draw.line((130, 160, 130, 200), fill=(0, 0, 0), width=2)
draw.text((145, 168), "1 : 1", fill=(0, 0, 0), font=font)

draw.line((620, 120, 720, 95), fill=(0, 0, 0), width=2)
draw.text((650, 95), "N : 1", fill=(0, 0, 0), font=font)
draw.line((620, 140, 720, 185), fill=(0, 0, 0), width=2)
draw.text((650, 175), "N : 1", fill=(0, 0, 0), font=font)
draw.line((620, 170, 720, 275), fill=(0, 0, 0), width=2)
draw.text((650, 250), "N : M", fill=(0, 0, 0), font=font)

draw.text(
    (40, 360),
    "UI: Equipment — dropdown Category/Brand + FilterChip Tag; Client — вложенный блок билета.",
    fill=(40, 40, 40),
    font=font,
)
img.save(OUT)
print(OUT)
