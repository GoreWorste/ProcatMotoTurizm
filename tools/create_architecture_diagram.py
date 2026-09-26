# -*- coding: utf-8 -*-
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parents[1] / "screenshots_report" / "fig_layers_schema.png"

BOXES = [
    ("screens / widgets", "UI, таблица, карточки"),
    ("state (Provider)", "ChangeNotifier, query, selected"),
    ("repositories", "find, CRUD, deleteMany"),
    ("models", "Equipment, Client, Query"),
]


def main() -> None:
    w, h = 900, 520
    img = Image.new("RGB", (w, h), "white")
    draw = ImageDraw.Draw(img)
    try:
        font = ImageFont.truetype("arial.ttf", 18)
        font_s = ImageFont.truetype("arial.ttf", 14)
    except OSError:
        font = ImageFont.load_default()
        font_s = font

    draw.text((w // 2 - 180, 20), "Схема слоёв приложения", fill="black", font=font)

    y = 70
    for title, sub in BOXES:
        draw.rectangle([120, y, w - 120, y + 90], outline="#2a7a72", width=2, fill="#f4fbfb")
        draw.text((140, y + 18), title, fill="#111", font=font)
        draw.text((140, y + 48), sub, fill="#333", font=font_s)
        if y + 90 < h - 40:
            draw.line([(w // 2, y + 90), (w // 2, y + 110)], fill="#2a7a72", width=2)
        y += 110

    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT)
    print("Saved", OUT)


if __name__ == "__main__":
    main()
